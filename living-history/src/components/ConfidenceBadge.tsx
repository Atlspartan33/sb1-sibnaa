import type { Confidence } from '../types';
import { confidenceLabels } from '../lib/format';

const styles: Record<Confidence, string> = {
  high: 'bg-malachite-500/10 text-malachite-600 ring-malachite-500/30',
  medium: 'bg-ochre-400/15 text-ochre-600 ring-ochre-500/30',
  low: 'bg-ink-800/5 text-ink-700 ring-ink-800/20',
};

export default function ConfidenceBadge({ level }: { level: Confidence }) {
  return (
    <span
      className={`inline-flex shrink-0 items-center rounded-full px-2 py-0.5 text-[11px] font-medium ring-1 ring-inset ${styles[level]}`}
    >
      {confidenceLabels[level]}
    </span>
  );
}
