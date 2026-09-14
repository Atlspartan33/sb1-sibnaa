# Four-Minute Floor

A yoga + meditation app built around one rule: **the floor is four minutes**, and a
four-minute day counts exactly as much as a twenty-minute day. The only number it
tracks is how *often* you get on the mat. There is deliberately no streak counter —
streaks punish the day you miss, and the day you miss is the day the habit actually
dies.

Live: https://claude.ai/artifact/Cbu3d1zc2AGBydHBjBJEcJ

## What it does

- **Move** — picks a sequence from a 38-pose library based on how the body feels today
  (stiff / tired / wired / fine) and how long you've got. Poses are held in *breaths*,
  not seconds, because that's the unit the practice runs on: one breath = six seconds,
  five breaths = thirty. The sequence is seeded by the date, so re-opening the page
  isn't a slot machine; `reroll` changes it on purpose.
- **Sit** — breath-paced meditation timer. Even 6s, long-exhale 12s, or box 16s. The ring
  paces the breath so there's something to follow instead of a blank countdown.
- **Log** — days on the mat, last 30 days, session history with how the body took it.
- **Voice cues** via the Web Speech API, so you can practise with your eyes shut.

## The AI parts

Two, both optional — the app works fully offline without either:

- **`sample`** — "Have Claude build today's sequence" sends your mood, your length, your
  last few sessions and a free-text note ("left hip is angry, slept badly") and gets back
  a sequence chosen from the library, with its own cues and a one-line note on why that
  shape today. Claude picks only from known pose ids, so it can't invent something unsafe;
  anything unrecognized is dropped and the offline sequence stands in.
- The closing line on the finish screen is generated from your actual log.

## Files

    yoga/mat.html     the app — artifact-shaped (no <!doctype>/<html>/<head>/<body>,
                      the Artifact host supplies those). This is the source of truth.
    yoga/build.mjs    wraps mat.html into a standalone page
    yoga/dist/        the standalone build — open dist/index.html from anywhere

    node yoga/build.mjs

## Extending it

The pose library is a flat array at the top of the first `<script>`. Each entry:

```js
{id, en, sk, breaths, cue, side?, group, load /*1-3*/, calm /*1-3*/}
```

`group` is one of `open spine stand hip twist fold back rest`. `MOODS` maps each mood to
an arc of groups plus an `ok(pose)` filter, and `buildSequence()` walks that arc as many
times as the time budget allows. Adding a pose means adding one object; adding a mood
means adding one entry to `MOODS`.
