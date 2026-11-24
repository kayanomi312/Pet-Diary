import Foundation

// MARK: - 1. Gender & Mystical Hybrid Offspring System

enum PetGender: String, Codable, CaseIterable, Sendable {
    case male = "male"
    case female = "female"

    var symbol: String {
        self == .male ? "♂" : "♀"
    }

    var label: String {
        self == .male ? "男孩子" : "女孩子"
    }

    var badgeHex: String {
        self == .male ? "#4B768A" : "#C46B7E"
    }
}

enum OffspringGrowthStage: String, Codable, CaseIterable, Sendable {
    case egg = "egg"
    case hatchling = "hatchling"
    case youth = "youth"
    case grown = "grown"

    var title: String {
        switch self {
        case .egg: return "奇幻靈卵"
        case .hatchling: return "剛破殼幼靈"
        case .youth: return "成長中少年靈"
        case .grown: return "獨當一面靈獸"
        }
    }

    var sunroomScaleMultiplier: Double {
        switch self {
        case .egg: return 0.50
        case .hatchling: return 0.62
        case .youth: return 0.80
        case .grown: return 0.96
        }
    }
}

enum PersonalityAxis: String, Codable, CaseIterable, Sendable {
    case brave = "brave"       // 冒險（散步、雨天、出門探險）
    case gentle = "gentle"     // 溫柔（泡茶、梳毛、午睡）
    case playful = "playful"   // 好奇（逗貓棒、躲貓貓、摺紙、丟球）
    case mystical = "mystical" // 靈性（奇譚故事、黃昏螢火、跨物種傳承）

    var title: String {
        switch self {
        case .brave: return "冒險"
        case .gentle: return "溫柔"
        case .playful: return "好奇"
        case .mystical: return "靈性"
        }
    }

    var colorHex: String {
        switch self {
        case .brave: return "#D46B48"
        case .gentle: return "#5A8E76"
        case .playful: return "#D99B38"
        case .mystical: return "#6E5FA8"
        }
    }
}

struct OffspringPersonalityArchetype: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let primaryAxis: PersonalityAxis
    let secondaryAxis: PersonalityAxis
    let summary: String
    let sunroomQuirk: String
}

/// Persisted Mystical Child / Egg raised across ~4-5 realistic days of indoor care & outdoor walks!
struct MysticalOffspringRecord: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var gender: PetGender
    let fatherPetID: String
    let motherPetID: String
    /// Body animation cel rig inherited from one parent
    let inheritedBodyPetID: String
    /// Subtle watercolor coat tint + secondary magical aura inherited from the other parent
    let inheritedTintPetID: String
    let createdAtUTC: Date
    let bornDateISO: String

    var growthStage: OffspringGrowthStage
    /// Distinct local civil dates nurtured (drives slow realistic 4-5 day growth pace!)
    var careDaysLogged: [String]
    var careActivityCount: Int
    var walkStepsShared: Int

    // 4 soft personality axes shaped by every activity
    var bravePoints: Int
    var gentlePoints: Int
    var playfulPoints: Int
    var mysticalPoints: Int

    var awakenedArchetypeID: String?
    var blendedHabitTitle: String
    var isLivingInSunroom: Bool
    var graduatedAnchorSiteID: String?
    var graduatedAnchorLabel: String?

    var dominantAxis: PersonalityAxis {
        let pairs: [(PersonalityAxis, Int)] = [
            (.brave, bravePoints),
            (.gentle, gentlePoints),
            (.playful, playfulPoints),
            (.mystical, mysticalPoints)
        ]
        return pairs.max(by: { $0.1 < $1.1 })?.0 ?? .gentle
    }

    var secondaryAxis: PersonalityAxis {
        let pairs: [(PersonalityAxis, Int)] = [
            (.brave, bravePoints),
            (.gentle, gentlePoints),
            (.playful, playfulPoints),
            (.mystical, mysticalPoints)
        ].sorted { $0.1 > $1.1 }
        return pairs.count > 1 ? pairs[1].0 : .mystical
    }

    /// Progress requirements for slow realistic ~4-5 day pace:
    /// - Egg -> Hatchling: >= 1 care day AND (>= 2 activities OR >= 800 walked steps)
    /// - Hatchling -> Youth: >= 2 care days AND >= 6 activities
    /// - Youth -> Grown: >= 4 care days AND >= 12 activities
    mutating func evaluateGrowthProgression() -> Bool {
        let old = growthStage
        switch growthStage {
        case .egg:
            if careDaysLogged.count >= 1 && (careActivityCount >= 2 || walkStepsShared >= 800) {
                growthStage = .hatchling
            }
        case .hatchling:
            if careDaysLogged.count >= 2 && careActivityCount >= 6 {
                growthStage = .youth
            }
        case .youth:
            if careDaysLogged.count >= 4 && careActivityCount >= 12 {
                growthStage = .grown
                if awakenedArchetypeID == nil {
                    awakenedArchetypeID = OffspringCatalog.resolveArchetype(
                        primary: dominantAxis,
                        secondary: secondaryAxis
                    ).id
                }
            }
        case .grown:
            break
        }
        return growthStage != old
    }

    var nextMilestoneHint: String {
        switch growthStage {
        case .egg:
            let acts = max(0, 2 - careActivityCount)
            return acts > 0 ? "再照護暖巢 \(acts) 次（或散步 800 步）即將破殼！" : "靈卵微微發亮，準備迎接新生命…"
        case .hatchling:
            let d = max(0, 2 - careDaysLogged.count)
            let a = max(0, 6 - careActivityCount)
            return "成長至少年靈：還需相伴 \(d) 天 · 互動 \(a) 次"
        case .youth:
            let d = max(0, 4 - careDaysLogged.count)
            let a = max(0, 12 - careActivityCount)
            return "長大覺醒性格：還需相伴 \(d) 天 · 互動 \(a) 次"
        case .grown:
            let arch = awakenedArchetypeID.flatMap(OffspringCatalog.archetype(id:))?.title ?? "奇幻靈獸"
            return "已長大覺醒：「\(arch)」"
        }
    }
}

