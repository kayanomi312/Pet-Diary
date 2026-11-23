import CoreGraphics
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
                guard encoded.width == 768, encoded.height == 768, encoded.pixels[3] == frame.pixels[3] else {
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

do {
    let args = Array(CommandLine.arguments.dropFirst())
    switch args.first {
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
