# Pawprint Days (足印日記) — Localization Glossary

**Target Languages:** Traditional Chinese (zh-Hant, Source) → English (EN) → Japanese (JA)  
**Version:** 1.0 (Phase 3 Localization Preparation)  
**Tone & Voice:** Warm, storybook, gentle, unhurried, second-person intimate.

---

## 1. Game Title & Core Concept

| zh-Hant (Source) | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Context & One-Line Note |
|---|---|---|---|---|---|
| 足印日記 | Pawprint Days | Footprints & Whiskers | あしあと日記 | 足あとデイズ | Core title: cozy walking + mystical-pet life-sim companion game. |
| 步數幣 | Step Coins | Paw Coins | 歩数コイン | あしあとコイン | In-game currency earned purely by walking real-world steps (1 coin per 200 steps). |
| 足印散步 / 散步 | Pawprint Stroll / Stroll | Walking Journey | 足あと散歩 / お散歩 | おでかけ散歩 | Walking session tracking real-world steps and encountering companions at street corners. |
| 街角相遇 | Sidewalk Encounter | Corner Meeting | 街角の出会い | 辻のめぐり逢い | 75 m geofenced encounter where you meet a mystical pet and greet with gestures. |
| 陽光室 | Sunroom | Solarium | サンルーム | 陽だまりの部屋 | 2.5D watercolor home stage where companions rest, play, eat snacks, and socialize. |
| 精裝日記 / 日記 | Hardcover Diary / Diary | Sketchbook Journal | 上製本日記 / 日記 | スケッチブック日記 | Hardcover watercolor keepsake recording daily strolls, encounters, photos, and notes. |
| 口袋拾遺 | Pocket Finds | Street Curios | ポケットの落としもの | 街のひろいもの | Qualitative tactile curios found automatically every 1,400 steps; zero rarity gacha. |
| 跨物種傳承計畫 | Inter-Species Mentorship | Cross-Species Heritage | 種族をこえた伝承 | 異種族のやさしい伝承 | Senior pets teach signature habits to other species via shared walking and props. |

---

## 2. The 6 Mystical Companions

Companions are not fantasy monsters or battle pets; they are gentle magical spirit animals coexisting with quiet city alleys.

### 2.1 Overview Table

| ID | zh-Hant Name | English (Rec.) | English (Alt.) | Japanese (Rec.) | Japanese (Alt.) | Species (zh-Hant) | Species (EN) | Species (JA) | Folklore Category (zh-Hant / EN / JA) |
|---|---|---|---|---|---|---|---|---|---|
| `pet.02` | 杜松 | Juniper | Obsidian | ジュニパー | ネズ | 黑曜惡魔貓 | Obsidian Demon Cat | 黒曜の悪魔猫 | 貓型惡魔 / Feline Demon / 猫型悪魔 |
| `pet.03` | 餘燼 | Ember | Cinder | ジン | エンバー | 赤瓦龍貓 | Terracotta Dragon Cat | 赤瓦の竜猫 | 貓型火龍 / Feline Fire Drake / 猫型火竜 |
| `pet.04` | 摺翼 | Flitter | Vesper | オリハ | ベスパー | 暮光夜魔貓 | Twilight Nightwing Cat | 黄昏の夜魔猫 | 貓型夜翼 / Feline Nightwing / 猫型夜翼 |
| `pet.06` | 鈕扣 | Button | Pip | ボタン | ポタン | 墨玉小魔犬 | Inky Imp Hound | 墨玉の小魔犬 | 犬型小魔 / Canine Imp / 犬型小魔 |
| `pet.07` | 梅子 | Plum | Ume | うめ | プラム | 銀月星靈犬 | Silver-Moon Astral Hound | 銀月の星霊犬 | 銀月星靈 / Silver-Moon Astral Spirit / 銀月星霊 |
| `pet.08` | 蘆葦 | Reed | Fern | アシ | ススキ | 鹿角森靈犬 | Antlered Forest Hound | 鹿角の森霊犬 | 鹿角森靈 / Antlered Forest Spirit / 鹿角森霊 |

### 2.2 Companion Details & Signatures

