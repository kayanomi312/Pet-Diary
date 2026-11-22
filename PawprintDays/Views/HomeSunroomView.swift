import SwiftUI

/// 陽光室空間家園（精繪台灣日式木造陽光室、斜射日光束、窗台盆栽、5→8 互動位置、歲月痕跡補丁）
struct HomeSunroomView: View {
    @Bindable var coordinator: GameCoordinator
    @State private var panOffset: CGFloat = 0
    @State private var draggedOffset: CGFloat = 0
    @State private var showWickerDrawer: Bool = false
    @State private var showTeapotDrawer: Bool = false
    @State private var showPetRibbonDrawer: Bool = false
    @State private var teaSteaming: Bool = false
    @State private var bouncingPetID: String? = nil
    @State private var isDecoratingMode: Bool = false
    @State private var roamingEngine = SunroomRoamingEngine()

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
            // 真 2.5D 透視陽光室（4 層視差景深、1 點透視紅檜木地板、前後深度縮放與 zIndex 遮擋排序、點擊地板喚來毛孩自由漫步！）
            Sunroom25DStageView(
                coordinator: coordinator,
                roaming: roamingEngine,
                effectivePan: effectivePan,
                bouncingPetID: bouncingPetID,
                isDecoratingMode: isDecoratingMode,
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
                onTapSpot: { _ in
                    CozySoundEngine.shared.playPaperFlip()
                    showWickerDrawer = true
                },
                onCompleteMentorship: { intention in
                    CozySoundEngine.shared.playCompassChime()
                    coordinator.completeMentorshipLesson(intentionUUID: intention.intentionUUID)
                },
                onCollectOrigami: { drop in
                    coordinator.collectOrigamiCharmGift(note: drop.note)
                },
                onTapWindowsillCurio: { entry in
                    let spec = CurioCatalog.curio(id: entry.curioID)
                    coordinator.showWhisper("窗台珍藏「\(spec.name)」(\(entry.placeLabel))：\(spec.journalNote)")
                }
            )
            .overlay(alignment: .bottom) {
                if teaSteaming {
                    TornPaperSlipView(text: "暖呼呼的薑茶在木托盤上緩緩冒著白煙，屋裡安靜又舒服。")
                        .padding(.horizontal, 28)
                        .padding(.bottom, 118)
                        .transition(.opacity)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        draggedOffset = value.translation.width * 0.55
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            panOffset = max(-maxPan, min(maxPan, panOffset + value.translation.width * 0.55))
                            draggedOffset = 0
                        }
                    }
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
                    // MARK: Single Ultra-Clean Top Bar (Real Weather & Sunroom Status)
                    HStack(spacing: 8) {
                        CozyGlassPill(horizontalPadding: 11, verticalPadding: 6) {
                            HStack(spacing: 6) {
                                CuteWeatherFaceIcon(weather: coordinator.activeWeather, size: 20)
                                Text("陽光室")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "#2F2A26"))
                                Text("·")
                                    .foregroundStyle(Color(hex: "#B5A590"))
                                Text(coordinator.activeWeather.displayName)
                                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.forestTeal)
                            }
                        }

                        Spacer(minLength: 4)

                        // Audio / BGM cycle
                        CozyIconCircleButton(
                            systemImage: !CozySoundEngine.shared.isSoundEnabled
                                ? "speaker.slash.fill"
                                : (CozySoundEngine.shared.isMusicEnabled ? "music.note" : "speaker.wave.2.fill"),
                            tint: CozySoundEngine.shared.isSoundEnabled ? AppTheme.forestTeal : AppTheme.softInk,
                            size: 36,
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
                            size: 36,
                            accessibilityLabelText: "純淨賞景模式"
                        ) {
                            CozySoundEngine.shared.playPaperFlip()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isDecoratingMode = false
                                coordinator.isSunroomPhotoMode = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

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

                    // MARK: Clean 3-Action Sunroom Toolbar right above the Unified Dock!
                    if isDecoratingMode {
                        HStack(spacing: 10) {
                            Button {
                                CozySoundEngine.shared.playPaperFlip()
                                showWickerDrawer = true
                            } label: {
                                CozyGlassPill(horizontalPadding: 14, verticalPadding: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chair.lounge.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text("更換家飾")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(Color(hex: "#2F2A26"))
                                }
                            }
                            .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1))

                            CozyHeroActionButton(
                                title: "完成佈置",
                                systemImage: "checkmark",
                                style: .sage
                            ) {
                                CozySoundEngine.shared.playPaperFlip()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                    isDecoratingMode = false
                                }
                            }
                        }
                        .padding(.bottom, 86)
                    } else {
                        HStack(spacing: 10) {
                            if !invitedPets.isEmpty {
                                Button {
                                    HapticsEngine.shared.playDogBallRoll()
                                    CozySoundEngine.shared.playPawTap()
                                    _ = roamingEngine.tossClothBall()
                                } label: {
                                    CozyGlassPill(horizontalPadding: 13, verticalPadding: 9) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "circle.dashed.inset.filled")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(Color(hex: "#D96B52"))
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
                                coordinator.showWhisper("拖曳地板上的家具即可自由調整 2.5D 位置！")
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

                            Button {
                                CozySoundEngine.shared.playPaperFlip()
                                showPetRibbonDrawer = true
                            } label: {
                                CozyGlassPill(horizontalPadding: 13, verticalPadding: 9) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "pawprint.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#C98D26"))
                                        Text("室友 \(invitedPets.count)/\(PetCatalog.allPets.count)")
                                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color(hex: "#2F2A26"))
                                    }
                                }
                            }
                            .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1))

                            CozyIconCircleButton(
                                systemImage: "cup.and.saucer.fill",
                                tint: Color(hex: "#4A7276"),
                                size: 38,
                                accessibilityLabelText: "泡暖薑茶與挑選散步夥伴"
                            ) {
                                CozySoundEngine.shared.playTeapotClink()
                                showTeapotDrawer = true
                            }
                        }
                        .padding(.bottom, 86)
                    }
                }
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
        .sheet(isPresented: $showWickerDrawer) {
            WickerBasketDrawer(coordinator: coordinator, onResetLayout: {
                roamingEngine.resetCustomSpotPositions()
                coordinator.showWhisper("已還原陽光室預設 2.5D 擺設位置。")
            })
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTeapotDrawer) {
            CeramicTeapotDrawer(coordinator: coordinator) {
                withAnimation { teaSteaming = true }
                HapticsEngine.shared.playCurioUnpack()
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation { teaSteaming = false }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPetRibbonDrawer) {
            PetBookmarkJumpDrawer(coordinator: coordinator)
                .presentationDetents([.medium, .large])
        }
    }
}

