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
    var isDecoratingMode: Bool = false
    var selectedDecorateSpotIndex: Int = 1
    var isFeatherWandMode: Bool = false
    var isPhotoMode: Bool = false
    var hidingSpotIndex: Int? = nil
    var hidingPetID: String? = nil
    var activeTeaRecipe: TeaRecipeSpec = TeaKitchenCatalog.allRecipes[0]
    let onTapPet: (String) -> Void
    let onTapSpot: (HomeSpotPlacement) -> Void
    let onCompleteMentorship: (TeachingIntention) -> Void
    var onCollectOrigami: ((SunroomRoamingEngine.OrigamiCharmDrop) -> Void)? = nil
    var onTapWindowsillCurio: ((ForagedCurioEntry) -> Void)? = nil
    var onTapOffspring: ((MysticalOffspringRecord) -> Void)? = nil
    var onFoundHidingPet: ((String, CGPoint) -> Void)? = nil
    var onTriggerSkit: ((String, String) -> Void)? = nil
    var onCompleteFeatherWandChase: (() -> Void)? = nil
    var onCycleTeaRecipe: (() -> Void)? = nil
    var onBrewTeaInWorld: ((TeaRecipeSpec) -> Void)? = nil
    var onTapOrigamiTable: (() -> Void)? = nil
    var onSendErrandSupply: ((ErrandSupplyPack) -> Void)? = nil
    var onCollectErrandInWorld: (() -> Void)? = nil
    var onStartCourtshipNest: ((String, String) -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draggingSpotIndex: Int? = nil
    @State private var draggingSpotUV: CGPoint? = nil
    @State private var wandScreenPoint: CGPoint? = nil
    @State private var lastWandPoint: CGPoint? = nil
    @State private var wandChaseDistance: CGFloat = 0
    @State private var lastWandCallDate: Date = .distantPast
    @State private var windChimeRingPulse: Bool = false

    var body: some View {
        GeometryReader { geo in
            let viewW = geo.size.width
            let viewH = geo.size.height
            let stageW = viewW + (coordinator.ledger.verandaUnlocked ? 360 : 200)
            let floorHorizonY = viewH * 0.46
            let floorBottomY = viewH * 0.855

            let viewportLeft = (stageW - viewW) / 2 - effectivePan
            let hidingPet = !isDecoratingMode && !isFeatherWandMode && !isPhotoMode &&
                coordinator.homeSpots.contains { $0.spotIndex == hidingSpotIndex && $0.equippedGoodieID != nil }
                ? hidingPetID : nil

            TimelineView(.animation(minimumInterval: AppTheme.Motion.interval(fps: 60, reduceMotion: reduceMotion))) { timeline in
                let now = timeline.date
                let visibleActors = roaming.actors.values.filter { $0.petID != hidingPet }
                let skitPair = isPhotoMode || isDecoratingMode || isFeatherWandMode
                    ? nil : nearbyRoommates(visibleActors, at: now)
                ZStack {
                    // MARK: Layer 1A — Back Hand-Painted Sunroom Wall & Sunlit Window (0.35x Parallax)
                    ZStack {
                        if let uiBg = UIImage(named: "bg_home_sunroom") {
                            Image(uiImage: uiBg)
                                .resizable()
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
                    .offset(x: effectivePan * (reduceMotion ? 1 : 0.35))

                    // MARK: Layer 1B — True 1-Point Perspective 2.5D Cedar Floorboard Plane, Baseboard & Rug (0.88x Parallax)
                    PerspectiveCedarFloorCanvas(
                        horizonY: floorHorizonY,
                        weather: coordinator.activeWeather,
                        theme: coordinator.ledger.activeRoomTheme,
                        verandaUnlocked: coordinator.ledger.verandaUnlocked,
                        lightOffsetX: reduceMotion ? 0 : effectivePan * (0.35 - 0.88)
                    )
                    .frame(width: stageW, height: viewH)
                    .offset(x: effectivePan * (reduceMotion ? 1 : 0.88))

                    // MARK: Layer 1C — Volumetric Sunbeams, Calendar Seasonal Window Ambiance & Tappable Curio Shelf (0.55x Parallax)
                    SunroomAmbientLayers(weather: coordinator.activeWeather, date: now, reduceMotion: reduceMotion)
                        .frame(width: stageW, height: viewH)
                        .offset(x: effectivePan * (reduceMotion ? 1 : 0.35))

                    if !reduceMotion {
                        SeasonalWindowAmbianceOverlay(stageDate: now, date: coordinator.currentSimulatedDate)
                            .frame(width: stageW, height: viewH)
                            .offset(x: effectivePan * (reduceMotion ? 1 : 0.58))
                            .allowsHitTesting(false)

                        if coordinator.activeWeather == .dusk {
                            DuskFireflyMotesOverlay(stageDate: now)
                                .frame(width: stageW, height: viewH)
                                .offset(x: effectivePan * (reduceMotion ? 1 : 0.70))
                                .allowsHitTesting(false)
                        }
                    }

                    if !coordinator.ledger.foragedCurios.isEmpty {
                        WindowsillCurioShelfView(
                            curios: Array(coordinator.ledger.foragedCurios.prefix(6)),
                            onTapCurio: { entry in
                                HapticsEngine.shared.playBrushStrokeTick()
                                CozySoundEngine.shared.playTeapotClink()
                                onTapWindowsillCurio?(entry)
                            }
                        )
                        .position(x: stageW * 0.50, y: floorHorizonY - 26)
                        .offset(x: effectivePan * (reduceMotion ? 1 : 0.60))
                    }

                    if coordinator.isGingerTeaActive {
                        SteamingGingerTeaTrayView(onTap: { coordinator.sipGingerTea() })
                            .scaleEffect(0.76)
                            .position(x: stageW * 0.40, y: floorHorizonY - 62)
                            .offset(x: effectivePan * (reduceMotion ? 1 : 0.60))
                            .allowsHitTesting(!isPhotoMode)
                    }

                    // Hanging Window Beam Decor: Swipeable Edo Glass Wind Chime + Crafted Origamis!
                    HangingWindowDecorBeamView(
                        origamis: coordinator.indoorState.hangingOrigamis,
                        isRinging: windChimeRingPulse,
                        onRingChime: {
                            coordinator.ringSunroomWindChime()
                            roaming.emitFloatingBurst(at: CGPoint(x: 0.48, y: 0.16), text: "♪ 叮噹清響", colorHex: "#4A7A76")
                            withAnimation(AppTheme.Motion.resolved(.bouncy, reduceMotion: reduceMotion)) {
                                windChimeRingPulse = true
                            }
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(700))
                                withAnimation(.easeOut(duration: 0.3)) { windChimeRingPulse = false }
                            }
                        }
                    )
                    .position(x: stageW * 0.50, y: max(116, floorHorizonY - 126))
                    .offset(x: effectivePan * (reduceMotion ? 1 : 0.50))

                    // Pinned Watercolor Diary Postcard mounted with Washi Tape on the back left wall
                    if let pinnedID = coordinator.indoorState.pinnedPostcardEncounterID,
                       let enc = coordinator.encounters.first(where: { $0.encounterUUID == pinnedID }),
                       let pngData = enc.bakedSnapshotPNGData,
                       let img = UIImage(data: pngData) {
                        PinnedWallPostcardView(image: img, placeLabel: enc.siteDisplayLabel) {
                            HapticsEngine.shared.playBrushStrokeTick()
                            CozySoundEngine.shared.playPaperFlip()
                            coordinator.showWhisper("牆上的珍藏明信片：\(enc.narrativeLine)")
                        }
                        .position(x: stageW * 0.24, y: floorHorizonY - 76)
                        .offset(x: effectivePan * (reduceMotion ? 1 : 0.44))
                    }

                    // Shy Undiscovered Mystical Companion peeking outside the Sunroom Window!
                    if !isDecoratingMode, !isFeatherWandMode, let visitorID = coordinator.currentWindowVisitorPetID {
                        let visits = coordinator.indoorState.windowVisitCounts[visitorID] ?? 0
                        SunroomWindowVisitorView(
                            petSpec: PetCatalog.pet(id: visitorID),
                            weather: coordinator.activeWeather,
                            visitCount: visits,
                            greetedToday: coordinator.hasGreetedWindowVisitorToday,
                            isPhotoMode: isPhotoMode
                        ) {
                            coordinator.greetWindowVisitor(petID: visitorID)
                        }
                        .position(x: stageW * 0.71, y: floorHorizonY - 46)
                        .offset(x: effectivePan * (reduceMotion ? 1 : 0.52))
                    }

                    // MARK: Layer 2 — Interactive 2.5D Depth-Sorted Floor Stage (Furniture + Free-Roaming Pets)
                    ZStack {
                        // Tap anywhere on the 2.5D wooden floor to call the nearest pet over!
                        // Hit area covers only the floor, so taps on the window wall (window visitor,
                        // curio shelf, pinned postcard) reach the views behind this layer.
                        Color.clear
                            .contentShape(FloorTapRegionShape(topY: floorHorizonY))
                            .onTapGesture { location in
                                guard !isDecoratingMode, !isPhotoMode else { return }
                                guard location.y >= floorHorizonY - 12 && location.y <= floorBottomY + 24 else { return }
                                let u = location.x / stageW
                                let depth = max(0.14, min(0.88, (location.y - floorHorizonY) / max(1, floorBottomY - floorHorizonY)))
                                HapticsEngine.shared.playBrushStrokeTick()
                                CozySoundEngine.shared.playPawTap()
                                roaming.callNearestPet(to: CGPoint(x: u, y: depth), now: now, useSprite: !reduceMotion)
                            }

                        // Golden foreshortened floor tap ripples
                        ForEach(roaming.floorRipples) { ripple in
                            let age = max(0, now.timeIntervalSince(ripple.createdAt))
                            let p = reduceMotion ? 0.0 : min(1.0, age / 1.1)
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

                        ForEach(reduceMotion ? [] : roaming.spriteFX.active(at: now)) { effect in
                            let uv = effect.position
                            let point = floorPoint(uv: uv, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let size = 44 * depthScale(for: uv.y)
                            let isGround = effect.kind == .dust || effect.kind == .floorRipple
                            SpriteFXLayer(effect: effect, date: now)
                                .frame(width: size, height: size)
                                .scaleEffect(y: effect.kind == .floorRipple ? 0.52 : 1)
                                .position(x: point.x, y: point.y - (isGround ? size * 0.16 : size * 1.35))
                                .zIndex(Double(uv.y * 1000) + (isGround ? -1 : 1))
                        }

                        // 2.5D Staggered Home Furnishings (depth-scaled, depth-sorted, & freely draggable in Decorate Mode!)
                        ForEach(coordinator.homeSpots, id: \.spotIndex) { spot in
                            let baseUV = roaming.resolvedSpotPosition(
                                for: spot.spotIndex,
                                verandaUnlocked: coordinator.ledger.verandaUnlocked
                            )
                            let uv = (draggingSpotIndex == spot.spotIndex ? draggingSpotUV : nil) ?? baseUV
                            let pt = floorPoint(uv: uv, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let scale = depthScale(for: uv.y)

                            VStack(spacing: 2) {
                                ZStack {
                                    if isDecoratingMode {
                                        let isSelected = (selectedDecorateSpotIndex == spot.spotIndex)
                                        Ellipse()
                                            .stroke(isSelected ? Color(hex: "#D98A36") : AppTheme.pawStrollChain, style: StrokeStyle(lineWidth: isSelected ? 3.0 : 2.0, dash: isSelected ? [] : [5, 4]))
                                            .fill(AppTheme.pawStrollChain.opacity(draggingSpotIndex == spot.spotIndex ? 0.28 : (isSelected ? 0.20 : 0.08)))
                                            .frame(width: 98, height: 36)
                                            .offset(y: 12)
                                    }
                                    if hidingSpotIndex == spot.spotIndex, let hidingPet {
                                        Button {
                                            onFoundHidingPet?(hidingPet, uv)
                                        } label: {
                                            SunroomPeekingEars()
                                                .frame(width: 26, height: 18)
                                                .frame(width: 36, height: 36)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        .offset(x: 33, y: -34)
                                        .accessibilityLabel("躲在家具後的小靈獸")
                                    }

                                    PaintedGoodiePropView(
                                        goodieID: spot.equippedGoodieID,
                                        hasLovedPatina: spot.hasLovedPatina,
                                        hasStitchedPatch: spot.hasStitchedPatch,
                                        isWide: spot.currentOccupantPetIDs.count > 1
                                    )
                                    .allowsHitTesting(isDecoratingMode)
                                }
                                let hideLabelInDecorate = isDecoratingMode && uv.y > 0.68 && selectedDecorateSpotIndex != spot.spotIndex && draggingSpotIndex != spot.spotIndex
                                if isDecoratingMode && !isPhotoMode && !hideLabelInDecorate {
                                    Text(spot.spotName)
                                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.forestTeal)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color(hex: "#FFFDF7").opacity(0.92))
                                                .overlay(Capsule().stroke(AppTheme.pawStrollChain, lineWidth: 1.3))
                                        )
                                }
                            }
                            .scaleEffect(scale * (draggingSpotIndex == spot.spotIndex ? 1.08 : 1.0))
                            .position(x: pt.x, y: pt.y + 8 * scale)
                            .zIndex(Double(uv.y * 1000.0) - (draggingSpotIndex == spot.spotIndex ? -50 : 10))
                            .gesture(TapGesture().onEnded { onTapSpot(spot) }, including: isDecoratingMode ? .all : .subviews)
                            .highPriorityGesture(
                                DragGesture(minimumDistance: 6, coordinateSpace: .named("sunroomFloor"))
                                    .onChanged { value in
                                        guard isDecoratingMode else { return }
                                        onTapSpot(spot)
                                        draggingSpotIndex = spot.spotIndex
                                        let u = max(0.10, min(0.90, value.location.x / stageW))
                                        let d = max(0.16, min(0.84, (value.location.y - floorHorizonY) / max(1, floorBottomY - floorHorizonY)))
                                        draggingSpotUV = CGPoint(x: u, y: d)
                                    }
                                    .onEnded { _ in
                                        guard isDecoratingMode else { return }
                                        if let newUV = draggingSpotUV {
                                            roaming.setCustomSpotPosition(spotIndex: spot.spotIndex, uv: newUV)
                                            HapticsEngine.shared.playBrushStrokeTick()
                                            CozySoundEngine.shared.playPawTap()
                                        }
                                        draggingSpotIndex = nil
                                        draggingSpotUV = nil
                                    },
                                including: isDecoratingMode ? .all : .none
                            )
                        }

                        // Live Interactive Rolling Stitched Cloth Ball across the 2.5D floor!
                        if !reduceMotion, let ball = roaming.rollingBall, let ballUV = ball.position(at: now) {
                            let bPt = floorPoint(uv: ballUV, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let bScale = depthScale(for: ballUV.y)
                            let spinDeg = now.timeIntervalSince(ball.startedAt) * 260.0
                            ZStack {
                                Ellipse()
                                    .fill(AppTheme.deepPineInk.opacity(0.18))
                                    .frame(width: 22 * bScale, height: 8 * bScale)
                                    .offset(y: 10 * bScale)
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color(hex: "#F6A88A"), Color(hex: "#D46B52")],
                                            center: .topLeading,
                                            startRadius: 2,
                                            endRadius: 12 * bScale
                                        )
                                    )
                                    .frame(width: 20 * bScale, height: 20 * bScale)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: "#FFF8EC").opacity(0.75), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                                            .padding(3)
                                    )
                                    .rotationEffect(.degrees(spinDeg))
                            }
                            .position(x: bPt.x, y: bPt.y - 6 * bScale)
                            .zIndex(Double(ballUV.y * 1000.0) + 5)
                            .onTapGesture {
                                HapticsEngine.shared.playDogBallRoll()
                                CozySoundEngine.shared.playPawTap()
                                _ = roaming.tossClothBall(now: now)
                            }
                        }

                        // Clickable Origami Paper Charms left on the wooden floor by Juniper (pet.02 DemonCat)!
                        ForEach(roaming.origamiDrops) { drop in
                            let dPt = floorPoint(uv: drop.position, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let dScale = depthScale(for: drop.position.y)
                            Button {
                                if let collected = roaming.collectOrigamiDrop(id: drop.id) {
                                    HapticsEngine.shared.playCurioUnpack()
                                    CozySoundEngine.shared.playCompassChime()
                                    onCollectOrigami?(collected)
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#F2C86B").opacity(0.28))
                                        .frame(width: 34 * dScale, height: 34 * dScale)
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 15 * dScale, weight: .bold))
                                        .foregroundStyle(Color(hex: "#B84A62"))
                                        .rotationEffect(.degrees(-24))
                                        .padding(6)
                                        .background(Color(hex: "#FFFDF7"), in: RoundedRectangle(cornerRadius: 7))
                                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#D4A352"), lineWidth: 1.2))
                                        .shadow(color: AppTheme.deepPineInk.opacity(0.22), radius: 3, y: 2)
                                }
                            }
                            .buttonStyle(TactileGameButtonStyle())
                            .accessibilityLabel("拾起杜松的摺紙符咒")
                            .position(x: dPt.x, y: dPt.y - 4 * dScale)
                            .zIndex(Double(drop.position.y * 1000.0) + 12)
                        }

                        // Physical Interactive Tea & Biscuit Tray right on the foreground floor (Swirl to Brew!)
                        if !isDecoratingMode && !isFeatherWandMode {
                            let teaUV = SunroomRoamingEngine.teaStationUV
                            let teaPt = floorPoint(uv: teaUV, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let teaScale = depthScale(for: teaUV.y)
                            InWorldTeaStationView(
                                stageDate: now,
                                recipe: activeTeaRecipe,
                                isPhotoMode: isPhotoMode,
                                onCycleRecipe: { onCycleTeaRecipe?() },
                                onBrewCompleted: { brewed in
                                    onBrewTeaInWorld?(brewed)
                                }
                            )
                            .allowsHitTesting(!isPhotoMode)
                            .scaleEffect(teaScale * 0.90)
                            .position(x: teaPt.x, y: teaPt.y - 16 * teaScale)
                            .zIndex(Double(teaUV.y * 1000.0) + 18)

                            // Physical Origami Craft Stool by the sunny left window (Tap to Fold in-world!)
                            let origUV = CGPoint(x: 0.30, y: 0.46)
                            let origPt = floorPoint(uv: origUV, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let origScale = depthScale(for: origUV.y)
                            InWorldOrigamiTableView(isPhotoMode: isPhotoMode) {
                                onTapOrigamiTable?()
                            }
                            .allowsHitTesting(!isPhotoMode)
                            .scaleEffect(origScale)
                            .position(x: origPt.x, y: origPt.y - 10 * origScale)
                            .zIndex(Double(origUV.y * 1000.0) + 10)

                            // Physical Porch Adventure Satchel near the right doorway (Direct Solo Errands!)
                            let doorUV = SunroomRoamingEngine.porchStationUV
                            let doorPt = floorPoint(uv: doorUV, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let doorScale = depthScale(for: doorUV.y)
                            if coordinator.isFeatureUnlocked(.errands) {
                                InWorldPorchSatchelView(
                                    activeErrand: isPhotoMode ? nil : coordinator.indoorState.activeErrand,
                                    now: now,
                                    coinBalance: coordinator.ledger.coinBalance,
                                    isPhotoMode: isPhotoMode,
                                    onSendSupply: { pack in onSendErrandSupply?(pack) },
                                    onCollectReturned: { onCollectErrandInWorld?() }
                                )
                                .id(isPhotoMode)
                                .allowsHitTesting(!isPhotoMode)
                                .scaleEffect(doorScale)
                                .position(x: doorPt.x, y: doorPt.y - 24 * doorScale)
                                .zIndex(Double(doorUV.y * 1000.0) + 22)
                            }

                            // Direct In-World Mystical Courtship Nesting Heart (♂ × ♀) when an eligible pair shares the room!
                            if !isPhotoMode,
                               coordinator.isFeatureUnlocked(.nesting),
                               let pair = coordinator.eligibleNestingPairs.first,
                               coordinator.indoorState.offsprings.filter({ $0.growthStage != .grown }).count < 2 {
                                let nestUV = CGPoint(x: 0.50, y: 0.43)
                                let nestPt = floorPoint(uv: nestUV, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                                Button {
                                    onStartCourtshipNest?(pair.fatherID, pair.motherID)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 10.5, weight: .bold))
                                            .foregroundStyle(Color(hex: "#D96B7E"))
                                        Text("\(coordinator.displayName(for: pair.fatherID)) × \(coordinator.displayName(for: pair.motherID)) 結緣築巢")
                                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color(hex: "#4A2D36"))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(hex: "#FFF5F7").opacity(0.95), in: Capsule())
                                    .overlay(Capsule().stroke(Color(hex: "#E695A4"), lineWidth: 1.2))
                                    .shadow(color: Color(hex: "#D96B7E").opacity(0.24), radius: 5, y: 2)
                                }
                                .buttonStyle(TactileGameButtonStyle(pressScale: 0.92, pressOffsetY: 1))
                                .position(x: nestPt.x, y: nestPt.y - 22)
                                .zIndex(1400)
                            }
                        }

                        // Raised Mystical Eggs & Hybrid Hatchlings living on the 2.5D Sunroom floor!
                        let nurseryFloorSpots: [CGPoint] = [
                            CGPoint(x: 0.36, y: 0.70),
                            CGPoint(x: 0.63, y: 0.72),
                            CGPoint(x: 0.49, y: 0.80)
                        ]
                        ForEach(Array(coordinator.sunroomOffsprings.prefix(3).enumerated()), id: \.element.id) { idx, child in
                            let cUV = nurseryFloorSpots[idx % nurseryFloorSpots.count]
                            let cPt = floorPoint(uv: cUV, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let cScale = depthScale(for: cUV.y) * child.growthStage.sunroomScaleMultiplier

                            Button {
                                if !isDecoratingMode && !isFeatherWandMode {
                                    HapticsEngine.shared.playPawRangeCue()
                                    CozySoundEngine.shared.playPetChirp()
                                    onTapOffspring?(child)
                                }
                            } label: {
                                HybridOffspringRigView(
                                    offspring: child,
                                    weather: coordinator.activeWeather,
                                    size: 98
                                )
                            }
                            .overlay(alignment: .bottom) {
                                if !isPhotoMode {
                                    Text(child.growthStage == .egg ? "✦ 奇幻靈卵" : "\(child.name) \(child.gender.symbol)")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#4A3628"))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: "#FFFDF7").opacity(0.92), in: Capsule())
                                        .overlay(Capsule().stroke(Color(hex: child.gender.badgeHex).opacity(0.55), lineWidth: 0.9))
                                        .allowsHitTesting(false)
                                }
                            }
                            .buttonStyle(.plain)
                            .allowsHitTesting(!isPhotoMode)
                            .scaleEffect(cScale)
                            .position(x: cPt.x, y: cPt.y - 24 * cScale)
                            .zIndex(Double(cUV.y * 1000.0) + 6)
                            .accessibilityLabel("\(child.name)，點擊打開奇幻育兒窩")
                        }

                        // 2.5D Free-Roaming Hand-Animated Pets (pure 60fps interpolated position + species magical auras!)
                        ForEach(visibleActors, id: \.petID) { actor in
                            let spec = PetCatalog.pet(id: actor.petID)
                            let resident = coordinator.resident(for: actor.petID)
                            let liveUV = reduceMotion ? actor.position : actor.interpolatedPosition(at: now)
                            let pt = floorPoint(uv: liveUV, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let depth = depthScale(for: liveUV.y)
                            let petMentorship = coordinator.teachingIntentions.first {
                                $0.state == .demonstrated &&
                                ($0.mentorPetID == actor.petID || $0.learnerPetID == actor.petID)
                            }
                            let isExcited = (bouncingPetID == actor.petID) || (now < actor.tapExcitedUntil)
                            let isInBox: Bool = { if case .cozyInBox = actor.behavior { return true }; return false }()
                            let petAction: PetPlayfulAction = {
                                if bouncingPetID == actor.petID { return .bellyBoop }
                                switch actor.behavior {
                                case .walking: return .walking
                                case .napping: return .cozyNap
                                case .greetingFriend: return .bellyBoop
                                case .playingBall: return .pounceHop
                                case .cozyInBox: return .idle
                                case .sitting: return .idle
                                }
                            }()

                            let scale = depth * (isInBox ? 0.86 : 1.0)
                            Button {
                                onTapPet(actor.petID)
                            } label: {
                                ZStack {
                                    // Match the canvas and shader's positive-X displacement per unit of Y.
                                    let shadowDrop: CGFloat = coordinator.activeWeather == .clearMorning ? 12 : 8
                                    let shadowRun = SunroomLight.runPerRise * shadowDrop * stageW / max(1, viewH)
                                    Ellipse()
                                        .fill(AppTheme.deepPineInk.opacity(coordinator.activeWeather.isRainy ? 0.08 : 0.15))
                                        .frame(width: 74, height: 16)
                                        .rotationEffect(.radians(atan2(shadowDrop, shadowRun)))
                                        .blur(radius: 5)
                                        .offset(x: shadowRun, y: 47 + shadowDrop)
                                        .allowsHitTesting(false)

                                    // Warm golden hearth-glow pool beneath napping DragonCat (pet.03)!
                                    if spec.kind == .dragonCat && actor.isNapping {
                                        Ellipse()
                                            .fill(
                                                RadialGradient(
                                                    colors: [Color(hex: "#F5B864").opacity(0.36), .clear],
                                                    center: .center,
                                                    startRadius: 8,
                                                    endRadius: 58
                                                )
                                            )
                                            .frame(width: 112, height: 34)
                                            .offset(y: 44)
                                            .allowsHitTesting(false)
                                    }

                                    // Species-specific magical room aura (Dragon hearth embers, Spirit cloud puffs, Antler forest leaves!)
                                    if !reduceMotion {
                                        SpeciesRoomMagicAuraCanvas(petKind: spec.kind, weather: coordinator.activeWeather, time: now.timeIntervalSinceReferenceDate)
                                            .frame(width: 126, height: 126)
                                            .allowsHitTesting(false)
                                    }

                                    ProceduralPetRigView(
                                        pet: spec,
                                        outfitID: resident?.activeOutfitID,
                                        pose: actor.isNapping ? .resting : .notice,
                                        weatherMode: coordinator.activeWeather,
                                        isHappySquint: isExcited || isInBox || ({ if case .greetingFriend = actor.behavior { return true }; return false }()),
                                        mentorshipParticle: petMentorship.flatMap { HabitFamily(rawValue: $0.habitFamilyID) },
                                        tapBounceScale: bouncingPetID == actor.petID ? 1.0 : 0.0,
                                        playfulAction: petAction,
                                        actionTriggerDate: actor.tapExcitedUntil.addingTimeInterval(-1.2),
                                        stageDate: now,
                                        poseTransition: actor.poseTransition,
                                        poseStartedAt: bouncingPetID == actor.petID ? nil : actor.poseStartedAt,
                                        locomotion: actor.direction,
                                        gaitRate: actor.gaitRate,
                                        facingRight: actor.facingRight,
                                        presentationScale: scale,
                                        onCelEvent: { event, date in
                                            if event == "footContact" || event == "land" {
                                                roaming.emitCelDust(petID: actor.petID, at: date)
                                            }
                                        }
                                    )
                                    .frame(width: 118, height: 118)

                                    // Foreground cardboard front-wall occlusion rim when a cat tucks INSIDE the bakery box!
                                    if isInBox {
                                        BakeryBoxForegroundRimView()
                                            .offset(y: 36)
                                            .allowsHitTesting(false)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(coordinator.displayName(for: actor.petID))，點擊互動照護")
                            .allowsHitTesting(!isDecoratingMode && !isFeatherWandMode && !isPhotoMode)
                            .overlay(alignment: .top) {
                                if !isPhotoMode && !isDecoratingMode && !isFeatherWandMode {
                                    petCallout(
                                        mentorship: petMentorship,
                                        skitPartner: skitPair?.host == actor.petID ? skitPair?.partner : nil,
                                        petID: actor.petID,
                                        speech: actor.speechBubble,
                                        x: pt.x,
                                        scale: scale,
                                        viewportLeft: viewportLeft,
                                        viewWidth: viewW
                                    )
                                    .alignmentGuide(.top) { $0[.bottom] + 2 }
                                }
                            }
                            .scaleEffect(scale)
                            .position(x: pt.x, y: pt.y - (isInBox ? 32 : 44) * depth)
                            .id(reduceMotion ? "\(liveUV.x),\(liveUV.y)" : actor.petID)
                            .transition(.opacity)
                            .animation(reduceMotion ? AppTheme.Motion.reduced : nil, value: liveUV)
                            .zIndex(Double(liveUV.y * 1000.0))
                        }

                        // Live Feather-Wand Interactive Floor Chase Mode (`逗貓棒追逐`)
                        if isFeatherWandMode {
                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .named("sunroomFloor"))
                                        .onChanged { value in
                                            let pt = value.location
                                            wandScreenPoint = pt
                                            if let prev = lastWandPoint {
                                                wandChaseDistance += hypot(pt.x - prev.x, pt.y - prev.y)
                                            }
                                            lastWandPoint = pt

                                            let clampedY = max(floorHorizonY + 6, min(floorBottomY, pt.y))
                                            let u = max(0.08, min(0.92, pt.x / stageW))
                                            let depth = max(0.14, min(0.88, (clampedY - floorHorizonY) / max(1, floorBottomY - floorHorizonY)))
                                            if now.timeIntervalSince(lastWandCallDate) >= 0.18 {
                                                lastWandCallDate = now
                                                roaming.chaseFeatherWand(at: CGPoint(x: u, y: depth), now: now)
                                                HapticsEngine.shared.playBrushStrokeTick()
                                            }
                                            if wandChaseDistance >= 340 {
                                                wandChaseDistance = 0
                                                onCompleteFeatherWandChase?()
                                            }
                                        }
                                        .onEnded { _ in
                                            wandScreenPoint = nil
                                            lastWandPoint = nil
                                        }
                                )
                                .zIndex(1900)

                            if let wandPt = wandScreenPoint, !reduceMotion {
                                FeatherWandRibbonOverlay(tipPoint: wandPt, time: now.timeIntervalSinceReferenceDate)
                                    .allowsHitTesting(false)
                                    .zIndex(2000)
                            }
                        }

                        // 60fps Floating In-World Reaction Bursts (+1 幣, ♡ 溫柔, ✦ 破殼, ♪ 叮噹)
                        ForEach(isPhotoMode ? [] : roaming.floatingBursts) { burst in
                            let age = max(0, now.timeIntervalSince(burst.createdAt))
                            let p = min(1.0, age / 1.85)
                            let bPt = floorPoint(uv: burst.position, stageW: stageW, horizonY: floorHorizonY, bottomY: floorBottomY)
                            let fadeAlpha = p < 0.15 ? (p / 0.15) : max(0, 1.0 - (p - 0.15) / 0.85)
                            Text(burst.text)
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: burst.colorHex), in: Capsule())
                                .overlay(Capsule().stroke(Color(hex: "#FFFDF8").opacity(0.85), lineWidth: 1.2))
                                .shadow(color: AppTheme.deepPineInk.opacity(0.22), radius: 4, y: 2)
                                .position(x: bPt.x, y: bPt.y - 36 - CGFloat(p) * 58)
                                .opacity(fadeAlpha)
                                .scaleEffect(0.85 + 0.20 * sin(min(1.0, p * 3.0) * .pi * 0.5))
                                .zIndex(2100)
                                .allowsHitTesting(false)
                        }

                        // Empty sunroom welcoming guide when the player hasn't invited a pet yet
                        if !isPhotoMode && roaming.actors.isEmpty {
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
                    .coordinateSpace(name: "sunroomFloor")
                    .onChange(of: timeline.date) { _, newDate in
                        // Throttled internally to 4Hz (0.25s) so SwiftUI never churns @Observable at 60Hz!
                        roaming.tick(
                            now: newDate,
                            spots: coordinator.homeSpots,
                            verandaUnlocked: coordinator.ledger.verandaUnlocked,
                            weather: coordinator.activeWeather
                        )
                    }
                    .offset(x: effectivePan)

                    // MARK: Layer 3 — Foreground Out-of-Focus Botanical & Timber Depth Frame (1.32x Parallax!)
                    ForegroundBotanicalParallaxOverlay(weather: coordinator.activeWeather)
                        .frame(width: viewW, height: viewH)
                        .offset(x: effectivePan * (reduceMotion ? 1 : 1.32))
                        .allowsHitTesting(false)
                }
                .frame(width: viewW, height: viewH)
                .clipped()
            }
        }
        .ignoresSafeArea()
    }

    private func nearbyRoommates(
        _ actors: [SunroomRoamingEngine.RoamingPetActor],
        at date: Date
    ) -> (host: String, partner: String)? {
        let positioned = actors.sorted { $0.petID < $1.petID }.map {
            (id: $0.petID, uv: reduceMotion ? $0.position : $0.interpolatedPosition(at: date))
        }
        var closest: (host: String, partner: String)?
        var shortestDistance: CGFloat = 0.26
        for (index, first) in positioned.enumerated() {
            for second in positioned.dropFirst(index + 1) {
                let distance = hypot(first.uv.x - second.uv.x, first.uv.y - second.uv.y)
                if distance < shortestDistance {
                    shortestDistance = distance
                    closest = (host: first.id, partner: second.id)
                }
            }
        }
        return closest
    }

    @ViewBuilder
    private func petCallout(
        mentorship: TeachingIntention?,
        skitPartner: String?,
        petID: String,
        speech: String?,
        x: CGFloat,
        scale: CGFloat,
        viewportLeft: CGFloat,
        viewWidth: CGFloat
    ) -> some View {
        if let mentorship {
            CutePlushButton(
                title: "記下傳承",
                tone: .butterHoney,
                fontSize: 10,
                horizontalPadding: 8,
                verticalPadding: 4,
                icon: { Image(systemName: "sparkles").font(.system(size: 10, weight: .bold)) },
                action: { onCompleteMentorship(mentorship) }
            )
        } else if let skitPartner {
            Button {
                onTriggerSkit?(skitPartner, petID)
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#966118"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#FFF6DE").opacity(0.93), in: Capsule())
                    .shadow(color: Color(hex: "#F4C56A").opacity(0.65), radius: 5)
                    .frame(minWidth: 40, minHeight: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("觀看室友互動")
        } else if let speech {
            // The bubble has a 168pt text cap plus 20pt padding before the pet's scale.
            let width = min(188, max(0, (viewWidth - 16) / scale))
            let inset = width * scale / 2 + 8
            let clampedX = min(max(x, viewportLeft + inset), viewportLeft + viewWidth - inset)
            SunroomPetSpeechBubble(text: speech)
                .frame(width: width)
                .offset(x: (clampedX - x) / scale)
                .allowsHitTesting(false)
        }
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

private enum SunroomLight {
    // Also used by sunroomAmbient in PaperGrainAndLUT.metal, in normalized stage coordinates.
    static let runPerRise: CGFloat = 0.64
}

private struct SunroomPeekingEars: View {
    var body: some View {
        Canvas { context, size in
            for side: CGFloat in [-1, 1] {
                let x = size.width * 0.44 + side * 5
                let ear = Path { path in
                    path.move(to: CGPoint(x: x - 4, y: 15))
                    path.addQuadCurve(to: CGPoint(x: x + side * 2, y: 3), control: CGPoint(x: x - 4, y: 4))
                    path.addQuadCurve(to: CGPoint(x: x + 4, y: 15), control: CGPoint(x: x + 4, y: 5))
                    path.closeSubpath()
                }
                context.fill(ear, with: .color(Color(hex: "#926D54")))
                context.stroke(ear, with: .color(AppTheme.warmPaper.opacity(0.7)), lineWidth: 0.8)
            }
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkle")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color(hex: "#FFE5A2"))
        }
    }
}

/// One-point cedar planks, a foreshortened braided rug, and window light.
private struct PerspectiveCedarFloorCanvas: View {
    let horizonY: CGFloat
    let weather: WeatherMode
    let theme: SeasonalRoomTheme
    let verandaUnlocked: Bool
    let lightOffsetX: CGFloat

    var body: some View {
        Canvas { context, size in
            let floor = CGRect(x: 0, y: horizonY, width: size.width, height: size.height - horizonY)
            let board = CGRect(x: 0, y: horizonY - 10, width: size.width, height: 10)
            context.fill(Path(board), with: .linearGradient(
                Gradient(colors: [Color(hex: "#A17A55"), Color(hex: "#745134")]),
                startPoint: CGPoint(x: 0, y: board.minY), endPoint: CGPoint(x: 0, y: board.maxY)
            ))

            var wood = context
            wood.clip(to: Path(floor))
            drawPlanks(in: wood, floor: floor)
            drawRug(in: wood, floor: floor)
            drawLight(in: wood, floor: floor)
        }
        .allowsHitTesting(false)
    }

    private func drawPlanks(in context: GraphicsContext, floor: CGRect) {
        let width = floor.width
        let top = CGPoint(x: 0, y: floor.minY)
        let bottom = CGPoint(x: 0, y: floor.maxY)
        let tones = [
            Color(hex: "#F7C98B").opacity(0.13),
            Color(hex: "#8B4A2A").opacity(0.09),
            Color(hex: "#FFE3AB").opacity(0.10),
            Color(hex: "#B36D41").opacity(0.10),
            Color.clear
        ]
        context.fill(Path(floor), with: .linearGradient(
            Gradient(colors: [Color(hex: theme.floorTopHex), Color(hex: theme.floorBottomHex)]),
            startPoint: top, endPoint: bottom
        ))

        let plankCount = verandaUnlocked ? 16 : 12
        for plank in -4..<(plankCount + 4) {
            func point(_ across: CGFloat, _ depth: CGFloat) -> CGPoint {
                let bottomX = (CGFloat(plank) + across) * width / CGFloat(plankCount)
                let spread: CGFloat = 0.36 + depth * 0.64
                return CGPoint(x: width * 0.5 + (bottomX - width * 0.5) * spread,
                               y: floor.minY + depth * floor.height)
            }

            let stagger = CGFloat((plank + 4) % 3) * 0.065
            let ends: [CGFloat] = [0, 0.10 + stagger, 0.30 + stagger, 0.56 + stagger, 0.90 + stagger * 0.5, 1]
            for row in 0..<(ends.count - 1) {
                let near = ends[row]
                let far = ends[row + 1]
                let segment = Path { path in
                    path.move(to: point(0, near))
                    path.addLines([point(1, near), point(1, far), point(0, far)])
                    path.closeSubpath()
                }
                context.fill(segment, with: .color(tones[((plank + 4) * 7 + row * 3) % tones.count]))

                if row > 0 {
                    let endJoin = Path { path in
                        path.move(to: point(0, near))
                        path.addLine(to: point(1, near))
                    }
                    context.stroke(endJoin, with: .color(Color(hex: "#573824").opacity(0.18)), lineWidth: 0.7)
                }

                let span = far - near
                for grain in 1...3 {
                    let x = CGFloat(grain) / 4 + CGFloat((row + plank + 4) % 3 - 1) * 0.05
                    let wave = Path { path in
                        path.move(to: point(x, near + span * 0.08))
                        path.addCurve(to: point(x - 0.08, far - span * 0.08),
                                      control1: point(x - 0.28, near + span * 0.38),
                                      control2: point(x + 0.20, near + span * 0.61))
                    }
                    context.stroke(wave, with: .color(Color(hex: "#FFF1D1").opacity(0.13)), lineWidth: 0.65)
                }
            }

            let seam = Path { path in
                path.move(to: point(0, 0))
                path.addLine(to: point(0, 1))
            }
            context.stroke(seam, with: .color(Color(hex: "#573824").opacity(0.25)), lineWidth: 0.9)
        }

        if verandaUnlocked {
            let deckX = width * 0.72
            let deck = CGRect(x: deckX, y: floor.minY, width: width - deckX, height: floor.height)
            context.fill(Path(deck), with: .linearGradient(
                Gradient(colors: [Color(hex: "#735843").opacity(0.22), .clear]),
                startPoint: CGPoint(x: deck.minX, y: 0), endPoint: CGPoint(x: deck.maxX, y: 0)
            ))
        }

        context.fill(Path(floor), with: .linearGradient(
            Gradient(colors: [Color(hex: "#3B2412").opacity(0.33), .clear]),
            startPoint: top, endPoint: CGPoint(x: 0, y: floor.minY + 25)
        ))
    }

    private func drawRug(in context: GraphicsContext, floor: CGRect) {
        let center = CGPoint(x: floor.midX, y: floor.minY + floor.height * 0.46)
        let rx = min(134, floor.width * 0.24)
        let ry = rx * 0.32
        func rimPoint(_ angle: CGFloat, inset: CGFloat = 0) -> CGPoint {
            let scallop = cos(angle * 28) * 1.8 - inset
            return CGPoint(x: center.x + cos(angle) * (rx + scallop),
                           y: center.y + sin(angle) * (ry + scallop * 0.48))
        }

        let bounds = CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2)
        var shade = context
        shade.addFilter(.blur(radius: 3))
        shade.fill(Path(ellipseIn: bounds.insetBy(dx: -3, dy: -2).offsetBy(dx: 2, dy: 4)),
                   with: .color(Color(hex: "#4A2E18").opacity(0.28)))

        for side: CGFloat in [0, .pi] {
            for strand in -6...6 {
                let angle = side + CGFloat(strand) * 0.055
                let root = rimPoint(angle, inset: 2)
                let tip = CGPoint(x: root.x + cos(angle) * CGFloat(7 + abs(strand % 3)),
                                  y: root.y + sin(angle) * 5 + 1)
                let fringe = Path { path in
                    path.move(to: root)
                    path.addQuadCurve(to: tip, control: CGPoint(x: (root.x + tip.x) / 2, y: root.y + 2))
                }
                context.stroke(fringe, with: .color(Color(hex: "#F2DAB4").opacity(0.9)),
                               style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }
        }

        let edge = Path { path in
            path.move(to: rimPoint(0))
            for step in 1...224 {
                path.addLine(to: rimPoint(CGFloat(step) / 224 * .pi * 2))
            }
            path.closeSubpath()
        }
        context.fill(edge, with: .color(Color(hex: "#71888A")))
        let braids: [(CGFloat, String)] = [
            (0.90, "#C0B599"), (0.80, "#E7D1AF"), (0.68, "#C38A70"),
            (0.55, "#DBC19B"), (0.43, "#EBDDCA"), (0.30, "#EEE3CF")
        ]
        for (scale, hex) in braids {
            let ring = Path(ellipseIn: bounds.insetBy(dx: rx * (1 - scale), dy: ry * (1 - scale)))
            context.fill(ring, with: .color(Color(hex: hex)))
            context.stroke(ring, with: .color(Color(hex: "#6B4B36").opacity(0.25)),
                           style: StrokeStyle(lineWidth: 1.7, dash: [2, 3]))
        }
    }

    private func drawLight(in context: GraphicsContext, floor: CGRect) {
        let height = floor.maxY
        let width = floor.width
        let startY = floor.minY
        let endY = startY + floor.height * 0.72
        let dimmed = weather == .overcast || theme == .rainySeason || theme == .winterLamp
        let paneColor = Color(hex: weather == .dusk ? "#FFD395" : "#FFF4CE")
        var reflected = context
        reflected.addFilter(.blur(radius: dimmed || weather.isRainy ? 7 : 2.5))

        if weather != .lightRain {
            for paneCenter: CGFloat in [0.25, 0.43] {
                func paneX(at y: CGFloat) -> CGFloat {
                    (paneCenter + SunroomLight.runPerRise * (y / height - 0.06)) * width + lightOffsetX
                }
                let paneTop = startY - 3
                let leftTop = paneX(at: paneTop) - width * 0.065
                let leftBottom = paneX(at: endY) - width * 0.065
                let span = width * 0.13
                let pane = Path { path in
                    path.move(to: CGPoint(x: leftTop, y: paneTop))
                    path.addLines([
                        CGPoint(x: leftTop + span, y: paneTop),
                        CGPoint(x: leftBottom + span, y: endY),
                        CGPoint(x: leftBottom, y: endY)
                    ])
                    path.closeSubpath()
                }
                reflected.fill(pane, with: .linearGradient(
                    Gradient(colors: [paneColor.opacity(dimmed ? 0.18 : 0.38), .clear]),
                    startPoint: CGPoint(x: 0, y: startY), endPoint: CGPoint(x: 0, y: endY)
                ))
            }
        }

        if theme == .rainySeason || weather.isRainy {
            let center = CGPoint(x: floor.midX + width * 0.04, y: startY + floor.height * 0.16)
            let mist = CGRect(x: center.x - width * 0.25, y: center.y - 14, width: width * 0.5, height: 28)
            reflected.fill(Path(ellipseIn: mist), with: .radialGradient(
                Gradient(colors: [Color(hex: "#E3EDF0").opacity(0.39), .clear]),
                center: center, startRadius: 0, endRadius: width * 0.23
            ))
        }

        if theme == .autumnCedar {
            context.fill(Path(floor), with: .radialGradient(
                Gradient(colors: [Color(hex: "#DC7941").opacity(0.23), .clear]),
                center: CGPoint(x: width * 0.46, y: startY + floor.height * 0.50),
                startRadius: 10, endRadius: width * 0.42
            ))
        }

        if theme == .winterLamp || weather == .dusk || weather.isRainy {
            let center = CGPoint(x: width * 0.30, y: startY + floor.height * 0.56)
            let pool = CGRect(x: center.x - width * 0.23, y: center.y - 42, width: width * 0.46, height: 84)
            reflected.fill(Path(ellipseIn: pool), with: .radialGradient(
                Gradient(colors: [Color(hex: "#FFCE7A").opacity(0.52), Color(hex: "#F0A758").opacity(0.18), .clear]),
                center: center, startRadius: 4, endRadius: width * 0.22
            ))
        }
    }
}

private struct ForegroundBotanicalParallaxOverlay: View {
    let weather: WeatherMode

    var body: some View {
        Canvas { context, size in
            let leaf = weather.isRainy ? Color(hex: "#2F5447") : Color(hex: "#4D7451")
            var soft = context
            soft.addFilter(.blur(radius: 0.65))
            for side: CGFloat in [-1, 1] {
                let isLeft = side > 0
                let root = CGPoint(x: isLeft ? -14 : size.width + 14, y: size.height - 36)
                for stem in 0..<3 {
                    let reach = CGFloat(36 + stem * 18)
                    let lift = CGFloat(128 - stem * 32)
                    func point(_ t: CGFloat) -> CGPoint {
                        CGPoint(x: root.x + side * reach * t * (1.68 - t * 0.68),
                                y: root.y - lift * t)
                    }

                    let stalk = Path { path in
                        path.move(to: root)
                        for step in 1...12 { path.addLine(to: point(CGFloat(step) / 12)) }
                    }
                    soft.stroke(stalk, with: .color(leaf.opacity(0.44)), lineWidth: 1.3)

                    for step in 2...8 {
                        let t = CGFloat(step) / 9
                        let base = point(t)
                        let span = 18 * (1 - t * 0.70)
                        for edge: CGFloat in [-1, 1] {
                            let tip = CGPoint(x: base.x + edge * span, y: base.y - 10 + t * 4)
                            let leaflet = Path { path in
                                path.move(to: base)
                                path.addQuadCurve(to: tip, control: CGPoint(x: base.x + edge * span * 0.27, y: tip.y - 7))
                                path.addQuadCurve(to: base, control: CGPoint(x: tip.x, y: base.y + 3))
                                path.closeSubpath()
                            }
                            soft.fill(leaflet, with: .color(leaf.opacity(0.27 + Double(t) * 0.14)))
                        }
                    }
                }
            }

            let eave = Path { path in
                path.move(to: .zero)
                path.addLines([CGPoint(x: size.width, y: 0), CGPoint(x: size.width, y: 25)])
                path.addQuadCurve(to: CGPoint(x: 0, y: 25), control: CGPoint(x: size.width / 2, y: -8))
                path.closeSubpath()
            }
            context.fill(eave, with: .linearGradient(
                Gradient(colors: [Color(hex: "#553820").opacity(0.38), .clear]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: 26)
            ))
        }
    }
}

/// Sunlit wooden windowsill shelf displaying up to 6 tappable foraged street curios inside the 2.5D Sunroom!
private struct WindowsillCurioShelfView: View {
    let curios: [ForagedCurioEntry]
    let onTapCurio: (ForagedCurioEntry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(curios) { entry in
                    Button {
                        onTapCurio(entry)
                    } label: {
                        PaintedCurioStampView(curioID: entry.curioID, size: 26)
                            .shadow(color: AppTheme.deepPineInk.opacity(0.24), radius: 2, y: 1)
                    }
                    .buttonStyle(TactileGameButtonStyle(pressScale: 0.88, pressOffsetY: 1))
                    .accessibilityLabel(CurioCatalog.curio(id: entry.curioID).name)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 2)

            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#B58454"), Color(hex: "#7D5430")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: CGFloat(curios.count) * 34 + 26, height: 7)
                .shadow(color: Color(hex: "#3B2412").opacity(0.30), radius: 3, y: 2)
        }
    }
}

/// Foreground cardboard front-wall + folded rim occluding a cat's belly so it visibly sits INSIDE the bakery box!
private struct BakeryBoxForegroundRimView: View {
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#E4C498"))
                .frame(width: 82, height: 8)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#8A6238"), lineWidth: 1.1))
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#D5AE7C"), Color(hex: "#BC915D")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 78, height: 34)
                .overlay(
                    Text("麵包坊")
                        .font(.system(size: 8.5, weight: .bold, design: .serif))
                        .foregroundStyle(Color(hex: "#6F4B2A").opacity(0.72))
                )
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#7A5530"), lineWidth: 1.2))
                .shadow(color: AppTheme.deepPineInk.opacity(0.22), radius: 4, y: 2)
        }
    }
}

