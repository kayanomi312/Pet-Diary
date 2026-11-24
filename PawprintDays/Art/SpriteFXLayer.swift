import SwiftUI
import UIKit

/// Watercolor strips in the asset catalog. Frames are square cells in a horizontal row.
enum SpriteFXKind: String, Sendable {
    case floorRipple = "floor_ripple"
    case dust
    case heart
    case sparkle
    case coin
    case sleep
    case steam
    case rainSplash = "rain_splash"

    var frameCount: Int { self == .heart ? 8 : 6 }
    var duration: Double { Double(frameCount) / 12 }

    func frame(at age: Double) -> Int? {
        guard age >= 0, age < duration else { return nil }
        return min(frameCount - 1, Int(age * 12))
    }
}

@MainActor
enum SpriteFXLibrary {
    private static let sheets: [SpriteFXKind: Image] = {
        let kinds: [SpriteFXKind] = [.floorRipple, .dust, .heart, .sparkle, .coin, .sleep, .steam, .rainSplash]
        return kinds.reduce(into: [:]) { sheets, kind in
            guard let uiImage = UIImage(named: "fx_\(kind.rawValue)"),
                  abs(uiImage.size.width - uiImage.size.height * CGFloat(kind.frameCount)) < 1 else { return }
            sheets[kind] = Image(uiImage: uiImage)
        }
    }()

    static func contains(_ kind: SpriteFXKind) -> Bool { sheets[kind] != nil }

    @discardableResult
    static func draw(_ kind: SpriteFXKind, age: Double, in rect: CGRect,
                     context: GraphicsContext, opacity: Double = 1) -> Bool {
        guard let image = sheets[kind], let frame = kind.frame(at: age) else { return false }
        var clipped = context
        clipped.clip(to: Path(rect))
        clipped.opacity *= opacity
        clipped.draw(clipped.resolve(image),
                     in: CGRect(x: rect.minX - CGFloat(frame) * rect.width, y: rect.minY,
                                width: rect.width * CGFloat(kind.frameCount), height: rect.height))
        return true
    }
}

struct SpriteFXPool {
    struct Instance: Identifiable {
        let id: UInt64
        let kind: SpriteFXKind
        let position: CGPoint
        let startedAt: Date
    }

    private let capacity = 32
    private var cursor = 0
    private var sequence: UInt64 = 0
    private var slots: [Instance] = []

    mutating func emit(_ kind: SpriteFXKind, at position: CGPoint, time: Date) {
        sequence &+= 1
        let effect = Instance(id: sequence, kind: kind, position: position, startedAt: time)
        if slots.count < capacity { slots.append(effect) }
        else { slots[cursor] = effect }
        cursor = (cursor + 1) % capacity
    }

    func active(at time: Date) -> [Instance] {
        slots.filter { $0.kind.frame(at: time.timeIntervalSince($0.startedAt)) != nil }
    }
}

/// Draw one depth-sorted effect. All effects sample the stage clock.
struct SpriteFXLayer: View {
    let effect: SpriteFXPool.Instance
    let date: Date

    var body: some View {
        let age = date.timeIntervalSince(effect.startedAt)
        Canvas { context, size in
            SpriteFXLibrary.draw(effect.kind, age: age, in: CGRect(origin: .zero, size: size),
                                 context: context)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
