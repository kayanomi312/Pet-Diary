import XCTest
import CoreData
import SwiftData
@testable import PawprintDays

/// Guards the on-disk diary across schema changes.
///
/// - `testFrozenV2FixtureReopensThroughMigrationPlan` opens `Fixtures/PawprintV2.store`, a binary
///   store written by the V2 schema and checked in. It never gets regenerated, so if anyone changes a
///   stored property without adding a new schema version, this test fails, just as players' stores would.
/// - `testV2SchemaStillMatchesFrozenFixtureVersionHashes` compares Core Data entity version hashes, so it
///   also catches *added* optional/defaulted properties and new entities, which the reopen test cannot see.
/// - `testRuntimeV2StoreReopensThroughMigrationPlan` writes the same sample through the V2 schema at
///   runtime (catches API-level regressions in the open path).
/// - When V3 lands: freeze V2's models as `PawprintSchemaV2.*` nested types, point the V2 helpers below
///   (`V2Sample.populate` / `assertIntact`, `writeLegacyV2Store`) at those types, and add a V2 → V3 test
///   asserting the transformed data. The fixture test then becomes the real V2 → V3 migration test.
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

    // MARK: - V2 stores → migration plan

    func testFrozenV2FixtureReopensThroughMigrationPlan() throws {
        let fixture = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "PawprintV2", withExtension: "store"),
            "Fixtures/PawprintV2.store missing from the test bundle"
        )
        try FileManager.default.copyItem(at: fixture, to: storeURL)

        let container = try openThroughPlan()
        try V2Sample.assertIntact(in: container.mainContext)
    }

    /// Opening the fixture only proves existing columns survive; an *added* optional or defaulted
    /// property (or a new entity) would be silently migrated in and every assertion would still pass.
    /// Comparing Core Data's per-entity version hashes catches any un-versioned edit to V2: the hashes
    /// recorded in the frozen fixture must equal those of a store created from `PawprintSchemaV2` today.
    func testV2SchemaStillMatchesFrozenFixtureVersionHashes() throws {
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "PawprintV2", withExtension: "store"))
        let shipped = try Self.entityVersionHashes(ofStoreAt: fixture)

        let freshURL = storeDirectory.appendingPathComponent("fresh-v2.store")
        try autoreleasepool {
            let schema = Schema(versionedSchema: PawprintSchemaV2.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: freshURL)])
            try ModelContext(container).save()
        }
        let current = try Self.entityVersionHashes(ofStoreAt: freshURL)

        XCTAssertEqual(Set(current.keys), Set(shipped.keys), "PawprintSchemaV2 entities changed; add a new schema version instead")
        for (entity, hash) in shipped where current[entity] != hash {
            XCTFail("PawprintSchemaV2.\(entity) no longer matches shipped V2 stores; freeze V2 and add a new schema version instead of editing it")
        }
    }

    func testRuntimeV2StoreReopensThroughMigrationPlan() throws {
        try writeLegacyV2Store(V2Sample.populate)

        let container = try openThroughPlan()
        let context = container.mainContext
        try V2Sample.assertIntact(in: context)

        // The game boots on top of the migrated store without re-seeding over the player's data.
        let coordinator = GameCoordinator(modelContext: context, modelContainer: container)
        XCTAssertEqual(coordinator.ledger.coinBalance, V2Sample.coinBalance)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WalletAndCurioLedger>()), 1)
        XCTAssertEqual(coordinator.resident(for: "pet.03")?.nickname, "小火")
        XCTAssertTrue(coordinator.diaryDays.contains { $0.localDateISO == "2026-11-20" && $0.acceptedSteps == 6_420 })
    }

    func testFreshStoreOpensThroughMigrationPlan() throws {
        let container = try openThroughPlan()
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<DiaryDayRecord>()), 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
    }

    // MARK: - Failure diagnostics

    func testFailedMigrationIsClassifiedAsMigrationFailure() throws {
        // An older-shaped `DiaryDayRecord` row with no value for attributes that are mandatory (and have
        // no default) in the current schema: inferred migration can't fill them, so opening must fail
        // with a Core Data migration error wrapped inside SwiftDataError.
        let legacySchema = Schema(versionedSchema: UnmigratableSchemaV1.self)
        do {
            let container = try ModelContainer(for: legacySchema, configurations: [ModelConfiguration(schema: legacySchema, url: storeURL)])
            container.mainContext.insert(UnmigratableSchemaV1.DiaryDayRecord(localDateISO: "2026-01-01"))
            try container.mainContext.save()
        }

        do {
            _ = try openThroughPlan()
            XCTFail("Opening a store whose rows can't be migrated must fail")
        } catch {
            let chain = PawprintPersistence.errorChain(error)
            let codes = chain.map { "\($0.domain)#\($0.code)" }
            XCTAssertTrue(
                PawprintPersistence.isMigrationFailure(error),
                "Expected a Core Data migration code somewhere in the chain, got \(codes)"
            )
            XCTAssertTrue(chain.contains { $0.domain == NSCocoaErrorDomain }, "SwiftDataError must be unwrapped to its Cocoa error: \(codes)")
        }
    }

    func testErrorChainFollowsUserInfoNesting() {
        let inner = NSError(domain: NSCocoaErrorDomain, code: 134_110, userInfo: ["reason": "Can't find mapping model"])
        let outer = NSError(domain: "Outer", code: 1, userInfo: [NSUnderlyingErrorKey: inner])
        XCTAssertEqual(PawprintPersistence.errorChain(outer).map(\.code), [1, 134_110])
        XCTAssertTrue(PawprintPersistence.isMigrationFailure(outer))
        XCTAssertEqual(PawprintPersistence.failureReason(of: inner), "Can't find mapping model")
        XCTAssertFalse(PawprintPersistence.isMigrationFailure(NSError(domain: NSCocoaErrorDomain, code: 4)))
        // NSSQLiteError (I/O, disk full, corruption) is not a migration failure even though it sits in 1341xx.
        XCTAssertEqual(PawprintPersistence.sqliteErrorCode, NSSQLiteError)
        let sqlite = NSError(domain: "Outer", code: 1, userInfo: [NSUnderlyingErrorKey: NSError(domain: NSCocoaErrorDomain, code: NSSQLiteError)])
        XCTAssertFalse(PawprintPersistence.isMigrationFailure(sqlite))
    }

    // MARK: - Helpers

    private static func entityVersionHashes(ofStoreAt url: URL) throws -> [String: Data] {
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: url)
        return try XCTUnwrap(metadata[NSStoreModelVersionHashesKey] as? [String: Data], "No entity version hashes in \(url.lastPathComponent)")
    }

    private func openThroughPlan() throws -> ModelContainer {
        let config = ModelConfiguration(schema: PawprintPersistence.currentSchema, url: storeURL)
        return try PawprintPersistence.makeContainer(configuration: config)
    }

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