enum OffspringCatalog {
    static let archetypes: [OffspringPersonalityArchetype] = [
        .init(id: "arch.rain_explorer", title: "追雨小探險家", primaryAxis: .brave, secondaryAxis: .playful, summary: "一聽見雨聲就興奮地跑到玄關張望，喜歡在積水石階上踩出小小水花。", sunroomQuirk: "總愛守在陽光室門口等著出發小探險"),
        .init(id: "arch.hearth_pioneer", title: "暖火領航者", primaryAxis: .brave, secondaryAxis: .gentle, summary: "勇敢又體貼，走在前頭替害羞的夥伴探路，也不忘回頭確認大家的步調。", sunroomQuirk: "喜歡替睡著的室友守夜"),
        .init(id: "arch.starlight_scout", title: "星途漫遊者", primaryAxis: .brave, secondaryAxis: .mystical, summary: "對黃昏與星霧巷口充滿憧憬，總能帶回不可思議的街角奇遇。", sunroomQuirk: "傍晚時分常望著窗外閃閃發亮"),

        .init(id: "arch.tea_poet", title: "暖茶小詩人", primaryAxis: .gentle, secondaryAxis: .mystical, summary: "最愛窩在熱呼呼的茶壺旁聽雨聲，眼神總帶著繪本般的寧靜微光。", sunroomQuirk: "特別喜歡在茶盤邊安靜打盹"),
        .init(id: "arch.blanket_angel", title: "軟毯守護靈", primaryAxis: .gentle, secondaryAxis: .brave, summary: "把每位室友都照顧得舒舒服服，是陽光室裡最令人安心的小太陽。", sunroomQuirk: "會主動走到中央毛毯依偎夥伴"),
        .init(id: "arch.sweet_baker", title: "蜜餅小點心師", primaryAxis: .gentle, secondaryAxis: .playful, summary: "只要聞到烤餅乾與蜂蜜茶香就會開心踏步，常把美味分給大家。", sunroomQuirk: "聞到茶點香氣立刻小跑過來"),

        .init(id: "arch.origami_trickster", title: "摺紙小魔術師", primaryAxis: .playful, secondaryAxis: .mystical, summary: "對會飄動的紙鶴與小星星愛不釋手，總愛把陽光室變成遊樂場。", sunroomQuirk: "特別愛撲向窗邊搖曳的紙飾與逗貓棒"),
        .init(id: "arch.hide_seek_champ", title: "躲貓貓冠軍", primaryAxis: .playful, secondaryAxis: .brave, summary: "最擅長藏在紙箱與盆景後面露出一截晃動的小尾巴，等你來發現。", sunroomQuirk: "超愛在陽光室家具後面玩躲貓貓"),
        .init(id: "arch.fluffy_jester", title: "絨球開心果", primaryAxis: .playful, secondaryAxis: .gentle, summary: "看見誰有點累就會滾來一顆縫布球，用圓滾滾的眼神逗大家開心。", sunroomQuirk: "看到布球滾動一定第一個追上去"),

        .init(id: "arch.mist_sage", title: "星霧小智者", primaryAxis: .mystical, secondaryAxis: .gentle, summary: "天生帶著古老繪本的靈氣，靜靜傾聽每段街角故事與風的低語。", sunroomQuirk: "身邊常飄起雙重奇幻微光"),
        .init(id: "arch.lantern_keeper", title: "提燈守秘靈", primaryAxis: .mystical, secondaryAxis: .brave, summary: "能感知街區隱藏的靈獸氣息，常在暮色裡引領夥伴遇見新驚喜。", sunroomQuirk: "黃昏時會在窗邊輕晃微光"),
        .init(id: "arch.whimsy_sprite", title: "幻彩小精靈", primaryAxis: .mystical, secondaryAxis: .playful, summary: "集好奇與奇幻於一身，連打個哈欠都會冒出幾顆調皮的小光點。", sunroomQuirk: "喜歡對著飄浮光塵輕輕伸爪")
    ]

    static func resolveArchetype(primary: PersonalityAxis, secondary: PersonalityAxis) -> OffspringPersonalityArchetype {
        if let exact = archetypes.first(where: { $0.primaryAxis == primary && $0.secondaryAxis == secondary }) {
            return exact
        }
        return archetypes.first(where: { $0.primaryAxis == primary }) ?? archetypes[0]
    }

    static func archetype(id: String) -> OffspringPersonalityArchetype? {
        archetypes.first(where: { $0.id == id })
    }

    static func blendedHabit(fatherID: String, motherID: String) -> String {
        let pair = [fatherID, motherID].sorted().joined(separator: "+")
        switch pair {
        case "pet.03+pet.07": return "雲火烘茶"
        case "pet.03+pet.04": return "暮炎暖翼"
        case "pet.03+pet.08": return "暖露蕨光"
        case "pet.02+pet.04": return "夜紙星影"
        case "pet.02+pet.07": return "星符雲步"
        case "pet.02+pet.08": return "葉紋契約"
        case "pet.04+pet.06": return "幽光夜翼"
        case "pet.06+pet.07": return "星火引路"
        case "pet.06+pet.08": return "森火守門"
        default: return "雙靈共鳴"
        }
    }

