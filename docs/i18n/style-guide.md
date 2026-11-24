# Pawprint Days (足印日記) — Localization Style Guide

**Languages:** Traditional Chinese (zh-Hant, Source) · English (EN) · Japanese (JA)  
**Target Release:** iOS 17+ (SwiftData, Metal PaperGrain Shader, WidgetKit, Dynamic Island)  
**Aesthetic Reference:** Taiwanese/Japanese watercolor stationery, picture books (Arnold Lobel's *Frog and Toad*, Beatrix Potter, Studio Ghibli storybooks).

---

## 1. Core Narrative Voice & Philosophy

Pawprint Days is an unhurried, cozy walking companion and mystical-pet life-sim. The tone must never feel like a high-friction free-to-play mobile game. Every line of text should read like an entry in an artist's personal travel journal or a page from a clothbound children's storybook.

### 1.1 The Four Cardinal Rules

1. **Second-Person Intimate ("You"):**  
   The player is the quiet walker stepping onto rain-washed flagstones. Speak directly to them with warmth and tenderness. Never use cold, bureaucratic, or instructional third-person language ("The user can tap...").
2. **Zero FOMO, Zero Guilt:**  
   There are no "broken streaks," no "daily penalties," and no countdown timers pressuring the player. If the player hasn't walked in a week, their companions welcome them back with quiet purrs and tea, not reprimands.
3. **Grounded Sensory Details:**  
   Ground every observation in physical, tactile sensations: the scent of toasted sesame, the warmth of terracotta tiles, the damp chill of rain on stone steps, the whisper of dry folded paper, the tiny bell ringing on an embroidered collar.
4. **Restraint Over Hyperbole:**  
   Companions express affection through subtle gestures: a tucked paw, a slow blink, a nudged paper star, a tail curled gently against shoes. Never use noisy game slang (*Awesome!*, *Level Up!*, *Mega Combo!*, *Claim Now!*).

---

## 2. Voice & Tone by Language

### 2.1 Traditional Chinese (zh-Hant, Taiwan Baseline)
- **Register:** Gentle, poetic, restrained Taiwanese storybook prose (國語日報 / 台灣溫暖繪本風格).
- **Key Characteristics:**
  - Sentences are brief and lyrical, leaving breathing room.
  - Natural local terms like 騎樓 (*kî-lâu*, shophouse covered walkway), 瓦楞紙箱, 泡茶, 步數幣.
  - Animal pronoun 「牠」 is used warmly and respectfully.

### 2.2 English (EN)
- **Register:** Classic English pastoral picture-book (evoking A.A. Milne, Arnold Lobel, and Kenneth Grahame).
- **Tone & Word Choice:**
  - Favor earthy Anglo-Saxon roots over cold Latinate technical jargon:
    - *Warmth, soft, snuggle, tuck, stroll, companion, keepsake, treat, quiet*
    - **Avoid:** *utilize, obtain, interact, execute, duration, currency, trigger, navigation*
  - Use short, cadence-rich sentences with natural rhythm.
  - When greeting the player, use gentle modal verbs (*Would you like to...*, *Let's pause here for a moment*, *Whenever you're ready*).
- **Pronouns:**
  - Companions have defined genders in `PetCatalog.swift` (`.male` or `.female`), but the game narrative often treats them with affectionate names or gender-neutral "they/them".
  - Prefer using their proper name (*"Juniper curled up beside your shoes"*) or natural pronouns (*"He nudged the folded star forward"*). Avoid sterile "it".

### 2.3 Japanese (JA)
- **Register:** Gentle, literary picture-book Japanese (絵本調・温かみのある日常語).
- **Duality of Styles:**
  - **System & UI Prompts (丁寧語・です・ます・〜してみてね):**
    - Soft, polite, inviting.
    - *Example:* 「雨の日のお散歩へ、いっしょに出かけませんか？」「窓辺のクッションにおやつを置きました。」
  - **Diary & Narrative Scene Slips (常体・体言止め・〜だった・〜している):**
    - Observational, personal diary entries.
    - *Example:* 「靴のそばに寄り添い、静かに雨宿りをした。」「鼻先でパッチワークボールをちょこんと押し戻す。」
- **Vocabulary Guidance (和語優先):**
  - Favor native Japanese words (和語) over hard loan words (カタカナ語):
    - **Use:** お散歩 (not ストロール), ひろいもの (not アイテム / キュリオ), おめかし (not コスチューム), まち / 街区 (not オーバーワールド), 陽だまり (not サンシャイン).
  - Use affectionate pet honorifics appropriately in dialogue (「ジュニパーくん」「うめちゃん」) while keeping system catalogs clean (「ジュニパー」「うめ」).

---

## 3. Side-by-Side Tone Examples

| Context | Traditional Chinese (Source) | English (Cozy Storybook) | Japanese (絵本調) | Notes |
|---|---|---|---|---|
| **Street Encounter (First Met)** | 杜松擺了擺彎鉤尾巴，把一張摺整齊的小紙片推到你鞋邊。 | Juniper flicked his hooked tail and pushed a neatly folded paper slip right to your shoe. | ジュニパーは鍵しっぽをゆらし、きれいに折った小紙片をそっと靴のそばへ押し出した。 | Concrete, tactile actions; no floating game UI popups. |
| **Street Encounter (Milestone)** | 餘燼在微風中躲進屋簷，背上的赤陶小鱗透著淡淡暖光。 | Ember ducked under the eaves against the breeze, the terracotta scales on his back glowing with faint warmth. | ジンはそよ風を避けて軒下へもぐり込み、背中の赤瓦鱗をぽっと温かく光らせた。 | Highlights pet's magical yet quiet species trait. |
| **Tactile Care (Belly Rub)** | 呼嚕嚕～(吐出一朵暖暖小火星) | Purr-purr... (puffs out a tiny, warm spark) | ごロゴロ…（ぽっと温かい火の粉をひとつ吐き出した） | Soft sound effects with delicate parenthetical action. |
| **Diary System Sentence** | 在老街騎樓初次遇見梅子，牠湊上前輕嗅我攤開的手背。 | First crossed paths with Plum beneath the heritage shophouse arcade; she stepped forward to gently sniff the back of my open hand. | レトロ横丁の軒下で、うめと初めて出会った。そっと近寄って、差し出した手の甲をくんくん嗅いだ。 | Objective record in diary; avoids presuming player's personal emotions. |
| **Pedometer Reminder** | 走滿 1,500 步返家回贈 +9 步數幣，並添上暖意手記。 | Reach 1,500 steps and return home to receive +9 Step Coins and a cozy diary note. | 1,500歩あるいておうちに帰ると、歩数コインが+9枚。心温まる手記も添えられます。 | Informative without sounding transactional. |
| **Empty Satchel** | 零消耗，步數與街角相遇完全照常進行。 | Pure walking at zero cost. Step counts and corner meetings carry on just as always. | 消費ゼロで身軽なお散歩。歩数も街角の出会いも、いつも通り楽しめます。 | Reassures the player that casual walks are 100% complete. |

---

## 4. Punctuation & Formatting Conventions

| Element | Traditional Chinese | English | Japanese | Rule & Example |
|---|---|---|---|---|
| **Quotation Marks** | 「Corner」『Inside』 | “Corner” ‘Inside’ | 「Corner」『Inside』 | EN uses curly quotes `“”` / `‘’`. Never use straight quotes `""` in user-facing text. |
| **Ellipsis** | …… (two 3-dot chars) | … (single U+2026 glyph) | …… (two 3-dot chars) | In EN, use one real ellipsis `…`, not three periods `...`. |
| **Middle Dot / Bullet** | 3 天 · 互動 12 次 | 3 days · 12 interactions | 3日 · 12回のふれあい | Use middle dot `·` (U+00B7) for inline metadata separated by spaces. |
| **Exclamation Points** | Very rare (reserved for puppy hops) | Very rare | Very rare | Never stack exclamations (`!!`). Keep the voice tranquil. |
| **Numbers & Counts** | 1,500 步 / 2 位室友 | 1,500 steps / 2 roommates | 1,500歩 / 2匹のルームメイト | Always format thousands with commas in EN and JA (`1,500`). |
| **Currencies & Plus** | +9 步數幣 | +9 Step Coins | +9 歩数コイン | Place sign directly in front of the digit (`+9`), followed by space and currency name. |
| **Brackets & Notes** | （ ）全形括號 | ( ) half-width parens | （ ）全形括號 | EN uses standard ASCII parens with outer spacing; zh/JA use full-width. |

---

## 5. String Interpolation & Grammatical Challenges

### 5.1 Positional Placeholders
Swift string interpolation `\(spec.name)` works in hardcoded Swift, but in String Catalogs (`.xcstrings`), arguments must be indexed to allow reordering across language syntax:
- **zh-Hant:** `在\(anchorLabel)初次遇見\(spec.name)` (Preposition + Place + Verb + Name)
- **English:** `First crossed paths with %2$@ at %1$@` (Verb + Name + Preposition + Place)
- **Japanese:** `%1$@で%2$@と初めて出会った` (Place + で + Name + と + Verb)

> [!IMPORTANT]
> Always use numbered positional specifiers (`%1$@`, `%2$@`, `%1$d`) in localized formats so English and Japanese translators can reorder sentence components freely.

### 5.2 Pluralization & Counts in English
English requires explicit singular and plural forms for counted nouns:
- 1 Step Coin vs 12 Step Coins
- 1 companion vs 3 companions
- 1 shared day vs 5 shared days

**Strategies:**
1. In Xcode String Catalogs, utilize `.xcstrings` plural variants (`one`, `other`).
2. Where single-key formatting is constrained in UI headers, use neutral noun-label phrasing:
   - *Instead of:* `%d coins`
   - *Use:* `Step Coins: %d` or `In Pouch: %d`

### 5.3 Pet Gender & Pronoun Agreements
Companions are individuals with rich personalities. In Chinese, `牠` is universally applied to pets.
- **English Translation:**
  - Avoid objectifying companions with "it".
  - If gender is fixed (e.g. Juniper ♂, Plum ♀), use "he/him" or "she/her".
  - When the string can apply to any companion dynamically, use the pet's name or singular "they/them".
- **Japanese Translation:**
  - Avoid awkward third-person pronouns (「彼」「彼女」「それ」).
  - Simply repeat the pet's name (「ジュニパーが」「うめが」) or omit the subject naturally (日本語の主語省略).

---

## 6. Length Guidance & UI Overflow Risk Audit

Traditional Chinese is remarkably compact: single ideograms pack entire concepts (e.g., 陽光室 is 3 characters; 拾遺 is 2 characters).
- **English** typically expands to **250%–350%** of the character count.
- **Japanese** typically expands to **150%–200%** of the character count (due to hiragana particles and okurigana).

### 6.1 Top 6 High-Risk UI Hotspots

```
+-------------------------------------------------------------------+
|  [HIGH-RISK OVERFLOW AUDIT: PAWPRINT DAYS MOBILE STAGE]          |
+-------------------------------------------------------------------+
| 1. CozyFloatingDockBar: [ 街區 ] [ 陽光室 ] [ 日記 ] [ 小舖 ]     |
|    - zh-Hant: 2 chars/tab                                         |
|    - EN Risk: "Neighborhood" / "Curio Cubbies" WILL COLLAPSE BAR  |
|    - EN Solution: "Street" / "Home" / "Diary" / "Shop" (4-5 chars)|
|    - JA Solution: "まち" / "お部屋" / "日記" / "小店" (2-3 chars) |
+-------------------------------------------------------------------+
| 2. Weather Curio Set Chips: "細雨微涼 領 +5"                      |
|    - EN Risk: "Cool Drizzle Claim +5" clips inside scroll capsule |
|    - Solution: Compact format: "Rainy +5" or icon + "+5"          |
+-------------------------------------------------------------------+
| 3. Street Overworld HUD Pill: "75m 街角 · 晴朗晨光"               |
|    - EN Risk: "75m Street Corner · Crisp Morning Sun" wraps to 2L |
|    - Solution: "75m Corner · Morning Sun"                         |
+-------------------------------------------------------------------+
| 4. Sidewalk Encounter Paper Slip: Paper strip overlay             |
|    - EN Risk: 3-line paragraph covers pet's watercolor face       |
|    - Solution: Cap encounter lines to max 90 characters in EN     |
+-------------------------------------------------------------------+
| 5. Tactile Care Texture Chips: "「香脆」手作茶點"                 |
|    - EN Risk: "'Crispy' Handmade Treats" exceeds tab width        |
|    - Solution: "Crispy Treats"                                    |
+-------------------------------------------------------------------+
| 6. Lock Screen / Small Widget: Strict 1-line budget               |
|    - EN Risk: Truncates with "..." midway                         |
|    - Solution: Keep widget strings <= 22 characters               |
+-------------------------------------------------------------------+
```

### 6.2 Specific Hotspot Rules

1. **Floating Dock Bar (`CozyFloatingDockBar.swift`):**
   - The capsule width is bounded to ~340pt on standard iPhones.
   - **Enforced Short Labels:**
     - 街區 → EN: `Street` · JA: `まち`
     - 陽光室 → EN: `Home` · JA: `お部屋`
     - 日記 → EN: `Diary` · JA: `日記`
     - 小舖 → EN: `Shop` · JA: `小店`
2. **Street HUD Status Bar (`StreetOverworldView.swift`):**
   - Location Quality:
     - `GPS 極精準` → EN: `GPS: High` · JA: `GPS: 良好`
     - `搜尋精準定位…` → EN: `Locating…` · JA: `測位中…`
3. **Widget Labels (`PawprintDaysWidgets.swift`):**
   - Lock screen accessory widgets have extreme character constraints (~14 chars max).
   - Use short, poetic phrases:
     - `在街角守候著你` → EN: `Waiting at corner` · JA: `街角で待機中`
     - `今日散步 %d 步` → EN: `%d steps today` · JA: `今日のお散歩 %d歩`

---

## 7. Quality Checklist for Translators

Before committing any string or reviewing a pull request:
- [ ] Is the voice quiet, warm, and second-person?
- [ ] Are all game-y buzzwords removed (*no "tokens", "EXP", "gacha", "grind"*)?
- [ ] Are single real curly quotes `“”` and proper ellipses `…` used in English?
- [ ] Have all String Catalog arguments used indexed specifiers (`%1$@`, `%2$d`)?
- [ ] Has the text been checked against the 6 High-Risk UI Hotspot width limits?
- [ ] In Japanese, is polite `です・ます` used in prompts and gentle `常体` used in diary stories?
- [ ] Do pet names and species strictly match `docs/i18n/glossary.md`?
