import SwiftUI

/// 真 2.5D 透視陽光室舞台：
/// - Layer 0/1：遠景手繪陽光室牆面與窗景（0.35× 視差）＋ 真 1 點透視紅檜木地板、窗框斜光與前縮編織地毯（0.85× 視差）
/// - Layer 2：可點擊自由漫步的 2.5D 深度排序地板舞台（家具與自由散步中的毛孩依深度 `y` 自動縮放 0.74×..1.15× 與即時 `zIndex` 前後遮擋）
/// - Layer 3：近景微景深植物與木樑前景框架（1.30× 視差，拖曳畫面時立即呈現強烈立體景深！）
struct Sunroom25DStageView: View {
    @Bindable var coordinator: GameCoordinator
    @Bindable var roaming: SunroomRoamingEngine
    let effectivePan: CGFloat
    let bouncingPetID: String?
    let onTapPet: (String) -> Void
    let onTapSpot: (HomeSpotPlacement) -> Void
    let onCompleteMentorship: (TeachingIntention) -> Void

    var body: some View {
        GeometryReader { geo in
            let viewW = geo.size.width
            let viewH = geo.size.height
            let stageW = viewW + (coordinator.ledger.verandaUnlocked ? 360 : 200)
            let floorHorizonY = viewH * 0.455
            let floorBottomY = viewH * 0.855

            ZStack {
                // MARK: Layer 1A — Back Hand-Painted Sunroom Wall & Sunlit Window (0.35x Parallax)
                ZStack {
                    if let uiBg = UIImage(named: "bg_home_sunroom") {
                        Image(uiImage: uiBg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: stageW, height: viewH)
                            .overlay(
                                Rectangle()
                                    .fill(sunroomThemeTint(weather: coordinator.activeWeather, theme: coordinator.ledger.activeRoomTheme))
                                    .blendMode(.multiply)
                            )
                    } else {
                        LinearGradient(
                            colors: [Color(hex: "#F2E9D8"), Color(hex: "#DFC9A8")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .offset(x: effectivePan * 0.35)

                // MARK: Layer 1B — True 1-Point Perspective 2.5D Cedar Floorboard Plane, Baseboard & Rug (0.88x Parallax)
                PerspectiveCedarFloorCanvas(
                    horizonY: floorHorizonY,
                    weather: coordinator.activeWeather,
                    theme: coordinator.ledger.activeRoomTheme,
                    verandaUnlocked: coordinator.ledger.verandaUnlocked
                )
                .frame(width: stageW, height: viewH)
                .offset(x: effectivePan * 0.88)

                // MARK: Layer 1C — Volumetric Sunbeams & Dust Motes / Window Rain (0.55x Parallax)
                SunroomAtmosphereParticlesView(weather: coordinator.activeWeather)
                    .offset(x: effectivePan * 0.55)

                // MARK: Layer 2 — Interactive 2.5D Depth-Sorted Floor Stage (Furniture + Free-Roaming Pets)
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let now = timeline.date
                    ZStack {
                        // Tap anywhere on the 2.5D wooden floor to call the nearest pet over!
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                guard location.y >= floorHorizonY - 12 && location.y <= floorBottomY + 24 else { return }
                                let u = location.x / stageW
                                let depth = max(0.14, min(0.88, (location.y - floorHorizonY) / max(1, floorBottomY - floorHorizonY)))
                                HapticsEngine.shared.playBrushStrokeTick()
                                CozySoundEngine.shared.playCompassChime()
                                roaming.callNearestPet(to: CGPoint(x: u, y: depth), now: now)
                            }

                        // Golden foreshortened floor tap ripples
                        ForEach(roaming.floorRipples) { ripple in
                            let age = max(0, now.timeIntervalSince(ripple.createdAt))
                            let p = min(1.0, age / 1.1)
                            let pt = floorPoint(uv: ripple.position, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let scale = depthScale(for: ripple.position.y)
                            ZStack {
                                Ellipse()
                                    .stroke(AppTheme.pawStrollChain.opacity((1.0 - p) * 0.85), lineWidth: 2.2)
                                    .frame(width: (24 + p * 68) * scale, height: (10 + p * 26) * scale)
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 11 * scale, weight: .bold))
                                    .foregroundStyle(AppTheme.pawStrollChain.opacity((1.0 - p) * 0.9))
                                    .scaleEffect(y: 0.65)
                            }
                            .position(pt)
                            .zIndex(Double(ripple.position.y * 1000.0) - 20)
                            .allowsHitTesting(false)
                        }

                        // 2.5D Staggered Home Furnishings (depth-scaled & depth-sorted)
                        ForEach(coordinator.homeSpots, id: \.spotIndex) { spot in
                            let uv = SunroomRoamingEngine.spot25DPosition(
                                for: spot.spotIndex,
                                verandaUnlocked: coordinator.ledger.verandaUnlocked
                            )
                            let pt = floorPoint(uv: uv, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let scale = depthScale(for: uv.y)

                            VStack(spacing: 2) {
                                PaintedGoodiePropView(
                                    goodieID: spot.equippedGoodieID,
                                    hasLovedPatina: spot.hasLovedPatina,
                                    hasStitchedPatch: spot.hasStitchedPatch,
                                    isWide: spot.currentOccupantPetIDs.count > 1
                                )
                                Text(spot.hasLovedPatina ? "✦ \(spot.spotName)" : spot.spotName)
                                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "#4A3628"))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "#FFFDF7").opacity(0.90))
                                            .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 0.9))
                                    )
                            }
                            .scaleEffect(scale)
                            .position(x: pt.x, y: pt.y + 8 * scale)
                            .zIndex(Double(uv.y * 1000.0) - 10)
                            .onTapGesture {
                                onTapSpot(spot)
                            }
                        }

