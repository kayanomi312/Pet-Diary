import Foundation
import SwiftData

extension GameCoordinator {
    // MARK: - Indoor State Persistence Helper
    private func mutateIndoorState(_ body: (inout SunroomIndoorState) -> Void) {
        var state = ledger.indoorState
        body(&state)
        ledger.indoorState = state
        try? modelContext.save()
        reloadAll()
    }

    var indoorState: SunroomIndoorState {
        ledger.indoorState
    }

    // MARK: - 1. Gentle Daily Cozy Wishes (Zero-FOMO)
    var todayWishesBoard: DailyWishesBoard {
        let iso = currentLocalDateISO
        let state = ledger.indoorState
        if let board = state.dailyWishes, board.localDateISO == iso {
            return board
        }
        return DailyWishesBoard.generate(for: iso, hasOffspring: !state.offsprings.isEmpty)
    }

    var unclaimedCompletedWishesCount: Int {
        todayWishesBoard.wishes.filter { $0.isCompleted && !$0.isClaimed }.count
    }

    func markDailyWishCompleted(_ kind: DailyWishKind) {
        let iso = currentLocalDateISO
        mutateIndoorState { state in
            var board = (state.dailyWishes?.localDateISO == iso)
                ? state.dailyWishes!
                : DailyWishesBoard.generate(for: iso, hasOffspring: !state.offsprings.isEmpty)
            if let idx = board.wishes.firstIndex(where: { $0.kind == kind && !$0.isCompleted }) {
                board.wishes[idx].isCompleted = true
                state.dailyWishes = board
            } else if state.dailyWishes?.localDateISO != iso {
                state.dailyWishes = board
            }
        }
    }

    @discardableResult
    func claimDailyWishReward(_ kind: DailyWishKind) -> Bool {
        let iso = currentLocalDateISO
        var claimed = false
        mutateIndoorState { state in
            guard var board = state.dailyWishes, board.localDateISO == iso,
                  let idx = board.wishes.firstIndex(where: { $0.kind == kind && $0.isCompleted && !$0.isClaimed }) else {
                return
            }
            board.wishes[idx].isClaimed = true
            state.dailyWishes = board
            ledger.coinBalance += kind.rewardCoins
            claimed = true
        }
        if claimed {
            CozySoundEngine.shared.playCompassChime()
            HapticsEngine.shared.playCurioUnpack()
            showWhisper("完成今日小願望「\(kind.title)」！（+\(kind.rewardCoins) 步數幣）")
        }
        return claimed
    }

    // MARK: - 2. Sunroom Tea & Biscuit Kitchen
    func brewTeaRecipe(_ recipe: TeaRecipeSpec) {
        var firstUnlock = false
        mutateIndoorState { state in
            if !state.unlockedTeaRecipeIDs.contains(recipe.id) {
                state.unlockedTeaRecipeIDs.append(recipe.id)
                firstUnlock = true
            }
            state.totalTeaBrewedCount += 1
            // Brewing warm tea also lures an undiscovered window visitor!
            if let unseen = residents.first(where: { $0.inviteState == .unmet }) {
                state.lastWindowVisitorPetID = unseen.petID
                state.lastWindowVisitorDateISO = currentLocalDateISO
            }
        }
        ledger.coinBalance += 1
        try? modelContext.save()
        reloadAll()

        nurtureAllGrowingOffspring(axis: .gentle, bonusSteps: 0)
        markDailyWishCompleted(.brewTea)
        CozySoundEngine.shared.playTeapotClink()
        HapticsEngine.shared.playCurioUnpack()
        showWhisper(firstUnlock
            ? "解鎖新茶點「\(recipe.name)」！香氣飄滿陽光室（+1 幣，幼靈溫柔度提升）。"
            : "泡好了熱呼呼的「\(recipe.name)」！室友們滿足地瞇起雙眼（+1 幣）。")
    }

    // MARK: - 3. Juniper's Origami Workshop & Hanging Window Decor
    func craftOrigami(_ kind: OrigamiCraftKind) {
        mutateIndoorState { state in
            state.hangingOrigamis.append(kind)
            if state.hangingOrigamis.count > 5 {
                state.hangingOrigamis.removeFirst(state.hangingOrigamis.count - 5)
            }
        }
        ledger.coinBalance += 1
        try? modelContext.save()
        reloadAll()

        nurtureAllGrowingOffspring(axis: .playful, bonusSteps: 0)
        nurtureAllGrowingOffspring(axis: .mystical, bonusSteps: 0, countAsActivity: false)
        markDailyWishCompleted(.foldOrigami)
        CozySoundEngine.shared.playPaperFlip()
        HapticsEngine.shared.playCurioUnpack()
        showWhisper("摺好了「\(kind.title)」並掛上陽光室窗樑！（+1 幣，幼靈好奇與靈性提升）")
    }

