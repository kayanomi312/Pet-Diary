import SwiftUI

// MARK: - 1. Tactile Springy Game Button Style
struct TactileGameButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var pressScale: CGFloat = 0.94
    var pressOffsetY: CGFloat = 2.0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? pressScale : 1.0)
            .offset(y: configuration.isPressed && !reduceMotion ? pressOffsetY : 0)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(AppTheme.Motion.resolved(.bouncy, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

// MARK: - 2. Hand-Carved Wood & Parchment Game Plaque Button (3D Lip + Inner Highlight)
enum GamePlaqueTone {
    case forestTeal
    case terracotta
    case warmCream
    case brassGold
    case cedarWood

    var topColor: Color {
        switch self {
        case .forestTeal: return Color(hex: "#296469")
        case .terracotta: return Color(hex: "#D66A41")
        case .warmCream:  return Color(hex: "#FCF8F0")
        case .brassGold:  return Color(hex: "#DDA53A")
        case .cedarWood:  return Color(hex: "#B8885B")
        }
    }

    var bottomColor: Color {
        switch self {
        case .forestTeal: return Color(hex: "#1B464A")
        case .terracotta: return Color(hex: "#B54D28")
        case .warmCream:  return Color(hex: "#EFE5D2")
        case .brassGold:  return Color(hex: "#BA811E")
        case .cedarWood:  return Color(hex: "#93663E")
        }
    }

    var lipColor: Color {
        switch self {
        case .forestTeal: return Color(hex: "#102E31")
        case .terracotta: return Color(hex: "#84351A")
        case .warmCream:  return Color(hex: "#C8B392")
        case .brassGold:  return Color(hex: "#855810")
        case .cedarWood:  return Color(hex: "#674325")
        }
    }

    var foreground: Color {
        switch self {
        case .warmCream: return AppTheme.deepPineInk
        default:         return Color(hex: "#FFFDF8")
        }
    }

    var strokeColor: Color {
        switch self {
        case .warmCream: return AppTheme.timberWarm.opacity(0.65)
        default:         return Color.white.opacity(0.28)
        }
    }
}

struct WoodPlaqueButton: View {
    let title: String
    var systemImage: String? = nil
    var tone: GamePlaqueTone = .forestTeal
    var fontSize: CGFloat = 13
    var horizontalPadding: CGFloat = 15
    var verticalPadding: CGFloat = 10
    var fullWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            HapticsEngine.shared.playBrushStrokeTick()
            action()
        } label: {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: fontSize, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(tone.foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background {
                if tone == .warmCream {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule(style: .continuous).fill(Color(hex: "#FFFDF8").opacity(0.92)))
                        .overlay(Capsule(style: .continuous).stroke(Color(hex: "#CBBAA0").opacity(0.65), lineWidth: 0.9))
                        .shadow(color: Color(hex: "#2D241E").opacity(0.10), radius: 8, y: 3)
                } else {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tone.topColor, tone.bottomColor],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.30), lineWidth: 0.9)
                                .padding(0.5)
                        )
                        .shadow(color: tone.bottomColor.opacity(0.28), radius: 9, y: 4)
                }
            }
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1.5))
    }
}

// MARK: - 3. Unified Warm Stationery Card (Clean Hairline Border + Optional Washi Tape + Soft Shadow)
struct StorybookPaperCard<Content: View>: View {
    var cornerRadius: CGFloat = 18
    var accentColor: Color = AppTheme.timberWarm
    var showWashiTape: Bool = false
    var paddingAmount: CGFloat = 15
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(paddingAmount)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFFDF8"), Color(hex: "#F8F2E7")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color(hex: "#D5C5AE").opacity(0.65), lineWidth: 0.9)
                    )
            )
            .overlay(alignment: .top) {
                if showWashiTape {
                    WashiTapeStrip(color: Color(hex: "#E6CFA3"), angle: -2.0, width: 62)
                        .offset(y: -7)
                }
            }
            .shadow(color: Color(hex: "#2D241E").opacity(0.09), radius: 10, y: 4)
    }
}

struct WashiTapeStrip: View {
    var color: Color = Color(hex: "#E8D5AE")
    var angle: Double = -2.5
    var width: CGFloat = 68

    var body: some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(0.86))
                .frame(width: width, height: 15)
                .overlay(
                    Rectangle()
                        .stroke(AppTheme.timberWarm.opacity(0.28), lineWidth: 0.7)
                )
            // Tiny crosshatch washi pattern
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    Circle()
                        .fill(AppTheme.warmPaper.opacity(0.45))
                        .frame(width: 3, height: 3)
                }
            }
        }
        .rotationEffect(.degrees(angle))
        .shadow(color: AppTheme.deepPineInk.opacity(0.08), radius: 2, y: 1)
    }
}

