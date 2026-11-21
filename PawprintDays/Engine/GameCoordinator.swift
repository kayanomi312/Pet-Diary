import Foundation
import SwiftData
import CoreLocation
import Observation

struct QuietRevisitMoment: Identifiable, Equatable, Sendable {
    let id = UUID()
    let siteLabel: String
    let petID: String
    let secondaryPetID: String?
    let timeBandLabel: String
    let familiarityLabel: String
    let vignetteLine: String
}

@MainActor
@Observable
final class GameCoordinator {
    private let ownedModelContainer: ModelContainer?
    let modelContext: ModelContext
    let locationService: LocationService
    let pedometerService: PedometerService

    var currentScreen: AppScreen = .street
    var currentSimulatedDate: Date = Date()
    var activeWeather: WeatherMode = .lightRain
    var showOnboardingPaperSlip: Bool = false
    var showAccessibleNearbyList: Bool = false
    var showFixtureDrawer: Bool = false
    var transientWhisper: String? = nil
    var latestFixtureReport: Stage1VerificationSummary? = nil
    var isDiscoveringAnchors: Bool = false
    var activeQuietRevisit: QuietRevisitMoment? = nil
    var newlyUnpackedCurio: ForagedCurioEntry? = nil
    var activeStroll: ActiveStrollSession? = nil
    var completedStrollSummary: CompletedStrollSummary? = nil

    var anchors: [AnchorSiteRecord] = []
    var residents: [PetResidentState] = []
    var homeSpots: [HomeSpotPlacement] = []
    var diaryDays: [DiaryDayRecord] = []
    var encounters: [EncounterLog] = []
    var teachingIntentions: [TeachingIntention] = []
    var ledger: WalletAndCurioLedger

    init(
        modelContext: ModelContext,
        modelContainer: ModelContainer? = nil,
        locationService: LocationService = LocationService(),
        pedometerService: PedometerService = PedometerService()
    ) {
        self.ownedModelContainer = modelContainer
        self.modelContext = modelContext
        self.locationService = locationService
        self.pedometerService = pedometerService

        let existingLedgers = (try? modelContext.fetch(FetchDescriptor<WalletAndCurioLedger>())) ?? []
        if let found = existingLedgers.first {
            self.ledger = found
        } else {
            let created = WalletAndCurioLedger()
            modelContext.insert(created)
            self.ledger = created
        }

        seedInitialWorldIfNeeded()
        reloadAll()
        wireLocationCallbacks()
    }

    var currentLocalDateISO: String {
        CivilCalendarHelper.localDateISO(for: currentSimulatedDate)
    }

    var activeWalkCompanionID: String? {
        todayDiaryRecord().companionPetID
    }

    var isNearPocketFind: Bool {
        StepCoinLedgerEngine.isNearPocketFind(progress: ledger.pocketFindStepProgress)
    }

    var stepsUntilNextPocketFind: Int {
        StepCoinLedgerEngine.stepsRemainingForPocketFind(progress: ledger.pocketFindStepProgress)
    }

    var visibleAnchors: [AnchorSiteRecord] {
        anchors.filter { !$0.isHiddenByUser }
    }

    var activeStrollChainTargetID: String? {
        guard ledger.activeStrollChainDateISO == currentLocalDateISO else { return nil }
        return ledger.activeStrollChainTargetSiteID
    }

    // MARK: - Sensor Callback Wiring
    private func wireLocationCallbacks() {
        locationService.onRealLocationMoved = { [weak self] location, lowSpeedMeters, dwellSeconds in
            guard let self else { return }
            if self.ledger.mobilityRollModeEnabled && (lowSpeedMeters > 0 || dwellSeconds > 0) {
                self.recordMobilityRollMovement(lowSpeedMeters: lowSpeedMeters, dwellSeconds: dwellSeconds)
            }
            let needsDiscovery: Bool
            if let lastLat = self.ledger.lastNeighborhoodLat, let lastLon = self.ledger.lastNeighborhoodLon {
                let dist = location.distance(from: CLLocation(latitude: lastLat, longitude: lastLon))
                needsDiscovery = dist > 2_000
            } else {
                needsDiscovery = true
            }
            if needsDiscovery && !self.isDiscoveringAnchors {
                Task { @MainActor in
                    await self.discoverRealNeighborhoodAnchors(around: location.coordinate)
                }
            }
        }

        locationService.onEnteredAnchorGeofence = { [weak self] siteID in
            guard let self,
                  let anchor = self.anchors.first(where: { $0.siteID == siteID }) else { return }
            self.showWhisper("前方 \(anchor.customLabel) 有隻小腳印正在等你。")
        }

        locationService.onBackgroundVisitRecorded = { [weak self] _, _ in
            guard let self, self.ledger.backgroundVisitsOptIn else { return }
            let day = self.todayDiaryRecord()
            if day.personalNote.isEmpty {
                day.personalNote = "在熟悉的小街角安靜停駐了一會兒。"
                try? self.modelContext.save()
                self.reloadAll()
            }
        }
    }

    // MARK: - Seeding (自動升級舊有英文種子名稱為繁體中文)
    private func seedInitialWorldIfNeeded() {
        let existingPets = (try? modelContext.fetch(FetchDescriptor<PetResidentState>())) ?? []
        if existingPets.isEmpty {
            showOnboardingPaperSlip = true
        }
        for spec in PetCatalog.allPets {
            if let existing = existingPets.first(where: { $0.petID == spec.id }) {
                if existing.nickname != spec.name && existing.nickname.allSatisfy(\.isASCII) {
                    existing.nickname = spec.name
                }
            } else {
                modelContext.insert(PetResidentState(petID: spec.id, nickname: spec.name))
            }
        }

        let existingAnchors = (try? modelContext.fetch(FetchDescriptor<AnchorSiteRecord>())) ?? []
        if existingAnchors.isEmpty {
            let origin = LocationService.defaultNeighborhoodOrigin
            let bakeryCoord = AnchorRotationEngine.coordinateAhead(from: origin, meters: 42, bearingDegrees: 22)
            let riverCoord = AnchorRotationEngine.coordinateAhead(from: origin, meters: 165, bearingDegrees: 115)
            let parkCoord = AnchorRotationEngine.coordinateAhead(from: origin, meters: 260, bearingDegrees: 295)

            modelContext.insert(AnchorSiteRecord(
                siteID: "sys.luodong.bakery_corner",
                lat: bakeryCoord.latitude,
                lon: bakeryCoord.longitude,
                radiusM: 75,
                customLabel: "麵包店巷口",
                regularPetID: "pet.01",
                cycleTapCount: 0,
                isFamiliarCorner: false
            ))
            modelContext.insert(AnchorSiteRecord(
                siteID: "sys.luodong.riverside_bench",
                lat: riverCoord.latitude,
                lon: riverCoord.longitude,
                radiusM: 75,
                customLabel: "溪畔木椅",
                regularPetID: "pet.05",
                cycleTapCount: 0,
                isFamiliarCorner: false
            ))
            modelContext.insert(AnchorSiteRecord(
                siteID: "sys.luodong.library_arcade",
                lat: parkCoord.latitude,
                lon: parkCoord.longitude,
                radiusM: 75,
                customLabel: "圖書館騎樓",
                regularPetID: "pet.02",
                cycleTapCount: 0,
                isFamiliarCorner: false
            ))
        } else {
            // 升級既有英文預設街角名稱為繁體中文
            for a in existingAnchors {
                if a.customLabel == "Bakery Corner" { a.customLabel = "麵包店巷口" }
                if a.customLabel == "Riverside Bench" { a.customLabel = "溪畔木椅" }
                if a.customLabel == "Library Arcade" { a.customLabel = "圖書館騎樓" }
            }
        }

        ensureHomeSpotsExist()

        let todayISO = currentLocalDateISO
        let existingDays = (try? modelContext.fetch(FetchDescriptor<DiaryDayRecord>())) ?? []
        if !existingDays.contains(where: { $0.localDateISO == todayISO }) {
            let day = DiaryDayRecord(
                localDateISO: todayISO,
                weatherCode: activeWeather.rawValue,
                weatherAttribution: "天氣範例 · 羅東街區"
            )
            modelContext.insert(day)
        }

        try? modelContext.save()
    }

