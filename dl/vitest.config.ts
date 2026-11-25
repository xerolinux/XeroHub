import { defineConfig } from 'vitest/config';
import { cloudflareTest, readD1Migrations } from '@cloudflare/vitest-plugin';

export default defineConfig(async () => ({
  plugins: [
    cloudflareTest({
      wrangler: { configPath: './wrangler.toml' },
      miniflare: {
        bindings: {
          TEST_MIGRATIONS: await readD1Migrations('./migrations'),
          SALT: 'test-salt',
          STAFF_KEY: 'test-staff-key',
          ADMIN_TOKEN: 'test-admin-token',
          R2_ACCESS_KEY_ID: '',
          R2_SECRET_ACCESS_KEY: '',
        },
      },
    }),
  ],
  test: { setupFiles: ['./test/setup.ts'] },
}));