                        // 2.5D Free-Roaming Hand-Animated Pets (live depth scaling, facing flip & painter's zIndex!)
                        ForEach(Array(roaming.actors.values), id: \.petID) { actor in
                            let spec = PetCatalog.pet(id: actor.petID)
                            let resident = coordinator.resident(for: actor.petID)
                            let pt = floorPoint(uv: actor.position, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let scale = depthScale(for: actor.position.y)
                            let petMentorship = coordinator.teachingIntentions.first {
                                $0.state == .demonstrated &&
                                ($0.mentorPetID == actor.petID || $0.learnerPetID == actor.petID)
                            }
                            let isExcited = (bouncingPetID == actor.petID) || (now < actor.tapExcitedUntil)
                            let petAction: PetPlayfulAction = {
                                if bouncingPetID == actor.petID { return .bellyBoop }
                                switch actor.behavior {
                                case .walking: return .walking
                                case .napping: return .cozyNap
                                case .greetingFriend: return .bellyBoop
                                case .sitting: return .idle
                                }
                            }()

                            VStack(spacing: 0) {
                                if let ready = petMentorship {
                                    CutePlushButton(
                                        title: "記下傳承",
                                        tone: .butterHoney,
                                        fontSize: 10,
                                        horizontalPadding: 8,
                                        verticalPadding: 4,
                                        icon: { Image(systemName: "sparkles").font(.system(size: 10, weight: .bold)) },
                                        action: { onCompleteMentorship(ready) }
                                    )
                                } else if let bubble = actor.speechBubble {
                                    SunroomPetSpeechBubble(text: bubble)
                                        .offset(y: 6)
                                }

                                Button {
                                    onTapPet(actor.petID)
                                } label: {
                                    ProceduralPetRigView(
                                        pet: spec,
                                        outfitID: resident?.activeOutfitID,
                                        pose: actor.isNapping ? .resting : .notice,
                                        weatherMode: coordinator.activeWeather,
                                        isHappySquint: isExcited || ( { if case .greetingFriend = actor.behavior { return true }; return false }() ),
                                        mentorshipParticle: petMentorship.flatMap { HabitFamily(rawValue: $0.habitFamilyID) },
                                        tapBounceScale: bouncingPetID == actor.petID ? 1.0 : 0.0,
                                        playfulAction: petAction,
                                        actionTriggerDate: actor.tapExcitedUntil.addingTimeInterval(-1.2)
                                    )
                                    .frame(width: 118, height: 118)
                                    // Smooth automatic facing direction when walking right vs. left!
                                    .scaleEffect(x: actor.facingRight ? -1.0 : 1.0, y: 1.0)
                                }
                                .buttonStyle(.plain)
                            }
                            .scaleEffect(scale)
                            // Ground-baseline anchor: pet's paws rest exactly on the 2.5D floor coordinate `pt`
                            .position(x: pt.x, y: pt.y - 44 * scale)
                            .zIndex(Double(actor.position.y * 1000.0))
                        }

                        // Empty sunroom welcoming guide when the player hasn't invited a pet yet
                        if roaming.actors.isEmpty {
                            VStack(spacing: 8) {
                                Text("去街角向第一位奇幻毛孩打招呼吧！")
                                    .font(AppTheme.serifTitle(16))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text("邀請牠們來陽光室後，就能看見牠們在 2.5D 木地板自由散步、聊天和午睡。")
                                    .font(AppTheme.handwritten(13))
                                    .foregroundStyle(AppTheme.softInk)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(16)
                            .background(AppTheme.warmPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 1.2))
                            .padding(.horizontal, 36)
                            .position(x: stageW * 0.5, y: (floorHorizonY + floorBottomY) * 0.5)
                        }
                    }
                    .frame(width: stageW, height: viewH)
                    .onChange(of: timeline.date) { _, newDate in
                        roaming.tick(
                            now: newDate,
                            spots: coordinator.homeSpots,
                            verandaUnlocked: coordinator.ledger.verandaUnlocked
                        )
                    }
                }
                .offset(x: effectivePan)

                // MARK: Layer 3 — Foreground Out-of-Focus Botanical & Timber Depth Frame (1.32x Parallax!)
                ForegroundBotanicalParallaxOverlay(weather: coordinator.activeWeather)
                    .frame(width: viewW + 260, height: viewH)
                    .offset(x: effectivePan * 1.32)
                    .allowsHitTesting(false)
            }
            .frame(width: viewW, height: viewH)
            .clipped()
        }
        .ignoresSafeArea()
    }

    /// Maps room floor UV `(x: 0..1, y: 0..1 depth)` onto the perspective floor trapezoid
    private func floorPoint(uv: CGPoint, stageW: CGFloat, horizonY: CGFloat, bottomY: CGFloat) -> CGPoint {
        // Subtle perspective horizontal pinch near back wall (`y=0`), wider near foreground (`y=1`)
        let perspectiveSpread = 0.80 + uv.y * 0.20
        let centeredX = (uv.x - 0.5) * perspectiveSpread + 0.5
        // Slightly non-linear depth foreshortening (objects move slower near back horizon, faster near foreground)
        let depthEase = pow(uv.y, 1.15)
        let screenY = horizonY + depthEase * (bottomY - horizonY)
        return CGPoint(x: centeredX * stageW, y: screenY)
    }

    /// True 2.5D perspective scale: smaller near back sunny window (0.74x), larger in foreground (1.15x)
    private func depthScale(for depth: CGFloat) -> CGFloat {
        0.74 + max(0, min(1, depth)) * 0.41
    }

    private func sunroomThemeTint(weather: WeatherMode, theme: SeasonalRoomTheme) -> Color {
        if weather.isRainy || theme == .rainySeason {
            return Color(hex: "#C8DCE2").opacity(0.26)
        } else if theme == .winterLamp || weather == .dusk {
            return Color(hex: "#F2C58A").opacity(0.28)
        } else if theme == .autumnCedar {
            return Color(hex: "#E6B98A").opacity(0.22)
        }
        return Color.clear
    }
}