    static func defaultBabyName(fatherID: String, motherID: String, index: Int) -> String {
        let pool = ["小暖星", "小露芽", "小雲焰", "小夜羽", "小紙星", "小琥珀", "小霜翼", "小苔火"]
        let seed = StableHash.value("\(fatherID)+\(motherID)#\(index)")
        return pool[seed % pool.count]
    }
}

// MARK: - 2. Daily Cozy Wishes (Zero-FOMO Indoor + Outdoor Gentle Prompts)

enum DailyWishKind: String, Codable, CaseIterable, Sendable {
    case featherChase = "wish.feather_chase"
    case brewTea = "wish.brew_tea"
    case foldOrigami = "wish.fold_origami"
    case hideAndSeek = "wish.hide_seek"
    case writeDiary = "wish.write_diary"
    case sendErrand = "wish.send_errand"
    case nurtureOffspring = "wish.nurture_offspring"
    case streetGreeting = "wish.street_greeting"

    var title: String {
        switch self {
        case .featherChase: return "在陽光室陪室友玩一次逗貓棒"
        case .brewTea: return "在茶點台手沖一杯熱茶或烤蜜餅"
        case .foldOrigami: return "和杜松一起摺一件手作摺紙"
        case .hideAndSeek: return "在陽光室找到躲貓貓的小靈獸"
        case .writeDiary: return "翻開足印日記回顧今日足跡"
        case .sendErrand: return "派一位靈獸出門散步小探險"
        case .nurtureOffspring: return "照護奇幻靈卵或幼靈一次"
        case .streetGreeting: return "外出或在窗邊向奇幻靈獸打招呼"
        }
    }

    var systemImage: String {
        switch self {
        case .featherChase: return "wand.and.stars"
        case .brewTea: return "cup.and.saucer.fill"
        case .foldOrigami: return "paperplane.fill"
        case .hideAndSeek: return "eyes"
        case .writeDiary: return "book.pages.fill"
        case .sendErrand: return "backpack.fill"
        case .nurtureOffspring: return "sparkles"
        case .streetGreeting: return "pawprint.fill"
        }
    }

    var rewardCoins: Int { 2 }
}

struct DailyWishItem: Codable, Identifiable, Hashable, Sendable {
    var id: String { kind.rawValue }
    let kind: DailyWishKind
    var isCompleted: Bool
    var isClaimed: Bool
}

struct DailyWishesBoard: Codable, Sendable {
    let localDateISO: String
    var wishes: [DailyWishItem]

    static func generate(for dateISO: String, hasOffspring: Bool) -> DailyWishesBoard {
        let indoorPool: [DailyWishKind] = [.featherChase, .brewTea, .foldOrigami, .hideAndSeek, .sendErrand]
        let seed = StableHash.value(dateISO)
        let first = indoorPool[seed % indoorPool.count]
        let second = indoorPool[(seed + 2) % indoorPool.count]
        let third: DailyWishKind = hasOffspring ? .nurtureOffspring : .writeDiary
        return DailyWishesBoard(
            localDateISO: dateISO,
            wishes: [
                DailyWishItem(kind: first, isCompleted: false, isClaimed: false),
                DailyWishItem(kind: second, isCompleted: false, isClaimed: false),
                DailyWishItem(kind: third, isCompleted: false, isClaimed: false)
            ]
        )
    }
}

// MARK: - 3. Solo Pet Errands (Tabikaeru-Style Indoor Progression)

enum ErrandSupplyPack: String, Codable, CaseIterable, Identifiable, Sendable {
    case bakeryBun = "errand.bakery_bun"
    case gingerFlask = "errand.ginger_flask"
    case paperUmbrella = "errand.paper_umbrella"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bakeryBun: return "溫熱奶油餐包"
        case .gingerFlask: return "隨身暖薑茶壺"
        case .paperUmbrella: return "迷你油紙小傘"
        }
    }

    var durationMinutes: Int {
        switch self {
        case .bakeryBun: return 25
        case .gingerFlask: return 40
        case .paperUmbrella: return 55
        }
    }

    var costCoins: Int {
        switch self {
        case .bakeryBun: return 0
        case .gingerFlask: return 3
        case .paperUmbrella: return 5
        }
    }

    var summary: String {
        switch self {
        case .bakeryBun: return "免費備妥 · 25 分鐘小散步，帶回 2 幣與巷口明信片。"
        case .gingerFlask: return "40 分鐘深巷探險，必帶回 1 件街區拾遺與 4 幣！"
        case .paperUmbrella: return "55 分鐘雨林巡禮，帶回拾遺、5 幣並吸引窗外訪客！"
        }
    }
}

struct ActivePetErrand: Codable, Identifiable, Sendable {
    let id: UUID
    let petID: String
    let supply: ErrandSupplyPack
    let startedAtUTC: Date
    let returnAtUTC: Date
    let destinationLabel: String

    func remainingSeconds(at now: Date = Date()) -> TimeInterval {
        max(0, returnAtUTC.timeIntervalSince(now))
    }

    func isReadyToReturn(at now: Date = Date()) -> Bool {
        now >= returnAtUTC
    }
}

struct CompletedErrandPostcard: Codable, Identifiable, Sendable {
    let id: UUID
    let petID: String
    let destinationLabel: String
    let storyLine: String
    let coinsEarned: Int
    let foundCurioID: String?
    let localDateISO: String
}

// MARK: - 4. Sunroom Tea & Biscuit Recipes + Origami Crafts + Wall Decor

