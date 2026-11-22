import Foundation
import AppIntents
import UIKit

/// Siri & Shortcuts Intent: "Hey Siri, 開始足印散步"
struct StartStrollAppIntent: AppIntent {
    static let title: LocalizedStringResource = "開始足印散步"
    static let description = IntentDescription("打開足印日記並準備攜帶小動物夥伴出發散步。")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        if let url = URL(string: "pawprintdays://start-stroll") {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}

/// Siri & Shortcuts Intent: "Hey Siri, 查看今天的足印日記"
struct CheckTodayDiaryAppIntent: AppIntent {
    static let title: LocalizedStringResource = "查看今天的足印日記"
    static let description = IntentDescription("打開足印日記的精裝手繪日記頁。")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        if let url = URL(string: "pawprintdays://diary") {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}

/// Registers hands-free Siri phrases automatically in the iOS Shortcuts app.
struct PawprintAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartStrollAppIntent(),
            phrases: [
                "在\(.applicationName)開始散步",
                "用\(.applicationName)出發散步",
                "帶小動物在\(.applicationName)散步"
            ],
            shortTitle: "開始足印散步",
            systemImageName: "figure.walk"
        )
        AppShortcut(
            intent: CheckTodayDiaryAppIntent(),
            phrases: [
                "查看\(.applicationName)",
                "打開\(.applicationName)今天的日記"
            ],
            shortTitle: "查看足印日記",
            systemImageName: "book.closed.fill"
        )
    }
}
