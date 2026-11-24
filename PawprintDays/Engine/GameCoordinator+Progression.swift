import Foundation
import CoreLocation

/// Gameplay progression layer: first-session doorstep corner, location fallback, favourite greeting
/// gestures, curio gifts & sets, "walk with me" quests, special time/weather visitors, staged feature
/// unlocks and the street "next goal" hint.
extension GameCoordinator {
    // MARK: - Mutation helper
    func updateIndoorState(_ body: (inout SunroomIndoorState) -> Void) {
        var state = ledger.indoorState
        body(&state)
        ledger.indoorState = state
    }

    // MARK: - Doorstep Corner & Location Fallback

    /// True on a real device where the player has denied or restricted location access, which makes
    /// every street corner unreachable. The UI shows a fallback card when this is set.
    var isStreetLocationUnavailable: Bool {
        guard !locationService.useSimulatedPosition else { return false }
        let status = locationService.authorizationStatus
        return status == .denied || status == .restricted
    }

    /// On the first trustworthy real GPS fix, place one "doorstep" corner ~45 m ahead so a brand-new
    /// player meets someone within minutes instead of needing a nearby café or park. The sample Luodong
    /// corners are tucked away at the same time when the player is far from them.
    @discardableResult
    func ensureDoorstepCornerIfNeeded(around location: CLLocation) -> AnchorSiteRecord? {
        guard !indoorState.hasPlacedDoorstepCorner else { return nil }
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 65 else { return nil }

        hideSampleNeighborhoodCornersIfFar(from: location.coordinate)

        let alreadyClose = visibleAnchors.contains { anchor in
            !anchor.siteID.hasPrefix("sys.luodong.") &&
            location.distance(from: CLLocation(latitude: anchor.lat, longitude: anchor.lon)) <= 120
        }
        updateIndoorState { $0.hasPlacedDoorstepCorner = true }
        guard !alreadyClose else {
            try? modelContext.save()
            reloadAll()
            return nil
        }

        let ahead = AnchorRotationEngine.coordinateAhead(from: location.coordinate, meters: 45, bearingDegrees: 30)
        // Prefer a companion the player hasn't met yet so the very first walk welcomes someone new.
        let regularID = residents.first(where: { $0.inviteState == .unmet })?.petID
            ?? MapKitAnchorDiscoveryService.pickRegularPetID(forIndex: 0, residents: residents)
        let record = AnchorSiteRecord(
            siteID: "local.doorstep.\(UUID().uuidString.prefix(6))",
            lat: ahead.latitude,
            lon: ahead.longitude,
            radiusM: 75,
            customLabel: "家門口轉角",
            regularPetID: regularID,
            cycleTapCount: 0,
            isFamiliarCorner: false
        )
        modelContext.insert(record)
        try? modelContext.save()
        reloadAll()
        showWhisper("前方 45 公尺的「家門口轉角」有隻小腳印在等你，走過去打聲招呼吧！")
        return record
    }

    func hideSampleNeighborhoodCornersIfFar(from coordinate: CLLocationCoordinate2D) {
        let origin = CLLocation(
            latitude: LocationService.defaultNeighborhoodOrigin.latitude,
            longitude: LocationService.defaultNeighborhoodOrigin.longitude
        )
        let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard here.distance(from: origin) > 1_500 else { return }
        for anchor in anchors where anchor.siteID.hasPrefix("sys.luodong.") && !anchor.isHiddenByUser {
            anchor.isHiddenByUser = true
        }
    }

    // MARK: - Favourite Greeting Gestures

    func isFavoriteGesture(_ gesture: GreetingGesture, for petID: String, weather: WeatherMode? = nil) -> Bool {
        let spec = PetCatalog.pet(id: petID)
        if gesture == .holdUmbrella && spec.kind.isCatFamily && (weather ?? activeWeather).isRainy {
            return true // Every cat loves sheltering under your umbrella in the rain.
        }
        return gesture == spec.favoriteGreeting
    }

