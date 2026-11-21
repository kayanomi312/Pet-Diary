import XCTest
import SwiftData
import CoreLocation
@testable import PawprintDays

@MainActor
final class Stage1VerificationTests: XCTestCase {

    private func makeInMemoryCoordinator() throws -> GameCoordinator {
        let schema = Schema([
            DiaryDayRecord.self,
            AnchorSiteRecord.self,
            EncounterLog.self,
            PetResidentState.self,
            HomeSpotPlacement.self,
            TeachingIntention.self,
            WalletAndCurioLedger.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return GameCoordinator(modelContext: container.mainContext, modelContainer: container)
    }

    /// End-to-end Stage 1 14-day deterministic verification covering all 4 opening-prompt gates.
    func testStage1FourteenDayDeterministicFixturePassesAllFourGates() throws {
        let coordinator = try makeInMemoryCoordinator()
        let report = coordinator.runStage1Deterministic14DayFixture()

        XCTAssertTrue(report.gate1ProximityAndDay3CallbackPassed, "Gate 1 failed: \(report.details)")
        XCTAssertTrue(report.gate2ImmutableSnapshotPassed, "Gate 2 failed: \(report.details)")
        XCTAssertTrue(report.gate3DisjointCoinLedgerPassed, "Gate 3 failed: \(report.details)")
        XCTAssertTrue(report.gate4SingleDayErasurePassed, "Gate 4 failed: \(report.details)")
        XCTAssertTrue(report.allPassed, "Overall Stage 1 fixture failed: \(report.details)")
    }

    /// Anti-reroll persistence & zero absence decay across a 30-day gap.
    func testAntiRerollPersistenceAndZeroAbsenceDecay() throws {
        let coordinator = try makeInMemoryCoordinator()
        let bakery = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.bakery_corner" }))

        // Advance cycle to Tap 3 (index 2)
        bakery.cycleTapCount = 2
        let firstOffer = AnchorRotationEngine.resolveAndPersistOfferedPetID(
            anchor: bakery,
            residents: coordinator.residents,
            ledger: coordinator.ledger
        )
        XCTAssertEqual(firstOffer, "pet.03", "Pilot Guarantee must offer Cinder on first Tap-3")
        XCTAssertEqual(bakery.cachedVisitorOfferID, "pet.03")

        // Closing and reloading must return the exact persisted animal without rerolling
        let secondOffer = AnchorRotationEngine.resolveAndPersistOfferedPetID(
            anchor: bakery,
            residents: coordinator.residents,
            ledger: coordinator.ledger
        )
        XCTAssertEqual(secondOffer, firstOffer)

        // 30 calendar days of absence never consumes a turn or decays bond
        let sesame = try XCTUnwrap(coordinator.resident(for: "pet.01"))
        sesame.sharedDaysCount = 5
        sesame.milestoneTier = PetResidentState.milestoneForSharedDays(5)
        coordinator.advanceSimulatedDays(30)
        XCTAssertEqual(bakery.cycleTapCount, 2, "Calendar absence must never consume rotation turns")
        XCTAssertEqual(sesame.sharedDaysCount, 5, "Absence must never decay bond")
    }

    /// Downward sensor revisions keep raw correction visible and forgive previously issued coins.
    func testDisjointStepLedgerDownwardRevisionForgiveness() throws {
        let coordinator = try makeInMemoryCoordinator()
        let t0 = Date(timeIntervalSince1970: 1_795_000_200)

        let first = coordinator.ingestSteps(steps: 450, intervalStartUTC: t0, placeLabel: "Bakery Corner")
        XCTAssertEqual(first.coinsAwarded, 2)
        XCTAssertEqual(coordinator.ledger.coinBalance, 2)
        XCTAssertEqual(coordinator.ledger.stepCarryRemainder, 50)

        // CoreMotion downward revision on the same 15-min UTC bucket: 450 -> 380
        let downward = coordinator.ingestSteps(steps: 380, intervalStartUTC: t0, placeLabel: "Bakery Corner")
        XCTAssertEqual(downward.newlyAcceptedSteps, 0)
        XCTAssertEqual(downward.coinsAwarded, 0)
        XCTAssertEqual(coordinator.ledger.coinBalance, 2, "Previously issued coins must be forgiven")

        // Revision upward only credits strictly above previous high-water (600 - 450 = 150 + 50 rem = 200 -> +1 coin)
        let upward = coordinator.ingestSteps(steps: 600, intervalStartUTC: t0, placeLabel: "Bakery Corner")
        XCTAssertEqual(upward.newlyAcceptedSteps, 150)
        XCTAssertEqual(upward.coinsAwarded, 1)
        XCTAssertEqual(coordinator.ledger.coinBalance, 3)
        XCTAssertEqual(coordinator.ledger.stepCarryRemainder, 0)
    }

    /// Qualitative Pocket Finds every 1,400 steps with 200-step anticipation glow.
    func testQualitativePocketFindAndAnticipationGlow() throws {
        let coordinator = try makeInMemoryCoordinator()
        coordinator.setWalkCompanion(petID: "pet.01")
        let base = Date(timeIntervalSince1970: 1_795_100_000)

        let r1 = coordinator.ingestSteps(steps: 1_250, intervalStartUTC: base, placeLabel: "Riverside Path")
        XCTAssertTrue(r1.isNearPocketFind, "At 1,250/1,400 steps (150 remaining <= 200), companion medallion must glow")
        XCTAssertTrue(r1.newCuriosForaged.isEmpty)

        let r2 = coordinator.ingestSteps(steps: 200, intervalStartUTC: base.addingTimeInterval(900), placeLabel: "Riverside Path")
        XCTAssertEqual(r2.newCuriosForaged.count, 1, "Crossing 1,400 steps must forage 1 qualitative curio")
        XCTAssertEqual(coordinator.ledger.pocketFindStepProgress, 50)
    }

    /// Personal Familiar Corners cap at 3 on-device corners and Room Solver pairs Sesame + Cinder on Wool Blanket.
    func testFamiliarCornersCapAndEmergentRoomPairing() throws {
        let coordinator = try makeInMemoryCoordinator()

        XCTAssertNotNil(coordinator.pinFamiliarCornerAhead(label: "Corner 1"))
        XCTAssertNotNil(coordinator.pinFamiliarCornerAhead(label: "Corner 2"))
        XCTAssertNotNil(coordinator.pinFamiliarCornerAhead(label: "Corner 3"))
        XCTAssertNil(coordinator.pinFamiliarCornerAhead(label: "Corner 4"), "Max 3 Personal Familiar Corners")

        let sesame = try XCTUnwrap(coordinator.resident(for: "pet.01"))
        let cinder = try XCTUnwrap(coordinator.resident(for: "pet.03"))
        sesame.inviteState = .invitedHome
        cinder.inviteState = .invitedHome

        coordinator.activeWeather = .postRain
        coordinator.solveHomeRoomNow()

        let allOccupants = coordinator.homeSpots.flatMap(\.currentOccupantPetIDs)
        XCTAssertTrue(allOccupants.contains("pet.01"))
        XCTAssertTrue(allOccupants.contains("pet.03"))
    }

    /// Timezone hygiene: grouping by local civil day across different timezones.
    func testLocalCivilDayTimezoneHygiene() throws {
        // 2026-11-21 02:30 UTC is Nov 21 in Taipei (+8) and Nov 20 in Los Angeles (-8)
        let utcDate = Date(timeIntervalSince1970: 1_795_228_200) // Verify exact civil day split
        let taipei = try XCTUnwrap(TimeZone(identifier: "Asia/Taipei"))
        let la = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))

        let taipeiISO = CivilCalendarHelper.localDateISO(for: utcDate, timeZone: taipei)
        let laISO = CivilCalendarHelper.localDateISO(for: utcDate, timeZone: la)
        XCTAssertNotEqual(taipeiISO, laISO, "Civil date must follow local timezone cleanly")
    }
}
