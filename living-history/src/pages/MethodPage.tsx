import type { Confidence } from '../types';
import ConfidenceBadge from '../components/ConfidenceBadge';

const confidenceExplained: { level: Confidence; text: string }[] = [
  {
    level: 'high',
    text: 'Shown directly in multiple contemporary sources: surviving objects, paintings, excavated remains, or texts.',
  },
  {
    level: 'medium',
    text: 'A reasonable inference from related evidence, or supported by a single source or a debated interpretation.',
  },
  {
    level: 'low',
    text: 'An artistic choice needed to make a complete image. Shown to readers, but never sent to the image model as fact.',
  },
];

const commitments = [
  {
    title: 'Every image is labeled',
    text: 'Reconstructions always carry a visible "AI reconstruction" badge so they can’t be mistaken for photographs or real artifacts.',
  },
  {
    title: 'Ordinary people first',
    text: 'Farmers, craftspeople, and families made up most of every civilization. We show them, not only kings and queens.',
  },
  {
    title: 'No single "look"',
    text: 'Civilizations lasted centuries and covered huge regions. We name the specific time, place, and social group of every image.',
  },
  {
    title: 'Stereotypes are named and excluded',
    text: 'Each Scene Spec lists the Hollywood tropes and anachronisms the image must avoid, and we show that list to readers.',
  },
  {
    title: 'Descendant communities lead',
    text: 'For Indigenous nations and other living cultures, we work with advisors from those communities and never depict ceremonial or sacred items without their approval.',
  },
  {
    title: 'Corrections welcome',
    text: 'Evidence changes. When a specialist shows we got something wrong, we fix the Scene Spec and regenerate the image.',
  },
];

export default function MethodPage() {
  return (
    <div className="container-page max-w-3xl py-12">
      <p className="eyebrow">Our method</p>
      <h1 className="mt-2 text-4xl font-bold sm:text-5xl">How we reconstruct the past</h1>
      <p className="mt-5 text-lg leading-relaxed text-ink-700">
        Image models learn from the internet, which is full of movie costumes and stereotypes. Left alone, they show you
        what Hollywood thinks the past looked like. We put a research step between the question and the image.
      </p>

      <section className="mt-12">
        <h2 className="text-2xl font-bold">The pipeline</h2>
        <ol className="mt-5 space-y-4">
          {[
            ['Research', 'Collect primary evidence (sites, artifacts, texts, scientific studies) and specialist scholarship.'],
            ['Scene Spec', 'Turn the research into a structured spec: every visual detail tied to sources and given a confidence level, plus an explicit "avoid" list.'],
            ['Prompt', 'Build the image prompt automatically from the spec. Speculative details stay out.'],
            ['Generate', 'Produce several variants, often with more than one image model.'],
            ['Review', 'Check each candidate against the evidence. Reject anachronisms, stereotypes, and invented details.'],
            ['Publish', 'Show the image with its sources, confidence levels, and myth-vs-reality notes.'],
          ].map(([title, text], i) => (
            <li key={title} className="flex gap-4">
              <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-ink-900 text-sm font-semibold text-papyrus-50">
                {i + 1}
              </span>
              <div>
                <p className="font-semibold text-ink-900">{title}</p>
                <p className="text-sm leading-relaxed text-ink-700">{text}</p>
              </div>
            </li>
          ))}
        </ol>
      </section>

      <section className="mt-12">
        <h2 className="text-2xl font-bold">Confidence levels</h2>
        <div className="mt-5 space-y-3">
          {confidenceExplained.map(({ level, text }) => (
            <div key={level} className="card flex flex-col gap-2 p-4 sm:flex-row sm:items-start sm:gap-4">
              <ConfidenceBadge level={level} />
              <p className="text-sm leading-relaxed">{text}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="mt-12">
        <h2 className="text-2xl font-bold">Our commitments</h2>
        <div className="mt-5 grid gap-4 sm:grid-cols-2">
          {commitments.map((c) => (
            <div key={c.title} className="card p-5">
              <h3 className="text-lg font-semibold">{c.title}</h3>
              <p className="mt-1.5 text-sm leading-relaxed text-ink-700">{c.text}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