    private func ensureHomeSpotsExist() {
        let existingSpots = (try? modelContext.fetch(FetchDescriptor<HomeSpotPlacement>())) ?? []
        let starterDefinitions: [(Int, String, String?)] = [
            (1, "向陽窗台", "goodie.folded_towel"),
            (2, "中央編織毯", "goodie.wool_blanket"),
            (3, "靜謐角落", "goodie.cloth_ball"),
            (4, "雨廊門檻", nil),
            (5, "茶席點心盤", nil)
        ]
        for (idx, name, defaultGoodie) in starterDefinitions {
            if let existing = existingSpots.first(where: { $0.spotIndex == idx }) {
                if existing.spotName.allSatisfy(\.isASCII) {
                    existing.spotName = name
                }
            } else {
                modelContext.insert(HomeSpotPlacement(spotIndex: idx, spotName: name, equippedGoodieID: defaultGoodie))
            }
        }
        if ledger.verandaUnlocked {
            let verandaDefinitions: [(Int, String)] = [
                (6, "雨廊木欄"),
                (7, "紅檜長凳"),
                (8, "細雨石階")
            ]
            for (idx, name) in verandaDefinitions {
                if !existingSpots.contains(where: { $0.spotIndex == idx }) {
                    modelContext.insert(HomeSpotPlacement(spotIndex: idx, spotName: name))
                }
            }
        }
    }

    func reloadAll() {
        anchors = ((try? modelContext.fetch(FetchDescriptor<AnchorSiteRecord>())) ?? [])
            .sorted { $0.siteID < $1.siteID }
        residents = ((try? modelContext.fetch(FetchDescriptor<PetResidentState>())) ?? [])
            .sorted { $0.petID < $1.petID }
        homeSpots = ((try? modelContext.fetch(FetchDescriptor<HomeSpotPlacement>())) ?? [])
            .sorted { $0.spotIndex < $1.spotIndex }
        diaryDays = ((try? modelContext.fetch(FetchDescriptor<DiaryDayRecord>())) ?? [])
            .sorted { $0.localDateISO > $1.localDateISO }
        encounters = ((try? modelContext.fetch(FetchDescriptor<EncounterLog>())) ?? [])
            .sorted { $0.createdAtUTC > $1.createdAtUTC }
        teachingIntentions = (try? modelContext.fetch(FetchDescriptor<TeachingIntention>())) ?? []
        locationService.syncRollingGeofences(for: anchors)
    }

    func todayDiaryRecord() -> DiaryDayRecord {
        let iso = currentLocalDateISO
        if let found = diaryDays.first(where: { $0.localDateISO == iso }) {
            return found
        }
        let created = DiaryDayRecord(
            localDateISO: iso,
            timeZoneID: TimeZone.current.identifier,
            weatherCode: activeWeather.rawValue,
            weatherAttribution: "天氣範例 · 鄰里街區"
        )
        modelContext.insert(created)
        try? modelContext.save()
        reloadAll()
        return created
    }

    func resident(for petID: String) -> PetResidentState? {
        residents.first(where: { $0.petID == petID })
    }

    // MARK: - Real-World Anchor Discovery & 'Carry Regulars Forward' Relocation Guarantee
    func discoverRealNeighborhoodAnchors(around coordinate: CLLocationCoordinate2D) async {
        isDiscoveringAnchors = true
        defer { isDiscoveringAnchors = false }

        let discovered = await MapKitAnchorDiscoveryService.discoverNearbyWalkableAnchors(around: coordinate)
        applyDiscoveredAnchors(discovered, around: coordinate)
        if discovered.isEmpty {
            showWhisper("周遭 400m 內無公園或咖啡館，隨時可點「前方 60m 釘選熟悉街角」！")
        }
    }

    func applyDiscoveredAnchors(_ discovered: [DiscoveredWalkableAnchor], around coordinate: CLLocationCoordinate2D) {
        ledger.lastNeighborhoodLat = coordinate.latitude
        ledger.lastNeighborhoodLon = coordinate.longitude

        // 若真實位置已離開羅東範例街區超過 1.5 公里，自動收起範例點，只留真實街角與私人熟悉街角
        let luodongLoc = CLLocation(latitude: LocationService.defaultNeighborhoodOrigin.latitude, longitude: LocationService.defaultNeighborhoodOrigin.longitude)
        let currentLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if currentLoc.distance(from: luodongLoc) > 1_500 && !discovered.isEmpty {
            for anchor in anchors where anchor.siteID.hasPrefix("sys.luodong.") {
                anchor.isHiddenByUser = true
            }
        }

        for (idx, item) in discovered.enumerated() {
            if !anchors.contains(where: { $0.siteID == item.siteID }) {
                let regularID = MapKitAnchorDiscoveryService.pickRegularPetID(forIndex: idx, residents: residents)
                modelContext.insert(AnchorSiteRecord(
                    siteID: item.siteID,
                    lat: item.latitude,
                    lon: item.longitude,
                    radiusM: 75.0,
                    customLabel: item.label,
                    regularPetID: regularID,
                    cycleTapCount: 0,
                    isFamiliarCorner: false
                ))
            }
        }
        try? modelContext.save()
        reloadAll()
        if !discovered.isEmpty {
            showWhisper("已替你標出周遭 \(discovered.count) 個可散步的街角足印。")
        }
    }

    // MARK: - Live Pedometer & Mobility-Aid Roll Mode
    func optInAndSyncPedometer() async {
        ledger.pedometerOptIn = true
        let buckets = await pedometerService.requestAndSyncRolling7Days(now: currentSimulatedDate)
        var totalAdded = 0
        for bucket in buckets {
            let res = ingestSteps(
                steps: bucket.steps,
                intervalStartUTC: bucket.intervalStartUTC,
                placeLabel: "日常散步"
            )
            totalAdded += res.newlyAcceptedSteps
        }
        try? modelContext.save()
        reloadAll()
        if totalAdded > 0 {
            showWhisper("已同步 \(totalAdded.formatted()) 步進你的步數幣袋。")
        } else if !pedometerService.isStepCountingAvailable {
            showWhisper("此裝置暫無計步器；可改開「緩步里程模式」。")
        } else {
            showWhisper("已連結計步器，日常散步會安靜累積成步數幣。")
        }
    }

