---
name: site-ship-check
description: Pre-publish review of the Massey AI site before pushing changes live. Use when asked to "ship it", "is this ready", "check before I publish", or after finishing a batch of site edits. Runs the build, then reviews copy, responsiveness, and brand voice against CLAUDE.md.
---

# Ship check

Run this before anything goes live. Report results as a checklist — pass, fail,
or judgment call — and do not say "ready to ship" unless every line passes.

## 1. It builds

```
npm run lint
npm run build
```

Both must exit clean. A warning is not a pass — name it.

## 2. Nothing fake is user-visible

Grep the diff for: `mock`, `TODO`, `lorem`, `placeholder`, `#` as an `href`,
`example.com`. Cross-check against the "Known incomplete work" list in CLAUDE.md.
Pre-existing known stubs are fine. *New* ones are a fail.

## 3. It works small

Every section must hold up at 375px wide. Look for fixed pixel widths, `min-w-`
values wider than a phone, grids that don't collapse, text that overflows.

## 4. The copy sounds like us

Check new or changed copy against the Voice and Never-say lines in CLAUDE.md.

Good — specific, plain, earns the claim:
> We rebuilt their intake process around a single form. Response time went from
> four days to under one.

Bad — vague, inflated, could be any consultancy:
> We leverage cutting-edge AI solutions to unlock transformative business value
> and drive synergies across the enterprise.

Bad — a claim with no basis behind it:
> The industry-leading platform trusted by thousands.

## 5. Report

One short checklist. For each fail, say what's wrong and what you'd change —
don't fix it unless asked.
