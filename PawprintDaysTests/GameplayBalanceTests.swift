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

    // MARK: - Zero-FOMO cozy stamp card

    func testCozyStampAccruesOncePerDayAndNeverResetsOnMissedDays() throws {
        let c = try makeInMemoryCoordinator()
        XCTAssertFalse(c.hasEarnedCozyStampToday)
        XCTAssertTrue(c.awardDailyCozyStampIfEligible(reason: "測試"))
        XCTAssertFalse(c.awardDailyCozyStampIfEligible(reason: "測試"), "At most one stamp per civil day")
        XCTAssertEqual(c.indoorState.stampCountInCard, 1)
        XCTAssertEqual(c.indoorState.lastStampAwardedDateISO, c.currentLocalDateISO)

        // Skipping several days never erases progress.
        c.currentSimulatedDate = c.currentSimulatedDate.addingTimeInterval(4 * 86_400)
        XCTAssertFalse(c.hasEarnedCozyStampToday)
        XCTAssertTrue(c.awardDailyCozyStampIfEligible(reason: "測試"))
        XCTAssertEqual(c.indoorState.stampCountInCard, 2)
        XCTAssertEqual(c.indoorState.completedStampCardsCount, 0)
    }

    func testSeventhStampPaysFifteenCoinsAndStartsAFreshCard() throws {
        let c = try makeInMemoryCoordinator()
        c.ledger.coinBalance = 0
        var paidDays = 0
        for day in 0..<7 {
            c.currentSimulatedDate = Date().addingTimeInterval(Double(day * 2) * 86_400) // every other day
            XCTAssertTrue(c.awardDailyCozyStampIfEligible(reason: "散步"))
            paidDays += 1
            if day < 6 {
                XCTAssertEqual(c.ledger.coinBalance, 0, "Only the 7th stamp pays")
                XCTAssertEqual(c.indoorState.stampCountInCard, day + 1)
            }
        }
        XCTAssertEqual(paidDays, 7)
        XCTAssertEqual(c.ledger.coinBalance, CozyStampCard.completionRewardCoins)
        XCTAssertEqual(CozyStampCard.completionRewardCoins, 15)
        XCTAssertEqual(c.indoorState.stampCountInCard, 0)
        XCTAssertEqual(c.indoorState.completedStampCardsCount, 1)
        XCTAssertTrue(c.todayDiaryRecord().revisitNotes.contains { $0.contains("足印集章卡第 1 張") })

        let celebration = try XCTUnwrap(c.pendingMilestoneCelebration)
        XCTAssertEqual(celebration.kind, .stampCard)
        XCTAssertEqual(celebration.rewardBadge, "+15 步數幣")
        c.dismissMilestoneCelebration()
        XCTAssertNil(c.pendingMilestoneCelebration)
    }

    func testStampTriggersEncounterStrollAndAllWishes() throws {
        // Street encounter
        let a = try makeInMemoryCoordinator()
        _ = try XCTUnwrap(a.commitStreetEncounter(siteID: "sys.luodong.bakery_corner", petID: "pet.03", gesture: .offerHand))
        XCTAssertTrue(a.hasEarnedCozyStampToday)
        XCTAssertEqual(a.indoorState.stampCountInCard, 1)

        // A short stroll (< 100 steps, no encounters) doesn't stamp; a real one does.
        let b = try makeInMemoryCoordinator()
        XCTAssertTrue(b.startStrollSession(companionPetID: "pet.03", charm: .none))
        _ = b.ingestSteps(steps: 40, intervalStartUTC: Date(), placeLabel: "巷口")
        _ = b.endStrollSession()
        XCTAssertFalse(b.hasEarnedCozyStampToday)
        XCTAssertTrue(b.startStrollSession(companionPetID: "pet.03", charm: .none))
        _ = b.ingestSteps(steps: 400, intervalStartUTC: Date().addingTimeInterval(1_800), placeLabel: "巷口")
        let summary = try XCTUnwrap(b.endStrollSession())
        XCTAssertGreaterThanOrEqual(summary.totalSteps, GameCoordinator.strollStampMinimumSteps)
        XCTAssertTrue(b.hasEarnedCozyStampToday)
        let snapshot = try XCTUnwrap(StrollStampSnapshot.store[summary.id])
        XCTAssertTrue(snapshot.stampedToday)
        XCTAssertEqual(snapshot.filledSlots, 1)

        // Claiming all three daily wishes
        let w = try makeInMemoryCoordinator()
        let kinds = w.todayWishesBoard.wishes.map(\.kind)
        XCTAssertEqual(kinds.count, 3)
        for kind in kinds { w.markDailyWishCompleted(kind) }
        XCTAssertTrue(w.claimDailyWishReward(kinds[0]))
        XCTAssertTrue(w.claimDailyWishReward(kinds[1]))
        XCTAssertFalse(w.hasEarnedCozyStampToday, "Two of three wishes isn't enough")
        XCTAssertTrue(w.claimDailyWishReward(kinds[2]))
        XCTAssertTrue(w.hasEarnedCozyStampToday)
    }

    func testLegacyIndoorStateDecodesStampFieldsWithDefaults() throws {
        var legacy = SunroomIndoorState()
        legacy.totalTeaBrewedCount = 3
        legacy.stampCountInCard = 4
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as? [String: Any])
        for key in ["stampCountInCard", "completedStampCardsCount", "lastStampAwardedDateISO", "unlockedCelebratedFeatures"] {
            json.removeValue(forKey: key)
        }
        let decoded = try JSONDecoder().decode(SunroomIndoorState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(decoded.totalTeaBrewedCount, 3)
        XCTAssertEqual(decoded.stampCountInCard, 0)
        XCTAssertEqual(decoded.completedStampCardsCount, 0)
        XCTAssertNil(decoded.lastStampAwardedDateISO)
        XCTAssertTrue(decoded.unlockedCelebratedFeatures.isEmpty)

        // An empty object and out-of-range / mistyped values never break the decode.
        XCTAssertNoThrow(try JSONDecoder().decode(SunroomIndoorState.self, from: Data("{}".utf8)))
        let odd = Data(#"{"stampCountInCard": 12, "completedStampCardsCount": "x", "totalTeaBrewedCount": 2}"#.utf8)
        let clamped = try JSONDecoder().decode(SunroomIndoorState.self, from: odd)
        XCTAssertEqual(clamped.stampCountInCard, CozyStampCard.slotCount - 1)
        XCTAssertEqual(clamped.completedStampCardsCount, 0)
        XCTAssertEqual(clamped.totalTeaBrewedCount, 2)

        // Round trip keeps the new fields.
        var fresh = SunroomIndoorState()
        fresh.stampCountInCard = 5
        fresh.completedStampCardsCount = 2
        fresh.lastStampAwardedDateISO = "2026-11-24"
        fresh.unlockedCelebratedFeatures = ["welcome.pet.07"]
        let roundTrip = try JSONDecoder().decode(SunroomIndoorState.self, from: JSONEncoder().encode(fresh))
        XCTAssertEqual(roundTrip.stampCountInCard, 5)
        XCTAssertEqual(roundTrip.completedStampCardsCount, 2)
        XCTAssertEqual(roundTrip.lastStampAwardedDateISO, "2026-11-24")
        XCTAssertEqual(roundTrip.unlockedCelebratedFeatures, ["welcome.pet.07"])
    }

    // MARK: - Bond progress & milestone celebrations

    func testBondProgressSnapshot() throws {
        let c = try makeInMemoryCoordinator()
        let pet = try XCTUnwrap(c.resident(for: "pet.03"))
        pet.sharedDaysCount = 4
        let mid = c.bondProgress(for: "pet.03")
        XCTAssertEqual(mid.currentTier, 2)
        XCTAssertEqual(mid.currentTierTitle, "熟悉面孔")
        XCTAssertEqual(mid.nextTierTitle, "散步同伴")
        XCTAssertEqual(mid.sharedDays, 4)
        XCTAssertEqual(mid.nextMilestoneDays, 6)
        XCTAssertEqual(mid.daysRemaining, 2)
        XCTAssertEqual(mid.progressFraction, 1.0 / 3.0, accuracy: 0.0001)

        pet.sharedDaysCount = 30
        let maxed = c.bondProgress(for: "pet.03")
        XCTAssertEqual(maxed.currentTier, 6)
        XCTAssertTrue(maxed.isMaxTier)
        XCTAssertNil(maxed.nextTierTitle)
        XCTAssertEqual(maxed.daysRemaining, 0)
        XCTAssertEqual(maxed.progressFraction, 1)

        let unknown = c.bondProgress(for: "pet.99")
        XCTAssertEqual(unknown.currentTier, 0)
        XCTAssertEqual(unknown.nextMilestoneDays, 1)
        XCTAssertEqual(unknown.progressFraction, 0)
    }

    func testBondTierUpCelebrationNamesTheUnlockedPerk() throws {
        let c = try makeInMemoryCoordinator()
        let pet = try XCTUnwrap(c.resident(for: "pet.03"))
        pet.sharedDaysCount = 2
        pet.milestoneTier = 1
        c.completeTactileCare(petID: "pet.03")
        let day3 = try XCTUnwrap(c.pendingMilestoneCelebration)
        XCTAssertEqual(day3.kind, .bondTierUp)
        XCTAssertEqual(day3.id, "bond.pet.03.tier2")
        XCTAssertTrue(day3.detail.contains("烘暖石階的小秘密"), "Day 3 names the new memory chapter")
        c.dismissMilestoneCelebration()

        // Same day again: no new shared day, no repeat celebration.
        c.completeTactileCare(petID: "pet.03")
        XCTAssertNil(c.pendingMilestoneCelebration)

        // Day 6 via a curio gift: street gifts unlock.
        pet.sharedDaysCount = 5
        c.currentSimulatedDate = c.currentSimulatedDate.addingTimeInterval(86_400)
        c.ledger.foragedCurios = [ForagedCurioEntry(curioID: CurioCatalog.all[0].id, placeLabel: "巷口", weatherCode: "dusk", localDateISO: c.currentLocalDateISO)]
        XCTAssertTrue(c.giftCurio(entryID: c.ledger.foragedCurios[0].id, to: "pet.03"))
        let day6 = try XCTUnwrap(c.pendingMilestoneCelebration)
        XCTAssertEqual(day6.id, "bond.pet.03.tier3")
        XCTAssertTrue(day6.detail.contains("小禮物"))
        c.dismissMilestoneCelebration()

        // Day 10 via a street encounter: signature habit.
        pet.sharedDaysCount = 9
        c.currentSimulatedDate = c.currentSimulatedDate.addingTimeInterval(86_400)
        _ = try XCTUnwrap(c.commitStreetEncounter(siteID: "sys.luodong.bakery_corner", petID: "pet.03", gesture: .offerHand))
        let day10 = try XCTUnwrap(c.pendingMilestoneCelebration)
        XCTAssertEqual(day10.id, "bond.pet.03.tier4")
        XCTAssertTrue(day10.detail.contains(PetCatalog.pet(id: "pet.03").signatureHabitTitle))

        XCTAssertTrue(GameCoordinator.bondTierPerk(tier: 5, petID: "pet.03").contains("導師"))
        XCTAssertTrue(GameCoordinator.bondTierPerk(tier: 6, petID: "pet.03").contains("柱石"))
    }

    func testWelcomingNewCompanionCelebratesOnce() throws {
        let c = try makeInMemoryCoordinator()
        _ = try XCTUnwrap(c.commitStreetEncounter(siteID: "sys.luodong.bakery_corner", petID: "pet.07", gesture: .offerHand))
        let all = [c.pendingMilestoneCelebration].compactMap { $0 } + c.queuedMilestoneCelebrations
        XCTAssertTrue(all.contains { $0.id == "welcome.pet.07" && $0.kind == .newCompanion })
        XCTAssertTrue(c.indoorState.unlockedCelebratedFeatures.contains("welcome.pet.07"))
        while c.pendingMilestoneCelebration != nil { c.dismissMilestoneCelebration() }

        c.celebrateNewCompanionIfNeeded(petID: "pet.07")
        XCTAssertNil(c.pendingMilestoneCelebration, "A welcome is only ever celebrated once")
    }

    func testCelebrationsQueueInOrder() throws {
        let c = try makeInMemoryCoordinator()
        func make(_ id: String) -> MilestoneCelebration {
            MilestoneCelebration(id: id, kind: .stampCard, title: id, subtitle: "", detail: "", symbol: "seal.fill", accentHex: "#B84A39", rewardBadge: nil)
        }
        c.emitMilestoneCelebration(make("a"))
        c.emitMilestoneCelebration(make("b"))
        c.emitMilestoneCelebration(make("b"))
        XCTAssertEqual(c.pendingMilestoneCelebration?.id, "a")
        XCTAssertEqual(c.queuedMilestoneCelebrations.map(\.id), ["b"], "Duplicates are not queued twice")
        c.dismissMilestoneCelebration()
        XCTAssertEqual(c.pendingMilestoneCelebration?.id, "b")
        c.dismissMilestoneCelebration()
        XCTAssertNil(c.pendingMilestoneCelebration)
    }

    func testCurioSetClaimEmitsCelebration() throws {
        let c = try makeInMemoryCoordinator()
        let curios = CurioCatalog.all.filter { $0.weatherTag == .lightRain }
        c.ledger.foragedCurios = curios.map {
            ForagedCurioEntry(curioID: $0.id, placeLabel: "巷口", weatherCode: "light_rain", localDateISO: c.currentLocalDateISO)
        }
        XCTAssertTrue(c.claimCurioSetReward(weather: .lightRain))
        let celebration = try XCTUnwrap(c.pendingMilestoneCelebration)
        XCTAssertEqual(celebration.kind, .curioSet)
        XCTAssertEqual(celebration.id, "curioSet.light_rain")
        XCTAssertNotNil(celebration.rewardBadge)
    }

    func testRoomThemePurchaseAutoEquipsAndCelebrates() throws {
        let c = try makeInMemoryCoordinator()
        let rainy = try XCTUnwrap(ShopCatalog.item(id: "room.rainy_season"))
        c.ledger.coinBalance = rainy.priceCoins
        XCTAssertTrue(c.purchaseItem(rainy))
        XCTAssertEqual(c.ledger.coinBalance, 0)
        XCTAssertEqual(c.ledger.activeRoomTheme, .rainySeason, "A bought theme is equipped immediately")
        XCTAssertTrue(c.ledger.ownedRoomThemeIDs.contains(rainy.id))
        let celebration = try XCTUnwrap(c.pendingMilestoneCelebration)
        XCTAssertEqual(celebration.kind, .roomTheme)
        c.dismissMilestoneCelebration()

        c.selectRoomTheme(.springSunlit)
        XCTAssertEqual(c.ledger.activeRoomTheme, .springSunlit, "The free starter theme can always be re-applied")
        c.selectRoomTheme(.winterLamp)
        XCTAssertEqual(c.ledger.activeRoomTheme, .springSunlit, "Unowned themes can't be applied")

        let veranda = try XCTUnwrap(ShopCatalog.item(id: "room.rain_veranda"))
        c.ledger.coinBalance = veranda.priceCoins
        XCTAssertTrue(c.purchaseItem(veranda))
        XCTAssertEqual(c.pendingMilestoneCelebration?.kind, .veranda)
    }

    func testJourneyProgressSummary() throws {
        let c = try makeInMemoryCoordinator()
        let start = c.journeyProgress
        XCTAssertEqual(start.companionsInvited, 1)
        XCTAssertEqual(start.companionsTotal, PetCatalog.allPets.count)
        XCTAssertEqual(start.curiosDiscovered, 0)
        XCTAssertEqual(start.curiosTotal, CurioCatalog.all.count)
        XCTAssertEqual(start.weatherSetsTotal, WeatherMode.allCases.count)
        XCTAssertEqual(start.themesOwned, 1)

        let dusk = CurioCatalog.all.filter { $0.weatherTag == .dusk }
        c.ledger.foragedCurios = (dusk + dusk).map {
            ForagedCurioEntry(curioID: $0.id, placeLabel: "巷口", weatherCode: "dusk", localDateISO: c.currentLocalDateISO)
        }
        c.awardDailyCozyStampIfEligible(reason: "測試")
        let later = c.journeyProgress
        XCTAssertEqual(later.curiosDiscovered, dusk.count, "Duplicates count once")
        XCTAssertEqual(later.weatherSetsCompleted, 1)
        XCTAssertEqual(later.stampCountInCard, 1)
    }

    // MARK: - Economy tuning, clues & reset

    func testTunedShopPrices() throws {
        XCTAssertEqual(ShopCatalog.item(id: "room.rainy_season")?.priceCoins, 300)
        XCTAssertEqual(ShopCatalog.item(id: "room.autumn_cedar")?.priceCoins, 320)
        XCTAssertEqual(ShopCatalog.item(id: "room.winter_lamp")?.priceCoins, 350)
        XCTAssertEqual(ShopCatalog.item(id: "outfit.forager_satchel")?.priceCoins, 100)
    }

    func testDiscoveryCluesNeverSpoilNames() {
        for spec in PetCatalog.allPets {
            XCTAssertFalse(spec.discoveryClue.isEmpty)
            XCTAssertFalse(spec.discoveryClue.contains(spec.name), "\(spec.id) clue must not reveal its name")
        }
    }

    func testResetClearsCustomSpotCoordsAndCelebrations() throws {
        let c = try makeInMemoryCoordinator()
        let key = "pawprintdays.sunroom.customSpotCoords.v1"
        UserDefaults.standard.set(Data([1, 2, 3]), forKey: key)
        c.emitMilestoneCelebration(MilestoneCelebration(id: "x", kind: .stampCard, title: "", subtitle: "", detail: "", symbol: "seal", accentHex: "#000000", rewardBadge: nil))
        c.resetAllGameData()
        XCTAssertNil(UserDefaults.standard.object(forKey: key))
        XCTAssertNil(c.pendingMilestoneCelebration)
        XCTAssertEqual(c.indoorState.stampCountInCard, 0)
    }
}
