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
                HStack(spacing: 8) {
                    WoodPlaqueButton(
                        title: "陽光室",
                        systemImage: "chevron.left",
                        tone: .warmCream,
                        fontSize: 12.5,
                        horizontalPadding: 11,
                        verticalPadding: 7
                    ) {
                        CozySoundEngine.shared.playPaperFlip()
                        coordinator.currentScreen = .home
                    }

                    Spacer()

                    WoodPlaqueButton(
                        title: "點心",
                        systemImage: "fork.knife",
                        tone: .terracotta,
                        fontSize: 11.5,
                        horizontalPadding: 10,
                        verticalPadding: 7
                    ) {
                        showSnackPicker = true
                    }
                    .accessibilityLabel("餵食小點心")

                    WoodPlaqueButton(
                        title: (resident?.isPinned == true) ? "已常駐" : "常駐",
                        systemImage: (resident?.isPinned == true) ? "pin.fill" : "pin",
                        tone: (resident?.isPinned == true) ? .brassGold : .warmCream,
                        fontSize: 11.5,
                        horizontalPadding: 10,
                        verticalPadding: 7
                    ) {
                        coordinator.togglePinFavorite(petID: petID)
                        triggerPetBounce()
                    }
                    .accessibilityLabel("釘選為常駐陽光室的室友")

                    WoodPlaqueButton(
                        title: "傳承",
                        systemImage: "pawprint.fill",
                        tone: .forestTeal,
                        fontSize: 11.5,
                        horizontalPadding: 10,
                        verticalPadding: 7
                    ) {
                        showMentorshipSheet = true
                    }
                    .accessibilityLabel("規劃跨物種傳承練習")
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                // 可愛貓耳奶油名牌與 3 顆愛心照護進度
                VStack(spacing: 4) {
                    ZStack(alignment: .top) {
                        CatEarAccentShape(
                            fillColor: Color(hex: "#FFFDF7"),
                            innerEarColor: Color(hex: "#F4B4A8"),
                            strokeColor: Color(hex: "#D2B692")
                        )
                        .scaleEffect(0.75)
                        .offset(y: -11)

                        HStack(spacing: 8) {
                            Text(petSpec.name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#3E2F28"))

                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { idx in
                                    Image(systemName: idx < brushStrokeCount ? "heart.fill" : "heart")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(idx < brushStrokeCount ? Color(hex: "#E87266") : AppTheme.timberWarm.opacity(0.45))
                                        .scaleEffect(idx < brushStrokeCount ? 1.18 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: brushStrokeCount)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(Color(hex: "#FFF6EA"), in: Capsule())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#FFFDF7"))
                                .overlay(Capsule().stroke(Color(hex: "#D5B895"), lineWidth: 1.3))
                                .shadow(color: AppTheme.deepPineInk.opacity(0.12), radius: 5, y: 2)
                        )
                    }

                    SpeciesFolkloreBadgeView(kind: petSpec.kind)
                        .padding(.top, 2)

                    Text("\(resident?.milestoneTitle ?? "初次相遇") · 相伴 \(resident?.sharedDaysCount ?? 1) 天")
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.softInk)
                }
                .padding(.top, 10)

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
                                // 輕點毛孩肚皮 → 軟糯麻糬彈跳 ＋ 愛心噴發！
                                HapticsEngine.shared.playPawRangeCue()
                                CozySoundEngine.shared.playCompassChime()
                                for _ in 0..<4 {
                                    emitTouchSparkle(
                                        at: CGPoint(
                                            x: value.location.x + CGFloat.random(in: -28...28),
                                            y: value.location.y + CGFloat.random(in: -22...18)
                                        ),
                                        force: true
                                    )
                                }
                                triggerPlayfulAction(.bellyBoop, bubble: cuteReactionLine(for: .bellyBoop))
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
                     : (brushStrokeCount >= 3
                        ? "\(petSpec.name)滿足地瞇起彎彎笑眼！（點牠肚皮或用下方小玩具一起玩吧）"
                        : "輕戳肚皮、左右滑動梳毛，或挑選下方可愛玩具陪\(petSpec.name)玩！"))
                    .font(AppTheme.handwritten(13.5))
                    .foregroundStyle(Color(hex: "#4A392E"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)

                // 超可愛 6 款手繪互動玩具列（戳肚皮、逗玩撲跳、拋魚餅、蓋被被午睡、轉圈撒嬌、今日散步夥伴）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        careToyChip(title: "戳肚皮", kind: .bellyPoke, active: activePlayAction == .bellyBoop) {
                            HapticsEngine.shared.playPawRangeCue()
                            CozySoundEngine.shared.playCompassChime()
                            emitBurstSparkles()
                            triggerPlayfulAction(.bellyBoop, bubble: cuteReactionLine(for: .bellyBoop))
                        }

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

                        careToyChip(title: "拋魚餅", kind: .fishSnack, active: activePlayAction == .eatMunch) {
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
                                triggerPlayfulAction(.eatMunch, bubble: cuteReactionLine(for: .eatMunch))
                                coordinator.completeTactileCare(petID: petID)
                            }
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
                            title: coordinator.activeWalkCompanionID == petID ? "同行夥伴" : "帶去散步",
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
                                verticalPadding: 8,
                                icon: { Image(systemName: "sparkles").font(.system(size: 12, weight: .bold)) },
                                action: { showKindredLessonSheet = true }
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.bottom, 8)

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "hanger")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "#F6E9CE"))
                            Text("木製掛衣架 · 點擊或上拖配戴")
                                .font(AppTheme.diegeticLabel(12))
                                .foregroundStyle(Color(hex: "#FFF9EE"))
                        }
                        Spacer()
                        Button {
                            CozySoundEngine.shared.playPaperFlip()
                            coordinator.currentScreen = .curioCubbies
                        } label: {
                            Text("步數幣小舖 ▸")
                                .font(AppTheme.diegeticLabel(11))
                                .foregroundStyle(Color(hex: "#FFE7B2"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

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
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(hex: "#674325"))
                            .offset(y: 3)
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#B5865A"), Color(hex: "#8F633B")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color(hex: "#DFB889").opacity(0.45), lineWidth: 1.2)
                    }
                    .shadow(color: AppTheme.deepPineInk.opacity(0.26), radius: 8, y: -2)
                )
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }
        }
        .sheet(isPresented: $showMentorshipSheet) {
            MentorshipPlannerSheet(coordinator: coordinator, petID: petID)
                .presentationDetents([.medium])
        }
        .confirmationDialog("心照不宣 · 招牌習慣練習（\(petSpec.signatureHabitTitle)）", isPresented: $showKindredLessonSheet, titleVisibility: .visible) {
            Button("放慢節奏，靜靜示範一次") {
                coordinator.completeKindredHabitPractice(petID: petID, choiceTitle: "放慢節奏靜靜示範")
            }
            Button("在牠身旁輕拍軟墊一起練習") {
                coordinator.completeKindredHabitPractice(petID: petID, choiceTitle: "輕拍軟墊並肩練習")
            }
            Button("改天再練", role: .cancel) {}
        } message: {
            Text("\(petSpec.signatureHabitDetail)\n選擇一種溫柔的方式陪\(petSpec.name)練習，以後牠在家就會自主展現這個小習慣。")
        }
        .confirmationDialog("請\(petSpec.name)吃點心（日常飯碗永久免費）", isPresented: $showSnackPicker, titleVisibility: .visible) {
            ForEach(FoodTexture.allCases, id: \.self) { texture in
                Button("請吃「\(texture.rawValue)」小點心（3 幣）") {
                    if let bite = ShopCatalog.item(id: "treat.favorite_bite"),
                       coordinator.purchaseItem(bite) {
                        coordinator.completeTactileCare(petID: petID, texture: texture)
                        let loved = (texture == petSpec.favoriteTexture)
                        coordinator.showWhisper(loved ? "\(petSpec.name)好喜歡「\(texture.rawValue)」口感！" : "\(petSpec.name)慢慢嚼完了\(texture.rawValue)點心。")
                    }
                }
            }
            Button("日常家常飯碗（免費）") {
                coordinator.completeTactileCare(petID: petID)
                coordinator.showWhisper("\(petSpec.name)安穩地吃飽了。基本照護永遠免費。")
            }
            Button("取消", role: .cancel) {}
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

    private func careToyChip(title: String, kind: CuteCareToyIcon.Kind, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                CuteCareToyIcon(kind: kind, size: 24)
                Text(title)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(active ? Color(hex: "#FFFDF7") : Color(hex: "#4A362B"))
            }
            .frame(width: 64, height: 54)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(active ? Color(hex: "#9B4236") : Color(hex: "#D4C2A5"))
                        .offset(y: 3)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(active ? Color(hex: "#E67B6A") : Color(hex: "#FFFDF7"))
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(active ? Color.white.opacity(0.45) : Color(hex: "#E5D3B5"), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        .padding(3)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "#5A4234").opacity(0.24), lineWidth: 1)
                }
            )
            .padding(.bottom, 3)
            .shadow(color: AppTheme.deepPineInk.opacity(0.14), radius: 4, y: 2)
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.90, pressOffsetY: 2.5))
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
                    .foregroundStyle(isEquipped ? Color(hex: "#FFF9DE") : AppTheme.warmPaper)
                    .lineLimit(1)
            }
            .frame(width: 88)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isEquipped ? AppTheme.forestTeal.opacity(0.92) : AppTheme.timberDeep.opacity(0.42))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isEquipped ? AppTheme.pawStrollChain.opacity(0.85) : Color.white.opacity(0.14), lineWidth: 1.2)
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
                        HStack {
                            VStack(alignment: .leading) {
                                Text(learnerSpec.name).font(AppTheme.serifTitle(16))
                                Text("\(learner.milestoneTitle) · 已習得 \(learner.learnedHabitIDs.count)/2 項習慣")
                                    .font(AppTheme.diegeticLabel(11))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            Button("安排同組") {
                                _ = coordinator.planMentorship(mentorID: petID, learnerID: learner.petID)
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.forestTeal)
                        }
                        .padding(12)
                        .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 12))
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