    func hasDiscoveredFavoriteGesture(for petID: String) -> Bool {
        indoorState.discoveredFavoriteGesturePetIDs.contains(petID)
    }

    /// Applies the favourite-greeting reward (or a soft hint) after a street greeting. Coins are only
    /// granted for the first greeting with that companion each day.
    @discardableResult
    func applyGreetingPreferenceOutcome(petID: String, gesture: GreetingGesture, isFirstGreetingToday: Bool) -> Bool {
        let spec = PetCatalog.pet(id: petID)
        let name = displayName(for: petID)
        lastGreetingFeedback = nil
        guard isFavoriteGesture(gesture, for: petID) else {
            if isFirstGreetingToday {
                let hint = "\(name)友善地回應了你，不過牠似乎更期待\(spec.favoriteGreetingHint)…"
                lastGreetingFeedback = hint
                showWhisper(hint)
            }
            return false
        }
        let firstDiscovery = !hasDiscoveredFavoriteGesture(for: petID)
        if firstDiscovery {
            updateIndoorState { $0.discoveredFavoriteGesturePetIDs.append(petID) }
        }
        if isFirstGreetingToday {
            ledger.coinBalance += 2
        }
        try? modelContext.save()
        reloadAll()
        let coinNote = isFirstGreetingToday ? "（+2 步數幣）" : ""
        if firstDiscovery {
            lastGreetingFeedback = "♡ 發現了！\(name)最喜歡「\(gesture.title)」的招呼方式\(coinNote)"
        } else {
            lastGreetingFeedback = "♡ \(name)開心地蹭了蹭你——這是牠最喜歡的招呼\(coinNote)"
        }
        if let feedback = lastGreetingFeedback { showWhisper(feedback) }
        return true
    }

    // MARK: - Curio Gifts & Weather Sets

    func isCurioGifted(_ entry: ForagedCurioEntry) -> Bool {
        indoorState.giftedCurioEntryIDs.contains(entry.id)
    }

    /// Gives a foraged curio to a companion. The curio stays in the collection (it moves to their
    /// windowsill corner), counts as a shared moment for the bond, and a curio the companion
    /// especially likes adds a coin and a diary note.
    @discardableResult
    func giftCurio(entryID: UUID, to petID: String) -> Bool {
        guard let entry = ledger.foragedCurios.first(where: { $0.id == entryID }),
              !isCurioGifted(entry),
              let pet = resident(for: petID), pet.inviteState == .invitedHome else { return false }
        let curio = CurioCatalog.curio(id: entry.curioID)
        let spec = PetCatalog.pet(id: petID)
        let name = displayName(for: petID)
        let loved = spec.resonantWeathers.contains(curio.weatherTag)
        let dateISO = currentLocalDateISO
        let previousBondTier = PetResidentState.milestoneForSharedDays(pet.sharedDaysCount)

        updateIndoorState { $0.giftedCurioEntryIDs.append(entry.id) }
        if pet.lastSharedDateISO != dateISO {
            pet.sharedDaysCount += 1
            pet.lastSharedDateISO = dateISO
            pet.milestoneTier = PetResidentState.milestoneForSharedDays(pet.sharedDaysCount)
        }
        if loved { ledger.coinBalance += 1 }
        let note = loved
            ? "把「\(curio.name)」送給了\(name)，牠珍惜地收進自己的小角落，眼睛亮晶晶的。"
            : "把「\(curio.name)」送給了\(name)，牠好奇地嗅了嗅，收下了這份心意。"
        let day = todayDiaryRecord()
        if !day.revisitNotes.contains(note) { day.revisitNotes.append(note) }
        try? modelContext.save()
        reloadAll()
        nurtureAllGrowingOffspring(axis: .gentle, bonusSteps: 0)
        HapticsEngine.shared.playCurioUnpack()
        CozySoundEngine.shared.playPaperFlip()
        showWhisper(loved ? "\(name)超喜歡「\(curio.name)」！（+1 步數幣，相伴天數 +1）" : "\(name)收下了「\(curio.name)」。")
        celebrateBondTierUpIfNeeded(petID: petID, previousTier: previousBondTier, newTier: pet.milestoneTier)
        return true
    }

