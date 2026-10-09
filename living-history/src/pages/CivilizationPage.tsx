import { useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import type { EntryType } from '../types';
import { getCivilization, getEntriesFor } from '../data';
import { entryTypeLabels, formatYear } from '../lib/format';
import EntryCard from '../components/EntryCard';
import NotFound from './NotFound';

type Filter = EntryType | 'all';

export default function CivilizationPage() {
  const { civilizationId = '' } = useParams();
  const civ = getCivilization(civilizationId);
  const entries = useMemo(() => getEntriesFor(civilizationId), [civilizationId]);
  const [filter, setFilter] = useState<Filter>('all');

  if (!civ) return <NotFound />;

  const types = Array.from(new Set(entries.map((e) => e.type)));
  const visible = filter === 'all' ? entries : entries.filter((e) => e.type === filter);

  const minYear = Math.min(...entries.map((e) => e.spec.period.start));
  const maxYear = Math.max(...entries.map((e) => e.spec.period.end));
  const span = Math.max(maxYear - minYear, 1);

  return (
    <div className="container-page py-12">
      <Link to="/" className="text-sm text-ink-700 hover:text-ink-900">
        ← All civilizations
      </Link>
      <p className="eyebrow mt-6">{civ.era}</p>
      <h1 className="mt-2 text-4xl font-bold sm:text-5xl">{civ.name}</h1>
      <p className="mt-2 text-sm text-ink-700">
        {civ.region} · {civ.dateLabel}
      </p>
      <p className="mt-4 max-w-3xl text-lg leading-relaxed text-ink-700">{civ.blurb}</p>

      {civ.status === 'in-research' && (
        <div className="card mt-8 p-5 text-sm leading-relaxed text-ink-700">
          <p className="font-semibold text-ink-900">In research</p>
          <p className="mt-1">{civ.researchNote ?? 'Reconstructions for this civilization are still being researched.'}</p>
        </div>
      )}

      {entries.length > 0 && (
        <>
          <section aria-label="Timeline" className="mt-10">
            <div className="relative h-16">
              <div className="absolute left-0 right-0 top-6 h-px bg-ink-800/20" />
              {entries.map((e) => {
                const left = ((e.spec.period.start - minYear) / span) * 100;
                return (
                  <Link
                    key={e.id}
                    to={`/entries/${e.id}`}
                    title={`${e.title} (${e.dateLabel})`}
                    className="group absolute top-4 -translate-x-1/2"
                    style={{ left: `${left}%` }}
                  >
                    <span className="block h-4 w-4 rounded-full border-2 border-papyrus-50 bg-ochre-500 transition-transform group-hover:scale-125" />
                  </Link>
                );
              })}
              <span className="absolute left-0 top-11 text-xs text-ink-700">{formatYear(minYear)}</span>
              <span className="absolute right-0 top-11 text-xs text-ink-700">{formatYear(maxYear)}</span>
            </div>
          </section>

          <div className="mt-6 flex flex-wrap gap-2">
            {(['all', ...types] as Filter[]).map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => setFilter(t)}
                className={`rounded-full px-3 py-1.5 text-sm ${
                  filter === t ? 'bg-ink-900 text-papyrus-50' : 'bg-white/70 text-ink-700 ring-1 ring-ink-800/10 hover:bg-white'
                }`}
              >
                {t === 'all' ? 'All' : entryTypeLabels[t]}
              </button>
            ))}
          </div>

          <div className="mt-8 grid gap-x-8 gap-y-10 sm:grid-cols-2 lg:grid-cols-3">
            {visible.map((entry) => (
              <EntryCard key={entry.id} entry={entry} />
            ))}
          </div>
        </>
      )}
    </div>
  );
}
