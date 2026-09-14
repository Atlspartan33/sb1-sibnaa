# CLAUDE.md — Massey AI Solutions site

This file loads automatically at the start of every Claude Code session in this
repo. Keep it short and true. If a line stops being true, delete it.

## Who this is for

<!-- TODO(terrell): fill these in. This is the highest-value part of the file.
     Everything below is stack trivia; this part is what makes Claude useful. -->

- **Business:** Massey AI Solutions — AI consulting.
- **What we sell:** <!-- the 2-4 concrete offers, with rough price bands -->
- **Who we sell to:** <!-- ideal client profile: company size, role, trigger event -->
- **Who we do NOT sell to:** <!-- saying no is context too -->
- **Voice:** <!-- 3-5 adjectives + one sentence you'd actually publish, as a sample -->
- **Never say:** <!-- words/claims that are off-brand or legally risky -->

## This repo

Marketing site. Vite + React 18 + TypeScript + Tailwind. Originally scaffolded
in Bolt/StackBlitz (`.bolt/`), now edited here.

- `src/App.tsx` composes every section. Sections live in `src/components/`.
- `src/utils/cn.ts` is the only class-merging helper — use it, don't inline clsx.
- Icons: `lucide-react` only.
- Images: local files in `src/assets/`, or Unsplash URLs. Never download stock photos.
- No new UI/icon/theme packages without asking first.

## Design rules

Carried over from `.bolt/prompt`:

- Production-quality and distinctive, not template-looking.
- Fully featured sections — no lorem, no half-built states.
- Tailwind classes only; no CSS-in-JS, no new stylesheets.

## Known incomplete work

Don't "fix" these silently — they're known, and changing them is a decision:

- `src/components/NewsFeed.tsx` renders `mockNews`, a hardcoded array. No real feed.
- `src/components/Chatbot.tsx` has no backend — replies are local state only.
- `src/components/ContactForm.tsx` validates but does not submit anywhere.
- A Supabase connector is authorized on this account but nothing in this repo uses it.

## Working agreement

- Run `npm run lint` and `npm run build` before telling me a change is done.
- Explain tradeoffs in plain English, not jargon. I'll ask for detail if I want it.
- For anything touching more than ~2 files, plan first and let me approve.
- Small commits with real messages. Don't batch unrelated changes.
