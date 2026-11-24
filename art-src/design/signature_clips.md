# Species Signature Clips (`x`) — Art Direction & Beat-by-Beat Spec (A2.8)

**Owner:** Gemini (design) · **Drawing split:** Codex (`pet_02`, `pet_04`), Gemini (`pet_03`, `pet_07`, `pet_08`)
**Bank code:** `x` (`art-src/petframes/pet_XX/x/01.png` … `NN.png`)
**Manifest clip key:** `"signature"` (`"bank": "x"`, `"loop": "once"`, `"next": "idle"`)

---

## 1. Shared Cel Spec v2 & Acting Rules

Every signature clip must obey `docs/ANIMATION_PLAN.md` §1:
- **Canvas:** 768 × 768 px, sRGB, transparent background, straight alpha, no white/black fringe.
- **Registration:** Ground/paw baseline at **y = 690 px** (`0.898`); body center at **x = 384** in starting/ending poses.
- **Head-height lock:** Standing/sitting top of head (excluding ears/horns/antlers) at **y = 170 px ± 6** on frame `01` and final settle frame, matching `i1` within ≤ 3% bbox height variance.
- **Facing & Lighting:** 3/4 left-facing (matching `f1` and `i1`). Soft window light from **upper-left**; watercolor paper grain & warm dark-brown/charcoal outlines matching each pet's `f1`–`f6` model sheet.
- **Arc & Overlap:**
  1. **Frames `01`–`02` (Anticipation):** Pull slightly back/up or inhale from `i1` so the action reads cleanly before firing.
  2. **Frames `03`–`06` (Core Action):** Clear silhouette peak, FX/prop integrated into the cel (watercolor wash, same line weight).
  3. **Frames `07`–`10/12` (Follow-Through & Settle):** Secondary elements (wings, tail, ears, ruff, leaves) lag by 1–2 frames and settle smoothly back toward `i1` so `signature -> idle` has zero pop.
- **Holds & Timing:** Export unique drawings only (`01.png`..`NN.png`); author holds in `manifests/pet_XX.json` (`holds`).

---

## 2. `pet_02` — 杜松 (Juniper · Tuxedo Demon Cat) · Drawn by **Codex**

**Lore hook (`PetCatalog` / `SunroomRoamingEngine`):** 「頭頂彎曲黑曜小角的貓型惡魔，總把摺得方正的小紙符安靜放在朋友身旁。」Drops an `OrigamiCharmDrop` onto the floor.
**Clip length:** **10 unique frames**, `fps: 10`, `loop: "once"`, `next: "idle"`, `holds: { "6": 3, "10": 2 }` (total ~1.3 s).
**Model sheet locks:** Charcoal-slate coat (`#1E242B`), crisp white muzzle/chest bib/4 paw socks, tiny white brow tufts, golden-amber almond eyes with vertical slit pupils, curved dark crimson-burgundy horns, burgundy bat wings (near wing visible extending viewer-right; far wing tucked/barely peeking), spade/heart-tipped tail.

### Beat-by-Beat Frame Breakdown