| Name (zh / EN / JA) | Personality Word | Signature Habit | Habit Family | Resonance Weathers | Lore & Characteristics Note |
|---|---|---|---|---|---|
| **杜松**<br>Juniper<br>ジュニパー | 傲嬌講究<br>Particular & Fastidious<br>ツンデレで几帳面 | **契約摺紙**<br>Contract Origami<br>契約の折り紙 | 輕遞小物<br>(habit.offer) | 微陰多雲, 暖黃暮色<br>(Overcast, Dusk) | A dark feline imp with curved obsidian horns; aloof on the outside, quietly leaves folded paper talismans beside friends. |
| **餘燼**<br>Ember<br>ジン / エンバー | 溫柔小心<br>Gentle & Tender<br>優しく控えめ | **爐爪烘暖**<br>Hearthpaw Warmth<br>炉爪のぬくもり | 暖毯築窩<br>(habit.nest) | 細雨微涼, 雨後初晴<br>(Light Rain, Post-Rain) | A young flame drake who thinks he is an ordinary street cat; terracotta scales radiate gentle warmth that toasty-dries wet blankets. |
| **摺翼**<br>Flitter<br>オリハ / ベスパー | 好奇安靜<br>Quietly Curious<br>好奇心旺盛で物静か | **夜翼遮蔭**<br>Nightwing Shade<br>夜翼の木陰 | 遮蔭引路<br>(habit.shield) | 暖黃暮色, 晴朗晨光<br>(Dusk, Clear Morning) | Clad in stardust dusk bat-wings; unfurls delicate folded wings to shade napping companions from bright sunshine. |
| **鈕扣**<br>Button<br>ボタン | 忠厚貼心<br>Loyal & Thoughtful<br>実直で健気 | **幽火排鞋**<br>Will-o'-Wisp Shoe Tidying<br>幽火の靴そろえ | 輕遞小物<br>(habit.offer) | 微陰多雲, 細雨微涼<br>(Overcast, Light Rain) | Short-legged pup with rounded horns and floating violet wisps; loves neatly aligning entryway slippers and warming doormats. |
| **梅子**<br>Plum<br>うめ / プラム | 溫和耐心<br>Mild & Patient<br>おだやかで辛抱強い | **雲步伴行**<br>Cloudstep Pacing<br>雲歩の道連れ | 沉靜守候<br>(habit.wait) | 暖黃暮色, 微陰多雲<br>(Dusk, Overcast) | Surrounded by soft white clouds and silver starlight; slows her breathing and walking pace whenever a shy companion stops. |
| **蘆葦**<br>Reed<br>アシ / ススキ | 敏銳細心<br>Keen & Observant<br>聡明で細やか | **鹿角引路**<br>Antler Wayfinding<br>鹿角の道案内 | 遮蔭引路<br>(habit.shield) | 細雨微涼, 雨後初晴<br>(Light Rain, Post-Rain) | Tender green leaves sprout from her small antlers; instinctively leads friends across rainy alleys to dry stone stairs. |

---

## 3. Places, Screens & Architectural Features

Taiwanese and East Asian architectural motifs are central to the visual world (especially the sheltered sidewalk arcade, *kî-lâu* / 騎樓).

| zh-Hant (Source) | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Context & One-Line Note |
|---|---|---|---|---|---|
| 街區 | Neighborhood | Streets / Town | まち | 街区 | Main overworld screen displaying local street anchors and stroll pedometer. |
| 陽光室 | Sunroom | Solarium | サンルーム | 陽だまりの部屋 | Main indoor 2.5D room screen where resident pets roam and interact. |
| 日記 / 精裝手繪日記 | Diary | Hardcover Journal | 日記 / 上製本日記 | スケッチブック日記 | Book view containing chronological daily entries, calendar spread, and annual pacts. |
| 小舖 / 拾遺木格櫃與紀念小舖 | Curio Cubbies | Corner Keepsake Shop | ひろいもの小店 | こもの棚と記念小舗 | Shop and collection gallery for wardrobe, furnishings, treats, and curio sets. |
| 街角 / 轉角 | Street Corner | Neighborhood Anchor | 街角 | 辻 / 曲がり角 | 75 m MapKit anchor site where companions wait for the player. |
| 騎樓 | Shophouse Arcade | Covered Sidewalk | 騎楼（きろう） | 軒下アーケード | Traditional covered sheltered sidewalk; provides rain-shelter during strolls. |
| 雨廊木檐 | Rain Veranda Eaves | Covered Rain Porch | 雨宿りの雨廊 | 軒下ウッドデッキ | Sunroom home expansion adding 3 outdoor sheltered interaction spots (5 → 8 spots). |
| 門前街角 | Doorstep Corner | Home Street Corner | 玄関先の街角 | 門前の街角 | Initial guaranteed neighborhood anchor placed right outside player's real-life home. |
| 麵包店巷口 | Bakery Alleyway | Bakery Corner | パン屋の小路 | ベーカリー横丁 | Anchor site associated with bakery box, fresh dough scent, and red-and-white twine. |
| 溪畔步道 / 溪畔木椅 | Riverside Path / Bench | Stream Walk | 小川の遊歩道 / ベンチ | 渓流沿いの散歩道 | Anchor site by water; associated with polished pebbles and gentle drizzle. |
| 公園木椅 | Park Wooden Bench | Green Bench | 公園の木製ベンチ | 公園のベンチ | Anchor site for quiet resting and watching golden ginkgo leaves drift down. |
| 老街騎樓 / 騎樓廊下 | Old Town Arcade | Heritage Shophouse Walk | レトロ横丁の騎楼 | 古い軒下通り | Historic arcade sheltered from rain; home to cedar pinecones and umbrella ribbons. |
| 公車候車亭 | Bus Stop Shelter | Transit Stop | バスの待合所 | バス停のベンチ | Rain-sheltered bench where commuters drop old train ticket stubs. |
| 圖書館小院 / 圖書館騎樓 | Library Courtyard / Arcade | Quiet Library Corner | 図書館の中庭 / 軒下 | 図書館の小径 | Quiet reading alcove surrounded by fragrant cypress twigs and green shade. |
| 烘豆咖啡館 | Coffee Roastery | Café Corner | 焙煎コーヒー館 | 珈琲屋の店先 | Warm corner smelling of roasted beans; where Button discovered a vintage brass button. |
| 轉角雜貨店 | Corner Grocery Shop | General Store | 街角の駄菓子屋 | 四つ角の雑貨店 | Nostalgic local shop lit by evening streetlamps; origin of dusky glass marbles. |
| 茶行石階 | Teahouse Stone Steps | Traditional Tea Shop | 茶舗の石段 | お茶屋の階段 | Stone steps outside an oolong tea merchant; where porcelain shards are uncovered. |
| 河堤草坡 | River Embankment Lawn | Grassy Bank | 堤防の草地 | 川沿いの土手 | Grassy river slope where dandelion seed-fluff drifts on cloudy afternoons. |

