import type { Confidence, EntryType } from '../types';

export function formatYear(year: number): string {
  return year < 0 ? `${Math.abs(year)} BCE` : `${year} CE`;
}

export const entryTypeLabels: Record<EntryType, string> = {
  portrait: 'Portrait',
  attire: 'Attire study',
  'daily-life': 'Daily life',
  place: 'Place',
  moment: 'Historic moment',
};

export const confidenceLabels: Record<Confidence, string> = {
  high: 'Well documented',
  medium: 'Reasonable inference',
  low: 'Speculative',
};
