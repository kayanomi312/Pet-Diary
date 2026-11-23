import XCTest
import SwiftData
import CoreLocation
@testable import PawprintDays

/// Gameplay balance & progression: indoor coin pacing, doorstep corner, sachet/thermos balance,
/// stable seeding, favourite greetings, curio gifts & sets, walk quests, special visitors, unlocks.
@MainActor
final class GameplayBalanceTests: XCTestCase {
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

    func testIndoorCoinsPayOncePerDayAndResetNextDay() throws {
        let c = try makeInMemoryCoordinator()
        c.ledger.coinBalance = 0
        let recipe = TeaKitchenCatalog.allRecipes[0]
        for _ in 0..<10 { c.brewTeaRecipe(recipe) }
        for _ in 0..<10 { c.craftOrigami(.star) }
        for _ in 0..<10 { c.collectOrigamiCharmGift(note: "紙符 (+1 步數幣)") }
        XCTAssertEqual(c.ledger.coinBalance, 1 + 1 + 3, "tea 1 + origami 1 + origami charms 3 per day")
        XCTAssertEqual(c.remainingIndoorCoins(for: "tea"), 0)

        c.currentSimulatedDate = c.currentSimulatedDate.addingTimeInterval(86_400)
        XCTAssertEqual(c.remainingIndoorCoins(for: "tea"), 1)
        XCTAssertTrue(c.brewTeaRecipe(recipe))
        XCTAssertEqual(c.ledger.coinBalance, 6)
    }

