import Foundation
import UserNotifications

// MARK: - Kinds

/// 四種溫柔的本機提醒。每一種都有固定的 identifier，重新排程時會取代舊的，不會重複堆疊。
enum GentleNotificationKind: String, CaseIterable, Sendable {
    case companionWaiting = "companionWaiting"
    case strollRecap = "strollRecap"
    case mentorshipReady = "mentorshipReady"
    case eveningDiary = "eveningDiary"

    static let identifierPrefix = "pawprintdays.gentle."

    var identifier: String { Self.identifierPrefix + rawValue }

    /// 落在安靜時段時的處理：過時就不好玩的提醒直接放棄，其餘順延到安靜時段結束。
    var quietHoursPolicy: QuietHoursPolicy {
        switch self {
        case .companionWaiting, .strollRecap: return .drop
        case .mentorshipReady, .eveningDiary: return .deferToEnd
        }
    }

    enum QuietHoursPolicy: Sendable { case drop, deferToEnd }
}

// MARK: - Quiet hours

/// 安靜時段（以當日分鐘數表示，可跨午夜）。start == end 代表不設安靜時段。
struct GentleQuietHours: Codable, Equatable, Sendable {
    var startMinute: Int
    var endMinute: Int

    static let `default` = GentleQuietHours(startMinute: 22 * 60, endMinute: 8 * 60)

    func contains(_ date: Date, calendar: Calendar) -> Bool {
        guard startMinute != endMinute else { return false }
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        if startMinute < endMinute {
            return minute >= startMinute && minute < endMinute
        }
        return minute >= startMinute || minute < endMinute
    }

    /// 下一個安靜時段結束的時間點（嚴格晚於 `date`）。
    func nextEnd(after date: Date, calendar: Calendar) -> Date {
        let components = DateComponents(hour: endMinute / 60, minute: endMinute % 60, second: 0)
        return calendar.nextDate(after: date, matching: components, matchingPolicy: .nextTime) ?? date
    }
}

// MARK: - Preferences

/// 玩家的提醒偏好。`isEnabled` 是總開關，預設關閉（需玩家主動開啟）。
struct GentleNotificationPreferences: Codable, Equatable, Sendable {
    var isEnabled = false
    var companionWaitingEnabled = true
    var strollRecapEnabled = true
    var mentorshipReadyEnabled = true
    var eveningDiaryEnabled = true
    var quietHours = GentleQuietHours.default
    /// 晚間日記提醒的時間（當日分鐘數），預設 20:30。
    var eveningDiaryMinuteOfDay = 20 * 60 + 30

    func isEnabled(_ kind: GentleNotificationKind) -> Bool {
        guard isEnabled else { return false }
        switch kind {
        case .companionWaiting: return companionWaitingEnabled
        case .strollRecap: return strollRecapEnabled
        case .mentorshipReady: return mentorshipReadyEnabled
        case .eveningDiary: return eveningDiaryEnabled
        }
    }
}

// MARK: - Outcome

enum GentleNotificationOutcome: Equatable, Sendable {
    case scheduled(Date)
    case skipped(SkipReason)

    enum SkipReason: Equatable, Sendable {
        case optedOut
        case kindDisabled
        case notAuthorized
        case quietHours
        case dailyLimitReached
        case dateInPast
        case failed
    }
}

// MARK: - Copy

/// 溫暖繪本口吻的提醒文案。純函式，方便測試與日後在地化。
enum GentleNotificationCopy {
    struct Message: Equatable, Sendable {
        let title: String
        let body: String
    }

    static func companionWaiting(companionName: String?, cornerName: String?) -> Message {
        let who = trimmed(companionName) ?? "一位毛孩朋友"
        let place = trimmed(cornerName).map { "「\($0)」的轉角" } ?? "附近的巷口"
        return Message(
            title: "巷口有人在等你",
            body: "\(who)在\(place)探出頭來，好像想和你打聲招呼。散步時順路去看看吧。"
        )
    }

    static func strollRecap(steps: Int, friendsMet: Int) -> Message {
        let body: String
        if friendsMet > 0 {
            body = "這趟走了 \(steps) 步，還遇見 \(friendsMet) 位朋友。回來翻翻日記，替這段路蓋個印章吧。"
        } else {
            body = "這趟走了 \(steps) 步，風和光都記在心裡了。回來翻翻日記，替這段路蓋個印章吧。"
        }
        return Message(title: "今天的散步，好溫柔", body: body)
    }

    static func mentorshipReady(mentorName: String?, apprenticeName: String?) -> Message {
        let mentor = trimmed(mentorName) ?? "前輩"
        let apprentice = trimmed(apprenticeName) ?? "小夥伴"
        return Message(
            title: "小課堂準備好了",
            body: "\(mentor)替\(apprentice)留了一堂悄悄話課，回來看看他們學會了什麼吧。"
        )
    }

