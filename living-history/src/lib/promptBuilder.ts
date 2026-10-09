import type { EvidencedDetail, SceneSpec } from '../types';
import { formatYear } from './format';

export interface ImagePrompt {
  prompt: string;
  negativePrompt: string;
  aspectRatio: SceneSpec['aspectRatio'];
}

const STYLE =
  'Photorealistic documentary photograph, historically accurate reconstruction, ' +
  'natural skin texture and real fabric detail, shot on a full-frame camera with a 35mm lens, ' +
  'no text, no captions, no watermark.';

/** Generic failure modes of image models on historical subjects, added to every negative prompt. */
const BASE_NEGATIVE = [
  'fantasy costume',
  'Hollywood epic film styling',
  'modern clothing, zippers, or synthetic fabrics',
  'modern buildings, power lines, or vehicles',
  'glossy plastic skin',
  'text, letters, or watermark',
];

// Low-confidence details stay out of the prompt so the model doesn't render speculation as fact.
function usable(details: EvidencedDetail[]): string[] {
  return details.filter((d) => d.confidence !== 'low').map((d) => d.detail);
}

export function buildImagePrompt(spec: SceneSpec): ImagePrompt {
  const when =
    spec.period.start === spec.period.end
      ? formatYear(spec.period.start)
      : `${formatYear(spec.period.start)}–${formatYear(spec.period.end)}`;

  const sections = [
    STYLE,
    `Subject: ${spec.subject}.`,
    `Culture and time: ${spec.culture}, ${spec.region}, ${when}.`,
    `Setting: ${spec.setting}.`,
    `People: ${usable(spec.appearance).join('; ')}.`,
    `Clothing and adornment: ${usable(spec.attire).join('; ')}.`,
    `Environment and objects: ${usable(spec.environment).join('; ')}.`,
    `Composition: ${spec.composition}.`,
    `Lighting: ${spec.lighting}.`,
  ];

  return {
    prompt: sections.join('\n'),
    negativePrompt: [...spec.avoid, ...BASE_NEGATIVE].join(', '),
    aspectRatio: spec.aspectRatio,
  };
}

/** Single-string form for image models that take no separate negative prompt. */
export function buildCombinedPrompt(spec: SceneSpec): string {
  const { prompt, aspectRatio } = buildImagePrompt(spec);
  // Semicolons, because individual avoid items contain commas.
  const avoid = [...spec.avoid, ...BASE_NEGATIVE].join('; ');
  return `${prompt}\nAspect ratio: ${aspectRatio}.\nDo NOT include: ${avoid}.`;
}
