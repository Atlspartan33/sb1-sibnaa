/** How well a detail is supported by evidence. */
export type Confidence = 'high' | 'medium' | 'low';

export type EntryType = 'portrait' | 'attire' | 'daily-life' | 'place' | 'moment';

export type AspectRatio = '1:1' | '3:2' | '2:3' | '16:9';

export type SourceKind = 'site' | 'artifact' | 'text' | 'study' | 'book' | 'project';

export interface Source {
  id: string;
  title: string;
  kind: SourceKind;
  author?: string;
  year?: string;
  url?: string;
  note?: string;
}

/** A single visual claim, tied to the evidence that supports it. */
export interface EvidencedDetail {
  detail: string;
  confidence: Confidence;
  sourceIds: string[];
}

/**
 * The structured, research-backed description of an image.
 * Image prompts are built from this, never written by hand, so every
 * visual decision traces back to evidence.
 */
export interface SceneSpec {
  culture: string;
  region: string;
  /** Years as integers; negative numbers are BCE. */
  period: { start: number; end: number };
  subject: string;
  setting: string;
  composition: string;
  lighting: string;
  appearance: EvidencedDetail[];
  attire: EvidencedDetail[];
  environment: EvidencedDetail[];
  /** Stereotypes and anachronisms the image must not contain. */
  avoid: string[];
  aspectRatio: AspectRatio;
}

export interface MythVsReality {
  myth: string;
  reality: string;
  sourceIds: string[];
}

export interface GeneratedImage {
  /** Path under /public, e.g. "/images/egypt-new-kingdom/deir-el-medina-workman-1.webp". */
  src: string;
  alt: string;
  model: string;
  generatedAt: string;
  reviewedBy?: string;
}

export interface Entry {
  id: string;
  civilizationId: string;
  type: EntryType;
  title: string;
  dateLabel: string;
  summary: string;
  spec: SceneSpec;
  mythsVsReality: MythVsReality[];
  images: GeneratedImage[];
}

export type CivilizationStatus = 'published' | 'in-research';

export interface Civilization {
  id: string;
  name: string;
  era: string;
  region: string;
  dateLabel: string;
  status: CivilizationStatus;
  blurb: string;
  /** Shown on in-research civilizations: what has to happen before images are made. */
  researchNote?: string;
}
