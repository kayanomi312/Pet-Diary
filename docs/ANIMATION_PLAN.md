# Pawprint Days — Animation Improvement Plan

_Written 2026-11-23 for **Codex (GPT-6.2 Sol)** and **Antigravity (Gemini 4 Hydrogen)**. Both can make art; Codex also owns the code. Claude Opus reviews and merges (see the collision rules in `docs/IMPROVEMENT_PLAN.md` §2)._

---

## 0. How the animation works today (read this first)

- **Character animation** is hand-painted watercolor cel frames, drawn by `ProceduralPetRigView` in `PawprintDays/Art/PlaceholderAssetGenerator.swift`. Despite the name, it doesn't generate anything procedurally. It picks a frame name from a timeline.
- Frames live in `PawprintDays/Resources/PetFrames/pet_XX_<bank><n>.heic` (folder reference), plus 6 keyframes per pet in `Assets.xcassets/pet_XX_fN.imageset` (512 px PNG; `f2` = blink, `f6` = curled nap).
- Banks per pet (8 pets: `pet_01`…`pet_08`):

  | Bank | Frames | Used for | Playback rate in code |
  |---|---|---|---|
  | `w` walk | 16 | Sunroom roaming | 9 fps |
  | `i` idle (sitting) | 16 | Default loop, ending on `f2` blinks | 5.2 fps |
  | `h` happy | 10 | Petting, excitement, bits of the idle loop | ~7 fps |
  | `m` mouth (vocal/munch) | 8 | Eating, vocalizing | ~7.5 fps |
  | `p` paw/play | 8 | Belly-boop, pounce, ball play | ~8.5 fps |
  | `s` sleep | 12 (ping-pong) | Napping | 3.2 fps |