/// A pre-V2-shaped schema whose `DiaryDayRecord` lacks mandatory V2 attributes, used to force a real
/// migration failure. (A store whose entities are simply *unknown* does not fail: SwiftData falls back
/// to inferred lightweight migration and drops them.)
private enum UnmigratableSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [DiaryDayRecord.self] }

    @Model final class DiaryDayRecord {
        var localDateISO: String
        init(localDateISO: String) { self.localDateISO = localDateISO }
    }
}

// MARK: - V2 sample data (every stored property set to a non-default value)

/// The data inside `Fixtures/PawprintV2.store`. Don't change these values: the fixture is frozen.
@MainActor
enum V2Sample {
    static let coinBalance = 1_234
    static let photo = Data((0..<4096).map { UInt8($0 % 251) })
    static let snapshotPNG = Data(repeating: 0xAB, count: 2048)
    static let encounterID = UUID(uuidString: "6F1C9E0A-2B44-4C55-9D66-7E8F90A1B2C3")!
    static let intentionID = UUID(uuidString: "0A1B2C3D-4E5F-4061-8273-94A5B6C7D8E9")!
    static let postcardID = UUID(uuidString: "11111111-2222-4333-8444-555566667777")!
    static let curio = ForagedCurioEntry(
        id: UUID(uuidString: "AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE")!,
        curioID: "curio.ginkgo_leaf",
        placeLabel: "麵包店轉角",
        weatherCode: "post_rain",
        localDateISO: "2026-11-20"
    )
    static let interval = StepIntervalRecord(intervalBucketUTC: 1_795_000_000, rawSteps: 812, highWaterAcceptedSteps: 800)
    static let createdAt = Date(timeIntervalSince1970: 1_795_100_000)
    static let solvedAt = Date(timeIntervalSince1970: 1_795_200_000)
    static let seenAt = Date(timeIntervalSince1970: 1_795_300_000)
    static let teaUntil = Date(timeIntervalSince1970: 1_795_400_000)