struct TeaRecipeSpec: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let icon: String
    let tintHex: String
    let favoritePetIDs: [String]
    let aromaNote: String
    let brewPrompt: String
}

enum TeaKitchenCatalog {
    static let allRecipes: [TeaRecipeSpec] = [
        .init(id: "tea.ginger_honey", name: "暖薑蜂蜜熱茶", icon: "cup.and.saucer.fill", tintHex: "#C98A3A", favoritePetIDs: ["pet.03", "pet.06"], aromaNote: "微微辛甜的老薑與龍眼蜜香，餘燼聞到立刻靠過來呼嚕。", brewPrompt: "沿著茶杯緩緩畫圈注入熱水…"),
        .init(id: "tea.hearth_biscuit", name: "爐火烤蜂蜜脆餅", icon: "birthday.cake.fill", tintHex: "#C86A42", favoritePetIDs: ["pet.02", "pet.03"], aromaNote: "用餘燼的微溫爐氣慢烘出的金黃酥脆小餅乾。", brewPrompt: "輕輕畫圈翻烤，讓餅面染上琥珀色…"),
        .init(id: "tea.starlight_lavender", name: "星霧薰衣草花茶", icon: "sparkles", tintHex: "#7A6BB0", favoritePetIDs: ["pet.04", "pet.07"], aromaNote: "帶著柔和夜色與雲霧清香的晚安花茶。", brewPrompt: "輕柔攪拌讓星霧花瓣慢慢舒展…"),
        .init(id: "tea.forest_matcha", name: "森靈宇治抹茶捲", icon: "leaf.fill", tintHex: "#4E825E", favoritePetIDs: ["pet.08", "pet.07"], aromaNote: "清甜微苦的茶香蛋糕捲，蘆葦頭頂的嫩葉跟著閃閃發亮。", brewPrompt: "均勻刷上抹茶糖漿與淡淡奶香…"),
        .init(id: "tea.dusk_brownsugar", name: "暮色黑糖鮮奶歐蕾", icon: "moon.stars.fill", tintHex: "#6E5244", favoritePetIDs: ["pet.02", "pet.04"], aromaNote: "焦香濃厚的手炒黑糖，連傲嬌的杜松都忍不住多舔兩口。", brewPrompt: "緩緩旋轉杯身讓黑糖畫出雲紋…"),
        .init(id: "tea.postrain_osmanthus", name: "雨後桂花烏龍茶", icon: "cloud.sun.fill", tintHex: "#4A7A76", favoritePetIDs: ["pet.06", "pet.08"], aromaNote: "像雨後巷口吹來的微甜桂花風，清新又暖胃。", brewPrompt: "注水沖開金黃桂花與烏龍茶葉…")
    ]
}

enum OrigamiCraftKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case star = "origami.star"
    case crane = "origami.crane"
    case dragon = "origami.dragon"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .star: return "契約摺紙小星"
        case .crane: return "晴雨和紙飛鶴"
        case .dragon: return "迷你赤瓦紙龍"
        }
    }

    var colorHex: String {
        switch self {
        case .star: return "#D9A441"
        case .crane: return "#5B8E94"
        case .dragon: return "#C85A32"
        }
    }

    var sfSymbol: String {
        switch self {
        case .star: return "star.fill"
        case .crane: return "bird.fill"
        case .dragon: return "flame.fill"
        }
    }
}

struct SunroomIndoorState: Codable, Sendable {
    var dailyWishes: DailyWishesBoard? = nil
    var activeErrand: ActivePetErrand? = nil
    var errandHistory: [CompletedErrandPostcard] = []
    var unlockedTeaRecipeIDs: [String] = []
    var totalTeaBrewedCount: Int = 0
    var hangingOrigamis: [OrigamiCraftKind] = []
    var hasWindChimeInstalled: Bool = true
    var pinnedPostcardEncounterID: UUID? = nil
    /// Tracks window sightings for undiscovered pets so indoor players can gently lure them too!
    var windowVisitCounts: [String: Int] = [:]
    var lastWindowVisitorPetID: String? = nil
    var lastWindowVisitorDateISO: String? = nil
    /// Raised mystical offspring & eggs
    var offsprings: [MysticalOffspringRecord] = []
    /// Seen multi-pet sunroom skit IDs
    var seenSkitIDs: [String] = []

    // MARK: Gameplay balance additions (all optional on decode so older saves keep every field)
    /// Civil day of the last window greeting (one greeting per day → 3 days to welcome a visitor).
    var lastWindowGreetDateISO: String? = nil
    /// Civil day the per-activity indoor coin counters belong to.
    var indoorCoinDateISO: String? = nil
    /// Indoor coin payouts already granted today, keyed by activity.
    var indoorCoinCounts: [String: Int] = [:]
    /// Pets whose favourite greeting gesture has been discovered.
    var discoveredFavoriteGesturePetIDs: [String] = []
    /// Foraged curio entries already given to a companion as a gift.
    var giftedCurioEntryIDs: [UUID] = []
    /// Weather curio sets whose completion reward has been claimed.
    var claimedCurioSetWeatherCodes: [String] = []
    /// Optional "walk with me" step quest offered by a street companion.
    var activeWalkQuest: WalkWithMeQuest? = nil
    var completedWalkQuestCount: Int = 0
    /// Special time-of-day / weather visitor appearances: visitor key → civil day it last appeared.
    var specialVisitorDates: [String: String] = [:]
    /// One-time doorstep corner created at the player's real first location.
    var hasPlacedDoorstepCorner: Bool = false

