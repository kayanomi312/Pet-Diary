import XCTest
import UserNotifications
@testable import PawprintDays

@MainActor
private final class FakeNotificationCenter: UserNotificationScheduling {
    var status: UNAuthorizationStatus = .authorized
    var grantsAuthorization = true
    var failNextAdd = false
    private(set) var pending: [String: UNNotificationRequest] = [:]
    private(set) var addCount = 0

    func authorizationStatus() async -> UNAuthorizationStatus { status }

    func requestAuthorization() async throws -> Bool {
        status = grantsAuthorization ? .authorized : .denied
        return grantsAuthorization
    }

    func add(_ request: UNNotificationRequest) async throws {
        if failNextAdd {
            failNextAdd = false
            throw NSError(domain: "fake", code: 1)
        }
        addCount += 1
        pending[request.identifier] = request
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        identifiers.forEach { pending[$0] = nil }
    }
}

@MainActor
final class GentleNotificationSchedulerTests: XCTestCase {
    private var calendar: Calendar!
    private var center: FakeNotificationCenter!
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var clock: Date!
    private var scheduler: GentleNotificationScheduler!

    override func setUp() async throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Taipei")!
        calendar = cal
        center = FakeNotificationCenter()
        suiteName = "GentleNotificationSchedulerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        clock = date(2026, 11, 23, 10, 0)
        scheduler = GentleNotificationScheduler(center: center, defaults: defaults, calendar: calendar, now: { [unowned self] in self.clock })
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    // MARK: Helpers

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func optIn(diary: Bool = false) {
        var prefs = GentleNotificationPreferences()
        prefs.isEnabled = true
        prefs.eveningDiaryEnabled = diary
        scheduler.preferences = prefs
    }

    private func triggerComponents(_ id: GentleNotificationKind) -> DateComponents? {
        (center.pending[id.identifier]?.trigger as? UNCalendarNotificationTrigger)?.dateComponents
    }

    // MARK: Opt-in & authorization

    func testNothingIsScheduledUntilPlayerOptsIn() async {
        let outcome = await scheduler.scheduleCompanionWaiting(companionName: "Cinder", cornerName: nil, at: date(2026, 11, 23, 15))
        XCTAssertEqual(outcome, .skipped(.optedOut))
        XCTAssertTrue(center.pending.isEmpty)
        XCTAssertFalse(scheduler.preferences.isEnabled)
    }

    func testDeniedOrUndeterminedAuthorizationSkips() async {
        optIn()
        center.status = .denied
        let denied = await scheduler.scheduleStrollRecap(steps: 100, friendsMet: 0)
        XCTAssertEqual(denied, .skipped(.notAuthorized))
        center.status = .notDetermined
        let undetermined = await scheduler.scheduleMentorshipReady(mentorName: nil, apprenticeName: nil, at: date(2026, 11, 23, 15))
        XCTAssertEqual(undetermined, .skipped(.notAuthorized))
        XCTAssertTrue(center.pending.isEmpty)
    }

    func testRequestAuthorizationReflectsSystemAnswer() async {
        center.status = .notDetermined
        center.grantsAuthorization = false
        let denied = await scheduler.requestAuthorization()
        XCTAssertFalse(denied)
        center.grantsAuthorization = true
        let granted = await scheduler.requestAuthorization()
        XCTAssertTrue(granted)
    }

    func testDisabledKindIsSkipped() async {
        var prefs = GentleNotificationPreferences()
        prefs.isEnabled = true
        prefs.strollRecapEnabled = false
        scheduler.preferences = prefs
        let outcome = await scheduler.scheduleStrollRecap(steps: 100, friendsMet: 0)
        XCTAssertEqual(outcome, .skipped(.kindDisabled))
    }

    // MARK: Content & identifiers

    func testCompanionWaitingUsesStableIdentifierAndCozyCopy() async throws {
        optIn()
        let fire = date(2026, 11, 23, 15, 30)
        let outcome = await scheduler.scheduleCompanionWaiting(companionName: "Cinder", cornerName: "榕樹巷口", at: fire)
        XCTAssertEqual(outcome, .scheduled(fire))
        let request = try XCTUnwrap(center.pending["pawprintdays.gentle.companionWaiting"])
        XCTAssertEqual(request.content.title, "巷口有人在等你")
        XCTAssertTrue(request.content.body.contains("Cinder"))
        XCTAssertTrue(request.content.body.contains("榕樹巷口"))
        XCTAssertEqual(request.content.interruptionLevel, .passive)
        XCTAssertEqual(request.content.userInfo[GentleNotificationScheduler.kindUserInfoKey] as? String, "companionWaiting")
        let parts = try XCTUnwrap(triggerComponents(.companionWaiting))
        XCTAssertEqual(parts.hour, 15)
        XCTAssertEqual(parts.minute, 30)
        XCTAssertEqual((request.trigger as? UNCalendarNotificationTrigger)?.repeats, false)
    }

