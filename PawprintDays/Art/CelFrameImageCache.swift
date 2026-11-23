import ImageIO
import SwiftUI
import UIKit

/// Shared decoded-frame budget. Entries are grouped by pet and eviction favors
/// unpinned frames, starting with the least recently used.
@MainActor
final class CelFrameImageCache {
    static let shared = CelFrameImageCache()
    static let budget = 48 * 1024 * 1024

    struct Key: Hashable, Sendable {
        let name: String
        let pixels: Int

        init(name: String, displayPixels: CGFloat) {
            self.name = name
            pixels = Self.bucket(for: displayPixels)
        }

        static func bucket(for displayPixels: CGFloat) -> Int {
            let requested = min(768, max(1, displayPixels))
            return min(768, Int(ceil(requested / 64)) * 64)
        }

        var pet: String { String(name.prefix(6)) }
    }

    private struct Entry {
        let image: UIImage
        let bytes: Int
        var used: UInt64
    }

    private var entries: [String: [Key: Entry]] = [:]
    private var requests: [Key: Task<CGImage?, Never>] = [:]
    private var pins: [UUID: Set<Key>] = [:]
    private var sequence: UInt64 = 0
    private(set) var decodedBytes = 0

    func setPins(_ keys: [Key], for owner: UUID) { pins[owner] = Set(keys) }
    func releasePins(for owner: UUID) { pins.removeValue(forKey: owner) }

    func cached(_ key: Key) -> UIImage? {
        guard let entry = entries[key.pet]?[key] else { return nil }
        sequence &+= 1
        entries[key.pet]?[key]?.used = sequence
        return entry.image
    }

    func image(_ key: Key) async -> UIImage? {
        if let image = cached(key) { return image }
        guard let url = CelLibrary.frameURL(key.name) else { return nil }
        let task: Task<CGImage?, Never>
        if let pending = requests[key] {
            task = pending
        } else {
            task = Task.detached(priority: .userInitiated) { Self.decode(url, pixels: key.pixels) }
            requests[key] = task
        }
        let decoded = await task.value
        requests.removeValue(forKey: key)
        if let image = cached(key) { return image }
        guard let decoded else { return nil }
        let bytes = decoded.bytesPerRow * decoded.height
        let image = UIImage(cgImage: decoded)
        guard bytes <= Self.budget else { return image }
        evict(untilAvailable: bytes)
        sequence &+= 1
        entries[key.pet, default: [:]][key] = Entry(image: image, bytes: bytes, used: sequence)
        decodedBytes += bytes
        return image
    }

    private func evict(untilAvailable bytes: Int) {
        guard decodedBytes + bytes > Self.budget else { return }
        let pinned = pins.values.reduce(into: Set<Key>()) { $0.formUnion($1) }
        let oldestFirst = entries.values.flatMap { $0 }.sorted { a, b in
            if pinned.contains(a.key) != pinned.contains(b.key) { return !pinned.contains(a.key) }
            return a.value.used < b.value.used
        }
        for (key, entry) in oldestFirst {
            entries[key.pet]?.removeValue(forKey: key)
            decodedBytes -= entry.bytes
            if decodedBytes + bytes <= Self.budget { break }
        }
    }

    private nonisolated static func decode(_ url: URL, pixels: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let width = properties?[kCGImagePropertyPixelWidth] as? Int ?? pixels
        let height = properties?[kCGImagePropertyPixelHeight] as? Int ?? pixels
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: min(pixels, max(width, height))
        ] as CFDictionary
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options)
    }
}

/// Keeps the previous drawing visible while a thumbnail misses cache.
struct CelFrameImage: View {
    let name: String
    let fallbackName: String?
    let displayPixels: CGFloat
    var fallbackColor: Color = .clear

    @State private var lastImage: UIImage?

    var body: some View {
        let key = CelFrameImageCache.Key(name: name, displayPixels: displayPixels)
        let cache = CelFrameImageCache.shared
        let isBundleCel = CelLibrary.frameURL(name) != nil
        Group {
            if let image = isBundleCel
                ? (cache.cached(key) ?? lastImage ?? fallbackName.flatMap { UIImage(named: $0) })
                : (UIImage(named: name) ?? fallbackName.flatMap { UIImage(named: $0) }) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                Circle().fill(fallbackColor)
            }
        }
        .task(id: key) {
            guard isBundleCel else {
                lastImage = nil
                return
            }
            let image = await cache.image(key)
            if !Task.isCancelled, let image { lastImage = image }
        }
    }
}

struct CelClipPreloader: ViewModifier {
    struct Plan: Equatable {
        let prefix: String
        let pixels: Int
        let current: CelClip?
        let upcoming: [CelClip]

        var keys: [CelFrameImageCache.Key] {
            func frames(_ clip: CelClip) -> [CelFrameImageCache.Key] {
                (1...clip.frames).map {
                    CelFrameImageCache.Key(name: clip.asset(prefix: prefix, frame: $0), displayPixels: CGFloat(pixels))
                }
            }
            let next = upcoming.flatMap(frames)
            let ordered = Array(next.prefix(3)) + (current.map(frames) ?? []) + next.dropFirst(3)
            var seen: Set<CelFrameImageCache.Key> = []
            return ordered.filter { seen.insert($0).inserted && CelLibrary.frameURL($0.name) != nil }
        }
    }

    let plan: Plan?
    @State private var pinOwner = UUID()

    func body(content: Content) -> some View {
        content
            .task(id: plan) {
                let frames = plan?.keys ?? []
                let cache = CelFrameImageCache.shared
                cache.setPins(frames, for: pinOwner)
                for frame in frames {
                    guard !Task.isCancelled else { return }
                    _ = await cache.image(frame)
                }
            }
            .onDisappear { CelFrameImageCache.shared.releasePins(for: pinOwner) }
    }
}
