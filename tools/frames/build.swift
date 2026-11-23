import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

private let bundlePath = "PawprintDays/Resources/PetFrames"
private let sourcePath = "art-src/petframes"
private let files = FileManager.default
private let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

struct FrameError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

struct Frame {
    let url: URL
    let image: CGImage
    let pixels: [UInt8]

    var width: Int { image.width }
    var height: Int { image.height }

    init(_ url: URL) throws {
        self.url = url
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let context = CGContext(data: nil, width: image.width, height: image.height,
                                      bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                      space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw FrameError("Cannot decode \(url.path)") }
        self.image = image
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        pixels = Array(UnsafeBufferPointer(start: context.data!.assumingMemoryBound(to: UInt8.self),
                                           count: image.width * image.height * 4))
    }

    func validateFormat() throws {
        guard width == 768, height == 768 else {
            throw FrameError("\(url.path): expected 768×768, found \(width)×\(height)")
        }
        guard image.colorSpace?.name == CGColorSpace.sRGB else {
            throw FrameError("\(url.path): export in sRGB")
        }
        guard stride(from: 3, to: pixels.count, by: 4).contains(where: { pixels[$0] == 0 }),
              stride(from: 3, to: pixels.count, by: 4).contains(where: { pixels[$0] >= 128 })
        else { throw FrameError("\(url.path): expected a visible subject on a transparent canvas") }
    }

    var bounds: CGRect {
        var left = width, top = height, right = -1, bottom = -1
        for y in 0..<height {
            for x in 0..<width where pixels[4 * (y * width + x) + 3] >= 128 {
                left = min(left, x)
                right = max(right, x)
                top = min(top, y)
                bottom = max(bottom, y)
            }
        }
        guard right >= left else { return .null }
        return CGRect(x: left, y: top, width: right - left + 1, height: bottom - top + 1)
    }

    func registrationIssue() -> String? {
        let box = bounds
        guard !box.isNull else { return "no opaque subject" }
        guard abs(Int(box.maxY) - 1 - 690) > 3 else { return nil }
        return "alpha baseline y=\(Int(box.maxY) - 1), expected 690 ±3 for grounded frames"
    }
}

struct Bank {
    let pet: String
    let name: String
    let urls: [URL]

    var label: String { "\(pet)/\(name)" }
    var manifestURL: URL { URL(fileURLWithPath: "\(bundlePath)/manifests/\(pet).json") }

    func readManifest() throws -> [String: Any]? {
        guard files.fileExists(atPath: manifestURL.path) else { return nil }
        guard let object = try JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any],
              object["pet"] as? String == pet, object["spec"] as? Int == 2,
              object["clips"] is [String: [String: Any]] else {
            throw FrameError("Invalid manifest: \(manifestURL.path)")
        }
        return object
    }

    func verifyCount(_ entry: [String: Any]) throws {
        guard let count = entry["frames"] as? Int, count == urls.count else {
            throw FrameError("\(label): manifest frames=\(entry["frames"] ?? "?"), found \(urls.count) PNGs")
        }
    }
}

let defaults: [String: (name: String, fps: Double, loop: String, next: String?)] = [
    "w": ("walk", 12, "loop", nil), "wr": ("walk_right", 12, "loop", nil),
    "wf": ("walk_toward", 12, "loop", nil), "wb": ("walk_away", 12, "loop", nil),
    "i": ("idle", 8, "loop", nil), "h": ("happy", 7, "loop", nil),
    "m": ("mouth", 7.5, "loop", nil), "p": ("play", 8.5, "loop", nil),
    "s": ("sleep", 4, "pingpong", nil),
    "tu": ("sit_to_stand", 12, "once", "walk"), "td": ("stand_to_sit", 12, "once", "idle"),
    "ld": ("lie_down", 12, "once", "sleep"), "wk": ("wake", 12, "once", "idle"),
    "tn": ("turn", 12, "once", "walk"), "tr": ("turn_right", 12, "once", "walk_right"),
    "e": ("eat", 12, "once", "idle"), "j": ("hop", 12, "once", "idle"),
    "r": ("startle", 12, "once", "idle"), "g": ("greet", 12, "once", "idle"),
    "x": ("signature", 12, "once", "idle")
]