    func ringSunroomWindChime() {
        CozySoundEngine.shared.playWardrobeSnap(withBell: true)
        HapticsEngine.shared.playBrushStrokeTick()
        showWhisper("窗邊的江戶風鈴隨著微風發出清脆叮噹聲 ♪")
    }

    func pinPostcardToSunroomWall(encounterID: UUID?) {
        mutateIndoorState { state in
            state.pinnedPostcardEncounterID = encounterID
        }
        CozySoundEngine.shared.playPaperFlip()
        showWhisper(encounterID != nil ? "已把這張水彩明信片別在陽光室牆面！" : "已取下牆面明信片。")
    }

    // MARK: - 4. Live Feather-Wand & Hide-and-Seek Indoor Play
    func recordFeatherWandPlaySession() {
        nurtureAllGrowingOffspring(axis: .playful, bonusSteps: 0)
        markDailyWishCompleted(.featherChase)
        CozySoundEngine.shared.playPetPurr()
        HapticsEngine.shared.playPawRangeCue()
    }

    func foundHidingPet(petID: String) {
        ledger.coinBalance += 1
        try? modelContext.save()
        reloadAll()
        nurtureAllGrowingOffspring(axis: .playful, bonusSteps: 0)
        markDailyWishCompleted(.hideAndSeek)
        CozySoundEngine.shared.playCompassChime()
        HapticsEngine.shared.playCurioUnpack()
        showWhisper("抓到躲貓貓的「\(displayName(for: petID))」囉！牠開心地跳了起來（+1 幣）。")
    }

    // MARK: - 5. Solo Pet Errands (Tabikaeru-Style Rainy Day Exploration)
    @discardableResult
    func sendPetOnErrand(petID: String, supply: ErrandSupplyPack) -> Bool {
        guard indoorState.activeErrand == nil else {
            showWhisper("已經有一位小靈獸正在外面探險囉，等牠帶著明信片回來吧！")
            return false
        }
        if supply.costCoins > 0 {
            guard ledger.coinBalance >= supply.costCoins else {
                showWhisper("備妥「\(supply.title)」需要 \(supply.costCoins) 步數幣。")
                return false
            }
            ledger.coinBalance -= supply.costCoins
        }
        let destinations = ["老街紅磚麵包巷", "雨後溪畔木棧道", "靜謐舊書店騎樓", "公園百年大榕樹下", "黃昏茶行石階口"]
        let dest = destinations[abs(petID.hashValue ^ indoorState.errandHistory.count) % destinations.count]
        let now = currentSimulatedDate
        let returnTime = now.addingTimeInterval(TimeInterval(supply.durationMinutes * 60))
        let errand = ActivePetErrand(
            id: UUID(),
            petID: petID,
            supply: supply,
            startedAtUTC: now,
            returnAtUTC: returnTime,
            destinationLabel: dest
        )
        mutateIndoorState { state in
            state.activeErrand = errand
        }
        markDailyWishCompleted(.sendErrand)
        nurtureAllGrowingOffspring(axis: .brave, bonusSteps: 0)
        CozySoundEngine.shared.playCompassChime()
        HapticsEngine.shared.playPawRangeCue()
        showWhisper("\(displayName(for: petID))背起「\(supply.title)」出門前往「\(dest)」探險囉！")
        return true
    }