// MARK: - 4. Unified Capsule Segmented Tab Bar (Matches Floating Dock & Care Tabs!)
struct StitchedClothTabBar<Tab: Hashable & CaseIterable & RawRepresentable>: View where Tab.RawValue == String, Tab.AllCases: RandomAccessCollection {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selection: Tab
    let iconProvider: (Tab) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                let active = (selection == tab)
                Button {
                    guard !active else { return }
                    withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
                        selection = tab
                    }
                    CozySoundEngine.shared.playPaperFlip()
                    HapticsEngine.shared.playBrushStrokeTick()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: iconProvider(tab))
                            .font(.system(size: 11.5, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 12.5, weight: active ? .bold : .semibold, design: .rounded))
                    }
                    .foregroundStyle(active ? Color.white : Color(hex: "#5A4D43"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8.5)
                    .background {
                        if active {
                            Capsule(style: .continuous)
                                .fill(AppTheme.forestTeal)
                                .shadow(color: AppTheme.forestTeal.opacity(0.24), radius: 5, y: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            Capsule(style: .continuous)
                .fill(Color(hex: "#EFE7D8").opacity(0.92))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color(hex: "#D5C5AE").opacity(0.65), lineWidth: 0.85)
                )
        }
    }
}

// MARK: - 5. Painted Miniature Outfit Illustration (For Peg Rack & Pouch Shop)
struct PaintedOutfitMiniatureView: View {
    let itemID: String?
    let swatchHex: String
    var secondaryHex: String = "#FAF6EE"
    var size: CGFloat = 46

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let ink = Color(hex: "#2B3637").opacity(0.78)
            let primary = Color(hex: swatchHex)
            let secondary = Color(hex: secondaryHex)

