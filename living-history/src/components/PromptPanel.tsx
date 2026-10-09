import { Check, Copy } from 'lucide-react';
import type { SceneSpec } from '../types';
import { buildImagePrompt } from '../lib/promptBuilder';
import { useCopy } from '../lib/useCopy';

function CopyBlock({ label, text }: { label: string; text: string }) {
  const [copied, copy] = useCopy();
  return (
    <div>
      <div className="mb-1.5 flex items-center justify-between">
        <span className="text-xs font-semibold uppercase tracking-wider text-ink-700">{label}</span>
        <button type="button" onClick={() => copy(text)} className="btn-ghost px-2 py-1 text-xs">
          {copied ? <Check className="h-3.5 w-3.5" /> : <Copy className="h-3.5 w-3.5" />}
          {copied ? 'Copied' : 'Copy'}
        </button>
      </div>
      <pre className="max-h-72 overflow-auto whitespace-pre-wrap rounded-lg bg-ink-900 p-3 text-xs leading-relaxed text-papyrus-100">
        {text}
      </pre>
    </div>
  );
}

export default function PromptPanel({ spec }: { spec: SceneSpec }) {
  const { prompt, negativePrompt, aspectRatio } = buildImagePrompt(spec);
  return (
    <div className="space-y-4">
      <CopyBlock label="Prompt" text={prompt} />
      <CopyBlock label="Negative prompt" text={negativePrompt} />
      <p className="text-xs text-ink-700">Aspect ratio: {aspectRatio}</p>
    </div>
  );
}
