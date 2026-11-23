import SwiftUI
import UIKit

enum PetRigPose: String, Sendable {
    case notice
    case respond
    case resting
}

/// Public animation intents used by encounters, care and the Sunroom.
enum PetPlayfulAction: Equatable, Sendable {
    case idle
    case walking
    case bellyBoop
    case pounceHop
    case eatMunch
    case cozyNap
    case happyTwirl
    case curiousWaddle
}

/// Renders hand-painted cels from a per-pet manifest, with legacy choreography
/// for pets whose new banks are still being drawn.
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale
    var playfulAction: PetPlayfulAction = .idle
    var actionTriggerDate: Date = .distantPast

    var stageDate: Date? = nil
    var poseTransition: CelPoseTransition? = nil
    var poseStartedAt: Date? = nil
    var locomotion: CelLocomotion? = nil
    var facingRight = false
    var presentationScale: CGFloat = 1
    var previewFrame: String? = nil
    var previewNeck: [Double]? = nil

    private var assetPrefix: String { CelLibrary.prefix(for: pet.id) }

    var body: some View {
        Group {
            if isStaticSnapshot || reduceMotion {
                celAnimationStack(time: 0.0)
            } else if let stageDate {
                celAnimationStack(time: stageDate.timeIntervalSinceReferenceDate)
            } else {
                TimelineView(.animation(minimumInterval: AppTheme.Motion.interval(fps: 30.0, reduceMotion: reduceMotion))) { timeline in
                    celAnimationStack(time: timeline.date.timeIntervalSinceReferenceDate)
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

    /// Legacy socket calibration for pets without authored anchors.
    private var calibratedNeckAnchor: (u: CGFloat, v: CGFloat, width: CGFloat) {
        if let neck = previewNeck, neck.count == 3 {
            return (neck[0], neck[1], neck[2])
        }
        switch pet.id {
        case "pet.01": return (0.43, 0.50, 0.22) // 芝麻
        case "pet.02": return (0.41, 0.49, 0.20) // 杜松（黑曜惡魔貓）
        case "pet.03": return (0.40, 0.51, 0.22) // 餘燼（赤瓦龍貓）
        case "pet.04": return (0.42, 0.51, 0.21) // 摺翼（暮光夜魔貓）
        case "pet.05": return (0.42, 0.49, 0.22) // 味噌
        case "pet.06": return (0.43, 0.52, 0.24) // 鈕扣（墨玉小魔犬）
        case "pet.07": return (0.43, 0.51, 0.22) // 梅子（銀月星靈犬）
        case "pet.08": return (0.42, 0.48, 0.18) // 蘆葦（鹿角森靈犬）
        default:       return (0.42, 0.50, 0.21)
        }
    }

    private struct CelFrameState {
        var assetName: String
        var hopOffsetX: CGFloat = 0
        var hopOffsetY: CGFloat = 0
        var isSleeping: Bool = false
        var isExcited: Bool = false
        var isWalkingDust: Bool = false
        var playback: CelPlayback? = nil
    }

    private func celName(_ idx: Int) -> String {
        "\(assetPrefix)_f\(idx)"
    }

    private func bankFrame(_ bank: String, time: Double, legacyRate: Double? = nil) -> String {
        guard let player = CelLibrary.player(for: pet.id, bank: bank) else { return celName(1) }
        let adjusted = if let legacyRate, CelLibrary.authored(for: pet.id, bank: bank) == nil {
            time * legacyRate / player.clip.fps
        } else {
            time
        }
        return player.clip.asset(prefix: assetPrefix, frame: player.frame(at: adjusted))
    }

    private func authoredFrame(_ bank: String, elapsed: Double) -> CelFrameState? {
        guard let player = CelLibrary.authored(for: pet.id, bank: bank) else { return nil }
        if let playback = CelLibrary.playback(for: pet.id, starting: player, elapsed: elapsed) {
            return frameState(for: playback)
        }
        guard let idle = CelLibrary.player(for: pet.id, bank: "i") else { return nil }
        return frameState(for: CelPlayback(player: idle, elapsed: max(0, elapsed - player.duration)))
    }

    private func frameState(for playback: CelPlayback) -> CelFrameState {
        let activeBank = playback.player.clip.bank
        return CelFrameState(
            assetName: playback.player.clip.asset(prefix: assetPrefix, frame: playback.frame),
            isSleeping: activeBank == "s",
            isExcited: ["e", "g", "j", "h", "p"].contains(activeBank),
            isWalkingDust: ["w", "wr", "wf", "wb"].contains(activeBank),
            playback: playback
        )
    }

    private func resolveCelFrameState(time: Double, minDim: CGFloat) -> CelFrameState {
        if let previewFrame { return CelFrameState(assetName: previewFrame) }
        if isStaticSnapshot {
            let staticIdx: Int
            switch pose {
            case .resting: staticIdx = 6
            case .respond: staticIdx = isHappySquint ? 3 : 5
            case .notice:  staticIdx = isHappySquint ? 3 : 1
            }
            return CelFrameState(assetName: celName(staticIdx), isSleeping: staticIdx == 6, isExcited: isHappySquint)
        }

        if reduceMotion { return CelFrameState(assetName: celName(1)) }
        if let playback = poseTransition?.playback(at: Date(timeIntervalSinceReferenceDate: time)) {
            return frameState(for: playback)
        }
        let elapsed = max(0, time - actionTriggerDate.timeIntervalSinceReferenceDate)
        let poseElapsed = max(0, time - (poseStartedAt ?? actionTriggerDate).timeIntervalSinceReferenceDate)
        let petPhase = Double(StableHash.value(pet.id) % 11) * 0.53
        let tPet = time + petPhase

        // 1. Active explicit playful interactions (highest priority)
        switch playfulAction {
        case .walking:
            if let authored = authoredFrame(locomotion?.bank ?? "w", elapsed: poseElapsed) { return authored }
            // Relaxed, natural 16-frame stroll cycle (`w1`..`w16`) at 9.0fps (~1.78s per unhurried stride)
            let walkFPS = 9.0
            let subtleCadence = -CGFloat(abs(sin(tPet * walkFPS * .pi / 8.0))) * minDim * 0.008
            return CelFrameState(
                assetName: bankFrame("w", time: tPet),
                hopOffsetY: subtleCadence,
                isWalkingDust: true
            )

        case .cozyNap:
            if let authored = authoredFrame("s", elapsed: poseElapsed) { return authored }
            if elapsed < 0.45 {
                return CelFrameState(assetName: celName(2), isSleeping: false)
            }
            // Tranquil 12-frame deep sleeping breath (~3.75s per full breath)
            return CelFrameState(assetName: bankFrame("s", time: tPet), isSleeping: true)

        case .bellyBoop:
            if let authored = authoredFrame("g", elapsed: poseElapsed) { return authored }
            if elapsed < 2.2 {
                let hopArc = (elapsed < 0.65) ? sin(elapsed / 0.65 * .pi) : 0.0
                if elapsed < 0.65 {
                    return CelFrameState(assetName: bankFrame("h", time: elapsed), hopOffsetY: -CGFloat(hopArc) * minDim * 0.036, isExcited: true)
                } else if elapsed < 1.25 {
                    return CelFrameState(assetName: bankFrame("m", time: elapsed), hopOffsetY: -CGFloat(hopArc) * minDim * 0.015, isExcited: true)
                } else if elapsed < 1.75 {
                    return CelFrameState(assetName: bankFrame("p", time: elapsed), isExcited: true)
                } else {
                    return CelFrameState(assetName: bankFrame("h", time: elapsed), isExcited: true)
                }
            }

        case .pounceHop:
            if let authored = authoredFrame("j", elapsed: poseElapsed) { return authored }
            if elapsed < 2.25 {
                if elapsed < 0.22 {
                    return CelFrameState(assetName: bankFrame("i", time: 2.0 / 5.2), isExcited: true)
                } else if elapsed < 0.92 {
                    let p = (elapsed - 0.22) / 0.70
                    let hopY = -CGFloat(sin(p * .pi)) * minDim * 0.088
                    let hopX = -CGFloat(sin(p * .pi)) * minDim * 0.036
                    return CelFrameState(assetName: bankFrame("p", time: (elapsed - 0.22)), hopOffsetX: hopX, hopOffsetY: hopY, isExcited: true)
                } else if elapsed < 1.55 {
                    let p = (elapsed - 0.92) / 0.63
                    let hopY = -CGFloat(sin(p * .pi)) * minDim * 0.03
                    return CelFrameState(assetName: bankFrame("m", time: (elapsed - 0.92)), hopOffsetY: hopY, isExcited: true)
                } else {
                    return CelFrameState(assetName: bankFrame("h", time: (elapsed - 1.55)), isExcited: true)
                }
            }

        case .eatMunch:
            if let authored = authoredFrame("e", elapsed: elapsed) { return authored }
            if elapsed < 2.65 {
                if elapsed > 1.95 {
                    return CelFrameState(assetName: bankFrame("h", time: elapsed), isExcited: true)
                }
                // Calm, adorable rhythmic munching (`m1..m8`) alternating gently with rosy smile (`h1..h10`)
                let chewBeat = Int(elapsed / 0.72) % 2
                if chewBeat == 0 {
                    return CelFrameState(assetName: bankFrame("m", time: elapsed), hopOffsetY: -minDim * 0.008, isExcited: true)
                } else {
                    return CelFrameState(assetName: bankFrame("h", time: elapsed), isExcited: true)
                }
            }

        case .happyTwirl:
            if elapsed < 2.6 {
                let phase = Int(elapsed / 0.78) % 3
                let beat = (elapsed.truncatingRemainder(dividingBy: 0.78)) / 0.78
                let hop = (phase != 1) ? -CGFloat(sin(beat * .pi)) * minDim * 0.028 : 0
                if phase == 0 {
                    return CelFrameState(assetName: bankFrame("p", time: elapsed), hopOffsetY: hop, isExcited: true)
                } else if phase == 1 {
                    return CelFrameState(assetName: bankFrame("h", time: elapsed), isExcited: true)
                } else {
                    return CelFrameState(assetName: bankFrame("m", time: elapsed), hopOffsetY: hop, isExcited: true)
                }
            }

        case .curiousWaddle:
            let cycle = tPet.truncatingRemainder(dividingBy: 7.4)
            let driftX = CGFloat(sin(tPet * 0.45)) * minDim * 0.020
            if cycle < 2.6 {
                return CelFrameState(assetName: bankFrame("i", time: tPet), hopOffsetX: driftX)
            } else if cycle < 4.2 {
                return CelFrameState(assetName: bankFrame("p", time: tPet, legacyRate: 8.0), hopOffsetX: driftX)
            } else if cycle < 4.44 {
                return CelFrameState(assetName: celName(2), hopOffsetX: driftX)
            } else if cycle < 6.0 {
                return CelFrameState(assetName: bankFrame("h", time: tPet), hopOffsetX: driftX, isExcited: true)
            } else {
                return CelFrameState(assetName: bankFrame("i", time: tPet), hopOffsetX: driftX)
            }

        case .idle:
            break
        }

        // 2. Live petting / zone-based touch focus / happy-squint reactions
        if let focus = fingerFocusNormalized {
            // Subtle directional lean & zone-aware facial expression!
            let leanX = focus.x * minDim * 0.014
            if focus.y < -0.18 {
                // Touching head/ears -> blissful half-lidded purr & happy smile!
                let useBlink = (Int(tPet * 2.0) % 3 == 0)
                return CelFrameState(assetName: useBlink ? celName(2) : bankFrame("h", time: tPet, legacyRate: 7.2), hopOffsetX: leanX, isExcited: true)
            } else if focus.y > 0.20 {
                // Touching belly -> playful paw-batting reaction!
                return CelFrameState(assetName: bankFrame("p", time: tPet), hopOffsetX: leanX, isExcited: true)
            } else {
                // Chin / cheek scratch -> warm smiling squint!
                return CelFrameState(assetName: bankFrame("h", time: tPet, legacyRate: 7.5), hopOffsetX: leanX, isExcited: true)
            }
        }
        if brushRuffleAmount > 0.08 {
            let purrPhase = tPet.truncatingRemainder(dividingBy: 2.6)
            if purrPhase > 2.25 {
                return CelFrameState(assetName: celName(2), isExcited: true)
            }
            return CelFrameState(assetName: bankFrame("h", time: tPet), isExcited: true)
        }
        if isHappySquint {
            let cycle = tPet.truncatingRemainder(dividingBy: 4.4)
            if cycle > 3.1 && cycle < 3.9 {
                return CelFrameState(assetName: bankFrame("m", time: tPet), isExcited: true)
            }
            return CelFrameState(assetName: bankFrame("h", time: tPet), isExcited: true)
        }
        if tapBounceScale > 0.1 {
            return CelFrameState(assetName: bankFrame("h", time: tPet), hopOffsetY: -minDim * 0.025, isExcited: true)
        }

        // 3. Resting pose -> deep tranquil 12-frame sleeping breath loop (~3.75s / breath)
        if pose == .resting {
            if let authored = authoredFrame("s", elapsed: tPet) { return authored }
            let napCycle = tPet.truncatingRemainder(dividingBy: 16.0)
            if napCycle > 15.1 {
                return CelFrameState(assetName: celName(2), isSleeping: false)
            }
            return CelFrameState(assetName: bankFrame("s", time: tPet), isSleeping: true)
        }

        // 4. Calm living idle cel loop (5.2fps `i1`..`i16` = 3.08s per gentle breath + lazy tail drift + natural blink `f2`)
        if let authored = authoredFrame("i", elapsed: tPet) { return authored }
        let t = tPet.truncatingRemainder(dividingBy: 10.8)
        if (t >= 3.10 && t < 3.30) || (t >= 6.40 && t < 6.56) || (t >= 6.72 && t < 6.88) {
            return CelFrameState(assetName: celName(2))
        }
        if t >= 8.40 && t < 9.85 {
            return CelFrameState(assetName: bankFrame("h", time: tPet, legacyRate: 6.8), isExcited: true)
        }
        return CelFrameState(assetName: bankFrame("i", time: tPet))
    }

    private func respond(to event: String) {
        switch event {
        case "footContact", "land":
            CozySoundEngine.shared.playPawTap()
            HapticsEngine.shared.playBrushStrokeTick()
        case "chew":
            CozySoundEngine.shared.playCelChew()
            HapticsEngine.shared.playBrushStrokeTick()
        default:
            break
        }
    }

    private func preloadPlan(state: CelFrameState, date: Date, pixels: CGFloat) -> CelClipPreloader.Plan? {
        guard !isStaticSnapshot, !reduceMotion else { return nil }
        let suffix = state.assetName.dropFirst(assetPrefix.count + 1)
        let bank = String(suffix.prefix { $0.isLetter })
        let current = state.playback?.player ?? CelLibrary.player(for: pet.id, bank: bank)
        var upcoming: [CelClipPlayer] = []
        if let poseTransition, date < poseTransition.arrivesAt {
            upcoming += poseTransition.players
            let targetBank: String = switch poseTransition.target {
            case .walk: locomotion?.bank ?? "w"
            case .sleep: "s"
            case .idle, .startle: "i"
            }
            if let target = CelLibrary.player(for: pet.id, bank: targetBank) { upcoming.append(target) }
        } else if let next = current?.clip.next, let target = CelLibrary.player(for: pet.id, named: next) {
            upcoming.append(target)
        }
        return CelClipPreloader.Plan(prefix: assetPrefix, pixels: CelFrameImageCache.Key.bucket(for: pixels),
                                     current: current?.clip, upcoming: upcoming.map(\.clip))
    }

    @ViewBuilder
    private func celAnimationStack(time: Double) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minDim = min(w, h)
            let state = resolveCelFrameState(time: time, minDim: minDim)
            let frameAssetName = state.assetName
            let displayPixels = minDim * displayScale * presentationScale
            let playback = state.playback
            let recentDust = playback?.player.events(after: (playback?.elapsed ?? 0) - 0.42,
                                                     through: playback?.elapsed ?? 0)
                .filter { $0.name == "footContact" || $0.name == "land" } ?? []
            let activeBank = state.playback?.player.clip.bank
            let hasRightWalk = CelLibrary.authored(for: pet.id, bank: "wr") != nil
            let mirror = facingRight && !hasRightWalk && !(["wr", "wf", "wb", "tr"].contains(activeBank ?? ""))
            let shadowShrink = max(0.76, 1.0 + (state.hopOffsetY / max(1, minDim)) * 1.4)

            let rimGlowColor: Color = {
                switch weatherMode {
                case .dusk: return Color(hex: "#F5C06B").opacity(0.20)
                case .lightRain, .postRain: return Color(hex: "#BBD5DF").opacity(0.16)
                case .clearMorning: return Color(hex: "#FFF6D6").opacity(0.22)
                case .overcast: return Color(hex: "#E8ECE8").opacity(0.12)
                }
            }()

            ZStack {
                // Soft ambient weather light aura behind character
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [rimGlowColor, .clear],
                            center: .center,
                            startRadius: minDim * 0.08,
                            endRadius: minDim * 0.46
                        )
                    )
                    .frame(width: minDim * 0.84, height: minDim * 0.74)
                    .offset(y: minDim * 0.04)

                // L1_Shadow: Grounded soft watercolor shadow under paws
                Ellipse()
                    .fill(AppTheme.deepPineInk.opacity(0.16))
                    .frame(
                        width: minDim * (state.isSleeping ? 0.68 : 0.58) * shadowShrink,
                        height: minDim * 0.11 * shadowShrink
                    )
                    .blur(radius: minDim * 0.018)
                    .offset(x: state.hopOffsetX * 0.7, y: minDim * 0.41)

                Ellipse()
                    .fill(AppTheme.deepPineInk.opacity(0.09))
                    .frame(
                        width: minDim * (state.isSleeping ? 0.52 : 0.42) * shadowShrink,
                        height: minDim * 0.06 * shadowShrink
                    )
                    .offset(x: state.hopOffsetX * 0.7, y: minDim * 0.41)

                // Soft trailing paw-step dust puffs while walking across the 2.5D cedar floor!
                if !isStaticSnapshot, !reduceMotion {
                    if let playback, !recentDust.isEmpty {
                        WalkingPawDustCanvas(time: time, contactAges: recentDust.map { playback.elapsed - $0.time })
                            .allowsHitTesting(false)
                    } else if state.isWalkingDust, playback?.player.clip.events?["footContact"] == nil {
                        WalkingPawDustCanvas(time: time)
                            .allowsHitTesting(false)
                    }
                }

                // Pure Hand-Drawn Cel Frame (ZERO distortion, ZERO squeezing, ZERO fake facial overlays!)
                ZStack {
                    CelFrameImage(name: frameAssetName, fallbackName: celName(1),
                                  displayPixels: displayPixels, fallbackColor: Color(hex: pet.primaryCoatHex))

                    // Wardrobe accessory bound cleanly to sitting/standing poses (f1..f5); hidden on curled nap (f6)
                    if !state.isSleeping, let outfitID, let item = ShopCatalog.item(id: outfitID) {
                        let authoredNeck = state.playback?.player.clip.anchors?.neck ?? CelLibrary.manifest(for: pet.id)?.anchors?.neck
                        let neck = if let authoredNeck, authoredNeck.count == 3, !isStaticSnapshot {
                            (u: CGFloat(authoredNeck[0]), v: CGFloat(authoredNeck[1]), width: CGFloat(authoredNeck[2]))
                        } else {
                            calibratedNeckAnchor
                        }
                        let actionNeckYOffset: CGFloat = (playfulAction == .walking) ? -minDim * 0.012 : 0
                        WardrobeSocketOverlayCanvas(
                            item: item,
                            neckAnchor: (
                                u: neck.u,
                                v: neck.v + actionNeckYOffset / max(1, h),
                                width: neck.width
                            ),
                            canvasSize: CGSize(width: w, height: h),
                            time: isStaticSnapshot ? 0.5 : time
                        )
                    }
                }
                .offset(x: state.hopOffsetX, y: state.hopOffsetY)

                // Ambient happy hearts / golden stars / peaceful sleeping Zzz motes
                if !reduceMotion, state.isExcited || state.isSleeping || mentorshipParticle != nil {
                    StorybookParticleMotesCanvas(
                        time: isStaticSnapshot ? 0.8 : time,
                        habit: mentorshipParticle,
                        isHappy: state.isExcited && !state.isSleeping,
                        isResting: state.isSleeping
                    )
                    .allowsHitTesting(false)
                }
            }
            .frame(width: w, height: h)
            .modifier(CelClipPreloader(plan: preloadPlan(state: state,
                date: Date(timeIntervalSinceReferenceDate: time), pixels: displayPixels)))
            .onChange(of: playback, initial: true) { previous, current in
                guard !isStaticSnapshot, !reduceMotion, let current, current.player.clip.events != nil else { return }
                let earlier: Double
                if let previous, previous.player == current.player, current.elapsed >= previous.elapsed {
                    earlier = max(previous.elapsed, current.elapsed - 0.12)
                } else {
                    earlier = current.elapsed <= 0.12 ? -0.001 : current.elapsed - 0.12
                }
                for marker in current.player.events(after: earlier, through: current.elapsed) {
                    respond(to: marker.name)
                }
            }
            .scaleEffect(x: mirror ? -1 : 1, y: 1)
            .animation(reduceMotion || hasRightWalk || ["wf", "wb", "tn", "tr"].contains(activeBank ?? "") ? nil : .easeInOut(duration: 0.16), value: mirror)
        }
    }
}