            guard let itemID else {
                // Bare neck: soft botanical sprout
                var stem = Path()
                stem.move(to: CGPoint(x: w * 0.50, y: h * 0.78))
                stem.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.30), control: CGPoint(x: w * 0.44, y: h * 0.54))
                ctx.stroke(stem, with: .color(AppTheme.vineGreen), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                let leftLeaf = Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.32, width: w * 0.24, height: h * 0.16))
                let rightLeaf = Path(ellipseIn: CGRect(x: w * 0.52, y: h * 0.24, width: w * 0.24, height: h * 0.16))
                ctx.fill(leftLeaf, with: .color(AppTheme.vineGreen.opacity(0.8)))
                ctx.fill(rightLeaf, with: .color(AppTheme.vineGreen))
                ctx.stroke(leftLeaf, with: .color(ink), lineWidth: 1.0)
                ctx.stroke(rightLeaf, with: .color(ink), lineWidth: 1.0)
                return
            }

            if itemID.contains("satchel") {
                // Canvas forager satchel with leather buckle flap
                var strap = Path()
                strap.move(to: CGPoint(x: w * 0.24, y: h * 0.38))
                strap.addQuadCurve(to: CGPoint(x: w * 0.76, y: h * 0.38), control: CGPoint(x: w * 0.50, y: h * 0.06))
                ctx.stroke(strap, with: .color(secondary), style: StrokeStyle(lineWidth: 3.0, lineCap: .round))

                let bag = Path(roundedRect: CGRect(x: w * 0.18, y: h * 0.36, width: w * 0.64, height: h * 0.48), cornerRadius: 7)
                ctx.fill(bag, with: .color(primary))
                ctx.stroke(bag, with: .color(ink), lineWidth: 1.3)

                let flap = Path(roundedRect: CGRect(x: w * 0.18, y: h * 0.36, width: w * 0.64, height: h * 0.22), cornerRadius: 5)
                ctx.fill(flap, with: .color(primary.opacity(0.82)))
                ctx.stroke(flap, with: .color(ink), lineWidth: 1.1)

                let buckle = Path(roundedRect: CGRect(x: w * 0.44, y: h * 0.52, width: w * 0.12, height: h * 0.14), cornerRadius: 2)
                ctx.fill(buckle, with: .color(AppTheme.brassLight))
                ctx.stroke(buckle, with: .color(ink), lineWidth: 0.9)
            } else if itemID.contains("bandana") {
                // Hand-stitched triangular bandana kerchief
                var kerchief = Path()
                kerchief.move(to: CGPoint(x: w * 0.14, y: h * 0.28))
                kerchief.addQuadCurve(to: CGPoint(x: w * 0.86, y: h * 0.28), control: CGPoint(x: w * 0.50, y: h * 0.40))
                kerchief.addLine(to: CGPoint(x: w * 0.50, y: h * 0.84))
                kerchief.closeSubpath()
                ctx.fill(
                    kerchief,
                    with: .linearGradient(
                        Gradient(colors: [primary, primary.opacity(0.82)]),
                        startPoint: CGPoint(x: w * 0.5, y: h * 0.24),
                        endPoint: CGPoint(x: w * 0.5, y: h * 0.84)
                    )
                )
                ctx.stroke(kerchief, with: .color(secondary), style: StrokeStyle(lineWidth: 1.4, dash: [3.2, 2.2]))
                ctx.stroke(kerchief, with: .color(ink), lineWidth: 1.3)
            } else if itemID == "outfit.occasion_collar" {
                // Heirloom embroidered collar + brass bell
                var collar = Path()
                collar.move(to: CGPoint(x: w * 0.16, y: h * 0.36))
                collar.addQuadCurve(to: CGPoint(x: w * 0.84, y: h * 0.36), control: CGPoint(x: w * 0.50, y: h * 0.62))
                ctx.stroke(collar, with: .color(primary), style: StrokeStyle(lineWidth: 9.0, lineCap: .round))
                ctx.stroke(collar, with: .color(secondary), style: StrokeStyle(lineWidth: 2.0, dash: [3, 3]))
                ctx.stroke(collar, with: .color(ink), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))

                let bell = Path(ellipseIn: CGRect(x: w * 0.39, y: h * 0.52, width: w * 0.22, height: h * 0.22))
                ctx.fill(
                    bell,
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: "#FFF8DC"), AppTheme.brassLight, AppTheme.brassDark]),
                        center: CGPoint(x: w * 0.46, y: h * 0.59),
                        startRadius: 1,
                        endRadius: w * 0.14
                    )
                )
                ctx.stroke(bell, with: .color(ink), lineWidth: 1.1)
            } else {
                // Hand-tied cotton ribbon bow
                var leftLoop = Path()
                leftLoop.move(to: CGPoint(x: w * 0.50, y: h * 0.46))
                leftLoop.addCurve(to: CGPoint(x: w * 0.18, y: h * 0.36), control1: CGPoint(x: w * 0.34, y: h * 0.22), control2: CGPoint(x: w * 0.16, y: h * 0.22))
                leftLoop.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.50), control1: CGPoint(x: w * 0.18, y: h * 0.54), control2: CGPoint(x: w * 0.36, y: h * 0.56))
                ctx.fill(leftLoop, with: .color(primary))
                ctx.stroke(leftLoop, with: .color(ink), lineWidth: 1.2)

                var rightLoop = Path()
                rightLoop.move(to: CGPoint(x: w * 0.50, y: h * 0.46))
                rightLoop.addCurve(to: CGPoint(x: w * 0.82, y: h * 0.36), control1: CGPoint(x: w * 0.66, y: h * 0.22), control2: CGPoint(x: w * 0.84, y: h * 0.22))
                rightLoop.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.50), control1: CGPoint(x: w * 0.82, y: h * 0.54), control2: CGPoint(x: w * 0.64, y: h * 0.56))
                ctx.fill(rightLoop, with: .color(primary))
                ctx.stroke(rightLoop, with: .color(ink), lineWidth: 1.2)

                // Ribbon tails
                var tailL = Path()
                tailL.move(to: CGPoint(x: w * 0.46, y: h * 0.50))
                tailL.addLine(to: CGPoint(x: w * 0.28, y: h * 0.82))
                tailL.addLine(to: CGPoint(x: w * 0.40, y: h * 0.80))
                tailL.closeSubpath()
                ctx.fill(tailL, with: .color(secondary))
                ctx.stroke(tailL, with: .color(ink), lineWidth: 1.1)

                var tailR = Path()
                tailR.move(to: CGPoint(x: w * 0.54, y: h * 0.50))
                tailR.addLine(to: CGPoint(x: w * 0.72, y: h * 0.82))
                tailR.addLine(to: CGPoint(x: w * 0.60, y: h * 0.80))
                tailR.closeSubpath()
                ctx.fill(tailR, with: .color(primary))
                ctx.stroke(tailR, with: .color(ink), lineWidth: 1.1)

                let knot = Path(ellipseIn: CGRect(x: w * 0.42, y: h * 0.40, width: w * 0.16, height: h * 0.16))
                ctx.fill(knot, with: .color(primary))
                ctx.stroke(knot, with: .color(ink), lineWidth: 1.1)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 6. Hand-Drawn Embroidered Step-Coin Pouch Icon
