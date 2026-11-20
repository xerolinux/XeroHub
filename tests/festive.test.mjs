import test from 'node:test';
import assert from 'node:assert/strict';
import { FESTIVE_IDS, easter, festiveFor } from '../src/data/festive.ts';

const at = (s) => festiveFor(new Date(`${s}T12:00:00`));

test('ids', () => assert.deepEqual(FESTIVE_IDS, ['new-year', 'lunar-new-year', 'valentines', 'st-patricks', 'easter', 'independence-day', 'halloween', 'diwali', 'thanksgiving', 'christmas']));

test('easter computus', () => {
  assert.equal(easter(2026).toDateString(), new Date(2026, 3, 5).toDateString());
  assert.equal(easter(2027).toDateString(), new Date(2027, 2, 28).toDateString());
});

test('dates', () => {
  const cases = {
    '2026-12-25': 'christmas', '2026-12-01': 'christmas', '2026-12-30': 'christmas', '2026-12-31': 'new-year', '2027-01-02': 'new-year', '2027-01-03': null,
    '2026-04-03': 'easter', '2026-04-06': 'easter', '2026-04-02': null, '2026-04-07': null,
    '2026-11-26': 'thanksgiving', '2026-11-29': 'thanksgiving', '2026-11-25': null,
    '2026-10-31': 'halloween', '2026-10-24': 'halloween', '2026-11-01': 'halloween', '2026-11-08': 'diwali', '2026-11-10': 'diwali', '2026-11-11': null,
    '2033-10-24': 'diwali', '2026-07-04': 'independence-day', '2026-07-06': null, '2026-03-17': 'st-patricks',
    '2026-02-14': 'valentines', '2026-02-17': 'lunar-new-year', '2026-02-19': 'lunar-new-year', '2026-02-20': null, '2026-06-01': null,
  };
  for (const [d, want] of Object.entries(cases)) assert.equal(at(d), want, d);
});