/// Mythical species ambient room magic (DragonCat hearth embers, SpiritHound cloud puffs, MarshHound leaf petals, ImpHound wisp glow!)
private struct SpeciesRoomMagicAuraCanvas: View {
    let petKind: PetSpeciesKind
    let weather: WeatherMode
    let time: Double

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width * 0.5
            let cy = size.height * 0.56
            switch petKind {
            case .dragonCat:
                // Warm drifting hearth embers (brighter on rainy days!)
                let count = weather.isRainy ? 5 : 3
                for i in 0..<count {
                    let phase = (time * 0.36 + Double(i) / Double(count)).truncatingRemainder(dividingBy: 1.0)
                    let px = cx + CGFloat(sin(time * 1.1 + Double(i) * 2.1)) * 22
                    let py = cy + 16 - CGFloat(phase) * 58
                    let r = 2.6 * (1.0 - CGFloat(phase) * 0.5)
                    let alpha = sin(phase * .pi) * (weather.isRainy ? 0.78 : 0.52)
                    ctx.fill(Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                             with: .color(Color(hex: "#F29D4B").opacity(alpha)))
                }
            case .spiritHound:
                // Soft drifting silver cloud wisps
                for i in 0..<3 {
                    let phase = (time * 0.24 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1.0)
                    let px = cx - 18 + CGFloat(phase) * 36
                    let py = cy + 8 - CGFloat(sin(phase * .pi)) * 18
                    let alpha = sin(phase * .pi) * 0.38
                    ctx.fill(Path(ellipseIn: CGRect(x: px - 7, y: py - 4, width: 14, height: 8)),
                             with: .color(Color.white.opacity(alpha)))
                }
            case .marshHound:
                // Tiny forest leaf motes drifting gently
                for i in 0..<3 {
                    let phase = (time * 0.28 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1.0)
                    let px = cx + CGFloat(cos(time * 0.9 + Double(i) * 2.0)) * 26
                    let py = cy - 18 + CGFloat(phase) * 36
                    let alpha = sin(phase * .pi) * 0.48
                    ctx.fill(Path(ellipseIn: CGRect(x: px - 3.5, y: py - 2, width: 7, height: 4)),
                             with: .color(Color(hex: "#679B6E").opacity(alpha)))
                }
            case .impHound:
                // Gentle dusk blue will-o'-wisp halo
                let glowAlpha = weather == .dusk ? 0.26 : 0.14
                let pulse = 1.0 + 0.12 * sin(time * 1.4)
                let r = CGFloat(24.0 * pulse)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx + 22 - r * 0.5, y: cy - 10 - r * 0.5, width: r, height: r)),
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: "#8CC8FF").opacity(glowAlpha), .clear]),
                        center: CGPoint(x: cx + 22, y: cy - 10),
                        startRadius: 1,
                        endRadius: r * 0.55
                    )
                )
            default:
                break
            }
        }
    }
}