---

## 4. Currency, Ledger & Progression Terms

| zh-Hant (Source) | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Context & One-Line Note |
|---|---|---|---|---|---|
| 步數幣 | Step Coins | Paw Coins | 歩数コイン | あしあとコイン | Primary currency earned by walking (1 coin per 200 validated steps). |
| 步數 | Steps | Daily Steps | 歩数 | 歩いた歩数 | Validated step count tracked by CoreMotion pedometer. |
| 今日散步步數 | Today's Stroll Steps | Walked Today | 今日のお散歩歩数 | 本日の歩数 | Steps taken during the current active calendar day. |
| 步數進度 | Step Progress | Stroll Milestone | 歩数進度 | 歩数の進み具合 | Progress toward next step coin reward or pocket curio find. |
| 零消耗 | Zero Cost | Pure Stroll | コストなし / 無料 | 消費ゼロ | Empty-handed stroll requiring 0 Step Coins with no resource burn if forgotten. |
| 刺繡步數幣袋 | Embroidered Coin Pouch | Step Coin Purse | 刺繍のコイン袋 | 刺し子の小銭入れ | UI wallet visual displaying player's Step Coin savings. |

---

## 5. Weather Modes (天氣模式)

Mapped directly to PaperGrain Metal shader and atmospheric lighting.

| zh-Hant (Source) | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Shader & Atmospheric Note |
|---|---|---|---|---|---|
| 晴朗晨光 | Crisp Morning Sun | Bright Morning | 晴れやかな朝光 | 晴天の朝 | Warm gentle sunlight; activates clear morning audio and paper grain shader (0.0). |
| 微陰多雲 | Gentle Overcast | Soft Clouds | 柔らかな薄曇り | 曇り空 | Diffused silver-white daylight; calm resting atmosphere (0.0). |
| 細雨微涼 | Cool Drizzle | Gentle Rain | しっとり小雨 | 涼やかな霧雨 | Cozy light rain; activates rain droplets, gentle puddle splashes, and shader (1.0). |
| 雨後初晴 | Clearing After Rain | Post-Rain Glow | 雨上がりの光 | 雨後初晴 | Golden sunlight breaking through lingering rain mist; fresh reflections (1.0). |
| 暖黃暮色 | Golden Twilight | Warm Dusk | 暖かな夕暮れ | 茜色の黄昏 | Amber evening streetlamp glow; brings out twilight and nightwing spirits (2.0). |

---

## 6. Room Themes (四季光影屋景)

Interior lighting and wall/floor watercolor palettes for the Sunroom.

| zh-Hant (Source) | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Palette & Visual Note |
|---|---|---|---|---|---|
| 春日暖木日光 | Sunlit Spring Wood | Spring Cedar Light | 春の木漏れ日 | 春暖の木漏れ日 | Default light wood floor with honey wall wash and warm sunbeams. |
| 梅雨季微霧光影 | Plum-Rain Season Mist | Soft Rain-Mist View | 梅雨の朝霧 | 梅雨時の微霧 | Cool mist-green wash with gentle rain streaks beyond the wide window. |
| 秋日紅檜餘暉 | Autumn Hinoki Dusk | Autumn Cedar Glow | 秋の紅檜と夕映え | 秋日杉の茜空 | Rich terracotta cypress grain bathed in low amber twilight rays. |
| 冬夜暖燈茶室 | Winter Night Lantern Tearoom | Winter Hearth Tearoom | 冬夜のともしび茶室 | 冬夜の灯り茶屋 | Deep roasted chestnut floor illuminated by an amber tabletop lamp. |

---

## 7. Greeting Gestures & Diary Verbs (打招呼手勢與動詞)

The quiet ritual performed at street corners. Companions are never captured; they are warmly greeted.

| Gesture (zh-Hant) | English (Rec.) | English (Alt.) | Japanese (Rec.) | Japanese (Alt.) | Diary Past Verb (zh-Hant) | Diary Past Verb (EN) | Diary Past Verb (JA) |
|---|---|---|---|---|---|---|---|
| 伸手輕輕打招呼 | Offer a Gentle Hand | Soft Hand Greet | そっと手を差し伸べる | やさしく手を出す | 湊上前輕嗅我攤開的手背 | stepped forward to gently sniff the back of my open hand | そっと近寄り、差し出した手の甲をくんくん嗅いだ |
| 坐在木凳靜靜陪伴 | Sit Quietly on the Bench | Quiet Bench Company | 木のベンチで静かに寄り添う | ベンチで静かに見守る | 安靜地窩在我的鞋邊 | snuggled quietly against my shoes | 靴のそばに静かにうずくまった |
| 滾出縫布球 | Gently Roll a Patchwork Ball | Roll a Cloth Ball | パッチワークボールを転がす | 縫い布ボールをころころ転がす | 用鼻尖把縫布球輕推回來 | gently nudged the patchwork ball back with its nose | 鼻先でパッチワークボールをちょこんと押し戻した |
| 撐傘一起躲雨 | Share an Umbrella from Rain | Hold an Umbrella | 傘をさしていっしょに雨宿り | 傘を差して雨宿り | 在乾燥的騎樓下和我一起避雨 | shared the dry shophouse arcade with me out of the rain | 濡れない軒下で、いっしょに雨宿りをした |

---

## 8. Satchel Charms (單趟帆布散步袋輕小物)

One-stroll supplies packed into the canvas bag. Zero empty burn if player forgets to close the app.