struct PaintedPouchIconView: View {
    var size: CGFloat = 24

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let ink = Color(hex: "#2B3637").opacity(0.78)

            // Gathered top ruffle
            var top = Path()
            top.move(to: CGPoint(x: w * 0.30, y: h * 0.24))
            top.addLine(to: CGPoint(x: w * 0.36, y: h * 0.10))
            top.addLine(to: CGPoint(x: w * 0.50, y: h * 0.16))
            top.addLine(to: CGPoint(x: w * 0.64, y: h * 0.10))
            top.addLine(to: CGPoint(x: w * 0.70, y: h * 0.24))
            top.closeSubpath()
            ctx.fill(top, with: .color(Color(hex: "#D5A760")))
            ctx.stroke(top, with: .color(ink), lineWidth: 1.0)

            // Round plump linen pouch belly
            let belly = Path(ellipseIn: CGRect(x: w * 0.14, y: h * 0.26, width: w * 0.72, height: h * 0.64))
            ctx.fill(
                belly,
                with: .radialGradient(
                    Gradient(colors: [Color(hex: "#F2D48E"), Color(hex: "#C99342")]),
                    center: CGPoint(x: w * 0.42, y: h * 0.46),
                    startRadius: 1,
                    endRadius: w * 0.45
                )
            )
            ctx.stroke(belly, with: .color(ink), lineWidth: 1.2)

            // Red-teal drawstring cord
            var cord = Path()
            cord.move(to: CGPoint(x: w * 0.28, y: h * 0.29))
            cord.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.29), control: CGPoint(x: w * 0.50, y: h * 0.36))
            ctx.stroke(cord, with: .color(AppTheme.clothBookmark), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

            // Tiny brass paw emblem on pouch front
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.42, y: h * 0.54, width: w * 0.16, height: h * 0.14)), with: .color(AppTheme.forestTeal.opacity(0.75)))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 7. Hanko Celebration Ink Stamp + Watercolor Confetti Burst
struct HankoCelebrationStampView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    var subtitle: String? = nil
    var stampColor: Color = AppTheme.clothBookmark

    @State private var stamped = false
    @State private var burst = false

    var body: some View {
        ZStack {
            // Radiating watercolor petals & golden sparkles
            ForEach(0..<10, id: \.self) { idx in
                let angle = Double(idx) * (360.0 / 10.0) * .pi / 180.0
                let radius: CGFloat = burst ? 76 : 12
                Circle()
                    .fill(idx % 2 == 0 ? AppTheme.pawStrollChain : stampColor.opacity(0.78))
                    .frame(width: idx % 3 == 0 ? 7 : 5, height: idx % 3 == 0 ? 7 : 5)
                    .offset(x: cos(angle) * radius, y: sin(angle) * radius)
                    .opacity(burst ? 0.0 : 0.92)
            }

            // Carved vermilion/gold seal plaque
            VStack(spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text(title)
                        .font(AppTheme.serifTitle(15))
                }
                .foregroundStyle(stampColor)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTheme.diegeticLabel(10))
                        .foregroundStyle(AppTheme.deepPineInk.opacity(0.78))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.warmPaper.opacity(0.96))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(stampColor, lineWidth: 2.2)
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(stampColor.opacity(0.55), style: StrokeStyle(lineWidth: 1.0, dash: [3, 2]))
                        .padding(3)
                }
            )
            .rotationEffect(.degrees(stamped || reduceMotion ? -3.5 : -14))
            .scaleEffect(stamped || reduceMotion ? 1.0 : 1.75)
            .opacity(stamped ? 1.0 : 0.0)
            .shadow(color: stampColor.opacity(0.25), radius: 8, y: 4)
        }
        .onAppear {
            withAnimation(AppTheme.Motion.resolved(.bouncy, reduceMotion: reduceMotion)) {
                stamped = true
            }
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.85)) { burst = true }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 8. Sunroom Ambient Cozy Speech Bubble
struct SunroomPetSpeechBubble: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(AppTheme.handwritten(11))
                .foregroundStyle(AppTheme.deepPineInk)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(AppTheme.warmPaper.opacity(0.95))
                        .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.5), lineWidth: 1))
                        .shadow(color: AppTheme.deepPineInk.opacity(0.14), radius: 4, y: 2)
                )

            // Tiny speech pointer dot trail
            Circle()
                .fill(AppTheme.warmPaper.opacity(0.95))
                .frame(width: 6, height: 6)
                .overlay(Circle().stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 0.8))
                .offset(y: -1)
        }
        .transition(reduceMotion ? .opacity : .scale(scale: 0.75).combined(with: .opacity))
    }
}

