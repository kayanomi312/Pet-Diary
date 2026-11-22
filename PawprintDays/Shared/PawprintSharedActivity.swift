import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Shared snapshot persisted for Home Screen Widgets (App Group with safe fallback).
struct PawprintWidgetSnapshot: Codable, Sendable {
    var companionName: String
    var companionPetID: String?
    var weatherDisplayName: String
    var weatherSymbol: String
    var stepsToday: Int
    var stepsUntilPocketFind: Int
    var coinBalance: Int
    var encountersToday: Int
    var updatedAt: Date

    static let placeholder = PawprintWidgetSnapshot(
        companionName: "餘燼",
        companionPetID: "pet.03",
        weatherDisplayName: "微涼細雨",
        weatherSymbol: "cloud.drizzle.fill",
        stepsToday: 1_240,
        stepsUntilPocketFind: 160,
        coinBalance: 18,
        encountersToday: 2,
        updatedAt: Date()
    )
}

enum PawprintWidgetStore {
    static let appGroupID = "group.com.pawprintdays.shared"
    private static let key = "pawprintdays.widget.snapshot.v1"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func save(_ snapshot: PawprintWidgetSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> PawprintWidgetSnapshot {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(PawprintWidgetSnapshot.self, from: data) {
            return decoded
        }
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(PawprintWidgetSnapshot.self, from: data) {
            return decoded
        }
        return .placeholder
    }
}

#if canImport(ActivityKit)
/// Lock Screen & Dynamic Island Live Activity Attributes for an Active Stroll Session!
struct StrollLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        var steps: Int
        var coinsEarned: Int
        var nearestCornerLabel: String
        var nearestDistanceMeters: Int
        var isNearPocketFind: Bool
    }

    var companionName: String
    var charmTitle: String
    var weatherLabel: String
    var weatherSymbol: String
}
#endif
