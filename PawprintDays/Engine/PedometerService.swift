import Foundation
import CoreMotion
import Observation

struct DisjointPedometerBucket: Sendable {
    let intervalStartUTC: Date
    let steps: Int
}

@MainActor
@Observable
final class PedometerService {
    private let pedometer = CMPedometer()

    var isStepCountingAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    var authorizationStatus: CMAuthorizationStatus {
        CMPedometer.authorizationStatus()
    }

    var isSyncing: Bool = false
    var lastSyncUTC: Date? = nil

    /// Progressive opt-in: triggers iOS Motion & Fitness permission ONLY when user taps
    /// 'Use steps for coins' inside the Embroidered Step-Coin Pouch.
    func requestAndSyncRolling7Days(
        now: Date = Date(),
        maxBucketsPerSync: Int = 96 * 7
    ) async -> [DisjointPedometerBucket] {
        guard isStepCountingAvailable else { return [] }
        isSyncing = true
        defer { isSyncing = false }

        // Align end boundary cleanly to current 15-minute UTC floor
        let bucketSeconds: TimeInterval = 900.0
        let currentBucketFloor = floor(now.timeIntervalSince1970 / bucketSeconds) * bucketSeconds
        let totalBuckets = min(maxBucketsPerSync, 96 * 7) // up to 7 rolling days of disjoint 15-min intervals
        let lookbackStart = currentBucketFloor - Double(totalBuckets) * bucketSeconds

        // To keep battery & latency gentle on device, query the most recent 24h in 15-min intervals
        // plus daily-rolled 15-min blocks only if no sync has happened yet.
        let activeBucketCount = (lastSyncUTC == nil) ? min(totalBuckets, 96 * 2) : 32
        let startEpoch = max(lookbackStart, currentBucketFloor - Double(activeBucketCount) * bucketSeconds)

        var results: [DisjointPedometerBucket] = []
        var cursor = startEpoch

        while cursor < currentBucketFloor {
            let intervalStart = Date(timeIntervalSince1970: cursor)
            let intervalEnd = Date(timeIntervalSince1970: cursor + bucketSeconds)
            if let steps = await querySingleBucket(from: intervalStart, to: intervalEnd), steps > 0 {
                results.append(DisjointPedometerBucket(intervalStartUTC: intervalStart, steps: steps))
            }
            cursor += bucketSeconds
        }

        // Also include the currently in-progress 15-minute bucket
        let liveStart = Date(timeIntervalSince1970: currentBucketFloor)
        if now > liveStart, let liveSteps = await querySingleBucket(from: liveStart, to: now), liveSteps > 0 {
            results.append(DisjointPedometerBucket(intervalStartUTC: liveStart, steps: liveSteps))
        }

        lastSyncUTC = now
        return results
    }

    private func querySingleBucket(from start: Date, to end: Date) async -> Int? {
        await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: end) { data, error in
                if error != nil {
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: data?.numberOfSteps.intValue)
                }
            }
        }
    }
}