/// Gentle glowing amber dusk fireflies / lantern motes drifting slowly through the 2.5D Sunroom at twilight!
private struct DuskFireflyMotesOverlay: View {
    let stageDate: Date
    var body: some View {
        let t = stageDate.timeIntervalSinceReferenceDate
        Canvas { ctx, size in
            for idx in 0..<10 {
                let seed = Double(idx) * 1.73
                let baseX = size.width * (0.12 + 0.76 * CGFloat((idx * 37 % 100)) / 100.0)
                let baseY = size.height * (0.28 + 0.44 * CGFloat((idx * 53 % 100)) / 100.0)
                let px = baseX + CGFloat(sin(t * 0.35 + seed)) * 24
                let py = baseY + CGFloat(cos(t * 0.28 + seed * 1.3)) * 18
                let glow = 0.25 + 0.55 * (0.5 + 0.5 * sin(t * 1.1 + seed * 2.0))
                let r: CGFloat = 9.0
                ctx.fill(
                    Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: "#FFE79B").opacity(glow), .clear]),
                        center: CGPoint(x: px, y: py),
                        startRadius: 0.5,
                        endRadius: r
                    )
                )
            }
        }
    }
}

/// Calendar-driven subtle seasonal ambiance outside the Sunroom window (zero FOMO, pure living charm!):
/// Spring sakura petals, Summer warm fireflies, Autumn golden ginkgo leaves, Winter cozy frosted windowpanes.
private struct SeasonalWindowAmbianceOverlay: View {
    let stageDate: Date
    let date: Date

