import { Link } from 'react-router-dom';
import { ArrowRight, BookOpenCheck, FileSearch, ScanEye, ShieldCheck } from 'lucide-react';
import { civilizations, getEntry } from '../data';
import type { Entry } from '../types';
import EntryCard from '../components/EntryCard';

const steps = [
  {
    icon: FileSearch,
    title: 'Gather evidence',
    text: 'Tomb paintings, artifacts, excavations, DNA and skeletal studies, and written records.',
  },
  {
    icon: BookOpenCheck,
    title: 'Write a Scene Spec',
    text: 'Every visual detail gets a source and a confidence level, plus a list of stereotypes to avoid.',
  },
  {
    icon: ScanEye,
    title: 'Generate and review',
    text: 'Images are generated from the spec, then checked against the evidence before publishing.',
  },
  {
    icon: ShieldCheck,
    title: 'Show our work',
    text: 'Each image is labeled as an AI reconstruction, with its sources and uncertainties shown alongside.',
  },
];

const FEATURED_IDS = ['deir-el-medina-tomb-builder', 'karnak-hypostyle-in-color', 'nubian-prince-tribute'];

export default function Home() {
  const featured = FEATURED_IDS.map(getEntry).filter((e): e is Entry => Boolean(e));

  return (
    <>
      <section className="relative overflow-hidden bg-ink-900 text-papyrus-50">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(208,138,60,0.35),transparent_60%),radial-gradient(ellipse_at_bottom_left,rgba(47,79,143,0.45),transparent_55%)]" />
        <div className="container-page relative py-20 sm:py-28">
          <p className="eyebrow text-ochre-400">Evidence-based reconstructions</p>
          <h1 className="mt-4 max-w-3xl text-5xl font-bold leading-[1.05] text-papyrus-50 sm:text-6xl">
            See the people of the past as they really were.
          </h1>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed text-papyrus-100/85">
            Photorealistic reconstructions of ancient lives, clothing, and cities, built from archaeology rather than
            Hollywood. Every image shows the evidence behind it, and where that evidence runs out.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link to="/civilizations/egypt-new-kingdom" className="btn bg-ochre-500 text-white hover:bg-ochre-600">
              Explore New Kingdom Egypt <ArrowRight className="h-4 w-4" />
            </Link>
            <Link to="/method" className="btn border border-papyrus-50/25 text-papyrus-50 hover:bg-papyrus-50/10">
              How it works
            </Link>
          </div>
        </div>
      </section>

      <section className="container-page py-16">
        <div className="flex items-end justify-between gap-4">
          <div>
            <p className="eyebrow">Featured</p>
            <h2 className="mt-2 text-3xl font-bold sm:text-4xl">Life in New Kingdom Egypt</h2>
          </div>
          <Link
            to="/civilizations/egypt-new-kingdom"
            className="hidden shrink-0 text-sm font-medium text-lapis-600 hover:underline sm:block"
          >
            View all →
          </Link>
        </div>
        <div className="mt-8 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
          {featured.map((entry) => (
            <EntryCard key={entry.id} entry={entry} />
          ))}
        </div>
      </section>

      <section className="border-y border-ink-800/10 bg-papyrus-100/60 py-16">
        <div className="container-page">
          <p className="eyebrow">Civilizations</p>
          <h2 className="mt-2 text-3xl font-bold sm:text-4xl">Where we’re going</h2>
          <div className="mt-8 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {civilizations.map((civ) => {
              const published = civ.status === 'published';
              const content = (
                <>
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-xs text-ink-700">{civ.dateLabel}</span>
                    <span
                      className={`rounded-full px-2 py-0.5 text-[11px] font-medium ${
                        published ? 'bg-malachite-500/15 text-malachite-600' : 'bg-ink-800/5 text-ink-700'
                      }`}
                    >
                      {published ? 'Explore' : 'In research'}
                    </span>
                  </div>
                  <h3 className="mt-3 text-2xl font-semibold">{civ.name}</h3>
                  <p className="mt-1 text-xs text-ink-700">{civ.region}</p>
                  <p className="mt-3 text-sm leading-relaxed text-ink-700">{civ.blurb}</p>
                </>
              );
              return published ? (
                <Link
                  key={civ.id}
                  to={`/civilizations/${civ.id}`}
                  className="card p-5 transition-shadow hover:shadow-md"
                >
                  {content}
                </Link>
              ) : (
                <div key={civ.id} className="card p-5 opacity-90">
                  {content}
                </div>
              );
            })}
          </div>
        </div>
      </section>

      <section className="container-page py-16">
        <p className="eyebrow">The method</p>
        <h2 className="mt-2 text-3xl font-bold sm:text-4xl">Research first, pixels second</h2>
        <div className="mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map(({ icon: Icon, title, text }, i) => (
            <div key={title} className="card p-5">
              <div className="flex items-center gap-3">
                <span className="flex h-9 w-9 items-center justify-center rounded-full bg-lapis-600/10 text-lapis-600">
                  <Icon className="h-4 w-4" />
                </span>
                <span className="text-xs font-semibold text-ink-700">Step {i + 1}</span>
              </div>
              <h3 className="mt-4 text-xl font-semibold">{title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-ink-700">{text}</p>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
