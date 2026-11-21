import SwiftUI
import UIKit

enum PetRigPose: String, Sendable {
    case notice
    case respond
    case resting
}

/// 2.5D Hand-Painted Taiwanese Storybook Rig (with Procedural Fallback):
/// Renders each pet's bundled 1024x1024 transparent gouache & colored-pencil illustration (`pet_01`..`pet_08`)
/// at 60fps with:
/// - Grounded gouache contact shadow (`L1_Shadow`)
/// - 3.5s breathing deformation anchored cleanly at the paws
/// - Live IK finger tracking tilt & subtle lean toward the user's touch
/// - Calibrated `socket_neck` wardrobe binding (ribbons, rice-stitched bandanas, heirloom brass bell)
///   and `socket_back` canvas satchel moving in sync with breathing and tilt
/// - Happy-purr / brushing warmth sparkles & Shared-Prop Mentorship floating particle motes
/// - Unified `PaperGrainAndLUT.metal` shader pass across illustration and accessories
struct ProceduralPetRigView: View {
    let pet: PetSpec
    var outfitID: String? = nil
    var pose: PetRigPose = .notice
    var weatherMode: WeatherMode = .lightRain
    var fingerFocusNormalized: CGPoint? = nil
    var isHappySquint: Bool = false
    var brushRuffleAmount: CGFloat = 0.0
    var mentorshipParticle: HabitFamily? = nil
    var applyMetalPaperShader: Bool = true
    var isStaticSnapshot: Bool = false
    var tapBounceScale: CGFloat = 0.0

    private var assetName: String {
        pet.id.replacingOccurrences(of: ".", with: "_") // "pet.01" -> "pet_01"
    }