| ID | zh-Hant Title | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Effect / Lore Note |
|---|---|---|---|---|---|---|
| `satchel.none` | 空手輕鬆散步 | Empty-Handed Stroll | Carefree Stroll | 手ぶらでお散歩 | 身軽なお散歩 | Free; standard step counting and regular street encounters. |
| `satchel.picnic_bread` | 手工野餐麵包袋 | Handmade Picnic Bread Pouch | Baker's Bread Bag | 手作りピクニックパン袋 | ピクニックの手作りパン | Lures a second companion to the corner for dual-pet postcard memories. |
| `satchel.forage_sachet` | 草本拾遺香包 | Herbal Foraging Sachet | Forager's Herb Sachet | ハーブのひろいもの匂い袋 | 草木の香り袋 | Boosts foraging progress by ×1.35 and increases daily curio limit by +1. |
| `satchel.ginger_thermos` | 雨天暖薑茶壺 | Rainy-Day Ginger Thermos | Warm Ginger Flask | 雨の日の温生姜ポット | 雨宿りの生姜茶ポット | Walking 1,500 steps returns +9 Step Coins at home (+2 if under), plus cozy diary note. |

---

## 9. Shop Items (小舖選物)

### 9.1 Wardrobe (衣飾)

| ID | zh-Hant Name | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Slot & Lore Note |
|---|---|---|---|---|---|---|
| `outfit.sage_ribbon` | 鼠尾草綠緞帶 | Sage Green Ribbon | Soft Sage Bow | セージグリーンのリボン | 若草色のリボン | Neck socket; soft cotton ribbon suitable for all cats and dogs. |
| `outfit.terracotta_ribbon` | 赤陶紅緞帶 | Terracotta Red Ribbon | Brick Red Bow | テラコッタのリボン | 赤瓦色のリボン | Neck socket; warm earthen-red bow, standout on rainy days. |
| `outfit.ochre_ribbon` | 琥珀黃緞帶 | Ochre Yellow Ribbon | Amber Cotton Bow | 琥珀色のリボン | 山吹色のリボン | Neck socket; warm lantern-yellow ribbon reminiscent of heritage streets. |
| `outfit.indigo_bandana` | 藍染手織領巾 | Indigo Handwoven Bandana | Indigo Woven Kerchief | 藍染めの手織りバンダナ | 藍染め三角スカーフ | Neck socket; natural plant-indigo twill neckerchief with draped fold. |
| `outfit.moss_bandana` | 苔蘚綠手織領巾 | Moss Green Handwoven Bandana | Deep Moss Kerchief | 苔緑の手織りバンダナ | 苔色の手織りスカーフ | Neck socket; forest-green handwoven bandana smelling of rainy woods. |
| `outfit.persimmon_bandana` | 柿染手織領巾 | Persimmon Handwoven Bandana | Warm Persimmon Kerchief | 柿染めの手織りバンダナ | 柿渋色の手織りスカーフ | Neck socket; autumn persimmon-dyed cloth with ivory edge stitching. |
| `outfit.forager_satchel` | 採集帆布小側包 | Forager's Canvas Satchel | Mini Canvas Bag | 採取の帆布ミニショルダー | 採集のミニ帆布カバン | Back socket; expands daily pocket curio carrying limit from 3 to 4. |
| `outfit.occasion_collar` | 刺繡紀念項圈與小鈴 | Embroidered Commemorative Collar & Bell | Festival Embroidered Collar | 刺繍の記念首輪と小さな鈴 | 記念刺繍の首輪と小鈴 | Neck socket; delicate floral needlework with a warm brass bell. |

### 9.2 Goodies / Furniture (家飾)

| ID | zh-Hant Name | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Capacity & Lore Note |
|---|---|---|---|---|---|---|
| `goodie.folded_towel` | 摺疊亞麻毛巾 | Folded Linen Towel | Sun-Dried Linen Towel | 畳んだリネンタオル | リネン折りたたみタオル | 1 pet; default starter prop; attracts rain-watching companions. |
| `goodie.bakery_box` | 麵包店瓦楞紙箱 | Bakery Cardboard Box | Bakery Box | パン屋の段ボール箱 | ベーカリーの紙箱 | 1 pet; favorite of Juniper and Flitter; shows claw marks after 25 uses. |
| `goodie.cloth_ball` | 手縫拼布球 | Hand-Stitched Patchwork Ball | Patchwork Cloth Ball | 手縫いのパッチワークボール | 継ぎ布ボール | 1 pet; favorite of Button and Reed; shared prop for "Gentle Offering". |
| `goodie.wool_blanket` | 手織藍羊毛毯 | Handwoven Indigo Wool Blanket | Wool Nesting Blanket | 手織りの藍色ウールブランケット | 手織りウール毛布 | 2 pets; lets two companions snuggle together; prop for "Cozy Blanket Nesting". |
| `goodie.window_cushion` | 暖木窗邊長軟墊 | Warm Cedar Window Cushion | Bench Window Cushion | ぬくもり窓辺の長クッション | 窓辺の木製ロング座布団 | 2 pets; expands window ledge capacity from 1 to 2 pets side-by-side. |
| `goodie.hearth_brazier` | 陶土小暖爐 | Clay Hearth Brazier | Terracotta Table Brazier | 素焼きの小火鉢 | 陶器のぬくもり小炉 | 1 pet; soft charcoal ember glow; favorite paw-warming spot for Ember & Button. |
| `goodie.cedar_perch` | 紅檜觀雨木架 | Hinoki Cedar Rain-Watch Perch | Cypress Look-out Tower | 紅檜の雨見やぐら | ヒノキの雨宿り台 | 1 pet; two-tier cypress roost for overlooking the garden in the rain. |
| `goodie.woven_hammock` | 竹編晴日吊床 | Woven Bamboo Sunlit Hammock | Breeze Bamboo Hammock | 竹編みの晴れ日ハンモック | 竹編みのひなたハンモック | 2 pets; gently sways in the afternoon breeze; nap favorite for Plum & Ember. |
| `goodie.moss_planter` | 森林苔蘚小盆景 | Woodland Moss Planter | Terracotta Moss Dish | 森の苔盆栽 | 森林の苔ポット | 1 pet; shallow ceramic bowl of living ferns; glows faintly beside Reed. |
| *(Mechanic)* | 歲月痕跡 / 溫馨歲月痕跡 | Loved Patina | Gentle Wear | 愛着のつや / 愛用の風合い | 暮らしの風合い | Visual transformation appearing on furnishings after 25 uses. |
| *(Mechanic)* | 針線縫補 / 補丁縫補 | Patch & Mend | Stitched Patch Mending | 繕い縫い / パッチ補修 | 針仕事のパッチ | Restores worn furniture while retaining its endearing patched charm. |