// MARK: - 9. Live Touch Sparkle & Heart Trail (For Tactile Care Petting/Brushing)
struct TouchSparkleSeed: Identifiable {
    let id = UUID()
    let position: CGPoint
    let createdAt: Date
    let isHeart: Bool
    let driftX: CGFloat
    let color: Color
}

struct LiveTouchSparkleLayer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let seeds: [TouchSparkleSeed]

    var body: some View {
        TimelineView(.animation(minimumInterval: AppTheme.Motion.interval(fps: 30.0, reduceMotion: reduceMotion))) { timeline in
            let now = timeline.date
            Canvas { ctx, _ in
                for seed in seeds {
                    let age = now.timeIntervalSince(seed.createdAt)
                    guard age >= 0 && age < 0.95 else { continue }
                    let p = reduceMotion ? 0 : CGFloat(age / 0.95)
                    let alpha = Double(1.0 - p)
                    let x = seed.position.x + seed.driftX * p
                    let y = seed.position.y - p * 44
                    let s = (1.0 - p * 0.35) * (seed.isHeart ? 11.0 : 8.0)

                    let sprite: SpriteFXKind = seed.isHeart ? .heart : .sparkle
                    let rect = CGRect(x: x - s, y: y - s, width: s * 2, height: s * 2)
                    if SpriteFXLibrary.draw(sprite, age: Double(p) * sprite.duration,
                                            in: rect, context: ctx, opacity: alpha) { continue }
                    if seed.isHeart {
                        var heart = Path()
                        heart.move(to: CGPoint(x: x, y: y + s * 0.45))
                        heart.addCurve(
                            to: CGPoint(x: x - s * 0.65, y: y - s * 0.15),
                            control1: CGPoint(x: x - s * 0.45, y: y + s * 0.30),
                            control2: CGPoint(x: x - s * 0.75, y: y + s * 0.05)
                        )
                        heart.addArc(center: CGPoint(x: x - s * 0.32, y: y - s * 0.20), radius: s * 0.33, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                        heart.addArc(center: CGPoint(x: x + s * 0.32, y: y - s * 0.20), radius: s * 0.33, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                        heart.addCurve(
                            to: CGPoint(x: x, y: y + s * 0.45),
                            control1: CGPoint(x: x + s * 0.75, y: y + s * 0.05),
                            control2: CGPoint(x: x + s * 0.45, y: y + s * 0.30)
                        )
                        ctx.fill(heart, with: .color(seed.color.opacity(alpha * 0.9)))
                    } else {
                        // 4-point storybook sparkle star
                        var star = Path()
                        star.move(to: CGPoint(x: x, y: y - s))
                        star.addQuadCurve(to: CGPoint(x: x + s, y: y), control: CGPoint(x: x + s * 0.18, y: y - s * 0.18))
                        star.addQuadCurve(to: CGPoint(x: x, y: y + s), control: CGPoint(x: x + s * 0.18, y: y + s * 0.18))
                        star.addQuadCurve(to: CGPoint(x: x - s, y: y), control: CGPoint(x: x - s * 0.18, y: y + s * 0.18))
                        star.addQuadCurve(to: CGPoint(x: x, y: y - s), control: CGPoint(x: x - s * 0.18, y: y - s * 0.18))
                        ctx.fill(star, with: .color(seed.color.opacity(alpha)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 10. 《貓與龍》奇幻物種徽章（貓型火龍、貓型惡魔、貓型夜翼、鹿角森靈等）
struct SpeciesFolkloreBadgeView: View {
    let kind: PetSpeciesKind
    var showFullName: Bool = true

    var body: some View {
        let tint = Color(hex: kind.badgeHex)
        HStack(spacing: 4) {
            Image(systemName: kind.badgeSymbol)
                .font(.system(size: 10.5, weight: .bold))
            Text(showFullName ? "\(kind.folkloreCategoryTag) · \(kind.rawValue)" : kind.folkloreCategoryTag)
                .font(AppTheme.diegeticLabel(10.5))
        }
        .foregroundStyle(kind.isMagical ? Color(hex: "#FFFDF7") : AppTheme.deepPineInk)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(kind.isMagical ? tint : AppTheme.warmPaper.opacity(0.95))
                .overlay(
                    Capsule()
                        .stroke(kind.isMagical ? Color.white.opacity(0.32) : tint.opacity(0.55), lineWidth: 1)
                )
        )
        .shadow(color: tint.opacity(0.22), radius: 3, y: 1)
    }
}