    private var season: Int {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3...5: return 0 // Spring
        case 6...8: return 1 // Summer
        case 9...11: return 2 // Autumn
        default: return 3 // Winter
        }
    }

    var body: some View {
        let t = stageDate.timeIntervalSinceReferenceDate
        Canvas { ctx, size in
            switch season {
            case 0: // Spring sakura petals drifting gently across window light
                for idx in 0..<8 {
                    let phase = (t * 0.11 + Double(idx) * 0.14).truncatingRemainder(dividingBy: 1.0)
                    let px = size.width * (0.14 + 0.72 * CGFloat((idx * 41 % 100)) / 100.0) + CGFloat(sin(t * 0.8 + Double(idx))) * 22
                    let py = size.height * (0.06 + CGFloat(phase) * 0.42)
                    let alpha = sin(phase * .pi) * 0.55
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px - 4, y: py - 2.2, width: 8, height: 4.5)),
                        with: .color(Color(hex: "#F6C8D2").opacity(alpha))
                    )
                }
            case 1: // Summer soft drifting pollen & warm glow motes
                for idx in 0..<7 {
                    let seed = Double(idx) * 1.9
                    let px = size.width * (0.18 + 0.64 * CGFloat((idx * 31 % 100)) / 100.0) + CGFloat(sin(t * 0.4 + seed)) * 18
                    let py = size.height * (0.12 + 0.30 * CGFloat((idx * 47 % 100)) / 100.0) + CGFloat(cos(t * 0.35 + seed)) * 12
                    let alpha = 0.25 + 0.30 * sin(t * 1.2 + seed)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px - 3, y: py - 3, width: 6, height: 6)),
                        with: .color(Color(hex: "#FFF0B3").opacity(alpha))
                    )
                }
            case 2: // Autumn golden ginkgo leaves gliding slowly past the window
                for idx in 0..<7 {
                    let phase = (t * 0.09 + Double(idx) * 0.17).truncatingRemainder(dividingBy: 1.0)
                    let px = size.width * (0.15 + 0.70 * CGFloat((idx * 43 % 100)) / 100.0) + CGFloat(cos(t * 0.7 + Double(idx))) * 26
                    let py = size.height * (0.06 + CGFloat(phase) * 0.40)
                    let alpha = sin(phase * .pi) * 0.52
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px - 5, y: py - 3, width: 10, height: 6)),
                        with: .color(Color(hex: "#E6B44C").opacity(alpha))
                    )
                }
            default: // Winter delicate frosted watercolor rim along top window corners
                let leftFrost = CGRect(x: size.width * 0.08, y: size.height * 0.05, width: 120, height: 80)
                let rightFrost = CGRect(x: size.width * 0.72, y: size.height * 0.05, width: 120, height: 80)
                for rect in [leftFrost, rightFrost] {
                    ctx.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [Color.white.opacity(0.32), .clear]),
                            center: CGPoint(x: rect.midX, y: rect.midY),
                            startRadius: 4,
                            endRadius: 60
                        )
                    )
                }
            }
        }
    }
}