    func toggleMobilityRollMode(_ enabled: Bool) {
        ledger.mobilityRollModeEnabled = enabled
        try? modelContext.save()
        reloadAll()
        showWhisper(enabled ? "已開啟緩步里程模式（低速 130 公尺或戶外停留 2 分鐘 = 1 幣）。" : "已關閉緩步里程模式。")
    }

    func toggleOptionalBackgroundVisits(_ enabled: Bool) {
        ledger.backgroundVisitsOptIn = enabled
        if enabled {
            locationService.enableOptionalBackgroundVisits()
            showWhisper("已開啟長停留日記備註，隨時可單日抹除。")
        } else {
            locationService.disableBackgroundVisits()
            showWhisper("已暫停背景停留備註。")
        }
        try? modelContext.save()
        reloadAll()
    }

    @discardableResult
    func recordMobilityRollMovement(
        lowSpeedMeters: Double,
        dwellSeconds: TimeInterval,
        placeLabel: String = "緩步散心"
    ) -> StepIngestionResult {
        let day = todayDiaryRecord()
        let result = StepCoinLedgerEngine.ingestMobilityRollCredit(
            ledger: ledger,
            lowSpeedMeters: lowSpeedMeters,
            outdoorDwellSeconds: dwellSeconds,
            companionPetID: day.companionPetID,
            weather: activeWeather,
            placeLabel: placeLabel,
            localDateISO: currentLocalDateISO
        )
        if result.newlyAcceptedSteps > 0 {
            day.acceptedSteps += result.newlyAcceptedSteps
            advanceMentorshipSteps(by: result.newlyAcceptedSteps)
            try? modelContext.save()
            reloadAll()
        }
        return result
    }

    // MARK: - Street Anchors, Stroll Chains & Familiar Corners
    func pawState(for anchor: AnchorSiteRecord) -> PawState {
        if anchor.lastVisitedLocalDate == currentLocalDateISO {
            return .metToday
        }
        if activeStrollChainTargetID == anchor.siteID {
            return .strollChain
        }
        let check = AnchorRotationEngine.evaluateProximity(
            anchor: anchor,
            userLocation: locationService.currentLocation,
            now: Date(),
            currentLocalDateISO: currentLocalDateISO
        )
        if case .eligible = check {
            return .inRange
        }
        return .distant
    }

    func distanceMeters(to anchor: AnchorSiteRecord) -> Double {
        let anchorLoc = CLLocation(latitude: anchor.lat, longitude: anchor.lon)
        return locationService.currentLocation.distance(from: anchorLoc)
    }

    @discardableResult
    func attemptOpenAnchor(_ anchor: AnchorSiteRecord) -> AnchorProximityCheck {
        if locationService.useSimulatedPosition {
            locationService.refreshFreshSimulatedFix()
        }
        let check = AnchorRotationEngine.evaluateProximity(
            anchor: anchor,
            userLocation: locationService.currentLocation,
            now: Date(),
            currentLocalDateISO: currentLocalDateISO
        )

        switch check {
        case .eligible:
            let offeredPetID = AnchorRotationEngine.resolveAndPersistOfferedPetID(
                anchor: anchor,
                residents: residents,
                ledger: ledger
            )
            let isStrollChainArrival = (activeStrollChainTargetID == anchor.siteID)
            let guidePetID = isStrollChainArrival ? ledger.activeStrollChainGuidePetID : nil
            let distinctGuide = (guidePetID != offeredPetID) ? guidePetID : nil
            try? modelContext.save()
            HapticsEngine.shared.playPawRangeCue()
            CozySoundEngine.shared.playCompassChime()
            currentScreen = .encounter(siteID: anchor.siteID, petID: offeredPetID, companionStreetPetID: distinctGuide)
        case .tooFar(let distanceM, _):
            showWhisper("請走近至 75 公尺內再打招呼（目前相距 \(Int(distanceM)) 公尺）。")
        case .poorAccuracy:
            showWhisper("正在等待較穩定的戶外定位訊號…")
        case .staleFix:
            showWhisper("正在重新確認你目前的散步位置…")
        case .movingTooFast:
            showWhisper("放慢至步行速度（12 km/h 以下）就能和街角夥伴打招呼。")
        case .alreadyMetToday:
            let dist = distanceMeters(to: anchor)
            if dist <= AnchorRotationEngine.maxActivationRadiusM {
                performQuietRevisit(anchor: anchor)
            } else {
                showWhisper("今天已在「\(anchor.customLabel)」打過招呼；走近 75m 內可順路看看牠在做什麼。")
            }
        }
        return check
    }

    /// 給常在自家附近反覆散步的使用者：當日已互動過的街角，在不同時段或再次經過時，
    /// 可開啟 5 秒溫馨「順路探望小札」（不重複計算相伴天數、零農度壓力，卻讓熟悉街區永遠有生命力）。
    @discardableResult
    func performQuietRevisit(anchor: AnchorSiteRecord, now: Date = Date()) -> QuietRevisitMoment {
        let hour = Calendar.current.component(.hour, from: now)
        let (bandKey, bandLabel): (String, String) = {
            switch hour {
            case 5..<11: return ("morning", "晨間順路")
            case 11..<17: return ("afternoon", "午後小歇")
            default: return ("evening", "傍晚歸途")
            }
        }()

        let petID = anchor.regularPetID
        let spec = PetCatalog.pet(id: petID)

        // 熟識度達到「常去轉角」(>=3次) 時，有機會遇見另一位已邀請的室友在街角結伴！
        let otherInvited = residents.filter { $0.inviteState == .invitedHome && $0.petID != petID }
        let friendID = (anchor.totalVisitsCount >= 2 && !otherInvited.isEmpty)
            ? otherInvited[(anchor.totalVisitsCount + hour) % otherInvited.count].petID
            : nil

        let line: String
        if let friendID {
            let friendSpec = PetCatalog.pet(id: friendID)
            line = "\(bandLabel)經過「\(anchor.customLabel)」時，看見\(spec.name)正和\(friendSpec.name)並肩躲在屋簷下看路人。"
        } else {
            switch bandKey {
            case "morning":
                line = "\(spec.name)正在「\(anchor.customLabel)」的暖陽石階上伸了個懶腰，眼神安穩地目送你去上班。"
            case "afternoon":
                line = "\(spec.name)把下巴墊在前掌上，在「\(anchor.customLabel)」的木凳旁半瞇著眼打盹。"
            default:
                line = "街燈剛亮起，\(spec.name)仍在「\(anchor.customLabel)」的燈籠暖光下安靜等著晚歸的腳步。"
            }
        }

        if anchor.lastRevisitTimeBand != "\(currentLocalDateISO)|\(bandKey)" {
            anchor.lastRevisitTimeBand = "\(currentLocalDateISO)|\(bandKey)"
            let day = todayDiaryRecord()
            if !day.revisitNotes.contains(line) {
                day.revisitNotes.append(line)
            }
            try? modelContext.save()
            reloadAll()
        }

        let moment = QuietRevisitMoment(
            siteLabel: anchor.customLabel,
            petID: petID,
            secondaryPetID: friendID,
            timeBandLabel: bandLabel,
            familiarityLabel: anchor.familiarityTitle,
            vignetteLine: line
        )
        activeQuietRevisit = moment
        HapticsEngine.shared.playPawRangeCue()
        return moment
    }

