import Foundation

struct StepIngestionResult: Sendable {
    var newlyAcceptedSteps: Int
    var coinsAwarded: Int
    var newCuriosForaged: [ForagedCurioEntry]
    var updatedCoinBalance: Int
    var updatedRemainder: Int
    var isNearPocketFind: Bool
}

enum StepCoinLedgerEngine {
    static let stepsPerCoin: Int = 200
    static let stepsPerPocketFind: Int = 1_400
    static let nearPocketFindWindowSteps: Int = 200

    /// Mobility Parity constants (Blueprint Chapter 8):
    /// 130m low-speed travel (<= 10 km/h) OR 2 min (120s) outdoor dwell = 200-step Coin & Foraging credit.
    static let mobilityMetersPerCredit: Double = 130.0
    static let mobilityDwellSecondsPerCredit: Double = 120.0

    /// Disjoint 15-minute UTC high-water step ingestion.
    /// - Upserts once even when queries overlap.
    /// - Credits coins ONLY above each interval's accepted high-water mark.
    /// - Forgives previously issued coins on downward sensor revisions (never negative credit).
    /// - Carries remainder steps (0..199) cleanly across midnight.
    /// - Triggers Qualitative Pocket Finds every 1,400 accepted steps if a Walk Buddy is assigned.
    static func ingestIntervalSteps(
        ledger: WalletAndCurioLedger,
        intervalStartUTC: Date,
        reportedSteps: Int,
        companionPetID: String?,
        weather: WeatherMode,
        placeLabel: String,
        localDateISO: String
    ) -> StepIngestionResult {
        let bucket = Int64(floor(intervalStartUTC.timeIntervalSince1970 / 900.0))
        let clampedRaw = max(0, reportedSteps)
        var intervals = ledger.stepIntervals

        let deltaAccepted: Int
        if let idx = intervals.firstIndex(where: { $0.intervalBucketUTC == bucket }) {
            let previousHighWater = intervals[idx].highWaterAcceptedSteps
            intervals[idx].rawSteps = clampedRaw
            if clampedRaw > previousHighWater {
                deltaAccepted = clampedRaw - previousHighWater
                intervals[idx].highWaterAcceptedSteps = clampedRaw
            } else {
                // Downward sensor revision: keep raw correction visible, forgive previously issued coins.
                deltaAccepted = 0
            }
        } else {
            deltaAccepted = clampedRaw
            intervals.append(
                StepIntervalRecord(
                    intervalBucketUTC: bucket,
                    rawSteps: clampedRaw,
                    highWaterAcceptedSteps: clampedRaw
                )
            )
            // Keep rolling 7 days of 15-minute buckets (7 * 96 = 672 max)
            if intervals.count > 672 {
                intervals.sort { $0.intervalBucketUTC < $1.intervalBucketUTC }
                intervals.removeFirst(intervals.count - 672)
            }
        }

        ledger.stepIntervals = intervals
        return applyAcceptedStepEquivalent(
            ledger: ledger,
            deltaSteps: deltaAccepted,
            companionPetID: companionPetID,
            weather: weather,
            placeLabel: placeLabel,
            localDateISO: localDateISO
        )
    }

    /// Real-time live step delta ingestion (e.g. from `CMPedometer.startUpdates` during an active stroll):
    /// Increments the current 15-minute bucket's high-water mark cleanly so subsequent rolling historical syncs
    /// never double-count steps already credited live.
    static func ingestLiveDeltaSteps(
        ledger: WalletAndCurioLedger,
        atUTC timestamp: Date,
        deltaSteps: Int,
        companionPetID: String?,
        weather: WeatherMode,
        placeLabel: String,
        localDateISO: String
    ) -> StepIngestionResult {
        let clampedDelta = max(0, deltaSteps)
        let bucket = Int64(floor(timestamp.timeIntervalSince1970 / 900.0))
        var intervals = ledger.stepIntervals
        if let idx = intervals.firstIndex(where: { $0.intervalBucketUTC == bucket }) {
            intervals[idx].rawSteps += clampedDelta
            intervals[idx].highWaterAcceptedSteps += clampedDelta
        } else {
            intervals.append(
                StepIntervalRecord(
                    intervalBucketUTC: bucket,
                    rawSteps: clampedDelta,
                    highWaterAcceptedSteps: clampedDelta
                )
            )
            if intervals.count > 672 {
                intervals.sort { $0.intervalBucketUTC < $1.intervalBucketUTC }
                intervals.removeFirst(intervals.count - 672)
            }
        }
        ledger.stepIntervals = intervals
        return applyAcceptedStepEquivalent(
            ledger: ledger,
            deltaSteps: clampedDelta,
            companionPetID: companionPetID,
            weather: weather,
            placeLabel: placeLabel,
            localDateISO: localDateISO
        )
    }

