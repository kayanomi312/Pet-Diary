import SwiftUI
import UIKit

enum PetRigPose: String, Sendable {
    case notice
    case respond
    case resting
}

/// 可愛活體互動與移動動畫狀態（軟糯麻糬彈跳、撲玩逗貓棒、開心嚼點心、蓋被被午睡、轉圈撒嬌、搖擺散步）
enum PetPlayfulAction: Equatable, Sendable {
    case idle
    case bellyBoop
    case pounceHop
    case eatMunch
    case cozyNap
    case happyTwirl
    case curiousWaddle
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
    var playfulAction: PetPlayfulAction = .idle
    var actionTriggerDate: Date = .distantPast

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

    private struct PlayfulTransform {
        var scaleX: CGFloat = 0
        var scaleY: CGFloat = 0
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        var rotationDeg: Double = 0
        var flipScaleX: CGFloat = 1.0
        var isExcited: Bool = false
    }

    private func computePlayfulTransform(time: Double, minDim: CGFloat) -> PlayfulTransform {
        var res = PlayfulTransform()
        let elapsed = isStaticSnapshot ? 99.0 : max(0, Date().timeIntervalSince(actionTriggerDate))

        switch playfulAction {
        case .idle:
            break
        case .bellyBoop:
            if elapsed < 1.15 {
                let p = elapsed / 1.15
                let jelly = sin(p * .pi * 5.0) * exp(-p * 3.2)
                let hop = sin(min(1.0, p * 1.8) * .pi)
                res.scaleX = CGFloat(-jelly * 0.16)
                res.scaleY = CGFloat(jelly * 0.17)
                res.offsetY = -CGFloat(hop) * minDim * 0.10
                res.rotationDeg = jelly * 8.0
                res.isExcited = true
            }
        case .pounceHop:
            if elapsed < 1.35 {
                let p = elapsed / 1.35
                if p < 0.25 {
                    let c = p / 0.25
                    res.scaleX = CGFloat(c * 0.14)
                    res.scaleY = CGFloat(-c * 0.14)
                    res.offsetY = CGFloat(c) * minDim * 0.03
                } else if p < 0.75 {
                    let j = (p - 0.25) / 0.50
                    let arc = sin(j * .pi)
                    res.scaleX = CGFloat(-arc * 0.09)
                    res.scaleY = CGFloat(arc * 0.12)
                    res.offsetY = -CGFloat(arc) * minDim * 0.18
                    res.offsetX = CGFloat(arc) * minDim * 0.09
                    res.rotationDeg = -arc * 11.0
                } else {
                    let l = (p - 0.75) / 0.25
                    let squish = sin(l * .pi)
                    res.scaleX = CGFloat(squish * 0.12)
                    res.scaleY = CGFloat(-squish * 0.10)
                }
                res.isExcited = true
            }
        case .eatMunch:
            if elapsed < 1.8 {
                let p = elapsed / 1.8
                let munch = abs(sin(p * .pi * 6.0)) * (1.0 - p * 0.35)
                res.scaleX = CGFloat(munch * 0.07)
                res.scaleY = CGFloat(-munch * 0.06)
                res.offsetY = -CGFloat(munch) * minDim * 0.035
                res.rotationDeg = sin(p * .pi * 6.0) * 4.5
                res.isExcited = true
            }
        case .cozyNap:
            let slowNap = sin(time * 1.15)
            res.scaleX = 0.07 + CGFloat(slowNap) * 0.025
            res.scaleY = -0.09 - CGFloat(slowNap) * 0.020
            res.offsetY = minDim * 0.06
            res.rotationDeg = sin(time * 0.6) * 2.0
        case .happyTwirl:
            if elapsed < 1.3 {
                let p = elapsed / 1.3
                let hop = sin(p * .pi)
                let spinCos = cos(p * .pi * 2.0)
                res.flipScaleX = CGFloat(spinCos >= 0 ? max(0.18, spinCos) : min(-0.18, spinCos))
                res.offsetY = -CGFloat(hop) * minDim * 0.15
                res.scaleY = CGFloat(hop * 0.10)
                res.rotationDeg = sin(p * .pi * 2.0) * 10.0
                res.isExcited = true
            }
        case .curiousWaddle:
            let step = sin(time * 3.8)
            let hop = abs(sin(time * 3.8))
            res.offsetX = CGFloat(sin(time * 1.4)) * minDim * 0.065
            res.offsetY = -CGFloat(hop) * minDim * 0.035
            res.rotationDeg = step * 5.8
            res.scaleY = CGFloat(hop * 0.04)
            res.scaleX = CGFloat(-hop * 0.03)
        }
        return res
    }