private struct WickerBasketDrawer: View {
    @Bindable var coordinator: GameCoordinator
    var onResetLayout: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSpotIndex: Int = 1

    private var ownedGoodies: [ShopItemSpec] {
        ShopCatalog.items.filter { $0.category == .goodies && coordinator.ledger.ownedGoodieIDs.contains($0.id) }
    }

    private var selectedSpot: HomeSpotPlacement? {
        coordinator.homeSpots.first(where: { $0.spotIndex == selectedSpotIndex })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("出門前先擺好家飾，回家時就會遇見驚喜相聚。")
                        .font(AppTheme.handwritten(15))
                        .foregroundStyle(AppTheme.softInk)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(coordinator.homeSpots, id: \.spotIndex) { spot in
                                Button {
                                    selectedSpotIndex = spot.spotIndex
                                } label: {
                                    Text(spot.spotName)
                                        .font(AppTheme.diegeticLabel(12))
                                        .foregroundStyle(selectedSpotIndex == spot.spotIndex ? .white : AppTheme.deepPineInk)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(selectedSpotIndex == spot.spotIndex ? AppTheme.forestTeal : AppTheme.warmPaper, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if let spot = selectedSpot, spot.hasLovedPatina {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("溫潤歲月痕跡（已陪伴 \(spot.goodieUseCount) 次）")
                                    .font(AppTheme.serifTitle(15))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text(spot.hasStitchedPatch
                                     ? "已縫上一塊溫暖的裝飾小補丁。"
                                     : "可以保留溫馨磨損模樣，或花 10 幣縫上可愛補丁。")
                                    .font(AppTheme.serifBody(12))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            if !spot.hasStitchedPatch {
                                Button("縫補丁 (10幣)") {
                                    _ = coordinator.mendGoodiePatch(spotIndex: spot.spotIndex)
                                }
                                .font(AppTheme.diegeticLabel(12))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.pawInRange, in: Capsule())
                            }
                        }
                        .padding(12)
                        .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14))
                    }

