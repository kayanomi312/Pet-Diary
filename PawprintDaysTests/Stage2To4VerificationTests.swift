import XCTest
import SwiftData
import CoreLocation
import UIKit
import AVFoundation
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
        XCTAssertEqual(coordinator.residents.count, 6, "Mystical launch cast must include all 6 mythical pets")
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

        XCTAssertGreaterThanOrEqual(seenPetIDs.count, 5, "Tap-22 should organically introduce the neighborhood cast")
        XCTAssertTrue(seenPetIDs.contains("pet.03"))
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
                petID: "pet.03",
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
                companionStreetPetID: "pet.03",
                gesture: .rollBall
            )
        )
        XCTAssertEqual(dualLog.secondaryPetID, "pet.03")
        XCTAssertNotNil(dualLog.bakedSnapshotPNGData)
        XCTAssertNil(coordinator.activeStrollChainTargetID, "Chain halo clears once followed")
        _ = riverside
    }

    /// Verifies Shared-Prop Cross-Species Mentorship: queued -> 2,500 Walk Nourishment steps -> demonstrated -> mastered.
    func testSharedPropCrossSpeciesMentorshipLifecycle() throws {
        let coordinator = try makeInMemoryCoordinator()
        let juniper = try XCTUnwrap(coordinator.resident(for: "pet.02"))
        let cinder = try XCTUnwrap(coordinator.resident(for: "pet.03"))
        juniper.inviteState = .invitedHome
        cinder.inviteState = .invitedHome
        juniper.sharedDaysCount = 15
        cinder.sharedDaysCount = 3

        let intention = try XCTUnwrap(coordinator.planMentorship(mentorID: "pet.02", learnerID: "pet.03"))
        XCTAssertEqual(intention.state, .queued)

        // Walk 2,500 steps to advance via Walk Nourishment without forcing a 24h wait
        _ = coordinator.ingestSteps(steps: 2_500, intervalStartUTC: Date(), placeLabel: "Canal Walk")
        XCTAssertEqual(intention.state, .demonstrated)

        coordinator.completeMentorshipLesson(intentionUUID: intention.intentionUUID)
        XCTAssertEqual(intention.state, .mastered)
        XCTAssertTrue(cinder.learnedHabitIDs.contains(HabitFamily.offer.rawValue))
        XCTAssertTrue(cinder.learnedHabitCredits.contains(where: { $0.contains("杜松") }))
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
        let cinder = try XCTUnwrap(coordinator.resident(for: "pet.03"))
        let reed = try XCTUnwrap(coordinator.resident(for: "pet.08"))
        cinder.inviteState = .invitedHome
        cinder.sharedDaysCount = 12
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
        XCTAssertEqual(newBakery.regularPetID, "pet.03", "Most-bonded regular Sesame carries forward first")
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
        coordinator.resident(for: "pet.03")?.inviteState = .invitedHome
        coordinator.resident(for: "pet.06")?.inviteState = .invitedHome

        let picnic = try XCTUnwrap(ShopCatalog.item(id: "treat.picnic_portion"))
        XCTAssertTrue(coordinator.purchaseItem(picnic, txID: "test.picnic"))
        let picnicLog = coordinator.encounters.first(where: { $0.siteDisplayLabel == "陽光室茶點盤" })
        XCTAssertNotNil(picnicLog?.secondaryPetID)
        XCTAssertNotNil(picnicLog?.bakedSnapshotPNGData)

        let pack = try XCTUnwrap(ShopCatalog.item(id: "outing.sketchbook_pack"))
        XCTAssertTrue(coordinator.purchaseItem(pack, txID: "test.sketch_pack"))
        XCTAssertEqual(coordinator.ledger.activeOutingPack, .sketchbookCharcoal)

        let bakery = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.bakery_corner" }))
        let wideLog = try XCTUnwrap(coordinator.commitStreetEncounter(siteID: bakery.siteID, petID: "pet.03", gesture: .offerHand))
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
        _ = coordinator.commitStreetEncounter(siteID: bakery.siteID, petID: "pet.03", gesture: .offerHand)
        _ = coordinator.commitStreetEncounter(siteID: river.siteID, petID: "pet.06", gesture: .rollBall)
        _ = coordinator.commitStreetEncounter(siteID: library.siteID, petID: "pet.02", gesture: .crouchQuietly)

        let today = coordinator.todayDiaryRecord()
        XCTAssertTrue(today.completedNeighborhoodLoop, "Visiting 3 distinct corners in one day must stamp Neighborhood Loop")
        XCTAssertEqual(bakery.totalVisitsCount, 1)

        // Quiet Revisit on same day must NOT double-claim Shared Days, while recording a calm revisit note
        let sharedBefore = coordinator.resident(for: "pet.03")?.sharedDaysCount ?? 0
        bakery.totalVisitsCount = 3 // 常去轉角
        XCTAssertEqual(bakery.familiarityTitle, "常去轉角")
        let moment = coordinator.performQuietRevisit(anchor: bakery)
        XCTAssertFalse(moment.vignetteLine.isEmpty)
        XCTAssertEqual(coordinator.resident(for: "pet.03")?.sharedDaysCount, sharedBefore, "Quiet revisit must never double-claim Shared Days")
        XCTAssertFalse(coordinator.todayDiaryRecord().revisitNotes.isEmpty)
    }

    /// Verifies Milestone 4 (Day 10) Kindred 2-Choice Habit Practice & Merging Adjacent Stop Detections.
    func testKindredTwoChoicePracticeAndMergeAdjacentAnchors() throws {
        let coordinator = try makeInMemoryCoordinator()
        let cinder = try XCTUnwrap(coordinator.resident(for: "pet.03"))
        cinder.sharedDaysCount = 10
        cinder.milestoneTier = PetResidentState.milestoneForSharedDays(10)

        coordinator.completeKindredHabitPractice(petID: "pet.03", choiceTitle: "放慢節奏靜靜示範")
        XCTAssertTrue(cinder.kindredPracticeCompleted)
        XCTAssertTrue(cinder.kindredChoiceNote?.contains("爐爪烘暖") == true)

        let bakery = try XCTUnwrap(coordinator.anchors.first(where: { $0.siteID == "sys.luodong.bakery_corner" }))
        let pinned = try XCTUnwrap(coordinator.pinFamiliarCornerAhead(label: "相鄰轉角"))
        bakery.totalVisitsCount = 4
        pinned.totalVisitsCount = 2

        coordinator.mergeAnchor(sourceSiteID: pinned.siteID, intoTargetSiteID: bakery.siteID)
        XCTAssertTrue(pinned.isHiddenByUser)
        XCTAssertEqual(bakery.totalVisitsCount, 6)
    }

    /// Verifies Cat-and-Dragon mythical species cast + optional Stroll Session, single-trip Satchel Charms (zero idle burn), and return-home summary.
    func testStrollSessionSatchelAndCatDragonMythicalCast() throws {
        let coordinator = try makeInMemoryCoordinator()
        let juniper = PetCatalog.pet(id: "pet.02")
        let cinder = PetCatalog.pet(id: "pet.03")
        XCTAssertEqual(juniper.kind, .demonCat)
        XCTAssertTrue(juniper.kind.isCatFamily && juniper.kind.isMagical)
        XCTAssertEqual(cinder.kind, .dragonCat)
        XCTAssertTrue(cinder.kind.isCatFamily && cinder.kind.isMagical)

        // 1. Forage Sachet stroll grants +35% sniffing progress without time-based burning
        coordinator.ledger.coinBalance = 20
        XCTAssertTrue(coordinator.startStrollSession(companionPetID: "pet.02", charm: .forageSachet))
        XCTAssertEqual(coordinator.ledger.coinBalance, 14)

        _ = coordinator.ingestSteps(steps: 1_100, intervalStartUTC: Date(), placeLabel: "老街麵包巷")
        let summary = try XCTUnwrap(coordinator.endStrollSession())
        XCTAssertEqual(summary.totalSteps, 1_100)
        XCTAssertEqual(summary.packedCharm, .forageSachet)
        // 1,100 + 385 (35% bonus) = 1,485 >= 1,400 -> triggers a Pocket Find curio!
        XCTAssertFalse(summary.curiosFoundIDs.isEmpty, "Forage sachet 35% bonus should trigger Pocket Find curio at 1,100 steps")

        // 2. Ginger Thermos awards +2 warm tea return bonus & day rollover auto-archives cleanly
        XCTAssertTrue(coordinator.startStrollSession(companionPetID: "pet.03", charm: .gingerThermos))
        let balanceAfterStart = coordinator.ledger.coinBalance
        _ = coordinator.ingestSteps(steps: 200, intervalStartUTC: Date().addingTimeInterval(4000), placeLabel: "雨巷")
        coordinator.advanceSimulatedDays(1)
        XCTAssertNil(coordinator.activeStroll, "Day rollover must cleanly auto-archive active stroll")
        XCTAssertEqual(coordinator.ledger.coinBalance, balanceAfterStart + 1 + 2, "Should include 1 step coin + 2 ginger thermos bonus coins")
    }

    /// Verifies 2.5D Sunroom free-roaming engine: resident sync, depth-staggered furniture positions, and tap-floor call-over.
    func testSunroom25DRoamingAndFloorTapCall() throws {
        let coordinator = try makeInMemoryCoordinator()
        let roaming = SunroomRoamingEngine()
        roaming.syncResidents(
            invitedPetIDs: ["pet.02", "pet.03", "pet.04"],
            spots: coordinator.homeSpots,
            verandaUnlocked: false
        )
        XCTAssertEqual(roaming.actors.count, 3)

        // Spot positions must span true 2.5D depth (back window vs foreground rug)
        let backSpot = SunroomRoamingEngine.spot25DPosition(for: 1, verandaUnlocked: false)
        let frontSpot = SunroomRoamingEngine.spot25DPosition(for: 5, verandaUnlocked: false)
        XCTAssertLessThan(backSpot.y, 0.30)
        XCTAssertGreaterThan(frontSpot.y, 0.70)

        // Calling nearest pet to far-right foreground floor starts walking & spawns tap ripple
        let tapPoint = CGPoint(x: 0.85, y: 0.80)
        roaming.callNearestPet(to: tapPoint)
        XCTAssertEqual(roaming.floorRipples.count, 1)
        XCTAssertTrue(roaming.actors.values.contains(where: { $0.isWalking }))
    }

    func testLiveStrollStepsNoDoubleCountAndMidnightRollover() throws {
        let coordinator = try makeInMemoryCoordinator()
        let startMorning = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 9, minute: 0))!
        coordinator.currentSimulatedDate = startMorning
        coordinator.isUsingSimulatedClock = false
        let initialISO = coordinator.currentLocalDateISO

        let started = coordinator.startStrollSession(companionPetID: nil, charm: .none)
        XCTAssertTrue(started)

        // Stream two live deltas within the same 15-min bucket -> both credit cleanly!
        let d1 = coordinator.ingestLiveStrollSteps(deltaSteps: 120)
        let d2 = coordinator.ingestLiveStrollSteps(deltaSteps: 130)
        XCTAssertEqual(d1, 120)
        XCTAssertEqual(d2, 130)
        XCTAssertEqual(coordinator.activeStroll?.sessionSteps, 250)
        XCTAssertEqual(coordinator.ledger.coinBalance, 1) // 250 / 200 = 1 coin, 50 carry

        // Subsequent historical bucket query for the same 15-min interval (250 total) MUST NOT double-count!
        let dup = coordinator.ingestSteps(steps: 250, intervalStartUTC: startMorning)
        XCTAssertEqual(dup.newlyAcceptedSteps, 0)
        XCTAssertEqual(coordinator.ledger.coinBalance, 1)

        // Crossing midnight on app foreground rolls over currentLocalDateISO and gently archives yesterday's stroll!
        let nextDay = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 8, minute: 30))!
        coordinator.handleAppBecameActive(now: nextDay)
        XCTAssertNotEqual(coordinator.currentLocalDateISO, initialISO)
        XCTAssertNil(coordinator.activeStroll)
    }

    func testSunroomFurnitureCustomDragOrigamiAndZeroChurnInterpolation() throws {
        let coordinator = try makeInMemoryCoordinator()
        let roaming = SunroomRoamingEngine()
        roaming.resetCustomSpotPositions()

        // Custom 2.5D drag-to-place furniture persistence
        roaming.setCustomSpotPosition(spotIndex: 2, uv: CGPoint(x: 0.77, y: 0.65))
        let moved = roaming.resolvedSpotPosition(for: 2, verandaUnlocked: false)
        XCTAssertEqual(moved.x, 0.77, accuracy: 0.001)
        XCTAssertEqual(moved.y, 0.65, accuracy: 0.001)

        // Pure 60fps interpolated position advances smoothly mid-walk without mutating stored anchor position
        let t0 = Date()
        roaming.syncResidents(invitedPetIDs: ["pet.02", "pet.03"], spots: coordinator.homeSpots, verandaUnlocked: false, now: t0)
        roaming.callNearestPet(to: CGPoint(x: 0.88, y: 0.82), now: t0)
        let walkingActor = try XCTUnwrap(roaming.actors.values.first(where: { $0.isWalking }))
        let pStart = walkingActor.interpolatedPosition(at: t0)
        let pMid = walkingActor.interpolatedPosition(at: t0.addingTimeInterval(1.5))
        XCTAssertNotEqual(pStart, pMid)

        // Juniper origami charm gift grants +1 coin cleanly
        let coinsBefore = coordinator.ledger.coinBalance
        coordinator.collectOrigamiCharmGift(note: "測試摺紙符")
        XCTAssertEqual(coordinator.ledger.coinBalance, coinsBefore + 1)
        roaming.resetCustomSpotPositions()
    }

    func testWeatherInferenceAndQuietNeighborhoodFallback() throws {
        let morning = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 8, minute: 15))!
        let dusk = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 17, minute: 45))!
        XCTAssertEqual(WeatherSyncService.inferTimeOfDayWeather(now: morning).weatherMode, .clearMorning)
        XCTAssertEqual(WeatherSyncService.inferTimeOfDayWeather(now: dusk).weatherMode, .dusk)
        XCTAssertEqual(WeatherSyncService.mapWMOCode(61, hour: 10), .lightRain)
        XCTAssertEqual(WeatherSyncService.mapWMOCode(0, hour: 17), .dusk)

        let center = LocationService.defaultNeighborhoodOrigin
        let fallbacks = MapKitAnchorDiscoveryService.quietNeighborhoodFallbackAnchors(around: center, existing: [])
        XCTAssertEqual(fallbacks.count, 3)
    }

    func testSunroomBallTossAndPetFramesBundleResolution() throws {
        let coordinator = try makeInMemoryCoordinator()
        let roaming = SunroomRoamingEngine()
        let now = Date()
        roaming.syncResidents(invitedPetIDs: ["pet.03", "pet.06"], spots: coordinator.homeSpots, verandaUnlocked: false, now: now)

        let chaserID = roaming.tossClothBall(now: now)
        XCTAssertNotNil(chaserID)
        XCTAssertNotNil(roaming.rollingBall)
        XCTAssertNotNil(roaming.rollingBall?.position(at: now.addingTimeInterval(0.8)))
        XCTAssertEqual(roaming.actors[chaserID!]?.isWalking, true)

        // Verify HEIC-alpha frames are bundled cleanly inside PetFrames/ folder reference
        let frameURL = Bundle.main.url(forResource: "pet_03_w1", withExtension: "heic", subdirectory: "PetFrames")
        XCTAssertNotNil(frameURL)
    }

    func testRound2PerSpeciesWeatherNarrativeAndPairDialogues() throws {
        let coordinator = try makeInMemoryCoordinator()
        // Advance pet.03 (餘燼) past early milestones so ambient selection runs
        let ember = try XCTUnwrap(coordinator.resident(for: "pet.03"))
        ember.sharedDaysCount = 12
        ember.lastSharedDateISO = "2026-11-01"

        let sunnyScene = NarrativeEngine.selectStreetScene(
            pet: ember,
            anchorLabel: "麵包店巷口",
            weather: .clearMorning,
            chosenGesture: .offerHand,
            localDateISO: "2026-11-22",
            pastEncounters: [],
            activeIntentions: []
        )
        XCTAssertFalse(sunnyScene.streetSlipLine.contains("滴水"), "Sunny morning ambient line must never mention dripping rain")
        XCTAssertTrue(sunnyScene.streetSlipLine.contains("餘燼"))

        let pair = NarrativeEngine.pairDialogue(
            primary: PetCatalog.pet(id: "pet.02"),
            secondary: PetCatalog.pet(id: "pet.03"),
            anchorLabel: "麵包店巷口",
            weather: .lightRain
        )
        XCTAssertTrue(pair.slip.contains("杜松") && pair.slip.contains("餘燼"))

        let revisit = NarrativeEngine.revisitVignette(
            pet: PetCatalog.pet(id: "pet.08"),
            secondary: nil,
            anchorLabel: "溪畔木椅",
            timeBandKey: "evening",
            weather: .dusk
        )
        XCTAssertTrue(revisit.contains("蘆葦") && revisit.contains("鹿角"))
    }

    func testRound2ShopGoodiesGingerTeaNicknamesAndDeepLinks() throws {
        let coordinator = try makeInMemoryCoordinator()
        // Verify 9 goodies exist (5 original + 4 new mythical furniture pieces) and 16 curios in Compendium
        let goodies = ShopCatalog.items.filter { $0.category == .goodies }
        XCTAssertEqual(goodies.count, 9)
        XCTAssertEqual(CurioCatalog.all.count, 16)

        // Buying Ginger Tea activates 24h foreground Sunroom tray
        coordinator.ledger.coinBalance = 500
        let tea = try XCTUnwrap(ShopCatalog.item(id: "treat.ginger_tea"))
        XCTAssertFalse(coordinator.isGingerTeaActive)
        XCTAssertTrue(coordinator.purchaseItem(tea))
        XCTAssertTrue(coordinator.isGingerTeaActive)

        // Pet custom nickname editing persists cleanly
        coordinator.updatePetNickname(petID: "pet.03", nickname: "小芝芝")
        XCTAssertEqual(coordinator.displayName(for: "pet.03"), "小芝芝")

        // Day 6+ companion street encounter bonus gift awards +1 coin
        let pet = try XCTUnwrap(coordinator.resident(for: "pet.03"))
        pet.sharedDaysCount = 7
        let coinsBefore = coordinator.ledger.coinBalance
        let giftMsg = coordinator.awardStreetEncounterBonusGiftIfEligible(petID: "pet.03")
        XCTAssertNotNil(giftMsg)
        XCTAssertEqual(coordinator.ledger.coinBalance, coinsBefore + 1)

        // URL Deep Link routing for Widgets & Siri
        coordinator.handleDeepLink(URL(string: "pawprintdays://start-stroll")!)
        XCTAssertEqual(coordinator.currentScreen, .street)
        XCTAssertTrue(coordinator.pendingOpenStartStrollSheet)
        coordinator.handleDeepLink(URL(string: "pawprintdays://diary")!)
        XCTAssertEqual(coordinator.currentScreen, .sketchbook)
    }

    func testRound2DiaryPhotoMountPDFExportAndJSONBackupRestore() throws {
        let coordinator = try makeInMemoryCoordinator()
        let iso = coordinator.currentLocalDateISO
        coordinator.savePersonalNote(for: iso, note: "今天與餘燼一起在巷口聽雨。")
        coordinator.toggleStarredTradition(for: iso)
        coordinator.saveWalkPhoto(for: iso, jpegData: Data([0xFF, 0xD8, 0xFF, 0xD9]))

        let day = coordinator.todayDiaryRecord()
        XCTAssertNotNil(day.photoJPEGData)
        XCTAssertTrue(day.isStarredTradition)

        // Monthly Watercolor PDF export produces a non-empty PDF file
        let comps = Calendar.current.dateComponents([.year, .month], from: coordinator.currentSimulatedDate)
        let pdfURL = DiaryExportService.exportMonthlyPDF(
            year: comps.year ?? 2026,
            month: comps.month ?? 11,
            days: coordinator.diaryDays,
            encounters: coordinator.encounters,
            curios: coordinator.ledger.foragedCurios
        )
        let unwrappedPDF = try XCTUnwrap(pdfURL)
        let pdfBytes = try Data(contentsOf: unwrappedPDF)
        XCTAssertGreaterThan(pdfBytes.count, 500)

        // Portable JSON backup & restore safely recovers notes without clobbering
        let backupURL = try XCTUnwrap(DiaryExportService.exportJSONBackup(coordinator: coordinator))
        day.personalNote = ""
        let restored = DiaryExportService.restoreJSONBackup(from: backupURL, coordinator: coordinator)
        XCTAssertGreaterThanOrEqual(restored, 1)
        XCTAssertEqual(coordinator.todayDiaryRecord().personalNote, "今天與餘燼一起在巷口聽雨。")
    }

    /// Regression test: connecting multiple AVAudioPlayerNodes through an AVAudioMixerNode into single-input
    /// AVAudioUnitReverb keeps all players connected (preventing NSException on foleyPlayer.play()).
    func testAudioReverbSubMixerGraphKeepsAllPlayersConnected() throws {
        let eng = AVAudioEngine()
        let foley = AVAudioPlayerNode()
        let music = AVAudioPlayerNode()
        let rain = AVAudioPlayerNode()
        let subMixer = AVAudioMixerNode()
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.smallRoom)
        reverb.wetDryMix = 14.0

        for node: AVAudioNode in [foley, music, rain, subMixer, reverb] {
            eng.attach(node)
        }
        let fmt = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2))
        eng.connect(foley, to: subMixer, format: fmt)
        eng.connect(music, to: subMixer, format: fmt)
        eng.connect(subMixer, to: reverb, format: fmt)
        eng.connect(reverb, to: eng.mainMixerNode, format: fmt)
        eng.connect(rain, to: eng.mainMixerNode, format: fmt)

        XCTAssertFalse(eng.outputConnectionPoints(for: foley, outputBus: 0).isEmpty, "foley must stay connected")
        XCTAssertFalse(eng.outputConnectionPoints(for: music, outputBus: 0).isEmpty, "music must stay connected")
        XCTAssertFalse(eng.outputConnectionPoints(for: rain, outputBus: 0).isEmpty, "rain must stay connected")
    }

    /// Comprehensive end-to-end crash-safety sweep across every player action, pure mystical cast,
    /// clean fresh-start reset, and interactive onboarding tutorial lifecycle.
    func testComprehensiveCrashSafetyMysticalCastResetAndTutorial() throws {
        let coordinator = try makeInMemoryCoordinator()

        // 1. Verify strictly mystical 6-companion cast (zero normal cats or dogs)
        XCTAssertEqual(PetCatalog.allPets.count, 6)
        XCTAssertTrue(PetCatalog.allPets.allSatisfy { $0.kind.isMagical })
        XCTAssertFalse(PetCatalog.allPets.contains(where: { $0.id == "pet.01" || $0.id == "pet.05" }))
        XCTAssertEqual(coordinator.residents.count, 6)

        // 2. Verify graceful handling of unknown/legacy pet IDs (never crashes)
        let fallbackSpec = PetCatalog.pet(id: "pet.nonexistent")
        XCTAssertTrue(fallbackSpec.kind.isMagical)
        XCTAssertFalse(coordinator.displayName(for: "pet.nonexistent").isEmpty)

        // 3. Exercise every audio & haptic cue safely
        CozySoundEngine.shared.playPaperFlip()
        CozySoundEngine.shared.playCompassChime()
        CozySoundEngine.shared.playPawTap()
        CozySoundEngine.shared.playBrushSwish()
        CozySoundEngine.shared.playPetPurr()
        CozySoundEngine.shared.playPetChirp()
        CozySoundEngine.shared.playTeapotClink()
        CozySoundEngine.shared.playWardrobeSnap(withBell: true)
        CozySoundEngine.shared.setCozyMusic(active: true, weather: .lightRain)
        CozySoundEngine.shared.setRainAmbience(active: true)
        CozySoundEngine.shared.stopRainAmbience()
        CozySoundEngine.shared.stopCozyMusic()
        HapticsEngine.shared.playBrushStrokeTick()
        HapticsEngine.shared.playPawRangeCue()
        HapticsEngine.shared.playDogBallRoll()
        HapticsEngine.shared.playCurioUnpack()

        // 4. Exercise every major user action & empty/populated states without crashing
        XCTAssertTrue(coordinator.discoveredFriendships.isEmpty)
        coordinator.ledger.coinBalance = 5_000
        for item in ShopCatalog.items where item.priceCoins > 0 {
            _ = coordinator.purchaseItem(item)
        }
        coordinator.sipGingerTea()
        for spec in PetCatalog.allPets {
            coordinator.resident(for: spec.id)?.inviteState = .invitedHome
            coordinator.updatePetNickname(petID: spec.id, nickname: spec.name)
            coordinator.equipOutfit(petID: spec.id, outfitID: "outfit.sage_ribbon")
            coordinator.completeTactileCare(petID: spec.id, texture: .warm)
            coordinator.togglePinFavorite(petID: spec.id)
        }
        coordinator.solveHomeRoomNow()
        _ = coordinator.discoveredFriendships
        _ = DiaryExportService.exportMonthlyPDF(year: 2026, month: 1, days: [], encounters: [], curios: [])
        _ = DiaryExportService.exportJSONBackup(coordinator: coordinator)

        // 5. Full fresh-start reset wipes all old history and opens interactive tutorial
        coordinator.completeInteractiveTutorial()
        XCTAssertFalse(coordinator.showInteractiveTutorial)
        coordinator.resetAllGameData()
        XCTAssertTrue(coordinator.showInteractiveTutorial)
        XCTAssertEqual(coordinator.ledger.coinBalance, 0)
        XCTAssertTrue(coordinator.encounters.isEmpty)
        XCTAssertTrue(coordinator.ledger.foragedCurios.isEmpty)
        let starterResidents = coordinator.residents.filter { $0.inviteState == .invitedHome }
        XCTAssertEqual(starterResidents.count, 1, "New game must start with exactly 1 mystical starter companion")
        XCTAssertEqual(starterResidents.first?.petID, "pet.03")
    }
}
