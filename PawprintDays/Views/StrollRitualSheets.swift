import SwiftUI

/// 出門前的「帆布散步袋」準備畫面（選同行奇幻夥伴 ＋ 選配單趟輕小物，空手也能免費出發）
struct StartStrollSatchelSheet: View {
    @Bindable var coordinator: GameCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPetID: String?
    @State private var selectedCharm: StrollSatchelCharm = .none

    init(coordinator: GameCoordinator) {
        self.coordinator = coordinator
        let invited = coordinator.residents.filter { $0.inviteState == .invitedHome }
        let defaultID = coordinator.activeWalkCompanionID ?? invited.first?.petID ?? "pet.01"
        _selectedPetID = State(initialValue: defaultID)
    }

    private var availableCompanions: [PetSpec] {
        let invitedIDs = Set(coordinator.residents.filter { $0.inviteState == .invitedHome }.map(\.petID))
        if invitedIDs.isEmpty {
            return Array(PetCatalog.allPets.prefix(4))
        }
        return PetCatalog.allPets.filter { invitedIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    StorybookPaperCard(cornerRadius: 18, accentColor: AppTheme.forestTeal, paddingAmount: 14) {
                        HStack(spacing: 10) {
                            Image(systemName: "figure.walk.motion")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(AppTheme.forestTeal)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("日常走路永遠自動計步，不開也能收集步數幣")
                                    .font(AppTheme.diegeticLabel(12.5))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text("按下出發散步可即時畫出水彩路線、帶上單趟帆布袋小物，返家領取專屬結算明信片。")
                                    .font(AppTheme.serifBody(12))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                        }
                    }

                    // 1. 選擇同行散步的奇幻夥伴
                    VStack(alignment: .leading, spacing: 10) {
                        Text("今天帶哪位夥伴一起出門？")
                            .font(AppTheme.serifTitle(16))
                            .foregroundStyle(AppTheme.deepPineInk)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(availableCompanions) { spec in
                                    let isSelected = (selectedPetID == spec.id)
                                    let outfitID = coordinator.resident(for: spec.id)?.activeOutfitID
                                    Button {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.72)) {
                                            selectedPetID = spec.id
                                        }
                                        HapticsEngine.shared.playBrushStrokeTick()
                                    } label: {
                                        VStack(spacing: 5) {
                                            ProceduralPetRigView(
                                                pet: spec,
                                                outfitID: outfitID,
                                                pose: .notice,
                                                weatherMode: coordinator.activeWeather,
                                                applyMetalPaperShader: false,
                                                isStaticSnapshot: true
                                            )
                                            .frame(width: 72, height: 72)

                                            Text(spec.name)
                                                .font(AppTheme.serifTitle(14))
                                                .foregroundStyle(AppTheme.deepPineInk)

                                            SpeciesFolkloreBadgeView(kind: spec.kind, showFullName: false)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(isSelected ? Color(hex: "#FFF9EA") : AppTheme.warmPaper.opacity(0.88))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(isSelected ? AppTheme.forestTeal : AppTheme.timberWarm.opacity(0.35), lineWidth: isSelected ? 2.2 : 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(TactileGameButtonStyle())
                                }
                            }
                        }
                    }

                    // 2. 帆布散步袋（1 格單趟選配輕小物，停下來或忘記關絕不空燒）
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("帆布散步袋（選配 · 絕不隨時間空燒）")
                                .font(AppTheme.serifTitle(16))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Spacer()
                            HStack(spacing: 4) {
                                PaintedPouchIconView(size: 18)
                                Text("\(coordinator.ledger.coinBalance) 幣")
                                    .font(AppTheme.diegeticLabel(12))
                                    .foregroundStyle(AppTheme.forestTeal)
                            }
                        }

