import { Link } from 'react-router-dom';
import type { Entry } from '../types';
import { entryTypeLabels } from '../lib/format';
import EntryImage from './EntryImage';

export default function EntryCard({ entry }: { entry: Entry }) {
  return (
    <Link to={`/entries/${entry.id}`} className="group block">
      <EntryImage entry={entry} aspect="3:2" className="transition-transform duration-300 group-hover:-translate-y-0.5" />
      <div className="mt-3">
        <p className="eyebrow">{entryTypeLabels[entry.type]}</p>
        <h3 className="mt-1 text-xl font-semibold leading-snug group-hover:text-lapis-600">{entry.title}</h3>
        <p className="mt-1 text-sm text-ink-700">{entry.dateLabel}</p>
      </div>
    </Link>
  );
}
