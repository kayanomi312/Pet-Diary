import SwiftUI

/// 近距離撫摸梳毛與木製掛衣架（繁體中文）
struct TactileCareView: View {
    @Bindable var coordinator: GameCoordinator
    let petID: String

    @State private var fingerFocus: CGPoint? = nil
    @State private var brushLocation: CGPoint? = nil
    @State private var brushStrokeCount: Int = 0
    @State private var brushRuffle: CGFloat = 0
    @State private var toyBounceOffset: CGFloat = 0
    @State private var showMentorshipSheet: Bool = false
    @State private var showSnackPicker: Bool = false
    @State private var showKindredLessonSheet: Bool = false
    @State private var showFieldGuideSheet: Bool = false
    @State private var activeTrayTab: Int = 0 // 0 = 互動陪玩, 1 = 換上衣飾
    @State private var draggingOutfitID: String? = nil
    @State private var draggingOffset: CGSize = .zero
    @State private var touchSparkles: [TouchSparkleSeed] = []
    @State private var lastSparkleTime: Date = .distantPast
    @State private var petBounce: CGFloat = 0.0
    @State private var showCareStamp: Bool = false
    @State private var activePlayAction: PetPlayfulAction = .idle
    @State private var actionTriggerDate: Date = .distantPast
    @State private var liveReactionBubble: String? = nil
    @State private var flyingSnackProgress: CGFloat? = nil
    @State private var wavingTeaserActive: Bool = false

    private var petSpec: PetSpec { PetCatalog.pet(id: petID) }
    private var resident: PetResidentState? { coordinator.resident(for: petID) }
    private var ownedWardrobe: [ShopItemSpec] {
        ShopCatalog.items.filter { $0.category == .wardrobe && coordinator.ledger.ownedOutfitIDs.contains($0.id) }
    }

