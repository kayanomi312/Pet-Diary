import Foundation
import SwiftData

// MARK: - 1. DiaryDayRecord
@Model
final class DiaryDayRecord {
    @Attribute(.unique) var localDateISO: String
    var timeZoneID: String
    var acceptedSteps: Int
    var weatherCode: String
    var weatherAttribution: String
    var companionPetID: String?
    var routeTrackGeoJSON: String?
    var personalNote: String
    var isStarredTradition: Bool
    var deletionStateRaw: String
    var linkedTraditionDateISO: String?
    var completedNeighborhoodLoop: Bool = false
    var revisitNotes: [String] = []
    @Attribute(.externalStorage) var photoJPEGData: Data? = nil

    init(
        localDateISO: String,
        timeZoneID: String = TimeZone.current.identifier,
        acceptedSteps: Int = 0,
        weatherCode: String = WeatherMode.lightRain.rawValue,
        weatherAttribution: String = "Weather Fixture · Neighborhood",
        companionPetID: String? = nil,
        routeTrackGeoJSON: String? = nil,
        personalNote: String = "",
        isStarredTradition: Bool = false,
        deletionState: DeletionState = .active,
        linkedTraditionDateISO: String? = nil
    ) {
        self.localDateISO = localDateISO
        self.timeZoneID = timeZoneID
        self.acceptedSteps = acceptedSteps
        self.weatherCode = weatherCode
        self.weatherAttribution = weatherAttribution
        self.companionPetID = companionPetID
        self.routeTrackGeoJSON = routeTrackGeoJSON
        self.personalNote = personalNote
        self.isStarredTradition = isStarredTradition
        self.deletionStateRaw = deletionState.rawValue
        self.linkedTraditionDateISO = linkedTraditionDateISO
    }

    var weatherMode: WeatherMode {
        get { WeatherMode(rawValue: weatherCode) ?? .overcast }
        set { weatherCode = newValue.rawValue }
    }

    var deletionState: DeletionState {
        get { DeletionState(rawValue: deletionStateRaw) ?? .active }
        set { deletionStateRaw = newValue.rawValue }
    }
}

// MARK: - 2. AnchorSiteRecord
@Model
final class AnchorSiteRecord {
    @Attribute(.unique) var siteID: String // sys.* or local.corner.*
    var lat: Double
    var lon: Double
    var radiusM: Double
    var customLabel: String
    var regularPetID: String
    var cycleTapCount: Int // 0..3 (2-1-1 deterministic rotation)
    var lastVisitedLocalDate: String?
    var cachedVisitorOfferID: String?
    var isFamiliarCorner: Bool
    var isHiddenByUser: Bool = false
    var totalVisitsCount: Int = 0
    var lastRevisitTimeBand: String? = nil

    var familiarityTitle: String {
        switch totalVisitsCount {
        case 0...2: return "初訪街角"
        case 3...6: return "常去轉角"
        case 7...14: return "老街熟面孔"
        default: return "街角秘密基地"
        }
    }

    init(
        siteID: String,
        lat: Double,
        lon: Double,
        radiusM: Double = 75.0,
        customLabel: String,
        regularPetID: String,
        cycleTapCount: Int = 0,
        lastVisitedLocalDate: String? = nil,
        cachedVisitorOfferID: String? = nil,
        isFamiliarCorner: Bool = false,
        isHiddenByUser: Bool = false
    ) {
        self.siteID = siteID
        self.lat = lat
        self.lon = lon
        self.radiusM = radiusM
        self.customLabel = customLabel
        self.regularPetID = regularPetID
        self.cycleTapCount = cycleTapCount
        self.lastVisitedLocalDate = lastVisitedLocalDate
        self.cachedVisitorOfferID = cachedVisitorOfferID
        self.isFamiliarCorner = isFamiliarCorner
        self.isHiddenByUser = isHiddenByUser
    }
}