    static var indoor: SunroomIndoorState {
        var state = SunroomIndoorState()
        state.totalTeaBrewedCount = 7
        state.windowVisitCounts = ["pet.05": 2]
        state.pinnedPostcardEncounterID = postcardID
        state.hasPlacedDoorstepCorner = true
        return state
    }

    static func populate(_ context: ModelContext) throws {
        let day = DiaryDayRecord(
            localDateISO: "2026-11-20",
            timeZoneID: "Asia/Taipei",
            acceptedSteps: 6_420,
            weatherCode: "post_rain",
            weatherAttribution: "Apple Weather · 羅東",
            companionPetID: "pet.03",
            routeTrackGeoJSON: "{\"type\":\"LineString\"}",
            personalNote: "雨後和小火一起散步，聞到桂花香。",
            isStarredTradition: true,
            deletionState: .placeErased,
            linkedTraditionDateISO: "2025-11-20"
        )
        day.completedNeighborhoodLoop = true
        day.revisitNotes = ["黃昏又路過一次"]
        day.photoJPEGData = photo
        context.insert(day)

        let anchor = AnchorSiteRecord(
            siteID: "local.corner.test",
            lat: 24.676,
            lon: 121.766,
            radiusM: 60,
            customLabel: "麵包店轉角",
            regularPetID: "pet.03",
            cycleTapCount: 2,
            lastVisitedLocalDate: "2026-11-20",
            cachedVisitorOfferID: "pet.04",
            isFamiliarCorner: true,
            isHiddenByUser: true
        )
        anchor.totalVisitsCount = 9
        anchor.lastRevisitTimeBand = "dusk"
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
            secondaryOutfitSnapshotID: "outfit.scarf",
            weatherSnapshot: .postRain,
            narrativeLine: "小火把縫布球推回你腳邊。",
            bakedSnapshotPNGData: snapshotPNG,
            strollChainTargetSiteID: "sys.luodong.riverside_bench",
            isWideWatercolorSpread: true,
            placeRedacted: true,
            createdAtUTC: createdAt
        ))

        let resident = PetResidentState(
            petID: "pet.03",
            nickname: "小火",
            inviteState: .invitedHome,
            sharedDaysCount: 11,
            milestoneTier: 4,
            firstMetDateISO: "2026-11-01",
            lastSharedDateISO: "2026-11-20",
            firstGesture: .crouchQuietly,
            favoriteTexture: .warm,
            activeOutfitID: "outfit.raincoat",
            learnedHabitIDs: ["habit.patient_wait"],
            learnedHabitCredits: ["Learned Patient Wait from Sesame on 2026-11-21"],
            recentSceneIDs: ["scene.a", "scene.b"],
            isPinned: true,
            lastSeenInHomeUTC: seenAt
        )
        resident.kindredPracticeCompleted = true
        resident.kindredChoiceNote = "心照不宣練習"
        context.insert(resident)

        context.insert(HomeSpotPlacement(
            spotIndex: 6,
            spotName: "雨廊窗台",
            equippedGoodieID: "goodie.window_cushion",
            goodieUseCount: 26,
            hasStitchedPatch: true,
            activeSnackID: "snack.millet",
            currentOccupantPetIDs: ["pet.03", "pet.04"],
            lastSolvedUTC: solvedAt
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
            stepCarryRemainder: 42,
            pocketFindStepProgress: 900,
            coinBalance: coinBalance,
            totalAcceptedStepsAllTime: 98_765,
            pilotTap3MagicalDelivered: true,
            ownedGoodieIDs: ["goodie.folded_towel", "goodie.hearth_brazier"],
            ownedOutfitIDs: ["outfit.raincoat"],
            processedTxIDs: ["tx.1", "tx.2"],
            foragedCurios: [curio],
            stepIntervals: [interval]
        )
        ledger.ownedRoomThemeIDs = ["room.spring_sunlit", "room.autumn_lantern"]
        ledger.activeRoomThemeRaw = "room.autumn_lantern"
        ledger.verandaUnlocked = true
        ledger.activeOutingPackRaw = "outing.towel_pack"
        ledger.pedometerOptIn = true
        ledger.backgroundVisitsOptIn = true
        ledger.mobilityRollModeEnabled = true
        ledger.mobilityDistanceCarryM = 12.5
        ledger.mobilityDwellCarrySec = 30.25
        ledger.lastNeighborhoodLat = 24.677
        ledger.lastNeighborhoodLon = 121.767
        ledger.activeStrollChainTargetSiteID = "sys.luodong.riverside_bench"
        ledger.activeStrollChainGuidePetID = "pet.03"
        ledger.activeStrollChainDateISO = "2026-11-20"
        ledger.gingerTeaActiveUntil = teaUntil
        ledger.indoorState = indoor
        context.insert(ledger)
    }

    static func assertIntact(in context: ModelContext, file: StaticString = #filePath, line: UInt = #line) throws {
        let day = try XCTUnwrap(context.fetch(FetchDescriptor<DiaryDayRecord>()).first, file: file, line: line)
        XCTAssertEqual(day.localDateISO, "2026-11-20", file: file, line: line)
        XCTAssertEqual(day.timeZoneID, "Asia/Taipei", file: file, line: line)
        XCTAssertEqual(day.acceptedSteps, 6_420, file: file, line: line)
        XCTAssertEqual(day.weatherCode, "post_rain", file: file, line: line)
        XCTAssertEqual(day.weatherAttribution, "Apple Weather · 羅東", file: file, line: line)
        XCTAssertEqual(day.companionPetID, "pet.03", file: file, line: line)
        XCTAssertEqual(day.routeTrackGeoJSON, "{\"type\":\"LineString\"}", file: file, line: line)
        XCTAssertEqual(day.personalNote, "雨後和小火一起散步，聞到桂花香。", file: file, line: line)
        XCTAssertTrue(day.isStarredTradition, file: file, line: line)
        XCTAssertEqual(day.deletionStateRaw, "placeErased", file: file, line: line)
        XCTAssertEqual(day.linkedTraditionDateISO, "2025-11-20", file: file, line: line)
        XCTAssertTrue(day.completedNeighborhoodLoop, file: file, line: line)
        XCTAssertEqual(day.revisitNotes, ["黃昏又路過一次"], file: file, line: line)
        XCTAssertEqual(day.photoJPEGData, photo, file: file, line: line)

        let anchor = try XCTUnwrap(context.fetch(FetchDescriptor<AnchorSiteRecord>()).first, file: file, line: line)
        XCTAssertEqual(anchor.siteID, "local.corner.test", file: file, line: line)
        XCTAssertEqual(anchor.lat, 24.676, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(anchor.lon, 121.766, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(anchor.radiusM, 60, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(anchor.customLabel, "麵包店轉角", file: file, line: line)
        XCTAssertEqual(anchor.regularPetID, "pet.03", file: file, line: line)
        XCTAssertEqual(anchor.cycleTapCount, 2, file: file, line: line)
        XCTAssertEqual(anchor.lastVisitedLocalDate, "2026-11-20", file: file, line: line)
        XCTAssertEqual(anchor.cachedVisitorOfferID, "pet.04", file: file, line: line)
        XCTAssertTrue(anchor.isFamiliarCorner, file: file, line: line)
        XCTAssertTrue(anchor.isHiddenByUser, file: file, line: line)
        XCTAssertEqual(anchor.totalVisitsCount, 9, file: file, line: line)
        XCTAssertEqual(anchor.lastRevisitTimeBand, "dusk", file: file, line: line)

        let encounter = try XCTUnwrap(context.fetch(FetchDescriptor<EncounterLog>()).first, file: file, line: line)
        XCTAssertEqual(encounter.encounterUUID, encounterID, file: file, line: line)
        XCTAssertEqual(encounter.siteDayKey, "local.corner.test|2026-11-20", file: file, line: line)
        XCTAssertEqual(encounter.siteID, "local.corner.test", file: file, line: line)
        XCTAssertEqual(encounter.siteDisplayLabel, "麵包店轉角", file: file, line: line)
        XCTAssertEqual(encounter.localDateISO, "2026-11-20", file: file, line: line)
        XCTAssertEqual(encounter.timeZoneID, "Asia/Taipei", file: file, line: line)
        XCTAssertEqual(encounter.petID, "pet.03", file: file, line: line)
        XCTAssertEqual(encounter.secondaryPetID, "pet.04", file: file, line: line)
        XCTAssertEqual(encounter.sceneRevisionID, "scene.r2", file: file, line: line)
        XCTAssertEqual(encounter.gestureChosenRaw, "roll_ball", file: file, line: line)
        XCTAssertEqual(encounter.equippedOutfitSnapshotID, "outfit.raincoat", file: file, line: line)
        XCTAssertEqual(encounter.secondaryOutfitSnapshotID, "outfit.scarf", file: file, line: line)
        XCTAssertEqual(encounter.weatherSnapshotCode, "post_rain", file: file, line: line)
        XCTAssertEqual(encounter.narrativeLine, "小火把縫布球推回你腳邊。", file: file, line: line)
        XCTAssertEqual(encounter.bakedSnapshotPNGData, snapshotPNG, file: file, line: line)
        XCTAssertEqual(encounter.strollChainTargetSiteID, "sys.luodong.riverside_bench", file: file, line: line)
        XCTAssertTrue(encounter.isWideWatercolorSpread, file: file, line: line)
        XCTAssertTrue(encounter.placeRedacted, file: file, line: line)
        XCTAssertEqual(encounter.createdAtUTC, createdAt, file: file, line: line)

        let resident = try XCTUnwrap(context.fetch(FetchDescriptor<PetResidentState>()).first, file: file, line: line)
        XCTAssertEqual(resident.petID, "pet.03", file: file, line: line)
        XCTAssertEqual(resident.nickname, "小火", file: file, line: line)
        XCTAssertEqual(resident.inviteStateRaw, "invitedHome", file: file, line: line)
        XCTAssertEqual(resident.sharedDaysCount, 11, file: file, line: line)
        XCTAssertEqual(resident.milestoneTier, 4, file: file, line: line)
        XCTAssertEqual(resident.firstMetDateISO, "2026-11-01", file: file, line: line)
        XCTAssertEqual(resident.lastSharedDateISO, "2026-11-20", file: file, line: line)
        XCTAssertEqual(resident.firstGestureRaw, "crouch_quietly", file: file, line: line)
        XCTAssertEqual(resident.favoriteTextureRaw, "溫熱", file: file, line: line)
        XCTAssertEqual(resident.activeOutfitID, "outfit.raincoat", file: file, line: line)
        XCTAssertEqual(resident.learnedHabitIDs, ["habit.patient_wait"], file: file, line: line)
        XCTAssertEqual(resident.learnedHabitCredits, ["Learned Patient Wait from Sesame on 2026-11-21"], file: file, line: line)
        XCTAssertEqual(resident.recentSceneIDs, ["scene.a", "scene.b"], file: file, line: line)
        XCTAssertTrue(resident.isPinned, file: file, line: line)
        XCTAssertEqual(resident.lastSeenInHomeUTC, seenAt, file: file, line: line)
        XCTAssertTrue(resident.kindredPracticeCompleted, file: file, line: line)
        XCTAssertEqual(resident.kindredChoiceNote, "心照不宣練習", file: file, line: line)

        let spot = try XCTUnwrap(context.fetch(FetchDescriptor<HomeSpotPlacement>()).first, file: file, line: line)
        XCTAssertEqual(spot.spotIndex, 6, file: file, line: line)
        XCTAssertEqual(spot.spotName, "雨廊窗台", file: file, line: line)
        XCTAssertEqual(spot.equippedGoodieID, "goodie.window_cushion", file: file, line: line)
        XCTAssertEqual(spot.goodieUseCount, 26, file: file, line: line)
        XCTAssertTrue(spot.hasStitchedPatch, file: file, line: line)
        XCTAssertEqual(spot.activeSnackID, "snack.millet", file: file, line: line)
        XCTAssertEqual(spot.currentOccupantPetIDs, ["pet.03", "pet.04"], file: file, line: line)
        XCTAssertEqual(spot.lastSolvedUTC, solvedAt, file: file, line: line)

        let intention = try XCTUnwrap(context.fetch(FetchDescriptor<TeachingIntention>()).first, file: file, line: line)
        XCTAssertEqual(intention.intentionUUID, intentionID, file: file, line: line)
        XCTAssertEqual(intention.mentorPetID, "pet.04", file: file, line: line)
        XCTAssertEqual(intention.learnerPetID, "pet.03", file: file, line: line)
        XCTAssertEqual(intention.habitFamilyID, "habit.patient_wait", file: file, line: line)
        XCTAssertEqual(intention.sharedPropID, "goodie.cloth_ball", file: file, line: line)
        XCTAssertEqual(intention.stepsAccumulated, 1_800, file: file, line: line)
        XCTAssertEqual(intention.stateRaw, "demonstrated", file: file, line: line)
        XCTAssertEqual(intention.plannedDateISO, "2026-11-21", file: file, line: line)

        let ledger = try XCTUnwrap(context.fetch(FetchDescriptor<WalletAndCurioLedger>()).first, file: file, line: line)
        XCTAssertEqual(ledger.txUUID, "primary", file: file, line: line)
        XCTAssertEqual(ledger.stepCarryRemainder, 42, file: file, line: line)
        XCTAssertEqual(ledger.pocketFindStepProgress, 900, file: file, line: line)
        XCTAssertEqual(ledger.coinBalance, coinBalance, file: file, line: line)
        XCTAssertEqual(ledger.totalAcceptedStepsAllTime, 98_765, file: file, line: line)
        XCTAssertTrue(ledger.pilotTap3MagicalDelivered, file: file, line: line)
        XCTAssertEqual(ledger.ownedGoodieIDs, ["goodie.folded_towel", "goodie.hearth_brazier"], file: file, line: line)
        XCTAssertEqual(ledger.ownedOutfitIDs, ["outfit.raincoat"], file: file, line: line)
        XCTAssertEqual(ledger.ownedRoomThemeIDs, ["room.spring_sunlit", "room.autumn_lantern"], file: file, line: line)
        XCTAssertEqual(ledger.activeRoomThemeRaw, "room.autumn_lantern", file: file, line: line)
        XCTAssertTrue(ledger.verandaUnlocked, file: file, line: line)
        XCTAssertEqual(ledger.activeOutingPackRaw, "outing.towel_pack", file: file, line: line)
        XCTAssertTrue(ledger.pedometerOptIn, file: file, line: line)
        XCTAssertTrue(ledger.backgroundVisitsOptIn, file: file, line: line)
        XCTAssertTrue(ledger.mobilityRollModeEnabled, file: file, line: line)
        XCTAssertEqual(ledger.mobilityDistanceCarryM, 12.5, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(ledger.mobilityDwellCarrySec, 30.25, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(ledger.lastNeighborhoodLat ?? 0, 24.677, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(ledger.lastNeighborhoodLon ?? 0, 121.767, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(ledger.activeStrollChainTargetSiteID, "sys.luodong.riverside_bench", file: file, line: line)
        XCTAssertEqual(ledger.activeStrollChainGuidePetID, "pet.03", file: file, line: line)
        XCTAssertEqual(ledger.activeStrollChainDateISO, "2026-11-20", file: file, line: line)
        XCTAssertEqual(ledger.processedTxIDs, ["tx.1", "tx.2"], file: file, line: line)
        XCTAssertEqual(ledger.foragedCurios, [curio], file: file, line: line)
        XCTAssertEqual(ledger.stepIntervals, [interval], file: file, line: line)
        XCTAssertEqual(ledger.gingerTeaActiveUntil, teaUntil, file: file, line: line)
        let indoorState = ledger.indoorState
        XCTAssertEqual(indoorState.totalTeaBrewedCount, 7, file: file, line: line)
        XCTAssertEqual(indoorState.windowVisitCounts, ["pet.05": 2], file: file, line: line)
        XCTAssertEqual(indoorState.pinnedPostcardEncounterID, postcardID, file: file, line: line)
        XCTAssertTrue(indoorState.hasPlacedDoorstepCorner, file: file, line: line)
    }
}