    struct CurioSetProgress: Identifiable, Sendable {
        var id: String { weather.rawValue }
        let weather: WeatherMode
        let foundCount: Int
        let totalCount: Int
        let isClaimed: Bool
        var isComplete: Bool { foundCount >= totalCount }
        var rewardCoins: Int { 10 + totalCount * 2 }
    }

    var curioSetProgress: [CurioSetProgress] {
        let found = Set(ledger.foragedCurios.map(\.curioID))
        let claimed = Set(indoorState.claimedCurioSetWeatherCodes)
        return WeatherMode.allCases.compactMap { weather in
            let members = CurioCatalog.all.filter { $0.weatherTag == weather }
            guard !members.isEmpty else { return nil }
            return CurioSetProgress(
                weather: weather,
                foundCount: members.filter { found.contains($0.id) }.count,
                totalCount: members.count,
                isClaimed: claimed.contains(weather.rawValue)
            )
        }
    }

    @discardableResult
    func claimCurioSetReward(weather: WeatherMode) -> Bool {
        guard let set = curioSetProgress.first(where: { $0.weather == weather }),
              set.isComplete, !set.isClaimed else { return false }
        updateIndoorState { $0.claimedCurioSetWeatherCodes.append(weather.rawValue) }
        ledger.coinBalance += set.rewardCoins
        let day = todayDiaryRecord()
        let note = "集齊了「\(weather.displayName)」的全部街區拾遺，在日記頁貼上一枚紀念封蠟。"
        if !day.revisitNotes.contains(note) { day.revisitNotes.append(note) }
        try? modelContext.save()
        reloadAll()
        CozySoundEngine.shared.playCompassChime()
        HapticsEngine.shared.playCurioUnpack()
        showWhisper("集齊「\(weather.displayName)」拾遺套組！（+\(set.rewardCoins) 步數幣）")
        emitMilestoneCelebration(MilestoneCelebration(
            id: "curioSet.\(weather.rawValue)",
            kind: .curioSet,
            title: "「\(weather.displayName)」拾遺套組集齊了",
            subtitle: "\(set.totalCount) 件小物都安穩收進木格櫃",
            detail: "日記頁貼上了一枚\(weather.displayName)紀念封蠟。下次在這樣的天氣出門，記得抬頭看看天空。",
            symbol: weather.sfSymbol,
            accentHex: "#C98D26",
            rewardBadge: "+\(set.rewardCoins) 步數幣"
        ), onceKey: "curioSet.\(weather.rawValue)")
        return true
    }

    // MARK: - "Walk With Me" Quests

    var activeWalkQuestToday: WalkWithMeQuest? {
        guard let quest = indoorState.activeWalkQuest, quest.localDateISO == currentLocalDateISO else { return nil }
        return quest
    }

    /// After a street greeting a companion may ask you to keep walking with it for a few hundred steps.
    @discardableResult
    func offerWalkQuestIfAppropriate(petID: String) -> WalkWithMeQuest? {
        guard activeWalkQuestToday == nil else { return nil }
        let target = 500 + (StableHash.value("\(petID)#\(currentLocalDateISO)") % 3) * 150
        let quest = WalkWithMeQuest(petID: petID, localDateISO: currentLocalDateISO, targetSteps: target)
        updateIndoorState { $0.activeWalkQuest = quest }
        try? modelContext.save()
        return quest
    }

