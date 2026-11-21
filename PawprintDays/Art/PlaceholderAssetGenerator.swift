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

    /// Exact pixel-calibrated Live2D anatomical rig for each 1024x1024 hand-painted pet portrait.
    fileprivate struct PetAnatomicalRig {
        let headCenter: CGPoint
        let headRadius: CGFloat
        let eyeL: CGPoint
        let eyeR: CGPoint
        let eyeRadius: CGFloat
        let eyelidHex: String
        let mouth: CGPoint
        let tailCenter: CGPoint
        let tailRadius: CGFloat
        let wingCenter: CGPoint?
        let pawL: CGPoint
        let pawR: CGPoint
    }

    private var anatomicalRig: PetAnatomicalRig {
        switch pet.id {
        case "pet.01": // 芝麻 · 街角虎斑貓
            return PetAnatomicalRig(
                headCenter: CGPoint(x: 0.42, y: 0.23), headRadius: 0.16,
                eyeL: CGPoint(x: 0.335, y: 0.240), eyeR: CGPoint(x: 0.435, y: 0.245), eyeRadius: 0.030,
                eyelidHex: "#8D959C", mouth: CGPoint(x: 0.375, y: 0.315),
                tailCenter: CGPoint(x: 0.26, y: 0.80), tailRadius: 0.19,
                wingCenter: nil,
                pawL: CGPoint(x: 0.41, y: 0.81), pawR: CGPoint(x: 0.47, y: 0.82)
            )
        case "pet.02": // 杜松 · 黑曜惡魔貓
            return PetAnatomicalRig(
                headCenter: CGPoint(x: 0.34, y: 0.23), headRadius: 0.15,
                eyeL: CGPoint(x: 0.255, y: 0.250), eyeR: CGPoint(x: 0.345, y: 0.255), eyeRadius: 0.029,
                eyelidHex: "#242931", mouth: CGPoint(x: 0.285, y: 0.320),
                tailCenter: CGPoint(x: 0.74, y: 0.54), tailRadius: 0.24,
                wingCenter: CGPoint(x: 0.58, y: 0.42),
                pawL: CGPoint(x: 0.32, y: 0.88), pawR: CGPoint(x: 0.41, y: 0.89)
            )
        case "pet.03": // 餘燼 · 赤瓦龍貓
            return PetAnatomicalRig(
                headCenter: CGPoint(x: 0.34, y: 0.22), headRadius: 0.16,
                eyeL: CGPoint(x: 0.245, y: 0.235), eyeR: CGPoint(x: 0.335, y: 0.240), eyeRadius: 0.030,
                eyelidHex: "#7E6B60", mouth: CGPoint(x: 0.275, y: 0.310),
                tailCenter: CGPoint(x: 0.68, y: 0.78), tailRadius: 0.20,
                wingCenter: CGPoint(x: 0.64, y: 0.41),
                pawL: CGPoint(x: 0.34, y: 0.84), pawR: CGPoint(x: 0.41, y: 0.86)
            )
        case "pet.04": // 摺翼 · 暮光夜魔貓
            return PetAnatomicalRig(
                headCenter: CGPoint(x: 0.36, y: 0.23), headRadius: 0.16,
                eyeL: CGPoint(x: 0.265, y: 0.250), eyeR: CGPoint(x: 0.360, y: 0.260), eyeRadius: 0.031,
                eyelidHex: "#5D5468", mouth: CGPoint(x: 0.295, y: 0.330),
                tailCenter: CGPoint(x: 0.34, y: 0.78), tailRadius: 0.20,
                wingCenter: CGPoint(x: 0.65, y: 0.52),
                pawL: CGPoint(x: 0.36, y: 0.80), pawR: CGPoint(x: 0.44, y: 0.82)
            )
        case "pet.05": // 味噌 · 巷口暖金犬
            return PetAnatomicalRig(
                headCenter: CGPoint(x: 0.58, y: 0.25), headRadius: 0.16,
                eyeL: CGPoint(x: 0.515, y: 0.225), eyeR: CGPoint(x: 0.610, y: 0.235), eyeRadius: 0.025,
                eyelidHex: "#DAA769", mouth: CGPoint(x: 0.555, y: 0.330),
                tailCenter: CGPoint(x: 0.29, y: 0.81), tailRadius: 0.15,
                wingCenter: nil,
                pawL: CGPoint(x: 0.62, y: 0.89), pawR: CGPoint(x: 0.76, y: 0.87)
            )
        case "pet.06": // 鈕扣 · 墨玉小魔犬
            return PetAnatomicalRig(
                headCenter: CGPoint(x: 0.39, y: 0.24), headRadius: 0.18,
                eyeL: CGPoint(x: 0.315, y: 0.205), eyeR: CGPoint(x: 0.425, y: 0.205), eyeRadius: 0.027,
                eyelidHex: "#272D34", mouth: CGPoint(x: 0.340, y: 0.330),
                tailCenter: CGPoint(x: 0.74, y: 0.78), tailRadius: 0.14,
                wingCenter: nil,
                pawL: CGPoint(x: 0.32, y: 0.86), pawR: CGPoint(x: 0.53, y: 0.88)
            )
        case "pet.07": // 梅子 · 銀月星靈犬
            return PetAnatomicalRig(
                headCenter: CGPoint(x: 0.42, y: 0.22), headRadius: 0.17,
                eyeL: CGPoint(x: 0.335, y: 0.200), eyeR: CGPoint(x: 0.415, y: 0.200), eyeRadius: 0.024,
                eyelidHex: "#C5BEB4", mouth: CGPoint(x: 0.345, y: 0.310),
                tailCenter: CGPoint(x: 0.68, y: 0.80), tailRadius: 0.15,
                wingCenter: nil,
                pawL: CGPoint(x: 0.32, y: 0.86), pawR: CGPoint(x: 0.48, y: 0.89)
            )
        default: // pet.08 蘆葦 · 鹿角森靈犬
            return PetAnatomicalRig(
                headCenter: CGPoint(x: 0.56, y: 0.21), headRadius: 0.15,
                eyeL: CGPoint(x: 0.505, y: 0.165), eyeR: CGPoint(x: 0.575, y: 0.165), eyeRadius: 0.023,
                eyelidHex: "#C47F3E", mouth: CGPoint(x: 0.515, y: 0.245),
                tailCenter: CGPoint(x: 0.36, y: 0.87), tailRadius: 0.18,
                wingCenter: nil,
                pawL: CGPoint(x: 0.61, y: 0.87), pawR: CGPoint(x: 0.73, y: 0.86)
            )
        }
    }

    fileprivate enum Live2DEyeExpression {
        case open(blinkProgress: CGFloat)
        case happyCrescent
        case sleepyClosed
    }

    fileprivate struct Live2DBoneState {
        var headTiltRad: Float = 0
        var headShiftX: Float = 0
        var headShiftY: Float = 0
        var earTwitch: Float = 0
        var chestBreath: Float = 0
        var tailWagPhase: Float = 0
        var tailWagAmp: Float = 0
        var wingFlapAmp: Float = 0
        var pawLiftL: Float = 0
        var pawLiftR: Float = 0
        var jumpOffsetX: CGFloat = 0
        var jumpOffsetY: CGFloat = 0
        var eyeExpression: Live2DEyeExpression = .open(blinkProgress: 0)
        var mouthOpen: CGFloat = 0
        var showDragonPuff: Bool = false
        var showBlush: Bool = false
        var isExcited: Bool = false
    }

    private func computeLive2DBoneState(time: Double, minDim: CGFloat) -> Live2DBoneState {
        var b = Live2DBoneState()
        let elapsed = isStaticSnapshot ? 99.0 : max(0, Date().timeIntervalSince(actionTriggerDate))
        let ikX = Float(fingerFocusNormalized?.x ?? 0.0)
        let ikY = Float(fingerFocusNormalized?.y ?? 0.0)

        // Base natural alive idle: localized ribcage breathing + gentle tail swish + periodic curious head tilt + natural double-blink
        let breath = Float(sin(time * (2.0 * .pi / 3.2)))
        b.chestBreath = breath * 0.032 + Float(brushRuffleAmount) * 0.038

        // Periodic curious ear twitch every ~3.8s
        let earCycle = (time * 0.27 + Double(pet.id.hashValue & 7) * 0.13).truncatingRemainder(dividingBy: 1.0)
        if earCycle > 0.86 && earCycle < 0.96 {
            let ep = (earCycle - 0.86) / 0.10
            b.earTwitch = Float(sin(ep * .pi * 2.0)) * 0.034
        }

        // Periodic curious head tilt + live 2.5D finger gaze tracking
        let headCycle = (time * 0.18).truncatingRemainder(dividingBy: 1.0)
        let idleHeadTilt = (headCycle > 0.65 && headCycle < 0.90)
            ? Float(sin((headCycle - 0.65) / 0.25 * .pi)) * 0.13
            : Float(sin(time * 0.85)) * 0.035
        b.headTiltRad = idleHeadTilt + ikX * 0.20
        b.headShiftX = ikX * 0.026
        b.headShiftY = ikY * 0.018 + breath * 0.008

        // Continuous supple tail swishing + gentle wing breathing for winged species
        b.tailWagPhase = Float(time * 3.1)
        b.tailWagAmp = 0.026
        if anatomicalRig.wingCenter != nil {
            b.wingFlapAmp = Float(sin(time * 2.1)) * 0.14
        }

        // Natural blinking every ~3.4s (with quick crisp eyelid sweep)
        let blinkCycle = (time * 0.30 + Double(pet.id.hashValue & 3) * 0.21).truncatingRemainder(dividingBy: 1.0)
        let naturalBlink: CGFloat = (blinkCycle > 0.92)
            ? CGFloat(sin((blinkCycle - 0.92) / 0.08 * .pi))
            : 0.0
        b.eyeExpression = .open(blinkProgress: naturalBlink)

        // Expressive multi-bone interactive animations (NO whole-image flat card squeezing/flipping!)
        switch playfulAction {
        case .idle:
            if pose == .resting {
                b.tailWagAmp = 0.012
                b.headShiftY += 0.018
                b.eyeExpression = .sleepyClosed
            }

        case .bellyBoop:
            if elapsed < 1.35 {
                let p = elapsed / 1.35
                let env = Float(sin(p * .pi))
                // Excited head tilt + rapid ear perk + happy tail wag + alternating front paw knead ("踏踏")!
                b.headTiltRad += Float(sin(p * .pi * 3.0)) * 0.22 * env
                b.headShiftY -= 0.025 * env
                b.earTwitch = Float(sin(p * .pi * 5.0)) * 0.055
                b.tailWagPhase = Float(time * 10.5)
                b.tailWagAmp = 0.068 * env
                b.wingFlapAmp = Float(sin(p * .pi * 4.0)) * 0.36
                b.pawLiftL = max(0, Float(sin(p * .pi * 4.0))) * 0.055
                b.pawLiftR = max(0, Float(-sin(p * .pi * 4.0))) * 0.055
                b.chestBreath += 0.045 * env
                b.eyeExpression = .happyCrescent
                b.mouthOpen = CGFloat(0.65 * env)
                b.showDragonPuff = (pet.kind == .dragonCat && p > 0.15 && p < 0.78)
                b.showBlush = true
                b.isExcited = true
            }

        case .pounceHop:
            if elapsed < 1.45 {
                let p = elapsed / 1.45
                if p < 0.28 {
                    // Crouch: head ducks forward, ears flatten, tail twitches rapidly in anticipation!
                    let c = Float(p / 0.28)
                    b.headShiftY += 0.045 * c
                    b.headShiftX -= 0.022 * c
                    b.earTwitch = -0.045 * c
                    b.tailWagPhase = Float(time * 14.0)
                    b.tailWagAmp = 0.052
                    b.chestBreath -= 0.03 * c
                } else if p < 0.78 {
                    // Leap: both front paws reach up/forward, wings unfurl wide, happy excited face!
                    let j = (p - 0.28) / 0.50
                    let arc = Float(sin(j * .pi))
                    b.jumpOffsetY = -CGFloat(arc) * minDim * 0.13
                    b.jumpOffsetX = CGFloat(arc) * minDim * 0.055
                    b.headShiftY -= 0.035 * arc
                    b.headTiltRad -= 0.18 * arc
                    b.pawLiftL = 0.085 * arc
                    b.pawLiftR = 0.075 * arc
                    b.wingFlapAmp = 0.45 * arc
                    b.tailWagPhase = Float(time * 11.0)
                    b.tailWagAmp = 0.070
                    b.mouthOpen = CGFloat(0.75 * arc)
                } else {
                    // Soft landing with happy paw pat & tail swish
                    let l = Float((p - 0.78) / 0.22)
                    b.headShiftY += Float(sin(l * .pi)) * 0.025
                    b.eyeExpression = .happyCrescent
                }
                b.showBlush = true
                b.isExcited = true
            }

        case .eatMunch:
            if elapsed < 2.0 {
                let p = elapsed / 2.0
                // Rhythmic chewing head nods + real opening/closing mouth + happy tail wag!
                let chewWave = sin(p * .pi * 10.0)
                let munchAmp = CGFloat(max(0.0, chewWave)) * CGFloat(1.0 - p * 0.25)
                b.headShiftY += Float(munchAmp) * 0.030
                b.headTiltRad += Float(sin(p * .pi * 5.0)) * 0.10
                b.earTwitch = Float(chewWave) * 0.025
                b.tailWagPhase = Float(time * 8.5)
                b.tailWagAmp = 0.055
                b.wingFlapAmp = Float(sin(p * .pi * 6.0)) * 0.22
                b.pawLiftL = max(0, Float(sin(p * .pi * 5.0))) * 0.028
                b.eyeExpression = .happyCrescent
                b.mouthOpen = munchAmp
                b.showBlush = true
                b.isExcited = true
            }

        case .cozyNap:
            // Peaceful sleeping: head gently droops, slow deep ribcage breathing, lazy tail curl, closed eyes!
            let slowBreath = Float(sin(time * 1.1))
            b.chestBreath = slowBreath * 0.040
            b.headShiftY += 0.038 + slowBreath * 0.008
            b.headTiltRad = 0.14 + slowBreath * 0.03
            b.earTwitch = -0.028
            b.tailWagPhase = Float(time * 1.1)
            b.tailWagAmp = 0.012
            b.eyeExpression = .sleepyClosed
            b.showBlush = true

        case .happyTwirl:
            // True Joyful Kneading Dance & Excited Tail-Wag (NO flat 2D card flip!)
            if elapsed < 1.8 {
                let p = elapsed / 1.8
                let env = Float(sin(p * .pi))
                let beat = Float(sin(p * .pi * 6.0))
                b.pawLiftL = max(0, beat) * 0.078 * env
                b.pawLiftR = max(0, -beat) * 0.078 * env
                b.headTiltRad = beat * 0.24 * env
                b.headShiftX = beat * 0.028 * env
                b.headShiftY = -abs(beat) * 0.022 * env
                b.earTwitch = beat * 0.052 * env
                b.tailWagPhase = Float(time * 13.0)
                b.tailWagAmp = 0.075 * env
                b.wingFlapAmp = Float(sin(p * .pi * 8.0)) * 0.42 * env
                b.jumpOffsetY = -CGFloat(abs(beat)) * minDim * 0.045 * CGFloat(env)
                b.eyeExpression = .happyCrescent
                b.mouthOpen = CGFloat(0.75 * env)
                b.showDragonPuff = (pet.kind == .dragonCat && p > 0.20 && p < 0.80)
                b.showBlush = true
                b.isExcited = true
            }

        case .curiousWaddle:
            // Living autonomous trotting/kneading + curious looking around + tail swish!
            let step = Float(sin(time * 4.4))
            b.pawLiftL = max(0, step) * 0.050
            b.pawLiftR = max(0, -step) * 0.050
            b.headTiltRad += step * 0.14
            b.headShiftX += Float(sin(time * 1.5)) * 0.024
            b.earTwitch = step * 0.026
            b.tailWagPhase = Float(time * 6.2)
            b.tailWagAmp = 0.048
            b.wingFlapAmp = Float(sin(time * 4.4)) * 0.20
            b.jumpOffsetX = CGFloat(sin(time * 1.3)) * minDim * 0.040
            b.jumpOffsetY = -CGFloat(abs(step)) * minDim * 0.018
        }

        if isHappySquint || brushRuffleAmount > 0.08 {
            b.eyeExpression = .happyCrescent
            b.tailWagAmp = max(b.tailWagAmp, 0.052)
            b.tailWagPhase = Float(time * 8.0)
            b.showBlush = true
        }
        if tapBounceScale > 0.1 {
            b.earTwitch = 0.045
            b.headShiftY -= 0.022
            b.eyeExpression = .happyCrescent
            b.showBlush = true
        }

        return b
    }

    @ViewBuilder
    private func animatedArtStack(time: Double) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minDim = min(w, h)
            let rig = anatomicalRig
            let bones = computeLive2DBoneState(time: time, minDim: minDim)
            let shadowShrink = max(0.74, 1.0 + (bones.jumpOffsetY / max(1, minDim)) * 1.3)

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
                    .frame(width: minDim * 0.58 * shadowShrink, height: minDim * 0.12 * shadowShrink)
                    .blur(radius: minDim * 0.020)
                    .offset(x: bones.jumpOffsetX * 0.7, y: minDim * 0.40 + (pose == .resting ? minDim * 0.02 : 0))

                Ellipse()
                    .fill(AppTheme.deepPineInk.opacity(0.10))
                    .frame(width: minDim * 0.42 * shadowShrink, height: minDim * 0.07 * shadowShrink)
                    .offset(x: bones.jumpOffsetX * 0.7, y: minDim * 0.40 + (pose == .resting ? minDim * 0.02 : 0))

                // Unified Live2D Multi-Bone GPU-Deformed Pet + Real Animated Face + Mythical Anatomy + Wardrobe!
                ZStack {
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

                    // Real Live2D Facial Rig: Fur-Matched Blinking Eyelids, Happy ^ ^ Eyes, Sleepy ◡ ◡ Eyes,
                    // Finger-Tracking Catchlights, Opening/Chewing Mouth & Rosy Watercolor Cheeks!
                    if !isStaticSnapshot {
                        Live2DFacialExpressionCanvas(
                            rig: rig,
                            bones: bones,
                            fingerFocus: fingerFocusNormalized,
                            time: time
                        )
                        .allowsHitTesting(false)
                    }

                    if pet.kind.isMagical {
                        MythicalSpeciesFrontLayerCanvas(
                            pet: pet,
                            neckAnchor: calibratedNeckAnchor,
                            time: isStaticSnapshot ? 0.6 : time
                        )
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
                .modifier(
                    Live2DMeshWarpModifier(
                        enabled: !isStaticSnapshot,
                        viewSize: CGSize(width: w, height: h),
                        rig: rig,
                        bones: bones
                    )
                )
                .offset(x: bones.jumpOffsetX, y: bones.jumpOffsetY)

                // Happy purr / brushing / Mentorship / Cozy Nap watercolor particle motes (hearts, stars, sleepy Zzz)
                if bones.showBlush || mentorshipParticle != nil || pose == .resting {
                    StorybookParticleMotesCanvas(
                        time: isStaticSnapshot ? 0.8 : time,
                        habit: mentorshipParticle,
                        isHappy: bones.showBlush && playfulAction != .cozyNap,
                        isResting: (pose == .resting && !isHappySquint && brushRuffleAmount <= 0.05 && !bones.isExcited) || playfulAction == .cozyNap
                    )
                    .allowsHitTesting(false)
                }
            }
            .frame(width: w, height: h)
        }
    }
}

