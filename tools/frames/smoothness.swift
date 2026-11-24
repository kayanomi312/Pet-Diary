import CoreGraphics
import Foundation
import ImageIO

private let bundle = URL(fileURLWithPath: "PawprintDays/Resources/PetFrames", isDirectory: true)
private let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
private let rates: Set<Double> = [3, 4, 5, 6, 8, 10, 12, 15, 24]

struct AuditError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct Manifest: Decodable {
    struct Clip: Decodable {
        let bank: String
        let frames: Int
        let fps: Double
        let loop: String
    }

    let pet: String
    let clips: [String: Clip]
}

struct Sample {
    static let side = 768
    static let reducedSide = 192
    let alpha: [UInt8]
    let centroidX: Double
    let baseline: Int
    let top: Int

    init(url: URL) throws {
        let side = Self.side
        let reducedSide = Self.reducedSide
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width == side, image.height == side,
              let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
                                      bytesPerRow: side * 4, space: sRGB,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let pixels = context.data?.assumingMemoryBound(to: UInt8.self)
        else { throw AuditError(message: "Expected a decodable 768×768 cel at \(url.lastPathComponent)") }

        context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        var bins = [Int](repeating: 0, count: reducedSide * reducedSide)
        var mass = 0, moment = 0
        var top = side, bottom = -1
        for y in 0..<side {
            for x in 0..<side {
                let value = Int(pixels[(y * side + x) * 4 + 3])
                bins[(y / 4) * reducedSide + x / 4] += value
                mass += value
                moment += x * value
                if value >= 128 {
                    top = min(top, y)
                    bottom = y
                }
            }
        }
        guard mass > 0, bottom >= 0, stride(from: 3, to: side * side * 4, by: 4).contains(where: { pixels[$0] == 0 }) else {
            throw AuditError(message: "Expected a visible cel with transparency at \(url.lastPathComponent)")
        }
        alpha = bins.map { UInt8(($0 + 8) / 16) }
        centroidX = Double(moment) / Double(mass)
        baseline = bottom
        self.top = top
    }

    func difference(from other: Sample) -> Double {
        let sum = zip(alpha, other.alpha).reduce(0) { $0 + abs(Int($1.0) - Int($1.1)) }
        return Double(sum) / Double(alpha.count)
    }
}

func median(_ values: [Double]) -> Double {
    let sorted = values.sorted()
    guard !sorted.isEmpty else { return 0 }
    return (sorted[(sorted.count - 1) / 2] + sorted[sorted.count / 2]) / 2
}

func metric(_ value: Double) -> String {
    String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
}

func audit(pet: String, clip: Manifest.Clip) throws -> [String] {
    guard (1...99).contains(clip.frames),
          clip.bank.range(of: "^[a-z]+$", options: .regularExpression) != nil,
          ["loop", "once", "pingpong"].contains(clip.loop) else {
        throw AuditError(message: "Invalid clip \(pet)/\(clip.bank)")
    }
    let frames = try (1...clip.frames).map {
        try Sample(url: bundle.appendingPathComponent("\(pet)_\(clip.bank)\($0).heic"))
    }
    let steps = zip(frames, frames.dropFirst()).map { $0.difference(from: $1) }
    let middle = median(steps)
    let maxStep = steps.max() ?? 0
    let seam = frames[frames.count - 1].difference(from: frames[0])
    let centroids = frames.map(\.centroidX)
    let drift = centroids.max()! - centroids.min()!
    let baseline = frames.map(\.baseline)
    let top = frames.map(\.top)
    var issues: [String] = []

    // Ping-pong never jumps from the last drawing back to the first.
    if clip.loop != "once", maxStep > 1.8 * middle { issues.append("max step > 1.8× median") }
    if clip.loop == "loop", seam > 1.5 * middle { issues.append("seam > 1.5× median") }
    if ["w", "wr"].contains(clip.bank), drift > 10 { issues.append("side-walk centroid range > 10 px") }
    if clip.bank == "i", maxStep < 0.5 { issues.append("idle max step < 0.5") }
    if !rates.contains(clip.fps) { issues.append("fps outside refresh-aligned set") }

    print("\(pet)/\(clip.bank) | \(frames.count)f @ \(metric(clip.fps)) \(clip.loop)"
        + " | steps [\(steps.map(metric).joined(separator: ", "))]"
        + " | median \(metric(middle)) | max \(metric(maxStep)) | seam \(metric(seam))"
        + " | centroid Δ\(metric(drift)) px | baseline \(baseline.min()!)–\(baseline.max()!)"
        + " | top \(top.min()!)–\(top.max()!) | \(issues.isEmpty ? "PASS" : issues.joined(separator: ", "))")
    return issues
}

do {
    let args = Array(CommandLine.arguments.dropFirst())
    let pets = (1...8).map { String(format: "pet_%02d", $0) }
    guard args.count <= 2, args.first.map(pets.contains) ?? true else {
        throw AuditError(message: "Usage: tools/frames/smoothness [pet_XX [bank]]")
    }
    let selected = args.first.map { [$0] } ?? pets
    let bank = args.dropFirst().first
    var failures = 0
    var count = 0
    print("Steps and seams are mean absolute alpha differences (0–255) at 192². Geometry is in 768² pixels.")
    for pet in selected {
        let path = bundle.appendingPathComponent("manifests/\(pet).json")
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: path))
        guard manifest.pet == pet else { throw AuditError(message: "Pet ID mismatch in \(path.lastPathComponent)") }
        let clips = manifest.clips.values.filter { bank == nil || $0.bank == bank }.sorted { $0.bank < $1.bank }
        for clip in clips {
            count += 1
            if try !audit(pet: pet, clip: clip).isEmpty { failures += 1 }
        }
    }
    guard count > 0 else { throw AuditError(message: "No manifest banks matched") }
    print("\(failures) of \(count) banks failed smoothness")
    exit(failures == 0 ? 0 : 1)
} catch {
    FileHandle.standardError.write(Data("smoothness: \(error.localizedDescription)\n".utf8))
    exit(2)
}