/// Interactive Edo Glass Wind Chime + Dangling Hand-Folded Origamis hanging from the top window beam!
private struct HangingWindowDecorBeamView: View {
    let origamis: [OrigamiCraftKind]
    let isRinging: Bool
    let onRingChime: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Swipeable / Tappable Edo Glass Wind Chime (`江戶風鈴`)
            Button(action: onRingChime) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(hex: "#8A6238").opacity(0.75))
                        .frame(width: 1.5, height: 14)
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "#E8F6FA").opacity(0.95), Color(hex: "#84BCC8").opacity(0.72)],
                                    center: .topLeading,
                                    startRadius: 2,
                                    endRadius: 15
                                )
                            )
                            .frame(width: 24, height: 22)
                            .overlay(Circle().stroke(Color(hex: "#4A7276").opacity(0.55), lineWidth: 1))
                        Image(systemName: "sparkle")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .offset(x: -4, y: -3)
                    }
                    Rectangle()
                        .fill(Color(hex: "#B84A62"))
                        .frame(width: 1.2, height: 7)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#FFFDF6"))
                        .frame(width: 11, height: 22)
                        .overlay(
                            VStack(spacing: 2) {
                                Circle().fill(Color(hex: "#D46B52").opacity(0.65)).frame(width: 4, height: 4)
                                RoundedRectangle(cornerRadius: 1).fill(Color(hex: "#5B4A3C").opacity(0.45)).frame(width: 2, height: 8)
                            }
                        )
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: "#D5C5AE"), lineWidth: 0.8))
                        .shadow(color: AppTheme.deepPineInk.opacity(0.16), radius: 2, y: 1)
                }
                .rotationEffect(.degrees(isRinging ? 14 : -3), anchor: .top)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onEnded { _ in onRingChime() }
            )
            .accessibilityLabel("輕撥江戶風鈴")

            // Crafted Origami Charms dangling along the sunlit window beam
            ForEach(Array(origamis.enumerated()), id: \.offset) { idx, kind in
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(hex: "#9E784B").opacity(0.65))
                        .frame(width: 1.2, height: CGFloat(14 + (idx % 2) * 10))
                    Image(systemName: kind.sfSymbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: kind.colorHex))
                        .padding(6)
                        .background(Color(hex: "#FFFDF8").opacity(0.92), in: RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: kind.colorHex).opacity(0.6), lineWidth: 1))
                        .shadow(color: AppTheme.deepPineInk.opacity(0.15), radius: 2, y: 1.5)
                        .rotationEffect(.degrees(isRinging ? (idx % 2 == 0 ? 10 : -10) : (idx % 2 == 0 ? -4 : 4)), anchor: .top)
                }
            }
        }
    }
}

