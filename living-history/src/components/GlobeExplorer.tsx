import { useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, Clock, X } from 'lucide-react';
import { civilizations, getEntriesFor } from '../data';
import { isActiveIn } from '../data/civilizations';
import { formatYear } from '../lib/format';
import Globe from './Globe';
import EntryImage from './EntryImage';

const MIN_YEAR = Math.min(...civilizations.map((c) => c.period.start));
const MAX_YEAR = Math.max(...civilizations.map((c) => c.period.end));
const YEAR_STEP = 25;

const byStart = [...civilizations].sort((a, b) => a.period.start - b.period.start);

function TimeControl({ year, onChange }: { year: number | null; onChange: (y: number | null) => void }) {
  const value = year ?? -1300;
  return (
    <div className="rounded-xl border border-papyrus-50/10 bg-papyrus-50/5 p-4">
      <div className="flex items-center justify-between gap-3">
        <label htmlFor="year" className="flex items-center gap-2 text-sm font-medium text-papyrus-100">
          <Clock className="h-4 w-4 text-ochre-400" aria-hidden />
          {year === null ? 'All eras' : formatYear(year)}
        </label>
        <button
          type="button"
          onClick={() => onChange(year === null ? value : null)}
          className="rounded-full border border-papyrus-50/20 px-3 py-1 text-xs text-papyrus-100 hover:bg-papyrus-50/10"
        >
          {year === null ? 'Travel through time' : 'Show all eras'}
        </button>
      </div>
      <input
        id="year"
        type="range"
        min={MIN_YEAR}
        max={MAX_YEAR}
        step={YEAR_STEP}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        aria-valuetext={formatYear(value)}
        className="mt-3 w-full accent-ochre-500"
      />
      <div className="mt-1 flex justify-between text-[11px] text-papyrus-100/60">
        <span>{formatYear(MIN_YEAR)}</span>
        <span>{formatYear(MAX_YEAR)}</span>
      </div>
    </div>
  );
}

function CivilizationList({ year, onSelect }: { year: number | null; onSelect: (id: string) => void }) {
  const list = year === null ? byStart : byStart.filter((c) => isActiveIn(c, year));
  return (
    <div>
      <p className="eyebrow text-ochre-400">{year === null ? 'All civilizations' : `Thriving in ${formatYear(year)}`}</p>
      <h2 className="mt-2 text-2xl font-semibold text-papyrus-50">
        {list.length === 0 ? 'No civilizations here yet' : 'Choose a place on the globe'}
      </h2>
      {list.length === 0 ? (
        <p className="mt-3 text-sm text-papyrus-100/70">Slide to another year. We’re adding more civilizations.</p>
      ) : (
        <ul className="mt-4 space-y-1">
          {list.map((c) => (
            <li key={c.id}>
              <button
                type="button"
                onClick={() => onSelect(c.id)}
                className="flex w-full items-center gap-3 rounded-lg px-2 py-2 text-left hover:bg-papyrus-50/10"
              >
                <span
                  className={`h-2.5 w-2.5 shrink-0 rounded-full ${
                    c.status === 'published' ? 'bg-ochre-400' : 'border-2 border-ochre-400'
                  }`}
                  aria-hidden
                />
                <span className="flex-1 text-sm text-papyrus-50">{c.name}</span>
                <span className="text-xs text-papyrus-100/60">{c.dateLabel}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function CivilizationPanel({ id, onClose }: { id: string; onClose: () => void }) {
  const civ = civilizations.find((c) => c.id === id);
  if (!civ) return null;
  const entries = getEntriesFor(civ.id);
  const published = civ.status === 'published';

  return (
    <div>
      <div className="flex items-start justify-between gap-3">
        <span
          className={`rounded-full px-2.5 py-0.5 text-[11px] font-medium ${
            published ? 'bg-ochre-500 text-white' : 'bg-papyrus-50/10 text-papyrus-100'
          }`}
        >
          {published ? `${entries.length} reconstructions` : 'In research'}
        </span>
        <button
          type="button"
          onClick={onClose}
          aria-label="Close"
          className="rounded-full p-1 text-papyrus-100/70 hover:bg-papyrus-50/10 hover:text-papyrus-50"
        >
          <X className="h-4 w-4" />
        </button>
      </div>
      <h2 className="mt-3 text-3xl font-semibold leading-tight text-papyrus-50">{civ.name}</h2>
      <p className="mt-1 text-sm text-papyrus-100/70">
        {civ.dateLabel} · {civ.region}
      </p>
      <p className="mt-4 text-sm leading-relaxed text-papyrus-100/90">{civ.blurb}</p>

      {published ? (
        <>
          <div className="mt-5 grid grid-cols-2 gap-3">
            {entries.slice(0, 4).map((e) => (
              <Link key={e.id} to={`/entries/${e.id}`} className="group">
                <EntryImage entry={e} aspect="3:2" className="rounded-lg" />
                <p className="mt-1.5 text-xs leading-snug text-papyrus-100 group-hover:text-white">{e.title}</p>
              </Link>
            ))}
          </div>
          <Link to={`/civilizations/${civ.id}`} className="btn mt-5 w-full justify-center bg-ochre-500 text-white hover:bg-ochre-600">
            Explore {civ.name.split(':')[0]} <ArrowRight className="h-4 w-4" />
          </Link>
        </>
      ) : (
        <div className="mt-5 rounded-lg border border-papyrus-50/10 bg-papyrus-50/5 p-4 text-sm leading-relaxed text-papyrus-100/80">
          {civ.researchNote ?? 'We’re gathering evidence for this civilization. Reconstructions are coming soon.'}
        </div>
      )}
    </div>
  );
}

export default function GlobeExplorer() {
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [year, setYear] = useState<number | null>(null);
  const panelRef = useRef<HTMLDivElement>(null);

  const select = (id: string) => {
    setSelectedId(id);
    // On narrow screens the panel sits below the globe; bring it into view.
    if (window.matchMedia('(max-width: 1023px)').matches) {
      requestAnimationFrame(() => panelRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' }));
    }
  };

  return (
    <div className="grid grid-cols-[minmax(0,1fr)] items-start gap-8 lg:grid-cols-[minmax(0,1fr)_380px]">
      <div className="space-y-4">
        <Globe civilizations={civilizations} selectedId={selectedId} onSelect={select} year={year} />
        <TimeControl year={year} onChange={setYear} />
      </div>
      <aside
        ref={panelRef}
        aria-live="polite"
        className="scroll-mt-20 rounded-2xl border border-papyrus-50/10 bg-ink-800/80 p-5 backdrop-blur lg:max-h-[640px] lg:overflow-y-auto"
      >
        {selectedId ? (
          <CivilizationPanel id={selectedId} onClose={() => setSelectedId(null)} />
        ) : (
          <CivilizationList year={year} onSelect={select} />
        )}
      </aside>
    </div>
  );
}
