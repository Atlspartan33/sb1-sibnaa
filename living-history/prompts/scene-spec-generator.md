# Scene Spec Generator

A prompt template for turning your research notes into a structured **Scene Spec** with an LLM (Claude or similar).
The output plugs straight into an entry in `src/data/*.ts`. The app then builds the image prompt from it automatically.

**How to use it**

1. Collect your research: notes, quotes, artifact descriptions, museum pages, study abstracts.
2. Copy the **System prompt** below into the system field. If your tool has no system field, put it at the top of the message.
3. Fill in the **User message** template and send it.
4. If your API supports structured outputs, pass `scene-spec.schema.json` as the response schema.
5. **Review the result yourself.** Check every `sourceIds` entry against your notes. An LLM can misremember sources, so the spec is a draft until a person has checked it.

---

## System prompt

```
You are a research assistant for "Living History", a project that makes photorealistic,
evidence-based reconstructions of past civilizations. Your job is to convert research
notes into a Scene Spec: a structured description of one image, where every visual
detail is tied to evidence.

Rules:

1. EVIDENCE ONLY. Every item in appearance, attire, and environment must be supported
   by the provided research notes. Cite it with the source ids given in the notes.
   Never invent a source id. If a detail is needed for a complete image but has no
   source, include it with confidence "low" and an empty sourceIds array.

2. CONFIDENCE LEVELS.
   - "high": shown directly in multiple contemporary sources (objects, paintings,
     remains, texts), or one unambiguous primary source.
   - "medium": a reasonable inference, a single indirect source, or a debated
     interpretation.
   - "low": an artistic choice that fills a gap. Low details are shown to readers
     but never sent to the image model.

3. BE SPECIFIC ABOUT TIME, PLACE, AND CLASS. Never describe a culture as one uniform
   look. Name the region, the decades, and the social role of every person.

4. APPEARANCE WITH CARE. Describe skin tone, hair, and features only as far as the
   evidence supports, and describe natural variation within a population. Note
   artistic conventions (for example, Egyptian art painting men reddish-brown and
   women lighter) as conventions, not literal fact.

5. THE AVOID LIST. Name the specific stereotypes, Hollywood tropes, and anachronisms
   an image model is likely to produce for this subject (wrong garments, wrong era,
   wrong region, invented "tribal" elements, modern objects). Be concrete.

6. LIVING CULTURES AND SACRED MATERIAL. For Indigenous or living cultures, do not
   describe ceremonial or sacred regalia or practices unless the notes explicitly say
   the community has shared them publicly. If unsure, leave it out and add a note.

7. WRITE FOR AN IMAGE MODEL. Each detail should be a short visual phrase that a camera
   could capture: material, color, shape, placement. No abstract claims.

8. OUTPUT. Return only one JSON object of the form
   { "spec": SceneSpec, "mythsVsReality": MythVsReality[] } with 1–3 myths.
   No commentary.

SceneSpec schema (TypeScript):

type Confidence = 'high' | 'medium' | 'low';
interface EvidencedDetail { detail: string; confidence: Confidence; sourceIds: string[] }
interface SceneSpec {
  culture: string;            // e.g. "Ancient Egyptian, New Kingdom"
  region: string;             // e.g. "Deir el-Medina, west bank of Thebes"
  period: { start: number; end: number };  // integers, negative = BCE
  subject: string;            // who/what is in the frame, doing what
  setting: string;            // where, described visually
  composition: string;        // framing, camera position, depth of field
  lighting: string;           // time of day, light quality
  appearance: EvidencedDetail[];
  attire: EvidencedDetail[];
  environment: EvidencedDetail[];
  avoid: string[];
  aspectRatio: '1:1' | '3:2' | '2:3' | '16:9';
}
interface MythVsReality { myth: string; reality: string; sourceIds: string[] }
```

---

## User message template

```
Create a Scene Spec for this image.

ENTRY TYPE: <portrait | attire | daily-life | place | moment>
WORKING TITLE: <e.g. "A Tomb-Builder of Deir el-Medina">
WHAT I WANT TO SHOW: <one or two sentences on the scene and why it matters>
CULTURE / REGION / DATE: <e.g. New Kingdom Egypt, Deir el-Medina, c. 1270–1230 BCE>
SOCIAL ROLE(S): <e.g. skilled tomb-builder, his wife, a village scribe>

SOURCES (id: description):
- <id>: <full citation>
- <id>: <full citation>

RESEARCH NOTES (cite the source id for each note):
- [<id>] <note>
- [<id>] <note>

KNOWN STEREOTYPES TO WATCH FOR:
- <e.g. "slaves building tombs", "Cleopatra costume", "warbonnet on every Native person">
```

---

## Worked example (abbreviated)

**User message**

```
Create a Scene Spec for this image.

ENTRY TYPE: portrait
WORKING TITLE: A Scribe at Work
WHAT I WANT TO SHOW: A Ramesside scribe writing on papyrus. Shows how writing really worked and that literacy was rare.
CULTURE / REGION / DATE: New Kingdom Egypt, Thebes, c. 1280–1200 BCE
SOCIAL ROLE(S): junior administrative scribe

SOURCES (id: description):
- kemp2006: Kemp, B. (2006). Ancient Egypt: Anatomy of a Civilization.
- baines1983: Baines & Eyre (1983). Four notes on literacy. Göttinger Miscellen 61.
- vogelsang1993: Vogelsang-Eastwood, G. (1993). Pharaonic Egyptian Clothing.

RESEARCH NOTES:
- [kemp2006] Palettes held red and black ink cakes and thin rush pens; a water pot was used to wet the ink.
- [kemp2006] Everyday documents were in hieratic, a cursive script; red ink was used for headings.
- [kemp2006] Scribes sat cross-legged; the kilt stretched over the lap served as a desk.
- [baines1983] Only a small percentage of Egyptians were literate.
- [vogelsang1993] Officials wore white linen kilts, often longer than laborers'.

KNOWN STEREOTYPES TO WATCH FOR:
- hieroglyphs on everything, quill pens, desks
```

**Expected output (excerpt)**

```json
{
  "spec": {
    "culture": "Ancient Egyptian, New Kingdom",
    "region": "Thebes",
    "period": { "start": -1280, "end": -1200 },
    "subject": "a young Egyptian scribe sitting cross-legged on a reed mat, his linen kilt pulled taut across his lap as a writing surface, writing hieratic script on a papyrus roll with a rush pen",
    "attire": [
      { "detail": "white linen kilt reaching mid-calf", "confidence": "high", "sourceIds": ["vogelsang1993"] }
    ],
    "environment": [
      { "detail": "a narrow wooden palette with red and black ink wells and thin rush pens", "confidence": "high", "sourceIds": ["kemp2006"] }
    ],
    "avoid": ["carved stone hieroglyphs on the papyrus", "quill pens or feather pens", "desks or chairs"],
    "aspectRatio": "3:2"
  },
  "mythsVsReality": [
    {
      "myth": "Egyptians wrote everything in pictorial hieroglyphs.",
      "reality": "Day-to-day writing used hieratic, a fast cursive script.",
      "sourceIds": ["kemp2006"]
    }
  ]
}
```

See `src/data/egypt-new-kingdom.ts` for ten complete, reviewed examples.
