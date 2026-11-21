import Foundation
import CoreLocation

enum AppScreen: Equatable, Sendable {
    case street
    case encounter(siteID: String, petID: String, companionStreetPetID: String? = nil)
    case home
    case tactileCare(petID: String)
    case sketchbook
    case curioCubbies
}

enum WeatherMode: String, Codable, CaseIterable, Sendable {
    case clearMorning = "clear_morning"
    case overcast = "overcast"
    case lightRain = "light_rain"
    case postRain = "post_rain"
    case dusk = "dusk"

    var displayName: String {
        switch self {
        case .clearMorning: return "晴朗晨光"
        case .overcast: return "微陰多雲"
        case .lightRain: return "細雨微涼"
        case .postRain: return "雨後初晴"
        case .dusk: return "暖黃暮色"
        }
    }

    /// Maps directly to PaperGrainAndLUT.metal weatherMode float parameter
    var shaderValue: Float {
        switch self {
        case .clearMorning, .overcast: return 0.0
        case .lightRain, .postRain: return 1.0
        case .dusk: return 2.0
        }
    }

    var isRainy: Bool {
        self == .lightRain || self == .postRain
    }

    var sfSymbol: String {
        switch self {
        case .clearMorning: return "sun.max"
        case .overcast: return "cloud"
        case .lightRain: return "cloud.drizzle"
        case .postRain: return "cloud.sun.rain"
        case .dusk: return "sunset"
        }
    }
}

enum SeasonalRoomTheme: String, Codable, CaseIterable, Sendable {
    case springSunlit = "room.spring_sunlit"
    case rainySeason = "room.rainy_season"
    case autumnCedar = "room.autumn_cedar"
    case winterLamp = "room.winter_lamp"

    var title: String {
        switch self {
        case .springSunlit: return "春日暖木日光"
        case .rainySeason: return "梅雨季微霧"
        case .autumnCedar: return "秋日紅檜餘暉"
        case .winterLamp: return "冬夜暖燈茶室"
        }
    }

    var wallHex: String {
        switch self {
        case .springSunlit: return "#EFE6D4"
        case .rainySeason: return "#E4E8E6"
        case .autumnCedar: return "#EAD9C2"
        case .winterLamp: return "#E6D3B8"
        }
    }

    var floorTopHex: String {
        switch self {
        case .springSunlit: return "#CFA679"
        case .rainySeason: return "#B7987A"
        case .autumnCedar: return "#C28B5B"
        case .winterLamp: return "#A5754A"
        }
    }

    var floorBottomHex: String {
        switch self {
        case .springSunlit: return "#B5895A"
        case .rainySeason: return "#9A7D62"
        case .autumnCedar: return "#9C6A3F"
        case .winterLamp: return "#7D5432"
        }
    }
}

enum OutingPackKind: String, Codable, CaseIterable, Sendable {
    case sketchbookCharcoal = "outing.sketchbook_pack"
    case trailShelterTowel = "outing.towel_pack"

    var title: String {
        switch self {
        case .sketchbookCharcoal: return "速寫本與炭筆組"
        case .trailShelterTowel: return "步道避雨毛巾組"
        }
    }
}

enum GreetingGesture: String, Codable, CaseIterable, Sendable {
    case offerHand = "offer_hand"
    case crouchQuietly = "crouch_quietly"
    case rollBall = "roll_ball"
    case holdUmbrella = "hold_umbrella"

    var title: String {
        switch self {
        case .offerHand: return "伸手輕輕打招呼"
        case .crouchQuietly: return "坐在木凳靜靜陪伴"
        case .rollBall: return "滾出縫布球"
        case .holdUmbrella: return "撐傘一起躲雨"
        }
    }

    var diaryVerb: String {
        switch self {
        case .offerHand: return "湊上前輕嗅我攤開的手背"
        case .crouchQuietly: return "安靜地窩在我的鞋邊"
        case .rollBall: return "用鼻尖把縫布球輕推回來"
        case .holdUmbrella: return "在乾燥的騎樓下和我一起避雨"
        }
    }
}

enum PawState: String, Sendable {
    case distant
    case inRange
    case metToday
    case strollChain
}