/// GPU-accelerated 60fps Live2D multi-bone mesh deformation wrapper
private struct Live2DMeshWarpModifier: ViewModifier {
    let enabled: Bool
    let viewSize: CGSize
    let rig: ProceduralPetRigView.PetAnatomicalRig
    let bones: ProceduralPetRigView.Live2DBoneState

    func body(content: Content) -> some View {
        if enabled && viewSize.width > 10 && viewSize.height > 10 {
            let wingU = Float(rig.wingCenter?.x ?? 0.5)
            let wingV = Float(rig.wingCenter?.y ?? 0.5)
            content.distortionEffect(
                ShaderLibrary.live2DCreatureWarp(
                    .float2(Float(viewSize.width), Float(viewSize.height)),
                    .float4(Float(rig.headCenter.x), Float(rig.headCenter.y), Float(rig.headRadius), bones.headTiltRad),
                    .float4(bones.headShiftX, bones.headShiftY, bones.earTwitch, bones.chestBreath),
                    .float4(Float(rig.tailCenter.x), Float(rig.tailCenter.y), Float(rig.tailRadius), bones.tailWagPhase),
                    .float4(bones.tailWagAmp, rig.wingCenter != nil ? bones.wingFlapAmp : 0.0, wingU, wingV),
                    .float4(Float(rig.pawL.x), Float(rig.pawL.y), Float(rig.pawR.x), Float(rig.pawR.y)),
                    .float2(bones.pawLiftL, bones.pawLiftR)
                ),
                maxSampleOffset: CGSize(width: 28, height: 28)
            )
        } else {
            content
        }
    }
}

