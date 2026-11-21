import SwiftUI

/// 街角相遇全螢幕水彩劇場（台灣老街騎樓、暖黃紙燈籠、森林綠暖簾、長按 2.5 秒呼嚕共振）
struct SidewalkEncounterView: View {
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

    private var petSpec: PetSpec { PetCatalog.pet(id: petID) }
    private var guideSpec: PetSpec? { companionStreetPetID.map(PetCatalog.pet(id:)) }
    private var resident: PetResidentState? { coordinator.resident(for: petID) }
    private var guideResident: PetResidentState? { companionStreetPetID.flatMap { coordinator.resident(for: $0) } }
    private var anchor: AnchorSiteRecord? { coordinator.anchors.first(where: { $0.siteID == siteID }) }

    var body: some View {
        ZStack {
            SidewalkVignetteBackdrop(
                weather: coordinator.activeWeather,
                placeLabel: anchor?.customLabel ?? "麵包店巷口"
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        HapticsEngine.shared.stopHoldToGreetPurr()
                        coordinator.currentScreen = .street
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text(anchor?.customLabel ?? "街區地圖")
                                .font(AppTheme.serifBody(14))
                        }
                        .foregroundStyle(AppTheme.deepPineInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.warmPaper.opacity(0.92), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(coordinator.activeWeather.displayName)
                        .font(AppTheme.diegeticLabel(12))
                        .foregroundStyle(AppTheme.deepPineInk)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(AppTheme.warmPaper.opacity(0.88), in: Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                if let guideSpec {
                    HStack(spacing: -36) {
                        ProceduralPetRigView(
                            pet: guideSpec,
                            outfitID: guideResident?.activeOutfitID,
                            pose: .respond,
                            weatherMode: coordinator.activeWeather,
                            fingerFocusNormalized: fingerFocus,
                            isHappySquint: committedLog != nil
                        )
                        .frame(width: 215, height: 215)

                        ProceduralPetRigView(
                            pet: petSpec,
                            outfitID: resident?.activeOutfitID,
                            pose: committedLog != nil ? .respond : .notice,
                            weatherMode: coordinator.activeWeather,
                            fingerFocusNormalized: fingerFocus ?? (isHoldingCobblestone ? CGPoint(x: -0.5, y: 0.35) : nil),
                            isHappySquint: committedLog != nil || holdProgress > 0.65
                        )
                        .frame(width: 230, height: 230)
                    }
                } else {
                    ProceduralPetRigView(
                        pet: petSpec,
                        outfitID: resident?.activeOutfitID,
                        pose: committedLog != nil ? .respond : .notice,
                        weatherMode: coordinator.activeWeather,
                        fingerFocusNormalized: fingerFocus ?? (isHoldingCobblestone ? CGPoint(x: -0.5, y: 0.35) : nil),
                        isHappySquint: committedLog != nil || holdProgress > 0.65
                    )
                    .frame(width: 280, height: 280)
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

                TornPaperSlipView(
                    text: slipText.isEmpty ? openingWhisper : slipText,
                    subtitle: subtitleLabel
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)

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
                        ZStack {
                            Circle()
                                .fill(AppTheme.warmPaper.opacity(0.92))
                                .frame(width: 110, height: 110)
                                .shadow(color: AppTheme.deepPineInk.opacity(0.22), radius: 8, y: 4)

                            Circle()
                                .stroke(AppTheme.timberWarm.opacity(0.35), lineWidth: 5)
                                .frame(width: 100, height: 100)

                            Circle()
                                .trim(from: 0, to: holdProgress)
                                .stroke(
                                    AppTheme.pawStrollChain,
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 100, height: 100)

                            VStack(spacing: 3) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(AppTheme.forestTeal)
                                Text(isHoldingCobblestone ? "別急，保持輕放…" : "長按伸手招呼")
                                    .font(AppTheme.diegeticLabel(11))
                                    .foregroundStyle(AppTheme.deepPineInk)
                            }
                        }
                        .scaleEffect(isHoldingCobblestone ? 1.06 : 1.0)
                        .animation(.easeOut(duration: 0.2), value: isHoldingCobblestone)
                        .onLongPressGesture(
                            minimumDuration: 2.5,
                            maximumDistance: 44,
                            pressing: { pressing in
                                if pressing { startCobblestoneHold() } else { cancelCobblestoneHold() }
                            },
                            perform: { completeGreeting(with: .offerHand) }
                        )
                        .accessibilityLabel("長按 2.5 秒向\(petSpec.name)伸手打招呼")

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) { secondaryGestureButtons }
                            VStack(spacing: 8) { secondaryGestureButtons }
                        }
                    }
                    .padding(.bottom, 26)
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 14) { departureButtons }
                        VStack(spacing: 10) { departureButtons }
                    }
                    .padding(.bottom, 30)
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
        }
        .onDisappear {
            cancelCobblestoneHold()
        }
    }

    @ViewBuilder
    private var secondaryGestureButtons: some View {
        Button {
            HapticsEngine.shared.playPawRangeCue()
            completeGreeting(with: .crouchQuietly)
        } label: {
            Label("坐上木凳陪伴", systemImage: "chair.lounge.fill")
                .font(AppTheme.diegeticLabel(12))
                .foregroundStyle(AppTheme.deepPineInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.warmPaper.opacity(0.94), in: Capsule())
        }
        .buttonStyle(.plain)

        if !petSpec.kind.isCatFamily {
            Button {
                HapticsEngine.shared.playDogBallRoll()
                completeGreeting(with: .rollBall)
            } label: {
                Label("滾出縫布球", systemImage: "circle.dashed.inset.filled")
                    .font(AppTheme.diegeticLabel(12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.forestTeal, in: Capsule())
            }
            .buttonStyle(.plain)
        } else if coordinator.activeWeather.isRainy {
            Button {
                HapticsEngine.shared.playPawRangeCue()
                completeGreeting(with: .holdUmbrella)
            } label: {
                Label("撐傘一起躲雨", systemImage: "umbrella.fill")
                    .font(AppTheme.diegeticLabel(12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.forestTeal, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var departureButtons: some View {
        Button {
            coordinator.solveHomeRoomNow()
            coordinator.currentScreen = .home
        } label: {
            Label("邀請回家看看", systemImage: "house.fill")
                .font(AppTheme.diegeticLabel(14))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .background(AppTheme.forestTeal, in: Capsule())
        }
        .buttonStyle(.plain)

        Button {
            coordinator.currentScreen = .street
        } label: {
            Text("收起日記繼續走")
                .font(AppTheme.diegeticLabel(14))
                .foregroundStyle(AppTheme.deepPineInk)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .background(AppTheme.warmPaper.opacity(0.95), in: Capsule())
                .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
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
        HapticsEngine.shared.startHoldToGreetPurr()
        holdTask?.cancel()
        holdTask = Task { @MainActor in
            for step in 1...50 {
                try? await Task.sleep(for: .milliseconds(50))
                if Task.isCancelled || !isHoldingCobblestone { return }
                holdProgress = CGFloat(step) / 50.0
            }
        }
    }

    private func cancelCobblestoneHold() {
        isHoldingCobblestone = false
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
            committedLog = log
            HapticsEngine.shared.playCurioUnpack()
        }
    }
}

/// 精繪台灣老街麵包店騎樓水彩背景（暖木窗格、森林綠暖簾、紙燈籠柔光、濕潤青石板）
private struct SidewalkVignetteBackdrop: View {
    let weather: WeatherMode
    let placeLabel: String

    var body: some View {
        ZStack {
            LinearGradient(colors: skyColors, startPoint: .top, endPoint: .bottom)

            // 遠景老街樹影水彩暈染
            VStack {
                HStack {
                    Circle()
                        .fill(AppTheme.vineGreen.opacity(0.20))
                        .frame(width: 200, height: 200)
                        .offset(x: -70, y: 120)
                    Spacer()
                }
                Spacer()
            }

            // 溫暖木造麵包店櫥窗與柱子
            GeometryReader { geo in
                ZStack {
                    // 暖木店面牆
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#F4E4C4").opacity(0.88))
                        .frame(width: geo.size.width * 0.78, height: geo.size.height * 0.42)
                        .overlay(
                            // 木窗格與溫暖燈光
                            HStack(spacing: 0) {
                                Rectangle().fill(AppTheme.timberWarm.opacity(0.65)).frame(width: 10)
                                Spacer()
                                Rectangle().fill(AppTheme.timberWarm.opacity(0.55)).frame(width: 8)
                                Spacer()
                                Rectangle().fill(AppTheme.timberWarm.opacity(0.65)).frame(width: 10)
                            }
                        )
                        .overlay(
                            VStack {
                                Spacer()
                                Rectangle().fill(AppTheme.timberWarm.opacity(0.7)).frame(height: 8)
                                // 店面木腰板
                                Color(hex: "#B8895C").opacity(0.55).frame(height: 62)
                            }
                        )
                        .position(x: geo.size.width * 0.56, y: geo.size.height * 0.39)

                    // 屋頂紅檜木屋簷
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#9B6D43"), Color(hex: "#7D5431")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geo.size.width + 20, height: 68)
                        .position(x: geo.size.width * 0.5, y: 34)

                    // 森林綠布暖簾 (Noren)
                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.forestTeal.opacity(0.86))
                                .frame(height: 62)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(AppTheme.deepPineInk.opacity(0.35), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 12)
                    .position(x: geo.size.width * 0.5, y: 92)

                    // 左上角發光暖黃紙燈籠
                    ZStack {
                        Circle()
                            .fill(AppTheme.duskAmber.opacity(0.36))
                            .frame(width: 112, height: 112)
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "#FFF4CC"), Color(hex: "#F0A846"), Color(hex: "#C7712A")],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: 34
                                )
                            )
                            .frame(width: 56, height: 64)
                            .overlay(Ellipse().stroke(AppTheme.timberDeep.opacity(0.6), lineWidth: 1.4))
                    }
                    .position(x: 68, y: 158)
                }
            }

            // 青石板地面與微濕反光
            VStack {
                Spacer()
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#C8C1B4"), Color(hex: "#A59E92")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 320)

                    // 石階縫線與微光倒影
                    VStack(spacing: 42) {
                        Rectangle().fill(AppTheme.deepPineInk.opacity(0.18)).frame(height: 2)
                        HStack(spacing: 28) {
                            Ellipse().fill(AppTheme.duskAmber.opacity(0.24)).frame(width: 96, height: 22)
                            Ellipse().fill(AppTheme.warmPaper.opacity(0.25)).frame(width: 118, height: 24)
                            Ellipse().fill(AppTheme.rainySlate.opacity(0.20)).frame(width: 82, height: 20)
                        }
                    }
                }
            }

            if weather.isRainy {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { ctx, size in
                        for i in 0..<38 {
                            let xBase = CGFloat((i * 43) % Int(max(1, size.width)))
                            let yOffset = CGFloat((t * 165 + Double(i * 37)).truncatingRemainder(dividingBy: Double(max(1, size.height))))
                            var path = Path()
                            path.move(to: CGPoint(x: xBase, y: yOffset))
                            path.addLine(to: CGPoint(x: xBase - 9, y: yOffset + 26))
                            ctx.stroke(path, with: .color(AppTheme.warmPaper.opacity(0.45)), lineWidth: 1.1)
                        }
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }

    private var skyColors: [Color] {
        switch weather {
        case .lightRain, .postRain:
            return [Color(hex: "#B7CBD3"), Color(hex: "#E5E2D8")]
        case .dusk:
            return [Color(hex: "#E9C89B"), Color(hex: "#DFC3A8")]
        case .clearMorning:
            return [Color(hex: "#F2EFE1"), Color(hex: "#E4ECE5")]
        case .overcast:
            return [Color(hex: "#DFE0DA"), Color(hex: "#ECE9E0")]
        }
    }
}