func directories(_ path: String) throws -> [URL] {
    guard files.fileExists(atPath: path) else { return [] }
    return try files.contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: [.isDirectoryKey],
                                         options: .skipsHiddenFiles)
        .filter { try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
}

func sourceBanks(pet: String?, bank: String?) throws -> [Bank] {
    try directories(sourcePath).flatMap { petURL -> [Bank] in
        let id = petURL.lastPathComponent
        guard pet == nil || id == pet else { return [] }
        guard id.range(of: "^pet_0[1-8]$", options: .regularExpression) != nil else {
            throw FrameError("Invalid source pet directory: \(id)")
        }
        return try directories(petURL.path).compactMap { bankURL in
            let name = bankURL.lastPathComponent
            guard bank == nil || name == bank else { return nil }
            guard name.range(of: "^[a-z]+$", options: .regularExpression) != nil else {
                throw FrameError("Invalid source bank: \(id)/\(name)")
            }
            let urls = try files.contentsOfDirectory(at: bankURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                .filter { $0.pathExtension.lowercased() == "png" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            guard !urls.isEmpty, urls.count <= 99, urls.enumerated().allSatisfy({
                $0.element.lastPathComponent == String(format: "%02d.png", $0.offset + 1)
            }) else {
                throw FrameError("\(id)/\(name): expected consecutive 01.png…NN.png")
            }
            return Bank(pet: id, name: name, urls: urls)
        }
    }
}

func writeImage(_ image: CGImage, format: UTType, to url: URL, options: [CFString: Any] = [:]) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, format.identifier as CFString, 1, nil)
    else { throw FrameError("Cannot write \(url.path)") }
    CGImageDestinationAddImage(destination, image, options as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { throw FrameError("Cannot encode \(url.path)") }
}

func build(_ banks: [Bank]) throws {
    let staging = files.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try files.createDirectory(at: staging, withIntermediateDirectories: false)
    defer { try? files.removeItem(at: staging) }

    for petBanks in Dictionary(grouping: banks, by: \.pet).values {
        guard let first = petBanks.first else { continue }
        var manifest = try first.readManifest() ?? ["pet": first.pet, "spec": 2]
        var clips = manifest["clips"] as? [String: [String: Any]] ?? [:]
        var staged: [(URL, URL)] = []
        for bank in petBanks.sorted(by: { $0.name < $1.name }) {
            if let existing = clips.first(where: { $0.value["bank"] as? String == bank.name }) {
                try bank.verifyCount(existing.value)
            } else {
                let spec = defaults[bank.name] ?? (bank.name, 12, "once", nil)
                guard clips[spec.name] == nil else { throw FrameError("Clip name collision: \(spec.name)") }
                var entry: [String: Any] = ["bank": bank.name, "frames": bank.urls.count, "fps": spec.fps, "loop": spec.loop]
                entry["next"] = spec.next
                clips[spec.name] = entry
            }
            for (index, url) in bank.urls.enumerated() {
                let frame = try Frame(url)
                try frame.validateFormat()
                let grounded = ["i", "w", "wr", "wf", "wb", "h", "m", "p", "s"].contains(bank.name)
                if grounded, let issue = frame.registrationIssue() { throw FrameError("\(url.path): \(issue)") }
                let name = "\(bank.pet)_\(bank.name)\(index + 1).heic"
                let output = staging.appendingPathComponent(name)
                try writeImage(frame.image, format: .heic, to: output, options: [kCGImageDestinationLossyCompressionQuality: 0.8])
                let encoded = try Frame(output)
                guard encoded.width == 768, encoded.height == 768, encoded.pixels[3] == frame.pixels[3],
                      encoded.image.alphaInfo != .none,
                      encoded.image.alphaInfo != .noneSkipFirst,
                      encoded.image.alphaInfo != .noneSkipLast else {
                    throw FrameError("\(name): HEIC dimensions or transparency changed during encoding")
                }
                staged.append((output, URL(fileURLWithPath: "\(bundlePath)/\(name)")))
            }
        }
        manifest["clips"] = clips
        let data = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
        for (input, output) in staged {
            try Data(contentsOf: input).write(to: output, options: .atomic)
        }
        try files.createDirectory(at: first.manifestURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try (data + Data([10])).write(to: first.manifestURL, options: .atomic)
        let bundleFiles = try files.contentsOfDirectory(atPath: bundlePath)
        for bank in petBanks {
            let prefix = "\(bank.pet)_\(bank.name)"
            for name in bundleFiles where name.hasPrefix(prefix) && name.hasSuffix(".heic") {
                let suffix = name.dropFirst(prefix.count).dropLast(5)
                if let index = Int(suffix), index > bank.urls.count {
                    try files.removeItem(atPath: "\(bundlePath)/\(name)")
                }
            }
        }
        print("\(first.pet): built \(staged.count) HEIC frames and updated manifest")
    }
}

func drawGuides(in context: CGContext, rect: CGRect) {
    for (row, color) in [(690.0, CGColor(red: 0.82, green: 0.24, blue: 0.22, alpha: 0.9)),
                         (170.0, CGColor(red: 0.21, green: 0.48, blue: 0.72, alpha: 0.9))] {
        let y = rect.maxY - rect.height * row / 768
        context.setStrokeColor(color)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: rect.minX, y: y))
        context.addLine(to: CGPoint(x: rect.maxX, y: y))
        context.strokePath()
    }
}