    func advanceWalkQuest(by steps: Int) {
        guard steps > 0, var quest = activeWalkQuestToday, !quest.isComplete else { return }
        quest.progressSteps += steps
        let finished = quest.isComplete
        updateIndoorState { state in
            state.activeWalkQuest = finished ? nil : quest
            if finished { state.completedWalkQuestCount += 1 }
        }
        guard finished else { return }
        ledger.coinBalance += WalkWithMeQuest.rewardCoins
        let name = displayName(for: quest.petID)
        let note = "\(name)陪我多走了 \(quest.targetSteps) 步，一路上踩著落葉哼著小調。"
        let day = todayDiaryRecord()
        if !day.revisitNotes.contains(note) { day.revisitNotes.append(note) }
        nurtureAllGrowingOffspring(axis: .brave, bonusSteps: 0)
        CozySoundEngine.shared.playCompassChime()
        HapticsEngine.shared.playCurioUnpack()
        showWhisper("和\(name)一起走完 \(quest.targetSteps) 步！牠滿足地搖搖尾巴（+\(WalkWithMeQuest.rewardCoins) 步數幣）。")
    }

    // MARK: - Special Time-of-Day & Weather Visitors

    struct SpecialVisitorRule: Sendable {
        let key: String
        let petID: String
        let arrivalLine: String
    }

    /// Which special visitor (if any) could appear at a corner right now.
    func specialVisitorRule(now: Date = Date(), weather: WeatherMode? = nil) -> SpecialVisitorRule? {
        let hour = Calendar.current.component(.hour, from: now)
        let w = weather ?? activeWeather
        if w.isRainy {
            return SpecialVisitorRule(key: "rain", petID: "pet.08", arrivalLine: "雨絲裡，鹿角森靈犬特地踏著水窪來街角找你了！")
        }
        if w == .dusk || (17..<20).contains(hour) {
            return SpecialVisitorRule(key: "dusk", petID: "pet.04", arrivalLine: "暮色時分，夜魔小貓舒展翅膀落在了街角！")
        }
        if hour >= 20 || hour < 5 {
            return SpecialVisitorRule(key: "night", petID: "pet.07", arrivalLine: "月光下，銀月星靈犬踩著雲步來和你打招呼！")
        }
        if (5..<9).contains(hour) {
            return SpecialVisitorRule(key: "morning", petID: "pet.03", arrivalLine: "晨光裡，餘燼把石階烘得暖暖的，在街角等你！")
        }
        return nil
    }

    /// Once per civil day per rule, the first corner you open during that window hosts the special visitor
    /// instead of the usual rotation (only when it isn't already that corner's regular).
    func applySpecialVisitorIfEligible(anchor: AnchorSiteRecord, now: Date = Date()) -> SpecialVisitorRule? {
        guard anchor.cachedVisitorOfferID == nil,
              let rule = specialVisitorRule(now: now),
              rule.petID != anchor.regularPetID,
              resident(for: rule.petID) != nil,
              indoorState.specialVisitorDates[rule.key] != currentLocalDateISO else { return nil }
        updateIndoorState { $0.specialVisitorDates[rule.key] = currentLocalDateISO }
        anchor.cachedVisitorOfferID = rule.petID
        return rule
    }

    // MARK: - Staged Feature Unlocks

    enum GameFeature: Sendable {
        case errands
        case nesting
        case mentorship

        var lockedHint: String {
            switch self {
            case .errands: return "完成第一次街角相遇，或與夥伴相伴滿 2 天後，就能派小靈獸獨自出門探險。"
            case .nesting: return "陽光室住進 3 位以上的室友後，才會出現結緣築巢的溫柔時刻。"
            case .mentorship: return "邀請第 2 位室友回家後，就能安排跨物種的習慣傳承。"
            }
        }
    }

    var invitedCompanionCount: Int {
        residents.filter { $0.inviteState == .invitedHome }.count
    }

    func isFeatureUnlocked(_ feature: GameFeature) -> Bool {
        switch feature {
        case .errands:
            let hasStreetEncounter = encounters.contains { !$0.siteID.hasPrefix("home.") }
            let bondDays = residents.map(\.sharedDaysCount).max() ?? 0
            return hasStreetEncounter || bondDays >= 2 || indoorState.activeErrand != nil || !indoorState.errandHistory.isEmpty
        case .nesting:
            return invitedCompanionCount >= 3 || !indoorState.offsprings.isEmpty
        case .mentorship:
            return invitedCompanionCount >= 2
        }
    }