/// True multi-part facial expression layer (blinking eyelids, ^ ^ happy eyes, ◡ ◡ sleepy eyes, live gaze catchlights, chewing/smiling mouth)
/// Warped together with the base portrait by `live2DCreatureWarp` so facial features stay 100% locked onto the head!
private struct Live2DFacialExpressionCanvas: View {
    let rig: ProceduralPetRigView.PetAnatomicalRig
    let bones: ProceduralPetRigView.Live2DBoneState
    let fingerFocus: CGPoint?
    let time: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let minDim = min(w, h)
            let lidColor = Color(hex: rig.eyelidHex)
            let ink = Color(hex: "#2B2220").opacity(0.86)
            let er = minDim * rig.eyeRadius

            let eyePoints = [
                CGPoint(x: w * rig.eyeL.x, y: h * rig.eyeL.y),
                CGPoint(x: w * rig.eyeR.x, y: h * rig.eyeR.y)
            ]

            // 1. Animated Eyes: Natural Blink / Happy ^ ^ Crescent / Sleepy ◡ ◡ Lashes / Gaze Catchlights
            switch bones.eyeExpression {
            case .open(let blinkProgress):
                if blinkProgress > 0.03 {
                    for pt in eyePoints {
                        // Fur-matched upper eyelid sweeping smoothly down over the eye
                        let lidHeight = er * 2.15 * blinkProgress
                        let lidRect = CGRect(x: pt.x - er * 1.18, y: pt.y - er * 1.05, width: er * 2.36, height: lidHeight)
                        ctx.fill(Path(roundedRect: lidRect, cornerRadius: er * 0.55), with: .color(lidColor))
                        // Crisp curved eyelid lash line at lower edge of eyelid
                        var lash = Path()
                        let ly = lidRect.maxY
                        lash.move(to: CGPoint(x: pt.x - er * 0.95, y: ly - er * 0.12))
                        lash.addQuadCurve(to: CGPoint(x: pt.x + er * 0.95, y: ly - er * 0.12), control: CGPoint(x: pt.x, y: ly + er * 0.35))
                        ctx.stroke(lash, with: .color(ink), style: StrokeStyle(lineWidth: max(1.4, minDim * 0.009), lineCap: .round))
                    }
                } else if let focus = fingerFocus {
                    // Subtle live eye-tracking sparkle catchlight shifting toward finger!
                    for pt in eyePoints {
                        let gx = pt.x + focus.x * er * 0.36
                        let gy = pt.y + focus.y * er * 0.28
                        let cr = er * 0.26
                        ctx.fill(Path(ellipseIn: CGRect(x: gx - cr, y: gy - cr, width: cr * 2, height: cr * 2)), with: .color(.white.opacity(0.85)))
                    }
                }

            case .happyCrescent:
                for pt in eyePoints {
                    // Seamless fur-matched eyelid mask covering open eye
                    let maskRect = CGRect(x: pt.x - er * 1.24, y: pt.y - er * 1.10, width: er * 2.48, height: er * 2.20)
                    ctx.fill(Path(ellipseIn: maskRect), with: .color(lidColor))
                    // Adorable curving ^ smiling eye arc
                    var arc = Path()
                    arc.move(to: CGPoint(x: pt.x - er * 0.95, y: pt.y + er * 0.24))
                    arc.addQuadCurve(to: CGPoint(x: pt.x + er * 0.95, y: pt.y + er * 0.24), control: CGPoint(x: pt.x, y: pt.y - er * 0.78))
                    ctx.stroke(arc, with: .color(ink), style: StrokeStyle(lineWidth: max(1.8, minDim * 0.012), lineCap: .round))
                }

            case .sleepyClosed:
                for pt in eyePoints {
                    let maskRect = CGRect(x: pt.x - er * 1.24, y: pt.y - er * 1.10, width: er * 2.48, height: er * 2.20)
                    ctx.fill(Path(ellipseIn: maskRect), with: .color(lidColor))
                    // Peaceful downward ◡ sleeping eyelid arc
                    var arc = Path()
                    arc.move(to: CGPoint(x: pt.x - er * 0.92, y: pt.y - er * 0.12))
                    arc.addQuadCurve(to: CGPoint(x: pt.x + er * 0.92, y: pt.y - er * 0.12), control: CGPoint(x: pt.x, y: pt.y + er * 0.65))
                    ctx.stroke(arc, with: .color(ink), style: StrokeStyle(lineWidth: max(1.6, minDim * 0.010), lineCap: .round))
                }
            }

