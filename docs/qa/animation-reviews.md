# Animation QA & Code Review Log (`docs/qa/animation-reviews.md`)

**Reviewer:** Gemini 4 Hydrogen · **Reviewed branches:** `codex/anim-art` (`1a8f958` A0.4, `f434d1b` A1.3, `d88eb65` A4.1/A4.2), `codex/anim-code` (`dbbaa0a` A0/A3)

---

## 1. A0.4 — Normalized Legacy Cels (`codex/anim-art` @ `1a8f958`)

### Automated Lint (`tools/frames/lint`)
Running `tools/frames/lint` across `codex/anim-art` reported **114 lint errors** (exit 1), broken down into two categories:
1. **Expected pre-A1.1 walk bank failures (`pet_02`–`pet_06` `w`):** `pet_02` (6 unique), `pet_03` (6), `pet_04` (3), `pet_05` (6), `pet_06` (4) fail `>= 8 unique drawings required` until A1.1 lands.
2. **`broadSilhouetteTop` head-height failures across `i` / `h` / `m` / `w`:**
   - `i1` `broadSilhouetteTop` measures `y=153` (`pet_01`), `y=150` (`pet_02`), `y=129` (`pet_03`), `y=148` (`pet_04`), `y=193` (`pet_05`), `y=149` (`pet_06`), `y=178` (`pet_07`), `y=79` (`pet_08`) vs `170 ± 6`.
   - Because `broadSilhouetteTop` checks for any row `>= 15%` opaque width, wide ears, horns, and `pet_08`'s wide antlers trigger false positives high above the skull, and slight ear/head tilt variations in `h`/`m`/`w` trigger `> 3%` height diffs.

### Visual Contact-Sheet Review (`art-src/previews/pet_01..08/{i,w,s}.png`)
- **Baselines:** **Pass across all 8 pets.** Every frame sits cleanly on `y = 690 px` (`690–690 px`).
- **Alpha & Upscale Quality:** **Pass.** Clean straight alpha on white/black; no matte halos or blocky upscale artifacts.
- **`pet_01`, `pet_07`, `pet_08`:** **Approved.** `i1` skull tops align cleanly near `y = 170`; `w` (16 unique) and `s` match `i` in scale and framing.
- **`pet_02`, `pet_03`, `pet_04`, `pet_05`, `pet_06`:** **Conditionally approved as A0.4 stop-gap (pending A1.1).** `i` and `s` scale cleanly, while legacy `w` frames (3–6 drawings) are visibly wider/larger horizontally than `i` (with `pet_02` and `pet_04` `w` touching the left/right canvas edges).

---

## 2. A1.3 — Idle Breath Timing & Blink Manifests (`codex/anim-art` @ `f434d1b`)

- **Approved (manifest data):** `pet_01`..`pet_08` `idle` clips cleanly switch to `fps: 8`, add breath holds (`"6": 3`, `"13"/"14": 3`), and mark `"events": { "blink": [13/14] }` with sorted JSON keys.
- **Code gap (for `codex/anim-code`):** `ProceduralPetRigView.respond(to:)` (`PawprintDays/Art/PlaceholderAssetGenerator.swift:347`) currently handles only `"footContact"`, `"land"`, and `"chew"`, and ignores `"blink"` events — so `A1.3` blink overlays/frames will not visually blink on authored `idle` clips until `"blink"` is wired in code.

---

## 3. A4.1 — Furniture Idle Loops (`codex/anim-art`, `cloth_ball` / `hearth_brazier` / `woven_hammock`)

All three use 768 × 768 transparent PNGs with warm dark-brown ink, watercolor washes, and paper tooth matching `Assets.xcassets/goodie_*`.

| Asset | Status | Findings |
|---|---|---|
| `cloth_ball` (`8d2d775`) | **Approved** | 24 frames. Straw mat stays anchored; stitched cloth ball rotates smoothly in place with consistent upper-left lighting. |
| `hearth_brazier` (`2d81bcc`) | **Approved (minor polish optional)** | 12 frames. Pot and ember bed match `goodie_hearth_brazier`; watercolor flame flickers smoothly. Optional polish: soften the cool blue-grey base tip of the flame into a warm ember glow on the coals. |
| `woven_hammock` (`96494ea`) | **Needs polish** | 12 frames. Art matches `goodie_woven_hammock`, **but motion between frames `01`, `04`, and `07` is only ~1–2 px of sag shift**, making the sway nearly imperceptible at Sunroom display size. Increase gentle horizontal pendulum swing to ~5–7 px across the cycle. |

---

## 4. A4.2 — FX Sprite Sheets (`codex/anim-art` vs `art-src/fx/LOOK.md`)