// MARK: - 3. EncounterLog
@Model
final class EncounterLog {
    @Attribute(.unique) var encounterUUID: UUID
    /// Enforces Unique(siteID, localDateISO) site-day deduplication atomically
    @Attribute(.unique) var siteDayKey: String
    var siteID: String
    var siteDisplayLabel: String
    var localDateISO: String
    var timeZoneID: String
    var petID: String
    var secondaryPetID: String?
    var sceneRevisionID: String
    var gestureChosenRaw: String
    var equippedOutfitSnapshotID: String?
    var secondaryOutfitSnapshotID: String?
    var weatherSnapshotCode: String
    var narrativeLine: String
    @Attribute(.externalStorage) var bakedSnapshotPNGData: Data?
    var strollChainTargetSiteID: String?
    var isWideWatercolorSpread: Bool = false
    var placeRedacted: Bool
    var createdAtUTC: Date

    init(
        encounterUUID: UUID = UUID(),
        siteID: String,
        siteDisplayLabel: String,
        localDateISO: String,
        timeZoneID: String = TimeZone.current.identifier,
        petID: String,
        secondaryPetID: String? = nil,
        sceneRevisionID: String,
        gestureChosen: GreetingGesture,
        equippedOutfitSnapshotID: String?,
        secondaryOutfitSnapshotID: String? = nil,
        weatherSnapshot: WeatherMode,
        narrativeLine: String,
        bakedSnapshotPNGData: Data? = nil,
        strollChainTargetSiteID: String? = nil,
        isWideWatercolorSpread: Bool = false,
        placeRedacted: Bool = false,
        createdAtUTC: Date = Date()
    ) {
        self.encounterUUID = encounterUUID
        self.siteDayKey = "\(siteID)|\(localDateISO)"
        self.siteID = siteID
        self.siteDisplayLabel = siteDisplayLabel
        self.localDateISO = localDateISO
        self.timeZoneID = timeZoneID
        self.petID = petID
        self.secondaryPetID = secondaryPetID
        self.sceneRevisionID = sceneRevisionID
        self.gestureChosenRaw = gestureChosen.rawValue
        self.equippedOutfitSnapshotID = equippedOutfitSnapshotID
        self.secondaryOutfitSnapshotID = secondaryOutfitSnapshotID
        self.weatherSnapshotCode = weatherSnapshot.rawValue
        self.narrativeLine = narrativeLine
        self.bakedSnapshotPNGData = bakedSnapshotPNGData
        self.strollChainTargetSiteID = strollChainTargetSiteID
        self.isWideWatercolorSpread = isWideWatercolorSpread
        self.placeRedacted = placeRedacted
        self.createdAtUTC = createdAtUTC
    }

    var gestureChosen: GreetingGesture {
        GreetingGesture(rawValue: gestureChosenRaw) ?? .offerHand
    }

    var weatherSnapshot: WeatherMode {
        WeatherMode(rawValue: weatherSnapshotCode) ?? .overcast
    }
}

// MARK: - 4. PetResidentState
@Model
final class PetResidentState {
    @Attribute(.unique) var petID: String // pet.01..pet.08
    var nickname: String
    var inviteStateRaw: String
    var sharedDaysCount: Int
    var milestoneTier: Int // 1..6
    var firstMetDateISO: String?
    var lastSharedDateISO: String?
    var firstGestureRaw: String?
    var favoriteTextureRaw: String?
    var activeOutfitID: String?
    var learnedHabitIDs: [String]
    var learnedHabitCredits: [String] = [] // e.g. "Learned Patient Wait from Sesame on 2026-11-21"
    var recentSceneIDs: [String]
    var isPinned: Bool
    var lastSeenInHomeUTC: Date?
    var kindredPracticeCompleted: Bool = false
    var kindredChoiceNote: String? = nil