func canvas(width: Int, height: Int) throws -> CGContext {
    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { throw FrameError("Cannot allocate \(width)×\(height) canvas") }
    return context
}

func guide() throws {
    let context = try canvas(width: 768, height: 768)
    drawGuides(in: context, rect: CGRect(x: 0, y: 0, width: 768, height: 768))
    try writeImage(context.makeImage()!, format: .png, to: URL(fileURLWithPath: "art-src/templates/guide_768.png"))
}

func legacyBanks(pet: String?, bank: String?) throws -> [Bank] {
    let urls = try files.contentsOfDirectory(at: URL(fileURLWithPath: bundlePath),
                                            includingPropertiesForKeys: nil)
    let pattern = try NSRegularExpression(pattern: "^(pet_0[1-8])_([a-z]+)([0-9]+)\\.heic$")
    var groups: [String: [(Int, URL)]] = [:]
    for url in urls {
        let name = url.lastPathComponent
        guard let match = pattern.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)),
              let petRange = Range(match.range(at: 1), in: name),
              let bankRange = Range(match.range(at: 2), in: name),
              let indexRange = Range(match.range(at: 3), in: name),
              let index = Int(name[indexRange]) else { continue }
        let id = String(name[petRange])
        let code = String(name[bankRange])
        guard (pet == nil || pet == id), (bank == nil || bank == code) else { continue }
        groups["\(id)/\(code)", default: []].append((index, url))
    }
    return groups.keys.sorted().map { key in
        let parts = key.split(separator: "/")
        return Bank(pet: String(parts[0]), name: String(parts[1]),
                    urls: groups[key]!.sorted { $0.0 < $1.0 }.map(\.1))
    }
}

extension Frame {
    var hasLikelyMatte: Bool {
        var fringeSamples = 0
        var whiteFringe = 0
        var blackFringe = 0
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let i = (y * width + x) * 4
                let alpha = Int(pixels[i + 3])
                guard (20...110).contains(alpha) else { continue }
                for offset in [-4, 4, -width * 4, width * 4] {
                    let inner = i + offset
                    guard pixels[inner + 3] >= 245 else { continue }
                    fringeSamples += 1
                    let edge = (0..<3).map { Int(pixels[i + $0]) * 255 / alpha }
                    let core = (0..<3).map { Int(pixels[inner + $0]) }
                    if edge.min()! > 230, core.min()! < 165 { whiteFringe += 1 }
                    if edge.max()! < 25, core.max()! > 95 { blackFringe += 1 }
                    break
                }
            }
        }
        return max(whiteFringe, blackFringe) > max(18, fringeSamples / 3)
    }

    // A broad central row filters narrow ear/horn tips. Inspect the true anatomy on the contact sheet.
    var broadSilhouetteTop: Int? {
        let box = bounds
        guard !box.isNull else { return nil }
        let left = Int(box.minX + box.width * 0.2)
        let right = Int(box.maxX - box.width * 0.2)
        let span = max(1, Int(box.width * 0.15))
        for y in Int(box.minY)..<Int(box.maxY) {
            var opaque = 0
            for x in left..<right where pixels[4 * (y * width + x) + 3] >= 128 {
                opaque += 1
            }
            if opaque >= span { return y }
        }
        return nil
    }
}

