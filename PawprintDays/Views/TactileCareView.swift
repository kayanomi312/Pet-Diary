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

                // 手繪名牌與 3 朵暖心花瓣照護進度（取代冰冷數值條）
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text(petSpec.name)
                            .font(AppTheme.serifTitle(26))
                            .foregroundStyle(AppTheme.deepPineInk)

                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { idx in
                                Image(systemName: idx < brushStrokeCount ? "heart.fill" : "heart")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(idx < brushStrokeCount ? AppTheme.clothBookmark : AppTheme.timberWarm.opacity(0.55))
                                    .scaleEffect(idx < brushStrokeCount ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: brushStrokeCount)
                            }
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(AppTheme.warmPaper.opacity(0.92), in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 1))
                    }

                    SpeciesFolkloreBadgeView(kind: petSpec.kind)

                    Text("\(resident?.milestoneTitle ?? "初次相遇") · 相伴 \(resident?.sharedDaysCount ?? 1) 天")
                        .font(AppTheme.serifBody(13.5))
                        .foregroundStyle(AppTheme.softInk)

                    if let fav = resident?.favoriteTexture {
                        Text("偏愛「\(fav.rawValue)」口感 · 招牌習慣：\(petSpec.signatureHabitTitle)")
                            .font(AppTheme.diegeticLabel(11))
                            .foregroundStyle(AppTheme.forestTeal)
                    }
                }
                .padding(.top, 6)

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
                        pose: brushStrokeCount >= 3 ? .resting : .respond,
                        weatherMode: coordinator.activeWeather,
                        fingerFocusNormalized: fingerFocus,
                        isHappySquint: brushStrokeCount >= 2 || brushRuffle > 0.1,
                        brushRuffleAmount: brushRuffle,
                        tapBounceScale: petBounce
                    )
                    .frame(width: 280, height: 280)

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
                                triggerPetBounce()
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
                            }
                            withAnimation(.easeOut(duration: 0.35)) {
                                fingerFocus = nil
                                brushLocation = nil
                                brushRuffle = 0
                            }
                        }
                )

                Text(brushStrokeCount >= 3
                     ? "\(petSpec.name)滿足地瞇起彎彎笑眼。（\(petSpec.signatureHabitTitle)）"
                     : (coordinator.activeWeather.isRainy
                        ? "左右輕滑拿乾毛巾替\(petSpec.name)擦乾雨珠，或停住指尖讓牠望向你。"
                        : "左右輕滑替\(petSpec.name)梳毛，或停住指尖讓牠望向你。"))
                    .font(AppTheme.handwritten(14))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
                    .padding(.bottom, 10)

                // 觸覺互動按鈕：今日散步夥伴 ＋ 滾球／拉毯互動 ＋ 第 10 天心照不宣雙選練習
                HStack(spacing: 10) {
                    WoodPlaqueButton(
                        title: coordinator.activeWalkCompanionID == petID ? "今日散步夥伴" : "一起出門散步",
                        systemImage: "figure.walk",
                        tone: .forestTeal,
                        fontSize: 12,
                        horizontalPadding: 13,
                        verticalPadding: 8
                    ) {
                        CozySoundEngine.shared.playCompassChime()
                        coordinator.setWalkCompanion(petID: petID)
                        triggerPetBounce()
                    }

                    WoodPlaqueButton(
                        title: petSpec.kind.isCatFamily ? "拉好毯角" : "滾出布球",
                        systemImage: petSpec.kind.isCatFamily ? "bed.double.fill" : "circle.dashed.inset.filled",
                        tone: .warmCream,
                        fontSize: 12,
                        horizontalPadding: 13,
                        verticalPadding: 8
                    ) {
                        HapticsEngine.shared.playDogBallRoll()
                        CozySoundEngine.shared.playBrushSwish()
                        triggerPetBounce()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                            toyBounceOffset = -10
                            brushRuffle = 0.85
                        }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(280))
                            withAnimation(.easeOut(duration: 0.35)) {
                                toyBounceOffset = 0
                                brushRuffle = 0
                            }
                        }
                        coordinator.completeTactileCare(petID: petID)
                        coordinator.showWhisper(petSpec.kind.isCatFamily ? "替\(petSpec.name)輕輕拉好毯子一角。" : "把縫布球輕輕滾向\(petSpec.name)的腳邊！")
                    }
                    .offset(y: toyBounceOffset)

                    if let res = resident, res.sharedDaysCount >= 10, !res.kindredPracticeCompleted {
                        WoodPlaqueButton(
                            title: "習慣練習",
                            systemImage: "sparkles",
                            tone: .brassGold,
                            fontSize: 12,
                            horizontalPadding: 12,
                            verticalPadding: 8
                        ) {
                            showKindredLessonSheet = true
                        }
                    }
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

    private func emitTouchSparkle(at point: CGPoint) {
        let now = Date()
        guard now.timeIntervalSince(lastSparkleTime) >= 0.085 else { return }
        lastSparkleTime = now
        let seed = TouchSparkleSeed(
            position: point,
            createdAt: now,
            isHeart: touchSparkles.count % 2 == 0,
            driftX: CGFloat.random(in: -18...18),
            color: touchSparkles.count % 2 == 0 ? Color(hex: "#D96A52") : AppTheme.pawStrollChain
        )
        touchSparkles.append(seed)
        if touchSparkles.count > 24 {
            touchSparkles.removeFirst(touchSparkles.count - 24)
        }
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