### 9.3 Outing Packs (行囊)

| ID | zh-Hant Name | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | One-Line Note |
|---|---|---|---|---|---|---|
| `outing.sketchbook_pack` | 速寫本與炭筆組 | Sketchbook & Charcoal Set | Artist's Field Kit | スケッチブックと木炭セット | スケッチ画材セット | Upgrades next sidewalk encounter into a wide watercolor panoramic spread. |
| `outing.towel_pack` | 步道避雨毛巾組 | Trail Rain Towel Kit | Rain Shelter Towel Pack | 遊歩道の雨宿りタオルセット | 雨の日のお手入れタオル | Unlocks post-rain towel-drying vignette and grants +1 daily curio limit. |

### 9.4 Treats & Kitchen Recipes (茶點與飲品)

| ID | zh-Hant Name | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Flavor & Ritual Note |
|---|---|---|---|---|---|---|
| `treat.favorite_bite` | 一口小點心 | Single Nibble Treat | Favorite Bite | ひとくちおやつ | お気に入りプチおやつ | Discovers and logs a companion's preferred food texture into their diary card. |
| `treat.picnic_portion` | 雙人野餐點心 | Two-Friend Picnic Treat | Shared Picnic Portion | ふたりピクニックのおやつ | ペアピクニックの茶点 | Generates a heartwarming watercolor postcard of two roommates eating together. |
| `treat.ginger_tea` | 雨天暖薑茶盤 | Rainy-Day Ginger Tea Tray | Warm Ginger Tea Set | 雨の日の温生姜茶トレイ | 雨日の生姜茶トレイ | Steaming ceramic teapot prop providing 24 hours of rainy-day warmth. |
| `tea.ginger_honey` | 暖薑蜂蜜熱茶 | Honey Ginger Warm Tea | Ginger Honey Brew | 蜂蜜と生姜の温茶 | ぽかぽか生姜蜂蜜茶 | Spicy old ginger and longan honey; Ember immediately curls up purring. |
| `tea.hearth_biscuit` | 爐火烤蜂蜜脆餅 | Hearth-Baked Honey Crisps | Hearth Honey Biscuits | 炉火の蜂蜜焼きビスケット | 暖炉の蜂蜜クッキー | Golden crunchy cookies baked slowly over Ember's dragon embers. |
| `tea.starlight_lavender` | 星霧薰衣草花茶 | Starlight Lavender Herbal Tea | Twilight Lavender Tisane | 星霧のラベンダーハーブティー | 星空ラベンダー茶 | Night-calming herbal brew infused with soft evening clouds and lavender petals. |
| `tea.forest_matcha` | 森靈宇治抹茶捲 | Sylvan Uji Matcha Roll | Woodland Matcha Cake | 森霊の宇治抹茶ロール | 森の宇治抹茶ロールケーキ | Bittersweet matcha cream roll; makes the tender sprouts on Reed's antlers glow. |
| `tea.dusk_brownsugar` | 暮色黑糖鮮奶歐蕾 | Twilight Brown Sugar Milk Au Lait | Brown Sugar Milk Tea | 黄昏の黒糖ミルクオレ | 茜色の黒糖ミルクティー | Rich caramel roasted sugar; sweet enough that fastidious Juniper licks his lips. |
| `tea.postrain_osmanthus` | 雨後桂花烏龍茶 | Post-Rain Osmanthus Oolong | Osmanthus Oolong Tea | 雨上がりの金木犀烏龍茶 | 雨上がりの桂花烏龍茶 | Sweet osmanthus blossoms over high-mountain oolong, warming like alley breezes. |

---

## 10. Mentorship, Cross-Species Raising & Offspring

### 10.1 Qualitative Friendship Milestones (質性里程碑)

Progression is strictly driven by **Shared Days (相伴日數)**. There are zero numerical XP bars or level caps.