    // MARK: Zero-FOMO cozy stamp card & milestone celebrations (optional on decode)
    /// Stamps on the current 7-slot card (0...6); the 7th stamp completes the card and resets this.
    var stampCountInCard: Int = 0
    /// Lifetime number of completed 7-stamp cards.
    var completedStampCardsCount: Int = 0
    /// Civil day of the last stamp (at most one stamp per day; missed days never reset progress).
    var lastStampAwardedDateISO: String? = nil
    /// Keys of one-time milestone celebrations already shown (e.g. "welcome.pet.07").
    var unlockedCelebratedFeatures: [String] = []

    init() {}

    private enum CodingKeys: String, CodingKey {
        case dailyWishes, activeErrand, errandHistory, unlockedTeaRecipeIDs, totalTeaBrewedCount
        case hangingOrigamis, hasWindChimeInstalled, pinnedPostcardEncounterID, windowVisitCounts
        case lastWindowVisitorPetID, lastWindowVisitorDateISO, offsprings, seenSkitIDs
        case lastWindowGreetDateISO, indoorCoinDateISO, indoorCoinCounts, discoveredFavoriteGesturePetIDs
        case giftedCurioEntryIDs, claimedCurioSetWeatherCodes, activeWalkQuest, completedWalkQuestCount
        case specialVisitorDates, hasPlacedDoorstepCorner
        case stampCountInCard, completedStampCardsCount, lastStampAwardedDateISO, unlockedCelebratedFeatures
    }

    /// Tolerant decoding: a missing key falls back to its default instead of failing the whole
    /// decode (which would silently reset the Sunroom, including raised offspring).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dailyWishes = try? c.decodeIfPresent(DailyWishesBoard.self, forKey: .dailyWishes)
        activeErrand = try? c.decodeIfPresent(ActivePetErrand.self, forKey: .activeErrand)
        errandHistory = (try? c.decodeIfPresent([CompletedErrandPostcard].self, forKey: .errandHistory)) ?? []
        unlockedTeaRecipeIDs = (try? c.decodeIfPresent([String].self, forKey: .unlockedTeaRecipeIDs)) ?? []
        totalTeaBrewedCount = (try? c.decodeIfPresent(Int.self, forKey: .totalTeaBrewedCount)) ?? 0
        hangingOrigamis = (try? c.decodeIfPresent([OrigamiCraftKind].self, forKey: .hangingOrigamis)) ?? []
        hasWindChimeInstalled = (try? c.decodeIfPresent(Bool.self, forKey: .hasWindChimeInstalled)) ?? true
        pinnedPostcardEncounterID = try? c.decodeIfPresent(UUID.self, forKey: .pinnedPostcardEncounterID)
        windowVisitCounts = (try? c.decodeIfPresent([String: Int].self, forKey: .windowVisitCounts)) ?? [:]
        lastWindowVisitorPetID = try? c.decodeIfPresent(String.self, forKey: .lastWindowVisitorPetID)
        lastWindowVisitorDateISO = try? c.decodeIfPresent(String.self, forKey: .lastWindowVisitorDateISO)
        offsprings = (try? c.decodeIfPresent([MysticalOffspringRecord].self, forKey: .offsprings)) ?? []
        seenSkitIDs = (try? c.decodeIfPresent([String].self, forKey: .seenSkitIDs)) ?? []
        lastWindowGreetDateISO = try? c.decodeIfPresent(String.self, forKey: .lastWindowGreetDateISO)
        indoorCoinDateISO = try? c.decodeIfPresent(String.self, forKey: .indoorCoinDateISO)
        indoorCoinCounts = (try? c.decodeIfPresent([String: Int].self, forKey: .indoorCoinCounts)) ?? [:]
        discoveredFavoriteGesturePetIDs = (try? c.decodeIfPresent([String].self, forKey: .discoveredFavoriteGesturePetIDs)) ?? []
        giftedCurioEntryIDs = (try? c.decodeIfPresent([UUID].self, forKey: .giftedCurioEntryIDs)) ?? []
        claimedCurioSetWeatherCodes = (try? c.decodeIfPresent([String].self, forKey: .claimedCurioSetWeatherCodes)) ?? []
        activeWalkQuest = try? c.decodeIfPresent(WalkWithMeQuest.self, forKey: .activeWalkQuest)
        completedWalkQuestCount = (try? c.decodeIfPresent(Int.self, forKey: .completedWalkQuestCount)) ?? 0
        specialVisitorDates = (try? c.decodeIfPresent([String: String].self, forKey: .specialVisitorDates)) ?? [:]
        hasPlacedDoorstepCorner = (try? c.decodeIfPresent(Bool.self, forKey: .hasPlacedDoorstepCorner)) ?? false
        let decodedStamps = (try? c.decodeIfPresent(Int.self, forKey: .stampCountInCard)) ?? 0
        stampCountInCard = min(max(decodedStamps, 0), CozyStampCard.slotCount - 1)
        completedStampCardsCount = max(0, (try? c.decodeIfPresent(Int.self, forKey: .completedStampCardsCount)) ?? 0)
        lastStampAwardedDateISO = try? c.decodeIfPresent(String.self, forKey: .lastStampAwardedDateISO)
        unlockedCelebratedFeatures = (try? c.decodeIfPresent([String].self, forKey: .unlockedCelebratedFeatures)) ?? []
    }
}

// MARK: - Zero-FOMO Cozy Stamp Card, Milestone Celebrations & Progress Snapshots

/// A gentle 7-slot stamp card: one stamp per civil day of play, never reset by missed days.
enum CozyStampCard {
    static let slotCount = 7
    static let completionRewardCoins = 15
}