    init(
        petID: String,
        nickname: String,
        inviteState: InviteState = .unmet,
        sharedDaysCount: Int = 0,
        milestoneTier: Int = 0,
        firstMetDateISO: String? = nil,
        lastSharedDateISO: String? = nil,
        firstGesture: GreetingGesture? = nil,
        favoriteTexture: FoodTexture? = nil,
        activeOutfitID: String? = nil,
        learnedHabitIDs: [String] = [],
        learnedHabitCredits: [String] = [],
        recentSceneIDs: [String] = [],
        isPinned: Bool = false,
        lastSeenInHomeUTC: Date? = nil
    ) {
        self.petID = petID
        self.nickname = nickname
        self.inviteStateRaw = inviteState.rawValue
        self.sharedDaysCount = sharedDaysCount
        self.milestoneTier = milestoneTier
        self.firstMetDateISO = firstMetDateISO
        self.lastSharedDateISO = lastSharedDateISO
        self.firstGestureRaw = firstGesture?.rawValue
        self.favoriteTextureRaw = favoriteTexture?.rawValue
        self.activeOutfitID = activeOutfitID
        self.learnedHabitIDs = learnedHabitIDs
        self.learnedHabitCredits = learnedHabitCredits
        self.recentSceneIDs = recentSceneIDs
        self.isPinned = isPinned
        self.lastSeenInHomeUTC = lastSeenInHomeUTC
    }

    var inviteState: InviteState {
        get { InviteState(rawValue: inviteStateRaw) ?? .unmet }
        set { inviteStateRaw = newValue.rawValue }
    }

    var firstGesture: GreetingGesture? {
        get { firstGestureRaw.flatMap(GreetingGesture.init(rawValue:)) }
        set { firstGestureRaw = newValue?.rawValue }
    }

    var favoriteTexture: FoodTexture? {
        get { favoriteTextureRaw.flatMap(FoodTexture.init(rawValue:)) }
        set { favoriteTextureRaw = newValue?.rawValue }
    }

    /// Recomputes qualitative milestone tier strictly from Shared Days (zero XP bars)
    static func milestoneForSharedDays(_ days: Int) -> Int {
        switch days {
        case ..<1: return 0
        case 1...2: return 1 // First Met
        case 3...5: return 2 // Familiar
        case 6...9: return 3 // Companion
        case 10...14: return 4 // Kindred
        case 15...24: return 5 // Mentor
        default: return 6 // Pillar
        }
    }

    var milestoneTitle: String {
        switch milestoneTier {
        case 1: return "初次相遇"
        case 2: return "熟悉面孔"
        case 3: return "散步同伴"
        case 4: return "心照不宣"
        case 5: return "溫柔導師"
        case 6: return "街角柱石"
        default: return "尚未遇見"
        }
    }
}

// MARK: - 5. HomeSpotPlacement
@Model
final class HomeSpotPlacement {
    @Attribute(.unique) var spotIndex: Int // 1..5 starter, 6..8 Rain-Porch Veranda
    var spotName: String
    var equippedGoodieID: String?
    var goodieUseCount: Int // 0..25+ Loved Patina
    var hasStitchedPatch: Bool
    var activeSnackID: String?
    var currentOccupantPetIDs: [String]
    var lastSolvedUTC: Date

    init(
        spotIndex: Int,
        spotName: String,
        equippedGoodieID: String? = nil,
        goodieUseCount: Int = 0,
        hasStitchedPatch: Bool = false,
        activeSnackID: String? = nil,
        currentOccupantPetIDs: [String] = [],
        lastSolvedUTC: Date = Date()
    ) {
        self.spotIndex = spotIndex
        self.spotName = spotName
        self.equippedGoodieID = equippedGoodieID
        self.goodieUseCount = goodieUseCount
        self.hasStitchedPatch = hasStitchedPatch
        self.activeSnackID = activeSnackID
        self.currentOccupantPetIDs = currentOccupantPetIDs
        self.lastSolvedUTC = lastSolvedUTC
    }

    var hasLovedPatina: Bool {
        goodieUseCount >= 25
    }
}

// MARK: - 6. TeachingIntention
@Model
final class TeachingIntention {
    @Attribute(.unique) var intentionUUID: UUID
    var mentorPetID: String
    var learnerPetID: String
    var habitFamilyID: String
    var sharedPropID: String
    var stepsAccumulated: Int // target 2,500
    var stateRaw: String
    var plannedDateISO: String

