import { ImageOff } from 'lucide-react';
import type { AspectRatio, Entry } from '../types';
import AIBadge from './AIBadge';

const aspectClasses: Record<AspectRatio, string> = {
  '1:1': 'aspect-square',
  '3:2': 'aspect-[3/2]',
  '2:3': 'aspect-[2/3]',
  '16:9': 'aspect-video',
};

interface Props {
  entry: Entry;
  /** Force a uniform crop (used in grids). */
  aspect?: AspectRatio;
  className?: string;
}

export default function EntryImage({ entry, aspect, className = '' }: Props) {
  const image = entry.images[0];
  const ratio = aspectClasses[aspect ?? entry.spec.aspectRatio];

  return (
    <div className={`relative overflow-hidden rounded-xl bg-ink-800 ${ratio} ${className}`}>
      {image ? (
        <>
          <img src={image.src} alt={image.alt} loading="lazy" className="h-full w-full object-cover" />
          <AIBadge className="absolute left-3 top-3" />
        </>
      ) : (
        <div className="flex h-full w-full flex-col items-center justify-center gap-2 bg-gradient-to-br from-ochre-500/30 via-ink-800 to-lapis-700 p-4 text-center text-papyrus-100">
          <ImageOff className="h-6 w-6 opacity-70" aria-hidden />
          <span className="text-xs uppercase tracking-widest opacity-80">Reconstruction pending</span>
        </div>
      )}
    </div>
  );
}
