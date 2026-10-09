import { Link } from 'react-router-dom';
import { BookOpenCheck, FileSearch, ScanEye, ShieldCheck } from 'lucide-react';
import { getEntry } from '../data';
import type { Entry } from '../types';
import EntryCard from '../components/EntryCard';
import GlobeExplorer from '../components/GlobeExplorer';

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
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(208,138,60,0.25),transparent_55%),radial-gradient(ellipse_at_bottom_left,rgba(47,79,143,0.4),transparent_55%)]" />
        <div className="container-page relative py-10 sm:py-14">
          <div className="max-w-3xl">
            <p className="eyebrow text-ochre-400">Evidence-based reconstructions</p>
            <h1 className="mt-3 text-4xl font-bold leading-[1.05] text-papyrus-50 sm:text-5xl">
              Spin the globe. See the people of the past as they really were.
            </h1>
            <p className="mt-4 text-base leading-relaxed text-papyrus-100/85 sm:text-lg">
              Photorealistic reconstructions built from archaeology rather than Hollywood. Drag the globe, travel
              through time, and select a civilization to explore it.
            </p>
          </div>
          <div className="mt-8">
            <GlobeExplorer />
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