    @discardableResult
    func collectReturnedErrand(forceReady: Bool = false) -> CompletedErrandPostcard? {
        guard let errand = indoorState.activeErrand else { return nil }
        guard forceReady || errand.isReadyToReturn(at: currentSimulatedDate) else { return nil }

        let name = displayName(for: errand.petID)
        let coins: Int
        let grantsCurio: Bool
        switch errand.supply {
        case .bakeryBun:
            coins = 2; grantsCurio = false
        case .gingerFlask:
            coins = 4; grantsCurio = true
        case .paperUmbrella:
            coins = 5; grantsCurio = true
        }

        var foundCurioID: String? = nil
        if grantsCurio {
            let spec = CurioCatalog.pickFor(weather: activeWeather, placeLabel: errand.destinationLabel, seed: ledger.foragedCurios.count + 7)
            let entry = ForagedCurioEntry(
                curioID: spec.id,
                placeLabel: errand.destinationLabel,
                weatherCode: activeWeather.rawValue,
                localDateISO: currentLocalDateISO
            )
            var curios = ledger.foragedCurios
            curios.insert(entry, at: 0)
            ledger.foragedCurios = curios
            foundCurioID = spec.id
        }

        let story = "\(name)帶著「\(errand.supply.title)」獨自走訪了「\(errand.destinationLabel)」，在屋簷下替你帶回一份暖呼呼的小禮物。"
        let postcard = CompletedErrandPostcard(
            id: errand.id,
            petID: errand.petID,
            destinationLabel: errand.destinationLabel,
            storyLine: story,
            coinsEarned: coins,
            foundCurioID: foundCurioID,
            localDateISO: currentLocalDateISO
        )

        ledger.coinBalance += coins
        let day = todayDiaryRecord()
        if !day.revisitNotes.contains(story) {
            day.revisitNotes.append(story)
        }

        mutateIndoorState { state in
            state.activeErrand = nil
            state.errandHistory.insert(postcard, at: 0)
            if state.errandHistory.count > 20 { state.errandHistory.removeLast() }
            if errand.supply == .paperUmbrella, let unseen = residents.first(where: { $0.inviteState == .unmet }) {
                state.lastWindowVisitorPetID = unseen.petID
                state.lastWindowVisitorDateISO = currentLocalDateISO
            }
        }

        nurtureAllGrowingOffspring(axis: .brave, bonusSteps: 300)
        CozySoundEngine.shared.playPaperFlip()
        HapticsEngine.shared.playCurioUnpack()
        showWhisper("\(name)探險平安返家！帶回 +\(coins) 步數幣與探險明信片。")
        return postcard
    }

    // MARK: - 6. Sunroom Window Visitors (Indoor Discovery of Undiscovered Mystical Companions)
    var currentWindowVisitorPetID: String? {
        let unseenIDs = residents.filter { $0.inviteState == .unmet }.map(\.petID)
        guard !unseenIDs.isEmpty else { return nil }
        if let saved = indoorState.lastWindowVisitorPetID, unseenIDs.contains(saved) {
            return saved
        }
        // Deterministically surface 1 shy mystical visitor peeking outside the window each civil day
        let seed = abs(currentLocalDateISO.hashValue)
        return unseenIDs[seed % unseenIDs.count]
    }

    func greetWindowVisitor(petID: String) {
        guard let target = resident(for: petID), target.inviteState == .unmet else { return }
        let spec = PetCatalog.pet(id: petID)
        var newVisits = 0
        mutateIndoorState { state in
            newVisits = (state.windowVisitCounts[petID] ?? 0) + 1
            state.windowVisitCounts[petID] = newVisits
            if newVisits >= 3 {
                state.lastWindowVisitorPetID = nil
            }
        }
        markDailyWishCompleted(.streetGreeting)
        CozySoundEngine.shared.playCompassChime()
        HapticsEngine.shared.playPawRangeCue()

        if newVisits >= 3 {
            target.inviteState = .invitedHome
            target.firstMetDateISO = target.firstMetDateISO ?? currentLocalDateISO
            target.sharedDaysCount = max(1, target.sharedDaysCount)
            target.milestoneTier = PetResidentState.milestoneForSharedDays(target.sharedDaysCount)
            try? modelContext.save()
            solveHomeRoomNow()
            showWhisper("窗外的「\(spec.name)」終於安心走進陽光室，成為你的新室友囉 ✦")
        } else {
            showWhisper("向窗外探頭的「\(spec.name)」溫柔揮了揮手（窗邊熟識度 \(newVisits)/3，泡熱茶更能吸引牠靠近！）。")
        }
    }

    // MARK: - 7. Emergent Multi-Pet Sunroom Skits
    func triggerSunroomSkit(petA: String, petB: String) -> SunroomPairSkit {
        let seen = Set(indoorState.seenSkitIDs)
        let skit = SunroomSkitCatalog.pickSkit(petA: petA, petB: petB, seen: seen)
        mutateIndoorState { state in
            if !state.seenSkitIDs.contains(skit.id) {
                state.seenSkitIDs.append(skit.id)
            }
        }
        nurtureAllGrowingOffspring(axis: .mystical, bonusSteps: 0)
        CozySoundEngine.shared.playCompassChime()
        HapticsEngine.shared.playCurioUnpack()
        return skit
    }