enum PetSpeciesKind: String, Codable, Sendable {
    case ordinaryCat = "普通貓"
    case dragonCat = "屋瓦龍貓"
    case batCat = "莢翼蝠貓"
    case ordinaryDog = "普通狗"
    case marshHound = "沼澤獵犬"

    var isCatFamily: Bool {
        switch self {
        case .ordinaryCat, .dragonCat, .batCat: return true
        case .ordinaryDog, .marshHound: return false
        }
    }

    var isMagical: Bool {
        switch self {
        case .dragonCat, .batCat, .marshHound: return true
        case .ordinaryCat, .ordinaryDog: return false
        }
    }
}

enum HabitFamily: String, Codable, CaseIterable, Sendable {
    case wait = "habit.wait"
    case offer = "habit.offer"
    case nest = "habit.nest"
    case shield = "habit.shield"

    var title: String {
        switch self {
        case .wait: return "沉靜守候"
        case .offer: return "輕遞小物"
        case .nest: return "暖毯築窩"
        case .shield: return "遮蔭引路"
        }
    }

    var sharedPropID: String {
        switch self {
        case .wait: return "goodie.window_cushion"
        case .offer: return "goodie.cloth_ball"
        case .nest: return "goodie.wool_blanket"
        case .shield: return "goodie.folded_towel"
        }
    }

    var particleDescription: String {
        switch self {
        case .wait: return "安穩收爪"
        case .offer: return "輕推小物"
        case .nest: return "琥珀暖意微塵"
        case .shield: return "溫柔涼蔭光影"
        }
    }
}

enum FoodTexture: String, Codable, CaseIterable, Sendable {
    case crispy = "香脆"
    case soft = "綿軟"
    case warm = "溫熱"
}

enum InviteState: String, Codable, Sendable {
    case unmet
    case sighted
    case invitedHome
}

enum DeletionState: String, Codable, Sendable {
    case active
    case placeErased
}

enum TeachingState: String, Codable, Sendable {
    case queued
    case demonstrated
    case mastered
}

struct CoordinatePoint: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ForagedCurioEntry: Codable, Hashable, Identifiable, Sendable {
    var id: UUID = UUID()
    var curioID: String
    var placeLabel: String
    var weatherCode: String
    var localDateISO: String
}

struct StepIntervalRecord: Codable, Hashable, Sendable {
    var intervalBucketUTC: Int64
    var rawSteps: Int
    var highWaterAcceptedSteps: Int
}

struct Stage1VerificationSummary: Sendable {
    var gate1ProximityAndDay3CallbackPassed: Bool
    var gate2ImmutableSnapshotPassed: Bool
    var gate3DisjointCoinLedgerPassed: Bool
    var gate4SingleDayErasurePassed: Bool
    var details: [String]

    var allPassed: Bool {
        gate1ProximityAndDay3CallbackPassed &&
        gate2ImmutableSnapshotPassed &&
        gate3DisjointCoinLedgerPassed &&
        gate4SingleDayErasurePassed
    }
}

enum CivilCalendarHelper {
    static func localDateISO(for date: Date, timeZone: TimeZone = .current) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func displayDate(from localDateISO: String) -> String {
        let parts = localDateISO.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return localDateISO }
        var comps = DateComponents()
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = parts[2]
        comps.hour = 12
        let cal = Calendar(identifier: .gregorian)
        guard let date = cal.date(from: comps) else { return localDateISO }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }

    static func monthTitle(from localDateISO: String) -> String {
        let parts = localDateISO.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return localDateISO }
        var comps = DateComponents()
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = 1
        comps.hour = 12
        let cal = Calendar(identifier: .gregorian)
        guard let date = cal.date(from: comps) else { return localDateISO }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }

    static func dayNumber(from localDateISO: String) -> Int {
        let parts = localDateISO.split(separator: "-").compactMap { Int($0) }
        return parts.count == 3 ? parts[2] : 1
    }

    static func daysBetween(startISO: String, endISO: String) -> Int {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d1 = formatter.date(from: startISO),
              let d2 = formatter.date(from: endISO) else { return 0 }
        return Calendar(identifier: .gregorian).dateComponents([.day], from: d1, to: d2).day ?? 0
    }
}