    var body: some View {
        ZStack {
            TactileCareFloorBackdrop(weather: coordinator.activeWeather)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Clean Minimal Top Bar
                HStack(spacing: 10) {
                    Button {
                        CozySoundEngine.shared.playPaperFlip()
                        coordinator.currentScreen = .home
                    } label: {
                        CozyGlassPill(horizontalPadding: 11, verticalPadding: 7) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .bold))
                                Text("陽光室")
                                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(Color(hex: "#2F2A26"))
                        }
                    }
                    .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1))

                    Spacer()

                    CozyIconCircleButton(
                        systemImage: "book.pages.fill",
                        tint: AppTheme.forestTeal,
                        size: 36,
                        accessibilityLabelText: "打開毛孩繪本小檔案"
                    ) {
                        CozySoundEngine.shared.playPaperFlip()
                        showFieldGuideSheet = true
                    }

                    Menu {
                        Button {
                            coordinator.togglePinFavorite(petID: petID)
                            triggerPetBounce()
                        } label: {
                            Label(
                                (resident?.isPinned == true) ? "取消常駐陽光室" : "釘選為常駐室友",
                                systemImage: (resident?.isPinned == true) ? "pin.slash" : "pin.fill"
                            )
                        }
                        Button {
                            showMentorshipSheet = true
                        } label: {
                            Label("規劃跨物種傳承練習", systemImage: "sparkles")
                        }
                        Button {
                            CozySoundEngine.shared.playCompassChime()
                            coordinator.setWalkCompanion(petID: petID)
                            triggerPlayfulAction(.happyTwirl, bubble: "好耶！帶我出門玩♡")
                        } label: {
                            Label(
                                coordinator.activeWalkCompanionID == petID ? "目前是今日散步夥伴" : "設為今日散步夥伴",
                                systemImage: "figure.walk"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(hex: "#2F2A26"))
                            .frame(width: 36, height: 36)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(Circle().fill(Color(hex: "#FFFDF8").opacity(0.88)))
                                    .overlay(Circle().stroke(Color(hex: "#CBBAA0").opacity(0.55), lineWidth: 0.85))
                                    .shadow(color: Color(hex: "#2D241E").opacity(0.11), radius: 8, y: 3)
                            }
                    }
                    .accessibilityLabel("更多照護選項")
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Clean Refined Nameplate & 3-Heart Care Progress
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text(petSpec.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#2F2A26"))

                        HStack(spacing: 3.5) {
                            ForEach(0..<3, id: \.self) { idx in
                                Image(systemName: idx < brushStrokeCount ? "heart.fill" : "heart")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(idx < brushStrokeCount ? Color(hex: "#E36B5E") : Color(hex: "#CBBAA0"))
                                    .scaleEffect(idx < brushStrokeCount ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: brushStrokeCount)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#FFF7EC"), in: Capsule())
                    }

                    HStack(spacing: 6) {
                        SpeciesFolkloreBadgeView(kind: petSpec.kind)
                        Text("\(resident?.milestoneTitle ?? "初次相遇") · 相伴 \(resident?.sharedDaysCount ?? 1) 天")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.softInk)
                    }
                }
                .padding(.top, 8)

                if let credits = resident?.learnedHabitCredits, !credits.isEmpty {
                    VStack(spacing: 3) {
                        ForEach(credits.suffix(2), id: \.self) { credit in
                            Text(credit)
                                .font(AppTheme.handwritten(12))
                                .foregroundStyle(AppTheme.forestTeal)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(AppTheme.warmPaper.opacity(0.88), in: Capsule())
                        }
                    }
                    .padding(.top, 6)
                }

                Spacer()

                ZStack {
                    ProceduralPetRigView(
                        pet: petSpec,
                        outfitID: resident?.activeOutfitID,
                        pose: (brushStrokeCount >= 3 || activePlayAction == .cozyNap) ? .resting : .respond,
                        weatherMode: coordinator.activeWeather,
                        fingerFocusNormalized: fingerFocus,
                        isHappySquint: brushStrokeCount >= 2 || brushRuffle > 0.1 || activePlayAction == .bellyBoop || activePlayAction == .eatMunch || activePlayAction == .happyTwirl,
                        brushRuffleAmount: brushRuffle,
                        tapBounceScale: petBounce,
                        playfulAction: activePlayAction,
                        actionTriggerDate: actionTriggerDate
                    )
                    .frame(width: 280, height: 280)

                    // 可愛即時互動對話泡泡（戳肚皮、逗玩、吃小魚餅、蓋被被、轉圈圈）
                    if let bubble = liveReactionBubble {
                        SunroomPetSpeechBubble(text: bubble)
                            .offset(y: -124)
                    }

                    // 拋出金色小魚餅飛向毛孩的弧線動畫！
                    if let p = flyingSnackProgress {
                        let x = -110 + p * 110
                        let y = 70 - sin(p * .pi) * 145
                        CuteCareToyIcon(kind: .fishSnack, size: 34)
                            .rotationEffect(.degrees(Double(p) * 320))
                            .offset(x: x, y: y)
                            .allowsHitTesting(false)
                    }

                    // 揮動粉色羽毛逗貓棒動畫！
                    if wavingTeaserActive {
                        CuteCareToyIcon(kind: .teaserWand, size: 42)
                            .rotationEffect(.degrees(wavingTeaserActive ? 18 : -18))
                            .offset(x: 68, y: -58)
                            .transition(.scale.combined(with: .opacity))
                            .allowsHitTesting(false)
                    }

                    // 指尖梳毛／輕撫即時飄出的愛心與金色星芒粒子
                    LiveTouchSparkleLayer(seeds: touchSparkles)
                        .frame(width: 280, height: 280)

                    // 從木製掛衣架拖曳衣飾靠近頸部時，於 socket_neck 浮現金色引導光圈與文字提示
                    if draggingOutfitID != nil {
                        VStack(spacing: 4) {
                            Text("放開即可配戴")
                                .font(AppTheme.diegeticLabel(10))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.pawStrollChain, in: Capsule())
                            Circle()
                                .stroke(AppTheme.pawStrollChain, style: StrokeStyle(lineWidth: 2.8, dash: [5, 4]))
                                .background(Circle().fill(AppTheme.pawStrollChain.opacity(0.20)))
                                .frame(width: 76, height: 76)
                        }
                        .offset(x: -18, y: -48)
                        .allowsHitTesting(false)
                    }

                    // 隨指尖移動的木質梳毛刷（雨天自動切換成溫熱毛巾擦毛！）
                    if let loc = brushLocation {
                        HStack(spacing: 4) {
                            Image(systemName: coordinator.activeWeather.isRainy ? "wind" : "comb.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(coordinator.activeWeather.isRainy ? "暖巾擦毛" : "木梳順毛")
                                .font(AppTheme.diegeticLabel(11))
                        }
                        .foregroundStyle(AppTheme.deepPineInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.warmPaper.opacity(0.95), in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.timberWarm, lineWidth: 1.3))
                        .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 5, y: 2)
                        .position(x: max(44, min(236, loc.x)), y: max(30, min(250, loc.y - 26)))
                        .allowsHitTesting(false)
                    }

                    if showCareStamp {
                        HankoCelebrationStampView(
                            title: "暖心照護 ✦",
                            subtitle: "\(petSpec.name)很開心",
                            stampColor: AppTheme.pawInRange
                        )
                        .offset(x: 62, y: -96)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let nx = (value.location.x / 280.0) * 2.0 - 1.0
                            let ny = (value.location.y / 280.0) * 2.0 - 1.0
                            fingerFocus = CGPoint(x: max(-1, min(1, nx)), y: max(-1, min(1, ny)))
                            if abs(value.translation.width) > 20 {
                                brushRuffle = 1.0
                                brushLocation = value.location
                                emitTouchSparkle(at: value.location)
                            }
                        }
                        .onEnded { value in
                            if abs(value.translation.width) > 36 {
                                brushStrokeCount += 1
                                HapticsEngine.shared.playBrushStrokeTick()
                                CozySoundEngine.shared.playBrushSwish()
                                triggerPlayfulAction(.bellyBoop, bubble: cuteReactionLine(for: .bellyBoop))
                                if brushStrokeCount == 3 {
                                    coordinator.completeTactileCare(petID: petID)
                                    HapticsEngine.shared.playCurioUnpack()
                                    CozySoundEngine.shared.playCompassChime()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                        showCareStamp = true
                                    }
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .seconds(2.8))
                                        withAnimation(.easeOut(duration: 0.35)) { showCareStamp = false }
                                    }
                                }
                            } else if abs(value.translation.width) < 12 && abs(value.translation.height) < 12 {
                                // 分區撫摸回饋：摸頭／抓下巴／輕戳肚皮各有不同可愛反應與呼嚕聲！
                                let tapNormY = (value.location.y / 280.0) * 2.0 - 1.0
                                HapticsEngine.shared.playPawRangeCue()
                                if petSpec.kind.isCatFamily {
                                    CozySoundEngine.shared.playPetPurr()
                                } else {
                                    CozySoundEngine.shared.playPetChirp()
                                }
                                for _ in 0..<4 {
                                    emitTouchSparkle(
                                        at: CGPoint(
                                            x: value.location.x + CGFloat.random(in: -28...28),
                                            y: value.location.y + CGFloat.random(in: -22...18)
                                        ),
                                        force: true
                                    )
                                }
                                if tapNormY < -0.18 {
                                    triggerPlayfulAction(.bellyBoop, bubble: "摸摸頭好舒服～耳朵動了一下♡")
                                } else if tapNormY > 0.20 {
                                    triggerPlayfulAction(.pounceHop, bubble: cuteReactionLine(for: .bellyBoop))
                                } else {
                                    triggerPlayfulAction(.bellyBoop, bubble: "抓抓下巴…呼嚕呼嚕♪")
                                }
                            }
                            withAnimation(.easeOut(duration: 0.35)) {
                                fingerFocus = nil
                                brushLocation = nil
                                brushRuffle = 0
                            }
                        }
                )

                Text(activePlayAction == .cozyNap
                     ? "\(petSpec.name)蓋著小被子發出甜甜的呼嚕聲…"
                     : "輕點頭頂、抓下巴、戳肚皮或滑動梳毛來陪伴\(petSpec.name)")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#6B5E53"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)

                // MARK: Clean Unified Warm-Linen Bottom Care Tray (2 Tidy Tabs: 互動陪玩 / 換上衣飾)
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        trayTabPill(title: "互動陪玩", icon: "sparkles", index: 0)
                        trayTabPill(title: "換上衣飾", icon: "hanger", index: 1)
                        Spacer()
                        if activeTrayTab == 1 {
                            Button {
                                CozySoundEngine.shared.playPaperFlip()
                                coordinator.currentScreen = .curioCubbies
                            } label: {
                                Text("前往小舖 ▸")
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.forestTeal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)

                    if activeTrayTab == 0 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                careToyChip(title: petSpec.kind.isCatFamily ? "逗貓棒" : "滾布球", kind: .teaserWand, active: activePlayAction == .pounceHop) {
                                    HapticsEngine.shared.playDogBallRoll()
                                    CozySoundEngine.shared.playBrushSwish()
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { wavingTeaserActive = true }
                                    triggerPlayfulAction(.pounceHop, bubble: cuteReactionLine(for: .pounceHop))
                                    coordinator.completeTactileCare(petID: petID)
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .milliseconds(1200))
                                        withAnimation(.easeOut(duration: 0.25)) { wavingTeaserActive = false }
                                    }
                                }

                                careToyChip(title: "餵點心", kind: .fishSnack, active: activePlayAction == .eatMunch) {
                                    CozySoundEngine.shared.playPaperFlip()
                                    showSnackPicker = true
                                }

                                careToyChip(title: activePlayAction == .cozyNap ? "起床囉" : "蓋被被", kind: .cozyBlanket, active: activePlayAction == .cozyNap) {
                                    HapticsEngine.shared.playBrushStrokeTick()
                                    CozySoundEngine.shared.playPaperFlip()
                                    if activePlayAction == .cozyNap {
                                        triggerPlayfulAction(.bellyBoop, bubble: "伸個大懶腰～早安！")
                                    } else {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                                            activePlayAction = .cozyNap
                                            actionTriggerDate = Date()
                                            liveReactionBubble = "蓋好被被…呼呼…"
                                        }
                                    }
                                }

                                careToyChip(title: "踏踏舞", kind: .happyTwirl, active: activePlayAction == .happyTwirl) {
                                    HapticsEngine.shared.playCurioUnpack()
                                    CozySoundEngine.shared.playWardrobeSnap(withBell: true)
                                    emitBurstSparkles()
                                    triggerPlayfulAction(.happyTwirl, bubble: cuteReactionLine(for: .happyTwirl))
                                }

                                careToyChip(
                                    title: coordinator.activeWalkCompanionID == petID ? "同行中" : "帶去散步",
                                    kind: .walkBuddy,
                                    active: coordinator.activeWalkCompanionID == petID
                                ) {
                                    CozySoundEngine.shared.playCompassChime()
                                    coordinator.setWalkCompanion(petID: petID)
                                    triggerPlayfulAction(.happyTwirl, bubble: "好耶！帶我出門玩♡")
                                }

                                if let res = resident, res.sharedDaysCount >= 10, !res.kindredPracticeCompleted {
                                    CutePlushButton(
                                        title: "習慣練習",
                                        tone: .butterHoney,
                                        fontSize: 11.5,
                                        horizontalPadding: 11,
                                        verticalPadding: 10,
                                        icon: { Image(systemName: "sparkles").font(.system(size: 12, weight: .bold)) },
                                        action: { showKindredLessonSheet = true }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                PegRackItemCard(
                                    itemID: nil,
                                    title: "素頸自然",
                                    swatchHex: "#E8DFCE",
                                    secondaryHex: "#FAF6EE",
                                    isEquipped: resident?.activeOutfitID == nil
                                ) {
                                    coordinator.equipOutfit(petID: petID, outfitID: nil)
                                    CozySoundEngine.shared.playPaperFlip()
                                    triggerPetBounce()
                                }

                                ForEach(ownedWardrobe) { item in
                                    PegRackItemCard(
                                        itemID: item.id,
                                        title: item.name,
                                        swatchHex: item.swatchHex,
                                        secondaryHex: item.secondaryHex,
                                        isEquipped: resident?.activeOutfitID == item.id
                                    ) {
                                        coordinator.equipOutfit(petID: petID, outfitID: item.id)
                                        HapticsEngine.shared.playPawRangeCue()
                                        CozySoundEngine.shared.playWardrobeSnap(withBell: item.id == "outfit.occasion_collar")
                                        triggerPetBounce()
                                    }
                                    .offset(draggingOutfitID == item.id ? draggingOffset : .zero)
                                    .zIndex(draggingOutfitID == item.id ? 20 : 0)
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 14)
                                            .onChanged { value in
                                                if value.translation.height < -14 {
                                                    draggingOutfitID = item.id
                                                    draggingOffset = value.translation
                                                }
                                            }
                                            .onEnded { value in
                                                if draggingOutfitID == item.id && value.translation.height < -65 {
                                                    coordinator.equipOutfit(petID: petID, outfitID: item.id)
                                                    HapticsEngine.shared.playPawRangeCue()
                                                    CozySoundEngine.shared.playWardrobeSnap(withBell: item.id == "outfit.occasion_collar")
                                                    triggerPetBounce()
                                                }
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                                    draggingOutfitID = nil
                                                    draggingOffset = .zero
                                                }
                                            }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(hex: "#FFFDF8").opacity(0.90))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color(hex: "#D5C5AE").opacity(0.65), lineWidth: 0.9)
                        )
                        .shadow(color: Color(hex: "#2D241E").opacity(0.11), radius: 14, y: -3)
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .sheet(isPresented: $showMentorshipSheet) {
            MentorshipPlannerSheet(coordinator: coordinator, petID: petID)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showFieldGuideSheet) {
            CompanionFieldGuideSheet(petSpec: petSpec, resident: resident, weather: coordinator.activeWeather)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showKindredLessonSheet) {
            KawaiiKindredPracticeSheet(petSpec: petSpec) { choiceTitle in
                showKindredLessonSheet = false
                coordinator.completeKindredHabitPractice(petID: petID, choiceTitle: choiceTitle)
                triggerPlayfulAction(.happyTwirl, bubble: "我學會「\(petSpec.signatureHabitTitle)」囉✦")
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSnackPicker) {
            KawaiiSnackTraySheet(
                petSpec: petSpec,
                coinBalance: coordinator.ledger.coinBalance,
                onSelectTexture: { texture in
                    if let bite = ShopCatalog.item(id: "treat.favorite_bite"),
                       coordinator.purchaseItem(bite) {
                        showSnackPicker = false
                        launchTossedSnack(texture: texture)
                    }
                },
                onSelectFreeBowl: {
                    showSnackPicker = false
                    launchTossedSnack(texture: nil)
                }
            )
            .presentationDetents([.medium])
        }
    }

    private func launchTossedSnack(texture: FoodTexture?) {
        HapticsEngine.shared.playCurioUnpack()
        CozySoundEngine.shared.playTeapotClink()
        flyingSnackProgress = 0.0
        withAnimation(.easeInOut(duration: 0.55)) {
            flyingSnackProgress = 1.0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            flyingSnackProgress = nil
            emitBurstSparkles()
            coordinator.completeTactileCare(petID: petID, texture: texture)
            if let texture {
                let loved = (texture == petSpec.favoriteTexture)
                let msg = loved ? "最喜歡「\(texture.rawValue)」口感啦！♡" : "卡滋卡滋～\(texture.rawValue)點心真香♪"
                triggerPlayfulAction(.eatMunch, bubble: msg)
                if loved { emitBurstSparkles() }
            } else {
                triggerPlayfulAction(.eatMunch, bubble: "家常飯碗吃飽飽～好安心♡")
            }
        }
    }

    private func triggerPetBounce() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) {
            petBounce = 1.0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(190))
            withAnimation(.easeOut(duration: 0.22)) { petBounce = 0.0 }
        }
    }

    private func emitTouchSparkle(at point: CGPoint, force: Bool = false) {
        let now = Date()
        if !force {
            guard now.timeIntervalSince(lastSparkleTime) >= 0.085 else { return }
        }
        lastSparkleTime = now
        let seed = TouchSparkleSeed(
            position: point,
            createdAt: now,
            isHeart: touchSparkles.count % 2 == 0,
            driftX: CGFloat.random(in: -22...22),
            color: touchSparkles.count % 2 == 0 ? Color(hex: "#F07A72") : Color(hex: "#F2BC52")
        )
        touchSparkles.append(seed)
        if touchSparkles.count > 28 {
            touchSparkles.removeFirst(touchSparkles.count - 28)
        }
    }

    private func emitBurstSparkles() {
        for _ in 0..<6 {
            emitTouchSparkle(
                at: CGPoint(x: CGFloat.random(in: 85...195), y: CGFloat.random(in: 85...180)),
                force: true
            )
        }
    }

    private func triggerPlayfulAction(_ action: PetPlayfulAction, bubble: String) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
            activePlayAction = action
            actionTriggerDate = Date()
            liveReactionBubble = bubble
        }
        let capturedDate = actionTriggerDate
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2100))
            if actionTriggerDate == capturedDate && activePlayAction != .cozyNap {
                withAnimation(.easeOut(duration: 0.35)) {
                    activePlayAction = .idle
                    liveReactionBubble = nil
                }
            }
        }
    }

    private func cuteReactionLine(for action: PetPlayfulAction) -> String {
        switch action {
        case .bellyBoop:
            switch petSpec.kind {
            case .demonCat: return "本惡魔才沒有覺得很舒服…喵♡"
            case .dragonCat: return "呼嚕嚕～(吐出一朵暖暖小火星)"
            case .batCat: return "窸窸窣窣～翅膀開心抖了一下♪"
            case .impHound: return "嗚汪！(肩畔小鬼火亮了起來)"
            default: return "咪嗚～好軟好癢喔♡"
            }
        case .pounceHop:
            return petSpec.kind.isCatFamily ? "咻——抓到羽毛啦！" : "汪嗚！成功撲住布球！"
        case .eatMunch:
            return "卡滋卡滋～好好吃喔♪"
        case .happyTwirl:
            return petSpec.kind == .dragonCat ? "踏踏踏～尾巴搖高高噴出小火星♪" : "踩踏踏搖尾巴最開心了♡"
        default:
            return "呼嚕呼嚕…"
        }
    }

    private func trayTabPill(title: String, icon: String, index: Int) -> some View {
        let active = (activeTrayTab == index)
        return Button {
            HapticsEngine.shared.playBrushStrokeTick()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                activeTrayTab = index
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(active ? .white : Color(hex: "#5A4D43"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(active ? AppTheme.forestTeal : Color(hex: "#F2EBDD"))
            )
        }
        .buttonStyle(.plain)
    }

    private func careToyChip(title: String, kind: CuteCareToyIcon.Kind, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                CuteCareToyIcon(kind: kind, size: 24)
                Text(title)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(active ? Color.white : Color(hex: "#3A312B"))
            }
            .frame(width: 68, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(active ? AppTheme.forestTeal : Color(hex: "#F7F1E5"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(active ? Color.clear : Color(hex: "#D5C5AE").opacity(0.65), lineWidth: 0.9)
                    )
            )
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.93, pressOffsetY: 1.5))
    }
}