/// Pinned Watercolor Diary Postcard framed with Washi Tape on the back Sunroom wall!
private struct PinnedWallPostcardView: View {
    let image: UIImage
    let placeLabel: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .top) {
                VStack(spacing: 3) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 58, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    Text(placeLabel)
                        .font(.system(size: 7.5, weight: .bold, design: .serif))
                        .foregroundStyle(Color(hex: "#5B4A3C"))
                        .lineLimit(1)
                        .frame(maxWidth: 58)
                }
                .padding(5)
                .background(Color(hex: "#FFFDF8"), in: RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "#D5C5AE"), lineWidth: 1))
                .shadow(color: AppTheme.deepPineInk.opacity(0.22), radius: 4, y: 2)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color(hex: "#E6CFA3").opacity(0.88))
                    .frame(width: 24, height: 6)
                    .offset(y: -3)
            }
            .rotationEffect(.degrees(-3.5))
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.92, pressOffsetY: 1))
        .accessibilityLabel("牆上珍藏的明信片：\(placeLabel)")
    }
}

/// Shy undiscovered mystical companion peeking gently outside the Sunroom window!
/// Rectangle from `topY` to the bottom of the stage; the floor-tap layer's hit-test shape.
private struct FloorTapRegionShape: Shape {
    let topY: CGFloat