| Tier | Days | zh-Hant Title | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Qualitative Relationship Stage |
|---|---|---|---|---|---|---|---|
| Tier 0 | 0 | 尚未遇見 | Unmet | Not Yet Sighted | まだ出会っていない | 出逢う前 | Walking in the neighborhood, waiting to cross paths. |
| Tier 1 | 1–2 | 初次相遇 | First Encounter | First Met | はじめての出会い | 初対面 | First gentle greeting; timid curiosity and light sniffing. |
| Tier 2 | 3–5 | 熟悉面孔 | Familiar Face | Known Visitor | 見慣れた顔 | 顔なじみ | Remembers the day 1 gesture and steps forward willingly. |
| Tier 3 | 6–9 | 散步同伴 | Walking Companion | Stroll Partner | お散步仲間 | 散策の友 | Pauses naturally at neighborhood corners like an old friend. |
| Tier 4 | 10–14 | 心照不宣 | Kindred Spirit | Mutual Understanding | 気の置けない仲 | 意気投合 | Demonstrates signature habit naturally beside the porch. |
| Tier 5 | 15–24 | 溫柔導師 | Gentle Mentor | Trusted Guide | 優しい導き手 | 頼れる師匠 | Calm and patient enough to guide junior companions. |
| Tier 6 | 25+ | 街角柱石 | Pillar of the Corner | Cornerstone Friend | 街角の大黒柱 | 街角の守り手 | Deeply rooted beloved guardian of the neighborhood. |

### 10.2 Habit Families (習慣家族)

| ID | zh-Hant Title | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Shared Prop & Particle Description |
|---|---|---|---|---|---|---|
| `habit.wait` | 沉靜守候 | Patient Quiet | Serene Watching | 静かな見守り | 穏やかな待機 | Window Cushion; tucks paws quietly, resting with steady breathing. |
| `habit.offer` | 輕遞小物 | Gentle Offering | Nudging Gifts | そっと手渡し | 小さな贈り物 | Patchwork Ball; gently nudging cherished toys to a companion. |
| `habit.nest` | 暖毯築窩 | Cozy Blanket Nesting | Blanket Snuggling | 毛布の巣ごもり | ぬくもり毛布の巣 | Indigo Wool Blanket; amber dust motes glowing with gentle warmth. |
| `habit.shield` | 遮蔭引路 | Shading & Wayfinding | Shaded Pathfinding | 涼蔭の道案内 | 木陰と先導 | Folded Linen Towel; cool comforting shade patterns shielding tired eyes. |

### 10.3 Offspring Growth Stages (靈卵與幼靈成長階段)

Nurtured realistically over ~4–5 real-world days of indoor care and outdoor strolls.

| Stage | zh-Hant Title | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Developmental Meaning |
|---|---|---|---|---|---|---|
| `egg` | 奇幻靈卵 | Mystical Spirit Egg | Spirit Egg | 奇幻の精霊卵 | 精霊の卵 | Warm glowing egg resting gently in the Sunroom nest. |
| `hatchling` | 剛破殼幼靈 | Newly-Hatched Fledgling | Little Hatchling | かえりたての幼霊 | 生まれたての幼霊 | Tiny spirit opening sleepy eyes to soft nursery light. |
| `youth` | 成長中少年靈 | Growing Youthling | Young Spiritling | すくすく育つ少年霊 | 伸び盛りの少年霊 | Playfully exploring the Sunroom furniture and chasing dust motes. |
| `grown` | 獨當一面靈獸 | Fully-Fledged Spirit | Mature Spirit Companion | 独り立ちの霊獣 | 一人前の精霊獣 | Fully awakened signature habit, ready for corner strolls. |

### 10.4 Personality Axes (四大性格維度)

| Axis | zh-Hant Title | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Nurturing Activities Associated |
|---|---|---|---|---|---|---|
| `brave` | 冒險 | Brave | Adventurous | 冒険 | 勇敢 | Rainy-day strolls, outdoor errands, exploring distant corners. |
| `gentle` | 溫柔 | Gentle | Tenderhearted | 温和 | 優しさ | Brewing warm tea, slow brushing, afternoon naps by the brazier. |
| `playful` | 好奇 | Playful | Inquisitive | 好奇 | 遊び心 | Chasing the feather wand, hide-and-seek, rolling patchwork balls. |
| `mystical` | 靈性 | Mystical | Ethereal | 霊性 | 神秘 | Origami folding, listening to folklore, evening starlight reflections. |

### 10.5 Awakened Offspring Archetypes (覺醒性格原型)

| ID | zh-Hant Title | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Primary + Secondary Axis |
|---|---|---|---|---|---|---|
| `arch.rain_explorer` | 追雨小探險家 | Little Rain Explorer | Puddle Scout | 雨追いの小冒険家 | 雨の日の探検隊 | Brave + Playful |
| `arch.hearth_pioneer` | 暖火領航者 | Hearth Pioneer | Ember Scout | 暖火の先導者 | 炉火のパイオニア | Brave + Gentle |
| `arch.starlight_scout` | 星途漫遊者 | Starlight Scout | Astral Wanderer | 星路の旅人 | 星空のスカウト | Brave + Mystical |
| `arch.tea_poet` | 暖茶小詩人 | Warm Tea Poet | Tearoom Dreamer | ぬくもり茶の小詩人 | お茶屋の詩人 | Gentle + Mystical |
| `arch.blanket_angel` | 軟毯守護靈 | Cozy Blanket Guardian | Blanket Angel | ぬくもり毛布の守護霊 | 毛布のガーディアン | Gentle + Brave |
| `arch.sweet_baker` | 蜜餅小點心師 | Honey Biscuit Baker | Sweet Baker | 蜜クッキーのパティシエ | 焼き菓子パティシエ | Gentle + Playful |
| `arch.origami_trickster` | 摺紙小魔術師 | Origami Conjurer | Paper Sprite | 折り紙の小手品師 | 折り紙マジシャン | Playful + Mystical |
| `arch.hide_seek_champ` | 躲貓貓冠軍 | Hide-and-Seek Champion | Peeking Master | かくれんぼの達人 | かくれんぼ名人 | Playful + Brave |
| `arch.fluffy_jester` | 絨球開心果 | Fluffy Ball of Joy | Pompom Jester | ぽんぽんムードメーカー | 陽気なポンポン | Playful + Gentle |
| `arch.mist_sage` | 星霧小智者 | Starmist Sage | Cloud Sage | 星霧の小賢者 | 霧の賢者 | Mystical + Gentle |
| `arch.lantern_keeper` | 提燈守秘靈 | Lantern Secretkeeper | Lantern Guide | ランタンの守秘霊 | 灯籠の番人 | Mystical + Brave |
| `arch.whimsy_sprite` | 幻彩小精靈 | Prismatic Sprite | Whimsical Sprite | プリズムの妖精 | 気まぐれスプライト | Mystical + Playful |