| Frame | Phase | Body & Pose | Head, Face & Appendages | Origami Prop & Notes |
|---|---|---|---|---|
| `01` | Start (match `i1`) | Sitting centered at x=384, paws on y=690 | Alert golden eyes looking slightly down-left; horns & ears upright | Matches `i1` silhouette cleanly |
| `02` | Anticipation | Slight chest lift + weight shift back; right forepaw lifts ~18 px off floor | Chin tucks slightly; eyes narrow in concentration; near wing hitches slightly up | Holds a tiny folded dark-charcoal/gold paper square tucked near chest |
| `03` | Lean & Reach | Torso leans forward-left; front left paw stays planted at y=690, right paw reaches forward-down | Ears angle slightly forward; tail curls up in counterbalance | Origami star/crane charm (`#2C333D` with `#E4BE6A` gold fold line) travels down with right paw |
| `04` | Placement Contact | Low crouch bow; right forepaw presses gently down to floor line y=690 at ~x=275 | Eyes glance down at placement spot; near wing spreads slightly for balance | Charm touches floor at **x ≈ 265, y = 690** (`events: { "charmPlace": [4] }`) |
| `05` | Delicate Nudge | Right paw lifts ~8 px and nudges charm edge to align it squarely | Cheek puffs slightly; tail heart-tip flicks right-to-left (1-frame lag) | Charm sits crisp & square on floor; subtle warm paper shadow underneath |
| `06` | **Peak / Admire** *(hold 3)* | Pulls torso partway back into a proud sit; paws together | Chin up, side-glance at charm with half-lidded satisfied tsundere blink; tiny smirk | Charm rests neatly at x=265, y=690 with a faint 2 px warm gold glint |
| `07` | Tsundere Snap-Back | Chest pops upright; right paw pulls cleanly back to chest/ground | Head turns slightly away (viewer-left profile → 3/4), eyes averted bashfully (`>` `<` or cool side-eye), faint rose cheek tint | Charm begins fading softly out over 2 frames OR stays crisp through `08` then dissolves cleanly so `idle` loop doesn't pop |
| `08` | Wing & Tail Follow-Through | Settling into sitting posture at x=384 | Near wing drops back down; ear twitches; tail settles behind haunch | Charm fades to ~45% watercolor wash (code spawns interactive `OrigamiCharmDrop` at floor) |
| `09` | Cushion Settle | Subtle chest exhale down ~3 px | Eyes blink half-way back to calm amber; horns/ears level | Charm gone (clean floor) |
| `10` | Settle *(hold 2)* | Matches `i1` sitting silhouette & head y=170 | Calm neutral expression matching `i1` | Ready to hand off to `"idle"` |

**Thumbnails (pose arc):**
`[01 sit] → [02 lift+tuck] → [03 lean down] → [04 place@690] → [05 square-nudge] → [06 proud glance*] → [07 look-away] → [08 wing settle] → [09 blink] → [10 i1]`

**Check on sight:** White bib & 4 paw socks stay intact; crimson horns never flip or vanish; spade-tail tip stays heart-shaped; no extra toes on reaching paw.

---

## 3. `pet_03` — 餘燼 (Cinder · Dragon-Cat) · Drawn by **Gemini**

**Lore hook (`PetCatalog` / `SunroomRoamingEngine`):** 「以為自己是普通街貓的赤炎幼龍，背上陶瓦龍鱗會吐出微溫把毛毯烘得暖烘烘。」
**Clip length:** **10 unique frames**, `fps: 10`, `loop: "once"`, `next: "idle"`, `holds: { "6": 2, "10": 2 }`.
**Model sheet locks:** Smoky taupe-brown coat (`#6D5B55`), cream-buff paw socks & chest ruff, cream-ochre ringed horns, **terracotta dorsal scales** (3 on forehead between horns + ridge down spine & tail upper edge + pinecone-like scale cluster at tail tip), smoky taupe bat/dragon wings (near wing extends viewer-right, far wing tip peeks behind neck), fiery amber-orange almond eyes.

### Beat-by-Beat Frame Breakdown