                    if coordinator.ledger.ownedRoomThemeIDs.count > 1 {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("陽光室光影主題")
                                .font(AppTheme.diegeticLabel(12))
                                .foregroundStyle(AppTheme.softInk)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(SeasonalRoomTheme.allCases, id: \.self) { theme in
                                        if coordinator.ledger.ownedRoomThemeIDs.contains(theme.rawValue) {
                                            Button(theme.title) {
                                                coordinator.selectRoomTheme(theme)
                                            }
                                            .font(AppTheme.diegeticLabel(11))
                                            .foregroundStyle(coordinator.ledger.activeRoomTheme == theme ? .white : AppTheme.deepPineInk)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(coordinator.ledger.activeRoomTheme == theme ? AppTheme.forestTeal : AppTheme.warmPaper, in: Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ForEach(ownedGoodies) { item in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: item.swatchHex))
                                .frame(width: 44, height: 44)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.deepPineInk.opacity(0.3)))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(AppTheme.serifTitle(15))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text(item.summary)
                                    .font(AppTheme.serifBody(13))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            Button("擺放") {
                                coordinator.placeGoodie(spotIndex: selectedSpotIndex, goodieID: item.id)
                                dismiss()
                            }
                            .font(AppTheme.diegeticLabel(12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppTheme.forestTeal, in: Capsule())
                        }
                        .padding(12)
                        .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(18)
            }
            .background(AppTheme.parchmentTray)
            .navigationTitle("藤編玩具籃")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let onResetLayout {
                        Button("重設擺位") {
                            onResetLayout()
                            dismiss()
                        }
                        .font(AppTheme.diegeticLabel(12))
                        .foregroundStyle(AppTheme.softInk)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
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

private struct CeramicTeapotDrawer: View {
    @Bindable var coordinator: GameCoordinator
    let onBrewTea: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var invitedPets: [PetResidentState] {
        coordinator.residents.filter { $0.inviteState == .invitedHome }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("沏一壺暖薑茶")
                                .font(AppTheme.serifTitle(16))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text("日常照護永久免費——替陽光室添點茶香，迎接室友們。")
                                .font(AppTheme.serifBody(13))
                                .foregroundStyle(AppTheme.softInk)
                        }
                        Spacer()
                        Button("泡茶") {
                            coordinator.solveHomeRoomNow()
                            onBrewTea()
                            dismiss()
                        }
                        .font(AppTheme.diegeticLabel(13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(AppTheme.forestTeal, in: Capsule())
                    }
                    .padding(14)
                    .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14))

                    if let picnic = ShopCatalog.item(id: "treat.picnic_portion"), !invitedPets.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("雙人野餐點心（8 幣）")
                                    .font(AppTheme.serifTitle(15))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text("在今日日記中留下一張雙寵共餐的靜態水彩明信片。")
                                    .font(AppTheme.serifBody(12))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            Button("8幣") {
                                if coordinator.purchaseItem(picnic) { dismiss() }
                            }
                            .font(AppTheme.diegeticLabel(12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppTheme.forestTeal, in: Capsule())
                        }
                        .padding(14)
                        .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("挑選今日散步夥伴")
                            .font(AppTheme.serifTitle(16))
                            .foregroundStyle(AppTheme.deepPineInk)
                        Text("手機放口袋就好——每累積 1,400 步就能替你撿回一樣街區小物。")
                            .font(AppTheme.serifBody(13))
                            .foregroundStyle(AppTheme.softInk)

                        if invitedPets.isEmpty {
                            Text("先在街角認識第一位小動物，就能邀請牠一起去散步。")
                                .font(AppTheme.handwritten(14))
                                .foregroundStyle(AppTheme.softInk)
                        } else {
                            ForEach(invitedPets, id: \.petID) { resident in
                                let spec = PetCatalog.pet(id: resident.petID)
                                let isCurrent = coordinator.activeWalkCompanionID == resident.petID
                                HStack {
                                    PetPortraitThumbnail(petID: resident.petID, size: 36)
                                    VStack(alignment: .leading) {
                                        Text(spec.name)
                                            .font(AppTheme.serifTitle(15))
                                            .foregroundStyle(AppTheme.deepPineInk)
                                        Text("\(resident.milestoneTitle) · 相伴 \(resident.sharedDaysCount) 天")
                                            .font(AppTheme.diegeticLabel(11))
                                            .foregroundStyle(AppTheme.softInk)
                                    }
                                    Spacer()
                                    Button(isCurrent ? "同行中" : "一起出門") {
                                        coordinator.setWalkCompanion(petID: resident.petID)
                                    }
                                    .font(AppTheme.diegeticLabel(12))
                                    .foregroundStyle(isCurrent ? AppTheme.forestTeal : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(isCurrent ? AppTheme.parchmentTray : AppTheme.forestTeal, in: Capsule())
                                }
                                .padding(10)
                                .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(AppTheme.parchmentTray)
            .navigationTitle("陶瓷茶壺")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
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
                                        SpeciesFolkloreBadgeView(kind: spec.kind)
                                    }
                                    Text(res.inviteState == .unmet
                                         ? "尚未遇見 · 靜候街角奇遇"
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
            .navigationTitle("布書籤 · 8 位奇幻鄰居名冊")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