    /// Mobility-Aid Distance & Time Roll Mode (Blueprint Chapter 8 & Stage 4):
    /// Converts 130m low-speed travel (<= 10 km/h) or 120s outdoor dwell into 200-step Coin & Foraging credit.
    static func ingestMobilityRollCredit(
        ledger: WalletAndCurioLedger,
        lowSpeedMeters: Double,
        outdoorDwellSeconds: TimeInterval,
        companionPetID: String?,
        weather: WeatherMode,
        placeLabel: String,
        localDateISO: String
    ) -> StepIngestionResult {
        guard ledger.mobilityRollModeEnabled else {
            return StepIngestionResult(
                newlyAcceptedSteps: 0,
                coinsAwarded: 0,
                newCuriosForaged: [],
                updatedCoinBalance: ledger.coinBalance,
                updatedRemainder: ledger.stepCarryRemainder,
                isNearPocketFind: isNearPocketFind(progress: ledger.pocketFindStepProgress)
            )
        }

        ledger.mobilityDistanceCarryM += max(0, lowSpeedMeters)
        ledger.mobilityDwellCarrySec += max(0, outdoorDwellSeconds)

        var earnedUnits = 0
        if ledger.mobilityDistanceCarryM >= mobilityMetersPerCredit {
            let units = Int(ledger.mobilityDistanceCarryM / mobilityMetersPerCredit)
            ledger.mobilityDistanceCarryM -= Double(units) * mobilityMetersPerCredit
            earnedUnits += units
        }
        if ledger.mobilityDwellCarrySec >= mobilityDwellSecondsPerCredit {
            let units = Int(ledger.mobilityDwellCarrySec / mobilityDwellSecondsPerCredit)
            ledger.mobilityDwellCarrySec -= Double(units) * mobilityDwellSecondsPerCredit
            earnedUnits += units
        }

        let equivalentSteps = earnedUnits * stepsPerCoin
        return applyAcceptedStepEquivalent(
            ledger: ledger,
            deltaSteps: equivalentSteps,
            companionPetID: companionPetID,
            weather: weather,
            placeLabel: placeLabel,
            localDateISO: localDateISO
        )
    }