| Frame | Phase | Body & Pose | Head, Face & Appendages | Hearth Breath FX |
|---|---|---|---|---|
| `01` | Start (match `i1`) | Sturdy sitting pose at x=384, paws y=690 | Calm amber eyes looking left | None |
| `02` | Inhale Anticipation | Chest & fluffy ruff expand outward/upward; paws plant firmly | Head tilts slightly back/up; dorsal scales warm slightly brighter terracotta-amber; wings lift ~10 px | None |
| `03` | Breath Aim | Front shoulders dip slightly forward-left toward floor in front of paws | Muzzle angles down-left (`~30°`), cheeks puff slightly, eyes half-squint happily | Tiny warm golden ember spark forms just past lips (`x ≈ 270`) |
| `04` | **Warm Exhale** | Torso leans gently forward, tail lifts slightly off floor | Mouth slightly open (`o` shape, small cute fang hint), ears angled comfortably back | Soft curling watercolor breath plume (`#F5B864` → `#FFE39C` wash, soft feathered edge, NO jagged cartoon fire) arcs down to `x ≈ 170–260, y = 665–690` (`events: { "hearthWarm": [4] }`) |
| `05` | **Plume Bloom** | Holds gentle forward lean; chest settles from exhale | Eyes curved in happy warm squint; near wing opens slightly | Plume curls upward in 2–3 gentle golden-amber spiral wisps + 3 tiny floating ember motes |
| `06` | **Glow Peak** *(hold 2)* | Relaxing upright; tail pinecone tip glows soft warm amber | Happy closed-eye smile; cheek blush | Breath plume breaks into 4 rising warm watercolor motes (`#F29D4B`) fading softly |
| `07` | Follow-Through | Chest returns to neutral; dorsal ridge settles | Tongue tiny-licks corner of muzzle; wings drop down by 1 frame lag | Last 2 warm motes drift high & fade to 15% alpha |
| `08` | Tail Settle | Sitting steady at x=384 | Head levels; eyes open 70% | None |
| `09` | Soft Blink | Micro-breath settle | Calm blink (`f2`-like soft lid) | None |
| `10` | Settle *(hold 2)* | Exact `i1` silhouette & head y=170 | Calm amber eyes, neutral cozy sit | Ready for `"idle"` |

**Check on sight:** All 3 forehead scales + spine/tail scales stay consistent; breath looks like cozy watercolor hearth warmth (translucent amber wash), NOT aggressive laser fire; far wing tip still peeks cleanly behind neck.

---

## 4. `pet_04` — 摺翼 (Foldwing · Twilight Bat-Cat) · Drawn by **Codex**

**Lore hook (`PetCatalog` / `SunroomRoamingEngine`):** 「身披星塵暮色蝠翼的貓型夜魔，張開細摺翅膀替打盹的夥伴擋住刺眼光線。」
**Clip length:** **10 unique frames**, `fps: 10`, `loop: "once"`, `next: "idle"`, `holds: { "5": 3, "10": 2 }` (total ~1.3 s).
**Model sheet locks:** **NO horns.** Dusty lavender-violet coat (`#5B5266`), pale lilac chest fluff, lower paws, and plush tail upper highlight/tip, very tall pointed bat-like ears, pale mint-green almond eyes with pale lilac oval brow spots, **large dark charcoal-violet bat wings** (in `i1`/`f1`: near/left wing folded down along flank, outer rim of far wing peeks along viewer-left chest).

### Beat-by-Beat Frame Breakdown

| Frame | Phase | Body & Pose | Wings & Tail | Shading / Canopy Notes |
|---|---|---|---|---|
| `01` | Start (match `i1`) | Slender sitting pose at x=384, paws y=690 | Near wing folded along flank; far wing rim peeks at left chest | Matches `i1` cleanly |
| `02` | Squint Anticipation | Slight crouch-tuck (~10 px lower head); paws gather inward | Tall bat ears twitch slightly; wings tense/lift away from ribs by ~15 px | Mint eyes squint gently as if noticing bright sunbeam from upper-left |
| `03` | Lift & Unfurl Start | Rises onto haunches/hind paws, chest lifted tall | Both wings sweep upward and outward from shoulders (elbows high, membranes half-opened); tail curls smoothly right | Wing membranes show subtle twilight stardust speckles (`#9183A0` soft dots) |
| `04` | Canopy Sweep | Steady upright crouch-stand; hind paws grounded at y=690 | Wings arch forward and overhead toward viewer-left, forming an umbrella-like twilight arc | Soft cool lavender-violet shadow gradient begins under wing arch |
| `05` | **Wing-Shade Peak** *(hold 3)* | Calm protective stance; head tucked softly beneath wing-arch shoulder | **Full wing-shade canopy:** near wing arches high-left across upper-left (`y ≈ 115–220`), far wing fans behind/left to create a wide hooded curtain; gentle calm blink/half-lid | Subtle translucent twilight shade wash underneath canopy (`events: { "wingShade": [5] }`) |
| `06` | Soft Sway | Micro-settle downward (~4 px) | Wingtips flutter/dip gently by ~8 px (secondary overlap); tail tip curls lazily | Shade glow softly softens |
| `07` | Begin Fold | Weight lowers back onto sitting haunches | Wings begin folding backward along elbow joints; ears relax slightly | Far wing tucks back behind chest; near wing sweeps back toward flank |
| `08` | Wrap & Tuck | Sitting paws touch y=690 | Near wing drapes down along body flank; tail wraps neatly around hip | Wing membranes fold cleanly without snapping |
| `09` | Feather/Fur Settle | Small chest exhale | Wingtips settle flush; mint eyes open peacefully | Subtle ear-tip settle |
| `10` | Settle *(hold 2)* | Exact `i1` silhouette & head y=170 | Near wing folded along flank, far wing rim peeking at left chest | Ready for `"idle"` |

