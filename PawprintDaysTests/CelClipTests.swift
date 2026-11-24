import ImageIO
import XCTest
@testable import PawprintDays

final class CelClipTests: XCTestCase {
    func testLoopWrapsAtDuration() {
        let player = CelClipPlayer(CelClip(bank: "w", frames: 4, fps: 4, loop: .loop))
        XCTAssertEqual([0, 0.249, 0.25, 0.999, 1, 1.5].map(player.frame(at:)), [1, 1, 2, 4, 1, 3])
    }

    func testOneShotClampsAtBothEnds() {
        let player = CelClipPlayer(CelClip(bank: "tu", frames: 3, fps: 4, loop: .once))
        XCTAssertEqual([-1, 0, 0.25, 0.75, 4].map(player.frame(at:)), [1, 1, 2, 3, 3])
        XCTAssertNil(player.neighbor(of: 2, offset: 1))
    }

    func testPingPongDoesNotRepeatEndpoints() {
        let player = CelClipPlayer(CelClip(bank: "s", frames: 4, fps: 4, loop: .pingpong))
        XCTAssertEqual((0...6).map { player.frame(at: Double($0) / 4) }, [1, 2, 3, 4, 3, 2, 1])
        XCTAssertEqual(player.duration, 1.5)
        XCTAssertEqual(CelClipPlayer(CelClip(bank: "s", frames: 1, fps: 4, loop: .pingpong)).frame(at: 8), 1)
    }

    func testManifestHoldsUseOneBasedDrawingNumbers() throws {
        let json = #"{"bank":"i","frames":3,"fps":4,"loop":"loop","holds":{"1":3,"3":2},"events":{"blink":[3]}}"#
        let clip = try JSONDecoder().decode(CelClip.self, from: Data(json.utf8))
        let player = CelClipPlayer(clip)
        XCTAssertEqual((0...6).map { player.frame(at: Double($0) / 4) }, [1, 1, 1, 2, 3, 3, 1])
        XCTAssertEqual(clip.events?["blink"], [3])
        XCTAssertEqual(player.duration, 1.5)
    }

    func testMissingNextLeavesLegacyFallbackAvailable() {
        let player = CelClipPlayer(CelClip(bank: "tu", frames: 2, fps: 4, loop: .once, next: "missing"))
        XCTAssertEqual(CelLibrary.playback(for: "pet.01", starting: player, elapsed: 0.25)?.frame, 2)
        XCTAssertNil(CelLibrary.playback(for: "pet.01", starting: player, elapsed: 0.5))
    }

    func testNextContinuesWithRemainingTime() {
        let player = CelClipPlayer(CelClip(bank: "tu", frames: 2, fps: 4, loop: .once, next: "walk"))
        let sample = CelLibrary.playback(for: "pet.01", starting: player, elapsed: 0.75)
        XCTAssertEqual(sample?.player.clip.bank, "w")
        XCTAssertEqual(sample?.frame, 3)
    }

    func testTransitionsSkipUnavailableBanksAndSignalArrivalAfterAvailableClips() {
        let start = Date(timeIntervalSinceReferenceDate: 100)
        let wake = CelClipPlayer(CelClip(bank: "wk", frames: 4, fps: 4, loop: .once))
        let stand = CelClipPlayer(CelClip(bank: "tu", frames: 2, fps: 4, loop: .once))
        let route = CelPoseTransition(from: .sleep, to: .walk, at: start) { ["wk": wake, "tu": stand][$0] }
        XCTAssertEqual(route.playback(at: start)?.player.clip.bank, "wk")
        XCTAssertEqual(route.playback(at: start.addingTimeInterval(1))?.player.clip.bank, "tu")
        XCTAssertNil(route.playback(at: route.arrivesAt))
        var arrival: Date?
        route.onArrival(at: start.addingTimeInterval(1.25)) { arrival = $0 }
        XCTAssertNil(arrival)
        route.onArrival(at: start.addingTimeInterval(1.75)) { arrival = $0 }
        XCTAssertEqual(arrival, start.addingTimeInterval(1.5))

        let legacy = CelPoseTransition(from: .idle, to: .walk, at: start) { _ in nil }
        XCTAssertEqual(legacy.arrivesAt, start)
        XCTAssertNil(legacy.playback(at: start))
    }