- **Clip selection** is a long hand-coded `switch` in `resolveCelFrameState(time:minDim:)` (lines ~138–332). Frame rates, durations and bank sequences are magic numbers, and the doc comments above it are out of date (they say `w1..w12`, `i1..i8`, …).
- **Motion in the world** (the pet's position, hop arcs, shadows) is applied in code with `.offset`/`.scaleEffect`. Sunroom roaming is `SunroomRoamingEngine` (ease-in-out lerp; `facingRight` mirrors the sprite using `scaleEffect(x: -1)`).
- **Props, weather and UI** are procedural SwiftUI/Canvas inside ~10 `TimelineView`s (`StorybookPropArt.swift`, `DiegeticProps.swift`, `Sunroom25DStage.swift` overlays, `LiveTouchSparkleLayer`). There are 173 `withAnimation`/`.animation`/`.transition` call sites with 72 hand-tuned `spring(...)`s and no shared motion tokens.
- **Furniture (`goodie_*`) and the room background** are static PNGs.

### Audit findings (measured, not guessed)

| # | Problem | Evidence | Visible effect |
|---|---|---|---|
| F1 | **Walk cycles are mostly held frames** | Unique drawings among the 16 `w` frames: pet_02 **6**, pet_03 **6**, pet_04 **3**, pet_05 **6**, pet_06 **4** (01/07/08 have 16) | Five pets "skate" across the floor with a 3–6 drawing shuffle |
| F2 | **Mixed canvas sizes** | `w` frames for 02–06 are **512²**; every other bank (and all banks of 01/07/08) is **320²**; the `f` keyframes are 512² | Pet changes size and jumps when switching between walk and idle. For example, pet_04 is 74% of canvas height while idling and 63% while walking |
| F3 | **Inconsistent baseline / registration** | Paw baseline: 320-frames at y≈292/320 (0.913), 512-frames at y≈455/512 (0.889). Per-pet bbox heights also differ by bank | Feet slide or pop on every clip change. The neck anchor for outfits (`calibratedNeckAnchor`) drifts |
| F4 | **Upscaled frames** | Encounter view draws the pet at 215 pt ≈ **645 px** on 3× devices, but most frames are 320 px | Soft/blurry pet in the hero moment (encounter, care) |
| F5 | **No transition clips** | Idle→walk, walk→sit, sit→nap and wake-up cut instantly (nap only shows the `f2` blink for 0.45 s) | Popping: the pet teleports between poses |
| F6 | **No turn, and the mirror flips asymmetric art** | Facing is `scaleEffect(x:-1)` with a 0.16 s ease. Idle is a 3/4 sitting view | Squash-flip "paper turn"; markings, wings and lighting swap sides |
| F7 | **Depth movement is side-on only** | Roaming moves in room depth (`y` 0.14–0.86), but only side-walk art exists | Pet walking "into" the room looks like it moonwalks |
| F8 | **Bank reuse hides missing acting** | Eating = vocal bank `m`; greeting = belly-boop; ball play = `p` + `m` + `h` sliced together by timers | Generic, samey reactions |
| F9 | **Decode/cache thrash** | `CelFrameImageCache` is 40 MB, ≈40 decoded 512² frames. 3 roaming pets × (16 walk + 16 idle) needs ~96 frames. Decoding is synchronous HEIC on the main thread, and every pet has its own 30 Hz `TimelineView` inside the 60 Hz stage `TimelineView` | Hitches when the clip changes, and battery drain |
| F10 | **No secondary / prop motion on furniture, FX as SF Symbols** | `goodie_*` are static. Floor ripples and bursts use `pawprint.fill` / text glyphs | The room feels static, and the effects break the watercolor style |

---

## 1. Target spec (everyone follows this)

### 1.1 Frame format — "Cel Spec v2"
- **Canvas:** 768 × 768 px, transparent background, sRGB, straight alpha, no matte/halo (check on black *and* white).
- **Registration:** ground/paw baseline at **y = 690 px** (0.898). The character's body center is at x = 384 when standing still. Locomotion clips are drawn **in place**, because the code moves the pet.
- **Scale:** the sitting idle `i1` defines the scale: the top of the head (not the ears/horns) sits at y = 170 px ± 6. Every other bank must match it. Tolerance: the bbox height of the same body part may vary by ≤ 3% within a pet.
- **Facing:** side clips face **left** (as today). Asymmetric pets (wings, single markings: pet_03, pet_04, pet_08) get a separately drawn **right-facing** set of `w`/`turn` clips instead of mirroring (see A2.3).
- **Light:** soft window light from upper **left**. Same watercolor paper texture, line weight and palette as the existing `f1` for that pet. **The existing `f1`–`f6` are the character model sheet. Never redesign the pet.**
- **Delivery:** export PNG to `art-src/petframes/pet_XX/<bank>/NN.png` (source of truth, Git LFS). The pipeline (A0.1) converts it to HEIC for the app bundle.

### 1.2 Animation principles to enforce
- **On ones for fast action, on twos for calm.** Walk ≥ 8 *unique* drawings per cycle (12 preferred). Idle breathing ≥ 8 unique. Holds must be authored in the manifest, never by duplicating files.
- **Loops must close:** the last frame should flow into the first without a pop (lint compares the diff between frame N→1 against the average frame-to-frame diff).
- Anticipation → action → follow-through / settle on every one-shot (pounce, hop, eat, startle).
- Secondary motion (tail, ears, wings, cheek fluff) overlaps the primary motion by 1–2 frames, so it doesn't move in lockstep.
- Contact frames in walk cycles must land when the code's dust puff spawns (the manifest marks `events: { "footContact": [1, 7] }`).

### 1.3 Manifest (data-driven playback)
Per pet: `PawprintDays/Resources/PetFrames/manifests/pet_XX.json` (one file per pet, so parallel art branches never conflict):

```json
{
  "pet": "pet_03",
  "spec": 2,
  "clips": {
    "walk":      { "bank": "w",  "frames": 12, "fps": 12, "loop": "loop",     "events": { "footContact": [1, 7] } },
    "idle":      { "bank": "i",  "frames": 16, "fps": 8,  "loop": "loop",     "holds": { "1": 3 } },
    "sit_to_stand": { "bank": "tu", "frames": 6, "fps": 12, "loop": "once", "next": "walk" },
    "sleep":     { "bank": "s",  "frames": 12, "fps": 4,  "loop": "pingpong" }
  },
  "anchors": { "neck": [0.42, 0.50, 0.21] }
}
```

The neck anchor moves out of `calibratedNeckAnchor` and into the manifest, and can be overridden per clip.

---

## 2. Work packages

**Owners:** **CX** = Codex (Sol, high effort), **GH** = Gemini 4 Hydrogen (Antigravity), **GF** = Gemini Flash, **OP** = Claude Opus (review/merge).
Both CX and GH make art. Codex's weekly quota refreshed on 2026-11-24, so **Codex now owns all the code plus about half the art**, split by pet or clip so the two never touch the same files. Gemini keeps art direction, the hardest acting clips, and all simulator QA. If Codex runs low on quota again, its art rows go back to GH; its code rows stay with Codex.

### Phase A0 — Pipeline & tooling (blocks everything) · ~2 days
| # | Task | Owner | Files owned | Done when |
|---|---|---|---|---|
| A0.1 | **Frame pipeline script** `tools/frames/build.swift` (or Python with `-I`): reads `art-src/petframes/**.png`, validates against Cel Spec v2, writes `Resources/PetFrames/*.heic` (quality 0.8) and an updated manifest stub | CX | `tools/frames/**`, `art-src/README.md` | Running it on a converted pet reproduces a valid bundle |
| A0.2 | **Frame lint** (`tools/frames/lint`): canvas size, alpha halo, baseline ±3 px, head-height ±3%, unique-drawings-per-clip ≥ spec, duplicate-file detection (md5), loop-closure diff, missing/extra frames vs manifest. Runs in CI | CX | `tools/frames/**`, CI workflow | Current assets produce a report that reproduces F1–F3 |
| A0.3 | **Contact sheets + GIF/APNG previews**: per pet per clip, with an **onion-skin** overlay (prev/next at 30% alpha) and the baseline/head guide lines drawn on top. Output in `art-src/previews/` (git-ignored) | CX | `tools/frames/**` | Art agents can review a clip without building the app |
| A0.4 | **Normalize existing frames** (no redraw): upscale all banks to 768² with a high-quality upscaler that preserves the paper texture, re-register to the baseline/scale spec, and remove the duplicate `w` files (recording holds in the manifest instead). This is a stop-gap until A1 lands | CX (pipeline + rescaling), GH approves visually | `art-src/petframes/**`, `Resources/PetFrames/**` | Lint passes for scale/baseline on all 8 pets. No visible size pop between walk and idle on device |
| A0.5 | **In-app Animation Gallery** (DEBUG only): every pet × clip, speed slider (0.25×–2×), frame stepper, onion-skin toggle, mirrored toggle, background picker (sunroom floor / street / white / black), outfit toggle to check the neck anchor | CX | `Views/Debug/AnimationGalleryView.swift` | Reachable from a debug menu. Used by GH for every QA screenshot/video |

### Phase A1 — Fix the existing banks (highest player-visible win) · ~1 week
Art packages are **one branch per pet** (`gemini/anim-pet03-walk`, `codex/anim-pet06-walk`), touching only that pet's `art-src/petframes/pet_XX/**` and `manifests/pet_XX.json`.

| # | Task | Owner | Done when |
|---|---|---|---|
| A1.1 | **Redraw walk cycles** for pet_04 (3 unique), pet_06 (4), pet_02/03/05 (6): 12 unique drawings, in place, contact/passing/down/up poses each side. Winged pets (03, 04) get a wing beat that offsets from the stride; the dragon tail (03) and tail flame/fluff follow through by 2 frames | CX: 02, 04, 06 · GH: 03, 05 (the winged and dragon-tail ones) | Lint shows ≥ 12 unique frames. Gallery GIF reviewed by OP. No foot sliding when played at the roaming speed |
| A1.2 | **Match walk speed to stride**: measure stride length (px per cycle) per pet from the new art and write `strideLengthUV` into the manifest. `SunroomRoamingEngine` derives the walk duration from distance ÷ stride, so feet don't skate | CX | Foot contact stays put over the floor (verify at 0.25× in the gallery with a floor grid) |
| A1.3 | **Re-time the idle loops** so they read as breathing, not wobbling: add holds at the breath peak and trough, and blink as an overlay event (manifest `events.blink`) instead of swapping to `f2`, which changes the whole pose | CX (timing + blink overlays), GH reviews | Idle reviewed side by side with the old one in the Gallery |
| A1.4 | **Upgrade the low-res banks** (`i`,`h`,`m`,`p`,`s` at 320 px) to true 768 px. Prefer a repaint over the A0.4 upscale where the upscale looks soft at 215 pt in the encounter view | CX: pets 01–04 · GH: pets 05–08 (Flash for bulk upscales) | Encounter screenshots on the 3× simulator are crisp at 100% zoom |

### Phase A2 — New clips that remove the popping · ~1–2 weeks
Priority order. Each clip is drawn for all 8 pets (one branch per pet per batch).

| # | Clip (bank code) | Frames | Purpose | Owner |
|---|---|---|---|---|
| A2.1 | `tu` sit→stand, `td` stand→sit | 6 each | Idle ↔ walk without teleporting (F5) | CX |
| A2.2 | `ld` lie down, `wk` wake + stretch | 8 + 10 | Sit → nap and back. The stretch is a big charm moment | GH |
| A2.3 | `tn` turn (3/4 → side → 3/4 opposite) + right-facing `wr` walk for asymmetric pets 03/04/08 | 5 (+12) | Replaces the mirror flip (F6) | CX (03, 04, 08 batch) |
| A2.4 | `wf` walk toward camera, `wb` walk away | 8 each | Depth movement in the 2.5D room (F7). The engine picks `wf`/`wb`/`w` from the movement vector angle | GH |
| A2.5 | `e` eat (head down, chew, lick lips) | 10 | Real eating, replacing bank `m` reuse (F8) | CX |
| A2.6 | `j` hop/pounce with anticipation crouch, air, land squash | 9 | Pounce and the ball. Removes the `.offset` arc pasted on top of `p` frames | CX |
| A2.7 | `r` startle/surprise, `g` greet (nose-boop / headbutt) | 6 + 8 | Encounter greetings and roommate greetings | GH |
| A2.8 | Species signature clips (`x`): 餘燼 (03) warms the blanket with breath, 杜松 (02) drops an origami charm, 摺翼 (04) wing-shade, 梅子 (07) mist puff, 蘆葦 (08) leaf sprout | 8–12 | Makes the existing magic behaviors in `SunroomRoamingEngine` visible | GH designs all; drawing split: CX 02, 04 · GH 03, 07, 08 |

**AI art procedure (for both Codex and Gemini):** (1) Lay out the pet's `f1`–`f6` plus 2 existing frames of the nearest bank as the character reference. (2) Generate **keys first** (e.g. walk: contact L, passing, contact R, passing), registered on a 768² guide template with the baseline and head lines. (3) Fill in the in-betweens using the keys as inputs, never from text alone. (4) Run lint and contact sheet. (5) Fix any off-model frame (wrong markings, extra limbs, palette drift) by repainting from its neighbors. (6) Post the GIF + sheet in the PR. **Reject on sight:** changed eye shape or markings, a moving paper texture (texture "boil" should be ≤ subtle), wings or horns flipping sides, a different number of toes or legs between frames.

### Phase A3 — Playback engine (code) · runs in parallel with A1/A2
| # | Task | Owner | Done when |
|---|---|---|---|
| A3.1 | **Data-driven clips**: replace the magic-number `switch` with `CelClip`/`CelClipPlayer` loaded from the manifest (fps, holds, loop mode, events, `next`). Keep `PetPlayfulAction` as the public API. Fix the stale doc comments | CX | Unit tests: frame index at time t for loop/once/pingpong/holds. Visual parity in the Gallery |
| A3.2 | **Transition graph**: an animation state machine (`idle ⇄ walk`, `idle → lieDown → sleep → wake → idle`, `any → startle`) that plays transition clips automatically. `SunroomRoamingEngine` asks for target states and waits on an "arrived in pose" callback before moving | CX | No pose pops in a 5-minute roaming capture (GH verifies) |
| A3.3 | **Directional locomotion**: choose `w`/`wr`/`wf`/`wb` and `tn` from the movement vector. Remove the `scaleEffect(x:-1)` flip for pets that have authored right-facing clips | CX | Depth walks no longer moonwalk |
| A3.4 | **Frame cache/perf**: decode with `CGImageSourceCreateThumbnailAtIndex` at **display size** (not 768²), off the main actor, and **preload the next clip** when a transition starts. Use an LRU per pet with clip pinning and a budget of 48 MB. Use **one shared clock** (`TimelineView` at stage level passes `time` down) instead of one 30 Hz `TimelineView` per pet | CX | Instruments: no main-thread decode during roaming, steady 60 fps with 4 pets on the iPhone 18 Pro simulator + a real device if available, memory < budget |
| A3.5 | **Motion tokens**: add `AppTheme.Motion` (`.gentle`, `.bouncy`, `.snappy`, `.settle`, durations, `.reduced` fallbacks) and migrate the 72 ad-hoc springs. Respect Reduce Motion everywhere: hold an idle key, crossfade instead of moving, and keep the TimelineView loops at ≤ 1 Hz | CX | `grep "spring("` outside `AppTheme` returns 0. Reduce Motion pass by GH |
| A3.6 | **Event hooks**: drive dust puffs, footstep sound (`CozySoundEngine`) and haptics from manifest events (`footContact`, `land`, `chew`), instead of the timers they use now | CX | Sound and dust sync visibly with the art |

### Phase A4 — World, props & FX art · ~1 week, after A0
| # | Task | Owner |
|---|---|---|
| A4.1 | **Furniture idle loops** (8–12 frames, subtle): hammock sway, hearth brazier flame, moss planter leaf rustle, window cushion sun-dust, wool blanket breathing when a pet is on it, cloth ball roll (24-frame rotation). Same spec, saved to `art-src/goodies/` | CX: ball, brazier, hammock · GH: planter, cushion, blanket |
| A4.2 | **Watercolor FX sprite sheets** to replace SF Symbols: paw-print floor ripple, dust puff (6f), heart pop (8f), sparkle twinkle (6f), coin "+1" stamp (6f), sleep "z" drift, steam, rain splash. Each hand-painted with transparent bg | GH designs the look; CX paints ripple, dust, coin, steam, rain; GH paints heart, sparkle, "z" |
| A4.3 | **FX player**: a lightweight `SpriteFXLayer` in a `Canvas` that plays these sheets, pooled, depth-sorted with the pets | CX |
| A4.4 | **Ambient layers**: animated sunbeam dust, curtain sway, window rain streaks per `WeatherMode`, cross-faded at weather changes. Prefer a Metal shader (extend `PaperGrainAndLUT.metal`) over 10 separate `TimelineView`s | CX (shader) + GH (look-dev frames as reference) |
| A4.5 | **Outfit secondary motion**: scarf/bow drift on walk (2–3 frame offset), driven by the manifest neck anchor per clip | CX |

### Phase A5 — QA & sign-off (continuous)
| # | Task | Owner |
|---|---|---|
| A5.1 | Baseline video capture of every screen with pets (Sunroom roaming 2 min, Encounter, Tactile Care, Stroll, Diary snapshot) **before** any change → `docs/qa/animation-baseline/` | GH |
| A5.2 | Per-PR review: Gallery GIF + 30 s simulator recording, a checklist against §1.2 and the "reject on sight" list | GH reviews CX art; OP reviews code and GH art |
| A5.3 | Final pass: Reduce Motion, low-power mode, 4-pet room perf, Diary snapshot (`DiarySnapshotBaker`) still uses the static `f` frames correctly, outfits stay attached through every new clip | GH, signed off by OP |

---

## 3. Sequencing & parallelism

```
A0.1–A0.3 (CX) ─┬─> A0.4 normalize (GH) ─> A1.* redraws (GH/CX per pet) ─> A2.* new clips (per pet batches)
                ├─> A0.5 Gallery (CX) ───────────────────────────────┘
                └─> A3.1 data-driven player (CX) ─> A3.2 state machine ─> A3.3 directional ─> A3.6 events
                                       A3.4 perf / A3.5 motion tokens (CX, any time after A3.1)
A5.1 baseline capture (GH) — day 1, before anything merges
A4.* props/FX — after A0, in parallel with A1/A2
```

- **Codex runs two lanes at once**, each in its own worktree: a **code lane** (A0 → A3 → A4.3–A4.5) and an **art lane** (A0.4 → its A1/A2/A4 rows). The lanes never share files, because art touches only `art-src/**`, `Resources/PetFrames/**` and `manifests/**`.
- **Ship slices:** A0 + A1.1 + A3.1 + A3.4 already fix the most visible problems (skating walks, size pops, blur, hitches). A2/A4 are about charm.
- **Simulator rule:** only one agent drives the simulator at a time. Gemini owns it during QA windows; Codex uses the Gallery in unit/snapshot tests and on-disk previews in between.
- **Merge gate:** `xcodebuild test` green, frame lint green, zero new warnings, GIF/video attached, reviewed by a different model family.

## 4. Brief template for each delegate

> **Task:** A1.1 — Redraw walk cycle for pet_04 (摺翼, twilight night-demon cat).
> **Read first:** `docs/ANIMATION_PLAN.md` §0, §1, A1.1 · reference frames `Assets.xcassets/pet_04_f1..f6`, `Resources/PetFrames/pet_04_w*.heic`, `pet_04_i1.heic`.
> **Own only:** `art-src/petframes/pet_04/w/**`, `Resources/PetFrames/pet_04_w*.heic`, `Resources/PetFrames/manifests/pet_04.json`.
> **Branch:** `gemini/anim-pet04-walk` in its own worktree.
> **Done when:** 12 unique frames, `tools/frames/lint pet_04` green, contact sheet + GIF in the PR, 30 s Gallery recording.
> **Report:** branch, head SHA, lint output, preview paths.

## 5. Decisions (settled 2026-11-24: defaults kept)
1. **Source resolution: 768 px.** PetFrames grows from 13 MB to roughly 50–60 MB of HEIC before new clips; runtime memory stays flat via A3.4.
2. **Right-facing art: yes.** Authored right-facing clips for asymmetric pets 03, 04 and 08 (no mirror flip for them).
3. **Toward/away walks (A2.4): yes.** `wf`/`wb` for all 8 pets.
4. **Art sources: Git LFS** for `art-src/**/*.png` if `git lfs` is installed; otherwise git-ignored and documented in `art-src/README.md`.