                        VStack(spacing: 10) {
                            ForEach(StrollSatchelCharm.allCases) { charm in
                                let isSelected = (selectedCharm == charm)
                                let canAfford = coordinator.ledger.coinBalance >= charm.priceCoins
                                Button {
                                    guard canAfford else { return }
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.72)) {
                                        selectedCharm = charm
                                    }
                                    HapticsEngine.shared.playBrushStrokeTick()
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color(hex: charm.tintHex).opacity(0.18))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: charm.iconName)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundStyle(Color(hex: charm.tintHex))
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 6) {
                                                Text(charm.title)
                                                    .font(AppTheme.serifTitle(15))
                                                    .foregroundStyle(AppTheme.deepPineInk)
                                                if charm.priceCoins == 0 {
                                                    Text("免費")
                                                        .font(AppTheme.diegeticLabel(10))
                                                        .foregroundStyle(AppTheme.vineGreen)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(AppTheme.vineGreen.opacity(0.12), in: Capsule())
                                                } else {
                                                    Text("\(charm.priceCoins) 幣 / 趟")
                                                        .font(AppTheme.diegeticLabel(10))
                                                        .foregroundStyle(canAfford ? AppTheme.forestTeal : AppTheme.clothBookmark)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(AppTheme.parchmentTray, in: Capsule())
                                                }
                                            }
                                            Text(charm.subtitle)
                                                .font(AppTheme.serifBody(12))
                                                .foregroundStyle(AppTheme.softInk)
                                                .multilineTextAlignment(.leading)
                                        }

                                        Spacer(minLength: 4)

                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundStyle(isSelected ? AppTheme.forestTeal : AppTheme.timberWarm.opacity(0.55))
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(isSelected ? Color(hex: "#FFFDF7") : AppTheme.warmPaper.opacity(0.86))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(isSelected ? AppTheme.forestTeal : AppTheme.timberWarm.opacity(0.4), lineWidth: isSelected ? 2.0 : 1)
                                            )
                                    )
                                    .opacity(canAfford ? 1.0 : 0.55)
                                }
                                .buttonStyle(TactileGameButtonStyle(pressScale: 0.97, pressOffsetY: 1.5))
                                .disabled(!canAfford)
                            }
                        }
                    }

                    WoodPlaqueButton(
                        title: selectedCharm == .none
                            ? "繫好領巾，出發散步！"
                            : "裝進「\(selectedCharm.title)」並出發！",
                        systemImage: "pawprint.fill",
                        tone: .forestTeal,
                        fontSize: 15,
                        verticalPadding: 13,
                        fullWidth: true
                    ) {
                        if coordinator.startStrollSession(companionPetID: selectedPetID, charm: selectedCharm) {
                            dismiss()
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(18)
            }
            .background(AppTheme.parchmentTray)
            .navigationTitle("準備出門散步")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("稍後") { dismiss() }
                        .foregroundStyle(AppTheme.softInk)
                }
            }
        }
    }
}

/// 返家結算水彩明信片（散步收工時彈出：朱紅印章、同行夥伴、本次步數、水彩路線縮圖、拾遺與步數幣，並支援一鍵分享實體明信片圖檔！）
struct StrollSummaryPostcardSheet: View {
    let summary: CompletedStrollSummary
    let weather: WeatherMode
    let onDismiss: () -> Void
    @State private var renderedPostcardImage: UIImage? = nil

    private var companionSpec: PetSpec? {
        summary.companionPetID.map(PetCatalog.pet(id:))
    }

