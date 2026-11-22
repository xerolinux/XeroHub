import test from 'node:test';
import assert from 'node:assert/strict';
import { BOSS_IDS, LEVELS, bossFor } from '../src/scripts/winvaders.ts';

test('12 levels with a unique boss on every third', () => {
  assert.equal(LEVELS, 12);
  const bosses = Array.from({ length: LEVELS }, (_, i) => bossFor(i + 1));
  assert.deepEqual(bosses.filter(Boolean), [...BOSS_IDS]);
  assert.equal(new Set(BOSS_IDS).size, 4);
  bosses.forEach((b, i) => assert.equal(!!b, (i + 1) % 3 === 0));
});