    func testLegacyIndoorStateDecodesWithoutLosingOffspring() throws {
        // Older saves lack the new keys; decoding must keep existing data instead of resetting.
        var legacy = SunroomIndoorState()
        legacy.totalTeaBrewedCount = 7
        legacy.seenSkitIDs = ["skit.a"]
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as? [String: Any])
        for key in ["lastWindowGreetDateISO", "indoorCoinCounts", "discoveredFavoriteGesturePetIDs",
                    "giftedCurioEntryIDs", "claimedCurioSetWeatherCodes", "completedWalkQuestCount",
                    "specialVisitorDates", "hasPlacedDoorstepCorner", "indoorCoinDateISO"] {
            json.removeValue(forKey: key)
        }
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(SunroomIndoorState.self, from: data)
        XCTAssertEqual(decoded.totalTeaBrewedCount, 7)
        XCTAssertEqual(decoded.seenSkitIDs, ["skit.a"])
        XCTAssertFalse(decoded.hasPlacedDoorstepCorner)
        XCTAssertTrue(decoded.indoorCoinCounts.isEmpty)
    }

    func testStableHashIsDeterministicAndDailyBoardsAreStable() {
        XCTAssertEqual(StableHash.value("2026-11-23"), StableHash.value("2026-11-23"))
        XCTAssertGreaterThanOrEqual(StableHash.value("pet.03"), 0)
        let a = DailyWishesBoard.generate(for: "2026-11-23", hasOffspring: false)
        let b = DailyWishesBoard.generate(for: "2026-11-23", hasOffspring: false)
        XCTAssertEqual(a.wishes.map(\.kind), b.wishes.map(\.kind))
        // Known FNV-1a 64 value (masked to 62 bits) pins the algorithm so it never silently changes.
        XCTAssertEqual(StableHash.value("a"), Int(UInt64(0xaf63dc4c8601ec8c) & 0x3FFF_FFFF_FFFF_FFFF))
    }

    func testDoorstepCornerPlacedOnceAndSampleCornersHiddenWhenFar() throws {
        let c = try makeInMemoryCoordinator()
        let taipei = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654),
            altitude: 10, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date()
        )
        let corner = try XCTUnwrap(c.ensureDoorstepCornerIfNeeded(around: taipei))
        XCTAssertEqual(corner.customLabel, "家門口轉角")
        XCTAssertEqual(c.resident(for: corner.regularPetID)?.inviteState, .unmet, "Doorstep regular should be someone new")
        XCTAssertLessThan(taipei.distance(from: CLLocation(latitude: corner.lat, longitude: corner.lon)), 75)
        XCTAssertFalse(c.visibleAnchors.contains { $0.siteID.hasPrefix("sys.luodong.") })
        XCTAssertNil(c.ensureDoorstepCornerIfNeeded(around: taipei), "Only ever placed once")
        XCTAssertEqual(c.anchors.filter { $0.siteID.hasPrefix("local.doorstep.") }.count, 1)
    }

    func testDoorstepSkippedForPoorAccuracy() throws {
        let c = try makeInMemoryCoordinator()
        let fuzzy = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654),
            altitude: 10, horizontalAccuracy: 300, verticalAccuracy: 10, timestamp: Date()
        )
        XCTAssertNil(c.ensureDoorstepCornerIfNeeded(around: fuzzy))
        XCTAssertFalse(c.indoorState.hasPlacedDoorstepCorner)
    }

    func testThermosFullRefundForRealWalks() throws {
        let c = try makeInMemoryCoordinator()
        c.ledger.coinBalance = 6
        XCTAssertTrue(c.startStrollSession(companionPetID: "pet.03", charm: .gingerThermos))
        XCTAssertEqual(c.ledger.coinBalance, 0)
        _ = c.ingestSteps(steps: 1_600, intervalStartUTC: Date(), placeLabel: "巷口")
        let summary = try XCTUnwrap(c.endStrollSession())
        XCTAssertEqual(summary.coinsEarned, 8 + 9)
        XCTAssertEqual(c.ledger.coinBalance, 17, "1,600 steps = 8 coins, plus +9 thermos refund (net positive)")
    }

    func testSachetRespectsDailyCapPlusOne() throws {
        let c = try makeInMemoryCoordinator()
        c.ledger.coinBalance = 6
        XCTAssertTrue(c.startStrollSession(companionPetID: "pet.03", charm: .forageSachet))
        XCTAssertEqual(c.dailyPocketFindCap, 4, "Base 3 + 1 while the sachet stroll is active")
        var t = Date()
        for _ in 0..<20 {
            _ = c.ingestSteps(steps: 2_000, intervalStartUTC: t, placeLabel: "巷口")
            t = t.addingTimeInterval(900)
        }
        XCTAssertEqual(c.todaysPocketFindCount, 4, "Sachet bonus finds must not bypass the daily cap")
        _ = c.endStrollSession()
        XCTAssertEqual(c.dailyPocketFindCap, 3)
    }

    func testFavoriteGestureRewardsAndDiscovery() throws {
        let c = try makeInMemoryCoordinator()
        c.ledger.coinBalance = 0
        let favorite = PetCatalog.pet(id: "pet.03").favoriteGreeting
        XCTAssertFalse(c.hasDiscoveredFavoriteGesture(for: "pet.03"))
        _ = try XCTUnwrap(c.commitStreetEncounter(siteID: "sys.luodong.bakery_corner", petID: "pet.03", gesture: favorite))
        XCTAssertTrue(c.hasDiscoveredFavoriteGesture(for: "pet.03"))
        XCTAssertEqual(c.ledger.coinBalance, 2)

        // A second greeting with the same pet today (another corner) doesn't pay again.
        _ = try XCTUnwrap(c.commitStreetEncounter(siteID: "sys.luodong.riverside_bench", petID: "pet.03", gesture: favorite))
        XCTAssertEqual(c.ledger.coinBalance, 2)

        // Mismatched gesture: no reward, no discovery.
        _ = try XCTUnwrap(c.commitStreetEncounter(siteID: "sys.luodong.library_arcade", petID: "pet.02", gesture: .offerHand))
        XCTAssertFalse(c.hasDiscoveredFavoriteGesture(for: "pet.02"))
        XCTAssertEqual(c.ledger.coinBalance, 2)

        // Every cat loves the umbrella in the rain.
        XCTAssertTrue(c.isFavoriteGesture(.holdUmbrella, for: "pet.02", weather: .lightRain))
        XCTAssertFalse(c.isFavoriteGesture(.holdUmbrella, for: "pet.02", weather: .clearMorning))
    }

    func testCurioGiftAndWeatherSetReward() throws {
        let c = try makeInMemoryCoordinator()
        c.ledger.coinBalance = 0
        let duskCurios = CurioCatalog.all.filter { $0.weatherTag == .dusk }
        c.ledger.foragedCurios = duskCurios.map {
            ForagedCurioEntry(curioID: $0.id, placeLabel: "巷口", weatherCode: "dusk", localDateISO: c.currentLocalDateISO)
        }
        let set = try XCTUnwrap(c.curioSetProgress.first { $0.weather == .dusk })
        XCTAssertTrue(set.isComplete)
        XCTAssertTrue(c.claimCurioSetReward(weather: .dusk))
        XCTAssertEqual(c.ledger.coinBalance, set.rewardCoins)
        XCTAssertFalse(c.claimCurioSetReward(weather: .dusk), "Set rewards are claimed once")

        let entry = c.ledger.foragedCurios[0]
        let before = c.resident(for: "pet.03")?.sharedDaysCount ?? 0
        XCTAssertTrue(c.giftCurio(entryID: entry.id, to: "pet.03"))
        XCTAssertTrue(c.isCurioGifted(entry))
        XCTAssertEqual(c.resident(for: "pet.03")?.sharedDaysCount, before + 1)
        XCTAssertFalse(c.giftCurio(entryID: entry.id, to: "pet.03"), "A curio can only be gifted once")
        XCTAssertFalse(c.giftCurio(entryID: c.ledger.foragedCurios[1].id, to: "pet.07"), "Only residents can receive gifts")
        XCTAssertEqual(c.ledger.foragedCurios.count, duskCurios.count, "Gifting keeps the collection intact")
    }

    func testWalkWithMeQuestCompletesFromSteps() throws {
        let c = try makeInMemoryCoordinator()
        let quest = try XCTUnwrap(c.offerWalkQuestIfAppropriate(petID: "pet.03"))
        XCTAssertNil(c.offerWalkQuestIfAppropriate(petID: "pet.03"), "One quest at a time")
        XCTAssertTrue((500...800).contains(quest.targetSteps))
        let coinsBefore = c.ledger.coinBalance
        _ = c.ingestSteps(steps: quest.targetSteps, intervalStartUTC: Date(), placeLabel: "巷口")
        XCTAssertNil(c.activeWalkQuestToday)
        XCTAssertEqual(c.indoorState.completedWalkQuestCount, 1)
        XCTAssertEqual(c.ledger.coinBalance, coinsBefore + quest.targetSteps / 200 + WalkWithMeQuest.rewardCoins)
    }

    func testSpecialVisitorAppearsOncePerWindowPerDay() throws {
        let c = try makeInMemoryCoordinator()
        c.setManualWeatherPreview(.lightRain)
        let bakery = try XCTUnwrap(c.anchors.first { $0.siteID == "sys.luodong.bakery_corner" })
        let rule = try XCTUnwrap(c.applySpecialVisitorIfEligible(anchor: bakery))
        XCTAssertEqual(rule.petID, "pet.08")
        XCTAssertEqual(bakery.cachedVisitorOfferID, "pet.08")
        let river = try XCTUnwrap(c.anchors.first { $0.siteID == "sys.luodong.library_arcade" })
        XCTAssertNil(c.applySpecialVisitorIfEligible(anchor: river), "Only once per day per rule")
    }

    func testStagedFeatureUnlocks() throws {
        let c = try makeInMemoryCoordinator()
        XCTAssertFalse(c.isFeatureUnlocked(.errands))
        XCTAssertFalse(c.isFeatureUnlocked(.nesting))
        XCTAssertFalse(c.isFeatureUnlocked(.mentorship))
        _ = c.commitStreetEncounter(siteID: "sys.luodong.bakery_corner", petID: "pet.07", gesture: .offerHand)
        XCTAssertTrue(c.isFeatureUnlocked(.errands))
        XCTAssertTrue(c.isFeatureUnlocked(.mentorship))
        c.resident(for: "pet.02")?.inviteState = .invitedHome
        XCTAssertTrue(c.isFeatureUnlocked(.nesting))
    }

    func testNextGoalHintGuidesFirstEncounter() throws {
        let c = try makeInMemoryCoordinator()
        let hint = try XCTUnwrap(c.nextGoalHint)
        XCTAssertEqual(hint.icon, "pawprint.fill")
    }
}
