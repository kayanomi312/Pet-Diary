import XCTest
import SwiftData
@testable import PawprintDays

/// Guards the on-disk diary across schema changes.
///
/// Every shipped schema version gets a "store written by that version reopens through
/// `PawprintMigrationPlan` with its data intact" test. When V3 lands, add a V2 → V3 case
/// next to `testV2StoreReopensThroughMigrationPlanWithDataIntact` that asserts the transformed data.
@MainActor
final class SchemaMigrationTests: XCTestCase {

    /// XCTest creates a fresh instance per test, so each test gets its own directory.
    private nonisolated let storeDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("SchemaMigrationTests-\(UUID().uuidString)", isDirectory: true)

    override func setUpWithError() throws {
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: storeDirectory)
    }

    private var storeURL: URL {
        storeDirectory.appendingPathComponent("default.store")
    }

    // MARK: - Plan shape

    func testMigrationPlanEndsAtCurrentSchemaWithOneStagePerVersionStep() {
        let schemas = PawprintMigrationPlan.schemas
        XCTAssertFalse(schemas.isEmpty)
        XCTAssertTrue(
            schemas.last == PawprintPersistence.currentVersionedSchema,
            "The newest schema in PawprintMigrationPlan must be PawprintPersistence.currentVersionedSchema"
        )
        XCTAssertEqual(
            PawprintMigrationPlan.stages.count, schemas.count - 1,
            "Each consecutive pair of schema versions needs exactly one migration stage"
        )
        let versions = schemas.map { [$0.versionIdentifier.major, $0.versionIdentifier.minor, $0.versionIdentifier.patch] }
        for (older, newer) in zip(versions, versions.dropFirst()) {
            XCTAssertTrue(older.lexicographicallyPrecedes(newer), "Schema versions must be strictly increasing: \(older) → \(newer)")
        }
    }

    // MARK: - V2 store on disk → migration plan

    func testV2StoreReopensThroughMigrationPlanWithDataIntact() throws {
        let photo = Data((0..<4096).map { UInt8($0 % 251) }) // large enough to land in external storage
        let snapshotPNG = Data(repeating: 0xAB, count: 2048)
        let encounterID = UUID()
        let intentionID = UUID()
        let curio = ForagedCurioEntry(curioID: "curio.ginkgo_leaf", placeLabel: "麵包店轉角", weatherCode: WeatherMode.postRain.rawValue, localDateISO: "2026-11-20")
        let interval = StepIntervalRecord(intervalBucketUTC: 1_795_000_000, rawSteps: 812, highWaterAcceptedSteps: 800)
        var indoor = SunroomIndoorState()
        indoor.totalTeaBrewedCount = 7
        indoor.windowVisitCounts = ["pet.05": 2]

        // 1. Write a store exactly the way V2 builds did (versioned schema, no migration plan).
        try writeLegacyV2Store { context in
            let day = DiaryDayRecord(
                localDateISO: "2026-11-20",
                timeZoneID: "Asia/Taipei",
                acceptedSteps: 6_420,
                weatherCode: WeatherMode.postRain.rawValue,
                companionPetID: "pet.03",
                routeTrackGeoJSON: "{\"type\":\"LineString\"}",
                personalNote: "雨後和小火一起散步，聞到桂花香。",
                isStarredTradition: true
            )
            day.completedNeighborhoodLoop = true
            day.revisitNotes = ["黃昏又路過一次"]
            day.photoJPEGData = photo
            context.insert(day)

            let anchor = AnchorSiteRecord(
                siteID: "local.corner.test",
                lat: 24.676,
                lon: 121.766,
                customLabel: "麵包店轉角",
                regularPetID: "pet.03",
                cycleTapCount: 2,
                lastVisitedLocalDate: "2026-11-20",
                cachedVisitorOfferID: "pet.04",
                isFamiliarCorner: true
            )
            anchor.totalVisitsCount = 9
            context.insert(anchor)

            context.insert(EncounterLog(
                encounterUUID: encounterID,
                siteID: "local.corner.test",
                siteDisplayLabel: "麵包店轉角",
                localDateISO: "2026-11-20",
                timeZoneID: "Asia/Taipei",
                petID: "pet.03",
                secondaryPetID: "pet.04",
                sceneRevisionID: "scene.r2",
                gestureChosen: .rollBall,
                equippedOutfitSnapshotID: "outfit.raincoat",
                weatherSnapshot: .postRain,
                narrativeLine: "小火把縫布球推回你腳邊。",
                bakedSnapshotPNGData: snapshotPNG,
                isWideWatercolorSpread: true
            ))

            let resident = PetResidentState(
                petID: "pet.03",
                nickname: "小火",
                inviteState: .invitedHome,
                sharedDaysCount: 11,
                milestoneTier: 4,
                firstMetDateISO: "2026-11-01",
                firstGesture: .crouchQuietly,
                favoriteTexture: .warm,
                learnedHabitIDs: ["habit.patient_wait"],
                learnedHabitCredits: ["Learned Patient Wait from Sesame on 2026-11-21"],
                recentSceneIDs: ["scene.a", "scene.b"],
                isPinned: true
            )
            resident.kindredPracticeCompleted = true
            context.insert(resident)

            context.insert(HomeSpotPlacement(
                spotIndex: 6,
                spotName: "雨廊窗台",
                equippedGoodieID: "goodie.window_cushion",
                goodieUseCount: 26,
                hasStitchedPatch: true,
                currentOccupantPetIDs: ["pet.03", "pet.04"]
            ))

            context.insert(TeachingIntention(
                intentionUUID: intentionID,
                mentorPetID: "pet.04",
                learnerPetID: "pet.03",
                habitFamilyID: "habit.patient_wait",
                sharedPropID: "goodie.cloth_ball",
                stepsAccumulated: 1_800,
                state: .demonstrated,
                plannedDateISO: "2026-11-21"
            ))

            let ledger = WalletAndCurioLedger(
                coinBalance: 1_234,
                totalAcceptedStepsAllTime: 98_765,
                ownedOutfitIDs: ["outfit.raincoat"],
                processedTxIDs: ["tx.1", "tx.2"],
                foragedCurios: [curio],
                stepIntervals: [interval]
            )
            ledger.verandaUnlocked = true
            ledger.activeRoomThemeRaw = "room.autumn_lantern"
            ledger.indoorState = indoor
            context.insert(ledger)
        }

        // 2. Reopen through the migration plan, the way the app does now.
        let config = ModelConfiguration(schema: PawprintPersistence.currentSchema, url: storeURL)
        let container = try PawprintPersistence.makeContainer(configuration: config)
        let context = container.mainContext

        let day = try XCTUnwrap(context.fetch(FetchDescriptor<DiaryDayRecord>()).first)
        XCTAssertEqual(day.localDateISO, "2026-11-20")
        XCTAssertEqual(day.timeZoneID, "Asia/Taipei")
        XCTAssertEqual(day.acceptedSteps, 6_420)
        XCTAssertEqual(day.weatherMode, .postRain)
        XCTAssertEqual(day.companionPetID, "pet.03")
        XCTAssertEqual(day.personalNote, "雨後和小火一起散步，聞到桂花香。")
        XCTAssertTrue(day.isStarredTradition)
        XCTAssertTrue(day.completedNeighborhoodLoop)
        XCTAssertEqual(day.revisitNotes, ["黃昏又路過一次"])
        XCTAssertEqual(day.photoJPEGData, photo)

        let anchor = try XCTUnwrap(context.fetch(FetchDescriptor<AnchorSiteRecord>()).first)
        XCTAssertEqual(anchor.siteID, "local.corner.test")
        XCTAssertEqual(anchor.lat, 24.676, accuracy: 1e-9)
        XCTAssertEqual(anchor.cycleTapCount, 2)
        XCTAssertEqual(anchor.cachedVisitorOfferID, "pet.04")
        XCTAssertTrue(anchor.isFamiliarCorner)
        XCTAssertEqual(anchor.totalVisitsCount, 9)

        let encounter = try XCTUnwrap(context.fetch(FetchDescriptor<EncounterLog>()).first)
        XCTAssertEqual(encounter.encounterUUID, encounterID)
        XCTAssertEqual(encounter.siteDayKey, "local.corner.test|2026-11-20")
        XCTAssertEqual(encounter.gestureChosen, .rollBall)
        XCTAssertEqual(encounter.weatherSnapshot, .postRain)
        XCTAssertEqual(encounter.secondaryPetID, "pet.04")
        XCTAssertEqual(encounter.narrativeLine, "小火把縫布球推回你腳邊。")
        XCTAssertEqual(encounter.bakedSnapshotPNGData, snapshotPNG)
        XCTAssertTrue(encounter.isWideWatercolorSpread)

        let resident = try XCTUnwrap(context.fetch(FetchDescriptor<PetResidentState>()).first)
        XCTAssertEqual(resident.nickname, "小火")
        XCTAssertEqual(resident.inviteState, .invitedHome)
        XCTAssertEqual(resident.sharedDaysCount, 11)
        XCTAssertEqual(resident.milestoneTier, 4)
        XCTAssertEqual(resident.firstGesture, .crouchQuietly)
        XCTAssertEqual(resident.favoriteTexture, .warm)
        XCTAssertEqual(resident.learnedHabitIDs, ["habit.patient_wait"])
        XCTAssertEqual(resident.learnedHabitCredits, ["Learned Patient Wait from Sesame on 2026-11-21"])
        XCTAssertEqual(resident.recentSceneIDs, ["scene.a", "scene.b"])
        XCTAssertTrue(resident.isPinned)
        XCTAssertTrue(resident.kindredPracticeCompleted)

        let spot = try XCTUnwrap(context.fetch(FetchDescriptor<HomeSpotPlacement>()).first)
        XCTAssertEqual(spot.spotIndex, 6)
        XCTAssertEqual(spot.equippedGoodieID, "goodie.window_cushion")
        XCTAssertTrue(spot.hasLovedPatina)
        XCTAssertEqual(spot.currentOccupantPetIDs, ["pet.03", "pet.04"])

        let intention = try XCTUnwrap(context.fetch(FetchDescriptor<TeachingIntention>()).first)
        XCTAssertEqual(intention.intentionUUID, intentionID)
        XCTAssertEqual(intention.state, .demonstrated)
        XCTAssertEqual(intention.stepsAccumulated, 1_800)

        let ledger = try XCTUnwrap(context.fetch(FetchDescriptor<WalletAndCurioLedger>()).first)
        XCTAssertEqual(ledger.txUUID, "primary")
        XCTAssertEqual(ledger.coinBalance, 1_234)
        XCTAssertEqual(ledger.totalAcceptedStepsAllTime, 98_765)
        XCTAssertEqual(ledger.ownedOutfitIDs, ["outfit.raincoat"])
        XCTAssertEqual(ledger.processedTxIDs, ["tx.1", "tx.2"])
        XCTAssertTrue(ledger.verandaUnlocked)
        XCTAssertEqual(ledger.activeRoomThemeRaw, "room.autumn_lantern")
        XCTAssertEqual(ledger.foragedCurios, [curio])
        XCTAssertEqual(ledger.stepIntervals, [interval])
        XCTAssertEqual(ledger.indoorState.totalTeaBrewedCount, 7)
        XCTAssertEqual(ledger.indoorState.windowVisitCounts, ["pet.05": 2])

        // 3. The game boots on top of the migrated store without re-seeding over the player's data.
        let coordinator = GameCoordinator(modelContext: context, modelContainer: container)
        XCTAssertEqual(coordinator.ledger.coinBalance, 1_234)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WalletAndCurioLedger>()), 1)
        XCTAssertEqual(coordinator.resident(for: "pet.03")?.nickname, "小火")
        XCTAssertTrue(coordinator.diaryDays.contains { $0.localDateISO == "2026-11-20" && $0.acceptedSteps == 6_420 })
    }

    func testFreshStoreOpensThroughMigrationPlan() throws {
        let config = ModelConfiguration(schema: PawprintPersistence.currentSchema, url: storeURL)
        let container = try PawprintPersistence.makeContainer(configuration: config)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<DiaryDayRecord>()), 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
    }

    // MARK: - Helpers

    /// Creates a V2 store on disk the way pre-migration-plan builds opened it, then releases the container
    /// so the next open goes through the file on disk.
    private func writeLegacyV2Store(_ populate: (ModelContext) throws -> Void) throws {
        let schema = Schema(versionedSchema: PawprintSchemaV2.self)
        let config = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        try populate(context)
        try context.save()
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path), "Legacy V2 store was not written to disk")
    }
}
