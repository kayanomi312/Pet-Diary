# Watercolor FX Sprite Sheets — Look & Spec Sheet (`art-src/fx/LOOK.md`, A4.2)

**Owner:** Gemini (look direction + `heart`, `sparkle`, `zzz`) · Codex (paints `ripple`, `dust`, `coin`, `steam`, `rain_splash`, plus `SpriteFXLayer` player A4.3)
**Goal:** Replace procedural SF Symbols (`pawprint.fill`, vector `Canvas` hearts/stars, plain `Text("z")` / `"+1 幣"`) with cohesive hand-painted watercolor sprite animations that share the paper texture, pigment bleed, and warm ink of `Assets.xcassets` and `PetFrames`.

---

## 1. Universal FX Technical Spec

- **Source directory:** `art-src/fx/<fx_name>/01.png` … `NN.png`
- **Format:** PNG, sRGB, transparent background, **straight alpha**, zero white/black fringe or matte halo (inspect on both `#181A1B` dark and `#FAF6EE` warm-paper backgrounds).
- **Canvas sizes:**
  - **128 × 128 px** for floating particles & motes (`heart`, `sparkle`, `zzz`, `dust`, `steam`, `rain_splash`)
  - **256 × 256 px** for ground decals & stamps (`ripple`, `coin`)
- **Paper & Pigment Look:**
  - Soft **watercolor pigment pooling** along outer edges (slightly darker edge ring where pigment dries, lighter translucent wash in the center — ~70–88% opacity, never flat 100% vector fill).
  - Subtle cold-press **watercolor paper tooth** inside the wash; keep texture locked per frame (minimal boil) so loops feel gentle, not jittery.
  - **Warm ink outlines (`#2C3536` at 55–75% opacity)** ONLY on tactile stamps/icons (`coin`, subtle rim on `heart` and `zzz`). Soft atmospheric FX (`dust`, `steam`, `ripple`, `rain_splash`, `sparkle`) have **NO hard ink outlines** — pure pigment wash and soft brush edges!
  - **Lighting:** Soft warm highlight bias on upper-left (`~315°`) to match Cel Spec v2.
- **Scale & Display:** `SpriteFXLayer` renders these at 28–72 pt display size (`~84–216 px` at 3×), so 128² / 256² source PNGs stay tack-sharp without upscaling.

---

## 2. Shared Color Tokens (from `AppTheme` & `StorybookPropArt`)

| Role | Hex | Usage |
|---|---|---|
| Warm Ink (soft) | `#2C3536` (55–75% α) | Stamp rims, coin outline, delicate `zzz` edge |
| Coral Heart Wash | `#E87266` / `#D96B7E` | `heart` pop wash + deep rose edge bloom `#B84A62` |
| Sunbeam / Star Gold | `#FFE39C` / `#F2D794` / `#C98D26` | `sparkle` core, `coin` brass stamp, warm glow |
| Sleep Slate-Indigo | `#6B86A8` / `#9BB0CA` | `zzz` dreamy wash |
| Cedar Floor Dust | `#FFF8EC` / `#E6D8C0` | `dust` puff behind walking paws |
| Rain / Dew Blue-Grey | `#BBD5DF` / `#7C9AA6` | `rain_splash`, `ripple` wet-ink wash |
| Warm Cream Steam | `#FAF6EE` / `#EADBC4` | `steam` wisps above ginger tea & brazier |
| Vermilion Hanko Seal | `#B83B32` | Accent ink ring on `coin` "+1" stamp |

---

## 3. Per-FX Sheet Specifications

### Gemini-Owned FX

#### 3.1 `heart` — Heart Pop (`art-src/fx/heart/01.png`..`08.png`)
- **Canvas:** 128 × 128 px · **Frames:** 8 · **FPS:** 12 · **Loop:** `once` (lifetime ~0.67 s)
- **Use:** Tactile petting, greeting completion, sunroom hearts (`StorybookParticleMotesCanvas` / `LiveTouchSparkleLayer` replacement).
- **Beat-by-beat:**
  - `01`: Tiny coral-pink watercolor dot (`#E87266`, ~16 px) squashed slightly horizontally, budding upward.
  - `02`: Swells into plump asymmetric brush-painted heart (~42 px), soft `#FFF8EC` highlight dot upper-left, slight squash-stretch (`+8%` height).
  - `03`: Peak pop (~64 px) with soft translucent outer pigment bloom (`#D96B7E` at 35% α) and two tiny 3 px paint-droplet flecks beside top lobes.
  - `04`–`05`: Gentle buoyant float upward (~10 px higher in canvas), subtle side-to-side tilt (`-4°` → `+3°`), center wash lightens like drying watercolor.
  - `06`–`07`: Softly expands ~10% while fading (opacity ~65% → ~35%), outer edge blooms softly.
  - `08`: Faint warm-rose petal/mist wisps (`~12%` α) dissipating cleanly before empty frame.

#### 3.2 `sparkle` — Sparkle Twinkle (`art-src/fx/sparkle/01.png`..`06.png`)
- **Canvas:** 128 × 128 px · **Frames:** 6 · **FPS:** 10 · **Loop:** `once` or `loop`
- **Use:** Curio discovery, touch sparkles, magic aura twinkles, mentorship shimmer.
- **Beat-by-beat:**
  - `01`: Soft warm cream-gold pinpoint glow (`#FFE39C`, ~14 px radial brush dab).
  - `02`: 4-point hand-painted gouache star stretches outward (~44 px tip-to-tip), curved tapered brush strokes (no sharp geometric polygon!).
  - `03`: Peak radiance (~68 px) — warm ivory core (`#FFFDF8`), butter-gold rays (`#F2D794`), plus 2 tiny companion pinpoint dots at diagonal offsets.
  - `04`: Rays rotate ~10° gently and begin softening; secondary dots drift outward ~6 px.
  - `05`: Rays shorten back toward soft diamond bloom (~36 px), opacity ~50%.
  - `06`: Faint golden dust-mote fade (`~18%` α) returning smoothly toward `01` if looped.

