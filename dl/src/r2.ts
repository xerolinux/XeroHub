import { AwsClient } from 'aws4fetch';
import type { Env } from './env';
import type { Entry } from './catalog';

export const LINK_TTL = 45 * 60;

export const r2Ready = (env: Env) => !!(env.R2_ENDPOINT && env.R2_BUCKET && env.R2_ACCESS_KEY_ID && env.R2_SECRET_ACCESS_KEY);

// Presigned GET, path style, like the VPS's S3 client.
export async function presign(env: Env, file: Entry) {
  const aws = new AwsClient({ accessKeyId: env.R2_ACCESS_KEY_ID, secretAccessKey: env.R2_SECRET_ACCESS_KEY, service: 's3', region: 'auto' });
  const url = new URL(`${env.R2_ENDPOINT.replace(/\/+$/, '')}/${env.R2_BUCKET}/${file.key.split('/').map(encodeURIComponent).join('/')}`);
  url.searchParams.set('X-Amz-Expires', String(LINK_TTL));
  url.searchParams.set('response-content-disposition', `attachment; filename="${file.name}"`);
  const signed = await aws.sign(new Request(url, { method: 'GET' }), { aws: { signQuery: true } });
  return signed.url;
}
