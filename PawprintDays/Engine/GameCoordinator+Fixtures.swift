import Foundation
import CoreLocation

extension GameCoordinator {
    // MARK: - 14-Day Fast-Forward Deterministic Verification Fixture
    func advanceSimulatedDays(_ days: Int) {
        isUsingSimulatedClock = true
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
        isUsingSimulatedClock = true
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
}