    @ViewBuilder
    private func animatedArtStack(time: Double) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minDim = min(w, h)

            // 1. 軟糯麻糬呼吸節奏（體積守恆的 Q 彈起伏 ＋ 週期性好奇小歪頭）
            let breath = sin(time * (2.0 * .pi / 3.1))
            let headBobPhase = (time * 0.22).truncatingRemainder(dividingBy: 1.0)
            let cutePeriodicTilt = (headBobPhase > 0.72 && headBobPhase < 0.92)
                ? sin((headBobPhase - 0.72) / 0.20 * .pi) * 4.2
                : 0.0

            // 2. 互動動作曲線計算（依 actionTriggerDate 跑出流暢 60fps 動態）
            let act = computePlayfulTransform(time: time, minDim: minDim)
            let actOffsetX = act.offsetX
            let actOffsetY = act.offsetY
            let isExcitedNow = act.isExcited

            let breathScaleY: CGFloat = 1.0 + CGFloat(breath) * 0.024 + brushRuffleAmount * 0.024 + tapBounceScale * 0.09 + act.scaleY
            let breathScaleX: CGFloat = (1.0 - CGFloat(breath) * 0.014 + brushRuffleAmount * 0.015 - tapBounceScale * 0.06 + act.scaleX) * act.flipScaleX

            // Subtle IK finger tracking lean & tilt (+-7.5 deg)
            let ikX = fingerFocusNormalized?.x ?? 0.0
            let ikY = fingerFocusNormalized?.y ?? 0.0
            let tiltDegrees = Double(ikX) * 7.5 + sin(time * 0.95) * 1.2 + cutePeriodicTilt + act.rotationDeg
            let leanOffsetX = ikX * minDim * 0.025 + actOffsetX
            let leanOffsetY = ikY * minDim * 0.014 + (pose == .resting ? minDim * 0.035 : 0) - tapBounceScale * minDim * 0.05 + actOffsetY

            let showRosyBlush = isHappySquint || brushRuffleAmount > 0.08 || isExcitedNow || playfulAction == .cozyNap
            let shadowShrink = max(0.70, 1.0 + (actOffsetY / max(1, minDim)) * 1.3)

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

                // L1_Shadow: Grounded multi-layer watercolor puddle shadow under paws (shrinks smoothly when hopping!)
                Ellipse()
                    .fill(AppTheme.deepPineInk.opacity(0.17))
                    .frame(width: minDim * 0.58 * shadowShrink, height: minDim * 0.12 * shadowShrink)
                    .blur(radius: minDim * 0.020)
                    .offset(x: actOffsetX * 0.7, y: minDim * 0.40 + (pose == .resting ? minDim * 0.02 : 0))

                Ellipse()
                    .fill(AppTheme.deepPineInk.opacity(0.10))
                    .frame(width: minDim * 0.42 * shadowShrink, height: minDim * 0.07 * shadowShrink)
                    .offset(x: actOffsetX * 0.7, y: minDim * 0.40 + (pose == .resting ? minDim * 0.02 : 0))