private struct PegRackItemCard: View {
    let itemID: String?
    let title: String
    let swatchHex: String
    let secondaryHex: String
    let isEquipped: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // 黃銅掛衣圓釘
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#F2D794"), AppTheme.brassDark],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 6
                        )
                    )
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(AppTheme.timberDeep.opacity(0.6), lineWidth: 0.8))

                // 垂掛棉紙吊卡 ＋ 手繪微型服飾圖案
                PaintedOutfitMiniatureView(
                    itemID: itemID,
                    swatchHex: swatchHex,
                    secondaryHex: secondaryHex,
                    size: 42
                )
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.warmPaper)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isEquipped ? AppTheme.pawStrollChain : AppTheme.timberWarm.opacity(0.45), lineWidth: isEquipped ? 2.2 : 1)
                        )
                )

                Text(title)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(isEquipped ? Color.white : Color(hex: "#3A312B"))
                    .lineLimit(1)
            }
            .frame(width: 84)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isEquipped ? AppTheme.forestTeal : Color(hex: "#F7F1E5"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isEquipped ? Color.clear : Color(hex: "#D5C5AE").opacity(0.65), lineWidth: 0.9)
                    )
            )
        }
        .buttonStyle(TactileGameButtonStyle())
    }
}

private struct MentorshipPlannerSheet: View {
    @Bindable var coordinator: GameCoordinator
    let petID: String
    @Environment(\.dismiss) private var dismiss

