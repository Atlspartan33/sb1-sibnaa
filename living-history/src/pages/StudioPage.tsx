import { Link } from 'react-router-dom';
import { CheckCircle2, Circle } from 'lucide-react';
import { entries } from '../data';
import { buildCombinedPrompt } from '../lib/promptBuilder';
import { entryTypeLabels } from '../lib/format';
import { useCopy } from '../lib/useCopy';
import PromptPanel from '../components/PromptPanel';

function CopyAllButton() {
  const [copied, copy] = useCopy();
  const pending = entries.filter((e) => e.images.length === 0);
  const text = pending.map((e) => `### ${e.title}\n${buildCombinedPrompt(e.spec)}`).join('\n\n');
  return (
    <button type="button" className="btn-primary" onClick={() => copy(text)} disabled={pending.length === 0}>
      {copied ? 'Copied!' : `Copy all ${pending.length} pending prompts`}
    </button>
  );
}

export default function StudioPage() {
  const done = entries.filter((e) => e.images.length > 0).length;

  return (
    <div className="container-page py-12">
      <p className="eyebrow">Studio</p>
      <h1 className="mt-2 text-4xl font-bold sm:text-5xl">Generation queue</h1>
      <p className="mt-4 max-w-3xl leading-relaxed text-ink-700">
        Prompts are built automatically from each entry’s Scene Spec. Paste them into your image model, pick the best
        result after checking it against the evidence, save it to{' '}
        <code className="rounded bg-ink-800/5 px-1">public/images/&lt;civilization&gt;/</code>, and add it to the
        entry’s <code className="rounded bg-ink-800/5 px-1">images</code> array.
      </p>

      <div className="mt-6 flex flex-wrap items-center gap-4">
        <CopyAllButton />
        <span className="text-sm text-ink-700">
          {done} of {entries.length} entries have an image
        </span>
      </div>

      <div className="mt-10 space-y-3">
        {entries.map((entry) => {
          const hasImage = entry.images.length > 0;
          return (
            <details key={entry.id} className="card p-4">
              <summary className="flex cursor-pointer list-none items-center gap-3">
                {hasImage ? (
                  <CheckCircle2 className="h-5 w-5 shrink-0 text-malachite-500" aria-label="Has image" />
                ) : (
                  <Circle className="h-5 w-5 shrink-0 text-ink-700/40" aria-label="Pending" />
                )}
                <span className="flex-1">
                  <span className="font-medium text-ink-900">{entry.title}</span>
                  <span className="ml-2 text-xs text-ink-700">{entryTypeLabels[entry.type]}</span>
                </span>
                <Link to={`/entries/${entry.id}`} className="text-xs text-lapis-600 hover:underline">
                  View entry
                </Link>
              </summary>
              <div className="mt-4">
                <PromptPanel spec={entry.spec} />
              </div>
            </details>
          );
        })}
      </div>
    </div>
  );
}