            // 2. Soft Rosy Watercolor Cheeks directly underneath the eyes
            if bones.showBlush {
                let cheekR = er * 1.55
                for pt in eyePoints {
                    let cx = pt.x
                    let cy = pt.y + er * 1.45
                    let blushRect = CGRect(x: cx - cheekR, y: cy - cheekR * 0.58, width: cheekR * 2, height: cheekR * 1.16)
                    ctx.fill(
                        Path(ellipseIn: blushRect),
                        with: .radialGradient(
                            Gradient(colors: [Color(hex: "#F5867B").opacity(0.62), Color(hex: "#F5867B").opacity(0.0)]),
                            center: CGPoint(x: cx, y: cy),
                            startRadius: 1,
                            endRadius: cheekR
                        )
                    )
                }
            }

            // 3. Real Animated Mouth (Happy open ᗜ smile / rhythmic chewing ○ ↔ ω + crumbs / Dragon-Cat fire puff!)
            if bones.mouthOpen > 0.08 {
                let mx = w * rig.mouth.x
                let my = h * rig.mouth.y
                let mw = minDim * 0.056 * (0.65 + bones.mouthOpen * 0.35)
                let mh = minDim * 0.044 * bones.mouthOpen

                var mouthPath = Path()
                mouthPath.move(to: CGPoint(x: mx - mw * 0.5, y: my))
                mouthPath.addQuadCurve(to: CGPoint(x: mx + mw * 0.5, y: my), control: CGPoint(x: mx, y: my - mh * 0.25))
                mouthPath.addQuadCurve(to: CGPoint(x: mx - mw * 0.5, y: my), control: CGPoint(x: mx, y: my + mh * 1.35))
                mouthPath.closeSubpath()
                ctx.fill(mouthPath, with: .color(Color(hex: "#C75A63")))
                // Cute tiny pink tongue inside open happy mouth
                ctx.fill(
                    Path(ellipseIn: CGRect(x: mx - mw * 0.28, y: my + mh * 0.18, width: mw * 0.56, height: mh * 0.52)),
                    with: .color(Color(hex: "#F29BA3"))
                )
                ctx.stroke(mouthPath, with: .color(ink), lineWidth: max(1.2, minDim * 0.007))

                // Dragon-Cat adorable glowing ember puff floating right out of snout!
                if bones.showDragonPuff {
                    let puffPhase = CGFloat((time * 2.2).truncatingRemainder(dividingBy: 1.0))
                    let px = mx - minDim * (0.04 + puffPhase * 0.10)
                    let py = my - minDim * (0.01 + puffPhase * 0.06)
                    let pr = minDim * 0.026 * (1.0 - puffPhase * 0.4)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px - pr, y: py - pr, width: pr * 2, height: pr * 2)),
                        with: .radialGradient(
                            Gradient(colors: [Color(hex: "#FFF2A6"), Color(hex: "#F28B3C"), .clear]),
                            center: CGPoint(x: px, y: py),
                            startRadius: 1,
                            endRadius: pr
                        )
                    )
                }
            }
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