    /// 合併相鄰重複偵測的街角停靠點（藍圖第四章：允許合併相鄰偵測點）
    func mergeAnchor(sourceSiteID: String, intoTargetSiteID targetSiteID: String) {
        guard sourceSiteID != targetSiteID,
              let source = anchors.first(where: { $0.siteID == sourceSiteID }),
              let target = anchors.first(where: { $0.siteID == targetSiteID }) else { return }

        target.totalVisitsCount += source.totalVisitsCount
        for enc in encounters where enc.siteID == sourceSiteID {
            if !enc.placeRedacted {
                enc.siteDisplayLabel = target.customLabel
            }
        }
        source.isHiddenByUser = true
        try? modelContext.save()
        reloadAll()
        showWhisper("已將「\(source.customLabel)」合併至「\(target.customLabel)」。")
    }

    /// 里程碑 4（第 10 天 · 心照不宣）：雙選觸覺習慣練習（藍圖第四章）
    func completeKindredHabitPractice(petID: String, choiceTitle: String) {
        guard let pet = resident(for: petID) else { return }
        let spec = PetCatalog.pet(id: petID)
        pet.kindredPracticeCompleted = true
        pet.kindredChoiceNote = "心照不宣練習：陪\(spec.name)以「\(choiceTitle)」練習了\(spec.signatureHabitTitle)。"
        try? modelContext.save()
        reloadAll()
        HapticsEngine.shared.playCurioUnpack()
        showWhisper("\(spec.name)記住了這份溫柔，以後在家會自主展現「\(spec.signatureHabitTitle)」！")
    }

    @discardableResult
    func pinFamiliarCornerAhead(label: String? = nil) -> AnchorSiteRecord? {
        let existingCorners = anchors.filter { $0.isFamiliarCorner && !$0.isHiddenByUser }
        guard existingCorners.count < AnchorRotationEngine.maxPersonalFamiliarCorners else {
            showWhisper("3 個私人熟悉街角已全部釘選完成。")
            return nil
        }

        let ahead = AnchorRotationEngine.coordinateAhead(
            from: locationService.currentLocation.coordinate,
            meters: 60.0,
            bearingDegrees: 35.0 + Double(existingCorners.count) * 45.0
        )
        let cornerIndex = existingCorners.count + 1
        let defaultNames = ["公車站老榕樹下", "轉角雨棚木凳", "靜巷石階口"]
        let chosenLabel = label ?? defaultNames[(cornerIndex - 1) % defaultNames.count]
        let regularID = MapKitAnchorDiscoveryService.pickRegularPetID(forIndex: cornerIndex, residents: residents)

        let record = AnchorSiteRecord(
            siteID: "local.corner.\(cornerIndex).\(UUID().uuidString.prefix(6))",
            lat: ahead.latitude,
            lon: ahead.longitude,
            radiusM: 75,
            customLabel: chosenLabel,
            regularPetID: regularID,
            cycleTapCount: 0,
            isFamiliarCorner: true
        )
        modelContext.insert(record)
        try? modelContext.save()
        reloadAll()
        showWhisper("已在前方 60 公尺釘選「\(chosenLabel)」（僅私密留存本機）。")
        return record
    }

    func renameAnchor(siteID: String, newLabel: String) {
        let trimmed = newLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let anchor = anchors.first(where: { $0.siteID == siteID }) else { return }
        anchor.customLabel = trimmed
        for enc in encounters where enc.siteID == siteID && !enc.placeRedacted {
            enc.siteDisplayLabel = trimmed
        }
        try? modelContext.save()
        reloadAll()
    }

    func hideAnchor(siteID: String) {
        guard let anchor = anchors.first(where: { $0.siteID == siteID }) else { return }
        anchor.isHiddenByUser = true
        try? modelContext.save()
        reloadAll()
        showWhisper("已將「\(anchor.customLabel)」從地圖隱藏。")
    }

    @discardableResult
    func commitStreetEncounter(
        siteID: String,
        petID: String,
        companionStreetPetID: String? = nil,
        gesture: GreetingGesture,
        inviteHome: Bool = true,
        forceOfferStrollChain: Bool = false
    ) -> EncounterLog? {
        guard let anchor = anchors.first(where: { $0.siteID == siteID }),
              let pet = residents.first(where: { $0.petID == petID }) else {
            return nil
        }

        let dateISO = currentLocalDateISO
        let siteDayKey = "\(siteID)|\(dateISO)"
        if let existing = encounters.first(where: { $0.siteDayKey == siteDayKey }) {
            return existing
        }

        var resolvedSecondaryPetID = companionStreetPetID
        // 若正帶著「手工野餐麵包袋」出門散步，街角會悄悄吸引另一位已入住的奇幻夥伴來串門子！
        if resolvedSecondaryPetID == nil,
           activeStroll?.packedCharm == .picnicBread {
            let otherInvited = residents.filter { $0.inviteState == .invitedHome && $0.petID != petID }
            if let cameo = otherInvited.first(where: { $0.petID == activeStroll?.companionPetID }) ?? otherInvited.first {
                resolvedSecondaryPetID = cameo.petID
            }
        }

        let secondarySpec = resolvedSecondaryPetID.map(PetCatalog.pet(id:))
        let secondaryOutfit = resolvedSecondaryPetID.flatMap { resident(for: $0)?.activeOutfitID }
        let activePack = ledger.activeOutingPack
        let isWideSpread = (activePack == .sketchbookCharcoal)

        let selection = NarrativeEngine.selectStreetScene(
            pet: pet,
            secondaryStreetPet: secondarySpec,
            anchorLabel: anchor.customLabel,
            weather: activeWeather,
            chosenGesture: gesture,
            localDateISO: dateISO,
            pastEncounters: encounters,
            activeIntentions: teachingIntentions,
            activeOutingPack: activePack
        )

        let petSpec = PetCatalog.pet(id: petID)
        let frozenOutfitID = pet.activeOutfitID
        let bakedPNG = DiarySnapshotBaker.bakeEncounterPostcardPNG(
            pet: petSpec,
            outfitID: frozenOutfitID,
            secondaryPet: secondarySpec,
            secondaryOutfitID: secondaryOutfit,
            weather: activeWeather,
            placeLabel: anchor.customLabel,
            localDateISO: dateISO,
            isWideSpread: isWideSpread
        )

        var offeredChainTargetID: String? = nil
        if companionStreetPetID == nil {
            let shouldOffer = forceOfferStrollChain || ((encounters.count + 1) % 3 == 0)
            if shouldOffer,
               let target = AnchorRotationEngine.pickStrollChainTarget(from: anchor, allAnchors: anchors, currentLocalDateISO: dateISO) {
                offeredChainTargetID = target.siteID
                ledger.activeStrollChainTargetSiteID = target.siteID
                ledger.activeStrollChainGuidePetID = petID
                ledger.activeStrollChainDateISO = dateISO
            }
        } else {
            ledger.activeStrollChainTargetSiteID = nil
            ledger.activeStrollChainGuidePetID = nil
            ledger.activeStrollChainDateISO = nil
        }

        if activePack == .sketchbookCharcoal {
            ledger.activeOutingPackRaw = nil
        }

        let log = EncounterLog(
            siteID: siteID,
            siteDisplayLabel: anchor.customLabel,
            localDateISO: dateISO,
            timeZoneID: TimeZone.current.identifier,
            petID: petID,
            secondaryPetID: resolvedSecondaryPetID,
            sceneRevisionID: selection.sceneRevisionID,
            gestureChosen: gesture,
            equippedOutfitSnapshotID: frozenOutfitID,
            secondaryOutfitSnapshotID: secondaryOutfit,
            weatherSnapshot: activeWeather,
            narrativeLine: selection.diarySystemSentence,
            bakedSnapshotPNGData: bakedPNG,
            strollChainTargetSiteID: offeredChainTargetID,
            isWideWatercolorSpread: isWideSpread,
            createdAtUTC: currentSimulatedDate
        )
        modelContext.insert(log)

        if pet.firstMetDateISO == nil {
            pet.firstMetDateISO = dateISO
            pet.firstGesture = gesture
        }
        if pet.lastSharedDateISO != dateISO {
            pet.sharedDaysCount += 1
            pet.lastSharedDateISO = dateISO
            pet.milestoneTier = PetResidentState.milestoneForSharedDays(pet.sharedDaysCount)
        }
        if inviteHome {
            pet.inviteState = .invitedHome
        } else if pet.inviteState == .unmet {
            pet.inviteState = .sighted
        }

        var recent = pet.recentSceneIDs
        recent.append(selection.sceneRevisionID)
        if recent.count > 6 { recent.removeFirst(recent.count - 6) }
        pet.recentSceneIDs = recent

        AnchorRotationEngine.commitCompletedTap(
            anchor: anchor,
            offeredPetID: petID,
            localDateISO: dateISO,
            ledger: ledger
        )
        anchor.totalVisitsCount += 1

        let day = todayDiaryRecord()
        day.weatherCode = activeWeather.rawValue
        if let trail = locationService.encodeTrailGeoJSON() {
            day.routeTrackGeoJSON = trail
        }
        if day.companionPetID == nil && pet.inviteState == .invitedHome {
            day.companionPetID = pet.petID
        }

        // 單日走訪 3 個以上不同街角 -> 蓋上「今日街區巡禮」紀念章（給常散步玩家的靜謐彩蛋，無任何錯過懲罰）
        let distinctSitesToday = Set(encounters.filter { $0.localDateISO == dateISO }.map(\.siteID)).union([siteID])
        if distinctSitesToday.count >= 3 && !day.completedNeighborhoodLoop {
            day.completedNeighborhoodLoop = true
            showWhisper("完成今日街區巡禮！已在日記頁蓋上散步紀念章。")
        }

        resolveMentorshipsOnNewDay(dateISO: dateISO)

        RoomOccupancySolver.solveRoom(
            spots: homeSpots,
            residents: residents,
            activeIntentions: teachingIntentions,
            weather: activeWeather,
            now: currentSimulatedDate
        )

        if var stroll = activeStroll {
            stroll.sessionEncountersCount += 1
            stroll.routePoints = locationService.liveTrail
            activeStroll = stroll
        }

        try? modelContext.save()
        reloadAll()
        return log
    }

