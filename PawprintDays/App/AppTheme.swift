import SwiftUI

enum AppTheme {
    enum Motion {
        static let short = 0.16
        static let standard = 0.28
        static let relaxed = 0.42
        static let reduced = Animation.easeInOut(duration: short)

        enum Preset {
            case gentle, bouncy, snappy, settle
        }

        static func resolved(_ preset: Preset, reduceMotion: Bool) -> Animation {
            if reduceMotion { return reduced }
            switch preset {
            case .gentle: return .spring(response: relaxed, dampingFraction: 0.83)
            case .bouncy: return .spring(response: standard, dampingFraction: 0.58)
            case .snappy: return .spring(response: 0.23, dampingFraction: 0.8)
            case .settle: return .spring(response: 0.32, dampingFraction: 0.78)
            }
        }

        static func interval(fps: Double, reduceMotion: Bool) -> TimeInterval {
            reduceMotion ? 1 : 1 / fps
        }
    }

    // WCAG 2.2 AAA Outdoor Contrast Palette
    static let warmPaper = Color(hex: "#FAF6EE")         // Cotton-rag paper
    static let parchmentTray = Color(hex: "#F3ECE0")     // Tactile drawer surface
    static let deepPineInk = Color(hex: "#132A2C")       // 11.4:1 contrast on warmPaper
    static let forestTeal = Color(hex: "#1F4E52")        // 9.2:1 contrast with white text
    static let softInk = Color(hex: "#46585A")           // Secondary ink (7.2:1 on warmPaper)

    // Color-Blind-Safe Paw States
    static let pawDistant = Color(hex: "#4E6E74")        // Slate Teal
    static let pawInRange = Color(hex: "#C85A32")        // Glowing Terracotta
    static let pawMetToday = Color(hex: "#7A6252")       // Sepia Sketch
    static let pawStrollChain = Color(hex: "#C98D26")    // Amber Gold Halo

    // Physical Diegetic Material Tones
    static let brassLight = Color(hex: "#D7B267")
    static let brassDark = Color(hex: "#8F6A29")
    static let timberWarm = Color(hex: "#A87C52")
    static let timberDeep = Color(hex: "#5B3E26")
    static let wicker = Color(hex: "#C79C63")
    static let ceramicCream = Color(hex: "#EFE7D8")
    static let ceramicGlaze = Color(hex: "#4A7276")
    static let clothBookmark = Color(hex: "#B84A39")
    static let vineGreen = Color(hex: "#4B7A54")
    static let rainySlate = Color(hex: "#6F8592")
    static let duskAmber = Color(hex: "#D69F5E")

    // Storybook Typography (scales dynamically with Dynamic Type)
    static func serifTitle(_ size: CGFloat = 22) -> Font {
        .system(textStyle(for: size), design: .serif).weight(.semibold)
    }

    static func serifBody(_ size: CGFloat = 16) -> Font {
        .system(textStyle(for: size), design: .serif)
    }

    static func handwritten(_ size: CGFloat = 16) -> Font {
        .system(textStyle(for: size), design: .serif).italic()
    }

    static func diegeticLabel(_ size: CGFloat = 13) -> Font {
        .system(textStyle(for: size), design: .rounded).weight(.semibold)
    }

    private static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 24...: return .title
        case 20..<24: return .title2
        case 17..<20: return .title3
        case 14.5..<17: return .subheadline
        case 12.5..<14.5: return .footnote
        case 11.2..<12.5: return .caption
        default: return .caption2
        }
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (128, 128, 128, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}