    private var otherInvited: [PetResidentState] {
        coordinator.residents.filter { $0.inviteState == .invitedHome && $0.petID != petID }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                let spec = PetCatalog.pet(id: petID)
                Text("一起計畫點小事（跨物種傳承）")
                    .font(AppTheme.serifTitle(20))
                    .foregroundStyle(AppTheme.deepPineInk)
                Text("\(spec.name)可以透過共享家飾，把「\(spec.signatureHabitTitle)」教給另一位室友。將於隔天或累積散步 2,500 步後完成。")
                    .font(AppTheme.serifBody(14))
                    .foregroundStyle(AppTheme.softInk)

                if otherInvited.isEmpty {
                    Text("再邀請一位鄰里小動物回家，就能安排牠們一起練習。")
                        .font(AppTheme.handwritten(14))
                        .foregroundStyle(AppTheme.softInk)
                } else {
                    ForEach(otherInvited, id: \.petID) { learner in
                        let learnerSpec = PetCatalog.pet(id: learner.petID)
                        HStack(spacing: 10) {
                            if let img = UIImage(named: learner.petID.replacingOccurrences(of: ".", with: "_")) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 42, height: 42)
                                    .background(AppTheme.parchmentTray)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppTheme.timberWarm.opacity(0.5), lineWidth: 1))
                            }
                            VStack(alignment: .leading) {
                                Text(learnerSpec.name).font(AppTheme.serifTitle(16))
                                Text("\(learner.milestoneTitle) · 已習得 \(learner.learnedHabitIDs.count)/2 項習慣")
                                    .font(AppTheme.diegeticLabel(11))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            CutePlushButton(
                                title: "安排同組",
                                tone: .matchaMint,
                                fontSize: 12,
                                horizontalPadding: 12,
                                verticalPadding: 7,
                                icon: { Image(systemName: "sparkles").font(.system(size: 10, weight: .bold)) },
                                action: {
                                    CozySoundEngine.shared.playCompassChime()
                                    _ = coordinator.planMentorship(mentorID: petID, learnerID: learner.petID)
                                    dismiss()
                                }
                            )
                        }
                        .padding(12)
                        .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 1))
                    }
                }
                Spacer()
            }
            .padding(20)
            .background(AppTheme.parchmentTray)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }
}