    // MARK: - 選用「出發散步」儀式與帆布散步袋（不開也能自動計步；開啟後可畫路線、帶單趟輕小物並領結算明信片）
    @discardableResult
    func startStrollSession(companionPetID: String?, charm: StrollSatchelCharm) -> Bool {
        if charm.priceCoins > 0 {
            guard ledger.coinBalance >= charm.priceCoins else {
                showWhisper("需要 \(charm.priceCoins) 步數幣才能裝進「\(charm.title)」（目前有 \(ledger.coinBalance) 幣）。")
                return false
            }
            ledger.coinBalance -= charm.priceCoins
        }

        let day = todayDiaryRecord()
        if let companionPetID {
            day.companionPetID = companionPetID
        }

        let initialCoord = locationService.currentLocation.coordinate
        let startPoint = CoordinatePoint(latitude: initialCoord.latitude, longitude: initialCoord.longitude, timestamp: currentSimulatedDate)
        activeStroll = ActiveStrollSession(
            startedAt: currentSimulatedDate,
            localDateISO: currentLocalDateISO,
            companionPetID: day.companionPetID,
            packedCharm: charm,
            routePoints: [startPoint]
        )

        CozySoundEngine.shared.playCompassChime()
        HapticsEngine.shared.playPawRangeCue()
        let companionName = day.companionPetID.map { PetCatalog.pet(id: $0).name } ?? "小動物夥伴"
        if charm == .none {
            showWhisper("已和\(companionName)輕鬆出發！沿途會記下水彩足跡，停下休息絕不浪費任何物品。")
        } else {
            showWhisper("已將「\(charm.title)」放進帆布袋，和\(companionName)出發散步囉！")
        }
        try? modelContext.save()
        reloadAll()
        return true
    }

    @discardableResult
    func endStrollSession(autoArchived: Bool = false) -> CompletedStrollSummary? {
        guard let stroll = activeStroll else { return nil }
        activeStroll = nil

        var finalCoins = stroll.sessionCoinsEarned
        var bonusNote: String? = nil
        let day = todayDiaryRecord()

        if stroll.packedCharm == .gingerThermos && (stroll.sessionSteps > 0 || stroll.sessionEncountersCount > 0) {
            ledger.coinBalance += 2
            finalCoins += 2
            let note = "散步返家喝了暖呼呼的薑茶（暖薑茶壺回禮 +2 步數幣）"
            bonusNote = note
            if !day.revisitNotes.contains(note) {
                day.revisitNotes.append(note)
            }
        } else if stroll.packedCharm == .picnicBread && stroll.sessionEncountersCount > 0 {
            bonusNote = "手工麵包香引來了熟悉的小夥伴在街角串門子！"
        } else if stroll.packedCharm == .forageSachet && stroll.sessionSteps > 0 {
            bonusNote = "草本香包讓這趟散步的口袋拾遺嗅覺提升了 35%。"
        }

        let mergedRoute = locationService.liveTrail.count >= stroll.routePoints.count
            ? locationService.liveTrail
            : stroll.routePoints
        if let trail = locationService.encodeTrailGeoJSON() {
            day.routeTrackGeoJSON = trail
        }

        let minutes = max(1, Int(currentSimulatedDate.timeIntervalSince(stroll.startedAt) / 60.0))
        let summary = CompletedStrollSummary(
            id: stroll.sessionID,
            localDateISO: stroll.localDateISO,
            durationMinutes: minutes,
            companionPetID: stroll.companionPetID,
            packedCharm: stroll.packedCharm,
            totalSteps: stroll.sessionSteps,
            coinsEarned: finalCoins,
            encountersCount: stroll.sessionEncountersCount,
            curiosFoundIDs: stroll.sessionCuriosFound,
            routePoints: mergedRoute,
            bonusNote: bonusNote
        )

        try? modelContext.save()
        reloadAll()

        if !autoArchived {
            completedStrollSummary = summary
            CozySoundEngine.shared.playPaperFlip()
            HapticsEngine.shared.playCurioUnpack()
        }
        return summary
    }

    // MARK: - Steps, Coins, Shop, Treats & Outings
    func setWalkCompanion(petID: String) {
        let day = todayDiaryRecord()
        day.companionPetID = petID
        try? modelContext.save()
        reloadAll()
        showWhisper("今天由「\(PetCatalog.pet(id: petID).name)」陪你一起放進口袋散步。")
    }