func frameDifference(_ first: Frame, _ second: Frame) -> Double {
    guard first.pixels.count == second.pixels.count else { return .infinity }
    var sum = 0
    for i in stride(from: 0, to: first.pixels.count, by: 16) {
        for channel in 0..<4 {
            sum += abs(Int(first.pixels[i + channel]) - Int(second.pixels[i + channel]))
        }
    }
    return Double(sum) / Double(first.pixels.count)
}

func validateManifest(_ manifest: [String: Any], bank: Bank) throws -> [String: Any] {
    let clips = manifest["clips"] as! [String: [String: Any]]
    var bankNames: Set<String> = []
    for (name, clip) in clips {
        guard let code = clip["bank"] as? String,
              code.range(of: "^[a-z]+$", options: .regularExpression) != nil,
              bankNames.insert(code).inserted,
              let count = clip["frames"] as? Int, (1...99).contains(count),
              let fps = clip["fps"] as? Double, fps > 0, fps <= 120,
              let loop = clip["loop"] as? String, ["loop", "once", "pingpong"].contains(loop)
        else { throw FrameError("\(bank.pet): invalid manifest clip \(name)") }
        if let rawHolds = clip["holds"] {
            guard let holds = rawHolds as? [String: Int], holds.allSatisfy({
                (1...count).contains(Int($0.key) ?? 0) && (1...120).contains($0.value)
            }) else { throw FrameError("\(bank.pet)/\(name): holds out of range") }
        }
        if let rawEvents = clip["events"] {
            guard let events = rawEvents as? [String: [Int]], events.values.allSatisfy({
                Set($0).count == $0.count && $0.allSatisfy { (1...count).contains($0) }
            }) else { throw FrameError("\(bank.pet)/\(name): event frames out of range or repeated") }
        }
        if let source = try sourceBanks(pet: bank.pet, bank: code).first {
            try source.verifyCount(clip)
        } else {
            let actual = try legacyBanks(pet: bank.pet, bank: code).first?.urls.map(\.lastPathComponent) ?? []
            let expected = (1...count).map { "\(bank.pet)_\(code)\($0).heic" }
            guard actual == expected else { throw FrameError("\(bank.pet)/\(code): manifest expects \(count) consecutive frames, found \(actual.count) bundled files") }
        }
    }
    guard let entry = clips.values.first(where: { $0["bank"] as? String == bank.name }) else {
        throw FrameError("\(bank.label): add source bank to the manifest with tools/frames/build")
    }
    return entry
}

