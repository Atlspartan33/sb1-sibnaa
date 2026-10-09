# Living History

Photorealistic, **evidence-based** AI reconstructions of how people in past civilizations looked, dressed, and lived.

Image models default to Hollywood: pale actors in eyeliner, or a Plains warbonnet on every Native American.
Living History puts a research step between the question and the image. Every image comes from a structured
**Scene Spec** in which each visual detail cites its sources and carries a confidence level. The app shows readers
that evidence next to the image.

## Run it

```bash
cd living-history
npm install
npm run dev        # http://localhost:5173
npm run build      # typecheck + production build
npm run lint
```

## Deploy

- **Your own domain:** connect the repo to Netlify with base directory `living-history`. `netlify.toml` sets the
  build and the single-page-app redirect. Any static host works the same way: build with `npm run build` and serve
  `dist/` with all routes falling back to `index.html`.
- **Static hosts without route fallbacks:** `npm run build:static` outputs `dist-static/` with relative asset paths
  and hash URLs (`#/entries/...`), so it runs from any folder.

## Pages

| Route | What it is |
| --- | --- |
| `/` | Globe explorer: drag to spin, a time slider that highlights civilizations alive in a given year, click a marker to open its panel. Then featured entries and how it works |
| `/civilizations/:id` | Timeline, type filters, and grid of entries |
| `/entries/:id` | The image, evidence with confidence badges and citations, myth vs. reality, sources, and the generated prompt |
| `/method` | Pipeline, confidence levels, and ethics commitments |
| `/studio` | Generation queue: copyable prompts for every entry, with image status |

## How the pipeline works

```
Research notes ──► Scene Spec (LLM-drafted, human-reviewed) ──► Image prompt (automatic)
      ──► Image model (several variants) ──► Review against the evidence ──► Publish
```

1. **Research.** Gather sources and add them to `src/data/sources.ts`.
2. **Draft a Scene Spec.** Use the prompt in [`prompts/scene-spec-generator.md`](prompts/scene-spec-generator.md)
   (with [`prompts/scene-spec.schema.json`](prompts/scene-spec.schema.json) for structured output). Check every
   citation yourself.
3. **Add the entry.** Put it in a data file such as `src/data/egypt-new-kingdom.ts`.
4. **Generate.** Open `/studio`, copy the prompt, and run it through your image model. `buildImagePrompt` in
   `src/lib/promptBuilder.ts` leaves out low-confidence details and merges the spec's `avoid` list with general
   negatives.
5. **Publish.** Save the chosen image to `public/images/<civilization-id>/` and add it to the entry's `images`
   array:

   ```ts
   images: [
     {
       src: '/images/egypt-new-kingdom/deir-el-medina-tomb-builder-1.webp',
       alt: 'A tomb-builder standing in a village doorway holding a chisel and mallet',
       model: '<image model name>',
       generatedAt: '2026-10-09',
       reviewedBy: '<your name>',
     },
   ],
   ```

## Project structure

```
src/
  types.ts                 SceneSpec, Entry, Civilization, Source types
  data/
    sources.ts             shared source registry (cited by id)
    civilizations.ts       civilizations with globe coordinates and date ranges
    egypt-new-kingdom.ts   10 research-backed Scene Specs
    index.ts               lookups
  lib/promptBuilder.ts     Scene Spec → image prompt + negative prompt
  components/Globe.tsx     orthographic SVG globe (d3-geo + world-atlas), drag, fly-to, markers
  components/GlobeExplorer.tsx  globe + time slider + civilization panel
  pages/                   Home, Civilization, Entry, Method, Studio
  components/              cards, badges, image frame, source list, prompt panel
prompts/
  scene-spec-generator.md  LLM prompt template for drafting Scene Specs
  scene-spec.schema.json   JSON Schema for structured output
```

## Adding a civilization to the globe

Add an object to `src/data/civilizations.ts` with `location` (lat/lng of its center or capital) and `period`
(start/end years, negative = BCE). It appears on the globe and in the time slider automatically. Set `status:
'published'` once it has reviewed entries.

## Content so far: New Kingdom Egypt (c. 1550–1070 BCE)

1. A Tomb-Builder of Deir el-Medina (portrait)
2. A Noblewoman at a Theban Banquet (portrait)
3. Linen Across the Classes (attire study)
4. The Great Hypostyle Hall of Karnak, in Full Color (place)
5. Market Day at the Theban Riverbank (daily life)
6. Harvest Time in the Theban Fields (daily life)
7. A Scribe at Work (portrait)
8. The Opet Festival Procession (historic moment)
9. A Nubian Prince at the Court of Tutankhamun (portrait)
10. The First Recorded Strike in History (historic moment)

These are well-researched drafts, not peer-reviewed content. Have an Egyptologist check them before you present
them publicly as authoritative.

## Roadmap

- **Phase 1 (now):** Egypt MVP. Generate and review images for the 10 entries.
- **Phase 2:** Native nations, built with advisors from each nation (Cahokia, Haudenosaunee, and others), plus an
  admin tool that runs the full pipeline (LLM spec drafting → image API → review queue). API keys go in a server or
  edge function, never in the browser.
- **Phase 3:** Map explorer, "A day in the life" story sequences, then-vs-now sliders, narration, and a classroom mode.

## Ground rules

- Every image carries a visible **AI reconstruction** label.
- Name the specific time, place, and social group. Never show a culture as a single uniform look.
- For Indigenous and other living cultures, descendant communities lead: no ceremonial or sacred items without their
  approval.