    func path(in rect: CGRect) -> Path {
        let top = min(max(rect.minY, topY), rect.maxY)
        return Path(CGRect(x: rect.minX, y: top, width: rect.width, height: rect.maxY - top))
    }
}

private struct SunroomWindowVisitorView: View {
    let petSpec: PetSpec
    let weather: WeatherMode
    let visitCount: Int
    var greetedToday: Bool = false
    var isPhotoMode: Bool = false
    let onGreet: () -> Void

    var body: some View {
        Button(action: onGreet) {
            VStack(spacing: 2) {
                if !isPhotoMode {
                    HStack(spacing: 3) {
                        Image(systemName: greetedToday ? "moon.zzz.fill" : "hand.wave.fill")
                            .font(.system(size: 9.5, weight: .bold))
                        Text(greetedToday ? "明天再來 \(visitCount)/3" : "窗外揮手 \(visitCount)/3")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color(hex: "#2F2A26"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color(hex: "#FFFDF8").opacity(0.94), in: Capsule())
                    .overlay(Capsule().stroke(Color(hex: "#D9A441"), lineWidth: 1))
                    .shadow(color: AppTheme.deepPineInk.opacity(0.16), radius: 3, y: 1)
                }

                ProceduralPetRigView(
                    pet: petSpec,
                    pose: .notice,
                    weatherMode: weather,
                    applyMetalPaperShader: false,
                    isStaticSnapshot: true
                )
                .frame(width: 68, height: 68)
                .opacity(greetedToday ? 0.6 : 0.86)
                .clipped()
            }
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.92, pressOffsetY: 1))
        .accessibilityLabel("向窗外探頭的\(petSpec.name)揮手")
    }
}