    // MARK: - 8. Mystical Nesting, Hybrid Inheritance & Slow 4-5 Day Personality Raising!
    struct NestingPairOption: Identifiable, Hashable, Sendable {
        var id: String { "\(fatherID)+\(motherID)" }
        let fatherID: String
        let motherID: String
        let blendedHabit: String
    }

    var eligibleNestingPairs: [NestingPairOption] {
        let invitedSpecs = residents
            .filter { $0.inviteState == .invitedHome }
            .map { PetCatalog.pet(id: $0.petID) }
        let males = invitedSpecs.filter { $0.gender == .male }
        let females = invitedSpecs.filter { $0.gender == .female }
        var pairs: [NestingPairOption] = []
        for f in males {
            for m in females {
                pairs.append(NestingPairOption(
                    fatherID: f.id,
                    motherID: m.id,
                    blendedHabit: OffspringCatalog.blendedHabit(fatherID: f.id, motherID: m.id)
                ))
            }
        }
        return pairs
    }

    var sunroomOffsprings: [MysticalOffspringRecord] {
        indoorState.offsprings.filter(\.isLivingInSunroom)
    }

    @discardableResult
    func startMysticalNest(fatherID: String, motherID: String) -> MysticalOffspringRecord? {
        let fatherSpec = PetCatalog.pet(id: fatherID)
        let motherSpec = PetCatalog.pet(id: motherID)
        guard fatherSpec.gender != motherSpec.gender else {
            showWhisper("需要一對不同性別的奇幻夥伴才能一起結緣築巢喔！")
            return nil
        }
        let activeEggsOrBabies = indoorState.offsprings.filter { $0.growthStage != .grown }
        guard activeEggsOrBabies.count < 2 else {
            showWhisper("陽光室裡已有 2 位正在成長的靈卵或幼靈，先專心陪牠們長大吧！")
            return nil
        }

        let count = indoorState.offsprings.count
        let inheritFatherBody = (count % 2 == 0)
        let bodyID = inheritFatherBody ? fatherID : motherID
        let tintID = inheritFatherBody ? motherID : fatherID
        let gender: PetGender = (count % 2 == 0) ? .female : .male
        let baby = MysticalOffspringRecord(
            id: UUID(),
            name: OffspringCatalog.defaultBabyName(fatherID: fatherID, motherID: motherID, index: count),
            gender: gender,
            fatherPetID: fatherID,
            motherPetID: motherID,
            inheritedBodyPetID: bodyID,
            inheritedTintPetID: tintID,
            createdAtUTC: currentSimulatedDate,
            bornDateISO: currentLocalDateISO,
            growthStage: .egg,
            careDaysLogged: [currentLocalDateISO],
            careActivityCount: 0,
            walkStepsShared: 0,
            bravePoints: 1,
            gentlePoints: 1,
            playfulPoints: 1,
            mysticalPoints: 1,
            awakenedArchetypeID: nil,
            blendedHabitTitle: OffspringCatalog.blendedHabit(fatherID: fatherID, motherID: motherID),
            isLivingInSunroom: sunroomOffsprings.count < 3,
            graduatedAnchorSiteID: nil,
            graduatedAnchorLabel: nil
        )

        mutateIndoorState { state in
            state.offsprings.insert(baby, at: 0)
        }
        CozySoundEngine.shared.playCompassChime()
        HapticsEngine.shared.playCurioUnpack()
        showWhisper("\(displayName(for: fatherID))與\(displayName(for: motherID))在暖毯上築好了巢，誕生一顆閃耀微光的「奇幻靈卵」！")
        return baby
    }

