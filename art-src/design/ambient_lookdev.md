# Sunroom Ambient Layers — Look-Dev Reference Spec (A4.4)

**Owner:** Gemini (look-dev frames) · Codex (Metal shader implementation in `PaperGrainAndLUT.metal`)
**Reference frames:** `art-src/design/ambient_lookdev/{clear_morning,overcast,light_rain,dusk}.png` (`684 × 1254` px matching `bg_home_sunroom.png`)

---

## 1. Purpose
Replace the separate ambient `TimelineView` overlays (`SunroomAtmosphereParticlesView`, `SeasonalWindowAmbianceOverlay`, `DuskFireflyMotesOverlay`) with a unified Metal shader pass extending `PaperGrainAndLUT.metal`, cross-fading smoothly (`1.2 s` ease-in-out) on `WeatherMode` transitions.

## 2. Per-Weather Layer Recipes

| `WeatherMode` | Tint LUT | Curtain Sway | Sunbeams / Rain | Floating Motes |
|---|---|---|---|---|
| `.clearMorning` | Warm cream `(1.00, 0.98, 0.92)` | Soft sheer `#FFF7E3` edge ripple (`α ≤ 0.22`), 6.5 s period | 2 diagonal shafts from upper-left (`xTop 0.20, 0.50` → `xBot 0.52, 0.78`), pulse `0.14 ± 0.04` | 18–24 sunlit dust bokeh (`#FFF8DC`), upward/diagonal slow drift |
| `.overcast` | Soft pearl mist `mix(..., #E4E8E6, 0.14)` | Calm `#EDF2F2` edge ripple (`α ≤ 0.16`), 9.0 s period | None (diffused window bloom only) | Minimal subtle dust (`≤ 6` motes, `α ≤ 0.25`) |
| `.lightRain` / `.postRain` | Cool slate tint `(0.90, 0.96, 1.05)` | `#D1E6F0` subtle draft (`α ≤ 0.14`), 5.0 s period | Slanted `~10°` watercolor rain streaks in window zone (`y: 0.10..0.44`), length `26–56 px`, `#F0F5FA` at `α ≤ 0.48` | Cool mist shimmer; rain-splash sprites on sill (`art-src/fx/rain`) |
| `.dusk` | Amber twilight `(1.04, 0.91, 0.78)` | `#FAD69E` warm edge glow (`α ≤ 0.18`), 7.5 s period | Low-angle amber beam (`#FACC85`, `α ≤ 0.22`) | 10–14 warm lantern fireflies (`#FFE79B`, radial `r = 9 pt`, breathing pulse) in `y: 0.30..0.72` |

## 3. Reduce Motion Contract
When `accessibilityReduceMotion == true` (A3.5):
- Freeze curtain phase (`phase = 0`), freeze rain streak translation (hold subtle static glass condensation wash), hold sunbeam pulse at nominal `0.14`, and render fireflies/dust at fixed static positions (or update at `≤ 1 Hz` via `AppTheme.Motion.interval(fps:reduceMotion:)`).
