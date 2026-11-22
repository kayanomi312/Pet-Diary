import Foundation
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class StrollLiveActivityManager {
    static let shared = StrollLiveActivityManager()
    private init() {}

    func syncWidgetSnapshot(
        companionName: String,
        companionPetID: String?,
        weather: WeatherMode,
        stepsToday: Int,
        stepsUntilPocketFind: Int,
        coinBalance: Int,
        encountersToday: Int
    ) {
        let snap = PawprintWidgetSnapshot(
            companionName: companionName,
            companionPetID: companionPetID,
            weatherDisplayName: weather.displayName,
            weatherSymbol: weather.sfSymbol,
            stepsToday: stepsToday,
            stepsUntilPocketFind: stepsUntilPocketFind,
            coinBalance: coinBalance,
            encountersToday: encountersToday,
            updatedAt: Date()
        )
        PawprintWidgetStore.save(snap)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func startStrollLiveActivity(
        companionName: String,
        charmTitle: String,
        weather: WeatherMode,
        nearestCornerLabel: String,
        nearestDistanceMeters: Int
    ) {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attrs = StrollLiveActivityAttributes(
            companionName: companionName,
            charmTitle: charmTitle,
            weatherLabel: weather.displayName,
            weatherSymbol: weather.sfSymbol
        )
        let state = StrollLiveActivityAttributes.ContentState(
            steps: 0,
            coinsEarned: 0,
            nearestCornerLabel: nearestCornerLabel,
            nearestDistanceMeters: nearestDistanceMeters,
            isNearPocketFind: false
        )
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(3600))
        _ = try? Activity<StrollLiveActivityAttributes>.request(attributes: attrs, content: content, pushType: nil)
        #endif
    }

    func updateStrollLiveActivity(
        steps: Int,
        coinsEarned: Int,
        nearestCornerLabel: String,
        nearestDistanceMeters: Int,
        isNearPocketFind: Bool
    ) {
        #if canImport(ActivityKit)
        let state = StrollLiveActivityAttributes.ContentState(
            steps: steps,
            coinsEarned: coinsEarned,
            nearestCornerLabel: nearestCornerLabel,
            nearestDistanceMeters: nearestDistanceMeters,
            isNearPocketFind: isNearPocketFind
        )
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(3600))
        Task {
            for activity in Activity<StrollLiveActivityAttributes>.activities {
                await activity.update(content)
            }
        }
        #endif
    }

    func endStrollLiveActivity() {
        #if canImport(ActivityKit)
        Task {
            for activity in Activity<StrollLiveActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        #endif
    }
}