/// A one-shot storybook celebration shown over the current screen. Never persisted.
struct MilestoneCelebration: Identifiable, Equatable, Sendable {
    enum Kind: String, Sendable {
        case bondTierUp, newCompanion, stampCard, curioSet, roomTheme, veranda
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String
    let detail: String
    let symbol: String
    let accentHex: String
    let rewardBadge: String?
}

/// Where a companion stands on the shared-days bond ladder (1, 3, 6, 10, 15, 25 days).
struct BondProgressSnapshot: Equatable, Sendable {
    let petID: String
    let currentTier: Int
    let currentTierTitle: String
    let nextTierTitle: String?
    let sharedDays: Int
    let nextMilestoneDays: Int?
    let daysRemaining: Int
    let progressFraction: Double

    var isMaxTier: Bool { nextMilestoneDays == nil }
}

/// A warm at-a-glance summary of the whole journey for the shop and keepsake diary.
struct JourneyProgressSummary: Equatable, Sendable {
    let companionsInvited: Int
    let companionsTotal: Int
    let curiosDiscovered: Int
    let curiosTotal: Int
    let weatherSetsCompleted: Int
    let weatherSetsTotal: Int
    let stampCountInCard: Int
    let completedStampCards: Int
    let themesOwned: Int
}

/// A short "walk with me" request a street companion makes after a greeting.
struct WalkWithMeQuest: Codable, Hashable, Sendable {
    var petID: String
    var localDateISO: String
    var targetSteps: Int
    var progressSteps: Int = 0

