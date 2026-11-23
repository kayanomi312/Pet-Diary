import SwiftUI

/// 陽光室空間家園（精繪台灣日式木造陽光室、斜射日光束、窗台盆栽、5→8 互動位置、歲月痕跡補丁）
struct HomeSunroomView: View {
    @Bindable var coordinator: GameCoordinator
    @State private var panOffset: CGFloat = 0
    @State private var draggedOffset: CGFloat = 0
    @State private var showPetRibbonDrawer: Bool = false
    @State private var bouncingPetID: String? = nil
    @State private var isDecoratingMode: Bool = false
    @State private var selectedDecorateSpotIndex: Int = 1
    @State private var isFeatherWandMode: Bool = false
    @State private var showOrigamiFoldMat: Bool = false
    @State private var showWishStickySlip: Bool = false
    @State private var activeTeaRecipeIndex: Int = 0
    @State private var selectedOffspringID: UUID? = nil
    @State private var returnedErrandToast: CompletedErrandPostcard? = nil
    @State private var hidingSpotIndex: Int? = nil
    @State private var hidingPetID: String? = nil
    @State private var activeSkitOverlay: SunroomPairSkit? = nil
    @State private var roamingEngine = SunroomRoamingEngine()

    private var activeTeaRecipe: TeaRecipeSpec {
        let all = TeaKitchenCatalog.allRecipes
        return all[activeTeaRecipeIndex % all.count]
    }

    private var selectedOffspring: MysticalOffspringRecord? {
        guard let id = selectedOffspringID else { return nil }
        return coordinator.indoorState.offsprings.first(where: { $0.id == id })
    }

    private var maxPan: CGFloat {
        coordinator.ledger.verandaUnlocked ? 180 : 100
    }

    private var effectivePan: CGFloat {
        max(-maxPan, min(maxPan, panOffset + draggedOffset))
    }

    private var invitedPets: [PetResidentState] {
        coordinator.residents.filter { $0.inviteState == .invitedHome }
    }

    private var readyMentorships: [TeachingIntention] {
        coordinator.teachingIntentions.filter { $0.state == .demonstrated }
    }