    static func eveningDiary() -> Message {
        Message(
            title: "今晚的日記還空著",
            body: "把今天的小事寫進日記吧，哪怕只是一枚小小的肉球印。"
        )
    }

    private static func trimmed(_ text: String?) -> String? {
        guard let value = text?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}

// MARK: - Center abstraction

/// 對 `UNUserNotificationCenter` 的最小封裝，方便測試時注入假的實作。
@MainActor
protocol UserNotificationScheduling {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

@MainActor
struct SystemUserNotificationCenter: UserNotificationScheduling {
    private let center = UNUserNotificationCenter.current()

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

// MARK: - Scheduler

/// 溫柔提醒排程器：
/// - 需玩家主動開啟（`preferences.isEnabled`），且系統已授權通知。
/// - 安靜時段（預設 22:00–08:00）內不打擾。
/// - 每天最多 2 則；已啟用的晚間日記提醒會固定佔用 1 則名額。
/// - identifier 固定，重新排程會取代舊提醒。
///
/// 尚未接上 UI／GameCoordinator；由主程式在重構完成後串接。
@MainActor
final class GentleNotificationScheduler {
    static let maxNotificationsPerDay = 2
    static let preferencesKey = "pawprintdays.gentleNotifications.preferences.v1"
    static let ledgerKey = "pawprintdays.gentleNotifications.ledger.v1"
    static let threadIdentifier = "pawprintdays.gentle"
    /// `userInfo` 中標示提醒種類的鍵，供日後點擊通知時導覽使用。
    static let kindUserInfoKey = "gentleNotificationKind"

    private let center: UserNotificationScheduling
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date

    init(
        center: UserNotificationScheduling = SystemUserNotificationCenter(),
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.center = center
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
    }

    // MARK: Preferences

    var preferences: GentleNotificationPreferences {
        get {
            guard let data = defaults.data(forKey: Self.preferencesKey),
                  let value = try? JSONDecoder().decode(GentleNotificationPreferences.self, from: data) else {
                return GentleNotificationPreferences()
            }
            return value
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Self.preferencesKey)
            }
        }
    }

    /// 儲存新偏好，並讓已排程的提醒與之同步（關閉的種類會被取消，晚間日記會依新時間重排）。
    func apply(_ newPreferences: GentleNotificationPreferences) async {
        preferences = newPreferences
        for kind in GentleNotificationKind.allCases where !newPreferences.isEnabled(kind) {
            cancel(kind)
        }
        if newPreferences.isEnabled(.eveningDiary) {
            enforceDailyLimitAfterReservingDiarySlot()
            _ = await scheduleEveningDiary()
        }
    }

    // MARK: Authorization