/// 專屬手繪茶點托盤（取代系統制式確認彈窗，點選口感直接拋出點心飛進毛孩嘴裡！）
private struct KawaiiSnackTraySheet: View {
    let petSpec: PetSpec
    let coinBalance: Int
    let onSelectTexture: (FoodTexture) -> Void
    let onSelectFreeBowl: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("挑選給\(petSpec.name)的小點心")
                            .font(AppTheme.serifTitle(17))
                            .foregroundStyle(AppTheme.deepPineInk)
                        Spacer()
                        Text("餘額 \(coinBalance) 幣")
                            .font(AppTheme.diegeticLabel(12))
                            .foregroundStyle(AppTheme.forestTeal)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.warmPaper, in: Capsule())
                    }

                    StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.vineGreen, paddingAmount: 12) {
                        HStack {
                            CuteCareToyIcon(kind: .fishSnack, size: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("日常家常飯碗")
                                    .font(AppTheme.serifTitle(15))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text("基本照護永久免費，隨時讓\(petSpec.name)安心吃飽。")
                                    .font(AppTheme.serifBody(12))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            CutePlushButton(
                                title: "免費餵食",
                                tone: .matchaMint,
                                fontSize: 12,
                                horizontalPadding: 11,
                                verticalPadding: 7,
                                icon: { Image(systemName: "heart.fill").font(.system(size: 10)) },
                                action: onSelectFreeBowl
                            )
                        }
                    }

                    ForEach(FoodTexture.allCases, id: \.self) { texture in
                        let isFav = (texture == petSpec.favoriteTexture)
                        StorybookPaperCard(cornerRadius: 16, accentColor: isFav ? AppTheme.pawStrollChain : AppTheme.timberWarm, paddingAmount: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 5) {
                                        Text("「\(texture.rawValue)」手作茶點")
                                            .font(AppTheme.serifTitle(15))
                                            .foregroundStyle(AppTheme.deepPineInk)
                                        if isFav {
                                            Text("✦ 最愛口感")
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color(hex: "#C85A32"))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(hex: "#FFF1DC"), in: Capsule())
                                        }
                                    }
                                    Text("會拋出一口可愛小魚餅飛向\(petSpec.name)！")
                                        .font(AppTheme.serifBody(12))
                                        .foregroundStyle(AppTheme.softInk)
                                }
                                Spacer()
                                CutePlushButton(
                                    title: "3 幣",
                                    tone: coinBalance >= 3 ? .butterHoney : .milkCream,
                                    fontSize: 12,
                                    horizontalPadding: 12,
                                    verticalPadding: 7,
                                    icon: { Image(systemName: "sparkles").font(.system(size: 10)) },
                                    action: { onSelectTexture(texture) }
                                )
                                .disabled(coinBalance < 3)
                                .opacity(coinBalance >= 3 ? 1.0 : 0.48)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.parchmentTray)
            .navigationTitle("午茶小點心盤")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("先不用") { dismiss() }
                }
            }
        }
    }
}

