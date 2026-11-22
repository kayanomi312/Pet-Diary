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
    nonisolated(unsafe) private let pedometer = CMPedometer()

    var isStepCountingAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    var authorizationStatus: CMAuthorizationStatus {
        CMPedometer.authorizationStatus()
    }

    var isSyncing: Bool = false
    var lastSyncUTC: Date? = nil
    var isStreamingLiveStroll: Bool = false
    private var lastStreamedCumulativeSteps: Int = 0

    /// Starts real-time `CMPedometer` step streaming while an active `出發散步` session is running,
    /// delivering incremental positive step deltas on the MainActor without waiting for manual sync.
    func startLiveStrollUpdates(from startDate: Date, onStepsDelta: @escaping @MainActor (Int) -> Void) {
        #if targetEnvironment(simulator)
        return
        #else
        guard isStepCountingAvailable else { return }
        stopLiveStrollUpdates()
        lastStreamedCumulativeSteps = 0
        isStreamingLiveStroll = true
        Self.beginUpdates(pedometer: pedometer, from: startDate) { [weak self] totalSteps in
            Task { @MainActor [weak self] in
                guard let self, self.isStreamingLiveStroll else { return }
                let delta = totalSteps - self.lastStreamedCumulativeSteps
                if delta > 0 {
                    self.lastStreamedCumulativeSteps = totalSteps
                    onStepsDelta(delta)
                }
            }
        }
        #endif
    }

    func stopLiveStrollUpdates() {
        #if !targetEnvironment(simulator)
        if isStreamingLiveStroll {
            pedometer.stopUpdates()
        }
        #endif
        isStreamingLiveStroll = false
        lastStreamedCumulativeSteps = 0
    }

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
        await Self.querySteps(pedometer: pedometer, from: start, to: end)
    }

    /// Strictly `nonisolated` so CoreMotion's background dispatch queue callback NEVER trips Swift 6's `@MainActor` executor assertion.
    nonisolated private static func querySteps(pedometer: CMPedometer, from start: Date, to end: Date) async -> Int? {
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

    /// Strictly `nonisolated` wrapper for `CMPedometer.startUpdates` background callbacks.
    nonisolated private static func beginUpdates(
        pedometer: CMPedometer,
        from startDate: Date,
        onTotalSteps: @escaping @Sendable (Int) -> Void
    ) {
        pedometer.startUpdates(from: startDate) { data, error in
            guard error == nil, let totalSteps = data?.numberOfSteps.intValue else { return }
            onTotalSteps(totalSteps)
        }
    }
}