    var body: some View {
        ZStack {
            AppTheme.parchmentTray.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    postcardBody
                        .padding(.top, 12)

                    HStack(spacing: 10) {
                        if let rendered = renderedPostcardImage {
                            let shareImg = Image(uiImage: rendered)
                            ShareLink(
                                item: shareImg,
                                preview: SharePreview("足印日記 · \(CivilCalendarHelper.displayDate(from: summary.localDateISO))散步明信片", image: shareImg)
                            ) {
                                shareButtonLabel
                            }
                        } else {
                            ShareLink(
                                item: "足印日記 · \(CivilCalendarHelper.displayDate(from: summary.localDateISO))\n今天散步了 \(summary.totalSteps.formatted()) 步（約 \(summary.durationMinutes) 分鐘），遇見 \(summary.encountersCount) 個街角，收穫 +\(summary.coinsEarned) 枚步數幣！"
                            ) {
                                shareButtonLabel
                            }
                        }

                        WoodPlaqueButton(
                            title: "收進精裝日記",
                            systemImage: "book.closed.fill",
                            tone: .forestTeal,
                            fontSize: 14.5,
                            verticalPadding: 13,
                            fullWidth: true,
                            action: onDismiss
                        )
                    }
                }
                .padding(20)
            }
        }
        .onAppear {
            bakePostcardImage()
        }
    }

    private var shareButtonLabel: some View {
        HStack(spacing: 5) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 13, weight: .bold))
            Text("珍藏分享")
                .font(AppTheme.diegeticLabel(13.5))
        }
        .foregroundStyle(AppTheme.deepPineInk)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.timberWarm.opacity(0.65), lineWidth: 1.2))
    }

    @MainActor
    private func bakePostcardImage() {
        let renderer = ImageRenderer(
            content: postcardBody
                .padding(18)
                .frame(width: 360)
                .background(AppTheme.parchmentTray)
        )
        renderer.scale = 2.5
        renderedPostcardImage = renderer.uiImage
    }

    private var postcardBody: some View {
        ZStack(alignment: .topTrailing) {
            StorybookPaperCard(cornerRadius: 22, accentColor: AppTheme.timberWarm, showWashiTape: true, paddingAmount: 18) {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("今日散步結算明信片")
                                .font(AppTheme.serifTitle(20))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text("\(CivilCalendarHelper.displayDate(from: summary.localDateISO)) · 漫步約 \(summary.durationMinutes) 分鐘")
                                .font(AppTheme.diegeticLabel(12))
                                .foregroundStyle(AppTheme.softInk)
                        }
                        Spacer()
                    }

                    if let companionSpec {
                        HStack(spacing: 12) {
                            ProceduralPetRigView(
                                pet: companionSpec,
                                pose: .respond,
                                weatherMode: weather,
                                isHappySquint: true,
                                applyMetalPaperShader: false,
                                isStaticSnapshot: true
                            )
                            .frame(width: 96, height: 96)

                            VStack(alignment: .leading, spacing: 5) {
                                Text("同行夥伴：\(companionSpec.name)")
                                    .font(AppTheme.serifTitle(17))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                SpeciesFolkloreBadgeView(kind: companionSpec.kind)
                                if summary.packedCharm != .none {
                                    Text("帆布袋小物：\(summary.packedCharm.title)")
                                        .font(AppTheme.handwritten(13))
                                        .foregroundStyle(AppTheme.forestTeal)
                                }
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(AppTheme.parchmentTray.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))
                    }

                    // 散步收穫統計格
                    HStack(spacing: 10) {
                        strollStatBadge(title: "本次步數", value: "\(summary.totalSteps.formatted())", icon: "figure.walk", tint: AppTheme.forestTeal)
                        strollStatBadge(title: "遇見街角", value: "\(summary.encountersCount) 處", icon: "pawprint.fill", tint: AppTheme.pawInRange)
                        strollStatBadge(title: "收穫步數幣", value: "+\(summary.coinsEarned)", icon: "circle.fill", tint: AppTheme.pawStrollChain)
                    }

                    // 水彩路線縮圖
                    if summary.routePoints.count >= 2 {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("剛畫下的水彩散步足跡")
                                .font(AppTheme.diegeticLabel(11))
                                .foregroundStyle(AppTheme.softInk)
                            StrollRouteInkCanvas(points: summary.routePoints)
                                .frame(height: 76)
                                .background(AppTheme.parchmentTray.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.timberWarm.opacity(0.35), lineWidth: 1))
                        }
                    }

                    // 撿回的小物
                    if !summary.curiosFoundIDs.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("沿途帶回的口袋拾遺")
                                .font(AppTheme.diegeticLabel(11))
                                .foregroundStyle(AppTheme.forestTeal)
                            HStack(spacing: 8) {
                                ForEach(summary.curiosFoundIDs, id: \.self) { cid in
                                    HStack(spacing: 5) {
                                        PaintedCurioStampView(curioID: cid, size: 26)
                                        Text(CurioCatalog.curio(id: cid).name)
                                            .font(AppTheme.diegeticLabel(11.5))
                                            .foregroundStyle(AppTheme.deepPineInk)
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.parchmentTray, in: Capsule())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let bonus = summary.bonusNote {
                        TornPaperSlipView(text: bonus)
                    }
                }
            }

            HankoCelebrationStampView(
                title: "散步收錄 ✦",
                subtitle: "已夾進今日日記",
                stampColor: AppTheme.clothBookmark
            )
            .offset(x: -10, y: 12)
        }
    }

    private func strollStatBadge(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(AppTheme.serifTitle(16))
                .foregroundStyle(AppTheme.deepPineInk)
            Text(title)
                .font(AppTheme.diegeticLabel(10))
                .foregroundStyle(AppTheme.softInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.parchmentTray.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.35), lineWidth: 1))
    }
}

private struct StrollRouteInkCanvas: View {
    let points: [CoordinatePoint]

    var body: some View {
        Canvas { ctx, size in
            let lats = points.map(\.latitude)
            let lons = points.map(\.longitude)
            guard let minLat = lats.min(), let maxLat = lats.max(),
                  let minLon = lons.min(), let maxLon = lons.max() else { return }

            let latSpan = max(0.0002, maxLat - minLat)
            let lonSpan = max(0.0002, maxLon - minLon)
            let pad: CGFloat = 14

            var path = Path()
            for (idx, pt) in points.enumerated() {
                let x = pad + CGFloat((pt.longitude - minLon) / lonSpan) * (size.width - pad * 2)
                let y = size.height - pad - CGFloat((pt.latitude - minLat) / latSpan) * (size.height - pad * 2)
                if idx == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(
                path,
                with: .color(AppTheme.forestTeal.opacity(0.28)),
                style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
            )
            ctx.stroke(
                path,
                with: .color(AppTheme.pawInRange.opacity(0.85)),
                style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round, dash: [3, 6])
            )
        }
    }
}
