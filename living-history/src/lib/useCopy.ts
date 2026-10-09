import { useEffect, useState } from 'react';

/** Copies text to the clipboard and reports success for a couple of seconds. */
export function useCopy(): [boolean, (text: string) => void] {
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!copied) return;
    const timer = window.setTimeout(() => setCopied(false), 2000);
    return () => window.clearTimeout(timer);
  }, [copied]);

  const copy = (text: string) => {
    navigator.clipboard?.writeText(text).then(
      () => setCopied(true),
      () => setCopied(false)
    );
  };

  return [copied, copy];
}
