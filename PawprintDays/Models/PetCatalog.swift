import Foundation

struct PetSpec: Identifiable, Hashable, Sendable {
    let id: String // pet.02..pet.08 (6 mystical companions)
    let name: String
    let gender: PetGender
    let kind: PetSpeciesKind
    let rigID: String
    let primaryCoatHex: String
    let accentHex: String
    let earDetailHex: String
    let personalityWord: String
    let signatureHabitTitle: String
    let signatureHabitDetail: String
    let habitFamily: HabitFamily
    let resonantWeathers: [WeatherMode]
    let favoriteGoodieIDs: [String]
    let favoriteTexture: FoodTexture
    let matureKindness: String
    let socketNeckU: Double
    let socketNeckV: Double
    let includedInStage1Slice: Bool
}

struct ShopItemSpec: Identifiable, Hashable, Sendable {
    enum Category: String, Codable, CaseIterable, Sendable {
        case wardrobe = "衣飾"
        case goodies = "家飾"
        case outings = "行囊"
        case treats = "茶點"
        case rooms = "屋景"
    }

    let id: String
    let name: String
    let category: Category
    let priceCoins: Int
    let slotType: String
    let swatchHex: String
    let secondaryHex: String
    let summary: String
    let capacitySlots: Int
}

struct CurioSpec: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let placeCategory: String
    let weatherTag: WeatherMode
    let stampHex: String
    let journalNote: String
}

