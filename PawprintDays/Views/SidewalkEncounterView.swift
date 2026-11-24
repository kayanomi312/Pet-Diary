import SwiftUI

/// 街角相遇全螢幕水彩劇場（台灣老街騎樓、暖黃紙燈籠、森林綠暖簾、長按 2.5 秒呼嚕共振）
struct SidewalkEncounterView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var coordinator: GameCoordinator
    let siteID: String
    let petID: String
    var companionStreetPetID: String? = nil

    @State private var irisProgress: CGFloat = 0.05
    @State private var holdProgress: CGFloat = 0.0
    @State private var isHoldingCobblestone: Bool = false
    @State private var holdTask: Task<Void, Never>? = nil
    @State private var fingerFocus: CGPoint? = nil
    @State private var committedLog: EncounterLog? = nil
    @State private var slipText: String = ""
    @State private var bonusGiftWhisper: String? = nil
    @State private var greetingFeedback: String? = nil
    @State private var walkQuestOffer: WalkWithMeQuest? = nil
    @State private var petTapBounce: CGFloat = 0.0
    @State private var holdRipplePulse: Bool = false

    // Interactive Mini-Ritual States: Ball-Flick & Rain Umbrella Shelter!
    @State private var ballDragOffset: CGSize = .zero
    @State private var ballRollingProgress: CGFloat = 0.0
    @State private var isBallInFlight: Bool = false
    @State private var isHoldingUmbrella: Bool = false
    @State private var umbrellaProgress: CGFloat = 0.0
    @State private var umbrellaTask: Task<Void, Never>? = nil
    @State private var lastPlayfulOverride: PetPlayfulAction? = nil

    private var petSpec: PetSpec { PetCatalog.pet(id: petID) }
    private var petDisplayName: String { coordinator.displayName(for: petID) }
    private var guideSpec: PetSpec? { companionStreetPetID.map(PetCatalog.pet(id:)) }
    private var resident: PetResidentState? { coordinator.resident(for: petID) }
    private var guideResident: PetResidentState? { companionStreetPetID.flatMap { coordinator.resident(for: $0) } }
    private var anchor: AnchorSiteRecord? { coordinator.anchors.first(where: { $0.siteID == siteID }) }

    /// Dynamic approach scale: as player holds out their hand, pet shyly walks closer (0.88x -> 1.06x)!
    private var approachScale: CGFloat {
        if reduceMotion { return 1.0 }
        if committedLog != nil { return 1.05 }
        return 0.88 + holdProgress * 0.18
    }

    private var activePetAction: PetPlayfulAction {
        if let override = lastPlayfulOverride { return override }
        if committedLog != nil { return .happyTwirl }
        if isBallInFlight { return .pounceHop }
        if isHoldingCobblestone { return .walking }
        return .idle
    }

    var body: some View {
        ZStack {
            TaiwaneseBakeryStorybookBackdrop(weather: coordinator.activeWeather)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    WoodPlaqueButton(
                        title: anchor?.customLabel ?? "街區地圖",
                        systemImage: "chevron.left",
                        tone: .warmCream,
                        fontSize: 12.5,
                        horizontalPadding: 12,
                        verticalPadding: 7
                    ) {
                        HapticsEngine.shared.stopHoldToGreetPurr()
                        coordinator.currentScreen = .street
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: coordinator.activeWeather.sfSymbol)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.forestTeal)
                        Text(coordinator.activeWeather.displayName)
                            .font(AppTheme.diegeticLabel(12))
                            .foregroundStyle(AppTheme.deepPineInk)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.warmPaper.opacity(0.92), in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 1))
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                Spacer()

                ZStack(alignment: .topTrailing) {
                    if let guideSpec {
                        HStack(spacing: -36) {
                            ProceduralPetRigView(
                                pet: guideSpec,
                                outfitID: guideResident?.activeOutfitID,
                                pose: .respond,
                                weatherMode: coordinator.activeWeather,
                                fingerFocusNormalized: fingerFocus,
                                isHappySquint: committedLog != nil,
                                tapBounceScale: petTapBounce
                            )
                            .frame(width: 215, height: 215)

                            ProceduralPetRigView(
                                pet: petSpec,
                                outfitID: resident?.activeOutfitID,
                                pose: committedLog != nil ? .respond : .notice,
                                weatherMode: coordinator.activeWeather,
                                fingerFocusNormalized: fingerFocus ?? (isHoldingCobblestone ? CGPoint(x: -0.5, y: 0.35) : nil),
                                isHappySquint: committedLog != nil || holdProgress > 0.65 || isHoldingUmbrella,
                                tapBounceScale: petTapBounce,
                                playfulAction: activePetAction,
                                actionTriggerDate: committedLog?.createdAtUTC ?? Date()
                            )
                            .frame(width: 230, height: 230)
                            .scaleEffect(approachScale)
                            .offset(y: reduceMotion ? 0 : (1.0 - holdProgress) * -10)
                            .animation(.easeOut(duration: 0.16), value: holdProgress)
                        }
                    } else {
                        ProceduralPetRigView(
                            pet: petSpec,
                            outfitID: resident?.activeOutfitID,
                            pose: committedLog != nil ? .respond : .notice,
                            weatherMode: coordinator.activeWeather,
                            fingerFocusNormalized: fingerFocus ?? (isHoldingCobblestone ? CGPoint(x: -0.5, y: 0.35) : nil),
                            isHappySquint: committedLog != nil || holdProgress > 0.65 || isHoldingUmbrella,
                            tapBounceScale: petTapBounce,
                            playfulAction: activePetAction,
                            actionTriggerDate: committedLog?.createdAtUTC ?? Date()
                        )
                        .frame(width: 280, height: 280)
                        .scaleEffect(approachScale)
                        .offset(y: reduceMotion ? 0 : (1.0 - holdProgress) * -14)
                        .animation(.easeOut(duration: 0.16), value: holdProgress)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let nx = (value.location.x / 280.0) * 2.0 - 1.0
                                    let ny = (value.location.y / 280.0) * 2.0 - 1.0
                                    fingerFocus = CGPoint(x: max(-1, min(1, nx)), y: max(-1, min(1, ny)))
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.4)) { fingerFocus = nil }
                                }
                        )
                    }

                    // Hand-Painted Forest-Green Watercolor Umbrella Canopy lowering gently during rainy umbrella shelter!
                    if isHoldingUmbrella || (committedLog?.gestureChosen == .holdUmbrella) {
                        WatercolorUmbrellaCanopyOverlay(progress: committedLog != nil ? 1.0 : umbrellaProgress)
                            .frame(width: 260, height: 140)
                            .offset(y: reduceMotion ? -48 : -48 + (1.0 - (committedLog != nil ? 1.0 : umbrellaProgress)) * -52)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .allowsHitTesting(false)
                    }

                    // Rolling stitched cloth ball flying smoothly across cobblestones toward the dog!
                    if isBallInFlight {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(hex: "#F6A88A"), Color(hex: "#C85A32")],
                                        center: .topLeading,
                                        startRadius: 2,
                                        endRadius: 18
                                    )
                                )
                                .frame(width: 34 * (1.0 - ballRollingProgress * 0.35), height: 34 * (1.0 - ballRollingProgress * 0.35))
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "#FFF8EC").opacity(0.8), style: StrokeStyle(lineWidth: 1.8, dash: [4, 3]))
                                        .padding(4)
                                )
                                .rotationEffect(.degrees(Double(ballRollingProgress) * 520))
                        }
                        .offset(x: -90, y: reduceMotion ? 154 : 210 - ballRollingProgress * 120)
                        .allowsHitTesting(false)
                    }

                    // 問候完成時蓋下傳統朱紅印章「今日相遇 ✦」
                    if committedLog != nil {
                        HankoCelebrationStampView(
                            title: "今日相遇 ✦",
                            subtitle: "已貼進精裝日記",
                            stampColor: AppTheme.clothBookmark
                        )
                        .offset(x: -6, y: 12)
                    }
                }

                SpeciesFolkloreBadgeView(kind: petSpec.kind)
                    .padding(.top, 2)

                TornPaperSlipView(
                    text: slipText.isEmpty ? openingWhisper : slipText,
                    subtitle: subtitleLabel
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if let feedback = greetingFeedback {
                    HStack(spacing: 8) {
                        Image(systemName: feedback.hasPrefix("♡") ? "heart.fill" : "questionmark.circle")
                            .foregroundStyle(Color(hex: "#D96B7E"))
                        Text(feedback)
                            .font(AppTheme.handwritten(13))
                            .foregroundStyle(AppTheme.deepPineInk)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.warmPaper.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#D96B7E").opacity(0.55), lineWidth: 1.2))
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }

                if let quest = walkQuestOffer {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .foregroundStyle(AppTheme.forestTeal)
                        Text("\(petDisplayName)想陪你再走 \(quest.targetSteps) 步——一起走完可得 +\(WalkWithMeQuest.rewardCoins) 步數幣。")
                            .font(AppTheme.handwritten(13))
                            .foregroundStyle(AppTheme.deepPineInk)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.warmPaper.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.forestTeal.opacity(0.5), lineWidth: 1.2))
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }

                if let gift = bonusGiftWhisper {
                    HStack(spacing: 8) {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(AppTheme.pawStrollChain)
                        Text(gift)
                            .font(AppTheme.handwritten(13))
                            .foregroundStyle(AppTheme.deepPineInk)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.warmPaper.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.pawStrollChain.opacity(0.65), lineWidth: 1.3))
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }

                if let chainTargetID = committedLog?.strollChainTargetSiteID,
                   let targetAnchor = coordinator.anchors.first(where: { $0.siteID == chainTargetID }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppTheme.pawStrollChain)
                        Text("\(petSpec.name)豎起耳朵望向「\(targetAnchor.customLabel)」——地圖已亮起金色漫步光暈（略過無任何懲罰）。")
                            .font(AppTheme.handwritten(13))
                            .foregroundStyle(AppTheme.deepPineInk)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(AppTheme.warmPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.pawStrollChain.opacity(0.75), lineWidth: 1.5))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Spacer()

                if committedLog == nil {
                    VStack(spacing: 14) {
                        // 招呼偏好小提示：發現後標記最愛，未發現時鼓勵嘗試不同方式
                        HStack(spacing: 5) {
                            Image(systemName: coordinator.hasDiscoveredFavoriteGesture(for: petID) ? "heart.fill" : "questionmark.circle")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "#D96B7E"))
                            Text(coordinator.hasDiscoveredFavoriteGesture(for: petID)
                                 ? "\(petDisplayName)最喜歡：\(petSpec.favoriteGreeting.title)"
                                 : "試試不同的招呼方式，找出\(petDisplayName)最喜歡的那一種")
                                .font(AppTheme.handwritten(12.5))
                                .foregroundStyle(AppTheme.deepPineInk)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(AppTheme.warmPaper.opacity(0.92), in: Capsule())

                        ZStack {
                            // 長按共振波紋
                            if isHoldingCobblestone {
                                Circle()
                                    .stroke(AppTheme.pawStrollChain.opacity(holdRipplePulse ? 0.0 : 0.72), lineWidth: 3)
                                    .frame(width: holdRipplePulse ? 156 : 108, height: holdRipplePulse ? 156 : 108)
                            }

                            // 3D 黃銅石座底影
                            Circle()
                                .fill(AppTheme.timberDeep.opacity(0.35))
                                .frame(width: 114, height: 114)
                                .offset(y: 4)

                            // 外層雕刻黃銅環
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(hex: "#F2D794"), AppTheme.brassLight, AppTheme.brassDark],
                                        center: .topLeading,
                                        startRadius: 6,
                                        endRadius: 64
                                    )
                                )
                                .frame(width: 114, height: 114)
                                .shadow(color: AppTheme.deepPineInk.opacity(0.26), radius: 8, y: 4)

                            // 象牙棉紙圓盤面
                            Circle()
                                .fill(AppTheme.warmPaper)
                                .frame(width: 102, height: 102)

                            Circle()
                                .stroke(AppTheme.timberWarm.opacity(0.30), lineWidth: 5.5)
                                .frame(width: 96, height: 96)

                            Circle()
                                .trim(from: 0, to: holdProgress)
                                .stroke(
                                    AppTheme.pawStrollChain,
                                    style: StrokeStyle(lineWidth: 6.5, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 96, height: 96)

                            VStack(spacing: 4) {
                                Image(systemName: isHoldingCobblestone ? "sparkles" : "hand.raised.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(isHoldingCobblestone ? AppTheme.pawStrollChain : AppTheme.forestTeal)
                                Text(isHoldingCobblestone ? "輕放感受呼嚕…" : "長按伸手招呼")
                                    .font(AppTheme.diegeticLabel(11))
                                    .foregroundStyle(AppTheme.deepPineInk)
                            }
                        }
                        .scaleEffect(isHoldingCobblestone ? 1.07 : 1.0)
                        .animation(AppTheme.Motion.resolved(.bouncy, reduceMotion: reduceMotion), value: isHoldingCobblestone)
                        .onLongPressGesture(
                            minimumDuration: 2.5,
                            maximumDistance: 44,
                            pressing: { pressing in
                                if pressing { startCobblestoneHold() } else { cancelCobblestoneHold() }
                            },
                            perform: { completeGreeting(with: .offerHand) }
                        )
                        .accessibilityLabel("長按 2.5 秒向\(petSpec.name)伸手打招呼")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("按住 2.5 秒向\(petDisplayName)伸出手")

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) { secondaryGestureButtons }
                            VStack(spacing: 8) { secondaryGestureButtons }
                        }
                    }
                    .padding(.bottom, 26)
                } else {
                    VStack(spacing: 12) {
                        // 剛印好的水彩明信片貼紙預覽（含和紙膠帶）
                        if let data = committedLog?.bakedSnapshotPNGData, let img = UIImage(data: data) {
                            ZStack(alignment: .top) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 92)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .padding(5)
                                    .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 8))
                                    .shadow(color: AppTheme.deepPineInk.opacity(0.22), radius: 7, y: 3)

                                WashiTapeStrip(color: Color(hex: "#E6CFA3"), angle: -2.0, width: 52)
                                    .offset(y: -6)
                            }
                            .rotationEffect(.degrees(1.2))
                            .transition(reduceMotion ? .opacity : .scale(scale: 0.7).combined(with: .opacity))
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 14) { departureButtons }
                            VStack(spacing: 10) { departureButtons }
                        }
                    }
                    .padding(.bottom, 26)
                }
            }
        }
        .mask(
            GeometryReader { geo in
                Circle()
                    .frame(
                        width: max(geo.size.width, geo.size.height) * 2.2 * irisProgress,
                        height: max(geo.size.width, geo.size.height) * 2.2 * irisProgress
                    )
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { irisProgress = 1.0 }
            CozySoundEngine.shared.setRainAmbience(active: coordinator.activeWeather.isRainy)
        }
        .onDisappear {
            cancelCobblestoneHold()
            CozySoundEngine.shared.stopRainAmbience()
        }
    }

    @ViewBuilder
    private var secondaryGestureButtons: some View {
        WoodPlaqueButton(
            title: "坐上木凳陪伴",
            systemImage: "chair.lounge.fill",
            tone: .warmCream,
            fontSize: 12,
            horizontalPadding: 14,
            verticalPadding: 9
        ) {
            HapticsEngine.shared.playPawRangeCue()
            completeGreeting(with: .crouchQuietly)
        }

        if !petSpec.kind.isCatFamily {
            // Interactive Ball-Flick Gesture (swipe upward OR tap for accessibility!)
            HStack(spacing: 8) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#F6A88A"), Color(hex: "#C85A32")],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 12
                        )
                    )
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color(hex: "#FFF8EC"), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2])).padding(2))
                Text("上滑或點擊滾布球")
                    .font(AppTheme.diegeticLabel(12))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(AppTheme.forestTeal, in: Capsule())
            .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 5, y: 2)
            .offset(y: min(0, max(-42, ballDragOffset.height * 0.55)))
            .onTapGesture {
                launchBallFlickRitual()
            }
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        ballDragOffset = value.translation
                    }
                    .onEnded { value in
                        withAnimation(AppTheme.Motion.resolved(.settle, reduceMotion: reduceMotion)) {
                            ballDragOffset = .zero
                        }
                        if value.translation.height < -24 {
                            launchBallFlickRitual()
                        }
                    }
            )
            .accessibilityLabel("向上滑動或輕點滾出縫布球給\(petDisplayName)")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                launchBallFlickRitual()
            }
        } else if coordinator.activeWeather.isRainy {
            // Interactive Rain Umbrella Shelter Hold (hold 1.2s to shelter pet under watercolor umbrella!)
            HStack(spacing: 6) {
                Image(systemName: "umbrella.fill")
                    .font(.system(size: 13, weight: .bold))
                Text(isHoldingUmbrella ? "正在替牠撐傘遮雨…" : "按住撐傘一起躲雨")
                    .font(AppTheme.diegeticLabel(12))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.forestTeal)
                    Capsule()
                        .fill(AppTheme.pawStrollChain.opacity(0.45))
                        .scaleEffect(x: max(0.01, umbrellaProgress), anchor: .leading)
                }
            )
            .clipShape(Capsule())
            .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 5, y: 2)
            .onLongPressGesture(
                minimumDuration: 1.15,
                maximumDistance: 44,
                pressing: { pressing in
                    if pressing { startUmbrellaHold() } else { cancelUmbrellaHold() }
                },
                perform: {
                    completeGreeting(with: .holdUmbrella)
                }
            )
            .accessibilityLabel("按住撐傘陪\(petDisplayName)一起躲雨")
        }
    }

    @ViewBuilder
    private var departureButtons: some View {
        WoodPlaqueButton(
            title: "邀請回家看看",
            systemImage: "house.fill",
            tone: .forestTeal,
            fontSize: 13.5,
            horizontalPadding: 18,
            verticalPadding: 11
        ) {
            CozySoundEngine.shared.playCompassChime()
            coordinator.solveHomeRoomNow()
            coordinator.currentScreen = .home
        }

        WoodPlaqueButton(
            title: "收起日記繼續走",
            systemImage: "map.fill",
            tone: .warmCream,
            fontSize: 13.5,
            horizontalPadding: 16,
            verticalPadding: 11
        ) {
            CozySoundEngine.shared.playPaperFlip()
            coordinator.currentScreen = .street
        }
    }

    private var subtitleLabel: String {
        if let guideSpec {
            return committedLog != nil
                ? "\(guideSpec.name) 與 \(petSpec.name) · 雙寵水彩明信片已收錄"
                : "金色漫步連鎖 · \(guideSpec.name) 帶你遇見 \(petSpec.name)"
        }
        return committedLog != nil
            ? "\(petSpec.name) · 已貼進今日精裝日記"
            : "\(petSpec.name) · \(petSpec.kind.rawValue)"
    }

    private var openingWhisper: String {
        if let guideSpec {
            return "\(guideSpec.name)輕輕回頭示意——\(petSpec.name)正從乾燥的屋簷下打量你。"
        }
        if let res = resident, res.sharedDaysCount == 2, let g = res.firstGesture {
            return "\(petSpec.name)盯著你的腳步，似乎還記得那天「\(g.title)」。"
        }
        return "\(petSpec.name)停在乾爽的木凳旁，安靜地看著你攤開的手。"
    }

    private func startCobblestoneHold() {
        guard committedLog == nil else { return }
        isHoldingCobblestone = true
        holdProgress = 0
        holdRipplePulse = false
        withAnimation(reduceMotion ? nil : .easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
            holdRipplePulse = !reduceMotion
        }
        HapticsEngine.shared.startHoldToGreetPurr()
        holdTask?.cancel()
        holdTask = Task { @MainActor in
            for step in 1...50 {
                try? await Task.sleep(for: .milliseconds(50))
                if Task.isCancelled || !isHoldingCobblestone { return }
                holdProgress = CGFloat(step) / 50.0
                if step == 24 {
                    if petSpec.kind.isCatFamily {
                        CozySoundEngine.shared.playPetPurr()
                    } else {
                        CozySoundEngine.shared.playPetChirp()
                    }
                }
            }
        }
    }

    private func launchBallFlickRitual() {
        guard committedLog == nil, !isBallInFlight else { return }
        HapticsEngine.shared.playDogBallRoll()
        CozySoundEngine.shared.playPawTap()
        isBallInFlight = true
        ballRollingProgress = 0.0
        withAnimation(.easeOut(duration: 0.52)) {
            ballRollingProgress = 1.0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(460))
            lastPlayfulOverride = .pounceHop
            CozySoundEngine.shared.playPetChirp()
            try? await Task.sleep(for: .milliseconds(260))
            isBallInFlight = false
            completeGreeting(with: .rollBall)
        }
    }

    private func startUmbrellaHold() {
        guard committedLog == nil else { return }
        isHoldingUmbrella = true
        umbrellaProgress = 0
        HapticsEngine.shared.playPawRangeCue()
        umbrellaTask?.cancel()
        umbrellaTask = Task { @MainActor in
            for step in 1...23 {
                try? await Task.sleep(for: .milliseconds(50))
                if Task.isCancelled || !isHoldingUmbrella { return }
                withAnimation(.linear(duration: 0.05)) {
                    umbrellaProgress = CGFloat(step) / 23.0
                }
            }
        }
    }

    private func cancelUmbrellaHold() {
        umbrellaTask?.cancel()
        umbrellaTask = nil
        if committedLog == nil {
            withAnimation(.easeOut(duration: 0.2)) {
                isHoldingUmbrella = false
                umbrellaProgress = 0
            }
        }
    }

    private func cancelCobblestoneHold() {
        isHoldingCobblestone = false
        holdRipplePulse = false
        holdTask?.cancel()
        holdTask = nil
        HapticsEngine.shared.stopHoldToGreetPurr()
        if committedLog == nil {
            withAnimation(.easeOut(duration: 0.25)) { holdProgress = 0 }
        }
    }

    private func completeGreeting(with gesture: GreetingGesture) {
        guard committedLog == nil else { return }
        cancelCobblestoneHold()
        holdProgress = 1.0

        if let res = resident {
            let preview = NarrativeEngine.selectStreetScene(
                pet: res,
                secondaryStreetPet: guideSpec,
                anchorLabel: anchor?.customLabel ?? "麵包店巷口",
                weather: coordinator.activeWeather,
                chosenGesture: gesture,
                localDateISO: coordinator.currentLocalDateISO,
                pastEncounters: coordinator.encounters,
                activeIntentions: coordinator.teachingIntentions,
                activeOutingPack: coordinator.ledger.activeOutingPack
            )
            slipText = preview.streetSlipLine
        }

        if let log = coordinator.commitStreetEncounter(
            siteID: siteID,
            petID: petID,
            companionStreetPetID: companionStreetPetID,
            gesture: gesture,
            inviteHome: true
        ) {
            withAnimation(AppTheme.Motion.resolved(.bouncy, reduceMotion: reduceMotion)) {
                committedLog = log
                petTapBounce = 1.0
                greetingFeedback = coordinator.lastGreetingFeedback
                if let quest = coordinator.activeWalkQuestToday, quest.petID == petID, quest.progressSteps == 0 {
                    walkQuestOffer = quest
                }
            }
            if let gift = coordinator.awardStreetEncounterBonusGiftIfEligible(petID: petID) {
                withAnimation(AppTheme.Motion.resolved(.gentle, reduceMotion: reduceMotion)) {
                    bonusGiftWhisper = gift
                }
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(260))
                withAnimation(.easeOut(duration: 0.25)) { petTapBounce = 0.0 }
            }
            HapticsEngine.shared.playCurioUnpack()
            CozySoundEngine.shared.playPaperFlip()
        }
    }
}