func lint(_ banks: [Bank], legacy: Bool) throws {
    var failures = 0
    for bank in banks {
        let entry: [String: Any]
        if legacy {
            entry = [:]
        } else {
            guard let manifest = try bank.readManifest() else { throw FrameError("\(bank.label): missing manifest, run tools/frames/build") }
            entry = try validateManifest(manifest, bank: bank)
        }
        let frames = try bank.urls.map(Frame.init)
        let fileHashes = try bank.urls.map { Insecure.MD5.hash(data: try Data(contentsOf: $0)) }
        let uniqueCount = Set(frames.map { Insecure.MD5.hash(data: Data($0.pixels)) }).count
        let sizes = Set(frames.map { "\($0.width)×\($0.height)" }).sorted().joined(separator: ", ")
        let baselines = frames.compactMap { frame in frame.bounds.isNull ? nil : Int(frame.bounds.maxY) - 1 }
        let heights = frames.compactMap { frame in frame.bounds.isNull ? nil : Int(frame.bounds.height / CGFloat(frame.height) * 100) }
        print("\(bank.label): \(uniqueCount)/\(frames.count) unique, \(sizes), baseline \(baselines.min() ?? 0)–\(baselines.max() ?? 0) px, bbox height \(heights.min() ?? 0)–\(heights.max() ?? 0)%")
        let duplicateCount = frames.count - Set(fileHashes).count
        if duplicateCount > 0 {
            print("  \(duplicateCount) duplicate files (MD5)")
        }
        guard !legacy else { continue }

        var issues: [String] = []
        let grounded = ["i", "w", "wr", "wf", "wb", "h", "m", "p", "s"].contains(bank.name)
        for frame in frames {
            try frame.validateFormat()
            if grounded, let issue = frame.registrationIssue() {
                issues.append("\(frame.url.lastPathComponent): \(issue)")
            }
            if frame.hasLikelyMatte { issues.append("\(frame.url.lastPathComponent): possible alpha matte") }
        }
        if uniqueCount < frames.count { issues.append("duplicate drawings, encode holds in the manifest") }
        if ["w", "wr", "wf", "wb", "i"].contains(bank.name), uniqueCount < 8 {
            issues.append("at least 8 unique drawings required")
        }
        let idleSource = try sourceBanks(pet: bank.pet, bank: "i").first?.urls.first
        let idleReference = try idleSource.flatMap { try Frame($0).broadSilhouetteTop }
        if ["i", "w", "wr", "wf", "wb", "h", "m"].contains(bank.name), let reference = idleReference {
            if bank.name == "i", abs(reference - 170) > 6 {
                issues.append("broad head silhouette in i1 is at y=\(reference), expected 170 ±6")
            }
            let height = 690 - reference
            for frame in frames {
                if let head = frame.broadSilhouetteTop, Double(abs(head - reference)) > Double(height) * 0.03 {
                    issues.append("\(frame.url.lastPathComponent): head height differs from i1 by more than 3%")
                }
            }
        }
        if entry["loop"] as? String == "loop", frames.count > 2,
           let first = frames.first, let last = frames.last {
            let internalDiff = zip(frames, frames.dropFirst()).map(frameDifference).reduce(0, +)
            let average = internalDiff / Double(frames.count - 1)
            let closure = frameDifference(last, first)
            print(String(format: "  loop closure %.2f vs %.2f mean adjacent difference", closure, average))
            if closure > average * 2.0 { issues.append("loop closure exceeds twice the mean adjacent difference") }
        }
        for issue in issues { print("  error: \(issue)") }
        failures += issues.count
    }
    guard failures == 0 else { throw FrameError("\(failures) cel lint issues") }
}