                // Hand-painted 1024x1024 transparent gouache & pencil illustration + synced mythical anatomy & wardrobe layer
                ZStack {
                    // 《貓與龍》奇幻物種背後羽翼／雲絮靈光層（位在角色身體後方）
                    if pet.kind.isMagical {
                        MythicalSpeciesBackLayerCanvas(
                            pet: pet,
                            neckAnchor: calibratedNeckAnchor,
                            time: isStaticSnapshot ? 0.6 : time
                        )
                    }

                    if let uiImage = UIImage(named: assetName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Circle()
                            .fill(Color(hex: pet.primaryCoatHex))
                            .frame(width: minDim * 0.5, height: minDim * 0.5)
                    }

                    // 《貓與龍》奇幻物種前層（惡魔小角、森靈鹿角、爐火龍息火星、星塵月光）
                    if pet.kind.isMagical {
                        MythicalSpeciesFrontLayerCanvas(
                            pet: pet,
                            neckAnchor: calibratedNeckAnchor,
                            time: isStaticSnapshot ? 0.6 : time
                        )
                    }

                    // 可愛水彩蜜桃紅暈雙頰（開心、被戳肚皮、梳毛、吃點心或午睡時綻放！）
                    if showRosyBlush {
                        let cheekY = h * (calibratedNeckAnchor.v - 0.105)
                        let cheekL = w * (calibratedNeckAnchor.u - 0.08)
                        let cheekR = w * (calibratedNeckAnchor.u + 0.06)
                        Ellipse()
                            .fill(Color(hex: "#F28D80").opacity(0.45))
                            .frame(width: minDim * 0.095, height: minDim * 0.055)
                            .blur(radius: minDim * 0.012)
                            .position(x: cheekL, y: cheekY)
                            .allowsHitTesting(false)
                        Ellipse()
                            .fill(Color(hex: "#F28D80").opacity(0.45))
                            .frame(width: minDim * 0.095, height: minDim * 0.055)
                            .blur(radius: minDim * 0.012)
                            .position(x: cheekR, y: cheekY)
                            .allowsHitTesting(false)
                    }

                    // 蓋被被午睡時，披上一條柔和馬卡龍拼布小棉被
                    if playfulAction == .cozyNap {
                        RoundedRectangle(cornerRadius: minDim * 0.09, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#A8C6D8").opacity(0.92), Color(hex: "#84A7BE").opacity(0.94)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: minDim * 0.08, style: .continuous)
                                    .stroke(Color(hex: "#FFF9EE").opacity(0.75), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                                    .padding(4)
                            )
                            .frame(width: minDim * 0.56, height: minDim * 0.24)
                            .position(x: w * 0.50, y: h * 0.72)
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

                // Happy purr / brushing / Mentorship / Cozy Nap watercolor particle motes (hearts, stars, sleepy Zzz)
                if showRosyBlush || mentorshipParticle != nil || pose == .resting {
                    StorybookParticleMotesCanvas(
                        time: isStaticSnapshot ? 0.8 : time,
                        habit: mentorshipParticle,
                        isHappy: showRosyBlush && playfulAction != .cozyNap,
                        isResting: (pose == .resting && !isHappySquint && brushRuffleAmount <= 0.05 && !isExcitedNow) || playfulAction == .cozyNap
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
                // 可愛夢幻飄浮的「z Z z」午睡泡泡
                let letters = ["z", "Z", "z"]
                for idx in 0..<3 {
                    let phase = (time * 0.34 + Double(idx) * 0.33).truncatingRemainder(dividingBy: 1.0)
                    let px = cx + minDim * 0.18 + CGFloat(sin(time * 1.4 + Double(idx))) * minDim * 0.035 + CGFloat(idx) * minDim * 0.025
                    let py = cy - CGFloat(phase) * minDim * 0.28
                    let alpha = sin(phase * .pi) * 0.85
                    ctx.draw(
                        Text(letters[idx])
                            .font(.system(size: minDim * (0.065 + CGFloat(idx) * 0.015), weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#6B86A8").opacity(alpha)),
                        at: CGPoint(x: px, y: py)
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

// MARK: - 《貓與龍》風格奇幻物種活體光影與解剖特徵層
private struct MythicalSpeciesBackLayerCanvas: View {
    let pet: PetSpec
    let neckAnchor: (u: CGFloat, v: CGFloat, width: CGFloat)
    let time: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let minDim = min(w, h)
            let ink = Color(hex: "#231E26").opacity(0.75)

            switch pet.kind {
            case .demonCat:
                // 杜松（黑曜惡魔貓）：身後微微拍動的迷你惡魔蝠翼 ＋ 俏皮黑桃尖尾
                let flap = CGFloat(sin(time * 2.6)) * minDim * 0.020
                let shoulderX = w * (neckAnchor.u + 0.18)
                let shoulderY = h * (neckAnchor.v + 0.06)

                var wing = Path()
                wing.move(to: CGPoint(x: shoulderX, y: shoulderY))
                wing.addQuadCurve(
                    to: CGPoint(x: shoulderX + minDim * 0.24, y: shoulderY - minDim * 0.17 - flap),
                    control: CGPoint(x: shoulderX + minDim * 0.12, y: shoulderY - minDim * 0.18)
                )
                wing.addQuadCurve(
                    to: CGPoint(x: shoulderX + minDim * 0.19, y: shoulderY - minDim * 0.01 - flap * 0.4),
                    control: CGPoint(x: shoulderX + minDim * 0.18, y: shoulderY - minDim * 0.09)
                )
                wing.addQuadCurve(
                    to: CGPoint(x: shoulderX + minDim * 0.09, y: shoulderY + minDim * 0.04),
                    control: CGPoint(x: shoulderX + minDim * 0.12, y: shoulderY - minDim * 0.02)
                )
                wing.closeSubpath()
                ctx.fill(
                    wing,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "#32263A"), Color(hex: "#6B2E48")]),
                        startPoint: CGPoint(x: shoulderX, y: shoulderY - minDim * 0.16),
                        endPoint: CGPoint(x: shoulderX + minDim * 0.20, y: shoulderY + minDim * 0.04)
                    )
                )
                ctx.stroke(wing, with: .color(ink), lineWidth: minDim * 0.008)

                // 黑桃小惡魔尾尖（輕輕擺動）
                let tailBaseX = w * 0.72
                let tailBaseY = h * 0.56
                let wag = CGFloat(sin(time * 2.2)) * minDim * 0.025
                var tailLine = Path()
                tailLine.move(to: CGPoint(x: tailBaseX, y: tailBaseY))
                tailLine.addCurve(
                    to: CGPoint(x: tailBaseX + minDim * 0.12 + wag, y: tailBaseY - minDim * 0.18),
                    control1: CGPoint(x: tailBaseX + minDim * 0.12, y: tailBaseY - minDim * 0.04),
                    control2: CGPoint(x: tailBaseX + minDim * 0.04 + wag, y: tailBaseY - minDim * 0.14)
                )
                ctx.stroke(tailLine, with: .color(Color(hex: "#26232D")), style: StrokeStyle(lineWidth: minDim * 0.022, lineCap: .round))

                // 桃心黑桃尾尖
                let tipX = tailBaseX + minDim * 0.12 + wag
                let tipY = tailBaseY - minDim * 0.19
                let s = minDim * 0.040
                var spade = Path()
                spade.move(to: CGPoint(x: tipX, y: tipY - s))
                spade.addQuadCurve(to: CGPoint(x: tipX + s * 0.85, y: tipY + s * 0.25), control: CGPoint(x: tipX + s * 0.9, y: tipY - s * 0.3))
                spade.addLine(to: CGPoint(x: tipX, y: tipY + s * 0.65))
                spade.addLine(to: CGPoint(x: tipX - s * 0.85, y: tipY + s * 0.25))
                spade.addQuadCurve(to: CGPoint(x: tipX, y: tipY - s), control: CGPoint(x: tipX - s * 0.9, y: tipY - s * 0.3))
                spade.closeSubpath()
                ctx.fill(spade, with: .color(Color(hex: "#9E3B58")))
                ctx.stroke(spade, with: .color(ink), lineWidth: minDim * 0.007)

            case .spiritHound:
                // 梅子（銀月星靈犬）：背後浮動的柔白雲霞仙帶與淡金星環
                let drift = CGFloat(sin(time * 1.3)) * minDim * 0.018
                var cloudRibbon = Path()
                cloudRibbon.move(to: CGPoint(x: w * 0.16, y: h * 0.44 + drift))
                cloudRibbon.addCurve(
                    to: CGPoint(x: w * 0.84, y: h * 0.38 - drift),
                    control1: CGPoint(x: w * 0.36, y: h * 0.18 - drift),
                    control2: CGPoint(x: w * 0.66, y: h * 0.20 + drift)
                )
                ctx.stroke(
                    cloudRibbon,
                    with: .linearGradient(
                        Gradient(colors: [.clear, Color(hex: "#FFFDF6").opacity(0.65), Color(hex: "#DDE8F0").opacity(0.55), .clear]),
                        startPoint: CGPoint(x: w * 0.16, y: h * 0.4),
                        endPoint: CGPoint(x: w * 0.84, y: h * 0.4)
                    ),
                    style: StrokeStyle(lineWidth: minDim * 0.045, lineCap: .round)
                )

            case .dragonCat:
                // 餘燼（赤瓦龍貓）：背後散發的溫暖爐火龍鱗柔光
                let pulse = 0.22 + sin(time * 2.0) * 0.07
                ctx.fill(
                    Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.22, width: w * 0.56, height: h * 0.52)),
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: "#F29D4B").opacity(pulse), Color(hex: "#C85A32").opacity(pulse * 0.35), .clear]),
                        center: CGPoint(x: w * 0.52, y: h * 0.46),
                        startRadius: minDim * 0.06,
                        endRadius: minDim * 0.34
                    )
                )

            default:
                break
            }
        }
    }
}