    var body: some View {
        Group {
            if isStaticSnapshot {
                animatedArtStack(time: 1.2)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    animatedArtStack(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .modifier(PaperGrainShaderModifier(weatherMode: weatherMode, enabled: applyMetalPaperShader))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityStoryLabel)
    }

    private var accessibilityStoryLabel: String {
        let outfitText: String
        if let outfitID, let item = ShopCatalog.item(id: outfitID) {
            outfitText = "，正配戴\(item.name)"
        } else {
            outfitText = ""
        }
        return "\(pet.name)，\(pet.personalityWord)的\(pet.kind.rawValue)\(outfitText)。"
    }

    /// Calibrated neck anchor `(u, v, neckWidthFraction)` matched to each 1024x1024 hand-painted pet portrait.
    private var calibratedNeckAnchor: (u: CGFloat, v: CGFloat, width: CGFloat) {
        switch pet.id {
        case "pet.01": return (0.41, 0.365, 0.21) // 芝麻
        case "pet.02": return (0.37, 0.355, 0.18) // 杜松
        case "pet.03": return (0.39, 0.370, 0.21) // 餘燼
        case "pet.04": return (0.41, 0.370, 0.20) // 摺翼
        case "pet.05": return (0.52, 0.380, 0.22) // 味噌
        case "pet.06": return (0.43, 0.400, 0.25) // 鈕扣
        case "pet.07": return (0.45, 0.375, 0.21) // 梅子
        case "pet.08": return (0.54, 0.335, 0.17) // 蘆葦
        default:       return (0.44, 0.370, 0.20)
        }
    }

    @ViewBuilder
    private func animatedArtStack(time: Double) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minDim = min(w, h)

            // 3.5s natural FFD breathing rhythm anchored at paws + playful squash-and-stretch on tap
            let breath = sin(time * (2.0 * .pi / 3.5))
            let breathScaleY: CGFloat = 1.0 + CGFloat(breath) * 0.018 + brushRuffleAmount * 0.022 + tapBounceScale * 0.08
            let breathScaleX: CGFloat = 1.0 - CGFloat(breath) * 0.009 + brushRuffleAmount * 0.012 - tapBounceScale * 0.05

            // Subtle IK finger tracking lean & tilt (+-6.5 deg)
            let ikX = fingerFocusNormalized?.x ?? 0.0
            let ikY = fingerFocusNormalized?.y ?? 0.0
            let tiltDegrees = Double(ikX) * 6.5 + sin(time * 0.85) * 0.85
            let leanOffsetX = ikX * minDim * 0.022
            let leanOffsetY = ikY * minDim * 0.012 + (pose == .resting ? minDim * 0.035 : 0) - tapBounceScale * minDim * 0.04

            let rimGlowColor: Color = {
                switch weatherMode {
                case .dusk: return Color(hex: "#F5C06B").opacity(0.22)
                case .lightRain, .postRain: return Color(hex: "#BBD5DF").opacity(0.18)
                case .clearMorning: return Color(hex: "#FFF6D6").opacity(0.24)
                case .overcast: return Color(hex: "#E8ECE8").opacity(0.14)
                }
            }()

            ZStack {
                // Soft ambient weather aura behind pet silhouette
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [rimGlowColor, .clear],
                            center: .center,
                            startRadius: minDim * 0.08,
                            endRadius: minDim * 0.48
                        )
                    )
                    .frame(width: minDim * 0.86, height: minDim * 0.78)
                    .offset(y: minDim * 0.04)

                // L1_Shadow: Grounded multi-layer watercolor puddle shadow under paws
                Ellipse()
                    .fill(AppTheme.deepPineInk.opacity(0.17))
                    .frame(width: minDim * 0.58, height: minDim * 0.12)
                    .blur(radius: minDim * 0.020)
                    .offset(y: minDim * 0.40 + (pose == .resting ? minDim * 0.02 : 0))

                Ellipse()
                    .fill(AppTheme.deepPineInk.opacity(0.10))
                    .frame(width: minDim * 0.42, height: minDim * 0.07)
                    .offset(y: minDim * 0.40 + (pose == .resting ? minDim * 0.02 : 0))

                // Hand-painted 1024x1024 transparent gouache & pencil illustration + synced wardrobe layer
                ZStack {
                    if let uiImage = UIImage(named: assetName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Circle()
                            .fill(Color(hex: pet.primaryCoatHex))
                            .frame(width: minDim * 0.5, height: minDim * 0.5)
                    }

                    // Soft watercolor warm cheek glow when happy / being brushed
                    if isHappySquint || brushRuffleAmount > 0.08 {
                        let blushX = w * (calibratedNeckAnchor.u - 0.03)
                        let blushY = h * (calibratedNeckAnchor.v - 0.10)
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "#E88B72").opacity(0.32), .clear],
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: minDim * 0.09
                                )
                            )
                            .frame(width: minDim * 0.18, height: minDim * 0.12)
                            .position(x: blushX, y: blushY)
                            .allowsHitTesting(false)
                    }

                    // L4_Socket_Back & L6_Socket_Neck synced wardrobe overlay
                    if let outfitID, let item = ShopCatalog.item(id: outfitID) {
                        WardrobeSocketOverlayCanvas(
                            item: item,
                            neckAnchor: calibratedNeckAnchor,
                            canvasSize: CGSize(width: w, height: h),
                            time: isStaticSnapshot ? 0.5 : time
                        )
                    }
                }
                .scaleEffect(x: breathScaleX, y: breathScaleY, anchor: .bottom)
                .rotationEffect(.degrees(tiltDegrees), anchor: .bottom)
                .offset(x: leanOffsetX, y: leanOffsetY)

                // Happy purr / brushing / Mentorship watercolor particle motes (hearts, stars, sleepy Zzz)
                if isHappySquint || brushRuffleAmount > 0.05 || mentorshipParticle != nil || pose == .resting {
                    StorybookParticleMotesCanvas(
                        time: isStaticSnapshot ? 0.8 : time,
                        habit: mentorshipParticle,
                        isHappy: isHappySquint || brushRuffleAmount > 0.05,
                        isResting: pose == .resting && !isHappySquint && brushRuffleAmount <= 0.05
                    )
                    .allowsHitTesting(false)
                }
            }
            .frame(width: w, height: h)
        }
    }
}

/// Painterly gouache wardrobe overlay bound cleanly to each hand-painted pet's `socket_neck` or `socket_back`.
private struct WardrobeSocketOverlayCanvas: View {
    let item: ShopItemSpec
    let neckAnchor: (u: CGFloat, v: CGFloat, width: CGFloat)
    let canvasSize: CGSize
    let time: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let minDim = min(w, h)
            let nx = w * neckAnchor.u
            let ny = h * neckAnchor.v
            let nw = minDim * neckAnchor.width
            let ink = Color(hex: "#2C3536").opacity(0.76)
            let swatch = Color(hex: item.swatchHex)
            let secondary = Color(hex: item.secondaryHex)
            let sway = CGFloat(sin(time * 2.1)) * minDim * 0.008