enum PetCatalog {
    /// 完整 6 位奇幻小靈獸夥伴（繁體中文台灣繪本語氣，純奇幻陣容）
    static let allPets: [PetSpec] = [
        PetSpec(
            id: "pet.02",
            name: "杜松",
            gender: .male,
            kind: .demonCat,
            rigID: "rig_cat_slim",
            primaryCoatHex: "#1E242B",
            accentHex: "#B84A62",
            earDetailHex: "#36404A",
            personalityWord: "傲嬌講究",
            signatureHabitTitle: "契約摺紙",
            signatureHabitDetail: "頭頂彎曲黑曜小角的貓型惡魔，總把摺得方正的小紙符安靜放在朋友身旁。",
            habitFamily: .offer,
            resonantWeathers: [.overcast, .dusk],
            favoriteGoodieIDs: ["goodie.bakery_box", "goodie.folded_towel", "goodie.hearth_brazier", "goodie.cedar_perch"],
            favoriteTexture: .crispy,
            matureKindness: "嘴上說著惡魔才不撒嬌，卻悄悄把緞帶排整齊放在老夥伴墊邊。",
            socketNeckU: 0.43,
            socketNeckV: 0.54,
            includedInStage1Slice: true
        ),
        PetSpec(
            id: "pet.03",
            name: "餘燼",
            gender: .male,
            kind: .dragonCat,
            rigID: "rig_cat_drgn",
            primaryCoatHex: "#6D5B55",
            accentHex: "#C85A32",
            earDetailHex: "#F5E9D6",
            personalityWord: "溫柔小心",
            signatureHabitTitle: "爐爪烘暖",
            signatureHabitDetail: "以為自己是普通街貓的赤炎幼龍，背上陶瓦龍鱗會吐出微溫把毛毯烘得暖烘烘。",
            habitFamily: .nest,
            resonantWeathers: [.postRain, .lightRain],
            favoriteGoodieIDs: ["goodie.wool_blanket", "goodie.folded_towel", "goodie.hearth_brazier", "goodie.woven_hammock"],
            favoriteTexture: .warm,
            matureKindness: "在涼亭用龍息的餘溫替淋濕的室友烘乾一條軟毯。",
            socketNeckU: 0.40,
            socketNeckV: 0.57,
            includedInStage1Slice: true
        ),
        PetSpec(
            id: "pet.04",
            name: "摺翼",
            gender: .female,
            kind: .batCat,
            rigID: "rig_cat_bat",
            primaryCoatHex: "#5B5266",
            accentHex: "#9183A0",
            earDetailHex: "#3F3847",
            personalityWord: "好奇安靜",
            signatureHabitTitle: "夜翼遮蔭",
            signatureHabitDetail: "身披星塵暮色蝠翼的貓型夜魔，張開細摺翅膀替打盹的夥伴擋住刺眼光線。",
            habitFamily: .shield,
            resonantWeathers: [.dusk, .clearMorning],
            favoriteGoodieIDs: ["goodie.bakery_box", "goodie.window_cushion", "goodie.cedar_perch"],
            favoriteTexture: .soft,
            matureKindness: "在刺眼的午後陽光下展開夜色小翼，替熟睡的朋友遮住眼睛。",
            socketNeckU: 0.42,
            socketNeckV: 0.55,
            includedInStage1Slice: true
        ),
        PetSpec(
            id: "pet.06",
            name: "鈕扣",
            gender: .male,
            kind: .impHound,
            rigID: "rig_dog_low",
            primaryCoatHex: "#23272D",
            accentHex: "#8A76C2",
            earDetailHex: "#3D434D",
            personalityWord: "忠厚貼心",
            signatureHabitTitle: "幽火排鞋",
            signatureHabitDetail: "長著一對圓潤小魔角、肩畔飄著藍紫微火的小魔犬，最愛把玄關拖鞋排得整整齊齊。",
            habitFamily: .offer,
            resonantWeathers: [.overcast, .lightRain],
            favoriteGoodieIDs: ["goodie.folded_towel", "goodie.wool_blanket", "goodie.cloth_ball", "goodie.hearth_brazier"],
            favoriteTexture: .warm,
            matureKindness: "雨夜點起微弱的小鬼火替剛進門的室友照亮乾地墊。",
            socketNeckU: 0.36,
            socketNeckV: 0.58,
            includedInStage1Slice: true
        ),
        PetSpec(
            id: "pet.07",
            name: "梅子",
            gender: .female,
            kind: .spiritHound,
            rigID: "rig_dog_senr",
            primaryCoatHex: "#948D86",
            accentHex: "#E2E8F0",
            earDetailHex: "#6F6862",
            personalityWord: "溫和耐心",
            signatureHabitTitle: "雲步伴行",
            signatureHabitDetail: "身周縈繞柔白雲絮與星光的銀月星靈犬，只要同伴停下腳步，牠也會一起放慢呼吸。",
            habitFamily: .wait,
            resonantWeathers: [.dusk, .overcast],
            favoriteGoodieIDs: ["goodie.wool_blanket", "goodie.window_cushion", "goodie.woven_hammock", "goodie.moss_planter"],
            favoriteTexture: .soft,
            matureKindness: "化出輕柔的星霧光暈，並肩陪著害羞的新朋友慢慢走過街口。",
            socketNeckU: 0.39,
            socketNeckV: 0.56,
            includedInStage1Slice: true
        ),
        PetSpec(
            id: "pet.08",
            name: "蘆葦",
            gender: .female,
            kind: .marshHound,
            rigID: "rig_dog_hnd",
            primaryCoatHex: "#A67644",
            accentHex: "#588A62",
            earDetailHex: "#D8BE9B",
            personalityWord: "敏銳細心",
            signatureHabitTitle: "鹿角引路",
            signatureHabitDetail: "頭頂抽著嫩綠新葉小鹿角的森靈犬，總能在積水的巷弄裡一眼找到乾燥的石階。",
            habitFamily: .shield,
            resonantWeathers: [.lightRain, .postRain],
            favoriteGoodieIDs: ["goodie.folded_towel", "goodie.cloth_ball", "goodie.moss_planter"],
            favoriteTexture: .soft,
            matureKindness: "在驟雨落下前搖晃帶著螢火微光的鹿角，領著室友躲進乾爽騎樓。",
            socketNeckU: 0.37,
            socketNeckV: 0.51,
            includedInStage1Slice: true
        )
    ]

    static var stage1Pets: [PetSpec] {
        allPets
    }

    static func pet(id: String) -> PetSpec {
        allPets.first(where: { $0.id == id }) ?? allPets[0]
    }
}

