import { Sparkles } from 'lucide-react';

export default function AIBadge({ className = '' }: { className?: string }) {
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full bg-ink-900/80 px-2.5 py-1 text-[11px] font-medium uppercase tracking-wider text-papyrus-50 backdrop-blur ${className}`}
    >
      <Sparkles className="h-3 w-3" aria-hidden />
      AI reconstruction
    </span>
  );
}