            if item.slotType == "socket_back" {
                // Forager's Canvas Satchel with diagonal leather strap & brass buckle
                let bx = nx + nw * 0.65
                let by = ny + minDim * 0.14
                var strap = Path()
                strap.move(to: CGPoint(x: nx - nw * 0.25, y: ny))
                strap.addQuadCurve(to: CGPoint(x: bx, y: by - minDim * 0.04), control: CGPoint(x: nx + nw * 0.3, y: ny + minDim * 0.03))
                ctx.stroke(strap, with: .color(secondary), style: StrokeStyle(lineWidth: minDim * 0.020, lineCap: .round))

                let bagRect = CGRect(x: bx - minDim * 0.085, y: by - minDim * 0.06, width: minDim * 0.17, height: minDim * 0.135)
                let bagShadow = bagRect.offsetBy(dx: 0, dy: minDim * 0.012)
                ctx.fill(Path(roundedRect: bagShadow, cornerRadius: minDim * 0.03), with: .color(AppTheme.deepPineInk.opacity(0.18)))

                let bagPath = Path(roundedRect: bagRect, cornerRadius: minDim * 0.028)
                ctx.fill(bagPath, with: .color(swatch.opacity(0.96)))
                let flapRect = CGRect(x: bagRect.minX, y: bagRect.minY, width: bagRect.width, height: bagRect.height * 0.45)
                ctx.fill(Path(roundedRect: flapRect, cornerRadius: minDim * 0.02), with: .color(swatch))
                ctx.stroke(Path(roundedRect: flapRect, cornerRadius: minDim * 0.02), with: .color(ink.opacity(0.55)), lineWidth: minDim * 0.006)
                ctx.fill(Path(roundedRect: CGRect(x: bagRect.midX - minDim * 0.016, y: flapRect.maxY - minDim * 0.014, width: minDim * 0.032, height: minDim * 0.032), cornerRadius: 2), with: .color(AppTheme.brassLight))
                ctx.stroke(bagPath, with: .color(ink), lineWidth: minDim * 0.008)
                return
            }

            // Soft fur contact shadow cast underneath the collar
            var collarShadow = Path()
            collarShadow.move(to: CGPoint(x: nx - nw * 0.52, y: ny - minDim * 0.004))
            collarShadow.addQuadCurve(
                to: CGPoint(x: nx + nw * 0.52, y: ny + minDim * 0.002),
                control: CGPoint(x: nx, y: ny + minDim * 0.056)
            )
            ctx.stroke(
                collarShadow,
                with: .color(AppTheme.deepPineInk.opacity(0.20)),
                style: StrokeStyle(lineWidth: minDim * 0.042, lineCap: .round)
            )

            // Curved collar strap following the cat/dog's neck contour
            var collar = Path()
            collar.move(to: CGPoint(x: nx - nw * 0.52, y: ny - minDim * 0.015))
            collar.addQuadCurve(
                to: CGPoint(x: nx + nw * 0.52, y: ny - minDim * 0.010),
                control: CGPoint(x: nx, y: ny + minDim * 0.045)
            )
            ctx.stroke(
                collar,
                with: .color(swatch),
                style: StrokeStyle(lineWidth: minDim * 0.038, lineCap: .round)
            )
            // Soft cotton top sheen along collar
            ctx.stroke(
                collar,
                with: .color(.white.opacity(0.22)),
                style: StrokeStyle(lineWidth: minDim * 0.011, lineCap: .round)
            )
            ctx.stroke(
                collar,
                with: .color(ink),
                style: StrokeStyle(lineWidth: minDim * 0.007, lineCap: .round)
            )