/// Flowing hand-painted ribbon + wooden wand + fluttering feathers drawn during Live Feather-Wand Chase Mode!
private struct FeatherWandRibbonOverlay: View {
    let tipPoint: CGPoint
    let time: Double

    var body: some View {
        Canvas { ctx, _ in
            let sway = CGFloat(sin(time * 9.0) * 14.0)
            let handlePt = CGPoint(x: tipPoint.x + 88, y: tipPoint.y - 110)
            let midCtrl = CGPoint(x: (handlePt.x + tipPoint.x) * 0.5 + sway, y: (handlePt.y + tipPoint.y) * 0.5 + 18)

            // Wooden wand rod (top half)
            let rodTip = CGPoint(x: tipPoint.x + 36, y: tipPoint.y - 52)
            var rod = Path()
            rod.move(to: handlePt)
            rod.addLine(to: rodTip)
            ctx.stroke(rod, with: .color(Color(hex: "#8A5F39")), style: StrokeStyle(lineWidth: 4.0, lineCap: .round))

            // Flowing pink-gold silk ribbon string
            var ribbon = Path()
            ribbon.move(to: rodTip)
            ribbon.addQuadCurve(to: tipPoint, control: midCtrl)
            ctx.stroke(ribbon, with: .color(Color(hex: "#E88B84")), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

            // Fluttering watercolor feather plume at the tip
            let plumeRect = CGRect(x: tipPoint.x - 14, y: tipPoint.y - 10, width: 28, height: 18)
            ctx.fill(Path(ellipseIn: plumeRect), with: .color(Color(hex: "#F2A08D").opacity(0.92)))
            let accentPlume = CGRect(x: tipPoint.x - 9, y: tipPoint.y - 6, width: 18, height: 11)
            ctx.fill(Path(ellipseIn: accentPlume), with: .color(Color(hex: "#F6D178").opacity(0.92)))
            ctx.fill(Path(ellipseIn: CGRect(x: tipPoint.x - 3, y: tipPoint.y - 3, width: 6, height: 6)), with: .color(.white))
        }
    }
}
