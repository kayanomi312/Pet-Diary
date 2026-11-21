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

    private var maxPan: CGFloat {
        coordinator.ledger.verandaUnlocked ? 240 : 140
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
            GeometryReader { geo in
                ZStack {
                    if let uiBg = UIImage(named: "bg_home_sunroom") {
                        Image(uiImage: uiBg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width + 180, height: geo.size.height)
                            .offset(x: effectivePan * 0.35)
                            .overlay(
                                Rectangle()
                                    .fill(sunroomThemeTint(weather: coordinator.activeWeather, theme: coordinator.ledger.activeRoomTheme))
                                    .blendMode(.multiply)
                            )
                            .clipped()
                    } else {
                        SunroomBackPlane(
                            weather: coordinator.activeWeather,
                            theme: coordinator.ledger.activeRoomTheme
                        )
                        .offset(x: effectivePan * 0.25)

                        SunroomMidTimberPlane(
                            weather: coordinator.activeWeather,
                            theme: coordinator.ledger.activeRoomTheme,
                            verandaUnlocked: coordinator.ledger.verandaUnlocked
                        )
                        .offset(x: effectivePan * 0.55)
                    }

                    SunroomAtmosphereParticlesView(weather: coordinator.activeWeather)

                    VStack {
                        Spacer()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .bottom, spacing: 18) {
                                ForEach(coordinator.homeSpots, id: \.spotIndex) { spot in
                                    let spotMentorship = coordinator.teachingIntentions.first {
                                        $0.state != .mastered &&
                                        spot.currentOccupantPetIDs.contains($0.mentorPetID) &&
                                        spot.currentOccupantPetIDs.contains($0.learnerPetID)
                                    }
                                    HomeSpotDioramaNode(
                                        spot: spot,
                                        activeMentorship: spotMentorship,
                                        coordinator: coordinator,
                                        onTapPet: { petID in
                                            coordinator.currentScreen = .tactileCare(petID: petID)
                                        },
                                        onTapEmptySpot: {
                                            showWickerDrawer = true
                                        },
                                        onCompleteMentorship: { intention in
                                            coordinator.completeMentorshipLesson(intentionUUID: intention.intentionUUID)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 134)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)

                    if teaSteaming {
                        VStack {
                            Spacer()
                            TornPaperSlipView(text: "暖呼呼的薑茶在木托盤上緩緩冒著白煙，屋裡安靜又舒服。")
                                .padding(.horizontal, 28)
                                .padding(.bottom, 118)
                        }
                        .transition(.opacity)
                    }
                }
            }
            .ignoresSafeArea()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        draggedOffset = value.translation.width * 0.45
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            panOffset = max(-maxPan, min(maxPan, panOffset + value.translation.width * 0.45))
                            draggedOffset = 0
                        }
                    }
            )

            VStack {
                ClothBookmarkBar(
                    onOpenSketchbook: { coordinator.currentScreen = .sketchbook },
                    onOpenCubbies: { coordinator.currentScreen = .curioCubbies },
                    onOpenFixture: { coordinator.showFixtureDrawer = true },
                    dayTitle: "陽光室 · \(coordinator.homeSpots.count) 處角落",
                    weather: coordinator.activeWeather
                )
                .padding(.top, 8)

                HStack {
                    Button {
                        showPetRibbonDrawer = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 12))
                            Text(invitedPets.isEmpty ? "到街角遇見第一位室友吧" : "家中室友 (\(invitedPets.count)/8)")
                                .font(AppTheme.diegeticLabel(12))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background(AppTheme.clothBookmark, in: Capsule())
                        .shadow(color: AppTheme.deepPineInk.opacity(0.20), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if let ready = readyMentorships.first {
                        Button {
                            coordinator.completeMentorshipLesson(intentionUUID: ready.intentionUUID)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "sparkles")
                                Text("觀摩傳承練習")
                                    .font(AppTheme.diegeticLabel(12))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.pawStrollChain, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)

                if let whisper = coordinator.transientWhisper {
                    TornPaperSlipView(text: whisper)
                        .padding(.horizontal, 18)
                        .padding(.top, 4)
                }

                Spacer()

                HStack(alignment: .bottom) {
                    WickerBasketCornerButton(
                        badgeText: "\(coordinator.ledger.ownedGoodieIDs.count)",
                        action: {
                            CozySoundEngine.shared.playPaperFlip()
                            showWickerDrawer = true
                        }
                    )

                    Spacer()

                    BrassPocketCompassButton(
                        destinationLabel: "出門回到街區地圖",
                        iconSystemName: "map.fill",
                        onTap: {
                            CozySoundEngine.shared.playCompassChime()
                            coordinator.currentScreen = .street
                        },
                        onLongPress: { coordinator.showFixtureDrawer = true }
                    )

                    Spacer()

                    CeramicTeapotCornerButton(
                        isSteaming: teaSteaming,
                        action: {
                            CozySoundEngine.shared.playTeapotClink()
                            showTeapotDrawer = true
                        }
                    )
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
            }
        }
        .onAppear {
            CozySoundEngine.shared.setRainAmbience(active: coordinator.activeWeather.isRainy)
        }
        .onChange(of: coordinator.activeWeather) { _, newWeather in
            CozySoundEngine.shared.setRainAmbience(active: newWeather.isRainy)
        }
        .onDisappear {
            CozySoundEngine.shared.stopRainAmbience()
        }
        .sheet(isPresented: $showWickerDrawer) {
            WickerBasketDrawer(coordinator: coordinator)
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

    private func sunroomThemeTint(weather: WeatherMode, theme: SeasonalRoomTheme) -> Color {
        if weather.isRainy || theme == .rainySeason {
            return Color(hex: "#C8DCE2").opacity(0.28)
        } else if theme == .winterLamp || weather == .dusk {
            return Color(hex: "#F2C58A").opacity(0.30)
        } else if theme == .autumnCedar {
            return Color(hex: "#E6B98A").opacity(0.22)
        }
        return Color.clear
    }
}

private struct HomeSpotDioramaNode: View {
    let spot: HomeSpotPlacement
    let activeMentorship: TeachingIntention?
    @Bindable var coordinator: GameCoordinator
    let onTapPet: (String) -> Void
    let onTapEmptySpot: () -> Void
    let onCompleteMentorship: (TeachingIntention) -> Void

    private var goodie: ShopItemSpec? {
        spot.equippedGoodieID.flatMap(ShopCatalog.item(id:))
    }

    private var mentorshipHabit: HabitFamily? {
        activeMentorship.flatMap { HabitFamily(rawValue: $0.habitFamilyID) }
    }

    var body: some View {
        VStack(spacing: 6) {
            if let intention = activeMentorship, intention.state == .demonstrated {
                Button {
                    onCompleteMentorship(intention)
                } label: {
                    Text("輕點記下這份溫柔")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(AppTheme.pawStrollChain, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            if !spot.currentOccupantPetIDs.isEmpty {
                HStack(spacing: -26) {
                    ForEach(spot.currentOccupantPetIDs, id: \.self) { petID in
                        let spec = PetCatalog.pet(id: petID)
                        let res = coordinator.resident(for: petID)
                        Button {
                            onTapPet(petID)
                        } label: {
                            ProceduralPetRigView(
                                pet: spec,
                                outfitID: res?.activeOutfitID,
                                pose: spot.spotIndex == 1 ? .resting : .notice,
                                weatherMode: coordinator.activeWeather,
                                isHappySquint: spot.currentOccupantPetIDs.count > 1,
                                mentorshipParticle: mentorshipHabit
                            )
                            .frame(width: 118, height: 118)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Button(action: onTapEmptySpot) {
                    VStack(spacing: 4) {
                        Image(systemName: spot.spotIndex >= 6 ? "cloud.drizzle" : "sparkles")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.timberDeep.opacity(0.55))
                        Text("空出的角落")
                            .font(AppTheme.handwritten(12))
                            .foregroundStyle(AppTheme.softInk)
                    }
                    .frame(width: 96, height: 86)
                }
                .buttonStyle(.plain)
            }

            // 精繪台灣繪本水彩家飾物（含毛毯流蘇、紙箱折翼、拼布球縫線、25 次歲月爪痕與手工補丁）
            PaintedGoodiePropView(
                goodieID: spot.equippedGoodieID,
                hasLovedPatina: spot.hasLovedPatina,
                hasStitchedPatch: spot.hasStitchedPatch,
                isWide: spot.currentOccupantPetIDs.count > 1
            )
            .offset(y: -12)
            .onTapGesture(perform: onTapEmptySpot)

            Text(spot.hasLovedPatina ? "\(spot.spotName) · 歲月溫潤" : spot.spotName)
                .font(AppTheme.diegeticLabel(10))
                .foregroundStyle(AppTheme.deepPineInk.opacity(0.85))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(AppTheme.warmPaper.opacity(0.86), in: Capsule())
        }
        .frame(minWidth: 118)
    }
}

private struct SunroomBackPlane: View {
    let weather: WeatherMode
    let theme: SeasonalRoomTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: weather.isRainy
                    ? [Color(hex: "#B5C9D1"), Color(hex: "#E6E4DC")]
                    : (theme == .winterLamp || weather == .dusk
                        ? [Color(hex: "#E5B47A"), Color(hex: "#F2DFC5")]
                        : [Color(hex: "#D6E8DF"), Color(hex: "#FAF6EE")]),
                startPoint: .top,
                endPoint: .bottom
            )

            // 窗外綠意水彩樹冠
            HStack(spacing: 28) {
                Circle().fill(AppTheme.vineGreen.opacity(0.26)).frame(width: 150, height: 150).offset(y: -140)
                Circle().fill(AppTheme.vineGreen.opacity(0.20)).frame(width: 190, height: 190).offset(y: -165)
            }
        }
    }
}

private struct SunroomMidTimberPlane: View {
    let weather: WeatherMode
    let theme: SeasonalRoomTheme
    let verandaUnlocked: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(hex: theme.wallHex)

                // 斜射溫暖日光光束
                if !weather.isRainy {
                    Path { p in
                        p.move(to: CGPoint(x: 90, y: 80))
                        p.addLine(to: CGPoint(x: 290, y: 80))
                        p.addLine(to: CGPoint(x: 380, y: 520))
                        p.addLine(to: CGPoint(x: 150, y: 520))
                        p.closeSubpath()
                    }
                    .fill(Color(hex: "#FFF8DC").opacity(0.24))
                }

                HStack(spacing: 24) {
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: weather.isRainy
                                        ? [Color(hex: "#C4D6DC").opacity(0.88), Color(hex: "#E4ECEE").opacity(0.65)]
                                        : [Color(hex: "#FFF9EB").opacity(0.92), Color(hex: "#F2E6CB").opacity(0.72)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 268, height: 224)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.timberWarm, lineWidth: 10))
                            .overlay(HStack { Spacer(); Rectangle().fill(AppTheme.timberWarm).frame(width: 6); Spacer() })
                            .overlay(VStack { Spacer(); Rectangle().fill(AppTheme.timberWarm.opacity(0.85)).frame(height: 5); Spacer() })

                        // 窗台小陶盆蕨類剪影
                        VStack(spacing: 0) {
                            HStack(spacing: -4) {
                                Ellipse().fill(AppTheme.vineGreen.opacity(0.85)).frame(width: 14, height: 24).rotationEffect(.degrees(-24))
                                Ellipse().fill(AppTheme.vineGreen).frame(width: 14, height: 28)
                                Ellipse().fill(AppTheme.vineGreen.opacity(0.8)).frame(width: 14, height: 22).rotationEffect(.degrees(26))
                            }
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.pawInRange)
                                .frame(width: 26, height: 18)
                        }
                        .offset(x: 22, y: -6)
                    }

                    if verandaUnlocked {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#C6D6D3").opacity(0.78))
                            .frame(width: 120, height: 240)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.timberDeep, lineWidth: 8))
                    }
                }
                .offset(y: -25)
            }
            .frame(maxHeight: .infinity)

            // 溫暖木地板與地腳線
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color(hex: theme.floorTopHex), Color(hex: theme.floorBottomHex)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Rectangle().fill(AppTheme.timberDeep.opacity(0.35)).frame(height: 8)
                VStack(spacing: 28) {
                    ForEach(0..<8, id: \.self) { _ in
                        Rectangle().fill(AppTheme.timberDeep.opacity(0.16)).frame(height: 1)
                    }
                }
                .padding(.top, 16)
            }
            .frame(height: 350)
        }
    }
}

private struct WickerBasketDrawer: View {
    @Bindable var coordinator: GameCoordinator
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
            List {
                ForEach(coordinator.residents, id: \.petID) { res in
                    let spec = PetCatalog.pet(id: res.petID)
                    HStack {
                        PetPortraitThumbnail(petID: res.petID, size: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spec.name)
                                .font(AppTheme.serifTitle(16))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text("\(spec.kind.rawValue) · \(res.inviteState == .unmet ? "尚未遇見" : "\(res.milestoneTitle)（相伴 \(res.sharedDaysCount) 天）")")
                                .font(AppTheme.serifBody(13))
                                .foregroundStyle(AppTheme.softInk)
                        }
                        Spacer()
                        if res.inviteState != .unmet {
                            Button("探望") {
                                dismiss()
                                coordinator.currentScreen = .tactileCare(petID: res.petID)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.forestTeal)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.warmPaper)
            .navigationTitle("布書籤 · 8 位鄰居名冊")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