### 10.6 Blended Habits (雙靈合鳴習慣)

| zh-Hant Title | English (Recommended) | Japanese (Recommended) | Parent Pair | Evocative Note |
|---|---|---|---|---|
| 雲火烘茶 | Cloudfire Tea Brewing | 雲火の茶沸かし | Ember + Plum | Dragon embers meet soft astral mist to brew tranquil tea. |
| 暮炎暖翼 | Twilight Hearthwings | 暮炎のぬくもり翼 | Ember + Flitter | Warm dragon embers wrapped inside twilight bat-wings. |
| 暖露蕨光 | Warm Dew Fernlight | 暖露のシダ光 | Ember + Reed | Sprouting antlers glowing warmly amidst morning dew. |
| 夜紙星影 | Nightpaper Starshade | 夜紙の星影 | Juniper + Flitter | Star-shaped folded paper twirling in dusk wing shadows. |
| 星符雲步 | Star-Charm Cloudstride | 星符の雲歩き | Juniper + Plum | Stepping on starlight clouds while leaving neat folded charms. |
| 葉紋契約 | Leaf-Vein Covenant | 葉紋の契約 | Juniper + Reed | Crisp origami folds adorned with delicate forest leaf veins. |
| 幽光夜翼 | Wisp-Lit Nightwings | 幽光の夜翼 | Flitter + Button | Soft twilight bat-wings guided by gentle floating blue flames. |
| 星火引路 | Starlight Spark Wayfinding | 星火の道案内 | Button + Plum | Quiet little wisps leading the way through starlit alleys. |
| 森火守門 | Sylvan Ember Gatekeeping | 森火の門守 | Button + Reed | Sprouting antler tips illuminating the dry entryway mats. |
| 雙靈共鳴 | Dual Spirit Resonance | 二霊の共鳴 | Generic Fallback | Harmonious resonance between two kindred mystical souls. |

### 10.7 Solo Pet Errands & Supplies (小靈獸獨自散步小差事)

| ID | zh-Hant Title | English (Recommended) | Japanese (Recommended) | Duration & Loot Note |
|---|---|---|---|---|
| `errand.bakery_bun` | 溫熱奶油餐包 | Warm Butter Dinner Roll | 焼きたてバターロール | 25 min; free; returns with 2 coins and an alley postcard. |
| `errand.ginger_flask` | 隨身暖薑茶壺 | Portable Warm Ginger Flask | 携帯の温生姜ポット | 40 min; 3 coins; guaranteed 1 pocket curio + 4 coins. |
| `errand.paper_umbrella` | 迷你油紙小傘 | Miniature Oiled-Paper Umbrella | ミニ和紙傘 | 55 min; 5 coins; brings back curio, 5 coins, and lures window visitors. |

### 10.8 Origami Crafts (手作摺紙)

| ID | zh-Hant Title | English (Recommended) | Japanese (Recommended) | Note |
|---|---|---|---|---|
| `origami.star` | 契約摺紙小星 | Contract Origami Star | 契約の折り紙星 | Golden yellow folded paper star; Juniper's favorite craft. |
| `origami.crane` | 晴雨和紙飛鶴 | Sun-or-Rain Washi Crane | 晴雨の和紙ツル | Sky blue folded paper crane hanging gently beside the window. |
| `origami.dragon` | 迷你赤瓦紙龍 | Mini Terracotta Paper Dragon | ミニ赤瓦の紙ドラゴン | Terracotta orange folded dragon with tiny outstretched wings. |

---

## 11. Pocket Curios (口袋拾遺 16 件)

Tactile, poetic treasures found during neighborhood walks. Zero gacha rarity stars.