/// Painterly gouache wardrobe overlay bound cleanly to each pet's `socket_neck` or `socket_back`.
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
            let sway = CGFloat(sin(time * 1.05)) * minDim * 0.005

            if item.slotType == "socket_back" {
                let bx = nx + nw * 0.62
                let by = ny + minDim * 0.13
                var strap = Path()
                strap.move(to: CGPoint(x: nx - nw * 0.25, y: ny))
                strap.addQuadCurve(to: CGPoint(x: bx, y: by - minDim * 0.04), control: CGPoint(x: nx + nw * 0.28, y: ny + minDim * 0.03))
                ctx.stroke(strap, with: .color(secondary), style: StrokeStyle(lineWidth: minDim * 0.020, lineCap: .round))

                let bagRect = CGRect(x: bx - minDim * 0.08, y: by - minDim * 0.055, width: minDim * 0.16, height: minDim * 0.125)
                let bagPath = Path(roundedRect: bagRect, cornerRadius: minDim * 0.026)
                ctx.fill(bagPath, with: .color(swatch.opacity(0.96)))
                ctx.stroke(bagPath, with: .color(ink), lineWidth: minDim * 0.008)
                return
            }

            var collarShadow = Path()
            collarShadow.move(to: CGPoint(x: nx - nw * 0.50, y: ny - minDim * 0.004))
            collarShadow.addQuadCurve(
                to: CGPoint(x: nx + nw * 0.50, y: ny + minDim * 0.002),
                control: CGPoint(x: nx, y: ny + minDim * 0.050)
            )
            ctx.stroke(collarShadow, with: .color(AppTheme.deepPineInk.opacity(0.18)), style: StrokeStyle(lineWidth: minDim * 0.038, lineCap: .round))

            var collar = Path()
            collar.move(to: CGPoint(x: nx - nw * 0.50, y: ny - minDim * 0.014))
            collar.addQuadCurve(
                to: CGPoint(x: nx + nw * 0.50, y: ny - minDim * 0.009),
                control: CGPoint(x: nx, y: ny + minDim * 0.040)
            )
            ctx.stroke(collar, with: .color(swatch), style: StrokeStyle(lineWidth: minDim * 0.034, lineCap: .round))
            ctx.stroke(collar, with: .color(.white.opacity(0.22)), style: StrokeStyle(lineWidth: minDim * 0.010, lineCap: .round))
            ctx.stroke(collar, with: .color(ink), style: StrokeStyle(lineWidth: minDim * 0.007, lineCap: .round))

            if item.id.contains("bandana") {
                var drape = Path()
                drape.move(to: CGPoint(x: nx - nw * 0.42, y: ny + minDim * 0.004))
                drape.addQuadCurve(
                    to: CGPoint(x: nx + nw * 0.42, y: ny + minDim * 0.007),
                    control: CGPoint(x: nx, y: ny + minDim * 0.032)
                )
                drape.addLine(to: CGPoint(x: nx - nw * 0.04 + sway, y: ny + minDim * 0.140))
                drape.closeSubpath()
                ctx.fill(drape, with: .color(swatch.opacity(0.96)))
                ctx.stroke(drape, with: .color(secondary.opacity(0.88)), style: StrokeStyle(lineWidth: minDim * 0.006, dash: [minDim * 0.013, minDim * 0.009]))
                ctx.stroke(drape, with: .color(ink), lineWidth: minDim * 0.008)
            } else if item.id == "outfit.occasion_collar" {
                ctx.stroke(collar, with: .color(secondary.opacity(0.85)), style: StrokeStyle(lineWidth: minDim * 0.007, dash: [minDim * 0.013, minDim * 0.013]))
                let bellR = minDim * 0.030
                let bellRect = CGRect(x: nx - bellR + sway * 0.8, y: ny + minDim * 0.022, width: bellR * 2, height: bellR * 2)
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
                var leftTail = Path()
                leftTail.move(to: CGPoint(x: nx - minDim * 0.010, y: ny + minDim * 0.018))
                leftTail.addQuadCurve(
                    to: CGPoint(x: nx - minDim * 0.070 + sway, y: ny + minDim * 0.100),
                    control: CGPoint(x: nx - minDim * 0.052, y: ny + minDim * 0.046)
                )
                leftTail.addLine(to: CGPoint(x: nx - minDim * 0.022 + sway * 0.7, y: ny + minDim * 0.106))
                leftTail.closeSubpath()
                ctx.fill(leftTail, with: .color(swatch))
                ctx.stroke(leftTail, with: .color(ink), lineWidth: minDim * 0.007)

                var rightTail = Path()
                rightTail.move(to: CGPoint(x: nx + minDim * 0.008, y: ny + minDim * 0.018))
                rightTail.addQuadCurve(
                    to: CGPoint(x: nx + minDim * 0.064 + sway, y: ny + minDim * 0.098),
                    control: CGPoint(x: nx + minDim * 0.048, y: ny + minDim * 0.045)
                )
                rightTail.addLine(to: CGPoint(x: nx + minDim * 0.016 + sway * 0.7, y: ny + minDim * 0.104))
                rightTail.closeSubpath()
                ctx.fill(rightTail, with: .color(secondary))
                ctx.stroke(rightTail, with: .color(ink), lineWidth: minDim * 0.007)

                let knotR = minDim * 0.022
                let knotRect = CGRect(x: nx - knotR, y: ny + minDim * 0.003, width: knotR * 2, height: knotR * 2)
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
                let letters = ["z", "Z", "z"]
                for idx in 0..<3 {
                    let phase = (time * 0.18 + Double(idx) * 0.33).truncatingRemainder(dividingBy: 1.0)
                    let px = cx + minDim * 0.18 + CGFloat(sin(time * 0.8 + Double(idx))) * minDim * 0.026 + CGFloat(idx) * minDim * 0.024
                    let py = cy - CGFloat(phase) * minDim * 0.25
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
                let phase = (time * 0.26 + Double(idx) * (1.0 / Double(count))).truncatingRemainder(dividingBy: 1.0)
                let spread = CGFloat(idx - count / 2) * minDim * 0.10
                let px = cx + spread + CGFloat(sin(time * 0.85 + Double(idx) * 1.5)) * minDim * 0.024
                let py = cy - CGFloat(phase) * minDim * 0.28
                let s = minDim * 0.020 * (1.0 - CGFloat(phase) * 0.3)
                let alpha = sin(phase * .pi) * (isHappy ? 0.85 : 0.65)

                if isHappy && idx % 2 == 0 {
                    var heart = Path()
                    heart.move(to: CGPoint(x: px, y: py + s * 0.5))
                    heart.addCurve(to: CGPoint(x: px - s * 0.7, y: py - s * 0.1), control1: CGPoint(x: px - s * 0.5, y: py + s * 0.3), control2: CGPoint(x: px - s * 0.8, y: py + s * 0.05))
                    heart.addArc(center: CGPoint(x: px - s * 0.35, y: py - s * 0.2), radius: s * 0.35, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                    heart.addArc(center: CGPoint(x: px + s * 0.35, y: py - s * 0.2), radius: s * 0.35, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                    heart.addCurve(to: CGPoint(x: px, y: py + s * 0.5), control1: CGPoint(x: px + s * 0.8, y: py + s * 0.05), control2: CGPoint(x: px + s * 0.5, y: py + s * 0.3))
                    ctx.fill(heart, with: .color(Color(hex: "#E87266").opacity(alpha)))
                } else {
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

/// Soft pastel floor dust puffs kicking up behind a walking pet's back paws
private struct WalkingPawDustCanvas: View {
    let time: Double
    var contactAges: [Double]? = nil

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let minDim = min(w, h)
            let phases = contactAges?.map { min(1, max(0, $0 / 0.42)) }
                ?? (0..<3).map { (time * 0.85 + Double($0) * 0.33).truncatingRemainder(dividingBy: 1.0) }
            for phase in phases {
                let px = w * 0.66 + CGFloat(phase) * minDim * 0.15
                let py = h * 0.87 - CGFloat(phase) * minDim * 0.045
                let r = minDim * (0.015 + CGFloat(phase) * 0.018)
                let alpha = (1.0 - phase) * 0.38
                ctx.fill(
                    Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                    with: .color(Color(hex: "#FFF8EC").opacity(alpha))
                )
            }
        }
    }
}