    /// Nurtures a specific offspring (or egg) with an activity on a chosen Personality Axis.
    @discardableResult
    func nurtureOffspring(id: UUID, axis: PersonalityAxis, bonusSteps: Int = 0, activityLabel: String? = nil) -> Bool {
        var evolvedStage: OffspringGrowthStage? = nil
        var childName = ""
        let iso = currentLocalDateISO

        mutateIndoorState { state in
            guard let idx = state.offsprings.firstIndex(where: { $0.id == id }) else { return }
            var child = state.offsprings[idx]
            childName = child.name
            if !child.careDaysLogged.contains(iso) {
                child.careDaysLogged.append(iso)
            }
            child.careActivityCount += 1
            child.walkStepsShared += max(0, bonusSteps)
            switch axis {
            case .brave: child.bravePoints += 2
            case .gentle: child.gentlePoints += 2
            case .playful: child.playfulPoints += 2
            case .mystical: child.mysticalPoints += 2
            }
            if child.evaluateGrowthProgression() {
                evolvedStage = child.growthStage
            }
            state.offsprings[idx] = child
        }

        markDailyWishCompleted(.nurtureOffspring)
        if let stage = evolvedStage {
            CozySoundEngine.shared.playCompassChime()
            HapticsEngine.shared.playCurioUnpack()
            let day = todayDiaryRecord()
            let note = "奇幻育兒紀念：「\(childName)」成長進入了「\(stage.title)」階段！"
            if !day.revisitNotes.contains(note) {
                day.revisitNotes.append(note)
                try? modelContext.save()
                reloadAll()
            }
            showWhisper("✦ 驚喜時刻！「\(childName)」成長為「\(stage.title)」囉！")
            return true
        } else if let activityLabel {
            CozySoundEngine.shared.playPetPurr()
            HapticsEngine.shared.playBrushStrokeTick()
            showWhisper("陪「\(childName)」\(activityLabel)（\(axis.title)特質 +2）！")
        }
        return false
    }

    /// Gently imprints indoor/outdoor activities onto all growing eggs & hatchlings in the Sunroom!
    func nurtureAllGrowingOffspring(axis: PersonalityAxis, bonusSteps: Int, countAsActivity: Bool = true) {
        let iso = currentLocalDateISO
        var evolvedNameAndStage: (String, OffspringGrowthStage)? = nil

        mutateIndoorState { state in
            var changed = false
            for idx in state.offsprings.indices {
                guard state.offsprings[idx].growthStage != .grown else { continue }
                changed = true
                if !state.offsprings[idx].careDaysLogged.contains(iso) {
                    state.offsprings[idx].careDaysLogged.append(iso)
                }
                if countAsActivity {
                    state.offsprings[idx].careActivityCount += 1
                }
                state.offsprings[idx].walkStepsShared += max(0, bonusSteps)
                switch axis {
                case .brave: state.offsprings[idx].bravePoints += 1
                case .gentle: state.offsprings[idx].gentlePoints += 1
                case .playful: state.offsprings[idx].playfulPoints += 1
                case .mystical: state.offsprings[idx].mysticalPoints += 1
                }
                if state.offsprings[idx].evaluateGrowthProgression() {
                    evolvedNameAndStage = (state.offsprings[idx].name, state.offsprings[idx].growthStage)
                }
            }
            if !changed { return }
        }
        if let (name, stage) = evolvedNameAndStage {
            CozySoundEngine.shared.playCompassChime()
            HapticsEngine.shared.playCurioUnpack()
            showWhisper("✦ 陪伴讓「\(name)」成長為「\(stage.title)」囉！")
        }
    }

    func renameOffspring(id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        mutateIndoorState { state in
            if let idx = state.offsprings.firstIndex(where: { $0.id == id }) {
                state.offsprings[idx].name = String(trimmed.prefix(12))
            }
        }
        showWhisper("已將幼靈命名為「\(String(trimmed.prefix(12)))」。")
    }

    func graduateOffspringToCorner(id: UUID, siteID: String) {
        guard let anchor = anchors.first(where: { $0.siteID == siteID }) else { return }
        mutateIndoorState { state in
            if let idx = state.offsprings.firstIndex(where: { $0.id == id }) {
                state.offsprings[idx].isLivingInSunroom = false
                state.offsprings[idx].graduatedAnchorSiteID = anchor.siteID
                state.offsprings[idx].graduatedAnchorLabel = anchor.customLabel
            }
        }
        CozySoundEngine.shared.playCompassChime()
        showWhisper("已送長大的孩子前往守護「\(anchor.customLabel)」，下次散步經過就能遇見牠囉！")
    }

    func toggleOffspringSunroomStay(id: UUID) {
        mutateIndoorState { state in
            guard let idx = state.offsprings.firstIndex(where: { $0.id == id }) else { return }
            let currentlyInRoom = state.offsprings[idx].isLivingInSunroom
            if !currentlyInRoom && state.offsprings.filter(\.isLivingInSunroom).count >= 3 {
                return
            }
            state.offsprings[idx].isLivingInSunroom.toggle()
            if state.offsprings[idx].isLivingInSunroom {
                state.offsprings[idx].graduatedAnchorSiteID = nil
                state.offsprings[idx].graduatedAnchorLabel = nil
            }
        }
    }

    func recordFolkloreChapterRead() {
        nurtureAllGrowingOffspring(axis: .mystical, bonusSteps: 0)
        CozySoundEngine.shared.playPaperFlip()
    }
}