| ID | zh-Hant Name | English (Recommended) | English (Alternate) | Japanese (Recommended) | Japanese (Alternate) | Associated Place & Weather |
|---|---|---|---|---|---|---|
| `curio.bakery_twine` | 麵包店紅白棉繩 | Bakery Red-and-White Twine | Bakery String | パン屋の紅白たこ糸 | ベーカリーの紅白紐 | 麵包店巷口, 微陰多雲 (Bakery Alley, Overcast) |
| `curio.rain_pebble` | 雨洗河畔鵝卵石 | Rain-Washed Riverside Pebble | River Pebble | 雨洗う河原の小石 | 雨濡れの丸小石 | 溪畔步道, 細雨微涼 (Riverside Path, Light Rain) |
| `curio.ginkgo_leaf` | 金黃銀杏落葉 | Golden Ginkgo Leaf | Autumn Ginkgo Fan | 黄金色のイチョウ落葉 | 金色のイチョウ葉 | 公園木椅, 晴朗晨光 (Park Bench, Clear Morning) |
| `curio.dusk_sea_glass` | 暮色磨砂海玻璃 | Twilight Frosted Sea Glass | Dusk Sea Glass | 黄昏のすりガラス | 茜色のシーグラス | 熟悉街角, 暖黃暮色 (Familiar Corner, Dusk) |
| `curio.cedar_pinecone` | 乾燥檜木小球果 | Dried Hinoki Cypress Cone | Cedar Pinecone | 乾燥ヒノキの小さな球果 | ヒノキの小松ぼっくり | 騎樓廊下, 雨後初晴 (Shophouse Arcade, Post-Rain) |
| `curio.tram_ticket` | 壓平的車站硬票根 | Flattened Train Ticket Stub | Transit Ticket Stub | 押し固めた硬券の切符 | 駅の古い硬券切符 | 公車候車亭, 微陰多雲 (Bus Shelter, Overcast) |
| `curio.umbrella_ribbon` | 雨滴藍傘帶 | Raindrop Blue Umbrella Strap | Umbrella Tie Ribbon | 雨粒ブルーの傘留めテープ | 雨粒ブルーの傘ひも | 老街騎樓, 細雨微涼 (Heritage Arcade, Light Rain) |
| `curio.cypress_sprig` | 清香柏樹嫩枝 | Fragrant Cypress Sprig | Hinoki Cypress Twig | 清らかなヒノキの小枝 | 芳しいヒノキの小枝 | 圖書館小院, 晴朗晨光 (Library Courtyard, Morning) |
| `curio.amber_ember_stone` | 微溫赤陶小碎石 | Warm Terracotta Tile Shard | Ember Hearth Stone | ほの温かい赤瓦の小石片 | 温もり残る赤瓦の破片 | 老街磚牆下, 雨後初晴 (Brick Wall, Post-Rain) |
| `curio.origami_star` | 黑金摺紙小星符 | Black-and-Gold Origami Star Charm | Inky Paper Star | 黒金の折り紙小星札 | 漆黒と金の折り紙星 | 書店騎樓, 暖黃暮色 (Bookstore Arcade, Dusk) |
| `curio.wisp_marble` | 暮紫玻璃彈珠 | Twilight Purple Glass Marble | Wisp Glass Marble | 宵紫のビー玉 | 薄紫のガラス玉 | 轉角雜貨店, 暖黃暮色 (Corner Grocery, Dusk) |
| `curio.cloud_feather` | 星霧白蒲公英絨 | Starmist White Dandelion Fluff | Astral Dandelion Down | 星霧の白タンポポの綿毛 | 星霧のタンポポ綿毛 | 河堤草坡, 微陰多雲 (River Lawn, Overcast) |
| `curio.fern_bookmark` | 雨露捲芽蕨葉 | Dewy Curled Fiddlehead | Rainy Fern Bookmark | 朝露巻くシダの新芽 | 雨露のシダのしおり | 林蔭小徑, 細雨微涼 (Shaded Path, Light Rain) |
| `curio.brass_button` | 舊大衣黃銅圓釦 | Vintage Coat Brass Button | Old Brass Button | 古いコートの真鍮ボタン | 真鍮のアンティーク丸ボタン | 烘豆咖啡館, 晴朗晨光 (Roastery Café, Morning) |
| `curio.bat_pod_seed` | 暮色翅果小種子 | Dusky Winged Seed Pod | Twilight Wing Seed | 黄昏の翼果の小種 | 宵闇の翼果のタネ | 老樹屋簷, 雨後初晴 (Old Tree Eaves, Post-Rain) |
| `curio.porcelain_shard` | 青花茶杯邊小瓷片 | Blue-and-White Porcelain Shard | Teacup Glaze Shard | 染付茶碗の小さな陶片 | 青花茶器のかけら | 茶行石階, 細雨微涼 (Teahouse Steps, Light Rain) |

---

## 12. UI & Accessibility Terms

| zh-Hant (Source) | English (Recommended) | Japanese (Recommended) | Context & One-Line Note |
|---|---|---|---|
| 出發散步 | Start Stroll | お散步に出発 | Primary call-to-action button to initiate walking session. |
| 結束散步 / 返家 | End Stroll / Return Home | お散步終了 / おうちへ帰る | Concludes stroll session and displays summary postcard. |
| 邀請回家 | Invite Home | おうちに迎える | Invites a met companion to reside permanently in the Sunroom. |
| 撫摸毛孩 / 輕撫 | Gentle Stroke / Pet | そっと撫でる | Touch interaction during close-up tactile care. |
| 梳理毛髮 / 輕柔梳毛 | Gentle Brushing | やさしくブラッシング | Grooming tool interaction smoothing watercolor fur. |
| 享用茶點 / 餵食點心 | Offer a Treat | おやつをあげる | Feeding interactive snack matching preferred texture. |
| 拍照紀念 / 留影 | Take Photo | 記念撮影 | Captures a diegetic polaroid or watercolor snapshot. |
| 歲月痕跡展示 | Loved Patina Display | 愛着の風合い展示 | Toggle viewing worn, cherished furnishings. |
| 安全健康提醒 | Health & Pedestrian Notice | 安全と健康のご案内 | Onboarding modal emphasizing traffic safety and step health. |
| 尋找附近街角 | Scanning for Corners… | 近くの街角を探しています… | LocationService acquiring CoreLocation anchor sites. |
