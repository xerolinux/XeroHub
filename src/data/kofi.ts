import { KOFI } from '../config';

async function fetchSupporters(): Promise<number> {
  try {
    const d = await (await fetch(KOFI.proxy, { signal: AbortSignal.timeout(5000) })).json();
    return typeof d.supporters === 'number' ? d.supporters : KOFI.supporters;
  } catch {
    return KOFI.supporters;
  }
}

export const SUPPORTERS = await fetchSupporters();