    var body: some View {
        ZStack {
            // 真 2.5D 透視陽光室（4 層視差景深、1 點透視紅檜木地板、實體互動站點與直接動畫回饋！）
            Sunroom25DStageView(
                coordinator: coordinator,
                roaming: roamingEngine,
                effectivePan: effectivePan,
                bouncingPetID: bouncingPetID,
                isDecoratingMode: isDecoratingMode,
                selectedDecorateSpotIndex: selectedDecorateSpotIndex,
                isFeatherWandMode: isFeatherWandMode,
                hidingSpotIndex: hidingSpotIndex,
                hidingPetID: hidingPetID,
                activeTeaRecipe: activeTeaRecipe,
                onTapPet: { petID in
                    HapticsEngine.shared.playPawRangeCue()
                    let spec = PetCatalog.pet(id: petID)
                    if spec.kind.isCatFamily {
                        CozySoundEngine.shared.playPetPurr()
                    } else {
                        CozySoundEngine.shared.playPetChirp()
                    }
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) {
                        bouncingPetID = petID
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(160))
                        withAnimation(.easeOut(duration: 0.15)) { bouncingPetID = nil }
                        coordinator.currentScreen = .tactileCare(petID: petID)
                    }
                },
                onTapSpot: { spot in
                    HapticsEngine.shared.playBrushStrokeTick()
                    selectedDecorateSpotIndex = spot.spotIndex
                    if !isDecoratingMode {
                        CozySoundEngine.shared.playPaperFlip()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                            isDecoratingMode = true
                        }
                    }
                },
                onCompleteMentorship: { intention in
                    CozySoundEngine.shared.playCompassChime()
                    coordinator.completeMentorshipLesson(intentionUUID: intention.intentionUUID)
                    roamingEngine.emitFloatingBurst(at: CGPoint(x: 0.50, y: 0.48), text: "✦ 跨物種傳承完成！", colorHex: "#C98D26")
                },
                onCollectOrigami: { drop in
                    let paid = coordinator.collectOrigamiCharmGift(note: drop.note)
                    roamingEngine.emitFloatingBurst(at: drop.position, text: paid ? "+1 幣 ✦ 摺紙符" : "✦ 摺紙符", colorHex: "#B84A62")
                },
                onTapWindowsillCurio: { entry in
                    let spec = CurioCatalog.curio(id: entry.curioID)
                    roamingEngine.emitFloatingBurst(at: CGPoint(x: 0.50, y: 0.18), text: "✦ \(spec.name)", colorHex: "#4A7A76")
                    coordinator.showWhisper("窗台珍藏「\(spec.name)」(\(entry.placeLabel))：\(spec.journalNote)")
                },
                onTapOffspring: { child in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        selectedOffspringID = (selectedOffspringID == child.id) ? nil : child.id
                    }
                },
                onFoundHidingPet: { foundID, spotUV in
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
                        hidingSpotIndex = nil
                        hidingPetID = nil
                        bouncingPetID = foundID
                    }
                    let paid = coordinator.foundHidingPet(petID: foundID)
                    roamingEngine.popOutHidingPet(petID: foundID, from: spotUV)
                    if paid {
                        roamingEngine.emitFloatingBurst(at: CGPoint(x: spotUV.x, y: max(0.1, spotUV.y - 0.08)), text: "+1 幣", colorHex: "#D98A36")
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(360))
                        withAnimation(.easeOut(duration: 0.2)) { bouncingPetID = nil }
                    }
                },
                onTriggerSkit: { petA, petB in
                    let skit = coordinator.triggerSunroomSkit(petA: petA, petB: petB)
                    roamingEngine.performPairDance(
                        petA: petA,
                        petB: petB,
                        bubbleA: "嘿～一起玩嗎♪",
                        bubbleB: "好呀好呀♡"
                    )
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                        activeSkitOverlay = skit
                    }
                },
                onCompleteFeatherWandChase: {
                    coordinator.recordFeatherWandPlaySession()
                    roamingEngine.emitFloatingBurst(at: CGPoint(x: 0.50, y: 0.52), text: "♡ 好奇心提升！", colorHex: "#E87A6A")
                },
                onCycleTeaRecipe: {
                    activeTeaRecipeIndex = (activeTeaRecipeIndex + 1) % TeaKitchenCatalog.allRecipes.count
                    coordinator.showWhisper("已切換茶單「\(activeTeaRecipe.name)」——在茶壺上畫圈就能直接手沖！")
                },
                onBrewTeaInWorld: { brewed in
                    let paid = coordinator.brewTeaRecipe(brewed)
                    roamingEngine.gatherAllPets(near: CGPoint(x: 0.72, y: 0.72), bubble: "好香的\(brewed.name)♡")
                    roamingEngine.emitFloatingBurst(at: CGPoint(x: 0.80, y: 0.72), text: paid ? "+1 幣 🍵 茶香四溢" : "🍵 茶香四溢", colorHex: brewed.tintHex)
                },
                onTapOrigamiTable: {
                    HapticsEngine.shared.playBrushStrokeTick()
                    CozySoundEngine.shared.playPaperFlip()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                        showOrigamiFoldMat = true
                        selectedOffspringID = nil
                    }
                },
                onSendErrandSupply: { pack in
                    let walkerID = coordinator.activeWalkCompanionID ?? invitedPets.first?.petID ?? "pet.03"
                    if coordinator.sendPetOnErrand(petID: walkerID, supply: pack),
                       let errand = coordinator.indoorState.activeErrand {
                        roamingEngine.sendPetOutDoor(petID: walkerID, destination: errand.destinationLabel)
                    }
                },
                onCollectErrandInWorld: {
                    if let postcard = coordinator.collectReturnedErrand() {
                        roamingEngine.welcomePetBackInDoor(petID: postcard.petID, coins: postcard.coinsEarned)
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                            returnedErrandToast = postcard
                        }
                    }
                },
                onStartCourtshipNest: { fatherID, motherID in
                    if let baby = coordinator.startMysticalNest(fatherID: fatherID, motherID: motherID) {
                        roamingEngine.performPairDance(
                            petA: fatherID,
                            petB: motherID,
                            bubbleA: "一起守護這顆靈卵♡",
                            bubbleB: "暖暖的好期待✦",
                            heartBurst: true
                        )
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                            selectedOffspringID = baby.id
                        }
                    }
                }
            )
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard !isDecoratingMode && !isFeatherWandMode && !showOrigamiFoldMat else { return }
                        draggedOffset = value.translation.width * 0.55
                    }
                    .onEnded { value in
                        guard !isDecoratingMode && !isFeatherWandMode && !showOrigamiFoldMat else { return }
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            panOffset = max(-maxPan, min(maxPan, panOffset + value.translation.width * 0.55))
                            draggedOffset = 0
                        }
                    },
                including: (isDecoratingMode || isFeatherWandMode || showOrigamiFoldMat) ? .none : .all
            )

            if coordinator.isSunroomPhotoMode {
                VStack {
                    Spacer()
                    CozyHeroActionButton(
                        title: "結束純淨賞景",
                        systemImage: "eye.fill",
                        style: .sage
                    ) {
                        CozySoundEngine.shared.playPaperFlip()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            coordinator.isSunroomPhotoMode = false
                        }
                    }
                    .padding(.bottom, 28)
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 8) {
                    // MARK: Minimal Diegetic Top Bar (Room + Roommates pill | Inline Wish Slip + Audio + Zen)
                    HStack(spacing: 7) {
                        Button {
                            CozySoundEngine.shared.playPaperFlip()
                            showPetRibbonDrawer = true
                        } label: {
                            CozyGlassPill(horizontalPadding: 11, verticalPadding: 6) {
                                HStack(spacing: 5) {
                                    CuteWeatherFaceIcon(weather: coordinator.activeWeather, size: 19)
                                    Text("陽光室")
                                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#2F2A26"))
                                    Text("·")
                                        .foregroundStyle(Color(hex: "#B5A590"))
                                    Text("室友 \(invitedPets.count)/\(PetCatalog.allPets.count)")
                                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.forestTeal)
                                }
                            }
                        }
                        .buttonStyle(TactileGameButtonStyle(pressScale: 0.95, pressOffsetY: 1))

                        Spacer(minLength: 4)

                        // Inline Daily Wishes Sticky-Note Pill (expands in-place, zero modal!)
                        Button {
                            HapticsEngine.shared.playBrushStrokeTick()
                            CozySoundEngine.shared.playPaperFlip()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                                showWishStickySlip.toggle()
                            }
                        } label: {
                            CozyGlassPill(horizontalPadding: 10, verticalPadding: 7) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundStyle(Color(hex: "#C98D26"))
                                    let done = coordinator.todayWishesBoard.wishes.filter(\.isCompleted).count
                                    Text("\(done)/3")
                                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#2F2A26"))
                                }
                            }
                            .overlay(alignment: .topTrailing) {
                                if coordinator.unclaimedCompletedWishesCount > 0 {
                                    Circle()
                                        .fill(Color(hex: "#D96B52"))
                                        .frame(width: 9, height: 9)
                                        .overlay(Circle().stroke(Color(hex: "#FFFDF8"), lineWidth: 1.4))
                                        .offset(x: -1, y: -1)
                                }
                            }
                        }
                        .buttonStyle(TactileGameButtonStyle(pressScale: 0.93, pressOffsetY: 1))
                        .accessibilityLabel("展開今日小小願望便利貼")

                        // Audio / BGM cycle
                        CozyIconCircleButton(
                            systemImage: !CozySoundEngine.shared.isSoundEnabled
                                ? "speaker.slash.fill"
                                : (CozySoundEngine.shared.isMusicEnabled ? "music.note" : "speaker.wave.2.fill"),
                            tint: CozySoundEngine.shared.isSoundEnabled ? AppTheme.forestTeal : AppTheme.softInk,
                            size: 35,
                            accessibilityLabelText: "切換背景音樂與音效"
                        ) {
                            if !CozySoundEngine.shared.isSoundEnabled {
                                CozySoundEngine.shared.isSoundEnabled = true
                                CozySoundEngine.shared.isMusicEnabled = true
                                CozySoundEngine.shared.setCozyMusic(active: true, weather: coordinator.activeWeather)
                                CozySoundEngine.shared.setRainAmbience(active: coordinator.activeWeather.isRainy)
                                coordinator.showWhisper("已開啟療癒白噪音與拇指琴輕音樂 ♪")
                            } else if CozySoundEngine.shared.isMusicEnabled {
                                CozySoundEngine.shared.isMusicEnabled = false
                                coordinator.showWhisper("已切換為純環境音效（關閉輕音樂）")
                            } else {
                                CozySoundEngine.shared.isSoundEnabled = false
                                coordinator.showWhisper("已靜音全部音效")
                            }
                        }

                        // Pure Photo / Zen mode
                        CozyIconCircleButton(
                            systemImage: "camera.fill",
                            tint: Color(hex: "#5A4D43"),
                            size: 35,
                            accessibilityLabelText: "純淨賞景模式"
                        ) {
                            CozySoundEngine.shared.playPaperFlip()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isDecoratingMode = false
                                isFeatherWandMode = false
                                showOrigamiFoldMat = false
                                showWishStickySlip = false
                                selectedOffspringID = nil
                                coordinator.isSunroomPhotoMode = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Inline Floating Sticky-Note for Daily Wishes (Zero Modal!)
                    if showWishStickySlip {
                        HStack {
                            Spacer()
                            InWorldWishStickySlip(
                                board: coordinator.todayWishesBoard,
                                onClaim: { kind in
                                    if coordinator.claimDailyWishReward(kind) {
                                        roamingEngine.emitFloatingBurst(at: CGPoint(x: 0.65, y: 0.26), text: "+\(kind.rewardCoins) 幣 ✦ 願望達成", colorHex: "#D98A36")
                                    }
                                },
                                onClose: {
                                    withAnimation(.easeOut(duration: 0.18)) { showWishStickySlip = false }
                                }
                            )
                        }
                        .padding(.horizontal, 16)
                        .transition(.scale(scale: 0.92, anchor: .topTrailing).combined(with: .opacity))
                    }

                    if let ready = readyMentorships.first {
                        CozyHeroActionButton(
                            title: "觀摩跨物種傳承 ✦",
                            systemImage: "sparkles",
                            style: .amber
                        ) {
                            CozySoundEngine.shared.playCompassChime()
                            coordinator.completeMentorshipLesson(intentionUUID: ready.intentionUUID)
                        }
                        .padding(.top, 2)
                    }

                    if let whisper = coordinator.transientWhisper {
                        TornPaperSlipView(text: whisper)
                            .padding(.horizontal, 18)
                            .padding(.top, 2)
                    }

                    Spacer()

                    // Lightweight In-World Folding Mat (Swipe 3 times -> launches origami up to window beam!)
                    if showOrigamiFoldMat {
                        InWorldOrigamiFoldOverlay(
                            onCraftComplete: { kind in
                                let paid = coordinator.craftOrigami(kind)
                                roamingEngine.gatherAllPets(near: CGPoint(x: 0.45, y: 0.30), bubble: "哇～\(kind.title)飛上去了✦")
                                roamingEngine.emitFloatingBurst(at: CGPoint(x: 0.45, y: 0.16), text: paid ? "+1 幣 ✦ 掛上窗樑" : "✦ 掛上窗樑", colorHex: kind.colorHex)
                            },
                            onClose: {
                                withAnimation(.easeOut(duration: 0.2)) { showOrigamiFoldMat = false }
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 92)
                        .transition(.scale(scale: 0.90).combined(with: .opacity))
                    } else if let child = selectedOffspring {
                        // Lightweight In-World Floating Radial Care Card for tapped Egg / Hybrid Hatchling!
                        InWorldOffspringFloatingCard(
                            offspring: child,
                            anchors: coordinator.anchors,
                            onNurture: { axis, label in
                                let evolved = coordinator.nurtureOffspring(id: child.id, axis: axis, activityLabel: label)
                                roamingEngine.emitFloatingBurst(
                                    at: CGPoint(x: 0.46, y: 0.66),
                                    text: evolved ? "✦ 破殼成長囉！" : "\(axis.title) +2 ♡",
                                    colorHex: evolved ? "#D98A36" : axis.colorHex
                                )
                                if evolved {
                                    roamingEngine.gatherAllPets(near: CGPoint(x: 0.48, y: 0.66), bubble: "恭喜長大囉！✦")
                                }
                            },
                            onRename: { newName in
                                coordinator.renameOffspring(id: child.id, newName: newName)
                            },
                            onGraduate: { siteID in
                                coordinator.graduateOffspringToCorner(id: child.id, siteID: siteID)
                                roamingEngine.emitFloatingBurst(at: CGPoint(x: 0.50, y: 0.56), text: "✦ 前往守護街角", colorHex: "#3C6E67")
                            },
                            onDismiss: {
                                withAnimation(.easeOut(duration: 0.2)) { selectedOffspringID = nil }
                            }
                        )
                        .padding(.horizontal, 18)
                        .padding(.bottom, 92)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if let toast = returnedErrandToast {
                        // Physical Floating Watercolor Postcard Toast on Solo Errand Return!
                        InWorldErrandPostcardToast(
                            postcard: toast,
                            petDisplayName: coordinator.displayName(for: toast.petID)
                        ) {
                            withAnimation(.easeOut(duration: 0.2)) { returnedErrandToast = nil }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 92)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                    } else if isDecoratingMode {
                        // Live Inline Bottom Furniture Carousel (Swap props live while dragging on the 2.5D floor!)
                        InWorldFurnitureCarouselBar(
                            coordinator: coordinator,
                            selectedSpotIndex: $selectedDecorateSpotIndex,
                            onResetPositions: {
                                roamingEngine.resetCustomSpotPositions()
                                coordinator.showWhisper("已還原陽光室預設 2.5D 擺設位置。")
                            },
                            onDone: {
                                CozySoundEngine.shared.playPaperFlip()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                    isDecoratingMode = false
                                }
                            }
                        )
                        .padding(.bottom, 86)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if isFeatherWandMode {
                        HStack(spacing: 10) {
                            CozyGlassPill(horizontalPadding: 12, verticalPadding: 9) {
                                HStack(spacing: 5) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(hex: "#D96B52"))
                                    Text("在木地板滑動揮舞逗貓棒！")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#2F2A26"))
                                }
                            }

                            CozyHeroActionButton(
                                title: "收起",
                                systemImage: "checkmark",
                                style: .sage
                            ) {
                                CozySoundEngine.shared.playPaperFlip()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                    isFeatherWandMode = false
                                }
                            }
                        }
                        .padding(.bottom, 86)
                    } else {
                        // Ultra-Clean 3-Action Direct Play Strip (Everything else is physically touchable IN the room!)
                        HStack(spacing: 9) {
                            if !invitedPets.isEmpty {
                                Button {
                                    HapticsEngine.shared.playPawRangeCue()
                                    CozySoundEngine.shared.playBrushSwish()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                        isFeatherWandMode = true
                                    }
                                    coordinator.showWhisper("在木地板上滑動手指揮舞羽毛逗貓棒，室友會飛奔過來撲抓！")
                                } label: {
                                    CozyGlassPill(horizontalPadding: 13, verticalPadding: 9) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(Color(hex: "#D96B52"))
                                            Text("逗貓棒")
                                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color(hex: "#2F2A26"))
                                        }
                                    }
                                }
                                .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1))

                                Button {
                                    HapticsEngine.shared.playDogBallRoll()
                                    CozySoundEngine.shared.playPawTap()
                                    _ = roamingEngine.tossClothBall()
                                } label: {
                                    CozyGlassPill(horizontalPadding: 13, verticalPadding: 9) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "circle.dashed.inset.filled")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(Color(hex: "#C98D26"))
                                            Text("丟布球")
                                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color(hex: "#2F2A26"))
                                        }
                                    }
                                }
                                .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1))
                            }

                            Button {
                                CozySoundEngine.shared.playPaperFlip()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                    isDecoratingMode = true
                                }
                                coordinator.showWhisper("直接拖曳家具移動位置，或在下方點選即時換裝！")
                            } label: {
                                CozyGlassPill(horizontalPadding: 13, verticalPadding: 9) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "slider.horizontal.3")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(AppTheme.forestTeal)
                                        Text("佈置")
                                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color(hex: "#2F2A26"))
                                    }
                                }
                            }
                            .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1))
                        }
                        .padding(.bottom, 86)
                    }
                }
            }

            // Emergent Multi-Pet Sunroom Skit Floating Storybook Card (non-blocking top-bottom warm slip!)
            if let skit = activeSkitOverlay {
                VStack {
                    Spacer()
                    SunroomSkitOverlayCard(skit: skit, coordinator: coordinator) {
                        withAnimation(.easeOut(duration: 0.2)) { activeSkitOverlay = nil }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 94)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(30)
            }
        }
        .onAppear {
            CozySoundEngine.shared.setRainAmbience(active: coordinator.activeWeather.isRainy)
            CozySoundEngine.shared.setCozyMusic(active: true, weather: coordinator.activeWeather)
            roamingEngine.syncResidents(
                invitedPetIDs: invitedPets.map(\.petID),
                spots: coordinator.homeSpots,
                verandaUnlocked: coordinator.ledger.verandaUnlocked
            )
            // Gently seed a playful Hide-and-Seek spot if one isn't active yet
            if hidingSpotIndex == nil,
               let pet = invitedPets.randomElement(),
               let spot = coordinator.homeSpots.randomElement() {
                hidingSpotIndex = spot.spotIndex
                hidingPetID = pet.petID
            }
        }
        .onChange(of: invitedPets.map(\.petID)) { _, newIDs in
            roamingEngine.syncResidents(
                invitedPetIDs: newIDs,
                spots: coordinator.homeSpots,
                verandaUnlocked: coordinator.ledger.verandaUnlocked
            )
        }
        .onChange(of: coordinator.activeWeather) { _, newWeather in
            CozySoundEngine.shared.setRainAmbience(active: newWeather.isRainy)
            CozySoundEngine.shared.setCozyMusic(active: true, weather: newWeather)
        }
        .onDisappear {
            CozySoundEngine.shared.stopRainAmbience()
            CozySoundEngine.shared.stopCozyMusic()
        }
        .sheet(isPresented: $showPetRibbonDrawer) {
            PetBookmarkJumpDrawer(coordinator: coordinator)
                .presentationDetents([.medium, .large])
        }
    }
}

