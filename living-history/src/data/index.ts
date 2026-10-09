import type { Entry } from '../types';
import { egyptNewKingdomEntries } from './egypt-new-kingdom';

export { civilizations, getCivilization } from './civilizations';
export { sources } from './sources';

export const entries: Entry[] = [...egyptNewKingdomEntries];

export function getEntry(id: string): Entry | undefined {
  return entries.find((e) => e.id === id);
}

/** Entries for a civilization, oldest first. */
export function getEntriesFor(civilizationId: string): Entry[] {
  return entries
    .filter((e) => e.civilizationId === civilizationId)
    .sort((a, b) => a.spec.period.start - b.spec.period.start);
}