/// Hand-painted forest-green watercolor umbrella dome with bouncing raindrop splashes!
private struct WatercolorUmbrellaCanopyOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let progress: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: AppTheme.Motion.interval(fps: 24.0, reduceMotion: reduceMotion))) { timeline in
            let t = reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let ink = Color(hex: "#1E3A38").opacity(0.75)

                // Canopy dome
                var dome = Path()
                dome.move(to: CGPoint(x: w * 0.12, y: h * 0.70))
                dome.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.70), control: CGPoint(x: w * 0.50, y: h * 0.06))
                // Scalloped lower umbrella hem
                dome.addQuadCurve(to: CGPoint(x: w * 0.69, y: h * 0.70), control: CGPoint(x: w * 0.78, y: h * 0.62))
                dome.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.70), control: CGPoint(x: w * 0.59, y: h * 0.62))
                dome.addQuadCurve(to: CGPoint(x: w * 0.31, y: h * 0.70), control: CGPoint(x: w * 0.40, y: h * 0.62))
                dome.addQuadCurve(to: CGPoint(x: w * 0.12, y: h * 0.70), control: CGPoint(x: w * 0.21, y: h * 0.62))
                dome.closeSubpath()

                ctx.fill(
                    dome,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "#467568"), Color(hex: "#274D46")]),
                        startPoint: CGPoint(x: w * 0.5, y: h * 0.12),
                        endPoint: CGPoint(x: w * 0.5, y: h * 0.72)
                    )
                )
                ctx.stroke(dome, with: .color(ink), lineWidth: 1.6)

                // Wooden finial tip & ribs
                var tip = Path()
                tip.move(to: CGPoint(x: w * 0.50, y: h * 0.18))
                tip.addLine(to: CGPoint(x: w * 0.50, y: h * 0.34))
                ctx.stroke(tip, with: .color(Color(hex: "#8A5E36")), style: StrokeStyle(lineWidth: 3, lineCap: .round))

                // Bouncing silver raindrops splashing softly off the dome!
                for idx in 0..<5 {
                    let phase = (t * 2.2 + Double(idx) * 0.21).truncatingRemainder(dividingBy: 1.0)
                    let rx = w * (0.24 + Double(idx) * 0.13)
                    let baseY = h * (0.48 - sin(Double(idx) / 4.0 * .pi) * 0.14)
                    let bounceY = baseY - CGFloat(sin(phase * .pi)) * 14
                    let alpha = sin(phase * .pi) * 0.75 * Double(progress)
                    let rect = CGRect(x: rx - 10, y: baseY - 16, width: 20, height: 20)
                    if SpriteFXLibrary.draw(.rainSplash, age: phase * SpriteFXKind.rainSplash.duration,
                                            in: rect, context: ctx, opacity: alpha) { continue }
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: rx - 2.2, y: bounceY - 2.2, width: 4.4, height: 4.4)),
                        with: .color(Color.white.opacity(alpha))
                    )
                }
            }
        }
    }
}
