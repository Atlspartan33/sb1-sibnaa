import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, ArrowRight, Info } from 'lucide-react';
import type { EvidencedDetail } from '../types';
import { getCivilization, getEntriesFor, getEntry, sources } from '../data';
import { entryTypeLabels } from '../lib/format';
import EntryImage from '../components/EntryImage';
import ConfidenceBadge from '../components/ConfidenceBadge';
import SourceList from '../components/SourceList';
import PromptPanel from '../components/PromptPanel';
import NotFound from './NotFound';

function Citations({ ids, order }: { ids: string[]; order: string[] }) {
  if (ids.length === 0) return null;
  return (
    <sup className="ml-0.5 text-[10px] text-lapis-600">
      [{ids.map((id) => order.indexOf(id) + 1).join(', ')}]
    </sup>
  );
}

function DetailGroup({ title, details, order }: { title: string; details: EvidencedDetail[]; order: string[] }) {
  if (details.length === 0) return null;
  return (
    <div>
      <h3 className="text-lg font-semibold">{title}</h3>
      <ul className="mt-3 space-y-3">
        {details.map((d) => (
          <li key={d.detail} className="flex flex-col gap-1.5 text-sm leading-relaxed sm:flex-row sm:items-start sm:justify-between sm:gap-4">
            <span className="first-letter:uppercase">
              {d.detail}
              <Citations ids={d.sourceIds} order={order} />
            </span>
            <ConfidenceBadge level={d.confidence} />
          </li>
        ))}
      </ul>
    </div>
  );
}

export default function EntryPage() {
  const { entryId = '' } = useParams();
  const entry = getEntry(entryId);
  if (!entry) return <NotFound />;

  const civ = getCivilization(entry.civilizationId);
  const siblings = getEntriesFor(entry.civilizationId);
  const index = siblings.findIndex((e) => e.id === entry.id);
  const prev = siblings[index - 1];
  const next = siblings[index + 1];

  const { spec } = entry;
  const sourceOrder = Array.from(
    new Set(
      [...spec.appearance, ...spec.attire, ...spec.environment, ...entry.mythsVsReality]
        .flatMap((d) => d.sourceIds)
        .filter((id) => sources[id])
    )
  );

  return (
    <article className="container-page py-10">
      {civ && (
        <Link to={`/civilizations/${civ.id}`} className="text-sm text-ink-700 hover:text-ink-900">
          ← {civ.name}
        </Link>
      )}

      <div className="mt-6 grid gap-10 lg:grid-cols-[1.1fr_1fr]">
        <div className="lg:sticky lg:top-24 lg:self-start">
          <EntryImage entry={entry} />
          <p className="mt-3 flex items-start gap-2 text-xs leading-relaxed text-ink-700">
            <Info className="mt-0.5 h-3.5 w-3.5 shrink-0" aria-hidden />
            This is an AI-generated reconstruction, not a photograph. It reflects current evidence and interpretation,
            which may change as research continues.
          </p>
        </div>

        <div>
          <p className="eyebrow">{entryTypeLabels[entry.type]}</p>
          <h1 className="mt-2 text-4xl font-bold leading-tight sm:text-5xl">{entry.title}</h1>
          <p className="mt-2 text-sm text-ink-700">
            {entry.dateLabel} · {spec.region}
          </p>
          <p className="mt-5 text-lg leading-relaxed">{entry.summary}</p>

          <section className="mt-10">
            <h2 className="text-2xl font-bold">What the evidence says</h2>
            <div className="mt-5 space-y-8">
              <DetailGroup title="People" details={spec.appearance} order={sourceOrder} />
              <DetailGroup title="Clothing and adornment" details={spec.attire} order={sourceOrder} />
              <DetailGroup title="Setting and objects" details={spec.environment} order={sourceOrder} />
            </div>
          </section>

          {entry.mythsVsReality.length > 0 && (
            <section className="mt-12">
              <h2 className="text-2xl font-bold">Myth vs. reality</h2>
              <div className="mt-5 space-y-4">
                {entry.mythsVsReality.map((m) => (
                  <div key={m.myth} className="card overflow-hidden">
                    <div className="border-b border-ink-800/10 bg-ink-800/5 px-5 py-3">
                      <p className="text-xs font-semibold uppercase tracking-wider text-ink-700">The myth</p>
                      <p className="mt-1 font-medium text-ink-900">{m.myth}</p>
                    </div>
                    <div className="px-5 py-3">
                      <p className="text-xs font-semibold uppercase tracking-wider text-malachite-600">The evidence</p>
                      <p className="mt-1 text-sm leading-relaxed">
                        {m.reality}
                        <Citations ids={m.sourceIds} order={sourceOrder} />
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </section>
          )}

          <section className="mt-12">
            <h2 className="text-2xl font-bold">Sources</h2>
            <div className="mt-5">
              <SourceList sourceIds={sourceOrder} />
            </div>
          </section>

          <details className="card mt-12 p-5">
            <summary className="cursor-pointer font-display text-xl font-semibold">Behind the image</summary>
            <div className="mt-5 space-y-5">
              <div>
                <h3 className="text-sm font-semibold uppercase tracking-wider text-ink-700">Deliberately avoided</h3>
                <ul className="mt-2 list-disc space-y-1 pl-5 text-sm">
                  {spec.avoid.map((a) => (
                    <li key={a}>{a}</li>
                  ))}
                </ul>
              </div>
              <PromptPanel spec={spec} />
            </div>
          </details>
        </div>
      </div>

      <nav className="mt-16 flex justify-between gap-4 border-t border-ink-800/10 pt-6 text-sm">
        {prev ? (
          <Link to={`/entries/${prev.id}`} className="flex items-center gap-2 text-ink-700 hover:text-ink-900">
            <ArrowLeft className="h-4 w-4" /> {prev.title}
          </Link>
        ) : (
          <span />
        )}
        {next && (
          <Link to={`/entries/${next.id}`} className="flex items-center gap-2 text-right text-ink-700 hover:text-ink-900">
            {next.title} <ArrowRight className="h-4 w-4" />
          </Link>
        )}
      </nav>
    </article>
  );
}