| FX | Status | Findings |
|---|---|---|
| `dust` (`ce5417c`) | **Approved** | 6 × 128² (`384×256` sheet). Translucent warm-cream watercolor puffs with paper tooth, clean alpha, no hard ink outlines. |
| `rain` (`d88eb65`) | **Approved** | 6 × 128² (`384×256` sheet). Perspective 2:1 splash crown and expanding wash rings match `LOOK.md` §3.8. Note: directory is `art-src/fx/rain/` (vs `rain_splash/` in `LOOK.md` — align `SpriteFXLayer` loader to `rain`). |
| `ripple` (`5717588`) | **Approved** | 8 × 256² (`1024×512` sheet). Perspective-foreshortened sepia paw stamp + expanding feathered blue-grey wash ring; clean alpha. |
| `coin` (`5baaa45`) | **Approved (minor note)** | 6 × 256² (`768×512` sheet). Hand-painted brass coin + `+1` with paper grain and clean alpha. Omits the `#B83B32` vermilion seal rim accent from `LOOK.md` §3.6 (acceptable if intentional). |
| `steam` (`380c441`, fixup `e4c4c42`) | **Reject — still unfixed** | **1) Opaque `#000000` black background** persists in `01.png`, `08.png`, and `sheet.png` after `e4c4c42`. **2) Wrong visual style:** flat grey silhouette instead of translucent warm-cream (`#FAF6EE`) watercolor ribbons. **3) Static:** all 8 frames show identical silhouettes with no rising curl. |

---

## 5. A2 Character Clips Spot-Check (`codex/anim-art` @ `0b411bb`)

| Clip | Status | Findings |
|---|---|---|
| `pet_02/x` (A2.8, `7510e64`) | **Approved** | Follows `art-src/design/signature_clips.md` beat-by-beat (sit → tuck charm → reach → floor place `y=690` → nudge → proud admire → tsundere look-away → settle). White bib/4 socks, crimson horns, burgundy wing, spade tail intact; minor note: `09`–`10` are near-identical and skull sits ~15–20 px above `y=170`. |
| `pet_03/wr` (A2.3, `30a69dd`) | **Reject on sight — missing marking** | Clean right-facing 12-frame walk cycle on `y=690`, **but the terracotta dorsal spine scales along the back are completely absent in all 12 frames** (present in `tn/01.png`), and forehead scales are barely visible. |
| `pet_03/tn` (A2.3, `30a69dd`) | **Approved (minor note)** | Smooth 5-frame turn (`right → 3/4 right → front → 3/4 left → left`), horns/3 forehead scales/pinecone tail/baseline intact. Minor note: in frame `03` (front view), dorsal scales peek symmetrically on both sides of the waist. |
| `pet_06/j` (A2.6, `00013b9`) | **Approved (minor head-height note)** | Smooth 9-frame anticipation crouch → airborne leap → 4-paw landing squash → sit settle; bronze horns, lavender wisp, 4 cream socks intact. Skull sits ~25–30 px above `y=170` in `01`/`09`. |
| `pet_07/e` (A2.5, `b3e408a`) | **Approved** | Clean 10-frame eat/chew/lip-lick loop on `y=690`; cloud ruff/ribbon stays strictly on viewer-right shoulder and crown stars remain consistent. |
| `pet_07/tu` (A2.1, `52882c9`) | **Approved (minor duplicate note)** | Clean 6-frame sit → standing profile transition on `y=690`; `01`–`02` and `05`–`06` are visually near-identical. |
| `pet_08/wr` & `tn` (A2.3, `10486af`) | **Approved** | Strictly preserves `pet_08` asymmetric antlers across all 12 right-walk and 5 turnaround frames (dog's right = 2 tines, dog's left = 3 tines; 4 legs, cream markings intact). Minor note: leaf buds on the smallest tine vary slightly on a few frames. |

---

## 6. Simulator & Code QA (`A0.5`, `A3.5`, `A5.3`)

- **A0.5 Animation Gallery (verified on iPhone 18 Pro Simulator, Debug build):** Reachable via `Debug menu` → `Animation Gallery`; `bg_home_sunroom`, pet/clip pickers, frame stepper, `0.25×`–`2×` playback slider, `Onion skin`, `Mirror`, and `Outfit` toggles render cleanly (minor note: bottom `Onion skin` toggle sits close to the bottom sheet edge).
- **A3.5 Reduce Motion pass (verified):**
  - `grep "spring("` outside `AppTheme.swift` returns 0 animation springs; all 10 `TimelineView` instances use `AppTheme.Motion.interval(fps:reduceMotion:)`.
  - With iOS Accessibility → Motion → **Reduce Motion ON** on simulator, a 9.0 s Sunroom recording (`36` sample times) produced `1` unique frame (`0` pixel changes), holding calm seated idle poses on `餘燼`, `梅子`, and window visitor `摺翼`.