    init(
        intentionUUID: UUID = UUID(),
        mentorPetID: String,
        learnerPetID: String,
        habitFamilyID: String,
        sharedPropID: String,
        stepsAccumulated: Int = 0,
        state: TeachingState = .queued,
        plannedDateISO: String
    ) {
        self.intentionUUID = intentionUUID
        self.mentorPetID = mentorPetID
        self.learnerPetID = learnerPetID
        self.habitFamilyID = habitFamilyID
        self.sharedPropID = sharedPropID
        self.stepsAccumulated = stepsAccumulated
        self.stateRaw = state.rawValue
        self.plannedDateISO = plannedDateISO
    }

    var state: TeachingState {
        get { TeachingState(rawValue: stateRaw) ?? .queued }
        set { stateRaw = newValue.rawValue }
    }
}

// MARK: - 7. WalletAndCurioLedger
@Model
final class WalletAndCurioLedger {
    @Attribute(.unique) var txUUID: String // "primary" singleton ledger
    var stepCarryRemainder: Int // 0..199
    var pocketFindStepProgress: Int // 0..1399 (forages every 1,400 accepted steps)
    var coinBalance: Int
    var totalAcceptedStepsAllTime: Int
    var pilotTap3MagicalDelivered: Bool
    var ownedGoodieIDs: [String]
    var ownedOutfitIDs: [String]
    var ownedRoomThemeIDs: [String] = ["room.spring_sunlit"]
    var activeRoomThemeRaw: String = "room.spring_sunlit"
    var verandaUnlocked: Bool = false
    var activeOutingPackRaw: String? = nil
    var pedometerOptIn: Bool = false
    var backgroundVisitsOptIn: Bool = false
    var mobilityRollModeEnabled: Bool = false
    var mobilityDistanceCarryM: Double = 0.0
    var mobilityDwellCarrySec: Double = 0.0
    var lastNeighborhoodLat: Double? = nil
    var lastNeighborhoodLon: Double? = nil
    var activeStrollChainTargetSiteID: String? = nil
    var activeStrollChainGuidePetID: String? = nil
    var activeStrollChainDateISO: String? = nil
    var processedTxIDs: [String]
    var foragedCuriosData: Data?
    var stepIntervalsData: Data?
    var gingerTeaActiveUntil: Date? = nil
    var indoorStateData: Data? = nil

    init(
        txUUID: String = "primary",
        stepCarryRemainder: Int = 0,
        pocketFindStepProgress: Int = 0,
        coinBalance: Int = 0,
        totalAcceptedStepsAllTime: Int = 0,
        pilotTap3MagicalDelivered: Bool = false,
        ownedGoodieIDs: [String] = ["goodie.folded_towel", "goodie.cloth_ball", "goodie.wool_blanket"],
        ownedOutfitIDs: [String] = [],
        processedTxIDs: [String] = [],
        foragedCurios: [ForagedCurioEntry] = [],
        stepIntervals: [StepIntervalRecord] = []
    ) {
        self.txUUID = txUUID
        self.stepCarryRemainder = stepCarryRemainder
        self.pocketFindStepProgress = pocketFindStepProgress
        self.coinBalance = coinBalance
        self.totalAcceptedStepsAllTime = totalAcceptedStepsAllTime
        self.pilotTap3MagicalDelivered = pilotTap3MagicalDelivered
        self.ownedGoodieIDs = ownedGoodieIDs
        self.ownedOutfitIDs = ownedOutfitIDs
        self.processedTxIDs = processedTxIDs
        self.foragedCuriosData = try? JSONEncoder().encode(foragedCurios)
        self.stepIntervalsData = try? JSONEncoder().encode(stepIntervals)
    }

    var activeRoomTheme: SeasonalRoomTheme {
        get { SeasonalRoomTheme(rawValue: activeRoomThemeRaw) ?? .springSunlit }
        set { activeRoomThemeRaw = newValue.rawValue }
    }