    @discardableResult
    func ingestSteps(
        steps: Int,
        intervalStartUTC: Date? = nil,
        placeLabel: String = "鄰里散步"
    ) -> StepIngestionResult {
        let day = todayDiaryRecord()
        let result = StepCoinLedgerEngine.ingestIntervalSteps(
            ledger: ledger,
            intervalStartUTC: intervalStartUTC ?? currentSimulatedDate,
            reportedSteps: steps,
            companionPetID: day.companionPetID,
            weather: activeWeather,
            placeLabel: placeLabel,
            localDateISO: currentLocalDateISO
        )
        day.acceptedSteps += result.newlyAcceptedSteps

        if result.newlyAcceptedSteps > 0 {
            advanceMentorshipSteps(by: result.newlyAcceptedSteps)
        }

        var newlyForagedIDs = result.newCuriosForaged.map(\.curioID)

        // 若正在進行「出發散步」：累積本趟步數與路線；若帶了「草本拾遺香包」享額外 +35% 拾遺嗅覺進度
        if var stroll = activeStroll {
            stroll.sessionSteps += result.newlyAcceptedSteps
            stroll.sessionCoinsEarned += result.coinsAwarded
            stroll.routePoints = locationService.liveTrail

            if stroll.packedCharm == .forageSachet && result.newlyAcceptedSteps > 0 && day.companionPetID != nil {
                let bonusForage = Int(Double(result.newlyAcceptedSteps) * 0.35)
                if bonusForage > 0 {
                    ledger.pocketFindStepProgress += bonusForage
                    while ledger.pocketFindStepProgress >= StepCoinLedgerEngine.stepsPerPocketFind {
                        ledger.pocketFindStepProgress -= StepCoinLedgerEngine.stepsPerPocketFind
                        let curio = CurioCatalog.pickFor(
                            weather: activeWeather,
                            placeLabel: placeLabel,
                            seed: ledger.foragedCurios.count + bonusForage
                        )
                        let entry = ForagedCurioEntry(
                            curioID: curio.id,
                            placeLabel: placeLabel,
                            weatherCode: activeWeather.rawValue,
                            localDateISO: currentLocalDateISO
                        )
                        var existing = ledger.foragedCurios
                        existing.insert(entry, at: 0)
                        ledger.foragedCurios = existing
                        newlyForagedIDs.append(entry.curioID)
                        newlyUnpackedCurio = entry
                        HapticsEngine.shared.playCurioUnpack()
                        CozySoundEngine.shared.playPaperFlip()
                        showWhisper("香包嗅覺加成！撿到口袋拾遺：\(curio.name)")
                    }
                }
            }

            stroll.sessionCuriosFound.append(contentsOf: newlyForagedIDs)
            activeStroll = stroll
        }

        if let firstCurio = result.newCuriosForaged.first {
            HapticsEngine.shared.playCurioUnpack()
            CozySoundEngine.shared.playPaperFlip()
            newlyUnpackedCurio = firstCurio
            let curioName = CurioCatalog.curio(id: firstCurio.curioID).name
            showWhisper("撿到口袋拾遺：\(curioName)")
        }

        try? modelContext.save()
        reloadAll()
        return result
    }

    private func advanceMentorshipSteps(by deltaSteps: Int) {
        for intention in teachingIntentions where intention.state == .queued {
            intention.stepsAccumulated += deltaSteps
            if intention.stepsAccumulated >= 2_500 {
                intention.state = .demonstrated
            }
        }
    }

    private func resolveMentorshipsOnNewDay(dateISO: String) {
        for intention in teachingIntentions where intention.state == .queued && intention.plannedDateISO != dateISO {
            intention.state = .demonstrated
        }
    }

    @discardableResult
    func purchaseItem(_ item: ShopItemSpec, txID: String? = nil) -> Bool {
        let resolvedTx = txID ?? "tx.\(item.id).\(UUID().uuidString.prefix(8))"
        let ok = StepCoinLedgerEngine.spendCoins(ledger: ledger, txID: resolvedTx, item: item)
        if ok {
            if item.id == "room.rain_veranda" {
                ensureHomeSpotsExist()
                solveHomeRoomNow()
            } else if item.id == "treat.picnic_portion" {
                createPicnicPortionSnapshot()
            }
            try? modelContext.save()
            reloadAll()
            showWhisper("已收進「\(item.name)」。")
        } else {
            showWhisper("需要 \(item.priceCoins) 步數幣（袋中目前有 \(ledger.coinBalance) 幣）。")
        }
        return ok
    }

    @discardableResult
    func createPicnicPortionSnapshot() -> EncounterLog? {
        let invited = residents.filter { $0.inviteState == .invitedHome }
        guard let first = invited.first else { return nil }
        let second = invited.dropFirst().first

        let firstSpec = PetCatalog.pet(id: first.petID)
        let secondSpec = second.map { PetCatalog.pet(id: $0.petID) }
        let dateISO = currentLocalDateISO
        let siteID = "home.picnic.\(UUID().uuidString.prefix(6))"
        let bakedPNG = DiarySnapshotBaker.bakeEncounterPostcardPNG(
            pet: firstSpec,
            outfitID: first.activeOutfitID,
            secondaryPet: secondSpec,
            secondaryOutfitID: second?.activeOutfitID,
            weather: activeWeather,
            placeLabel: "陽光室茶點盤",
            localDateISO: dateISO
        )
        let line: String
        if let secondSpec {
            line = "\(firstSpec.name)與\(secondSpec.name)在暖木窗邊一起享用了雙人野餐點心。"
        } else {
            line = "\(firstSpec.name)在陶瓷茶壺旁慢慢品嚐了野餐點心。"
        }
        let log = EncounterLog(
            siteID: siteID,
            siteDisplayLabel: "陽光室茶點盤",
            localDateISO: dateISO,
            petID: first.petID,
            secondaryPetID: second?.petID,
            sceneRevisionID: "home.picnic.\(dateISO)",
            gestureChosen: .crouchQuietly,
            equippedOutfitSnapshotID: first.activeOutfitID,
            secondaryOutfitSnapshotID: second?.activeOutfitID,
            weatherSnapshot: activeWeather,
            narrativeLine: line,
            bakedSnapshotPNGData: bakedPNG,
            createdAtUTC: currentSimulatedDate
        )
        modelContext.insert(log)
        _ = todayDiaryRecord()
        try? modelContext.save()
        reloadAll()
        return log
    }

    func selectRoomTheme(_ theme: SeasonalRoomTheme) {
        guard ledger.ownedRoomThemeIDs.contains(theme.rawValue) else { return }
        ledger.activeRoomTheme = theme
        try? modelContext.save()
        reloadAll()
    }

    @discardableResult
    func mendGoodiePatch(spotIndex: Int, txID: String? = nil) -> Bool {
        guard let spot = homeSpots.first(where: { $0.spotIndex == spotIndex }) else { return false }
        let resolvedTx = txID ?? "tx.patch.\(spotIndex).\(UUID().uuidString.prefix(6))"
        let ok = StepCoinLedgerEngine.spendPatchMendCoins(ledger: ledger, spot: spot, txID: resolvedTx)
        if ok {
            try? modelContext.save()
            reloadAll()
            showWhisper("已替「\(spot.spotName)」縫上一塊溫暖小補丁。")
        } else {
            showWhisper("縫補裝飾補丁需要 10 步數幣。")
        }
        return ok
    }