private struct PetPortraitThumbnail: View {
    let petID: String
    let size: CGFloat

    private var assetName: String {
        petID.replacingOccurrences(of: ".", with: "_")
    }

    var body: some View {
        ZStack {
            Circle().fill(AppTheme.parchmentTray)
            if let img = UIImage(named: assetName) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 1.45, height: size * 1.45)
                    .offset(y: size * 0.22)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 1))
    }
}

private struct PetBookmarkJumpDrawer: View {
    @Bindable var coordinator: GameCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(coordinator.residents, id: \.petID) { res in
                        let spec = PetCatalog.pet(id: res.petID)
                        StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.timberWarm, paddingAmount: 12) {
                            HStack(spacing: 12) {
                                PetPortraitThumbnail(petID: res.petID, size: 46)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(spec.name)
                                            .font(AppTheme.serifTitle(16))
                                            .foregroundStyle(AppTheme.deepPineInk)
                                        Text(spec.gender.symbol)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 5.5)
                                            .padding(.vertical, 1.5)
                                            .background(Color(hex: spec.gender.badgeHex), in: Capsule())
                                        SpeciesFolkloreBadgeView(kind: spec.kind)
                                    }
                                    Text(res.inviteState == .unmet
                                         ? "尚未遇見 · 靜候街角奇遇或窗邊揮手"
                                         : "\(res.milestoneTitle) · 相伴 \(res.sharedDaysCount) 天")
                                        .font(AppTheme.serifBody(12.5))
                                        .foregroundStyle(AppTheme.softInk)
                                }
                                Spacer(minLength: 4)
                                if res.inviteState != .unmet {
                                    CutePlushButton(
                                        title: "探望",
                                        tone: .matchaMint,
                                        fontSize: 12,
                                        horizontalPadding: 12,
                                        verticalPadding: 7,
                                        icon: { Image(systemName: "heart.fill").font(.system(size: 10, weight: .bold)) },
                                        action: {
                                            CozySoundEngine.shared.playPaperFlip()
                                            dismiss()
                                            coordinator.currentScreen = .tactileCare(petID: res.petID)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.parchmentTray)
            .navigationTitle("布書籤 · \(PetCatalog.allPets.count) 位奇幻鄰居名冊")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

/// Warm watercolor storybook card displaying an Emergent Multi-Pet Sunroom Skit (`室友互動小劇場`)!
private struct SunroomSkitOverlayCard: View {
    let skit: SunroomPairSkit
    @Bindable var coordinator: GameCoordinator
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                PetPortraitThumbnail(petID: skit.petA, size: 52)
                VStack(spacing: 3) {
                    Text("✦ 陽光室小劇場 ✦")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#C98D26"))
                    Text(skit.title)
                        .font(AppTheme.serifTitle(18))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Text("\(coordinator.displayName(for: skit.petA)) × \(coordinator.displayName(for: skit.petB))")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.forestTeal)
                }
                .frame(maxWidth: .infinity)
                PetPortraitThumbnail(petID: skit.petB, size: 52)
            }

            Text(skit.dialogue)
                .font(AppTheme.serifBody(14.5))
                .foregroundStyle(Color(hex: "#3E342C"))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(hex: "#F6EFE1"), in: RoundedRectangle(cornerRadius: 14))

            CozyHeroActionButton(
                title: "收進暖心回憶",
                systemImage: "heart.fill",
                style: .sage,
                action: onDismiss
            )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "#FFFDF8"))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: "#D5C5AE"), lineWidth: 1.2))
                .shadow(color: Color(hex: "#2B211A").opacity(0.22), radius: 18, y: 10)
        )
    }
}