/// True 1-Point Perspective 2.5D Cedar Floorboards, Baseboard Molding, Sunbeam Floor Reflection & Foreshortened Rug
private struct PerspectiveCedarFloorCanvas: View {
    let horizonY: CGFloat
    let weather: WeatherMode
    let theme: SeasonalRoomTheme
    let verandaUnlocked: Bool

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let floorH = h - horizonY

            // 1. Warm baseboard timber skirting separating back sunroom wall from the 2.5D floor
            let baseboardRect = CGRect(x: 0, y: horizonY - 14, width: w, height: 18)
            ctx.fill(
                Path(baseboardRect),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#8A5F39"), Color(hex: "#674325")]),
                    startPoint: CGPoint(x: 0, y: baseboardRect.minY),
                    endPoint: CGPoint(x: 0, y: baseboardRect.maxY)
                )
            )
            // Soft wall-to-floor ambient occlusion shadow strip
            ctx.fill(
                Path(CGRect(x: 0, y: horizonY + 4, width: w, height: 22)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#3B2412").opacity(0.28), .clear]),
                    startPoint: CGPoint(x: 0, y: horizonY + 4),
                    endPoint: CGPoint(x: 0, y: horizonY + 26)
                )
            )

            // 2. Main 2.5D Cedar Wood Floor Plane (rich honey/amber/rain-cool gradient)
            let floorRect = CGRect(x: 0, y: horizonY + 4, width: w, height: floorH)
            ctx.fill(
                Path(floorRect),
                with: .linearGradient(
                    Gradient(colors: weather.isRainy
                             ? [Color(hex: "#C5AE91"), Color(hex: "#A88D6F"), Color(hex: "#8E7358")]
                             : [Color(hex: theme.floorTopHex), Color(hex: theme.floorBottomHex), Color(hex: "#8B5E39")]),
                    startPoint: CGPoint(x: 0, y: horizonY),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )

            // 3. True 1-Point Perspective Floorboard Seam Lines converging toward window vanishing point!
            let vp = CGPoint(x: w * 0.50, y: horizonY - floorH * 0.55)
            let plankCount = verandaUnlocked ? 16 : 12
            for idx in -2...(plankCount + 2) {
                let bottomX = CGFloat(idx) * (w / CGFloat(plankCount))
                // Intersect ray from bottomX toward vanishing point `vp` at `y = horizonY + 4`
                let t = (horizonY + 4 - h) / (vp.y - h)
                let topX = bottomX + (vp.x - bottomX) * t
                var seam = Path()
                seam.move(to: CGPoint(x: topX, y: horizonY + 4))
                seam.addLine(to: CGPoint(x: bottomX, y: h))
                ctx.stroke(seam, with: .color(Color(hex: "#4B2E17").opacity(0.22)), lineWidth: 1.2)
            }

            // Exponentially spaced horizontal plank end-joins (closer near back wall, wider in foreground)
            for row in 1...7 {
                let f = pow(Double(row) / 7.5, 1.55)
                let y = horizonY + 4 + CGFloat(f) * floorH
                var join = Path()
                join.move(to: CGPoint(x: 0, y: y))
                join.addLine(to: CGPoint(x: w, y: y))
                ctx.stroke(join, with: .color(Color(hex: "#4B2E17").opacity(0.13)), lineWidth: 1.0)
            }

            // 4. Optional Rain-Porch Wooden Veranda Deck Strip on Right Side
            if verandaUnlocked {
                let deckX = w * 0.72
                ctx.fill(
                    Path(CGRect(x: deckX, y: horizonY + 4, width: w - deckX, height: floorH)),
                    with: .color(Color(hex: "#735843").opacity(0.22))
                )
                var divider = Path()
                divider.move(to: CGPoint(x: deckX + 18, y: horizonY + 4))
                divider.addLine(to: CGPoint(x: deckX - 18, y: h))
                ctx.stroke(divider, with: .color(Color(hex: "#52351E").opacity(0.45)), lineWidth: 3.0)
            }

            // 5. Foreshortened 2.5D Braided Oval Sunroom Rug centered on the mid-foreground floor
            let rugCenter = CGPoint(x: w * (verandaUnlocked ? 0.36 : 0.50), y: horizonY + floorH * 0.44)
            let rugRings: [(CGFloat, CGFloat, Color)] = [
                (260, 86, Color(hex: "#4A2E18").opacity(0.16)), // soft cast shadow
                (252, 80, Color(hex: "#58788C").opacity(0.62)),
                (212, 66, Color(hex: "#EFE2C8").opacity(0.82)),
                (168, 50, Color(hex: "#CC855A").opacity(0.58)),
                (120, 34, Color(hex: "#F6ECD8").opacity(0.76))
            ]
            for (idx, ring) in rugRings.enumerated() {
                let yOff: CGFloat = idx == 0 ? 4 : 0
                let rect = CGRect(x: rugCenter.x - ring.0 * 0.5, y: rugCenter.y - ring.1 * 0.5 + yOff, width: ring.0, height: ring.1)
                ctx.fill(Path(ellipseIn: rect), with: .color(ring.2))
                if idx > 0 {
                    ctx.stroke(Path(ellipseIn: rect), with: .color(Color(hex: "#5B3E26").opacity(0.24)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                }
            }

            // 6. Slanting Warm Windowpane Sunlight Reflection lying flat on the 2.5D wooden floor!
            if !weather.isRainy {
                let lightTint = weather == .dusk ? Color(hex: "#FFD99B").opacity(0.26) : Color(hex: "#FFFCE8").opacity(0.28)
                for pane in 0..<2 {
                    let shift = CGFloat(pane) * 140
                    var patch = Path()
                    patch.move(to: CGPoint(x: w * 0.16 + shift, y: horizonY + 12))
                    patch.addLine(to: CGPoint(x: w * 0.36 + shift, y: horizonY + 12))
                    patch.addLine(to: CGPoint(x: w * 0.52 + shift, y: horizonY + floorH * 0.56))
                    patch.addLine(to: CGPoint(x: w * 0.28 + shift, y: horizonY + floorH * 0.56))
                    patch.closeSubpath()
                    ctx.fill(patch, with: .color(lightTint))
                }
            }
        }
    }
}