    func equipOutfit(petID: String, outfitID: String?) {
        guard let pet = residents.first(where: { $0.petID == petID }) else { return }
        pet.activeOutfitID = outfitID
        try? modelContext.save()
        reloadAll()
    }

    func placeGoodie(spotIndex: Int, goodieID: String) {
        guard let spot = homeSpots.first(where: { $0.spotIndex == spotIndex }) else { return }
        spot.equippedGoodieID = goodieID
        spot.goodieUseCount = 0
        spot.hasStitchedPatch = false
        RoomOccupancySolver.solveRoom(
            spots: homeSpots,
            residents: residents,
            activeIntentions: teachingIntentions,
            weather: activeWeather,
            now: currentSimulatedDate
        )
        try? modelContext.save()
        reloadAll()
    }

    func solveHomeRoomNow() {
        RoomOccupancySolver.solveRoom(
            spots: homeSpots,
            residents: residents,
            activeIntentions: teachingIntentions,
            weather: activeWeather,
            now: currentSimulatedDate
        )
        try? modelContext.save()
        reloadAll()
    }

    func completeTactileCare(petID: String, texture: FoodTexture? = nil) {
        guard let pet = residents.first(where: { $0.petID == petID }) else { return }
        let dateISO = currentLocalDateISO
        if pet.lastSharedDateISO != dateISO {
            pet.sharedDaysCount += 1
            pet.lastSharedDateISO = dateISO
            pet.milestoneTier = PetResidentState.milestoneForSharedDays(pet.sharedDaysCount)
        }
        if let texture {
            pet.favoriteTexture = texture
        }
        try? modelContext.save()
        reloadAll()
    }

    func togglePinFavorite(petID: String) {
        guard let pet = residents.first(where: { $0.petID == petID }) else { return }
        pet.isPinned.toggle()
        solveHomeRoomNow()
    }

    // MARK: - Shared-Prop Cross-Species Mentorship
    @discardableResult
    func planMentorship(mentorID: String, learnerID: String) -> TeachingIntention? {
        guard mentorID != learnerID else { return nil }
        let spec = PetCatalog.pet(id: mentorID)
        let intention = TeachingIntention(
            mentorPetID: mentorID,
            learnerPetID: learnerID,
            habitFamilyID: spec.habitFamily.rawValue,
            sharedPropID: spec.habitFamily.sharedPropID,
            plannedDateISO: currentLocalDateISO
        )
        modelContext.insert(intention)
        solveHomeRoomNow()
        try? modelContext.save()
        reloadAll()
        showWhisper("已約好一起練習：由\(spec.name)分享「\(spec.signatureHabitTitle)」。")
        return intention
    }

    func completeMentorshipLesson(intentionUUID: UUID) {
        guard let intention = teachingIntentions.first(where: { $0.intentionUUID == intentionUUID }),
              let learner = resident(for: intention.learnerPetID) else { return }
        let mentorSpec = PetCatalog.pet(id: intention.mentorPetID)
        let habit = HabitFamily(rawValue: intention.habitFamilyID) ?? .wait

        intention.state = .mastered

        var habits = learner.learnedHabitIDs
        if !habits.contains(habit.rawValue) {
            habits.append(habit.rawValue)
            if habits.count > 2 { habits.removeFirst(habits.count - 2) }
            learner.learnedHabitIDs = habits
        }

        let credit = "於\(CivilCalendarHelper.displayDate(from: currentLocalDateISO))向\(mentorSpec.name)學會了「\(habit.title)」。"
        var credits = learner.learnedHabitCredits
        if !credits.contains(credit) {
            credits.append(credit)
            learner.learnedHabitCredits = credits
        }

        try? modelContext.save()
        reloadAll()
        HapticsEngine.shared.playCurioUnpack()
        showWhisper("\(PetCatalog.pet(id: learner.petID).name)向\(mentorSpec.name)學會了「\(habit.title)」！")
    }

    // MARK: - Living Diary, Annual Traditions & Single-Day Erasure
    func savePersonalNote(for localDateISO: String, note: String) {
        guard let day = diaryDays.first(where: { $0.localDateISO == localDateISO }) else { return }
        day.personalNote = note
        try? modelContext.save()
        reloadAll()
    }

    func toggleStarredTradition(for localDateISO: String) {
        guard let day = diaryDays.first(where: { $0.localDateISO == localDateISO }) else { return }
        day.isStarredTradition.toggle()
        try? modelContext.save()
        reloadAll()
    }

    func removeEncounter(uuid: UUID) {
        guard let target = encounters.first(where: { $0.encounterUUID == uuid }) else { return }
        modelContext.delete(target)
        try? modelContext.save()
        reloadAll()
    }

    func erasePlaceDataForSingleDay(localDateISO: String) {
        if let day = diaryDays.first(where: { $0.localDateISO == localDateISO }) {
            day.routeTrackGeoJSON = nil
            day.weatherAttribution = "已抹除地點"
            day.deletionState = .placeErased
        }
        for encounter in encounters where encounter.localDateISO == localDateISO {
            encounter.siteDisplayLabel = "一段安靜的散步"
            encounter.placeRedacted = true
            encounter.narrativeLine = "\(PetCatalog.pet(id: encounter.petID).name)與我共度了一段平靜片刻。"
        }
        try? modelContext.save()
        reloadAll()
        showWhisper("已抹除 \(localDateISO) 的地點與軌跡；動物夥伴與步數幣完整保留。")
    }