    /// 向系統請求通知權限。建議在玩家於設定中打開總開關時才呼叫。
    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization()) ?? false
    }

    private func isAuthorized() async -> Bool {
        switch await center.authorizationStatus() {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined, .denied: return false
        @unknown default: return false
        }
    }

    // MARK: Scheduling API

    /// 有毛孩在附近巷口等待。
    @discardableResult
    func scheduleCompanionWaiting(companionName: String?, cornerName: String?, at fireDate: Date) async -> GentleNotificationOutcome {
        await schedule(.companionWaiting, message: GentleNotificationCopy.companionWaiting(companionName: companionName, cornerName: cornerName), at: fireDate)
    }

    /// 散步結束後的回顧。預設在 `delay`（15 分鐘）後送出。
    @discardableResult
    func scheduleStrollRecap(steps: Int, friendsMet: Int, after delay: TimeInterval = 15 * 60) async -> GentleNotificationOutcome {
        await schedule(.strollRecap, message: GentleNotificationCopy.strollRecap(steps: steps, friendsMet: friendsMet), at: now().addingTimeInterval(delay))
    }

    /// 師徒小課堂準備好了。
    @discardableResult
    func scheduleMentorshipReady(mentorName: String?, apprenticeName: String?, at fireDate: Date) async -> GentleNotificationOutcome {
        await schedule(.mentorshipReady, message: GentleNotificationCopy.mentorshipReady(mentorName: mentorName, apprenticeName: apprenticeName), at: fireDate)
    }

    /// 每天一次的晚間日記提醒（重複觸發，預設 20:30）。若時間落在安靜時段，會順延到安靜時段結束。
    @discardableResult
    func scheduleEveningDiary() async -> GentleNotificationOutcome {
        let kind = GentleNotificationKind.eveningDiary
        let prefs = preferences
        guard prefs.isEnabled else { return .skipped(.optedOut) }
        guard prefs.isEnabled(kind) else { return .skipped(.kindDisabled) }
        guard await isAuthorized() else { return .skipped(.notAuthorized) }

        let reminder = effectiveDiaryTime(prefs)
        let message = GentleNotificationCopy.eveningDiary()
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: reminder.hour, minute: reminder.minute),
            repeats: true
        )
        do {
            try await center.add(makeRequest(kind, message: message, trigger: trigger))
        } catch {
            return .skipped(.failed)
        }
        let next = calendar.nextDate(after: now(), matching: DateComponents(hour: reminder.hour, minute: reminder.minute, second: 0), matchingPolicy: .nextTime) ?? now()
        return .scheduled(next)
    }

    func cancel(_ kind: GentleNotificationKind) {
        center.removePendingNotificationRequests(withIdentifiers: [kind.identifier])
        var ledger = loadLedger()
        for (day, ids) in ledger {
            let kept = ids.filter { $0 != kind.rawValue }
            ledger[day] = kept.isEmpty ? nil : kept
        }
        saveLedger(ledger)
    }

    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: GentleNotificationKind.allCases.map(\.identifier))
        saveLedger([:])
    }

    // MARK: Core

    private func schedule(_ kind: GentleNotificationKind, message: GentleNotificationCopy.Message, at requestedDate: Date) async -> GentleNotificationOutcome {
        let prefs = preferences
        guard prefs.isEnabled else { return .skipped(.optedOut) }
        guard prefs.isEnabled(kind) else { return .skipped(.kindDisabled) }
        guard await isAuthorized() else { return .skipped(.notAuthorized) }

        var fireDate = requestedDate
        if prefs.quietHours.contains(fireDate, calendar: calendar) {
            switch kind.quietHoursPolicy {
            case .drop: return .skipped(.quietHours)
            case .deferToEnd: fireDate = prefs.quietHours.nextEnd(after: fireDate, calendar: calendar)
            }
        }
        guard fireDate > now() else { return .skipped(.dateInPast) }

        var ledger = pruned(loadLedger())
        // 重新排程同一種提醒時，先釋放它原本佔用的名額。
        for (day, ids) in ledger {
            let kept = ids.filter { $0 != kind.rawValue }
            ledger[day] = kept.isEmpty ? nil : kept
        }
        let dayKey = Self.dayKey(for: fireDate, calendar: calendar)
        let reserved = prefs.isEnabled(.eveningDiary) ? 1 : 0
        guard (ledger[dayKey]?.count ?? 0) + reserved < Self.maxNotificationsPerDay else {
            // 舊的提醒已在上方從名額中移除，這裡同步取消，避免殘留。
            center.removePendingNotificationRequests(withIdentifiers: [kind.identifier])
            saveLedger(ledger)
            return .skipped(.dailyLimitReached)
        }

        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        do {
            try await center.add(makeRequest(kind, message: message, trigger: trigger))
        } catch {
            saveLedger(ledger)
            return .skipped(.failed)
        }
        ledger[dayKey, default: []].append(kind.rawValue)
        saveLedger(ledger)
        return .scheduled(fireDate)
    }

    private func makeRequest(_ kind: GentleNotificationKind, message: GentleNotificationCopy.Message, trigger: UNNotificationTrigger) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = nil
        content.threadIdentifier = Self.threadIdentifier
        content.interruptionLevel = .passive
        content.userInfo = [Self.kindUserInfoKey: kind.rawValue]
        return UNNotificationRequest(identifier: kind.identifier, content: content, trigger: trigger)
    }

    private func effectiveDiaryTime(_ prefs: GentleNotificationPreferences) -> (hour: Int, minute: Int) {
        var minuteOfDay = prefs.eveningDiaryMinuteOfDay
        let probe = calendar.date(bySettingHour: minuteOfDay / 60, minute: minuteOfDay % 60, second: 0, of: now()) ?? now()
        if prefs.quietHours.contains(probe, calendar: calendar) {
            minuteOfDay = prefs.quietHours.endMinute
        }
        return (minuteOfDay / 60, minuteOfDay % 60)
    }

    // MARK: Ledger (哪一天已排了哪些一次性提醒)

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func loadLedger() -> [String: [String]] {
        guard let data = defaults.data(forKey: Self.ledgerKey),
              let value = try? JSONDecoder().decode([String: [String]].self, from: data) else { return [:] }
        return value
    }

    private func saveLedger(_ ledger: [String: [String]]) {
        if let data = try? JSONEncoder().encode(ledger) {
            defaults.set(data, forKey: Self.ledgerKey)
        }
    }

    private func pruned(_ ledger: [String: [String]]) -> [String: [String]] {
        let today = Self.dayKey(for: now(), calendar: calendar)
        return ledger.filter { $0.key >= today }
    }

    /// 開啟晚間日記提醒後，若某天已排了太多一次性提醒，取消最晚排入的多餘項目，維持每天最多 2 則。
    private func enforceDailyLimitAfterReservingDiarySlot() {
        var ledger = pruned(loadLedger())
        let allowed = Self.maxNotificationsPerDay - 1
        for (day, ids) in ledger where ids.count > allowed {
            let removed = ids.suffix(ids.count - allowed)
            center.removePendingNotificationRequests(withIdentifiers: removed.map { GentleNotificationKind.identifierPrefix + $0 })
            ledger[day] = Array(ids.prefix(allowed))
        }
        saveLedger(ledger)
    }
}
