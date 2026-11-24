# Animation Smoothness Plan

_Written 2026-11-24 by Claude Opus after on-device feedback that the pet cel animations don't feel smooth. Measured on `claude/integration-build` @ `ff5f1e2`._

**Owners:** **Codex** does the art (S1–S6, branch `codex/anim-smooth-art`). **Claude Opus** does the engine (E1–E6) and merges once the art lands.

## How it was measured

I downsampled every cel in `PawprintDays/Resources/PetFrames/` to 192², then measured, per bank:
- the **alpha centroid x** (how far the body slides inside a walk-in-place cycle),
- the **foot baseline** (lowest opaque row) and the **head top**,
- the **mean absolute alpha difference** between consecutive drawings ("step"), and between the last and first drawing of a loop ("seam").

An even cycle has steps of roughly the same size and a seam about the same as a normal step. A step 2–3× the median shows up as a pop or hitch.

Foot baselines are **fine**: every bank sits on y = 688 px. The problems are the spacing, the drawing count, the timing and some missing banks.

## Findings: art

| # | Problem | Evidence | What it looks like |
|---|---|---|---|
| F1 | **Frozen idle for pet_01–04.** All 16 `i` drawings are pixel-identical (step = 0.0). `h`, `m` and `s` barely move (step 0.1–1.0). | `pet_01..04_i` steps `0,0,0,…` | The pet looks like a still sticker, then pops when another clip starts. Pets 05–08 breathe properly (step 1–2). |
| F2 | **Uneven walk spacing.** Some in-betweens are missing or doubled. | `pet_02_w` 7→27 · `pet_04_w` 6→23 · `pet_04_wr` 7→22 · `pet_06_w` 29 at 5→6 · `pet_08_wr` 35 at 2→3 and 28 at 5→6 · `pet_05_w` 7→22 | A limp or stutter once per cycle. |
| F3 | **Body surges inside the walk-in-place cycle.** The centroid wanders horizontally. | Centroid range: `pet_02_w` 38 px · `pet_01_w` 23 · `pet_07_w` 19 · `pet_04_wr` 17 (normal ≤ 8 px at 768²) | The body rocks forward and back while it slides across the floor, so it reads as skating. |
| F4 | **Too few walk drawings.** | `pet_03_w` and `pet_05_w` have 6 drawings at 9 fps | Choppy left-facing walks. |
| F5 | **Loop seam hitches.** | Seam vs mean step: `pet_01_w` 11 vs 7 · `pet_07_w` 10 vs 5 · `pet_03_w` 19 vs 12 | A hiccup every time the cycle wraps. |
| F6 | **Turns pop.** `tn` has only 5 drawings, and the middle steps are huge. pet_01/02/05/06/07 have no `tn` or `wr` at all, so the engine mirrors the sprite with a squash flip. | `pet_03_tn` 20,**57**,25,19 · `pet_04_tn` 34,**60**,**56**,32 · `pet_08_tn` 43,**57**,**65**,23 | A snap through the 3/4 view, or a paper-flip squash. |
| F7 | **Missing transition banks.** No pet has `ld` (lie down), `wk` (wake) or `r` (startle), although `CelPoseTransition` looks them up. | `grep '"ld"\|"wk"\|"r"'` → 0 | Idle ↔ sleep and startle cut instead of animating. |
| F8 | **Frame rates that don't divide the display refresh.** | 9, 7, 7.5, 8.5 and 3.2 fps are used. On a 60/120 Hz screen, frames are held for an uneven 6/7 or 13/14 refreshes. | A subtle irregular cadence (judder), even when the drawings are perfect. |
| F9 | **No stride data.** No manifest has `strideLengthUV`. | `grep strideLengthUV manifests/pet_0*.json` → none | The engine falls back to an ease-in/out slide under a constant-speed gait, so the feet skate at the start and end of every walk. |

## Findings: engine (Claude fixes these after the art lands)