**Thumbnails (pose arc):**
`[01 sit] → [02 squint-tuck] → [03 rise+lift wings] → [04 sweep forward] → [05 canopy shield*] → [06 gentle sway] → [07 fold back] → [08 tuck flank] → [09 settle] → [10 i1]`

**Check on sight:** **Never add horns** to `pet_04` (only `pet_02`, `pet_03`, `pet_06` have horns). Both wings attach cleanly at the shoulder blades; mint eyes and lilac brow ovals stay intact; near wing folds back to exact `i1` placement.

---

## 5. `pet_07` — 梅子 (Plum · Silver-Moon Spirit Hound) · Drawn by **Gemini**

**Lore hook (`PetCatalog` / `SunroomRoamingEngine`):** 「身周縈繞柔白雲絮與星光的銀月星靈犬，只要同伴停下腳步，牠也會一起放慢呼吸。」
**Clip length:** **10 unique frames**, `fps: 10`, `loop: "once"`, `next: "idle"`, `holds: { "5": 2, "10": 2 }`.
**Model sheet locks:** Creamy off-white curly woolly coat (`#E2E8F0` / ivory with warm stone-grey curl shading), puffy drooping curly ears, puffy curled tail, round dark-brown button eyes, cream cloud ruff at front neck + long swirling cloud ribbon sweeping back across near/left shoulder toward viewer-right, faint pale-yellow 4-point star sparkles on crown/viewer-right ear.

### Beat-by-Beat Frame Breakdown

| Frame | Phase | Body & Pose | Cloud Ruff & Stars | Mist Puff FX |
|---|---|---|---|---|
| `01` | Start (match `i1`) | Fluffy sitting pose at x=384, paws y=690 | Cloud ribbon sweeps back across near shoulder; crown stars subtle | None |
| `02` | Calm Inhale | Chest lifts gently; shoulders round softly | Eyes close into serene curved arcs; cloud ruff swells slightly | None |
| `03` | Gentle Shake Prep | Head dips slightly (~8 px); fluffy ears swing slightly inward | Cloud ribbon coils slightly tighter around neck | Faint pearlescent silver-cream ring begins forming at collar |
| `04` | **Mist Exhale / Ruff Bloom** | Head lifts & gives a soft, slow shake (never frantic) | Cloud ruff expands outward in a soft concentric ring; crown stars brighten | Translucent ivory-silver mist puffs (`#F7FAFC` / `#D6E2EC` soft watercolor bloom) drift out left & right (`events: { "mistPuff": [4] }`) |
| `05` | **Moonlit Aura Peak** *(hold 2)* | Upright tranquil sit; head slightly tilted in kindness | Cloud ribbon floats gently buoyant (~6 px higher); 4–5 tiny pale-gold 4-point stars twinkle in the mist | Soft crescent-soft mist halo wraps loosely around lower shoulders & floats upward |
| `06` | Drift & Breathe | Gentle exhale downward | Eyes open softly to warm calm smile; mist puffs break into drifting cloudlets | 3 small cloud wisps drift upward-right and upward-left |
| `07` | Ear & Tail Lag | Body settled; ears & puffy tail finish gentle bounce | Cloud ribbon settles smoothly down onto shoulder | Mist wisps thin to ~40% alpha |
| `08` | Star Fade | Calm sitting posture | Trailing wisps fade to ~15% alpha | Only core collar cloud ruff remains |
| `09` | Soft Blink | Micro-settle | Calm blink/settle | None |
| `10` | Settle *(hold 2)* | Exact `i1` silhouette & head y=170 | Matches `i1` cloud ribbon & ear placement | Ready for `"idle"` |

