import Foundation

/// One authored bank. Holds and events use the 1-based drawing index in the manifest.
struct CelClip: Decodable, Equatable, Sendable {
    enum Loop: String, Decodable, Sendable {
        case loop, once, pingpong
    }

    struct Anchors: Decodable, Equatable, Sendable {
        var neck: [Double]?
    }

    let bank: String
    let frames: Int
    let fps: Double
    let loop: Loop
    var holds: [Int: Int]?
    var events: [String: [Int]]?
    var next: String?
    var anchors: Anchors?
    var strideLengthUV: Double?

    func asset(prefix: String, frame: Int) -> String {
        "\(prefix)_\(bank)\(frame)"
    }

    var isValid: Bool {
        (1...99).contains(frames) && fps.isFinite && fps > 0 && fps <= 120
            && !bank.isEmpty && bank.utf8.allSatisfy { (97...122).contains($0) }
    }
}

/// Converts seconds to drawing indices, without repeating the endpoints on ping-pong.
struct CelClipPlayer: Sendable {
    let clip: CelClip
    let order: [Int]
    private let ends: [Int]

    init(_ clip: CelClip) {
        self.clip = clip
        let forward = Array(1...max(1, clip.frames))
        order = clip.loop == .pingpong ? forward + forward.dropFirst().dropLast().reversed() : forward
        var tick = 0
        ends = order.map { drawing in
            tick += max(1, min(120, clip.holds?[drawing] ?? 1))
            return tick
        }
    }

    var duration: Double { Double(ends.last ?? 1) / clip.fps }

    func step(at elapsed: Double) -> Int {
        guard elapsed.isFinite, elapsed > 0 else { return 0 }
        if clip.loop == .once && elapsed >= duration { return order.count - 1 }
        let local = clip.loop == .once ? elapsed : elapsed.truncatingRemainder(dividingBy: duration)
        let tick = local * clip.fps
        return ends.firstIndex { Double($0) > tick + 1e-9 } ?? 0
    }

    func startTime(of step: Int) -> Double {
        step <= 0 ? 0 : Double(ends[step - 1]) / clip.fps
    }

    func frame(at elapsed: Double) -> Int { order[step(at: elapsed)] }

    func neighbor(of step: Int, offset: Int) -> Int? {
        let index = step + offset
        if order.indices.contains(index) { return order[index] }
        if clip.loop == .once { return nil }
        return order[(index + order.count) % order.count]
    }
}

struct CelPlayback: Sendable {
    let player: CelClipPlayer
    let elapsed: Double

    var frame: Int { player.frame(at: elapsed) }
}

struct CelManifest: Decodable, Sendable {
    let pet: String
    let spec: Int
    var clips: [String: CelClip]
    var anchors: CelClip.Anchors?
    var strideLengthUV: Double?
}

enum CelLibrary {
    static func prefix(for petID: String) -> String {
        petID.replacingOccurrences(of: ".", with: "_")
    }

    private static let manifests: [String: CelManifest] = {
        let files = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "PetFrames/manifests") ?? []
        var result: [String: CelManifest] = [:]
        for url in files {
            let prefix = url.deletingPathExtension().lastPathComponent
            guard let data = try? Data(contentsOf: url),
                  var manifest = try? JSONDecoder().decode(CelManifest.self, from: data),
                  manifest.pet == prefix, manifest.spec == 2 else { continue }
            manifest.clips = manifest.clips.filter { _, clip in
                clip.isValid && (1...clip.frames).allSatisfy {
                    frameURL(clip.asset(prefix: prefix, frame: $0)) != nil
                }
            }
            result[prefix] = manifest
        }
        return result
    }()

    private static let authoredPlayers = manifests.mapValues { $0.clips.mapValues(CelClipPlayer.init) }

    static func authored(for petID: String, bank: String) -> CelClipPlayer? {
        authoredPlayers[prefix(for: petID)]?.values.first { $0.clip.bank == bank }
    }

    static func player(for petID: String, bank: String) -> CelClipPlayer? {
        authored(for: petID, bank: bank) ?? legacyPlayers.values.first { $0.clip.bank == bank }
    }

    /// Follows one-shot links on the same clock. A missing link leaves the caller's legacy fallback in control.
    static func playback(for petID: String, starting player: CelClipPlayer, elapsed: Double) -> CelPlayback? {
        var current = player
        var time = elapsed
        var visited: Set<String> = []
        while current.clip.loop == .once && time >= current.duration {
            guard let next = current.clip.next, visited.insert(next).inserted,
                  let following = authoredPlayers[prefix(for: petID)]?[next] ?? legacyPlayers[next] else { return nil }
            time -= current.duration
            current = following
        }
        return CelPlayback(player: current, elapsed: time)
    }

    static func manifest(for petID: String) -> CelManifest? { manifests[prefix(for: petID)] }

    static func frameURL(_ name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "heic", subdirectory: "PetFrames")
    }

    private static let legacyPlayers = legacy.mapValues(CelClipPlayer.init)

    static let legacy: [String: CelClip] = [
        "walk": CelClip(bank: "w", frames: 16, fps: 9, loop: .loop),
        "idle": CelClip(bank: "i", frames: 16, fps: 5.2, loop: .loop),
        "happy": CelClip(bank: "h", frames: 10, fps: 7, loop: .loop),
        "mouth": CelClip(bank: "m", frames: 8, fps: 7.5, loop: .loop),
        "play": CelClip(bank: "p", frames: 8, fps: 8.5, loop: .loop),
        "sleep": CelClip(bank: "s", frames: 12, fps: 3.2, loop: .loop),
        "keyframes": CelClip(bank: "f", frames: 6, fps: 3, loop: .once)
    ]
}

enum CelPose: Equatable, Sendable {
    case idle, walk, sleep, startle
}

/// A short sequence of available one-shots between stable poses.
struct CelPoseTransition: Sendable {
    let source: CelPose
    let target: CelPose
    let startsAt: Date
    let players: [CelClipPlayer]

    init(from source: CelPose, to target: CelPose, at start: Date,
         lookup: (String) -> CelClipPlayer?) {
        self.source = source
        self.target = target
        startsAt = start
        let banks: [String]
        switch (source, target) {
        case (_, .startle): banks = ["r"]
        case (.idle, .walk), (.startle, .walk): banks = ["tu"]
        case (.walk, .idle): banks = ["td"]
        case (.sleep, .idle): banks = ["wk"]
        case (.idle, .sleep), (.startle, .sleep): banks = ["ld"]
        case (.walk, .sleep): banks = ["td", "ld"]
        case (.sleep, .walk): banks = ["wk", "tu"]
        default: banks = []
        }
        players = banks.compactMap(lookup).filter { $0.clip.loop == .once }
    }

    var arrivesAt: Date {
        startsAt.addingTimeInterval(players.reduce(0) { $0 + $1.duration })
    }

    func playback(at date: Date) -> CelPlayback? {
        var elapsed = max(0, date.timeIntervalSince(startsAt))
        for player in players {
            if elapsed < player.duration {
                return CelPlayback(player: player, elapsed: elapsed)
            }
            elapsed -= player.duration
        }
        return nil
    }

    func onArrival(at date: Date, perform: (Date) -> Void) {
        if date >= arrivesAt { perform(arrivesAt) }
    }
}
