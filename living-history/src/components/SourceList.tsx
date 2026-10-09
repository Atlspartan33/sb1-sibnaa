import { sources } from '../data';

export default function SourceList({ sourceIds }: { sourceIds: string[] }) {
  if (sourceIds.length === 0) {
    return <p className="text-sm italic text-ink-700">No direct source. This is an artistic inference.</p>;
  }

  return (
    <ol className="space-y-3">
      {sourceIds.map((id) => {
        const source = sources[id];
        if (!source) return null;
        return (
          <li key={id} className="text-sm leading-relaxed">
            <span className="font-medium text-ink-900">
              {source.url ? (
                <a href={source.url} target="_blank" rel="noreferrer" className="underline underline-offset-4">
                  {source.title}
                </a>
              ) : (
                source.title
              )}
            </span>
            {(source.author || source.year) && (
              <span className="text-ink-700">
                {' '}
                ({[source.author, source.year].filter(Boolean).join(', ')})
              </span>
            )}
            {source.note && <p className="mt-0.5 text-ink-700">{source.note}</p>}
          </li>
        );
      })}
    </ol>
  );
}