enum ShopCatalog {
    static let patchMendPriceCoins: Int = 10

    static let items: [ShopItemSpec] = [
        // 茶點（日常照護永久免費，這些是特別的紀念體驗）
        ShopItemSpec(
            id: "treat.favorite_bite",
            name: "一口小點心",
            category: .treats,
            priceCoins: 3,
            slotType: "single_snack",
            swatchHex: "#D9A465",
            secondaryHex: "#945B2C",
            summary: "觸發專屬進食反應，並把牠喜歡的口感記進檔案。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "treat.picnic_portion",
            name: "雙人野餐點心",
            category: .treats,
            priceCoins: 8,
            slotType: "shared_meal",
            swatchHex: "#C76D4B",
            secondaryHex: "#F4E5C9",
            summary: "在今日日記留下一張兩位室友共進點心的水彩明信片。",
            capacitySlots: 2
        ),
        ShopItemSpec(
            id: "treat.ginger_tea",
            name: "雨天暖薑茶盤",
            category: .treats,
            priceCoins: 15,
            slotType: "tray_prop",
            swatchHex: "#4A7276",
            secondaryHex: "#E8C38A",
            summary: "冒著熱氣的陶瓷茶壺前景道具，增添 24 小時雨日暖意。",
            capacitySlots: 1
        ),

        // 行囊（單次散步包）
        ShopItemSpec(
            id: "outing.sketchbook_pack",
            name: "速寫本與炭筆組",
            category: .outings,
            priceCoins: 25,
            slotType: "one_walk_pack",
            swatchHex: "#3C4B4E",
            secondaryHex: "#FAF6EE",
            summary: "讓下一次街頭相遇升級成寬幅水彩跨頁明信片。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "outing.towel_pack",
            name: "步道避雨毛巾組",
            category: .outings,
            priceCoins: 30,
            slotType: "one_walk_pack",
            swatchHex: "#7A948A",
            secondaryHex: "#E8DEC8",
            summary: "解鎖雨後溫馨擦毛小劇場，並增加今日口袋拾遺上限 +1。",
            capacitySlots: 1
        ),

        // 衣飾（頸部節點 socket_neck 與背部 socket_back）
        ShopItemSpec(
            id: "outfit.sage_ribbon",
            name: "鼠尾草綠緞帶",
            category: .wardrobe,
            priceCoins: 12,
            slotType: "socket_neck",
            swatchHex: "#5E8B6E",
            secondaryHex: "#3C6149",
            summary: "柔軟棉質緞帶，所有貓咪與狗狗都能輪流佩帶。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "outfit.terracotta_ribbon",
            name: "赤陶紅緞帶",
            category: .wardrobe,
            priceCoins: 12,
            slotType: "socket_neck",
            swatchHex: "#C85A32",
            secondaryHex: "#8C381A",
            summary: "溫潤磚紅色的棉布結，雨天裡格外醒目溫柔。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "outfit.ochre_ribbon",
            name: "琥珀黃緞帶",
            category: .wardrobe,
            priceCoins: 12,
            slotType: "socket_neck",
            swatchHex: "#C9963A",
            secondaryHex: "#8A621C",
            summary: "像老街燈籠般溫暖的黃赭色棉質緞帶。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "outfit.indigo_bandana",
            name: "藍染手織領巾",
            category: .wardrobe,
            priceCoins: 60,
            slotType: "socket_neck",
            swatchHex: "#2E4C6D",
            secondaryHex: "#DCE5EE",
            summary: "天然藍染斜紋領巾，穿戴時可即時預覽合身垂墜感。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "outfit.moss_bandana",
            name: "苔蘚綠手織領巾",
            category: .wardrobe,
            priceCoins: 60,
            slotType: "socket_neck",
            swatchHex: "#476953",
            secondaryHex: "#E4ECE5",
            summary: "帶著雨後林間氣息的深綠手織棉領巾。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "outfit.persimmon_bandana",
            name: "柿染手織領巾",
            category: .wardrobe,
            priceCoins: 60,
            slotType: "socket_neck",
            swatchHex: "#BD5B38",
            secondaryHex: "#F7E6D4",
            summary: "暖秋柿子色手織領巾，點綴細緻米白針腳。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "outfit.forager_satchel",
            name: "採集帆布小側包",
            category: .wardrobe,
            priceCoins: 140,
            slotType: "socket_back",
            swatchHex: "#9C7E54",
            secondaryHex: "#5B462B",
            summary: "迷你散步帆布包，讓每日口袋拾遺攜帶上限由 3 增至 4。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "outfit.occasion_collar",
            name: "刺繡紀念項圈與小鈴",
            category: .wardrobe,
            priceCoins: 240,
            slotType: "socket_neck",
            swatchHex: "#8C3B34",
            secondaryHex: "#E4BE6A",
            summary: "典藏手工刺繡花紋，垂掛一顆溫潤黃銅小鈴鐺。",
            capacitySlots: 1
        ),

        // 家飾（陽光室互動點 — 使用 25 次出現溫馨歲月痕跡）
        ShopItemSpec(
            id: "goodie.folded_towel",
            name: "摺疊亞麻毛巾",
            category: .goodies,
            priceCoins: 0,
            slotType: "window_or_alcove",
            swatchHex: "#E3DAC8",
            secondaryHex: "#8B9E96",
            summary: "曬過太陽的棉麻毛巾，吸引愛看雨的安靜室友。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "goodie.bakery_box",
            name: "麵包店瓦楞紙箱",
            category: .goodies,
            priceCoins: 45,
            slotType: "one_slot",
            swatchHex: "#C99F6D",
            secondaryHex: "#8B6339",
            summary: "吸引好奇的貓咪（杜松、摺翼）；使用 25 次會留下可愛爪痕。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "goodie.cloth_ball",
            name: "手縫拼布球",
            category: .goodies,
            priceCoins: 55,
            slotType: "one_slot",
            swatchHex: "#C85A32",
            secondaryHex: "#F0DEC4",
            summary: "吸引愛玩的奇幻夥伴（鈕扣、蘆葦）；也是「輕遞小物」跨物種傳承道具。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "goodie.wool_blanket",
            name: "手織藍羊毛毯",
            category: .goodies,
            priceCoins: 110,
            slotType: "two_slot",
            swatchHex: "#506D84",
            secondaryHex: "#D6C5A9",
            summary: "可讓兩位室友依偎取暖；也是「暖毯築窩」傳承共享道具。",
            capacitySlots: 2
        ),
        ShopItemSpec(
            id: "goodie.window_cushion",
            name: "暖木窗邊長軟墊",
            category: .goodies,
            priceCoins: 180,
            slotType: "window_spot",
            swatchHex: "#B57B48",
            secondaryHex: "#F2E6D2",
            summary: "將窗台容量由 1 位擴展至 2 位，並肩看雨更愜意。",
            capacitySlots: 2
        ),
        ShopItemSpec(
            id: "goodie.hearth_brazier",
            name: "陶土小暖爐",
            category: .goodies,
            priceCoins: 135,
            slotType: "one_slot",
            swatchHex: "#B55233",
            secondaryHex: "#F4C98B",
            summary: "散發微紅炭火暖光的素燒暖爐，餘燼、杜松與鈕扣最愛在旁烘爪。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "goodie.cedar_perch",
            name: "紅檜觀雨木架",
            category: .goodies,
            priceCoins: 150,
            slotType: "window_or_alcove",
            swatchHex: "#8C603B",
            secondaryHex: "#DCC5A1",
            summary: "雙層紅檜棲木架，摺翼與杜松喜歡登高俯瞰整個陽光室與雨景。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "goodie.woven_hammock",
            name: "竹編晴日吊床",
            category: .goodies,
            priceCoins: 165,
            slotType: "two_slot",
            swatchHex: "#C7A672",
            secondaryHex: "#F5EAD4",
            summary: "隨微風輕輕搖曳的竹編吊床，讓梅子與餘燼舒舒服服打個長盹。",
            capacitySlots: 2
        ),
        ShopItemSpec(
            id: "goodie.moss_planter",
            name: "森林苔蘚小盆景",
            category: .goodies,
            priceCoins: 125,
            slotType: "one_slot",
            swatchHex: "#557C5B",
            secondaryHex: "#D2BFA2",
            summary: "盛著林間綠苔與蕨芽的淺陶盆，蘆葦靠近時嫩葉會飄起微光。",
            capacitySlots: 1
        ),

        // 屋景（四季光影主題與雨廊擴建）
        ShopItemSpec(
            id: "room.rainy_season",
            name: "梅雨季微霧光影",
            category: .rooms,
            priceCoins: 400,
            slotType: "interior_theme",
            swatchHex: "#8FA7AD",
            secondaryHex: "#E4E8E6",
            summary: "柔和清涼的雨霧窗光，最適合泡壺薑茶聽雨聲。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "room.autumn_cedar",
            name: "秋日紅檜餘暉",
            category: .rooms,
            priceCoins: 420,
            slotType: "interior_theme",
            swatchHex: "#C28B5B",
            secondaryHex: "#EAD9C2",
            summary: "斜照進木造地板的溫暖紅檜夕陽色調。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "room.winter_lamp",
            name: "冬夜暖燈茶室",
            category: .rooms,
            priceCoins: 450,
            slotType: "interior_theme",
            swatchHex: "#B57845",
            secondaryHex: "#F2D7AA",
            summary: "替微寒的夜晚點起一盞琥珀桌燈暖光。",
            capacitySlots: 1
        ),
        ShopItemSpec(
            id: "room.rain_veranda",
            name: "雨廊木檐擴建",
            category: .rooms,
            priceCoins: 650,
            slotType: "room_expansion",
            swatchHex: "#58786E",
            secondaryHex: "#D8C6A8",
            summary: "替家園增建遮雨木檐，互動位置由 5 處擴展至 8 處。",
            capacitySlots: 3
        )
    ]

