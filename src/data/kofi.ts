import { KOFI_GOAL } from '../config';

export interface Goal { title: string; currentEUR: number; targetEUR: number; pct: number; supporters: number }

const fallback: Goal = { ...KOFI_GOAL, pct: Math.round((KOFI_GOAL.currentEUR / KOFI_GOAL.targetEUR) * 100) };

async function fetchGoal(): Promise<Goal> {
  try {
    const r = await fetch(KOFI_GOAL.proxy, { signal: AbortSignal.timeout(5000) });
    const d = await r.json();
    if (typeof d.percentage !== 'number' || typeof d.targetEUR !== 'number') return fallback;
    return { supporters: typeof d.supporters === 'number' ? d.supporters : fallback.supporters, title: d.title || fallback.title, currentEUR: d.currentEUR ?? Math.round((d.percentage / 100) * d.targetEUR), targetEUR: d.targetEUR, pct: Math.round(d.percentage) };
  } catch {
    return fallback;
  }
}

export const GOAL = await fetchGoal();
