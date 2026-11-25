const enc = new TextEncoder();

export async function hmac(key: string, msg: string) {
  const k = await crypto.subtle.importKey('raw', enc.encode(key), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return [...new Uint8Array(await crypto.subtle.sign('HMAC', k, enc.encode(msg)))].map((b) => b.toString(16).padStart(2, '0')).join('');
}

// Hash both sides first so the comparison is constant-time and length-independent.
export async function safeEqual(a: string, b: string, salt: string) {
  const [x, y] = await Promise.all([hmac(salt, `cmp:${a}`), hmac(salt, `cmp:${b}`)]);
  return crypto.subtle.timingSafeEqual(enc.encode(x), enc.encode(y));
}

// IPv4 as is, IPv6 reduced to its /64, so one household or one v6 client is one visitor.
export function ipScope(ip: string) {
  ip = ip.trim().toLowerCase();
  if (!ip) return '';
  if (!ip.includes(':')) return ip;
  const last = ip.slice(ip.lastIndexOf(':') + 1);
  if (last.includes('.')) return last;
  const [head, tail] = ip.split('::');
  const h = head ? head.split(':') : [];
  const t = tail ? tail.split(':') : [];
  const parts = ip.includes('::') ? [...h, ...Array(Math.max(0, 8 - h.length - t.length)).fill('0'), ...t] : h;
  return `${parts.slice(0, 4).map((p) => parseInt(p || '0', 16).toString(16)).join(':')}::/64`;
}
