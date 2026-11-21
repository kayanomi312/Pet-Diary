import XCTest
import SwiftData
import CoreLocation
import UIKit
@testable import PawprintDays

@MainActor
final class Stage2To4VerificationTests: XCTestCase {

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

    /// Verifies the full 8-pet launch cast, Tap-22 familiar-cast progression, and interrupted encounter recovery (no double-claim).
    func testFull8PetCastTap22AndInterruptedRecovery() throws {
        let coordinator = try makeInMemoryCoordinator()
        XCTAssertEqual(coordinator.residents.count, 8, "Full launch cast must include all 8 pets")
        XCTAssertEqual(coordinator.homeSpots.count, 5, "Starter sunroom must have 5 interactive spots")

        let bakery = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.bakery_corner" }))
        let nearBakery = AnchorRotationEngine.coordinateAhead(
            from: CLLocationCoordinate2D(latitude: bakery.lat, longitude: bakery.lon),
            meters: 10,
            bearingDegrees: 0
        )
        coordinator.locationService.walkSimulated(to: nearBakery)

        var seenPetIDs = Set<String>()
        for dayOffset in 0..<22 {
            if dayOffset > 0 { coordinator.advanceSimulatedDays(1) }
            let offered = AnchorRotationEngine.resolveAndPersistOfferedPetID(
                anchor: bakery,
                residents: coordinator.residents,
                ledger: coordinator.ledger
            )
            // Simulate interrupted encounter reload before commit: offer MUST remain identical
            let reloadedOffer = AnchorRotationEngine.resolveAndPersistOfferedPetID(
                anchor: bakery,
                residents: coordinator.residents,
                ledger: coordinator.ledger
            )
            XCTAssertEqual(offered, reloadedOffer, "Interrupted encounter must reopen cleanly with same pet")

            let log1 = coordinator.commitStreetEncounter(siteID: bakery.siteID, petID: offered, gesture: .offerHand)
            let log2 = coordinator.commitStreetEncounter(siteID: bakery.siteID, petID: offered, gesture: .offerHand)
            XCTAssertEqual(log1?.encounterUUID, log2?.encounterUUID, "Site-day deduplication must prevent double-claiming")
            seenPetIDs.insert(offered)
        }

        XCTAssertGreaterThanOrEqual(seenPetIDs.count, 6, "Tap-22 should organically introduce the neighborhood cast")
        XCTAssertTrue(seenPetIDs.contains("pet.01"))
        XCTAssertTrue(seenPetIDs.contains("pet.03"), "Pilot Tap-3 guarantee must deliver Cinder")
    }