    // MARK: - Street "Next Goal" Hint

    struct NextGoalHint: Sendable, Equatable {
        let icon: String
        let text: String
    }

    var nextGoalHint: NextGoalHint? {
        let today = currentLocalDateISO

        if isStreetLocationUnavailable {
            return NextGoalHint(icon: "location.slash", text: "定位未開啟：街角相遇需要位置權限。你仍可在陽光室窗邊結識新朋友、派小靈獸探險。")
        }
        if let quest = activeWalkQuestToday {
            return NextGoalHint(icon: "figure.walk", text: "\(displayName(for: quest.petID))想再陪你走 \(quest.remainingSteps) 步（完成 +\(WalkWithMeQuest.rewardCoins) 幣）")
        }
        if let errand = indoorState.activeErrand, errand.isReadyToReturn(at: currentSimulatedDate) {
            return NextGoalHint(icon: "envelope.open.fill", text: "\(displayName(for: errand.petID))探險回來了，回陽光室收下明信片吧！")
        }
        if encounters.isEmpty, let nearest = visibleAnchors.min(by: { distanceMeters(to: $0) < distanceMeters(to: $1) }) {
            return NextGoalHint(icon: "pawprint.fill", text: "第一位街角朋友在「\(nearest.customLabel)」（約 \(Int(distanceMeters(to: nearest))) 公尺），走近 75 公尺內輕點足印。")
        }
        if let set = curioSetProgress.first(where: { $0.isComplete && !$0.isClaimed }) {
            return NextGoalHint(icon: "seal.fill", text: "「\(set.weather.displayName)」拾遺已集齊！到拾遺櫃領取套組獎勵。")
        }
        if let growing = indoorState.offsprings.first(where: { $0.growthStage != .grown }) {
            return NextGoalHint(icon: "sparkles", text: "「\(growing.name)」：\(growing.nextMilestoneHint)")
        }
        let unvisited = visibleAnchors.filter { $0.lastVisitedLocalDate != today }
        if let nearest = unvisited.min(by: { distanceMeters(to: $0) < distanceMeters(to: $1) }) {
            let dist = Int(distanceMeters(to: nearest))
            if let rule = specialVisitorRule(), indoorState.specialVisitorDates[rule.key] != today,
               rule.petID != nearest.regularPetID {
                return NextGoalHint(icon: "moon.stars.fill", text: "這個時段可能有特別訪客！「\(nearest.customLabel)」約 \(dist) 公尺。")
            }
            if let closest = residents
                .filter({ $0.inviteState == .invitedHome })
                .compactMap({ pet -> (PetResidentState, Int)? in
                    guard let next = Self.nextMilestoneDays(after: pet.sharedDaysCount) else { return nil }
                    return (pet, next - pet.sharedDaysCount)
                })
                .min(by: { $0.1 < $1.1 }), closest.1 <= 2, closest.0.lastSharedDateISO != today {
                return NextGoalHint(icon: "heart.fill", text: "再相伴 \(closest.1) 天，\(displayName(for: closest.0.petID))就會升到下一個羈絆階段。")
            }
            return NextGoalHint(icon: "map.fill", text: "今天還沒拜訪「\(nearest.customLabel)」（約 \(dist) 公尺）。")
        }
        return nil
    }

    static func nextMilestoneDays(after days: Int) -> Int? {
        [1, 3, 6, 10, 15, 25].first(where: { $0 > days })
    }
}

// MARK: - Zero-FOMO Cozy Stamp Card, Milestone Celebrations & Progress Snapshots
extension GameCoordinator {
    // MARK: Cozy stamp card

    var hasEarnedCozyStampToday: Bool {
        indoorState.lastStampAwardedDateISO == currentLocalDateISO
    }

    /// Stamps already on the current card (0...6).
    var cozyStampCountInCard: Int {
        indoorState.stampCountInCard
    }