- **A5.3 Partial/Code-Engine Pass (verified on `gemini/anim-art` @ `95cd7d2` merge):**
  - `xcodebuild test` passed (`Stage2To4VerificationTests` & `CelClipTests` green).
  - 33.4 s Sunroom roaming (`A3.2`, `A3.4`, `A4.3`, `A4.4`, `A4.5`) stayed live with zero white-screen crashes, smooth depth sorting, and clean diagonal sunbeams.
  - `DiarySnapshotBaker` (`HardcoverSketchbookView`) continues to render static `f` keyframe postcards cleanly with weather, date, and `遇` stamp intact.
  - *Remaining scope:* Final full-cast A5.3 sign-off (including 4-pet room perf & outfit check across all new clips) waits on the GH character art banks (`A1.1`, `A1.4`, `A2.2`, `A2.4`, `A2.7`, `A2.8` for `03/07/08`), which are blocked by server capacity (`503 MODEL_CAPACITY_EXHAUSTED` on `gemini-3.1-flash-image`).

## 7. Open Code Review Notes (`codex/anim-code` @ `95cd7d2`)

1. **`tools/frames/build.swift` (`broadSilhouetteTop` heuristic):** Needs refinement or documented per-pet tolerances for horned/antlered/tall-eared species (`pet_03`, `pet_08`, `pet_04`) so `tools/frames/lint` does not fail 114 checks when skull tops are actually at `y = 170`.
2. **`PlaceholderAssetGenerator.swift` (`events.blink`):** Wire `"blink"` event from `CelClip` manifests (used by `A1.3` in `pet_01..08.json`) so idle loops trigger a brief blink frame/overlay without popping the whole pose.
3. **`SpriteFXLayer.swift` (`SpriteFXKind.sleep.frameCount`):** Expects 6 cells for `fx_sleep`, while `ANIMATION_PLAN.md` / `art-src/fx/LOOK.md` specify 8 frames for `zzz`. `art-src/fx/zzz/sheet.png` is exported as a 6-frame `768×128` strip matching `SpriteFXKind.sleep`, with all 8 individual frames (`01..08.png`) plus `sheet_8f.png` preserved.
4. **Sunroom stage bounds / crash investigation (`docs/qa/animation-baseline/`):** Monitor sustained (>2 min) roaming stability and ensure `SunroomRoamingEngine` UV bounds keep speech bubbles inside the right edge.

## 8. S0–S6 smoothness art on the crown-registered base

The [per-bank comparison](../../art-src/design/smoothness-comparison.md) compares
integration commit `23c5bb2` against the final bundled HEIC cels. Smoothness
flagged 51 of 88 banks at baseline and 12 of 122 after the art and timing work.
The full frame lint passed, including the crown landmarks. All 58 banks with
new or repainted cels passed both tools. The iPhone 17 simulator suite passed
all 83 tests. Gallery playback still needs a visual check on device.

### S2 walk gaps

| Bank | Remaining issue |
| --- | --- |
| `pet_02/w` | The replacement in-between still produced a conspicuous paw transition from the long reach to the passing pose. The original has 38.28 px centroid travel. |
| `pet_04/w` | Interpolation ghosted the paws. The painted alternates introduced crown and limb-spacing jumps. |
| `pet_04/wr` | The new passing keys moved the head and increased the peak step. |
| `pet_06/w` | The candidate reduced torso travel, but its large paw steps persisted and the typical step grew. |
| `pet_08/wr` | The replacements traded the original spikes for other visible jumps and a crown-height mismatch. The existing asymmetrical antlers were retained. |
| `pet_03/wr` | The existing art still needs the terracotta dorsal scales called out in section 5. Centroid travel is 11.01 px. |

The shipped left-walk revisions cover pets 01, 03, 05, 07 and 08. The new
12-drawing walks for 03 and 05 have larger absolute steps than their short
predecessors. Relative step and seam thresholds pass, and the new cycles
include both contact and passing poses. Pet 03's dorsal scales are visible
in all 12 left-walk cels.

Six other smoothness findings remain in existing cels for pets 05–08.
These are `pet_05/i`, `pet_05/s`, `pet_06/i`, `pet_07/i`, `pet_08/i`
and `pet_08/s`. Pets 05–08's expression and sleep art was assigned to the
other art lane.

### Art and playback notes

The built-in image generator used the six model cels and the nearest
existing bank for each pet. Breathing uses the original body paint with
small chest and tail motion and localized closed-lid paint for cel 14.
The walk prompts used contact and passing keys in both directions. The
turn prompts used profile, three-quarter and frontal keys. Lie-down uses
the seated and curled keys, with wake using the same intermediate drawings
in reverse. Startle uses the idle and airborne reference poses and ends back
at idle after a small recoil.

All `tn` banks face right at entry, end facing left and link to `walk`.
The art includes `wr` for every pet. The right-facing turn path still needs
engine playback in the opposite direction. The new `ld`, `wk` and `r`
clips are one-shots and link to `sleep`, `idle` and `idle` respectively.
Startle emits `land` on cel 4. The [stride measurements](../../art-src/design/stride.md)
are estimates for the base Sunroom at mid-depth. Validate contact against
the floor grid when wiring the engine changes.