    private static func applyAcceptedStepEquivalent(
        ledger: WalletAndCurioLedger,
        deltaSteps: Int,
        companionPetID: String?,
        weather: WeatherMode,
        placeLabel: String,
        localDateISO: String
    ) -> StepIngestionResult {
        guard deltaSteps > 0 else {
            return StepIngestionResult(
                newlyAcceptedSteps: 0,
                coinsAwarded: 0,
                newCuriosForaged: [],
                updatedCoinBalance: ledger.coinBalance,
                updatedRemainder: ledger.stepCarryRemainder,
                isNearPocketFind: isNearPocketFind(progress: ledger.pocketFindStepProgress)
            )
        }

        ledger.totalAcceptedStepsAllTime += deltaSteps

        // 1 Step Coin per 200 accepted steps with exact remainder carry across days
        let totalWithRemainder = ledger.stepCarryRemainder + deltaSteps
        let coinsEarned = totalWithRemainder / stepsPerCoin
        let newRemainder = totalWithRemainder % stepsPerCoin
        ledger.coinBalance += coinsEarned
        ledger.stepCarryRemainder = newRemainder

        // Qualitative Pocket Finds (every 1,400 accepted steps while walking with a Walk Buddy)
        var newCurios: [ForagedCurioEntry] = []
        if companionPetID != nil {
            let totalForagingSteps = ledger.pocketFindStepProgress + deltaSteps
            let findsEarned = totalForagingSteps / stepsPerPocketFind
            ledger.pocketFindStepProgress = totalForagingSteps % stepsPerPocketFind

            if findsEarned > 0 {
                var existing = ledger.foragedCurios
                var dailyCap = ledger.ownedOutfitIDs.contains("outfit.forager_satchel") ? 4 : 3
                if ledger.activeOutingPack == .trailShelterTowel {
                    dailyCap += 1
                }
                let todaysCount = existing.filter { $0.localDateISO == localDateISO }.count
                let allowedCount = max(0, min(findsEarned, dailyCap - todaysCount))

                for offset in 0..<allowedCount {
                    let curioSpec = CurioCatalog.pickFor(
                        weather: weather,
                        placeLabel: placeLabel,
                        seed: existing.count + offset + deltaSteps
                    )
                    let entry = ForagedCurioEntry(
                        curioID: curioSpec.id,
                        placeLabel: placeLabel,
                        weatherCode: weather.rawValue,
                        localDateISO: localDateISO
                    )
                    existing.append(entry)
                    newCurios.append(entry)
                }
                ledger.foragedCurios = existing
            }
        }

        return StepIngestionResult(
            newlyAcceptedSteps: deltaSteps,
            coinsAwarded: coinsEarned,
            newCuriosForaged: newCurios,
            updatedCoinBalance: ledger.coinBalance,
            updatedRemainder: ledger.stepCarryRemainder,
            isNearPocketFind: isNearPocketFind(progress: ledger.pocketFindStepProgress)
        )
    }

    static func isNearPocketFind(progress: Int) -> Bool {
        progress >= (stepsPerPocketFind - nearPocketFindWindowSteps)
    }

    static func stepsRemainingForPocketFind(progress: Int) -> Int {
        max(0, stepsPerPocketFind - progress)
    }

    /// Idempotent purchase transaction: never double-spends if txID is replayed.
    @discardableResult
    static func spendCoins(
        ledger: WalletAndCurioLedger,
        txID: String,
        item: ShopItemSpec
    ) -> Bool {
        if ledger.processedTxIDs.contains(txID) {
            return true // Idempotent replay
        }
        guard ledger.coinBalance >= item.priceCoins else {
            return false
        }
        ledger.coinBalance -= item.priceCoins
        ledger.processedTxIDs.append(txID)

        switch item.category {
        case .wardrobe:
            if !ledger.ownedOutfitIDs.contains(item.id) {
                ledger.ownedOutfitIDs.append(item.id)
            }
        case .goodies:
            if !ledger.ownedGoodieIDs.contains(item.id) {
                ledger.ownedGoodieIDs.append(item.id)
            }
        case .outings:
            ledger.activeOutingPackRaw = item.id
        case .rooms:
            if item.id == "room.rain_veranda" {
                ledger.verandaUnlocked = true
            } else {
                if !ledger.ownedRoomThemeIDs.contains(item.id) {
                    ledger.ownedRoomThemeIDs.append(item.id)
                }
                ledger.activeRoomThemeRaw = item.id
            }
        case .treats:
            break
        }
        return true
    }

    /// 10 Step Coins to stitch a visible decorative patch onto a 25-use Loved Patina goodie.
    @discardableResult
    static func spendPatchMendCoins(ledger: WalletAndCurioLedger, spot: HomeSpotPlacement, txID: String) -> Bool {
        if ledger.processedTxIDs.contains(txID) { return true }
        guard spot.hasLovedPatina, !spot.hasStitchedPatch, ledger.coinBalance >= ShopCatalog.patchMendPriceCoins else {
            return false
        }
        ledger.coinBalance -= ShopCatalog.patchMendPriceCoins
        ledger.processedTxIDs.append(txID)
        spot.hasStitchedPatch = true
        return true
    }
}