    /// Awards today's single cozy stamp (street greeting, a real stroll, or all three daily wishes).
    /// At most one per civil day, and missed days never erase progress. The 7th stamp completes the
    /// card: +15 coins, a keepsake diary line, a fresh card, and a storybook celebration.
    @discardableResult
    func awardDailyCozyStampIfEligible(reason: String) -> Bool {
        let today = currentLocalDateISO
        guard indoorState.lastStampAwardedDateISO != today else { return false }

        var completedCardNumber: Int? = nil
        updateIndoorState { state in
            state.lastStampAwardedDateISO = today
            let next = min(max(state.stampCountInCard, 0), CozyStampCard.slotCount - 1) + 1
            if next >= CozyStampCard.slotCount {
                state.stampCountInCard = 0
                state.completedStampCardsCount += 1
                completedCardNumber = state.completedStampCardsCount
            } else {
                state.stampCountInCard = next
            }
        }

        if let cardNumber = completedCardNumber {
            ledger.coinBalance += CozyStampCard.completionRewardCoins
            let note = "足印集章卡第 \(cardNumber) 張蓋滿了！七個慢慢走過的日子，一枚一枚都是我們的小小約定。（+\(CozyStampCard.completionRewardCoins) 步數幣）"
            let day = todayDiaryRecord()
            if !day.revisitNotes.contains(note) { day.revisitNotes.append(note) }
            try? modelContext.save()
            reloadAll()
            CozySoundEngine.shared.playCompassChime()
            HapticsEngine.shared.playCurioUnpack()
            emitMilestoneCelebration(MilestoneCelebration(
                id: "stampCard.\(cardNumber)",
                kind: .stampCard,
                title: "足印集章卡蓋滿了",
                subtitle: "第 \(cardNumber) 張 · 七枚小印章",
                detail: "不必天天打卡，只要想出門的時候就出門——今天的「\(reason)」替這張卡蓋上了最後一枚印章。新的一張已經悄悄攤開。",
                symbol: "seal.fill",
                accentHex: "#B84A39",
                rewardBadge: "+\(CozyStampCard.completionRewardCoins) 步數幣"
            ), onceKey: "stampCard.\(cardNumber)")
        } else {
            try? modelContext.save()
            reloadAll()
            HapticsEngine.shared.playBrushStrokeTick()
        }
        return true
    }

    // MARK: Milestone celebrations

    /// Shows a celebration now, or queues it behind the one on screen. With `onceKey`, the same
    /// celebration is never shown twice (the key is remembered in the save file).
    func emitMilestoneCelebration(_ celebration: MilestoneCelebration, onceKey: String? = nil) {
        if let key = onceKey {
            guard !indoorState.unlockedCelebratedFeatures.contains(key) else { return }
            updateIndoorState { $0.unlockedCelebratedFeatures.append(key) }
            try? modelContext.save()
        }
        if pendingMilestoneCelebration == nil {
            pendingMilestoneCelebration = celebration
        } else if pendingMilestoneCelebration?.id != celebration.id,
                  !queuedMilestoneCelebrations.contains(where: { $0.id == celebration.id }) {
            queuedMilestoneCelebrations.append(celebration)
        }
    }

    func dismissMilestoneCelebration() {
        pendingMilestoneCelebration = queuedMilestoneCelebrations.isEmpty ? nil : queuedMilestoneCelebrations.removeFirst()
    }

    func celebrateNewCompanionIfNeeded(petID: String) {
        let spec = PetCatalog.pet(id: petID)
        let name = displayName(for: petID)
        emitMilestoneCelebration(MilestoneCelebration(
            id: "welcome.\(petID)",
            kind: .newCompanion,
            title: "\(name)搬進陽光室了",
            subtitle: "第 \(invitedCompanionCount) 位室友 · \(spec.personalityWord)",
            detail: "牠在木地板上繞了一圈，挑好最喜歡的角落。往後的散步、茶點與午睡，都多了一個小小身影。",
            symbol: "house.fill",
            accentHex: spec.accentHex,
            rewardBadge: nil
        ), onceKey: "welcome.\(petID)")
    }