private struct KawaiiKindredPracticeSheet: View {
    let petSpec: PetSpec
    let onChoose: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                StorybookPaperCard(cornerRadius: 18, accentColor: AppTheme.pawStrollChain, paddingAmount: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("心照不宣 · 招牌習慣練習")
                            .font(AppTheme.serifTitle(17))
                            .foregroundStyle(AppTheme.deepPineInk)
                        Text(petSpec.signatureHabitTitle)
                            .font(AppTheme.diegeticLabel(13))
                            .foregroundStyle(AppTheme.forestTeal)
                        Text(petSpec.signatureHabitDetail)
                            .font(AppTheme.serifBody(13.5))
                            .foregroundStyle(AppTheme.softInk)
                    }
                }

                CutePlushButton(
                    title: "放慢節奏，靜靜示範一次",
                    tone: .matchaMint,
                    fontSize: 13.5,
                    horizontalPadding: 16,
                    verticalPadding: 11,
                    icon: { Image(systemName: "sparkles").font(.system(size: 12, weight: .bold)) },
                    action: { onChoose("放慢節奏靜靜示範") }
                )

                CutePlushButton(
                    title: "在牠身旁輕拍軟墊一起練習",
                    tone: .butterHoney,
                    fontSize: 13.5,
                    horizontalPadding: 16,
                    verticalPadding: 11,
                    icon: { Image(systemName: "pawprint.fill").font(.system(size: 12, weight: .bold)) },
                    action: { onChoose("輕拍軟墊並肩練習") }
                )

                Spacer()
            }
            .padding(18)
            .background(AppTheme.parchmentTray)
            .navigationTitle("與\(petSpec.name)的小約定")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("改天再練") { dismiss() }
                }
            }
        }
    }
}