    func testReversedPlayerRunsTurnBackwards() {
        let turn = CelClip(bank: "tn", frames: 8, fps: 12, loop: .once, next: "walk")
        let backwards = CelClipPlayer(turn, reversed: true)
        XCTAssertEqual(backwards.order, Array((1...8).reversed()))
        XCTAssertEqual(backwards.frame(at: 0.01), 8)
        XCTAssertEqual(backwards.frame(at: backwards.duration + 1), 1)
        XCTAssertEqual(backwards.duration, CelClipPlayer(turn).duration)
    }

    func testAuthoredTurnIsReversedForRightTurns() throws {
        let forward = try XCTUnwrap(CelLibrary.transitionPlayer(for: "pet.01", bank: "tn"))
        let backward = try XCTUnwrap(CelLibrary.transitionPlayer(for: "pet.01", bank: "tn<"))
        XCTAssertEqual(backward.order, forward.order.reversed())
        XCTAssertNil(CelLibrary.transitionPlayer(for: "pet.01", bank: "zz<"))
    }

    func testStrideMatchingBoundsGaitRateAndPacing() throws {
        let walk = CelClipPlayer(CelClip(bank: "w", frames: 12, fps: 12, loop: .loop))
        // Plausible stride: feet lock exactly, linear travel keeps the intended time.
        let fair = try XCTUnwrap(CelStride(lengthUV: 0.1, player: walk)?.matched(distance: 0.3, intended: 3))
        XCTAssertEqual(fair.gaitRate, 1, accuracy: 1e-9)
        XCTAssertEqual(fair.duration, 3, accuracy: 1e-9)
        // A tiny measured stride cannot turn a 3 s stroll into a crawl.
        let tiny = try XCTUnwrap(CelStride(lengthUV: 0.02, player: walk)?.matched(distance: 0.3, intended: 3))
        XCTAssertEqual(tiny.gaitRate, CelStride.gaitRateRange.upperBound)
        XCTAssertEqual(tiny.duration, 3 * CelStride.pacingTolerance, accuracy: 1e-9)
        // A huge one cannot turn it into a sprint.
        let huge = try XCTUnwrap(CelStride(lengthUV: 0.6, player: walk)?.matched(distance: 0.3, intended: 3))
        XCTAssertEqual(huge.gaitRate, CelStride.gaitRateRange.lowerBound)
        XCTAssertEqual(huge.duration, 3 / CelStride.pacingTolerance, accuracy: 1e-9)
    }

    func testLocomotionSelectsDepthAndRightBanksWithSideFallback() {
        let banks: Set<String> = ["wr", "wf", "wb"]
        XCTAssertEqual(CelLocomotion(dx: 0.1, dy: 0.5, facingRight: true, hasBank: banks.contains).bank, "wf")
        XCTAssertEqual(CelLocomotion(dx: 0, dy: -0.5, facingRight: false, hasBank: banks.contains).bank, "wb")
        XCTAssertEqual(CelLocomotion(dx: 0.4, dy: 0.1, facingRight: true, hasBank: banks.contains).bank, "wr")
        XCTAssertEqual(CelLocomotion(dx: 0.1, dy: 0.5, facingRight: true) { $0 == "wr" }.bank, "wr")
        XCTAssertEqual(CelLocomotion(dx: -0.4, dy: 0.05, facingRight: false) { _ in false }.bank, "w")
    }

    func testEventsFireOnEntryAcrossHoldsAndLoopBoundaries() {
        let clip = CelClip(bank: "w", frames: 3, fps: 4, loop: .loop, holds: [1: 2],
                           events: ["footContact": [1, 3]])
        let player = CelClipPlayer(clip)
        XCTAssertEqual(player.events(after: -0.01, through: 0.5).map(\.time), [0])
        XCTAssertEqual(player.events(after: 0.5, through: 1.05).map(\.time), [0.75, 1])
        XCTAssertEqual(player.events(after: 1, through: 1.25), [])
    }