    /// Celebrates reaching a new bond tier (Day 3, 6, 10, 15 and 25), naming exactly what it unlocks.
    func celebrateBondTierUpIfNeeded(petID: String, previousTier: Int, newTier: Int) {
        guard newTier > previousTier, newTier >= 2 else { return }
        let name = displayName(for: petID)
        let spec = PetCatalog.pet(id: petID)
        let perk = Self.bondTierPerk(tier: newTier, petID: petID)
        emitMilestoneCelebration(MilestoneCelebration(
            id: "bond.\(petID).tier\(newTier)",
            kind: .bondTierUp,
            title: "和\(name)成為「\(Self.bondTierTitle(newTier))」",
            subtitle: "相伴第 \(Self.bondTierStartDays(newTier)) 天",
            detail: perk,
            symbol: "heart.fill",
            accentHex: spec.accentHex,
            rewardBadge: nil
        ), onceKey: "bond.\(petID).tier\(newTier)")
    }

    func celebrateRoomPurchaseIfNeeded(_ item: ShopItemSpec) {
        if let theme = SeasonalRoomTheme(rawValue: item.id) {
            emitMilestoneCelebration(MilestoneCelebration(
                id: "theme.\(theme.rawValue)",
                kind: .roomTheme,
                title: "陽光室換上「\(item.name)」",
                subtitle: "屋景已經掛好 · 隨時可在小舖切換",
                detail: item.summary,
                symbol: "sun.max.fill",
                accentHex: item.swatchHex,
                rewardBadge: nil
            ), onceKey: "theme.\(theme.rawValue)")
        } else if item.id == "room.rain_veranda" {
            emitMilestoneCelebration(MilestoneCelebration(
                id: "veranda",
                kind: .veranda,
                title: "雨廊木檐蓋好了",
                subtitle: "陽光室多了 3 處新角落",
                detail: "雨天裡，室友們可以在新木檐下聽雨、打盹，再也不怕窗邊太擠。",
                symbol: "house.lodge.fill",
                accentHex: item.swatchHex,
                rewardBadge: nil
            ), onceKey: "veranda")
        }
    }

    // MARK: Bond progress

    static let bondMilestoneDays: [Int] = [1, 3, 6, 10, 15, 25]

    static func bondTierTitle(_ tier: Int) -> String {
        switch tier {
        case 1: return "初次相遇"
        case 2: return "熟悉面孔"
        case 3: return "散步同伴"
        case 4: return "心照不宣"
        case 5: return "溫柔導師"
        case 6: return "街角柱石"
        default: return "尚未遇見"
        }
    }

    /// Shared days at which `tier` begins (tier 0 begins at 0).
    static func bondTierStartDays(_ tier: Int) -> Int {
        guard tier >= 1 else { return 0 }
        return bondMilestoneDays[min(tier, bondMilestoneDays.count) - 1]
    }

    static func bondTierPerk(tier: Int, petID: String) -> String {
        let spec = PetCatalog.pet(id: petID)
        switch tier {
        case 2:
            let chapter = MysticalFolkloreCatalog.chapters(for: petID).first { $0.requiredSharedDays == 3 }
            if let chapter {
                return "解鎖新的回憶篇章「\(chapter.title)」，到陽光室的奇譚繪本翻開讀讀看吧。"
            }
            return "解鎖一段新的回憶篇章，到陽光室的奇譚繪本翻開讀讀看吧。"
        case 3:
            return "從今天起，在街角相遇時牠偶爾會遞上一份小禮物。"
        case 4:
            return "牠願意在陽光室展示招牌習慣「\(spec.signatureHabitTitle)」了。"
        case 5:
            return "牠可以當溫柔導師，把「\(spec.signatureHabitTitle)」傳授給其他室友。"
        case 6:
            return "牠成了你的街角柱石，年度約定裡多了一頁專屬的相伴紀念跨頁。"
        default:
            return "你們又更靠近了一點。"
        }
    }