| # | Problem | Where |
|---|---|---|
| E1 | The decoded-frame cache key includes `displayPixels`, which is multiplied by the depth `presentationScale`. When a pet walks toward or away from the camera, the 64-px bucket changes, every frame misses the cache, and `CelFrameImage` holds the previous drawing until the decode finishes. That is a visible stutter on depth walks. | `PlaceholderAssetGenerator.swift:389`, `CelFrameImageCache.Key` |
| E2 | The pet rig samples its own clock at **30 Hz**, while the stage moves the pet at 60 Hz. A 12 fps clip on a 30 Hz clock alternates 2- and 3-tick holds. | `PlaceholderAssetGenerator.swift:62` |
| E3 | Without stride data, walks use an ease-in/out position curve (see F9). Use linear travel matched to the stride, with acceleration only inside the `tu`/`td` transitions. | `SunroomRoamingEngine.interpolatedPosition` |
| E4 | Facing flips animate `scaleEffect(x:)` through zero with `.easeInOut(0.16)`. That causes a squash on pets without a turn bank. | `PlaceholderAssetGenerator.swift` `.animation(…, value: mirror)` |
| E5 | `CelFrameImage` falls back to the last image on a miss, which can be a drawing from the *previous clip*. The preloader should also warm the target clip at the new depth bucket before the transition. | `CelFrameImageCache.swift` |
| E6 | Wire `ld`, `wk` and `r`, plus stride metadata, once the art provides them. Turn on the 120 Hz ProMotion cadence (`CADisableMinimumFrameDurationOnPhone`) if it isn't already on. | engine and Info.plist |

## Art tasks (Codex)

Follow the AI art procedure and the reject-on-sight rules in `docs/ANIMATION_PLAN.md` (keys first, then in-betweens from the keys, never from text alone; same markings, toes and horn sides on every frame). Work only in `art-src/**`, `PawprintDays/Resources/PetFrames/**` and `tools/frames/**`.

- **S0 · Tooling first.** Add `tools/frames/smoothness` (Swift, like `build.swift`). For each bank it prints the step list, seam, centroid range and baseline range, and it exits non-zero if a loop has max step > 1.8 × median, seam > 1.5 × median, side-walk centroid range > 10 px at 768², idle max step < 0.5 (frozen), or fps not in {3, 4, 5, 6, 8, 10, 12, 15, 24}. Commit a baseline report before you change any art, so improvements are measurable.
- **S1 · Idle for pet_01–04 (F1).** Paint a real 16-drawing breathing idle that matches the motion range of pets 05–08 (chest rise, tail drift, one blink on drawing 14). Give `h`, `m` and `s` for pet_01–04 visible motion too.
- **S2 · Even walks (F2, F3, F5).** Re-space `pet_02_w`, `pet_04_w`, `pet_04_wr`, `pet_06_w`, `pet_08_wr` and `pet_05_w`. Repaint or insert in-betweens where a step spikes. Re-register every walk cycle so the torso stays within ±5 px horizontally (the walk is in place; the engine does the travel). Make the last drawing lead cleanly into drawing 1.
- **S3 · More walk drawings (F4).** Bring `pet_03_w` and `pet_05_w` to 12 drawings.
- **S4 · Turns (F6).** Repaint `tn` for pet_03/04/08 as 8 drawings with eased spacing (slow out, slow in). Add `wr` (12 drawings) and `tn` (8 drawings) for pet_01, 02, 05, 06 and 07, so no pet relies on a mirror flip.
- **S5 · Transitions (F7).** Paint `ld` (stand or sit → curled sleep, 8 drawings, `next: "sleep"`), `wk` (sleep → sit, 8 drawings, `next: "idle"`) and `r` (startle hop-back, 6 drawings, `next: "idle"`) for all 8 pets. Add them to the manifests as `loop: "once"`.
- **S6 · Timing and stride (F8, F9).** Retime the manifests so every fps is in {3, 4, 5, 6, 8, 10, 12, 15, 24}, and use `holds` for acting beats instead of odd fps (for example walk 12, idle 8 with holds, sleep 4, happy/mouth/play 10). For each walk bank, measure the foot travel of one full cycle (planted-foot slide distance in px at the pet's rendered size) and record `strideLengthUV` in the clip, following `manifests/schema.json`. Note the measuring method in `art-src/design/stride.md`.

**Done when:** `tools/frames/smoothness` and `tools/frames/lint` pass for every bank you touched (head-height false positives on horned or antlered pets are known and may stay); the contact sheets and GIFs for each changed bank are in `art-src/previews/`; `xcodebuild test` passes; and the Animation Gallery (Debug menu) shows each new clip playing.