    // MARK: - 14-Day Fast-Forward Deterministic Verification Fixture
    func advanceSimulatedDays(_ days: Int) {
        if activeStroll != nil {
            // 跨日防呆：忘記按結束也不浪費任何資源，自動溫柔歸檔進前一天日記
            _ = endStrollSession(autoArchived: true)
        }
        if let next = Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: currentSimulatedDate) {
            currentSimulatedDate = next
            _ = todayDiaryRecord()
            resolveMentorshipsOnNewDay(dateISO: currentLocalDateISO)
            reloadAll()
        }
    }

    @discardableResult
    func runStage1Deterministic14DayFixture() -> Stage1VerificationSummary {
        var details: [String] = []
        let baseDate = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 9, minute: 0)) ?? Date()
        currentSimulatedDate = baseDate
        activeWeather = .lightRain

        guard let bakery = anchors.first(where: { $0.siteID == "sys.luodong.bakery_corner" }),
              let riverside = anchors.first(where: { $0.siteID == "sys.luodong.riverside_bench" }) else {
            return Stage1VerificationSummary(
                gate1ProximityAndDay3CallbackPassed: false,
                gate2ImmutableSnapshotPassed: false,
                gate3DisjointCoinLedgerPassed: false,
                gate4SingleDayErasurePassed: false,
                details: ["找不到預設街角錨點。"]
            )
        }

        let farCoord = AnchorRotationEngine.coordinateAhead(from: CLLocationCoordinate2D(latitude: bakery.lat, longitude: bakery.lon), meters: 220, bearingDegrees: 180)
        locationService.walkSimulated(to: farCoord, stepsSegments: 2)
        let farCheck = AnchorRotationEngine.evaluateProximity(
            anchor: bakery,
            userLocation: locationService.currentLocation,
            now: Date(),
            currentLocalDateISO: currentLocalDateISO
        )
        let rejectedWhenFar: Bool
        if case .tooFar = farCheck { rejectedWhenFar = true } else { rejectedWhenFar = false }

        let nearBakery = AnchorRotationEngine.coordinateAhead(from: CLLocationCoordinate2D(latitude: bakery.lat, longitude: bakery.lon), meters: 12, bearingDegrees: 0)
        locationService.walkSimulated(to: nearBakery, stepsSegments: 4)
        let day1ISO = currentLocalDateISO
        let offeredDay1 = AnchorRotationEngine.resolveAndPersistOfferedPetID(anchor: bakery, residents: residents, ledger: ledger)
        let day1Log = commitStreetEncounter(siteID: bakery.siteID, petID: offeredDay1, gesture: .offerHand, inviteHome: true)
        let day1SnapshotBytes = day1Log?.bakedSnapshotPNGData
        details.append("第 1 天 (\(day1ISO))：遠距阻擋=\(rejectedWhenFar)；素頸遇見\(PetCatalog.pet(id: offeredDay1).name)。")

        advanceSimulatedDays(1)
        let day2ISO = currentLocalDateISO
        let intervalA = currentSimulatedDate
        let intervalB = currentSimulatedDate.addingTimeInterval(900)
        _ = ingestSteps(steps: 5_840, intervalStartUTC: intervalA, placeLabel: bakery.customLabel)
        _ = ingestSteps(steps: 5_840, intervalStartUTC: intervalA, placeLabel: bakery.customLabel)
        _ = ingestSteps(steps: 160, intervalStartUTC: intervalB, placeLabel: bakery.customLabel)
        let coinsBeforePurchase = ledger.coinBalance
        let sageRibbon = ShopCatalog.item(id: "outfit.sage_ribbon")!
        let boughtRibbon = purchaseItem(sageRibbon, txID: "fixture.buy.sage_ribbon")
        _ = purchaseItem(sageRibbon, txID: "fixture.buy.sage_ribbon")
        let coinsAfterRibbon = ledger.coinBalance
        let gate3Passed = (coinsBeforePurchase == 30) && boughtRibbon && (coinsAfterRibbon == 18) && (ledger.stepCarryRemainder == 0)
        details.append("第 2 天 (\(day2ISO))：5,840+160 步 → \(coinsBeforePurchase) 幣 − 12 幣緞帶 = \(coinsAfterRibbon) 幣。")

        equipOutfit(petID: "pet.01", outfitID: sageRibbon.id)
        let offeredDay2 = AnchorRotationEngine.resolveAndPersistOfferedPetID(anchor: bakery, residents: residents, ledger: ledger)
        let day2Log = commitStreetEncounter(siteID: bakery.siteID, petID: offeredDay2, gesture: .offerHand, inviteHome: true)
        let day1AfterReload = encounters.first(where: { $0.localDateISO == day1ISO && $0.petID == "pet.01" })
        let gate2Passed =
            day1AfterReload?.equippedOutfitSnapshotID == nil &&
            day2Log?.equippedOutfitSnapshotID == sageRibbon.id &&
            day1AfterReload?.bakedSnapshotPNGData != nil &&
            day2Log?.bakedSnapshotPNGData != nil &&
            day1AfterReload?.bakedSnapshotPNGData == day1SnapshotBytes &&
            day1AfterReload?.bakedSnapshotPNGData != day2Log?.bakedSnapshotPNGData
        details.append("歷史明信片驗證：第 1 天素頸原圖未受第 2 天緞帶影響=\(gate2Passed)。")

        advanceSimulatedDays(1)
        activeWeather = .overcast
        let offeredTap3 = AnchorRotationEngine.resolveAndPersistOfferedPetID(anchor: bakery, residents: residents, ledger: ledger)
        let cinderLog = commitStreetEncounter(siteID: bakery.siteID, petID: offeredTap3, gesture: .crouchQuietly, inviteHome: true)

        let nearRiver = AnchorRotationEngine.coordinateAhead(from: CLLocationCoordinate2D(latitude: riverside.lat, longitude: riverside.lon), meters: 10, bearingDegrees: 0)
        locationService.walkSimulated(to: nearRiver, stepsSegments: 3)
        let misoOffer = AnchorRotationEngine.resolveAndPersistOfferedPetID(anchor: riverside, residents: residents, ledger: ledger)
        _ = commitStreetEncounter(siteID: riverside.siteID, petID: misoOffer, gesture: .rollBall, inviteHome: true)

        advanceSimulatedDays(1)
        let sesameBeforeDay3 = resident(for: "pet.01")!
        let callbackSelection = NarrativeEngine.selectStreetScene(
            pet: sesameBeforeDay3,
            anchorLabel: bakery.customLabel,
            weather: .overcast,
            chosenGesture: .offerHand,
            localDateISO: currentLocalDateISO,
            pastEncounters: encounters,
            activeIntentions: teachingIntentions
        )
        locationService.walkSimulated(to: nearBakery, stepsSegments: 3)
        _ = commitStreetEncounter(siteID: bakery.siteID, petID: "pet.01", gesture: .offerHand, inviteHome: true)

        let gate1Passed =
            rejectedWhenFar &&
            offeredTap3 == "pet.03" &&
            cinderLog != nil &&
            callbackSelection.sceneRevisionID.contains("milestone.day3.callback.offer_hand")
        details.append("第 3–4 天驗證：第 3 輪保底奇幻訪客=\(PetCatalog.pet(id: offeredTap3).name)；芝麻記得首日手勢。")

        advanceSimulatedDays(10)
        activeWeather = .dusk
        solveHomeRoomNow()

        let coinsBeforeErase = ledger.coinBalance
        let invitedCountBeforeErase = residents.filter { $0.inviteState == .invitedHome }.count
        erasePlaceDataForSingleDay(localDateISO: day1ISO)
        let erasedDay = diaryDays.first(where: { $0.localDateISO == day1ISO })
        let erasedEnc = encounters.first(where: { $0.localDateISO == day1ISO && $0.petID == "pet.01" })
        let gate4Passed =
            erasedDay?.deletionState == .placeErased &&
            erasedDay?.routeTrackGeoJSON == nil &&
            erasedEnc?.placeRedacted == true &&
            ledger.coinBalance == coinsBeforeErase &&
            residents.filter { $0.inviteState == .invitedHome }.count == invitedCountBeforeErase
        details.append("第 14 天隱私抹除：已清除第 1 天路線與地名，完整保留 \(invitedCountBeforeErase) 位室友與 \(ledger.coinBalance) 步數幣。")

        let report = Stage1VerificationSummary(
            gate1ProximityAndDay3CallbackPassed: gate1Passed,
            gate2ImmutableSnapshotPassed: gate2Passed,
            gate3DisjointCoinLedgerPassed: gate3Passed,
            gate4SingleDayErasurePassed: gate4Passed,
            details: details
        )
        latestFixtureReport = report
        return report
    }

    func showWhisper(_ text: String) {
        transientWhisper = text
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.2))
            if self.transientWhisper == text {
                self.transientWhisper = nil
            }
        }
    }
}