            if item.id.contains("bandana") {
                // Woven bandana kerchief with layered shade + sashiko rice-stitch trim
                var drape = Path()
                drape.move(to: CGPoint(x: nx - nw * 0.44, y: ny + minDim * 0.005))
                drape.addQuadCurve(
                    to: CGPoint(x: nx + nw * 0.44, y: ny + minDim * 0.008),
                    control: CGPoint(x: nx, y: ny + minDim * 0.036)
                )
                drape.addLine(to: CGPoint(x: nx - nw * 0.04 + sway, y: ny + minDim * 0.155))
                drape.closeSubpath()
                ctx.fill(
                    drape,
                    with: .linearGradient(
                        Gradient(colors: [swatch, swatch.opacity(0.84)]),
                        startPoint: CGPoint(x: nx, y: ny),
                        endPoint: CGPoint(x: nx, y: ny + minDim * 0.16)
                    )
                )
                // Inner sashiko stitch line
                var innerStitch = Path()
                innerStitch.move(to: CGPoint(x: nx - nw * 0.34, y: ny + minDim * 0.022))
                innerStitch.addLine(to: CGPoint(x: nx - nw * 0.03 + sway * 0.8, y: ny + minDim * 0.132))
                innerStitch.addLine(to: CGPoint(x: nx + nw * 0.34, y: ny + minDim * 0.024))
                ctx.stroke(innerStitch, with: .color(secondary.opacity(0.88)), style: StrokeStyle(lineWidth: minDim * 0.006, dash: [minDim * 0.014, minDim * 0.009]))
                ctx.stroke(drape, with: .color(ink), lineWidth: minDim * 0.008)
            } else if item.id == "outfit.occasion_collar" {
                // Gold embroidery dashes along collar + gently swinging heirloom brass bell
                ctx.stroke(collar, with: .color(secondary.opacity(0.85)), style: StrokeStyle(lineWidth: minDim * 0.008, dash: [minDim * 0.014, minDim * 0.014]))
                let bellR = minDim * 0.034
                let bellRect = CGRect(x: nx - bellR + sway * 0.9, y: ny + minDim * 0.026, width: bellR * 2, height: bellR * 2)
                ctx.fill(
                    Path(ellipseIn: bellRect),
                    with: .radialGradient(
                        Gradient(colors: [AppTheme.warmPaper, secondary, AppTheme.brassDark]),
                        center: CGPoint(x: bellRect.midX - bellR * 0.28, y: bellRect.midY - bellR * 0.28),
                        startRadius: 1,
                        endRadius: bellR * 1.35
                    )
                )
                // Bell sound slit
                var slit = Path()
                slit.move(to: CGPoint(x: bellRect.minX + bellR * 0.35, y: bellRect.midY + bellR * 0.32))
                slit.addLine(to: CGPoint(x: bellRect.maxX - bellR * 0.35, y: bellRect.midY + bellR * 0.32))
                ctx.stroke(slit, with: .color(ink), lineWidth: minDim * 0.007)
                ctx.stroke(Path(ellipseIn: bellRect), with: .color(ink), lineWidth: minDim * 0.007)
            } else {
                // Soft hand-tied cotton ribbon bow with fluttering tails
                var leftTail = Path()
                leftTail.move(to: CGPoint(x: nx - minDim * 0.012, y: ny + minDim * 0.020))
                leftTail.addQuadCurve(
                    to: CGPoint(x: nx - minDim * 0.078 + sway, y: ny + minDim * 0.112),
                    control: CGPoint(x: nx - minDim * 0.058, y: ny + minDim * 0.052)
                )
                leftTail.addLine(to: CGPoint(x: nx - minDim * 0.024 + sway * 0.7, y: ny + minDim * 0.118))
                leftTail.closeSubpath()
                ctx.fill(leftTail, with: .color(swatch))
                ctx.stroke(leftTail, with: .color(ink), lineWidth: minDim * 0.007)

                var rightTail = Path()
                rightTail.move(to: CGPoint(x: nx + minDim * 0.008, y: ny + minDim * 0.020))
                rightTail.addQuadCurve(
                    to: CGPoint(x: nx + minDim * 0.072 + sway, y: ny + minDim * 0.108),
                    control: CGPoint(x: nx + minDim * 0.054, y: ny + minDim * 0.050)
                )
                rightTail.addLine(to: CGPoint(x: nx + minDim * 0.018 + sway * 0.7, y: ny + minDim * 0.114))
                rightTail.closeSubpath()
                ctx.fill(rightTail, with: .color(secondary))
                ctx.stroke(rightTail, with: .color(ink), lineWidth: minDim * 0.007)

                let knotR = minDim * 0.024
                let knotRect = CGRect(x: nx - knotR, y: ny + minDim * 0.004, width: knotR * 2, height: knotR * 2)
                ctx.fill(Path(ellipseIn: knotRect), with: .color(swatch))
                ctx.stroke(Path(ellipseIn: knotRect), with: .color(ink), lineWidth: minDim * 0.007)
            }
        }
    }
}