    static func item(id: String) -> ShopItemSpec? {
        items.first(where: { $0.id == id })
    }
}

enum CurioCatalog {
    /// 僅依「地點與天氣」分類的質性拾遺小物 — 絕無手遊稀有度分級！
    static let all: [CurioSpec] = [
        CurioSpec(
            id: "curio.bakery_twine",
            name: "麵包店紅白棉繩",
            placeCategory: "麵包店巷口",
            weatherTag: .overcast,
            stampHex: "#A86C4A",
            journalNote: "細細打好蝴蝶結的紅白棉繩，還留著一點剛出爐的麵粉香。"
        ),
        CurioSpec(
            id: "curio.rain_pebble",
            name: "雨洗河畔鵝卵石",
            placeCategory: "溪畔步道",
            weatherTag: .lightRain,
            stampHex: "#55717A",
            journalNote: "被細雨沖得溫潤發亮的灰青小石子，握在手心涼涼的。"
        ),
        CurioSpec(
            id: "curio.ginkgo_leaf",
            name: "金黃銀杏落葉",
            placeCategory: "公園木椅",
            weatherTag: .clearMorning,
            stampHex: "#C99A3B",
            journalNote: "完整的小扇葉，剛好夾進速寫本內頁做成壓花。"
        ),
        CurioSpec(
            id: "curio.dusk_sea_glass",
            name: "暮色磨砂海玻璃",
            placeCategory: "熟悉街角",
            weatherTag: .dusk,
            stampHex: "#4D827E",
            journalNote: "在黃昏路燈下泛著柔和青綠光的霧面玻璃小圓片。"
        ),
        CurioSpec(
            id: "curio.cedar_pinecone",
            name: "乾燥檜木小球果",
            placeCategory: "騎樓廊下",
            weatherTag: .postRain,
            stampHex: "#7A583B",
            journalNote: "散發淡淡木頭與雨後暖陽的清香。"
        ),
        CurioSpec(
            id: "curio.tram_ticket",
            name: "壓平的車站硬票根",
            placeCategory: "公車候車亭",
            weatherTag: .overcast,
            stampHex: "#6D7C86",
            journalNote: "在乾爽的木椅縫旁撿到的舊票根，適合當書籤。"
        ),
        CurioSpec(
            id: "curio.umbrella_ribbon",
            name: "雨滴藍傘帶",
            placeCategory: "老街騎樓",
            weatherTag: .lightRain,
            stampHex: "#496C73",
            journalNote: "陣雨來臨前，蘆葦在乾石板上發現的小布帶。"
        ),
        CurioSpec(
            id: "curio.cypress_sprig",
            name: "清香柏樹嫩枝",
            placeCategory: "圖書館小院",
            weatherTag: .clearMorning,
            stampHex: "#4E7858",
            journalNote: "在日記頁緣留下清淡微甜的木質葉香。"
        ),
        CurioSpec(
            id: "curio.amber_ember_stone",
            name: "微溫赤陶小碎石",
            placeCategory: "老街磚牆下",
            weatherTag: .postRain,
            stampHex: "#C4633B",
            journalNote: "餘燼路過時尾巴掃到的小碎瓦，握在掌心竟帶著淡淡暖意。"
        ),
        CurioSpec(
            id: "curio.origami_star",
            name: "黑金摺紙小星符",
            placeCategory: "書店騎樓",
            weatherTag: .dusk,
            stampHex: "#3C4652",
            journalNote: "摺痕筆直方正的小紙星，一看就知道出自講究的杜松之手。"
        ),
        CurioSpec(
            id: "curio.wisp_marble",
            name: "暮紫玻璃彈珠",
            placeCategory: "轉角雜貨店",
            weatherTag: .dusk,
            stampHex: "#7A68B0",
            journalNote: "在昏黃街燈下閃著柔和藍紫微光，像鈕扣肩上的小小鬼火。"
        ),
        CurioSpec(
            id: "curio.cloud_feather",
            name: "星霧白蒲公英絨",
            placeCategory: "河堤草坡",
            weatherTag: .overcast,
            stampHex: "#9EAAB5",
            journalNote: "輕得幾乎沒有重量，夾進日記時還散發著梅子身邊的微甜雲氣。"
        ),
        CurioSpec(
            id: "curio.fern_bookmark",
            name: "雨露捲芽蕨葉",
            placeCategory: "林蔭小徑",
            weatherTag: .lightRain,
            stampHex: "#4D805D",
            journalNote: "蘆葦輕輕點頭示意的嫩蕨芽，壓乾後剛好當成月曆書籤。"
        ),
        CurioSpec(
            id: "curio.brass_button",
            name: "舊大衣黃銅圓釦",
            placeCategory: "烘豆咖啡館",
            weatherTag: .clearMorning,
            stampHex: "#B88C3E",
            journalNote: "被晨光曬得暖融融的舊銅釦，鈕扣用鼻尖把它推到了鞋尖旁。"
        ),
        CurioSpec(
            id: "curio.bat_pod_seed",
            name: "暮色翅果小種子",
            placeCategory: "老樹屋簷",
            weatherTag: .postRain,
            stampHex: "#6D5E7E",
            journalNote: "形狀宛如摺翼的細摺小翅膀，在微風裡會旋轉著緩緩落下。"
        ),
        CurioSpec(
            id: "curio.porcelain_shard",
            name: "青花茶杯邊小瓷片",
            placeCategory: "茶行石階",
            weatherTag: .lightRain,
            stampHex: "#4A7276",
            journalNote: "邊緣已被歲月磨得圓潤光滑，映著雨後天青色的釉面光澤。"
        )
    ]

    static func pickFor(weather: WeatherMode, placeLabel: String, seed: Int) -> CurioSpec {
        let matchingWeather = all.filter { $0.weatherTag == weather }
        if !matchingWeather.isEmpty {
            return matchingWeather[abs(seed) % matchingWeather.count]
        }
        return all[abs(seed) % all.count]
    }

    static func curio(id: String) -> CurioSpec {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}