**Check on sight:** Cloud ribbon stays on the **near/viewer-right shoulder** (never switches sides); woolly scalloped coat lines remain delicate warm-taupe; mist looks airy and watercolor-washed, not opaque cotton balls.

---

## 6. `pet_08` — 蘆葦 (Reed · Antlered Marsh Hound) · Drawn by **Gemini**

**Lore hook (`PetCatalog` / `SunroomRoamingEngine`):** 「頭頂抽著嫩綠新葉小鹿角的森靈犬，總能在積水的巷弄裡一眼找到乾燥的石階。」
**Clip length:** **10 unique frames**, `fps: 10`, `loop: "once"`, `next: "idle"`, `holds: { "5": 2, "10": 2 }`.
**Model sheet locks:** Tall/slim spaniel-setter build, rich russet-amber/chestnut coat (`#A67644`), cream snout blaze, cream throat/chest ruff, cream inner belly/paw tips, 2 cream oval brow dots, long wavy feathered ears, **STRICTLY ASYMMETRIC ANTLERS:**
- Dog's right antler (**viewer-left**): **2 main tines** + 2 sage-green leaves near tips.
- Dog's left antler (**viewer-right**): **3 main tines** + 2 sage-green leaves (middle-upper & outer-right tips).

### Beat-by-Beat Frame Breakdown

| Frame | Phase | Body & Pose | Antlers & Ears (Asymmetric!) | Leaf Sprout FX |
|---|---|---|---|---|
| `01` | Start (match `i1`) | Tall graceful sit at x=384, paws y=690 | 2-tine antler (viewer-left) & 3-tine antler (viewer-right) with 2 leaves each | Resting state |
| `02` | Alert Anticipation | Chest rises slightly; snout lifts ~8° | Feathered ears perk slightly outward; head dips 5° before shake | Tiny pale-lime bud swell appears at upper tine tips |
| `03` | Antler Shake Left | Crisp, graceful head tilt left | Viewer-left 2-tine & viewer-right 3-tine antlers swing slightly left; feathered ears trail by 1 frame | 2 tiny new sage-lime sprout buds unfurl at tine tips (`#8FC488` / `#588A62`) |
| `04` | **Antler Shake Right / Sprout** | Head swings smoothly back slightly right | Antlers catch warm emerald-gold rim gleam; ears follow through | New fresh leaves pop open on both antlers + 3 detached floating tiny forest leaves & dew-gold firefly motes release (`events: { "leafSprout": [4] }`) |
| `05` | **Sprout Peak** *(hold 2)* | Proud tall sit; chest out, cream ruff fluffed | **2-tine (left) / 3-tine (right) unmistakably clear;** tiny warm yellow-green firefly glow (`#E5F29B`) around antler tips | 4–5 small sage leaves + soft dew sparkles float gently outward & down |
| `06` | Gentle Follow-Through | Head returns to centered 3/4 left | Feathered ears swing smoothly back to rest along cheeks | Detached floating leaves drift downward at ~35% alpha |
| `07` | Ear & Tail Settle | Sleek feathered tail wags softly behind right hip | Rosy-warm content expression, amber eyes bright | Last 2 floating leaf motes drift low and fade |
| `08` | Sprout Absorb / Calm | Breathing settle | Fresh antler leaves relax back to standard 2+2 leaf count seamlessly | Floor/air motes gone |
| `09` | Calm Blink | Micro-exhale | Soft blink | None |
| `10` | Settle *(hold 2)* | Exact `i1` silhouette & head y=170 | Matches `i1` antler geometry & ear drape | Ready for `"idle"` |

**Check on sight:** Viewer-left antler MUST have **2 tines** and viewer-right antler MUST have **3 tines** in every single frame (never symmetrical!). Snout blaze and cream brow dots stay crisp.