    /// Verifies Multi-Paw Stroll Chains (Amber Gold Halo) -> Dual-Pet Street Scene + two-animal baked postcard.
    func testStrollChainAndDualPetStreetPostcard() throws {
        let coordinator = try makeInMemoryCoordinator()
        let bakery = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.bakery_corner" }))
        let riverside = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.riverside_bench" }))

        let firstLog = try XCTUnwrap(
            coordinator.commitStreetEncounter(
                siteID: bakery.siteID,
                petID: "pet.01",
                gesture: .offerHand,
                forceOfferStrollChain: true
            )
        )
        let targetID = try XCTUnwrap(firstLog.strollChainTargetSiteID)
        let targetAnchor = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == targetID }))
        XCTAssertEqual(coordinator.pawState(for: targetAnchor), .strollChain, "Target paw must glow Amber Gold")

        // Walk to Stroll Chain target & greet -> Dual-Pet Street Scene
        let nearTarget = AnchorRotationEngine.coordinateAhead(
            from: CLLocationCoordinate2D(latitude: targetAnchor.lat, longitude: targetAnchor.lon),
            meters: 8,
            bearingDegrees: 0
        )
        coordinator.locationService.walkSimulated(to: nearTarget)
        _ = coordinator.attemptOpenAnchor(targetAnchor)

        let dualLog = try XCTUnwrap(
            coordinator.commitStreetEncounter(
                siteID: targetAnchor.siteID,
                petID: targetAnchor.regularPetID,
                companionStreetPetID: "pet.01",
                gesture: .rollBall
            )
        )
        XCTAssertEqual(dualLog.secondaryPetID, "pet.01")
        XCTAssertNotNil(dualLog.bakedSnapshotPNGData)
        XCTAssertNil(coordinator.activeStrollChainTargetID, "Chain halo clears once followed")
        _ = riverside
    }

    /// Verifies Shared-Prop Cross-Species Mentorship: queued -> 2,500 Walk Nourishment steps -> demonstrated -> mastered.
    func testSharedPropCrossSpeciesMentorshipLifecycle() throws {
        let coordinator = try makeInMemoryCoordinator()
        let sesame = try XCTUnwrap(coordinator.resident(for: "pet.01"))
        let cinder = try XCTUnwrap(coordinator.resident(for: "pet.03"))
        sesame.inviteState = .invitedHome
        cinder.inviteState = .invitedHome
        sesame.sharedDaysCount = 15
        cinder.sharedDaysCount = 3

        let intention = try XCTUnwrap(coordinator.planMentorship(mentorID: "pet.01", learnerID: "pet.03"))
        XCTAssertEqual(intention.state, .queued)

        // Walk 2,500 steps to advance via Walk Nourishment without forcing a 24h wait
        _ = coordinator.ingestSteps(steps: 2_500, intervalStartUTC: Date(), placeLabel: "Canal Walk")
        XCTAssertEqual(intention.state, .demonstrated)

        coordinator.completeMentorshipLesson(intentionUUID: intention.intentionUUID)
        XCTAssertEqual(intention.state, .mastered)
        XCTAssertTrue(cinder.learnedHabitIDs.contains(HabitFamily.wait.rawValue))
        XCTAssertTrue(cinder.learnedHabitCredits.contains(where: { $0.contains("芝麻") }))
    }

    /// Verifies 2-State Loved Patina (25 uses) + 10c Patch Mending + Rain-Porch Veranda (5 -> 8 spots).
    func testLovedPatinaPatchMendingAndVerandaExpansion() throws {
        let coordinator = try makeInMemoryCoordinator()
        coordinator.ledger.coinBalance = 700

        let spot1 = try XCTUnwrap(coordinator.homeSpots.first(where: { $0.spotIndex == 1 }))
        spot1.goodieUseCount = 25
        XCTAssertTrue(spot1.hasLovedPatina)

        XCTAssertTrue(coordinator.mendGoodiePatch(spotIndex: 1, txID: "test.patch.1"))
        XCTAssertTrue(spot1.hasStitchedPatch)
        XCTAssertEqual(coordinator.ledger.coinBalance, 690)

        // Idempotent replay does not double-charge
        XCTAssertTrue(coordinator.mendGoodiePatch(spotIndex: 1, txID: "test.patch.1"))
        XCTAssertEqual(coordinator.ledger.coinBalance, 690)

        let veranda = try XCTUnwrap(ShopCatalog.item(id: "room.rain_veranda"))
        XCTAssertTrue(coordinator.purchaseItem(veranda, txID: "test.veranda"))
        XCTAssertTrue(coordinator.ledger.verandaUnlocked)
        XCTAssertEqual(coordinator.homeSpots.count, 8, "Veranda must expand Home from 5 to 8 spots")
    }

    /// Verifies 'Carry Regulars Forward' relocation guarantee when moving to a brand-new city.
    func testCarryRegularsForwardRelocationGuarantee() throws {
        let coordinator = try makeInMemoryCoordinator()
        let sesame = try XCTUnwrap(coordinator.resident(for: "pet.01"))
        let reed = try XCTUnwrap(coordinator.resident(for: "pet.08"))
        sesame.inviteState = .invitedHome
        sesame.sharedDaysCount = 12
        reed.inviteState = .invitedHome
        reed.sharedDaysCount = 8

        let tokyoCenter = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        let newCityAnchors = [
            DiscoveredWalkableAnchor(siteID: "sys.poi.tokyo_bakery", label: "Kissa Bakery", latitude: 35.6765, longitude: 139.6506),
            DiscoveredWalkableAnchor(siteID: "sys.poi.tokyo_park", label: "Pocket Park", latitude: 35.6775, longitude: 139.6512)
        ]
        coordinator.applyDiscoveredAnchors(newCityAnchors, around: tokyoCenter)

        let newBakery = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.poi.tokyo_bakery" }))
        let newPark = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.poi.tokyo_park" }))
        XCTAssertEqual(newBakery.regularPetID, "pet.01", "Most-bonded regular Sesame carries forward first")
        XCTAssertEqual(newPark.regularPetID, "pet.08", "Second bonded regular Reed carries forward")
    }

    /// Verifies Mobility-Aid Distance & Time Roll Mode + Bus (>12 km/h) Speed Filter.
    func testMobilityRollModeAndBusSpeedFilter() throws {
        let coordinator = try makeInMemoryCoordinator()
        coordinator.setWalkCompanion(petID: "pet.08")
        coordinator.toggleMobilityRollMode(true)

        // 130m low-speed travel + 120s outdoor dwell = 2 units = 400 equivalent steps = 2 Coins
        let res = coordinator.recordMobilityRollMovement(lowSpeedMeters: 130, dwellSeconds: 120)
        XCTAssertEqual(res.newlyAcceptedSteps, 400)
        XCTAssertEqual(res.coinsAwarded, 2)
        XCTAssertEqual(coordinator.ledger.coinBalance, 2)

        // Bus speed (> 12 km/h = 3.33 m/s) must reject street paw tap
        let bakery = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.bakery_corner" }))
        let fastBusLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: bakery.lat, longitude: bakery.lon),
            altitude: 10,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 5.5, // ~20 km/h
            timestamp: Date()
        )
        let speedCheck = AnchorRotationEngine.evaluateProximity(
            anchor: bakery,
            userLocation: fastBusLocation,
            now: Date(),
            currentLocalDateISO: coordinator.currentLocalDateISO
        )
        XCTAssertEqual(speedCheck, .movingTooFast)
    }

    /// Verifies Picnic Portion dual-pet Home snapshot & Wide Charcoal Watercolor Spread (Sketchbook Pack).
    func testPicnicSnapshotAndWideCharcoalSpread() throws {
        let coordinator = try makeInMemoryCoordinator()
        coordinator.ledger.coinBalance = 100
        coordinator.resident(for: "pet.01")?.inviteState = .invitedHome
        coordinator.resident(for: "pet.05")?.inviteState = .invitedHome

        let picnic = try XCTUnwrap(ShopCatalog.item(id: "treat.picnic_portion"))
        XCTAssertTrue(coordinator.purchaseItem(picnic, txID: "test.picnic"))
        let picnicLog = coordinator.encounters.first(where: { $0.siteDisplayLabel == "陽光室茶點盤" })
        XCTAssertNotNil(picnicLog?.secondaryPetID)
        XCTAssertNotNil(picnicLog?.bakedSnapshotPNGData)

        let pack = try XCTUnwrap(ShopCatalog.item(id: "outing.sketchbook_pack"))
        XCTAssertTrue(coordinator.purchaseItem(pack, txID: "test.sketch_pack"))
        XCTAssertEqual(coordinator.ledger.activeOutingPack, .sketchbookCharcoal)

        let bakery = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.bakery_corner" }))
        let wideLog = try XCTUnwrap(coordinator.commitStreetEncounter(siteID: bakery.siteID, petID: "pet.01", gesture: .offerHand))
        XCTAssertTrue(wideLog.isWideWatercolorSpread)
        if let data = wideLog.bakedSnapshotPNGData, let img = UIImage(data: data) {
            XCTAssertGreaterThan(img.size.width, 320, "Wide charcoal spread must render wider than standard 300pt postcard")
        } else {
            XCTFail("Expected baked PNG image for wide watercolor spread")
        }
    }

    /// Verifies Frequent Neighborhood Walker depth: Quiet Revisit (zero double-claiming), Corner Familiarity, and 3-Corner Loop Stamp.
    func testFrequentWalkerQuietRevisitFamiliarityAndLoopStamp() throws {
        let coordinator = try makeInMemoryCoordinator()
        let bakery = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.bakery_corner" }))
        let river = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.riverside_bench" }))
        let library = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.library_arcade" }))

        // Visit all 3 distinct neighborhood corners in one day -> awards Neighborhood Loop Stamp
        _ = coordinator.commitStreetEncounter(siteID: bakery.siteID, petID: "pet.01", gesture: .offerHand)
        _ = coordinator.commitStreetEncounter(siteID: river.siteID, petID: "pet.05", gesture: .rollBall)
        _ = coordinator.commitStreetEncounter(siteID: library.siteID, petID: "pet.02", gesture: .crouchQuietly)

        let today = coordinator.todayDiaryRecord()
        XCTAssertTrue(today.completedNeighborhoodLoop, "Visiting 3 distinct corners in one day must stamp Neighborhood Loop")
        XCTAssertEqual(bakery.totalVisitsCount, 1)

        // Quiet Revisit on same day must NOT double-claim Shared Days, while recording a calm revisit note
        let sharedBefore = coordinator.resident(for: "pet.01")?.sharedDaysCount ?? 0
        bakery.totalVisitsCount = 3 // 常去轉角
        XCTAssertEqual(bakery.familiarityTitle, "常去轉角")
        let moment = coordinator.performQuietRevisit(anchor: bakery)
        XCTAssertFalse(moment.vignetteLine.isEmpty)
        XCTAssertEqual(coordinator.resident(for: "pet.01")?.sharedDaysCount, sharedBefore, "Quiet revisit must never double-claim Shared Days")
        XCTAssertFalse(coordinator.todayDiaryRecord().revisitNotes.isEmpty)
    }

    /// Verifies Milestone 4 (Day 10) Kindred 2-Choice Habit Practice & Merging Adjacent Stop Detections.
    func testKindredTwoChoicePracticeAndMergeAdjacentAnchors() throws {
        let coordinator = try makeInMemoryCoordinator()
        let sesame = try XCTUnwrap(coordinator.resident(for: "pet.01"))
        sesame.sharedDaysCount = 10
        sesame.milestoneTier = PetResidentState.milestoneForSharedDays(10)

        coordinator.completeKindredHabitPractice(petID: "pet.01", choiceTitle: "放慢節奏靜靜示範")
        XCTAssertTrue(sesame.kindredPracticeCompleted)
        XCTAssertTrue(sesame.kindredChoiceNote?.contains("沉靜守候") == true)

        let bakery = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.bakery_corner" }))
        let pinned = try XCTUnwrap(coordinator.pinFamiliarCornerAhead(label: "相鄰轉角"))
        bakery.totalVisitsCount = 4
        pinned.totalVisitsCount = 2

        coordinator.mergeAnchor(sourceSiteID: pinned.siteID, intoTargetSiteID: bakery.siteID)
        XCTAssertTrue(pinned.isHiddenByUser)
        XCTAssertEqual(bakery.totalVisitsCount, 6)
    }
}
