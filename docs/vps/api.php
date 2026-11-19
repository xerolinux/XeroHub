<?php
declare(strict_types=1);

// JSON API for the xerolinux.xyz download page (paid period, until the ISO goes free).
// Same rules as access.php and KDEPlasma/<edition>/index.php, but token based instead of cookies.
// Lives at /app/KDEPlasma/api.php (already mounted), so compose.yml does not change.

require '/opt/r2/portal.php';

const API_ORIGINS   = ['https://xerolinux.xyz', 'https://www.xerolinux.xyz', 'http://127.0.0.1:4321', 'http://localhost:4321'];
const API_EDITIONS  = ['std', 'nvidia'];
const API_CODES     = '/etc/xeroiso/codez.json';
const API_TOKENS    = '/var/lib/xeroiso/api-tokens.json';
const API_RATE      = '/var/lib/xeroiso/api-rate.json';
const API_TOKEN_TTL = 7200;
const API_RATE_MAX  = 10;     // failed logins per IP per window
const API_RATE_WIN  = 900;    // seconds

function out(int $status, array $body): never
{
    http_response_code($status);
    echo json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

// Read-modify-write a JSON file under an exclusive lock. $fn gets the decoded array and returns [newData, result].
function withJson(string $path, callable $fn): mixed
{
    $fh = fopen($path, 'c+');
    if ($fh === false) out(503, ['error' => 'Downloads are temporarily unavailable. Please try again later.']);
    flock($fh, LOCK_EX);
    $raw  = stream_get_contents($fh);
    $data = ($raw === '' || $raw === false) ? [] : (json_decode($raw, true) ?? []);
    [$data, $result] = $fn(is_array($data) ? $data : []);
    ftruncate($fh, 0);
    rewind($fh);
    fwrite($fh, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    fflush($fh);
    flock($fh, LOCK_UN);
    fclose($fh);
    return $result;
}

function clientKey(): string
{
    $ip = (string) ($_SERVER['HTTP_CF_CONNECTING_IP'] ?? $_SERVER['REMOTE_ADDR'] ?? '');
    return hash('sha256', $ip);
}

function linksLeft(string $code): ?int
{
    if (r2IsStaff($code)) return null;
    $raw  = @file_get_contents(R2_CODE_LINKS);
    $used = $raw ? (json_decode($raw, true) ?? []) : [];
    return max(0, R2_CODE_LIMIT - (int) ($used[$code] ?? 0));
}

function editionInfo(string $edition): ?array
{
    $files = r2Catalog($edition);
    if (!$files) return null;
    $f = $files[0];
    $raw = @file_get_contents("/app/KDEPlasma/$edition/downloads.json");
    $counts = $raw ? (json_decode($raw, true) ?? []) : [];
    $total = 0;
    foreach ($counts as $name => $n) {
        if (str_ends_with(strtolower((string) $name), '.iso')) $total += (int) $n;
    }
    return [
        'file' => $f['name'], 'size' => $f['size'], 'date' => $f['modified'],
        'md5' => $f['md5'], 'sha1' => $f['sha1'], 'sha256' => $f['sha256'],
        'release' => (int) ($counts[$f['name']] ?? 0), 'total' => $total,
    ];
}

// ── CORS ────────────────────────────────────────────────────────
$origin = (string) ($_SERVER['HTTP_ORIGIN'] ?? '');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
header('Vary: Origin');
if (in_array($origin, API_ORIGINS, true)) {
    header("Access-Control-Allow-Origin: $origin");
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
    header('Access-Control-Max-Age: 600');
}
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') out(204, []);
if ($_SERVER['REQUEST_METHOD'] !== 'POST') out(405, ['error' => 'Method not allowed.']);
if (file_exists('/app/flags/maintenance')) out(503, ['error' => 'The download portal is under maintenance. Please try again later.']);

$in = json_decode((string) file_get_contents('php://input', false, null, 0, 4096), true);
if (!is_array($in)) out(400, ['error' => 'Bad request.']);
$action = (string) ($_GET['action'] ?? '');

// ── Login: same checks as access.php ────────────────────────────
if ($action === 'login') {
    $ip = clientKey();
    $now = time();
    $blocked = withJson(API_RATE, function (array $r) use ($ip, $now) {
        $r = array_filter($r, fn($v) => $now - (int) ($v['t'] ?? 0) < API_RATE_WIN);
        return [$r, (int) ($r[$ip]['n'] ?? 0) >= API_RATE_MAX];
    });
    if ($blocked) out(429, ['error' => 'Too many attempts. Please wait a few minutes and try again.']);

    $code  = strtoupper(trim((string) ($in['code'] ?? '')));
    $email = strtolower(trim((string) ($in['email'] ?? '')));
    $raw   = file_get_contents(API_CODES);
    $codes = $raw !== false ? json_decode($raw, true) : null;
    if (!is_array($codes)) out(503, ['error' => 'Service temporarily unavailable. Please try again later.']);

    $entry = $codes[$code] ?? null;
    $error = null;
    if ($entry === null) $error = 'Invalid code.';
    elseif (strtolower((string) $entry['email']) !== $email) $error = 'Email does not match the code.';
    elseif (($entry['product'] ?? '') !== 'kde') $error = 'Unknown product type.';

    if ($error !== null) {
        withJson(API_RATE, function (array $r) use ($ip, $now) {
            $r[$ip] = ['n' => (int) ($r[$ip]['n'] ?? 0) + 1, 't' => $now];
            return [$r, null];
        });
        out(401, ['error' => $error]);
    }

    $token = bin2hex(random_bytes(32));
    withJson(API_TOKENS, function (array $t) use ($token, $code, $now) {
        $t = array_filter($t, fn($v) => (int) ($v['exp'] ?? 0) > $now);
        $t[$token] = ['code' => $code, 'exp' => $now + API_TOKEN_TTL];
        return [$t, null];
    });

    $editions = [];
    foreach (API_EDITIONS as $e) {
        $info = editionInfo($e);
        if ($info !== null) $editions[$e] = $info;
    }
    out(200, ['token' => $token, 'expires' => $now + API_TOKEN_TTL, 'linksLeft' => linksLeft($code), 'editions' => $editions]);
}

// ── Link: same steps as KDEPlasma/<edition>/index.php ?dl= ──────
if ($action === 'link') {
    $now  = time();
    $tok  = (string) ($in['token'] ?? '');
    $code = withJson(API_TOKENS, function (array $t) use ($tok, $now) {
        $t = array_filter($t, fn($v) => (int) ($v['exp'] ?? 0) > $now);
        return [$t, $t[$tok]['code'] ?? null];
    });
    if ($code === null) out(401, ['error' => 'Your session expired. Please enter your code again.']);

    $edition = (string) ($in['edition'] ?? '');
    if (!in_array($edition, API_EDITIONS, true)) out(404, ['error' => 'File not found.']);
    $file = r2Find(r2Catalog($edition), trim((string) ($in['file'] ?? '')));
    if ($file === null) out(404, ['error' => 'File not found.']);

    try {
        $s3 = r2Client();
    } catch (Throwable $e) {
        error_log('R2 config: ' . $e->getMessage());
        out(503, ['error' => 'Downloads are temporarily unavailable. Please try again later.']);
    }

    if (!r2TakeLink($code)) out(403, ['error' => 'This code has reached its download limit.']);

    if (!r2IsStaff($code)) {
        $cf = "/app/KDEPlasma/$edition/downloads.json";
        $raw = file_exists($cf) ? file_get_contents($cf) : '';
        $counts = ($raw !== false && $raw !== '') ? (json_decode($raw, true) ?? []) : [];
        $counts[$file['name']] = ($counts[$file['name']] ?? 0) + 1;
        file_put_contents($cf, json_encode($counts, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE), LOCK_EX);
    }

    out(200, ['url' => r2Link($s3, $file), 'linksLeft' => linksLeft($code)]);
}

out(404, ['error' => 'Unknown action.']);