    func testCopyFallsBackGracefullyWithoutNames() {
        let waiting = GentleNotificationCopy.companionWaiting(companionName: "  ", cornerName: nil)
        XCTAssertTrue(waiting.body.contains("一位毛孩朋友"))
        XCTAssertTrue(waiting.body.contains("附近的巷口"))
        let lonely = GentleNotificationCopy.strollRecap(steps: 1200, friendsMet: 0)
        XCTAssertTrue(lonely.body.contains("1200"))
        XCTAssertFalse(lonely.body.contains("位朋友"))
        let social = GentleNotificationCopy.strollRecap(steps: 1200, friendsMet: 2)
        XCTAssertTrue(social.body.contains("2 位朋友"))
        XCTAssertTrue(GentleNotificationCopy.mentorshipReady(mentorName: nil, apprenticeName: nil).body.contains("前輩"))
    }

    func testReschedulingReplacesInsteadOfDuplicating() async throws {
        optIn()
        _ = await scheduler.scheduleCompanionWaiting(companionName: "Cinder", cornerName: nil, at: date(2026, 11, 23, 15))
        _ = await scheduler.scheduleCompanionWaiting(companionName: "Mochi", cornerName: nil, at: date(2026, 11, 23, 16))
        _ = await scheduler.scheduleCompanionWaiting(companionName: "Biscuit", cornerName: nil, at: date(2026, 11, 23, 17))
        XCTAssertEqual(center.pending.count, 1)
        XCTAssertTrue(try XCTUnwrap(center.pending["pawprintdays.gentle.companionWaiting"]).content.body.contains("Biscuit"))
        // Same kind re-planned three times must not eat the daily budget.
        let recap = await scheduler.scheduleStrollRecap(steps: 10, friendsMet: 0)
        XCTAssertEqual(recap, .scheduled(clock.addingTimeInterval(15 * 60)))
    }

    func testStrollRecapDefaultsToFifteenMinutesLater() async {
        optIn()
        let outcome = await scheduler.scheduleStrollRecap(steps: 4200, friendsMet: 1)
        XCTAssertEqual(outcome, .scheduled(date(2026, 11, 23, 10, 15)))
    }

    // MARK: Quiet hours

    func testQuietHoursContainsWrapsAcrossMidnight() {
        let quiet = GentleQuietHours.default
        XCTAssertTrue(quiet.contains(date(2026, 11, 23, 22, 0), calendar: calendar))
        XCTAssertTrue(quiet.contains(date(2026, 11, 24, 0, 30), calendar: calendar))
        XCTAssertTrue(quiet.contains(date(2026, 11, 24, 7, 59), calendar: calendar))
        XCTAssertFalse(quiet.contains(date(2026, 11, 24, 8, 0), calendar: calendar))
        XCTAssertFalse(quiet.contains(date(2026, 11, 23, 21, 59), calendar: calendar))
        XCTAssertFalse(GentleQuietHours(startMinute: 0, endMinute: 0).contains(date(2026, 11, 23, 3), calendar: calendar))
        XCTAssertEqual(quiet.nextEnd(after: date(2026, 11, 23, 23, 0), calendar: calendar), date(2026, 11, 24, 8, 0))
        XCTAssertEqual(quiet.nextEnd(after: date(2026, 11, 24, 6, 0), calendar: calendar), date(2026, 11, 24, 8, 0))
    }