/// Layer 3 Foreground Parallax Botanical Leaves & Timber Corner Eave (moves faster than floor for vivid 2.5D depth!)
private struct ForegroundBotanicalParallaxOverlay: View {
    let weather: WeatherMode

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            // Soft out-of-focus foreground fern/monstera fronds in bottom-left & bottom-right corners
            let frondColor = weather.isRainy ? Color(hex: "#2F5447") : Color(hex: "#3E6E52")
            for idx in 0..<4 {
                let fx = 28.0 + Double(idx) * 26.0
                let fy = Double(h) - 110.0 + Double(idx % 2) * 24.0
                let leaf = Path(ellipseIn: CGRect(x: fx - 44, y: fy - 18, width: 88, height: 34))
                ctx.fill(leaf, with: .color(frondColor.opacity(0.22)))
            }
            for idx in 0..<4 {
                let fx = Double(w) - 34.0 - Double(idx) * 26.0
                let fy = Double(h) - 118.0 + Double(idx % 2) * 22.0
                let leaf = Path(ellipseIn: CGRect(x: fx - 44, y: fy - 18, width: 88, height: 34))
                ctx.fill(leaf, with: .color(frondColor.opacity(0.20)))
            }

            // Warm top-corner cedar roof beam vignette framing the 2.5D room
            ctx.fill(
                Path(CGRect(x: 0, y: 0, width: w, height: 22)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#4B2E17").opacity(0.35), .clear]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: 22)
                )
            )
        }
        .blur(radius: 1.5)
    }
}
