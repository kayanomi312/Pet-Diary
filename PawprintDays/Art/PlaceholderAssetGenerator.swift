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

            // 3.5s natural FFD breathing rhythm anchored at paws
            let breath = sin(time * (2.0 * .pi / 3.5))
            let breathScaleY: CGFloat = 1.0 + CGFloat(breath) * 0.018 + brushRuffleAmount * 0.018
            let breathScaleX: CGFloat = 1.0 - CGFloat(breath) * 0.009 + brushRuffleAmount * 0.010

            // Subtle IK finger tracking lean & tilt (+-6.5 deg)
            let ikX = fingerFocusNormalized?.x ?? 0.0
            let ikY = fingerFocusNormalized?.y ?? 0.0
            let tiltDegrees = Double(ikX) * 6.5 + sin(time * 0.85) * 0.85
            let leanOffsetX = ikX * minDim * 0.022
            let leanOffsetY = ikY * minDim * 0.012 + (pose == .resting ? minDim * 0.035 : 0)

            ZStack {
                // L1_Shadow: Grounded soft watercolor puddle shadow under paws
                Ellipse()
                    .fill(AppTheme.deepPineInk.opacity(0.14))
                    .frame(width: minDim * 0.56, height: minDim * 0.11)
                    .blur(radius: minDim * 0.018)
                    .offset(y: minDim * 0.40 + (pose == .resting ? minDim * 0.02 : 0))

                // Hand-painted 1024x1024 transparent gouache & pencil illustration + synced wardrobe layer
                ZStack {
                    if let uiImage = UIImage(named: assetName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        // Safe vector fallback if an asset is ever missing
                        Circle()
                            .fill(Color(hex: pet.primaryCoatHex))
                            .frame(width: minDim * 0.5, height: minDim * 0.5)
                    }

                    // L4_Socket_Back & L6_Socket_Neck synced wardrobe overlay
                    if let outfitID, let item = ShopCatalog.item(id: outfitID) {
                        WardrobeSocketOverlayCanvas(
                            item: item,
                            neckAnchor: calibratedNeckAnchor,
                            canvasSize: CGSize(width: w, height: h)
                        )
                    }
                }
                .scaleEffect(x: breathScaleX, y: breathScaleY, anchor: .bottom)
                .rotationEffect(.degrees(tiltDegrees), anchor: .bottom)
                .offset(x: leanOffsetX, y: leanOffsetY)

                // Happy purr / brushing / Mentorship watercolor particle motes
                if isHappySquint || brushRuffleAmount > 0.05 || mentorshipParticle != nil {
                    StorybookParticleMotesCanvas(
                        time: isStaticSnapshot ? 0.8 : time,
                        habit: mentorshipParticle,
                        isHappy: isHappySquint || brushRuffleAmount > 0.05
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

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let minDim = min(w, h)
            let nx = w * neckAnchor.u
            let ny = h * neckAnchor.v
            let nw = minDim * neckAnchor.width
            let ink = Color(hex: "#2C3536").opacity(0.75)
            let swatch = Color(hex: item.swatchHex)
            let secondary = Color(hex: item.secondaryHex)

            if item.slotType == "socket_back" {
                // Forager's Canvas Satchel slung gently along side
                let bx = nx + nw * 0.65
                let by = ny + minDim * 0.14
                let bagRect = CGRect(x: bx - minDim * 0.08, y: by - minDim * 0.06, width: minDim * 0.16, height: minDim * 0.13)
                let bagPath = Path(roundedRect: bagRect, cornerRadius: minDim * 0.028)
                ctx.fill(bagPath, with: .color(swatch.opacity(0.95)))
                ctx.stroke(bagPath, with: .color(ink), lineWidth: minDim * 0.008)
                return
            }

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
                style: StrokeStyle(lineWidth: minDim * 0.036, lineCap: .round)
            )
            ctx.stroke(
                collar,
                with: .color(ink),
                style: StrokeStyle(lineWidth: minDim * 0.007, lineCap: .round)
            )

            if item.id.contains("bandana") {
                // Woven bandana kerchief with delicate rice-stitch trim
                var drape = Path()
                drape.move(to: CGPoint(x: nx - nw * 0.42, y: ny + minDim * 0.005))
                drape.addQuadCurve(
                    to: CGPoint(x: nx + nw * 0.42, y: ny + minDim * 0.008),
                    control: CGPoint(x: nx, y: ny + minDim * 0.035)
                )
                drape.addLine(to: CGPoint(x: nx - nw * 0.04, y: ny + minDim * 0.145))
                drape.closeSubpath()
                ctx.fill(drape, with: .color(swatch.opacity(0.96)))
                ctx.stroke(drape, with: .color(secondary.opacity(0.85)), style: StrokeStyle(lineWidth: minDim * 0.005, dash: [minDim * 0.012, minDim * 0.009]))
                ctx.stroke(drape, with: .color(ink), lineWidth: minDim * 0.008)
            } else if item.id == "outfit.occasion_collar" {
                // Heirloom embroidered collar + brass bell charm
                let bellR = minDim * 0.032
                let bellRect = CGRect(x: nx - bellR, y: ny + minDim * 0.025, width: bellR * 2, height: bellR * 2)
                ctx.fill(
                    Path(ellipseIn: bellRect),
                    with: .radialGradient(
                        Gradient(colors: [AppTheme.warmPaper, secondary, AppTheme.brassDark]),
                        center: CGPoint(x: bellRect.midX - bellR * 0.25, y: bellRect.midY - bellR * 0.25),
                        startRadius: 1,
                        endRadius: bellR * 1.3
                    )
                )
                ctx.stroke(Path(ellipseIn: bellRect), with: .color(ink), lineWidth: minDim * 0.007)
            } else {
                // Soft hand-tied cotton ribbon bow
                var leftTail = Path()
                leftTail.move(to: CGPoint(x: nx - minDim * 0.012, y: ny + minDim * 0.020))
                leftTail.addQuadCurve(
                    to: CGPoint(x: nx - minDim * 0.075, y: ny + minDim * 0.105),
                    control: CGPoint(x: nx - minDim * 0.055, y: ny + minDim * 0.050)
                )
                leftTail.addLine(to: CGPoint(x: nx - minDim * 0.025, y: ny + minDim * 0.112))
                leftTail.closeSubpath()
                ctx.fill(leftTail, with: .color(swatch))
                ctx.stroke(leftTail, with: .color(ink), lineWidth: minDim * 0.007)

                var rightTail = Path()
                rightTail.move(to: CGPoint(x: nx + minDim * 0.008, y: ny + minDim * 0.020))
                rightTail.addQuadCurve(
                    to: CGPoint(x: nx + minDim * 0.068, y: ny + minDim * 0.102),
                    control: CGPoint(x: nx + minDim * 0.052, y: ny + minDim * 0.048)
                )
                rightTail.addLine(to: CGPoint(x: nx + minDim * 0.018, y: ny + minDim * 0.110))
                rightTail.closeSubpath()
                ctx.fill(rightTail, with: .color(secondary))
                ctx.stroke(rightTail, with: .color(ink), lineWidth: minDim * 0.007)

                let knotR = minDim * 0.022
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

    var body: some View {
        Canvas { ctx, size in
            let minDim = min(size.width, size.height)
            let cx = size.width * 0.5
            let cy = size.height * 0.38
            let moteColor: Color = {
                switch habit {
                case .nest: return AppTheme.pawInRange
                case .shield: return AppTheme.forestTeal
                case .offer: return AppTheme.pawStrollChain
                case .wait: return AppTheme.vineGreen
                case nil: return AppTheme.pawStrollChain
                }
            }()

            let count = habit != nil ? 5 : 3
            for idx in 0..<count {
                let phase = (time * 0.45 + Double(idx) * (1.0 / Double(count))).truncatingRemainder(dividingBy: 1.0)
                let spread = CGFloat(idx - count / 2) * minDim * 0.11
                let px = cx + spread + CGFloat(sin(time * 1.2 + Double(idx) * 1.4)) * minDim * 0.03
                let py = cy - CGFloat(phase) * minDim * 0.28
                let r = minDim * 0.014 * (1.0 - CGFloat(phase) * 0.35)
                let alpha = sin(phase * .pi) * (isHappy ? 0.72 : 0.58)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                    with: .color(moteColor.opacity(alpha))
                )
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