/// 手繪毛孩圖鑑小檔案（呈現《貓與龍》世界觀傳聞、最愛口感、共振天氣、溫柔特質與相伴里程碑）
private struct CompanionFieldGuideSheet: View {
    let petSpec: PetSpec
    let resident: PetResidentState?
    let weather: WeatherMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    StorybookPaperCard(cornerRadius: 20, accentColor: AppTheme.timberWarm, showWashiTape: true, paddingAmount: 14) {
                        HStack(spacing: 14) {
                            ProceduralPetRigView(
                                pet: petSpec,
                                outfitID: resident?.activeOutfitID,
                                pose: .respond,
                                weatherMode: weather,
                                isHappySquint: true,
                                applyMetalPaperShader: false,
                                isStaticSnapshot: true
                            )
                            .frame(width: 96, height: 96)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(petSpec.name)
                                    .font(AppTheme.serifTitle(22))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                SpeciesFolkloreBadgeView(kind: petSpec.kind)
                                Text("個性：\(petSpec.personalityWord) · \(resident?.milestoneTitle ?? "初次相遇")")
                                    .font(AppTheme.diegeticLabel(11.5))
                                    .foregroundStyle(AppTheme.forestTeal)
                                if let firstISO = resident?.firstMetDateISO {
                                    Text("初遇於 \(CivilCalendarHelper.displayDate(from: firstISO))（已相伴 \(resident?.sharedDaysCount ?? 1) 天）")
                                        .font(AppTheme.serifBody(12))
                                        .foregroundStyle(AppTheme.softInk)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.forestTeal, paddingAmount: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("招牌習慣 · \(petSpec.signatureHabitTitle)")
                                .font(AppTheme.serifTitle(16))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text(petSpec.signatureHabitDetail)
                                .font(AppTheme.serifBody(13.5))
                                .foregroundStyle(AppTheme.softInk)
                            Divider()
                            Text("熟稔後的溫柔模樣")
                                .font(AppTheme.diegeticLabel(11.5))
                                .foregroundStyle(AppTheme.forestTeal)
                            Text("「\(petSpec.matureKindness)」")
                                .font(AppTheme.handwritten(14))
                                .foregroundStyle(AppTheme.deepPineInk)
                        }
                    }

                    StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.pawStrollChain, paddingAmount: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("生活小偏好")
                                .font(AppTheme.serifTitle(15.5))
                                .foregroundStyle(AppTheme.deepPineInk)
                            HStack(spacing: 8) {
                                Label("最愛口感：\(petSpec.favoriteTexture.rawValue)", systemImage: "fork.knife")
                                    .font(AppTheme.diegeticLabel(11.5))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.parchmentTray, in: Capsule())
                            }
                            HStack(spacing: 6) {
                                Text("喜歡的天氣：")
                                    .font(AppTheme.diegeticLabel(11.5))
                                    .foregroundStyle(AppTheme.softInk)
                                ForEach(petSpec.resonantWeathers, id: \.self) { w in
                                    Text(w.displayName)
                                        .font(AppTheme.diegeticLabel(11))
                                        .foregroundStyle(AppTheme.forestTeal)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppTheme.parchmentTray, in: Capsule())
                                }
                            }
                        }
                    }

                    if let credits = resident?.learnedHabitCredits, !credits.isEmpty {
                        StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.vineGreen, paddingAmount: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("向室友學到的溫柔習慣")
                                    .font(AppTheme.serifTitle(15))
                                    .foregroundStyle(AppTheme.forestTeal)
                                ForEach(credits, id: \.self) { credit in
                                    Text("✦ \(credit)")
                                        .font(AppTheme.handwritten(13.5))
                                        .foregroundStyle(AppTheme.deepPineInk)
                                }
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(AppTheme.parchmentTray)
            .navigationTitle("毛孩繪本小檔案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("闔上") { dismiss() }
                }
            }
        }
    }
}