    func testTimeSensitiveKindsAreDroppedDuringQuietHours() async {
        optIn()
        let corner = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 23, 0))
        XCTAssertEqual(corner, .skipped(.quietHours))
        clock = date(2026, 11, 23, 21, 50)
        let recap = await scheduler.scheduleStrollRecap(steps: 100, friendsMet: 0) // lands at 22:05
        XCTAssertEqual(recap, .skipped(.quietHours))
        XCTAssertTrue(center.pending.isEmpty)
    }

    func testMentorshipLessonDefersToEndOfQuietHours() async throws {
        optIn()
        let outcome = await scheduler.scheduleMentorshipReady(mentorName: "Cinder", apprenticeName: "Mochi", at: date(2026, 11, 23, 23, 15))
        XCTAssertEqual(outcome, .scheduled(date(2026, 11, 24, 8, 0)))
        let parts = try XCTUnwrap(triggerComponents(.mentorshipReady))
        XCTAssertEqual(parts.day, 24)
        XCTAssertEqual(parts.hour, 8)
    }

    func testCustomQuietHoursAreRespected() async {
        var prefs = GentleNotificationPreferences()
        prefs.isEnabled = true
        prefs.quietHours = GentleQuietHours(startMinute: 13 * 60, endMinute: 14 * 60)
        scheduler.preferences = prefs
        let blocked = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 13, 30))
        XCTAssertEqual(blocked, .skipped(.quietHours))
        let allowed = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 22, 30))
        XCTAssertEqual(allowed, .scheduled(date(2026, 11, 23, 22, 30)))
    }

    func testPastDatesAreSkipped() async {
        optIn()
        let outcome = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 9, 0))
        XCTAssertEqual(outcome, .skipped(.dateInPast))
    }

    // MARK: Daily limit

    func testAtMostTwoNotificationsPerDay() async {
        optIn()
        let a = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 12))
        let b = await scheduler.scheduleMentorshipReady(mentorName: nil, apprenticeName: nil, at: date(2026, 11, 23, 14))
        let c = await scheduler.scheduleStrollRecap(steps: 10, friendsMet: 0) // 10:15 same day
        XCTAssertEqual(a, .scheduled(date(2026, 11, 23, 12)))
        XCTAssertEqual(b, .scheduled(date(2026, 11, 23, 14)))
        XCTAssertEqual(c, .skipped(.dailyLimitReached))
        XCTAssertEqual(center.pending.count, 2)
        // Next day has a fresh budget.
        let d = await scheduler.scheduleStrollRecap(steps: 10, friendsMet: 0, after: 24 * 3600)
        XCTAssertEqual(d, .scheduled(date(2026, 11, 24, 10, 0)))
    }

    func testEnabledDiaryReminderReservesOneSlotPerDay() async {
        optIn(diary: true)
        let first = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 12))
        let second = await scheduler.scheduleMentorshipReady(mentorName: nil, apprenticeName: nil, at: date(2026, 11, 23, 14))
        XCTAssertEqual(first, .scheduled(date(2026, 11, 23, 12)))
        XCTAssertEqual(second, .skipped(.dailyLimitReached))
    }

    func testCancelFreesDailyBudget() async {
        optIn()
        _ = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 12))
        _ = await scheduler.scheduleMentorshipReady(mentorName: nil, apprenticeName: nil, at: date(2026, 11, 23, 14))
        scheduler.cancel(.companionWaiting)
        XCTAssertNil(center.pending["pawprintdays.gentle.companionWaiting"])
        let recap = await scheduler.scheduleStrollRecap(steps: 10, friendsMet: 0)
        XCTAssertEqual(recap, .scheduled(date(2026, 11, 23, 10, 15)))
    }

    func testPastDaysAreForgottenFromTheLedger() async {
        optIn()
        _ = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 12))
        _ = await scheduler.scheduleMentorshipReady(mentorName: nil, apprenticeName: nil, at: date(2026, 11, 23, 14))
        clock = date(2026, 11, 24, 9, 0)
        let outcome = await scheduler.scheduleStrollRecap(steps: 10, friendsMet: 0)
        XCTAssertEqual(outcome, .scheduled(date(2026, 11, 24, 9, 15)))
    }

    func testFailedAddDoesNotConsumeBudget() async {
        optIn()
        center.failNextAdd = true
        let failed = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 12))
        XCTAssertEqual(failed, .skipped(.failed))
        let a = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 12))
        let b = await scheduler.scheduleMentorshipReady(mentorName: nil, apprenticeName: nil, at: date(2026, 11, 23, 13))
        XCTAssertEqual(a, .scheduled(date(2026, 11, 23, 12)))
        XCTAssertEqual(b, .scheduled(date(2026, 11, 23, 13)))
    }

    // MARK: Evening diary

    func testEveningDiaryRepeatsDailyAt2030ByDefault() async throws {
        optIn(diary: true)
        let outcome = await scheduler.scheduleEveningDiary()
        XCTAssertEqual(outcome, .scheduled(date(2026, 11, 23, 20, 30)))
        let request = try XCTUnwrap(center.pending["pawprintdays.gentle.eveningDiary"])
        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        XCTAssertTrue(trigger.repeats)
        XCTAssertEqual(trigger.dateComponents.hour, 20)
        XCTAssertEqual(trigger.dateComponents.minute, 30)
        XCTAssertNil(trigger.dateComponents.day)
        XCTAssertEqual(request.content.title, "今晚的日記還空著")
    }

    func testEveningDiaryAfterTodaysTimeSchedulesTomorrow() async {
        optIn(diary: true)
        clock = date(2026, 11, 23, 21, 0)
        let outcome = await scheduler.scheduleEveningDiary()
        XCTAssertEqual(outcome, .scheduled(date(2026, 11, 24, 20, 30)))
    }

    func testEveningDiaryInsideQuietHoursMovesToQuietEnd() async throws {
        var prefs = GentleNotificationPreferences()
        prefs.isEnabled = true
        prefs.eveningDiaryMinuteOfDay = 23 * 60
        scheduler.preferences = prefs
        _ = await scheduler.scheduleEveningDiary()
        let parts = try XCTUnwrap(triggerComponents(.eveningDiary))
        XCTAssertEqual(parts.hour, 8)
        XCTAssertEqual(parts.minute, 0)
    }

    func testEveningDiaryRespectsOptInAndReschedulesOnce() async {
        let before = await scheduler.scheduleEveningDiary()
        XCTAssertEqual(before, .skipped(.optedOut))
        optIn(diary: true)
        _ = await scheduler.scheduleEveningDiary()
        _ = await scheduler.scheduleEveningDiary()
        XCTAssertEqual(center.pending.count, 1)
    }

    // MARK: Preferences

    func testPreferencesPersistAndRoundTrip() {
        var prefs = GentleNotificationPreferences()
        prefs.isEnabled = true
        prefs.mentorshipReadyEnabled = false
        prefs.eveningDiaryMinuteOfDay = 21 * 60
        prefs.quietHours = GentleQuietHours(startMinute: 23 * 60, endMinute: 7 * 60)
        scheduler.preferences = prefs
        let reloaded = GentleNotificationScheduler(center: center, defaults: defaults, calendar: calendar, now: { Date() })
        XCTAssertEqual(reloaded.preferences, prefs)
        XCTAssertFalse(reloaded.preferences.isEnabled(.mentorshipReady))
        XCTAssertTrue(reloaded.preferences.isEnabled(.strollRecap))
    }

    func testApplyingPreferencesCancelsDisabledKindsAndSchedulesDiary() async {
        optIn()
        _ = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 12))
        _ = await scheduler.scheduleMentorshipReady(mentorName: nil, apprenticeName: nil, at: date(2026, 11, 23, 14))
        var next = scheduler.preferences
        next.companionWaitingEnabled = false
        next.eveningDiaryEnabled = true
        await scheduler.apply(next)
        XCTAssertNil(center.pending["pawprintdays.gentle.companionWaiting"])
        XCTAssertNotNil(center.pending["pawprintdays.gentle.mentorshipReady"])
        XCTAssertNotNil(center.pending["pawprintdays.gentle.eveningDiary"])
    }

    func testEnablingDiaryTrimsDaysThatWouldExceedTheLimit() async {
        optIn()
        _ = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 12))
        _ = await scheduler.scheduleMentorshipReady(mentorName: nil, apprenticeName: nil, at: date(2026, 11, 23, 14))
        var next = scheduler.preferences
        next.eveningDiaryEnabled = true
        await scheduler.apply(next)
        XCTAssertNotNil(center.pending["pawprintdays.gentle.companionWaiting"])
        XCTAssertNil(center.pending["pawprintdays.gentle.mentorshipReady"], "latest one-shot is trimmed so the day stays at 2")
        XCTAssertNotNil(center.pending["pawprintdays.gentle.eveningDiary"])
    }

    func testTurningMasterSwitchOffClearsEverything() async {
        optIn(diary: true)
        _ = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 12))
        _ = await scheduler.scheduleEveningDiary()
        var off = scheduler.preferences
        off.isEnabled = false
        await scheduler.apply(off)
        XCTAssertTrue(center.pending.isEmpty)
    }

    func testCancelAllRemovesEveryGentleRequest() async {
        optIn(diary: true)
        _ = await scheduler.scheduleCompanionWaiting(companionName: nil, cornerName: nil, at: date(2026, 11, 23, 12))
        _ = await scheduler.scheduleEveningDiary()
        scheduler.cancelAll()
        XCTAssertTrue(center.pending.isEmpty)
    }
}