    var activeOutingPack: OutingPackKind? {
        get { activeOutingPackRaw.flatMap(OutingPackKind.init(rawValue:)) }
        set { activeOutingPackRaw = newValue?.rawValue }
    }

    var foragedCurios: [ForagedCurioEntry] {
        get {
            guard let data = foragedCuriosData else { return [] }
            return (try? JSONDecoder().decode([ForagedCurioEntry].self, from: data)) ?? []
        }
        set {
            foragedCuriosData = try? JSONEncoder().encode(newValue)
        }
    }

    var stepIntervals: [StepIntervalRecord] {
        get {
            guard let data = stepIntervalsData else { return [] }
            return (try? JSONDecoder().decode([StepIntervalRecord].self, from: data)) ?? []
        }
        set {
            stepIntervalsData = try? JSONEncoder().encode(newValue)
        }
    }

    func isGingerTeaActive(at date: Date = Date()) -> Bool {
        guard let until = gingerTeaActiveUntil else { return false }
        return until > date
    }

    var indoorState: SunroomIndoorState {
        get {
            guard let data = indoorStateData else { return SunroomIndoorState() }
            return (try? JSONDecoder().decode(SunroomIndoorState.self, from: data)) ?? SunroomIndoorState()
        }
        set {
            indoorStateData = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - Explicit Versioned Schema (preserves top-level SwiftData model identities across upgrades)
enum PawprintSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            DiaryDayRecord.self,
            AnchorSiteRecord.self,
            EncounterLog.self,
            PetResidentState.self,
            HomeSpotPlacement.self,
            TeachingIntention.self,
            WalletAndCurioLedger.self
        ]
    }
}

// MARK: - Schema Migration Plan
/// The single source of truth for how on-disk diaries move between schema versions.
///
/// Every `ModelContainer` that touches the persistent store must be opened through this plan
/// (use `PawprintPersistence.makeContainer`), otherwise SwiftData falls back to inferred
/// lightweight migration and can't run custom stages.
///
/// ### Adding V3 (checklist)
/// 1. **Freeze V2.** Copy the current `@Model` classes, byte-for-byte as they are in this
///    file today, into `PawprintSchemaV2` as nested types (`PawprintSchemaV2.DiaryDayRecord`, …)
///    and point `PawprintSchemaV2.models` at those nested copies. Its `versionIdentifier`
///    and stored properties must never change again — they describe stores already on devices.
/// 2. **Declare V3.** Add `enum PawprintSchemaV3: VersionedSchema` (version `3.0.0`) whose
///    `models` lists the live top-level classes with the new changes applied.
/// 3. **Register it here.** Append `PawprintSchemaV3.self` to `schemas` and a stage to `stages`:
///    `.lightweight(fromVersion: PawprintSchemaV2.self, toVersion: PawprintSchemaV3.self)` when
///    SwiftData can infer the change (new optional / defaulted property, rename via
///    `@Attribute(originalName:)`), or `.custom(...)` with `willMigrate`/`didMigrate` closures
///    for data back-fills and unique-constraint changes.
/// 4. **Bump `PawprintPersistence.currentVersionedSchema`** to `PawprintSchemaV3.self`.
/// 5. **Extend `SchemaMigrationTests`** with a V2-store → V3 case asserting the transformed data.
///
/// Two schemas with identical model shapes produce identical version checksums and make
/// SwiftData reject the plan, so do not add an empty V3 "placeholder" before it has real changes.
enum PawprintMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PawprintSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

// MARK: - Persistence Factory
/// Builds model containers for the persistent diary store. Shared by the app and the migration tests
/// so both open the store exactly the same way.
enum PawprintPersistence {
    /// The newest schema in `PawprintMigrationPlan.schemas`.
    static var currentVersionedSchema: any VersionedSchema.Type { PawprintSchemaV2.self }

    static var currentSchema: Schema {
        Schema(versionedSchema: currentVersionedSchema)
    }

    /// Opens (and if needed migrates) the store described by `configuration` through `PawprintMigrationPlan`.
    static func makeContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: currentSchema,
            migrationPlan: PawprintMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