private struct StorybookParticleMotesCanvas: View {
    let time: Double
    let habit: HabitFamily?
    let isHappy: Bool
    var isResting: Bool = false

    var body: some View {
        Canvas { ctx, size in
            let minDim = min(size.width, size.height)
            let cx = size.width * 0.5
            let cy = size.height * 0.34
            let moteColor: Color = {
                switch habit {
                case .nest: return AppTheme.pawInRange
                case .shield: return AppTheme.forestTeal
                case .offer: return AppTheme.pawStrollChain
                case .wait: return AppTheme.vineGreen
                case nil: return AppTheme.pawStrollChain
                }
            }()

            if isResting && habit == nil {
                // Soft dreamy floating zzz motes for resting pets
                for idx in 0..<2 {
                    let phase = (time * 0.32 + Double(idx) * 0.5).truncatingRemainder(dividingBy: 1.0)
                    let px = cx + minDim * 0.18 + CGFloat(sin(time + Double(idx))) * minDim * 0.025
                    let py = cy - CGFloat(phase) * minDim * 0.22
                    let alpha = sin(phase * .pi) * 0.52
                    let r = minDim * (0.012 + CGFloat(idx) * 0.005)
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                        with: .color(AppTheme.warmPaper.opacity(alpha)),
                        lineWidth: 1.4
                    )
                }
                return
            }

            let count = habit != nil ? 6 : 4
            for idx in 0..<count {
                let phase = (time * 0.48 + Double(idx) * (1.0 / Double(count))).truncatingRemainder(dividingBy: 1.0)
                let spread = CGFloat(idx - count / 2) * minDim * 0.10
                let px = cx + spread + CGFloat(sin(time * 1.35 + Double(idx) * 1.5)) * minDim * 0.032
                let py = cy - CGFloat(phase) * minDim * 0.30
                let s = minDim * 0.020 * (1.0 - CGFloat(phase) * 0.3)
                let alpha = sin(phase * .pi) * (isHappy ? 0.85 : 0.65)

                if isHappy && idx % 2 == 0 {
                    // Miniature hand-drawn heart
                    var heart = Path()
                    heart.move(to: CGPoint(x: px, y: py + s * 0.5))
                    heart.addCurve(to: CGPoint(x: px - s * 0.7, y: py - s * 0.1), control1: CGPoint(x: px - s * 0.5, y: py + s * 0.3), control2: CGPoint(x: px - s * 0.8, y: py + s * 0.05))
                    heart.addArc(center: CGPoint(x: px - s * 0.35, y: py - s * 0.2), radius: s * 0.35, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                    heart.addArc(center: CGPoint(x: px + s * 0.35, y: py - s * 0.2), radius: s * 0.35, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                    heart.addCurve(to: CGPoint(x: px, y: py + s * 0.5), control1: CGPoint(x: px + s * 0.8, y: py + s * 0.05), control2: CGPoint(x: px + s * 0.5, y: py + s * 0.3))
                    ctx.fill(heart, with: .color(Color(hex: "#D96A52").opacity(alpha)))
                } else {
                    // 4-point storybook golden sparkle
                    var star = Path()
                    star.move(to: CGPoint(x: px, y: py - s))
                    star.addQuadCurve(to: CGPoint(x: px + s, y: py), control: CGPoint(x: px + s * 0.2, y: py - s * 0.2))
                    star.addQuadCurve(to: CGPoint(x: px, y: py + s), control: CGPoint(x: px + s * 0.2, y: py + s * 0.2))
                    star.addQuadCurve(to: CGPoint(x: px - s, y: py), control: CGPoint(x: px - s * 0.2, y: py + s * 0.2))
                    star.addQuadCurve(to: CGPoint(x: px, y: py - s), control: CGPoint(x: px - s * 0.2, y: py - s * 0.2))
                    ctx.fill(star, with: .color(moteColor.opacity(alpha)))
                }
            }
        }
    }
}

struct PaperGrainShaderModifier: ViewModifier {
    let weatherMode: WeatherMode
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.colorEffect(
                ShaderLibrary.paperGrainAndWeather(.float(weatherMode.shaderValue))
            )
        } else {
            content
        }
    }
}
