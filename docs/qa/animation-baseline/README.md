# Animation Baseline QA Capture (A5.1)

> The `.mp4` recordings listed below are kept on the capture machine only and are not committed (the largest is over GitHub's 100 MB file limit). The `.png` stills are in the repo.

- **Captured:** 2026-11-24 (pre-merge baseline on `gemini/anim-art` @ `49acbf0`)
- **Device:** iPhone 18 Pro Simulator (`F839F388-C746-4C4E-9A82-AEB40A1ECC70`), iOS 27.2 (`1206 × 2622` px @3x)
- **App:** `com.pawprintdays.app` (`PawprintDays`)

## Recordings & Captures

| File | Screen | Duration | Size | Notes |
|---|---|---|---|---|
| `01-sunroom-roaming.mp4` | 陽光室 (`HomeSunroomView` / `Sunroom25DStageView`) | 149.3 s | 144 MB | `餘燼` (`pet_03`) & `梅子` (`pet_07`) roaming + cloth-ball toss at ~60 s; app went white & terminated to SpringBoard after `01:36.88` |
| `02-encounter.mp4` | 街角相遇 (`SidewalkEncounterView`) | 21.0 s | 26 MB | `梅子` (`pet_07`) at `永康體育用品社`: idle → ball-flick pounce → greeting complete + postcard |
| `03-tactile-care.mp4` | 近距離照護 (`TactileCareView`) | 29.3 s | 34 MB | `餘燼` (`pet_03`): idle → `逗貓棒` (`pounceHop`) → `踏踏舞` (`happyTwirl`) → `蓋被被` (`cozyNap`) |
| `04-stroll.mp4` | 散步同行 (`StreetOverworldView`) | 20.6 s | 21 MB | Active stroll setup + street map with `餘燼`; exited to SpringBoard at `00:15.34` |
| `05-diary-snapshot.mp4` | 精裝日記 (`HardcoverSketchbookView`) | 9.1 s | 4.6 MB | Sunroom → `日記` tab showing `梅子` baked postcard (`DiarySnapshotBaker`) |
| `05-diary-snapshot.png` | 精裝日記 (`HardcoverSketchbookView`) | — | 3× PNG | Full-res `1206 × 2622` reference of static baked postcard |

---

## Observed Problems (Pre-Overhaul Baseline)

1. **Simulator instability / termination during sustained roaming & active strolls (F9)**
   - In `01-sunroom-roaming.mp4`, both pets roamed until `01:36.88`, followed by an all-white frame (`01:44.96`), a blank map reset (`01:49.53`), and SpringBoard termination (`02:29.27`).
   - In `04-stroll.mp4`, the active stroll map froze visually and terminated to SpringBoard at `00:15.34`.
2. **Abrupt pose pops on every state change (F5)**
   - Encounter (`02-encounter.mp4`): `梅子` snaps instantaneously from sitting `i` → `pounceHop` (`00:06.27`) → `happyTwirl` (`00:07.15`).
   - Tactile Care (`03-tactile-care.mp4`): hard cuts between sitting idle, paws-up `h`/`p`, side-on `m`, and curled nap `s`; `f2` blink swaps the entire head/body pose rather than blinking in place.
   - Sunroom (`01-sunroom-roaming.mp4`): pets snap directly from walk to sit or curled nap without `sit_to_stand` / `lie_down` / `wake` transitions.
3. **Instant horizontal mirror flips (F6)**
   - In `01-sunroom-roaming.mp4`, `餘燼` flips 180° via `scaleEffect(x: -1)` between `01:32.86` and `01:36.88` with no turn clip (`tn`), flipping asymmetric dorsal/wing shading.
4. **Scale & baseline drift between banks (F2, F3)**
   - Curled nap (`s`) appears noticeably smaller/flatter on the floor than walking (`w`) and sitting (`i`) frames in both `01-sunroom-roaming.mp4` and `03-tactile-care.mp4`.
   - `餘燼`'s `w` bank is 512² (6 unique frames out of 16) while `i`/`h`/`m`/`p`/`s` are 320², causing subtle size/footing shifts.
5. **Hero-scale softness from 320 px frames (F4)**
   - In `02-encounter.mp4`, `03-tactile-care.mp4`, and `05-diary-snapshot.png`, `梅子` and `餘燼` show soft/blurry watercolor outlines compared to the crisp vector UI badges and stationery cards around them.
6. **Edge clipping & UI occlusion in Sunroom (code / layout)**
   - `餘燼` clips at the upper-right floor/wall boundary (`00:16.15`) and disappears off-edge with a clipped speech bubble (`00:20.09`).
   - `梅子` clips behind right-side UI pills (`00:48.37`–`00:52.48`).
7. **Static sleep loop & static props / procedural FX (F10)**
   - During `cozyNap` (`03-tactile-care.mp4`, `00:24.32`–`00:29.32`), `餘燼`'s curled body has barely perceptible breathing; only vector `Z` glyphs drift upward.
   - Furniture (`goodie_*`), window foliage, and sunbeams are static; sparkles, hearts, and `Zzz` use vector shapes / system text glyphs rather than watercolor sprite sheets.
8. **Diary snapshot (`05-diary-snapshot.png`)**
   - `DiarySnapshotBaker` renders `梅子` cleanly onto the `永康體育用品社` postcard (with 320 px softness and faint sparkle/neck-arc artifacts); bottom floating dock overlaps the `鋼筆手記` section at the bottom of the scroll view.