    func testStrideDurationUsesTheEntireCycleIncludingHolds() throws {
        let clip = CelClip(bank: "w", frames: 4, fps: 4, loop: .loop, holds: [1: 3])
        let stride = try XCTUnwrap(CelStride(lengthUV: 0.2, player: CelClipPlayer(clip)))
        let duration = try XCTUnwrap(stride.duration(forDistance: 0.5))
        XCTAssertEqual(duration, 3.75, accuracy: 0.000001)
        XCTAssertNil(stride.duration(forDistance: 0))
        XCTAssertNil(CelStride(lengthUV: nil, player: CelClipPlayer(clip)))
    }

    @MainActor
    func testBundledFrameDecodesAtRequestedDisplaySize() async throws {
        let cache = CelFrameImageCache()
        let key = CelFrameImageCache.Key(name: "pet_01_w1", displayPixels: 118)
        let decoded = await cache.image(key)
        let image = try XCTUnwrap(decoded?.cgImage)
        XCTAssertLessThanOrEqual(max(image.width, image.height), 128)
        XCTAssertEqual(cache.decodedBytes, image.bytesPerRow * image.height)
        XCTAssertNotNil(cache.cached(key))

        let oversizeKey = CelFrameImageCache.Key(name: "pet_01_w1", displayPixels: 645)
        let native = await cache.image(oversizeKey)
        let nativeImage = try XCTUnwrap(native?.cgImage)
        let url = try XCTUnwrap(CelLibrary.frameURL(oversizeKey.name))
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let nativeWidth = try XCTUnwrap(properties[kCGImagePropertyPixelWidth] as? Int)
        let nativeHeight = try XCTUnwrap(properties[kCGImagePropertyPixelHeight] as? Int)
        XCTAssertEqual(max(nativeImage.width, nativeImage.height), min(oversizeKey.pixels, max(nativeWidth, nativeHeight)))
    }

    func testSpritePoolBoundsLiveEffectsAndExpiresThem() {
        let date = Date(timeIntervalSinceReferenceDate: 300)
        var pool = SpriteFXPool()
        for index in 0..<40 {
            pool.emit(.dust, at: CGPoint(x: index, y: 0), time: date)
        }
        let active = pool.active(at: date)
        XCTAssertEqual(active.count, 32)
        XCTAssertEqual(active.map(\.position.x).min(), 8)
        XCTAssertTrue(pool.active(at: date.addingTimeInterval(0.5)).isEmpty)
        XCTAssertEqual(SpriteFXKind.heart.frame(at: 0.61), 7)
    }

    func testOutfitTailLagsTheGaitByTwoAndAHalfFrames() {
        let player = CelClipPlayer(CelClip(bank: "w", frames: 12, fps: 12, loop: .loop))
        let lag = 2.5 / player.clip.fps
        let start = CelOutfitMotion.sway(during: CelPlayback(player: player, elapsed: 0))
        let peak = CelOutfitMotion.sway(during: CelPlayback(player: player, elapsed: lag + 0.25))
        XCTAssertEqual(start, .zero)
        XCTAssertEqual(peak.x, 0.018, accuracy: 0.000001)
        XCTAssertEqual(peak.y, 0, accuracy: 0.000001)
    }
}

@MainActor
final class CelEventFeedbackThrottleTests: XCTestCase {
    func testThrottleSuppressesBurstsPerEvent() {
        let start = Date(timeIntervalSinceReferenceDate: 1_000_000)
        XCTAssertTrue(CelEventFeedbackThrottle.allows("throttleTest", now: start))
        XCTAssertFalse(CelEventFeedbackThrottle.allows("throttleTest", now: start.addingTimeInterval(0.1)))
        XCTAssertTrue(CelEventFeedbackThrottle.allows("throttleTestOther", now: start.addingTimeInterval(0.1)))
        XCTAssertTrue(CelEventFeedbackThrottle.allows("throttleTest", now: start.addingTimeInterval(0.35)))
    }
}