#### 3.3 `zzz` — Sleep "Z" Drift (`art-src/fx/zzz/01.png`..`08.png`)
- **Canvas:** 128 × 128 px · **Frames:** 8 · **FPS:** 6 · **Loop:** `loop`
- **Use:** Napping pets (`cozyNap` / `.resting` in Sunroom & Tactile Care).
- **Beat-by-beat:**
  - Hand-lettered rounded brush `"z"` (soft calligraphic stroke in slate-indigo `#6B86A8` with pale sky highlight `#9BB0CA` and very soft `#2C3536` 30% α edge—NOT system rounded font!).
  - `01`: Small `"z"` appears low-left (`x ≈ 42, y ≈ 94`, ~22 px tall) at ~35% α.
  - `02`–`04`: Drifts gently up and right along a lazy sine S-curve (`x ≈ 54 → 64, y ≈ 78 → 54`), swelling smoothly to ~36 px at ~85% α, slight playful `-6°` → `+4°` tilt.
  - `05`–`06`: Peak float (`x ≈ 72, y ≈ 38`, ~40 px), soft dreamy blur/bloom around stroke edge.
  - `07`–`08`: Continues drifting upper-right (`y ≈ 24 → 14`) while dissolving into soft indigo-mist wash (`45% → 12%` α) so the next `"z"` loop enters seamlessly.

---

### Codex-Owned FX (Follow This Look Sheet)

#### 3.4 `ripple` — Paw-Print Floor Ripple (`art-src/fx/ripple/01.png`..`08.png`)
- **Canvas:** 256 × 256 px · **Frames:** 8 · **FPS:** 12 · **Loop:** `once`
- **Use:** Sunroom floor tap (`FloorTapRipple` replacement).
- **Visual:** Perspective-foreshortened (2:1 ellipse for 2.5D floor!) hand-painted ink-wash paw stamp at center (`#7C9AA6` / `#C98D26` warm tintable wash) that prints softly at `01`–`02`, then emits an expanding, feathered watercolor concentric ring (`03`–`07`) fading cleanly to `08`.

#### 3.5 `dust` — Footstep Dust Puff (`art-src/fx/dust/01.png`..`06.png`)
- **Canvas:** 128 × 128 px · **Frames:** 6 · **FPS:** 12 · **Loop:** `once` (spawned on `footContact` manifest event!)
- **Use:** `WalkingPawDustCanvas` replacement behind walking paws.
- **Visual:** 2–3 tiny overlapping warm-cream watercolor puffs (`#FFF8EC` with subtle `#E6D8C0` underside shade) that kick slightly backward-upward (`01`–`02`), billow softly apart (`03`–`04`), and dissolve into translucent paper wash (`05`–`06`). Very light (`≤ 55%` peak opacity) so it never competes with the pet's paws.

#### 3.6 `coin` — Coin "+1" Stamp (`art-src/fx/coin/01.png`..`06.png`)
- **Canvas:** 256 × 256 px · **Frames:** 6 · **FPS:** 12 · **Loop:** `once`
- **Use:** Origami pickup, tea brew, hide-and-seek `+1 幣` floating burst.
- **Visual:** Small hand-painted brass coin / hanko seal stamp (`#F2D794` / `#C98D26` with subtle `#B83B32` seal rim & hand-brushed `"+1"`), squashing slightly on `01`–`02` stamp-down, popping upward with 3 tiny gold flecks on `03`–`04`, and drifting/fading cleanly on `05`–`06`.

#### 3.7 `steam` — Tea & Hearth Steam (`art-src/fx/steam/01.png`..`08.png`)
- **Canvas:** 128 × 128 px · **Frames:** 8 · **FPS:** 8 · **Loop:** `loop`
- **Use:** `SteamingGingerTeaTrayView`, `goodie.hearth_brazier`, warm blankets near `pet_03`.
- **Visual:** 2 delicate curling ribbons of translucent warm cream wash (`#FAF6EE` at `≤ 45%` α) rising smoothly from bottom center (`y ≈ 110`) to top (`y ≈ 16`) with seamless loop closure (`08 → 01` continuous curl).

#### 3.8 `rain_splash` — Raindrop Splash (`art-src/fx/rain_splash/01.png`..`06.png`)
- **Canvas:** 128 × 128 px · **Frames:** 6 · **FPS:** 12 · **Loop:** `once`
- **Use:** Street puddles, veranda sill, window ledge during `.lightRain` / `.postRain`.
- **Visual:** Cool blue-grey watercolor droplet (`#BBD5DF` / `#7C9AA6`) landing into a perspective 2:1 ellipse splash crown (`02`–`03`), 3 tiny bead droplets arcing out (`04`), and a thin expanding wash ring (`05`–`06`).

---

## 4. Reject-on-Sight Rules for FX

1. **Crisp vector / SF Symbol look:** Hard geometric circles, flat 100% solid fills, or system typography fonts.
2. **Dark/white fringe:** Visible matte halo when previewed over `#181A1B` dark cedar shadow or `#FAF6EE` cream paper.
3. **Opaque occlusion:** `dust` or `steam` heavier than ~55% opacity that obscures the pet's paws or furniture beneath.
4. **Loop pop (`zzz`, `steam`):** Noticeable jump or blink between final frame `NN` and `01`.