func preview(_ banks: [Bank], onion: Bool, dark: Bool) throws {
    let tile = 240
    let output = URL(fileURLWithPath: "art-src/previews", isDirectory: true)
    try files.createDirectory(at: output, withIntermediateDirectories: true)
    let background = dark ? CGColor(gray: 0, alpha: 1) : CGColor(gray: 1, alpha: 1)

    for bank in banks {
        let images = try bank.urls.map { try Frame($0).image }
        let entry = (try bank.readManifest()?["clips"] as? [String: [String: Any]])?
            .values.first { $0["bank"] as? String == bank.name }
        let fps = entry?["fps"] as? Double ?? defaults[bank.name]?.fps ?? 8
        guard fps.isFinite, (0.01...120).contains(fps) else { throw FrameError("\(bank.label): invalid fps") }
        let holds = entry?["holds"] as? [String: Int] ?? [:]
        let loop = entry?["loop"] as? String ?? defaults[bank.name]?.loop ?? "once"
        var order = Array(images.indices)
        if loop == "pingpong", images.count > 2 {
            order += images.indices.dropFirst().dropLast().reversed()
        }
        let columns = min(4, images.count)
        let rows = (images.count + columns - 1) / columns
        let sheet = try canvas(width: columns * tile, height: rows * tile)
        let directory = output.appendingPathComponent(bank.pet, isDirectory: true)
        try files.createDirectory(at: directory, withIntermediateDirectories: true)
        let suffix = (dark ? "_black" : "") + (onion ? "" : "_clean")
        let gif = directory.appendingPathComponent("\(bank.name)\(suffix).gif")
        guard let destination = CGImageDestinationCreateWithURL(gif as CFURL, UTType.gif.identifier as CFString,
                                                                 order.count, nil)
        else { throw FrameError("Cannot create \(gif.path)") }
        if loop != "once" {
            CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        }
        for (step, index) in order.enumerated() {
            let tileCanvas = try canvas(width: tile, height: tile)
            let bounds = CGRect(x: 0, y: 0, width: tile, height: tile)
            tileCanvas.interpolationQuality = .high
            tileCanvas.setFillColor(background)
            tileCanvas.fill(bounds)
            if onion {
                tileCanvas.setAlpha(0.3)
                if step > 0 || loop != "once" {
                    tileCanvas.draw(images[order[(step + order.count - 1) % order.count]], in: bounds)
                }
                if step + 1 < order.count || loop != "once" {
                    tileCanvas.draw(images[order[(step + 1) % order.count]], in: bounds)
                }
                tileCanvas.setAlpha(1)
            }
            tileCanvas.draw(images[index], in: bounds)
            drawGuides(in: tileCanvas, rect: bounds)
            let tileImage = tileCanvas.makeImage()!
            if step < images.count {
                let rect = CGRect(x: (index % columns) * tile, y: (rows - 1 - index / columns) * tile,
                                  width: tile, height: tile)
                sheet.draw(tileImage, in: rect)
            }
            let delay = Double(max(1, holds[String(index + 1)] ?? 1)) / fps
            let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay,
                                                              kCGImagePropertyGIFUnclampedDelayTime: delay]]
            CGImageDestinationAddImage(destination, tileImage, properties as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else { throw FrameError("Cannot write \(gif.path)") }
        let sheetURL = directory.appendingPathComponent("\(bank.name)\(suffix).png")
        try writeImage(sheet.makeImage()!, format: .png, to: sheetURL)
        print("art-src/previews/\(bank.pet)/\(bank.name)\(suffix).{png,gif}")
    }
}

do {
    let args = Array(CommandLine.arguments.dropFirst())
    switch args.first {
    case "--lint", "--legacy":
        let selectors = Array(args.dropFirst())
        guard selectors.count <= 2 else { throw FrameError("Usage: tools/frames/lint [--legacy] [pet_XX [bank]]") }
        let pet = selectors.first
        let bank = selectors.dropFirst().first
        let source = try sourceBanks(pet: pet, bank: bank)
        if args.first == "--legacy" || source.isEmpty {
            let legacy = try legacyBanks(pet: pet, bank: bank)
            guard !legacy.isEmpty else { throw FrameError("No frames matched") }
            print("Legacy bundle audit")
            try lint(legacy, legacy: true)
        } else {
            try lint(source, legacy: false)
        }
    case "--preview":
        let options = args.dropFirst()
        let selectors = options.filter { !$0.hasPrefix("--") }
        let flags = Set(options.filter { $0.hasPrefix("--") })
        guard selectors.count <= 2, flags.isSubset(of: ["--black", "--clean"]) else {
            throw FrameError("Usage: tools/frames/preview [pet_XX [bank]] [--black] [--clean]")
        }
        let pet = selectors.first
        let bank = selectors.dropFirst().first
        let source = try sourceBanks(pet: pet, bank: bank)
        let selected = source.isEmpty ? try legacyBanks(pet: pet, bank: bank) : source
        guard !selected.isEmpty else { throw FrameError("No frames matched") }
        try preview(selected, onion: !flags.contains("--clean"), dark: flags.contains("--black"))
    case "--guide":
        try guide()
    default:
        guard args.count <= 2 else { throw FrameError("Usage: tools/frames/build [pet_XX [bank]] or --guide") }
        let banks = try sourceBanks(pet: args.first, bank: args.dropFirst().first)
        guard !banks.isEmpty else { throw FrameError("No source PNGs matched") }
        try build(banks)
    }
} catch {
    FileHandle.standardError.write(Data("error: \(error.localizedDescription)\n".utf8))
    exit(1)
}
