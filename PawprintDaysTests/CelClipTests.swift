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
}