    var isComplete: Bool { progressSteps >= targetSteps }
    var remainingSteps: Int { max(0, targetSteps - progressSteps) }
    static let rewardCoins: Int = 3
}

/// Process-stable string hashing. Swift's `hashValue` is reseeded on every launch, so it must
/// never drive anything a player expects to stay put (daily wishes, visitors, names).
enum StableHash {
    static func value(_ text: String) -> Int {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return Int(hash & 0x3FFF_FFFF_FFFF_FFFF)
    }
}

// MARK: - 5. Mystical Folklore Storybook (6 Companions x 5 Milestone Chapters = 30 Chapters!)

struct FolkloreChapter: Identifiable, Hashable, Sendable {
    var id: String { "\(petID).ch\(chapterIndex)" }
    let petID: String
    let chapterIndex: Int // 1..5
    let requiredSharedDays: Int // 0/1, 3, 6, 10, 15
    let title: String
    let body: String
}

enum MysticalFolkloreCatalog {
    static func chapters(for petID: String) -> [FolkloreChapter] {
        switch petID {
        case "pet.02": // 杜松 ♂ 黑曜惡魔貓
            return [
                .init(petID: "pet.02", chapterIndex: 1, requiredSharedDays: 1, title: "第一章 · 講究的黑曜小角", body: "杜松總堅稱自己來自古老魔界，卻每早對著巷口玻璃門仔細整理耳尖的黑毛。誰若弄歪牠放在石階上的摺紙符，牠會氣鼓鼓甩尾三下，然後再自己重新摺一張更工整的。"),
                .init(petID: "pet.02", chapterIndex: 2, requiredSharedDays: 3, title: "第二章 · 第一張溫柔契約", body: "據說惡魔的紙符是用來締結契約的——但杜松的紙條上只寫著「今日路面乾爽，適合散步」。牠絕不會承認，那是特別留給常路過的你的。"),
                .init(petID: "pet.02", chapterIndex: 3, requiredSharedDays: 6, title: "第三章 · 紙箱裡的小領地", body: "雖然貴為惡魔貓，麵包店剛空出來的瓦楞紙箱卻是牠唯一的弱點。只要紙箱帶點麵粉香，杜松便會矜持地跳進去，只露出一對彎彎黑角觀察世界。"),
                .init(petID: "pet.02", chapterIndex: 4, requiredSharedDays: 10, title: "第四章 · 暗夜裡的小幫手", body: "每當有新來的奇幻夥伴不敢過馬路，杜松嘴上嘀咕著麻煩，尾巴尖卻悄悄替對方撥開水窪旁的落葉。"),
                .init(petID: "pet.02", chapterIndex: 5, requiredSharedDays: 15, title: "第五章 · 永遠不撕毀的約定", body: "「才不是因為喜歡你的陽光室才留下來的，只是你的木地板剛好適合摺紙罷了。」說完，杜松把頭輕輕靠在了你的手腕上。")
            ]
        case "pet.03": // 餘燼 ♂ 赤瓦火龍貓
            return [
                .init(petID: "pet.03", chapterIndex: 1, requiredSharedDays: 0, title: "第一章 · 以為自己是小貓的幼龍", body: "餘燼從小聽著老街屋簷的雨聲長大，深信背上的赤陶龍鱗只是比較特別的橘色虎斑。每次學貓咪打呼嚕，胸口就會透出剛出爐麵包般的暖烘烘熱氣。"),
                .init(petID: "pet.03", chapterIndex: 2, requiredSharedDays: 3, title: "第二章 · 烘暖石階的小秘密", body: "陰雨天裡，鄰居總覺得麵包店門口的石階特別溫暖乾爽，卻不知道那全是餘燼趴在上頭睡午覺留下的爐火餘溫。"),
                .init(petID: "pet.03", chapterIndex: 3, requiredSharedDays: 6, title: "第三章 · 小小火花的克制", body: "有次興奮過頭，餘燼鼻尖冒出一縷小煙，差點把毛毯烘焦。從那天起牠學會把爪尖收得軟軟的，只放出最剛好的暖薑茶溫度。"),
                .init(petID: "pet.03", chapterIndex: 4, requiredSharedDays: 10, title: "第四章 · 雨天的暖爐心願", body: "牠最喜歡看你把濕漉漉的傘收起來，然後把自己團成一顆小暖爐挨著你的鞋邊，像在說「我把雨氣都烘乾囉」。"),
                .init(petID: "pet.03", chapterIndex: 5, requiredSharedDays: 15, title: "第五章 · 陽光室的永恆微火", body: "無論牠究竟是龍還是貓，在你的陽光室裡，餘燼永遠是那隻會悄悄替每條毛毯與每顆心添上暖意的小寶貝。")
            ]
        case "pet.04": // 摺翼 ♀ 暮光夜魔貓
            return [
                .init(petID: "pet.04", chapterIndex: 1, requiredSharedDays: 1, title: "第一章 · 細摺的暮色斗篷", body: "摺翼的紫色蝠翼平時收得像把優雅的和紙摺扇，藏在老屋招牌的涼蔭下，靜靜看著白天喧鬧的街道。"),
                .init(petID: "pet.04", chapterIndex: 2, requiredSharedDays: 3, title: "第二章 · 黃昏的第一陣風", body: "當夕陽把天空染成薰衣草與橘紅交界，摺翼便會輕輕舒展翅膀。她並不想飛遠，只想在低牆上多看一眼晚歸的人影。"),
                .init(petID: "pet.04", chapterIndex: 3, requiredSharedDays: 6, title: "第三章 · 替夥伴遮住烈日", body: "發現陽光室午後光線太亮會晃醒熟睡的朋友後，摺翼學會站在窗邊展開薄薄的星塵小翼，灑下一片溫柔陰影。"),
                .init(petID: "pet.04", chapterIndex: 4, requiredSharedDays: 10, title: "第四章 · 收集風裡的聲音", body: "她特別喜歡屋簷風鈴與細雨打在傘面的節奏，總會歪著頭把每個溫柔聲響記在心底。"),
                .init(petID: "pet.04", chapterIndex: 5, requiredSharedDays: 15, title: "第五章 · 落在你肩畔的星夜", body: "曾經怕光的夜魔小貓，如今在你的陽光室裡也能安心閉上眼，在晨光與暮色之間找到最舒服的歸處。")
            ]
        case "pet.06": // 鈕扣 ♂ 墨玉小魔犬
            return [
                .init(petID: "pet.06", chapterIndex: 1, requiredSharedDays: 1, title: "第一章 · 肩畔的藍紫小燈火", body: "鈕扣天生伴著一團軟綿綿的藍紫鬼火，別的靈獸以為那是嚇人的魔法，其實它連一張紙也燒不著，只像一盞暖心小夜燈。"),
                .init(petID: "pet.06", chapterIndex: 2, requiredSharedDays: 3, title: "第二章 · 玄關整理小隊長", body: "忠厚細心的鈕扣最看不慣歪掉的地墊與散落的拖鞋，每次經過巷口小店總會悄悄用鼻尖替人家頂整齊。"),
                .init(petID: "pet.06", chapterIndex: 3, requiredSharedDays: 6, title: "第三章 · 雨夜的引路微光", body: "天色暗得早的雨天裡，鈕扣會主動亮起肩上的小紫火，靜靜守在台階旁照亮每一個濕滑的角落。"),
                .init(petID: "pet.06", chapterIndex: 4, requiredSharedDays: 10, title: "第四章 · 圓潤魔角的害羞秘密", body: "牠其實很喜歡被輕輕揉揉小魔角中間的絨毛，只是每次都會裝出很穩重的樣子，尾巴卻誠實地晃個不停。"),
                .init(petID: "pet.06", chapterIndex: 5, requiredSharedDays: 15, title: "第五章 · 永遠亮著的歸家燈", body: "無論你多晚推開陽光室的門，鈕扣和那盞藍紫小火永遠會在門檻邊溫柔迎接你回家。")
            ]
        case "pet.07": // 梅子 ♀ 銀月星靈犬
            return [
                .init(petID: "pet.07", chapterIndex: 1, requiredSharedDays: 1, title: "第一章 · 落入人間的一朵雲", body: "銀吻的梅子走起路來幾乎沒有聲音，身周縈繞著剛曬過月光般的柔白雲絮，讓經過的旅人呼吸不自覺慢了半拍。"),
                .init(petID: "pet.07", chapterIndex: 2, requiredSharedDays: 3, title: "第二章 · 不趕路的散步哲學", body: "梅子從不催促同伴走快一點。如果你停下來看一朵雲或聽一首歌，她就會優雅地在你身旁坐下，一起數著時間流過。"),
                .init(petID: "pet.07", chapterIndex: 3, requiredSharedDays: 6, title: "第三章 · 雲枕上的甜夢", body: "據說靠著梅子的雲霧毛色打盹的人，夢境裡都會飄著淡淡的桂花與雨後清風。"),
                .init(petID: "pet.07", chapterIndex: 4, requiredSharedDays: 10, title: "第四章 · 撫平焦躁的銀光", body: "每當陽光室裡有新來的小靈獸太興奮睡不著，梅子便會化出一縷微光雲絲，輕輕哄大家進入夢鄉。"),
                .init(petID: "pet.07", chapterIndex: 5, requiredSharedDays: 15, title: "第五章 · 並肩走過四季的星靈", body: "「漫長的日子不用急著走完，只要身邊有你在，每一步都是最美的風景。」")
            ]
        case "pet.08": // 蘆葦 ♀ 鹿角森靈犬
            return [
                .init(petID: "pet.08", chapterIndex: 1, requiredSharedDays: 1, title: "第一章 · 抽著新芽的小鹿角", body: "蘆葦頭頂的木質鹿角會隨季節長出嫩綠新葉，雨天帶著清甜朝露，晴天則散發著淡淡的紅檜林香。"),
                .init(petID: "pet.08", chapterIndex: 2, requiredSharedDays: 3, title: "第二章 · 乾爽石階的秘密地圖", body: "沒人比蘆葦更熟悉城裡的每一條林蔭小路。大雨來臨前，她總能提前三分鐘找到屋簷最寬、石板最乾的轉角。"),
                .init(petID: "pet.08", chapterIndex: 3, requiredSharedDays: 6, title: "第三章 · 苔蘚盆景的悄悄話", body: "在陽光室放上一盆森靈苔蘚後，蘆葦常常湊在盆邊輕輕嗅聞，彷彿在向遠方的山林捎去平安口信。"),
                .init(petID: "pet.08", chapterIndex: 4, requiredSharedDays: 10, title: "第四章 · 暮色裡的螢火鹿角", body: "黃昏散步時，她鹿角上的嫩葉會悄悄聚集幾點暖綠螢光，替同行的夥伴照亮林蔭下方的路。"),
                .init(petID: "pet.08", chapterIndex: 5, requiredSharedDays: 15, title: "第五章 · 把森林帶進陽光室", body: "因為遇見了你，原本只屬於遠方山林的蘆葦，決定把一片翠綠溫柔的春天留在你的窗邊。")
            ]
        default:
            return []
        }
    }
}

// MARK: - 6. Emergent Multi-Pet Sunroom Skits

struct SunroomPairSkit: Identifiable, Hashable, Sendable {
    let id: String
    let petA: String
    let petB: String
    let title: String
    let dialogue: String
}

enum SunroomSkitCatalog {
    static let all: [SunroomPairSkit] = [
        .init(id: "skit.02_03.toast", petA: "pet.02", petB: "pet.03", title: "烘暖的摺紙角", dialogue: "杜松才剛摺好一張筆直的小星星，餘燼好奇湊近打了個暖噴嚏，紙角微微捲成可愛的琥珀色。杜松愣了兩秒，最後竟默默收進了自己的寶盒裡。"),
        .init(id: "skit.03_04.shade", petA: "pet.03", petB: "pet.04", title: "暖火與暮翼", dialogue: "午後光線透進窗台，摺翼展開紫灰小翼替打盹的餘燼遮住眼睛，餘燼則把暖烘烘的尾巴繞過來替她驅散窗邊涼風。"),
        .init(id: "skit.03_07.cloudtea", petA: "pet.03", petB: "pet.07", title: "雲霧暖茶時間", dialogue: "餘燼的微微熱氣遇上梅子身旁的柔白雲絮，陽光室中央竟飄起一縷像剛沏好熱茶般的香氣暖霧，兩位小傢伙滿足地同時瞇起眼。"),
        .init(id: "skit.02_06.tidy", petA: "pet.02", petB: "pet.06", title: "整齊控聯盟", dialogue: "鈕扣認真把玄關拖鞋排成一條直線，杜松在旁邊背著爪監工，還順手把地毯流蘇一根根撥齊。"),
        .init(id: "skit.04_08.rainlisten", petA: "pet.04", petB: "pet.08", title: "窗邊聽雨會", dialogue: "摺翼與蘆葦並肩坐在窗台前數雨滴，蘆葦鹿角上的小嫩葉隨著窗外微風輕輕搖曳，像在替細雨打拍子。"),
        .init(id: "skit.06_08.lantern", petA: "pet.06", petB: "pet.08", title: "幽火與螢光", dialogue: "傍晚天色轉暗時，鈕扣肩上的藍紫小火與蘆葦鹿角上的青綠螢光互相映照，把木造陽光室襯得宛如森林裡的小茶館。"),
        .init(id: "skit.07_08.nap", petA: "pet.07", petB: "pet.08", title: "星霧與森林香", dialogue: "梅子把柔軟的銀白雲絮鋪在苔蘚盆景旁，蘆葦舒舒服服把下巴枕上去，兩人一起做了一場關於青草與星空的甜夢。"),
        .init(id: "skit.02_04.wings", petA: "pet.02", petB: "pet.04", title: "翅膀比一比", dialogue: "杜松神氣地展示自己的黑曜小蝠翼，摺翼輕輕舒展細褶暮色羽翼回應——兩隻夜行小貓最後決定一起霸佔最高那層紅檜棲木架。")
    ]

    static func pickSkit(petA: String, petB: String, seen: Set<String>) -> SunroomPairSkit {
        let pair = Set([petA, petB])
        let matching = all.filter { Set([$0.petA, $0.petB]) == pair }
        if let unseen = matching.first(where: { !seen.contains($0.id) }) {
            return unseen
        }
        if let anyMatch = matching.first {
            return anyMatch
        }
        let nameA = PetCatalog.pet(id: petA).name
        let nameB = PetCatalog.pet(id: petB).name
        return SunroomPairSkit(
            id: "skit.dynamic.\(min(petA, petB))_\(max(petA, petB))",
            petA: petA,
            petB: petB,
            title: "陽光室的小默契",
            dialogue: "\(nameA)與\(nameB)在紅檜地板上輕輕碰了碰鼻尖，彷彿悄悄約好下次要一起去街角探險。"
        )
    }
}