    func bondProgress(for petID: String) -> BondProgressSnapshot {
        let days = resident(for: petID)?.sharedDaysCount ?? 0
        let tier = PetResidentState.milestoneForSharedDays(days)
        let next = Self.nextMilestoneDays(after: days)
        let start = Self.bondTierStartDays(tier)
        let fraction: Double
        if let next {
            fraction = min(1, max(0, Double(days - start) / Double(max(1, next - start))))
        } else {
            fraction = 1
        }
        return BondProgressSnapshot(
            petID: petID,
            currentTier: tier,
            currentTierTitle: Self.bondTierTitle(tier),
            nextTierTitle: next == nil ? nil : Self.bondTierTitle(tier + 1),
            sharedDays: days,
            nextMilestoneDays: next,
            daysRemaining: next.map { max(0, $0 - days) } ?? 0,
            progressFraction: fraction
        )
    }

    // MARK: Journey summary

    var journeyProgress: JourneyProgressSummary {
        let sets = curioSetProgress
        return JourneyProgressSummary(
            companionsInvited: invitedCompanionCount,
            companionsTotal: PetCatalog.allPets.count,
            curiosDiscovered: Set(ledger.foragedCurios.map(\.curioID)).count,
            curiosTotal: CurioCatalog.all.count,
            weatherSetsCompleted: sets.filter(\.isComplete).count,
            weatherSetsTotal: sets.count,
            stampCountInCard: indoorState.stampCountInCard,
            completedStampCards: indoorState.completedStampCardsCount,
            themesOwned: Set(ledger.ownedRoomThemeIDs).count
        )
    }

    // MARK: Stroll postcard stamp snapshot

    /// Remembers the stamp card and pocket-find countdown right after a stroll, so the summary
    /// postcard can show them even when it is presented without a coordinator.
    func recordStrollStampSnapshot(for summaryID: UUID) {
        StrollStampSnapshot.store[summaryID] = StrollStampSnapshot(
            stampCountInCard: indoorState.stampCountInCard,
            completedStampCards: indoorState.completedStampCardsCount,
            stampedToday: hasEarnedCozyStampToday,
            stepsUntilNextPocketFind: stepsUntilNextPocketFind,
            pocketFindsLeftToday: max(0, StepCoinLedgerEngine.dailyPocketFindCap(for: ledger) - todaysPocketFindCount)
        )
    }
}

/// Stamp-card state captured at the end of a stroll for the summary postcard.
struct StrollStampSnapshot: Equatable, Sendable {
    let stampCountInCard: Int
    let completedStampCards: Int
    let stampedToday: Bool
    let stepsUntilNextPocketFind: Int
    let pocketFindsLeftToday: Int

    /// Number of filled slots to draw on the 7-slot card (a just-completed card shows all 7).
    var filledSlots: Int {
        stampedToday && stampCountInCard == 0 && completedStampCards > 0 ? CozyStampCard.slotCount : stampCountInCard
    }

    @MainActor static var store: [UUID: StrollStampSnapshot] = [:]
}

// MARK: - Species greeting preferences
extension PetSpec {
    /// The greeting each companion secretly loves most (discovered through play).
    var favoriteGreeting: GreetingGesture {
        switch id {
        case "pet.02": return .crouchQuietly // 傲嬌講究: don't crowd him
        case "pet.03": return .offerHand     // 溫柔小心: a gentle open hand
        case "pet.04": return .crouchQuietly // 好奇安靜: quiet company
        case "pet.06": return .rollBall      // 忠厚貼心: fetch!
        case "pet.07": return .offerHand     // 溫和耐心
        case "pet.08": return .rollBall      // 敏銳細心: loves a chase
        default: return .offerHand
        }
    }

    var favoriteGreetingHint: String {
        switch favoriteGreeting {
        case .offerHand: return "你伸出手、讓牠先聞聞"
        case .crouchQuietly: return "你安安靜靜地坐在一旁陪著"
        case .rollBall: return "一起玩點會滾動的東西"
        case .holdUmbrella: return "雨天裡有人替牠撐傘"
        }
    }
}