private struct MythicalSpeciesFrontLayerCanvas: View {
    let pet: PetSpec
    let neckAnchor: (u: CGFloat, v: CGFloat, width: CGFloat)
    let time: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let minDim = min(w, h)
            let ink = Color(hex: "#251E28").opacity(0.80)

            switch pet.kind {
            case .demonCat:
                // 頭頂成對彎曲黑曜緋紅小惡魔角
                let headX = w * (neckAnchor.u - 0.01)
                let headY = h * (neckAnchor.v - 0.175)
                drawCurvedHorn(in: &ctx, base: CGPoint(x: headX - minDim * 0.055, y: headY), dir: -1, scale: minDim, topColor: Color(hex: "#B84A62"), baseColor: Color(hex: "#2B2230"), ink: ink)
                drawCurvedHorn(in: &ctx, base: CGPoint(x: headX + minDim * 0.045, y: headY - minDim * 0.005), dir: 1, scale: minDim, topColor: Color(hex: "#B84A62"), baseColor: Color(hex: "#2B2230"), ink: ink)

                // 飄浮的紫紅魔法小火星
                for idx in 0..<3 {
                    let phase = (time * 0.55 + Double(idx) * 0.33).truncatingRemainder(dividingBy: 1.0)
                    let px = w * (0.28 + CGFloat(idx) * 0.22) + CGFloat(sin(time * 2.0 + Double(idx))) * minDim * 0.02
                    let py = h * 0.42 - CGFloat(phase) * minDim * 0.24
                    let r = minDim * 0.011
                    ctx.fill(Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)), with: .color(Color(hex: "#D66586").opacity(sin(phase * .pi) * 0.85)))
                }

            case .dragonCat:
                // 餘燼（赤瓦龍貓）：上升的爐火橘金小火星與可愛小煙圈
                for idx in 0..<4 {
                    let phase = (time * 0.52 + Double(idx) * 0.25).truncatingRemainder(dividingBy: 1.0)
                    let px = w * (0.25 + CGFloat(idx) * 0.16) + CGFloat(sin(time * 1.8 + Double(idx) * 1.3)) * minDim * 0.025
                    let py = h * 0.44 - CGFloat(phase) * minDim * 0.28
                    let r = minDim * (0.013 - CGFloat(phase) * 0.004)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                        with: .color(Color(hex: idx % 2 == 0 ? "#FFD275" : "#E86C3A").opacity(sin(phase * .pi) * 0.88))
                    )
                }

            case .batCat:
                // 摺翼（暮光夜魔貓）：星塵月光微芒
                for idx in 0..<4 {
                    let phase = (time * 0.45 + Double(idx) * 0.25).truncatingRemainder(dividingBy: 1.0)
                    let px = w * (0.24 + CGFloat(idx) * 0.18)
                    let py = h * 0.38 - CGFloat(phase) * minDim * 0.20
                    let s = minDim * 0.018 * CGFloat(sin(phase * .pi))
                    var star = Path()
                    star.move(to: CGPoint(x: px, y: py - s))
                    star.addLine(to: CGPoint(x: px + s * 0.35, y: py - s * 0.35))
                    star.addLine(to: CGPoint(x: px + s, y: py))
                    star.addLine(to: CGPoint(x: px + s * 0.35, y: py + s * 0.35))
                    star.addLine(to: CGPoint(x: px, y: py + s))
                    star.addLine(to: CGPoint(x: px - s * 0.35, y: py + s * 0.35))
                    star.addLine(to: CGPoint(x: px - s, y: py))
                    star.addLine(to: CGPoint(x: px - s * 0.35, y: py - s * 0.35))
                    star.closeSubpath()
                    ctx.fill(star, with: .color(Color(hex: "#EDE2FF").opacity(0.90)))
                }

            case .impHound:
                // 鈕扣（墨玉小魔犬）：圓潤小魔角 ＋ 肩畔漂浮的溫柔藍紫小鬼火
                let headX = w * (neckAnchor.u - 0.01)
                let headY = h * (neckAnchor.v - 0.17)
                drawCurvedHorn(in: &ctx, base: CGPoint(x: headX - minDim * 0.06, y: headY), dir: -1, scale: minDim * 0.82, topColor: Color(hex: "#D49B6A"), baseColor: Color(hex: "#322F3D"), ink: ink)
                drawCurvedHorn(in: &ctx, base: CGPoint(x: headX + minDim * 0.05, y: headY), dir: 1, scale: minDim * 0.82, topColor: Color(hex: "#D49B6A"), baseColor: Color(hex: "#322F3D"), ink: ink)

                let wispX = w * 0.72 + CGFloat(cos(time * 1.6)) * minDim * 0.02
                let wispY = h * 0.32 + CGFloat(sin(time * 2.2)) * minDim * 0.03
                let glowR = minDim * 0.065
                ctx.fill(
                    Path(ellipseIn: CGRect(x: wispX - glowR, y: wispY - glowR, width: glowR * 2, height: glowR * 2)),
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: "#C5B4FF").opacity(0.65), Color(hex: "#7358C7").opacity(0.22), .clear]),
                        center: CGPoint(x: wispX, y: wispY),
                        startRadius: 2,
                        endRadius: glowR
                    )
                )
                ctx.fill(Path(ellipseIn: CGRect(x: wispX - minDim * 0.016, y: wispY - minDim * 0.018, width: minDim * 0.032, height: minDim * 0.036)), with: .color(Color(hex: "#F2EDFF")))

            case .spiritHound:
                // 梅子（銀月星靈犬）：環繞的淡金小星光
                for idx in 0..<3 {
                    let angle = time * 0.9 + Double(idx) * (2.0 * .pi / 3.0)
                    let px = w * 0.50 + CGFloat(cos(angle)) * minDim * 0.30
                    let py = h * 0.28 + CGFloat(sin(angle)) * minDim * 0.07
                    let r = minDim * 0.013
                    ctx.fill(Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)), with: .color(Color(hex: "#F7DF9C").opacity(0.85)))
                }

            case .marshHound:
                // 蘆葦（鹿角森靈犬）：頭頂嫩綠新葉小鹿角 ＋ 林間螢火光點
                let headX = w * (neckAnchor.u + 0.01)
                let headY = h * (neckAnchor.v - 0.165)
                drawBotanicalAntler(in: &ctx, base: CGPoint(x: headX - minDim * 0.045, y: headY), dir: -1, scale: minDim, ink: ink)
                drawBotanicalAntler(in: &ctx, base: CGPoint(x: headX + minDim * 0.045, y: headY), dir: 1, scale: minDim, ink: ink)

                for idx in 0..<3 {
                    let phase = (time * 0.5 + Double(idx) * 0.33).truncatingRemainder(dividingBy: 1.0)
                    let fx = w * (0.30 + CGFloat(idx) * 0.22) + CGFloat(sin(time * 1.4 + Double(idx))) * minDim * 0.03
                    let fy = h * 0.32 - CGFloat(phase) * minDim * 0.16
                    let r = minDim * 0.012
                    ctx.fill(Path(ellipseIn: CGRect(x: fx - r, y: fy - r, width: r * 2, height: r * 2)), with: .color(Color(hex: "#DDF08A").opacity(sin(phase * .pi) * 0.90)))
                }

            default:
                break
            }
        }
    }

    private func drawCurvedHorn(in ctx: inout GraphicsContext, base: CGPoint, dir: CGFloat, scale: CGFloat, topColor: Color, baseColor: Color, ink: Color) {
        var horn = Path()
        horn.move(to: CGPoint(x: base.x - dir * scale * 0.018, y: base.y + scale * 0.008))
        horn.addQuadCurve(
            to: CGPoint(x: base.x + dir * scale * 0.048, y: base.y - scale * 0.082),
            control: CGPoint(x: base.x + dir * scale * 0.042, y: base.y - scale * 0.020)
        )
        horn.addQuadCurve(
            to: CGPoint(x: base.x + dir * scale * 0.018, y: base.y + scale * 0.008),
            control: CGPoint(x: base.x + dir * scale * 0.012, y: base.y - scale * 0.035)
        )
        horn.closeSubpath()
        ctx.fill(
            horn,
            with: .linearGradient(
                Gradient(colors: [topColor, baseColor]),
                startPoint: CGPoint(x: base.x, y: base.y - scale * 0.08),
                endPoint: CGPoint(x: base.x, y: base.y + scale * 0.01)
            )
        )
        ctx.stroke(horn, with: .color(ink), lineWidth: scale * 0.008)
    }

    private func drawBotanicalAntler(in ctx: inout GraphicsContext, base: CGPoint, dir: CGFloat, scale: CGFloat, ink: Color) {
        var stem = Path()
        stem.move(to: base)
        stem.addQuadCurve(
            to: CGPoint(x: base.x + dir * scale * 0.055, y: base.y - scale * 0.095),
            control: CGPoint(x: base.x + dir * scale * 0.015, y: base.y - scale * 0.055)
        )
        var branch = Path()
        branch.move(to: CGPoint(x: base.x + dir * scale * 0.025, y: base.y - scale * 0.048))
        branch.addLine(to: CGPoint(x: base.x + dir * scale * 0.072, y: base.y - scale * 0.058))
        ctx.stroke(stem, with: .color(Color(hex: "#7D5836")), style: StrokeStyle(lineWidth: scale * 0.014, lineCap: .round))
        ctx.stroke(branch, with: .color(Color(hex: "#7D5836")), style: StrokeStyle(lineWidth: scale * 0.010, lineCap: .round))
        // Tiny sprouting spring leaf on antler
        let lx = base.x + dir * scale * 0.068
        let ly = base.y - scale * 0.068
        let leaf = Path(ellipseIn: CGRect(x: lx - scale * 0.018, y: ly - scale * 0.010, width: scale * 0.036, height: scale * 0.020))
        ctx.fill(leaf, with: .color(Color(hex: "#6AA36F")))
        ctx.stroke(leaf, with: .color(ink), lineWidth: scale * 0.005)
    }
}
