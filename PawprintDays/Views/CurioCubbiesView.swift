import SwiftUI

/// 刺繡步數幣袋、足印集章卡、拾遺木格櫃與街角紀念小舖（繁體中文）
struct CurioCubbiesView: View {
    @Bindable var coordinator: GameCoordinator
    @State private var selectedCategory: ShopItemSpec.Category = .wardrobe
    @State private var showPouchShop: Bool = false
    @State private var showVisitOptInPreview: Bool = false
    @State private var showWalkingSettings: Bool = false
    @State private var showFullCompendium: Bool = false
    @State private var confirmResetDiary: Bool = false

    private var discoveredCurioIDs: Set<String> {
        Set(coordinator.ledger.foragedCurios.map(\.curioID))
    }

    private var invitedCompanionIDs: [String] {
        coordinator.residents.filter { $0.inviteState == .invitedHome }.map(\.petID)
    }

    /// The cheapest item the player doesn't own yet: a gentle, concrete walking goal.
    private var nextShopGoal: ShopItemSpec? {
        ShopCatalog.items
            .filter { $0.priceCoins > 0 && !PouchShopOwnership.isOwned($0, ledger: coordinator.ledger) }
            .filter { $0.category != .treats }
            .min(by: { $0.priceCoins < $1.priceCoins })
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#F5EEE0"), Color(hex: "#EAE0CD")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("拾遺櫃與紀念小舖")
                            .font(AppTheme.serifTitle(22))
                            .foregroundStyle(AppTheme.deepPineInk)
                        Text("已收藏 \(discoveredCurioIDs.count) 種街區拾遺 · 蓋滿 \(coordinator.indoorState.completedStampCardsCount) 張集章卡")
                            .font(AppTheme.diegeticLabel(11))
                            .foregroundStyle(AppTheme.softInk)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        pouchAndStampCard
                        CedarCurioCabinetView(
                            coordinator: coordinator,
                            showFullCompendium: $showFullCompendium,
                            invitedCompanionIDs: invitedCompanionIDs
                        )
                        settingsCard
                    }
                    .padding(16)
                    .padding(.bottom, 104)
                }
            }
        }
        // While the shop sheet is up it hosts the celebration itself (so it shows above the sheet).
        .milestoneCelebrationOverlay(coordinator: coordinator, isEnabled: !showPouchShop)
        .onChange(of: showPouchShop) { _, isPresented in
            coordinator.isMilestoneSheetHostActive = isPresented
        }
        .onDisappear {
            coordinator.isMilestoneSheetHostActive = false
        }
        .sheet(isPresented: $showPouchShop) {
            PouchShopDrawer(coordinator: coordinator, selectedCategory: $selectedCategory)
                .presentationDetents([.large])
        }
        .confirmationDialog(
            "確定要重置所有日記並重新開始嗎？",
            isPresented: $confirmResetDiary,
            titleVisibility: .visible
        ) {
            Button("清除紀錄並重新開始", role: .destructive) {
                coordinator.resetAllGameData()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("這會清除本機所有日記、步數幣、街角與室友紀錄，回到全新空白狀態並開啟新手引導。")
        }
        .sheet(isPresented: $showVisitOptInPreview) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 14) {
                    StorybookPaperCard(cornerRadius: 18, accentColor: AppTheme.forestTeal, showWashiTape: true, paddingAmount: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("本機日記儲存範例")
                                .font(AppTheme.diegeticLabel(11))
                                .foregroundStyle(AppTheme.forestTeal)
                            Text("「11月18日 星期三 · 麵包店，午後。在熟悉的小街角安靜停駐了一會兒。」")
                                .font(AppTheme.handwritten(15))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text("街角相遇完全不需要背景定位；此功能 100% 只留在你的 iPhone 上，且隨時可單日抹除。")
                                .font(AppTheme.serifBody(12.5))
                                .foregroundStyle(AppTheme.softInk)
                        }
                    }

                    CutePlushButton(
                        title: "開啟長停留日記備註",
                        tone: .matchaMint,
                        fontSize: 13.5,
                        horizontalPadding: 16,
                        verticalPadding: 11,
                        icon: { Image(systemName: "checkmark.circle.fill").font(.system(size: 12, weight: .bold)) },
                        action: {
                            coordinator.toggleOptionalBackgroundVisits(true)
                            showVisitOptInPreview = false
                        }
                    )

                    Spacer()
                }
                .padding(18)
                .background(AppTheme.parchmentTray)
                .navigationTitle("替我記住停留較久的街角")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("先不用") { showVisitOptInPreview = false }
                    }
                }
            }
            .presentationDetents([.height(310)])
        }
    }

    // MARK: - 1. Embroidered pouch, shop CTA & 7-stamp cozy stamp card

    private var pouchAndStampCard: some View {
        StorybookPaperCard(cornerRadius: 22, accentColor: AppTheme.brassDark, showWashiTape: true, paddingAmount: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    PaintedPouchIconView(size: 50)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("刺繡步數幣袋")
                            .font(AppTheme.serifTitle(17))
                            .foregroundStyle(AppTheme.deepPineInk)
                        Text("每 200 步換 1 枚 · 餘步 \(coordinator.ledger.stepCarryRemainder)/200")
                            .font(AppTheme.serifBody(12))
                            .foregroundStyle(AppTheme.softInk)
                    }
                    Spacer(minLength: 4)
                    Text("\(coordinator.ledger.coinBalance) 幣")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.forestTeal)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background(AppTheme.parchmentTray, in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.brassDark.opacity(0.5), lineWidth: 1.1))
                        .accessibilityLabel("袋中 \(coordinator.ledger.coinBalance) 枚步數幣")
                }

                if let activePack = coordinator.ledger.activeOutingPack {
                    Label("下次散步已備妥：\(activePack.title)", systemImage: "backpack.fill")
                        .font(AppTheme.diegeticLabel(12))
                        .foregroundStyle(AppTheme.vineGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.vineGreen.opacity(0.10), in: Capsule())
                }

                WoodPlaqueButton(
                    title: "逛逛街角紀念小舖",
                    systemImage: "bag.fill",
                    tone: .forestTeal,
                    fontSize: 14,
                    verticalPadding: 12,
                    fullWidth: true
                ) {
                    CozySoundEngine.shared.playCompassChime()
                    showPouchShop = true
                }

                if let goal = nextShopGoal {
                    ShopWalkGoalBar(
                        label: "下一個小目標：\(goal.name)",
                        priceCoins: goal.priceCoins,
                        balance: coordinator.ledger.coinBalance,
                        carrySteps: coordinator.ledger.stepCarryRemainder
                    )
                }

                CozyStampCardView(
                    stampCount: coordinator.indoorState.stampCountInCard,
                    completedCards: coordinator.indoorState.completedStampCardsCount,
                    stampedToday: coordinator.hasEarnedCozyStampToday
                )

                WoodPlaqueButton(
                    title: coordinator.pedometerService.isSyncing
                        ? "同步步數中…"
                        : (coordinator.ledger.pedometerOptIn ? "同步每日步數" : "用步數換步數幣"),
                    systemImage: "figure.walk",
                    tone: .warmCream,
                    fontSize: 12.5,
                    horizontalPadding: 14,
                    verticalPadding: 10,
                    fullWidth: true
                ) {
                    Task { await coordinator.optInAndSyncPedometer() }
                }
                .disabled(coordinator.pedometerService.isSyncing)
            }
        }
    }

    // MARK: - 3. Walking preferences & accessibility

    private var settingsCard: some View {
        StorybookPaperCard(cornerRadius: 20, accentColor: AppTheme.timberWarm, paddingAmount: 14) {
            DisclosureGroup(isExpanded: $showWalkingSettings) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { CozySoundEngine.shared.isSoundEnabled },
                        set: { CozySoundEngine.shared.isSoundEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("療癒音效與環境雨聲")
                                .font(AppTheme.serifTitle(13.5))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text("包含翻頁聲、呼嚕聲、木地板踩踏聲與細雨白噪音（遵守靜音鍵）。")
                                .font(AppTheme.serifBody(11))
                                .foregroundStyle(AppTheme.softInk)
                        }
                    }
                    .tint(AppTheme.forestTeal)

                    Toggle(isOn: Binding(
                        get: { CozySoundEngine.shared.isMusicEnabled },
                        set: { CozySoundEngine.shared.isMusicEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("陽光室拇指琴輕音樂")
                                .font(AppTheme.serifTitle(13.5))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text("依晨光、細雨與黃昏自動切換柔和五聲和弦，絕不打斷手機背景音樂。")
                                .font(AppTheme.serifBody(11))
                                .foregroundStyle(AppTheme.softInk)
                        }
                    }
                    .tint(AppTheme.forestTeal)

                    Toggle(isOn: Binding(
                        get: { HapticsEngine.shared.isHapticsEnabled },
                        set: { HapticsEngine.shared.isHapticsEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("溫柔觸覺震動回饋")
                                .font(AppTheme.serifTitle(13.5))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text("包含長按貓咪呼嚕震動、走近街角雙輕點與開箱觸感。")
                                .font(AppTheme.serifBody(11))
                                .foregroundStyle(AppTheme.softInk)
                        }
                    }
                    .tint(AppTheme.forestTeal)

                    Toggle(isOn: Binding(
                        get: { coordinator.ledger.mobilityRollModeEnabled },
                        set: { coordinator.toggleMobilityRollMode($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("緩步里程與停留模式（無障礙平權）")
                                .font(AppTheme.serifTitle(13.5))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text("適合輪椅與輔具使用者：低速移動 130 公尺（<=10 km/h）或戶外停留 2 分鐘，等同 200 步換 1 幣與拾遺進度。")
                                .font(AppTheme.serifBody(11))
                                .foregroundStyle(AppTheme.softInk)
                        }
                    }
                    .tint(AppTheme.forestTeal)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("替我記住停留較久的街角")
                                .font(AppTheme.serifTitle(13.5))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text(coordinator.ledger.backgroundVisitsOptIn
                                 ? "已開啟 · 僅私密儲存在本機日記中。"
                                 : "選用的背景日記輔助（預設關閉）。")
                                .font(AppTheme.serifBody(11))
                                .foregroundStyle(AppTheme.softInk)
                        }
                        Spacer()
                        Button(coordinator.ledger.backgroundVisitsOptIn ? "暫停" : "查看範例") {
                            if coordinator.ledger.backgroundVisitsOptIn {
                                coordinator.toggleOptionalBackgroundVisits(false)
                            } else {
                                showVisitOptInPreview = true
                            }
                        }
                        .font(AppTheme.diegeticLabel(12))
                        .foregroundStyle(AppTheme.forestTeal)
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("新手玩法引導")
                                .font(AppTheme.serifTitle(13.5))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text("隨時重新瀏覽散步、陽光室與日記圖解教學。")
                                .font(AppTheme.serifBody(11))
                                .foregroundStyle(AppTheme.softInk)
                        }
                        Spacer()
                        Button("查看引導") {
                            CozySoundEngine.shared.playPaperFlip()
                            coordinator.reopenInteractiveTutorial()
                        }
                        .font(AppTheme.diegeticLabel(12))
                        .foregroundStyle(AppTheme.forestTeal)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("重新開始一本新日記")
                                .font(AppTheme.serifTitle(13.5))
                                .foregroundStyle(Color(hex: "#B5482B"))
                            Text("清除本機所有舊散步與收藏，從空白日記全新開始。")
                                .font(AppTheme.serifBody(11))
                                .foregroundStyle(AppTheme.softInk)
                        }
                        Spacer()
                        Button("重置日記") {
                            confirmResetDiary = true
                        }
                        .font(AppTheme.diegeticLabel(12))
                        .foregroundStyle(Color(hex: "#B5482B"))
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.softInk)
                    Text("散步偏好與無障礙設定")
                        .font(AppTheme.diegeticLabel(12))
                        .foregroundStyle(AppTheme.softInk)
                }
            }
            .tint(AppTheme.forestTeal)
        }
    }
}

// MARK: - Cozy 7-Stamp Card

/// Seven hanko slots. One stamp per day of play, never reset by missed days; 7 stamps → +15 coins.
struct CozyStampCardView: View {
    let stampCount: Int
    let completedCards: Int
    let stampedToday: Bool
    var compact: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var slotSize: CGFloat { compact ? 26 : 34 }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("足印集章卡 \(stampCount)/\(CozyStampCard.slotCount)")
                    .font(AppTheme.serifTitle(compact ? 13.5 : 15.5))
                    .foregroundStyle(AppTheme.deepPineInk)
                Spacer(minLength: 4)
                if completedCards > 0 {
                    Label("已蓋滿 \(completedCards) 張", systemImage: "seal.fill")
                        .font(AppTheme.diegeticLabel(10.5))
                        .foregroundStyle(AppTheme.clothBookmark)
                }
            }

            HStack(spacing: compact ? 5 : 7) {
                ForEach(0..<CozyStampCard.slotCount, id: \.self) { index in
                    stampSlot(index: index)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)

            if !compact {
                Text(stampedToday
                     ? "今天的印章蓋好了 ✓ 明天想出門時再來蓋下一枚。"
                     : "今天在街角打聲招呼、散步一小段，或完成三個小願望，就能蓋一枚章。")
                    .font(AppTheme.handwritten(13))
                    .foregroundStyle(stampedToday ? AppTheme.forestTeal : AppTheme.softInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text("蓋滿 7 枚送 +\(CozyStampCard.completionRewardCoins) 幣 · 錯過的日子不會清空")
                    .font(AppTheme.diegeticLabel(10.5))
                    .foregroundStyle(AppTheme.timberDeep.opacity(0.8))
            }
        }
        .padding(compact ? 10 : 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "#FBF3E4"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.clothBookmark.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("足印集章卡，已蓋 \(stampCount) 枚，共 \(CozyStampCard.slotCount) 枚。\(stampedToday ? "今天已蓋章。" : "今天還可以蓋一枚。")")
    }

    @ViewBuilder
    private func stampSlot(index: Int) -> some View {
        let filled = index < stampCount
        let isLast = index == CozyStampCard.slotCount - 1
        ZStack {
            Circle()
                .fill(filled ? AppTheme.clothBookmark.opacity(0.10) : Color(hex: "#F1E6D3"))
            Circle()
                .stroke(
                    filled ? AppTheme.clothBookmark.opacity(0.85) : Color(hex: "#C9B597").opacity(0.7),
                    style: StrokeStyle(lineWidth: filled ? 1.8 : 1.1, dash: filled ? [] : [3, 3])
                )
            if filled {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: slotSize * 0.42, weight: .bold))
                    .foregroundStyle(AppTheme.clothBookmark)
                    .rotationEffect(.degrees(Double((index * 37) % 24) - 12))
            } else if isLast {
                Image(systemName: "gift.fill")
                    .font(.system(size: slotSize * 0.36, weight: .semibold))
                    .foregroundStyle(AppTheme.pawStrollChain.opacity(0.75))
            } else {
                Text("\(index + 1)")
                    .font(.system(size: slotSize * 0.34, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#B19D80"))
            }
        }
        .frame(width: slotSize, height: slotSize)
        .scaleEffect(filled || reduceMotion ? 1 : 0.96)
    }
}

// MARK: - Walk-goal progress bar ("還差 X 幣 · 約走 Y 步")

struct ShopWalkGoalBar: View {
    let label: String?
    let priceCoins: Int
    let balance: Int
    let carrySteps: Int

    private var coinsShort: Int { max(0, priceCoins - balance) }
    private var stepsNeeded: Int {
        max(0, coinsShort * StepCoinLedgerEngine.stepsPerCoin - carrySteps)
    }
    private var fraction: Double {
        guard priceCoins > 0 else { return 1 }
        return min(1, Double(max(0, balance)) / Double(priceCoins))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let label {
                Text(label)
                    .font(AppTheme.diegeticLabel(11.5))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .lineLimit(1)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: "#EADFCB"))
                    Capsule()
                        .fill(LinearGradient(colors: [AppTheme.vineGreen, AppTheme.forestTeal], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, geo.size.width * fraction))
                }
            }
            .frame(height: 6)
            Text(coinsShort == 0 ? "已經可以帶回家了 ✦" : "還差 \(coinsShort) 幣 · 約走 \(stepsNeeded.formatted()) 步")
                .font(AppTheme.diegeticLabel(10.5))
                .foregroundStyle(coinsShort == 0 ? AppTheme.vineGreen : AppTheme.softInk)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 2. Warm cedar curio cabinet (拾遺木格櫃)

private enum CedarPalette {
    static let frameTop = Color(hex: "#9A6A43")
    static let frameBottom = Color(hex: "#6F4628")
    static let cubbyBack = Color(hex: "#E9D2AE")
    static let cubbyBackDeep = Color(hex: "#D9BC92")
    static let plankTop = Color(hex: "#B98552")
    static let plankBottom = Color(hex: "#7E522F")
    static let ink = Color(hex: "#3B2A1C")
    static let softInk = Color(hex: "#6B5440")
}

private struct CedarCurioCabinetView: View {
    @Bindable var coordinator: GameCoordinator
    @Binding var showFullCompendium: Bool
    let invitedCompanionIDs: [String]

    private var discoveredIDs: Set<String> {
        Set(coordinator.ledger.foragedCurios.map(\.curioID))
    }

    /// One cubby per catalog curio (full compendium) or per discovered kind (collection view).
    private var cubbies: [CurioSpec] {
        if showFullCompendium { return CurioCatalog.all }
        return CurioCatalog.all.filter { discoveredIDs.contains($0.id) }
    }

    private var shelfRows: [[CurioSpec]] {
        stride(from: 0, to: cubbies.count, by: 2).map { Array(cubbies[$0..<min($0 + 2, cubbies.count)]) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            weatherSetBadges

            VStack(spacing: 0) {
                if cubbies.isEmpty {
                    emptyShelf
                    shelfPlank
                } else {
                    ForEach(Array(shelfRows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 0) {
                            ForEach(row) { spec in
                                cubby(for: spec)
                                if spec.id != row.last?.id { shelfDivider }
                            }
                            if row.count == 1 {
                                shelfDivider
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        shelfPlank
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [CedarPalette.frameTop, CedarPalette.frameBottom], startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.18), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            .padding(3)
                    )
                    .shadow(color: Color(hex: "#2D241E").opacity(0.22), radius: 10, y: 5)
            )
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("拾遺木格櫃 · \(discoveredIDs.count)/\(CurioCatalog.all.count)")
                    .font(AppTheme.serifTitle(17))
                    .foregroundStyle(AppTheme.deepPineInk)
                Text("今日拾遺 \(coordinator.todaysPocketFindCount)/\(coordinator.dailyPocketFindCap) · 再走 \(coordinator.stepsUntilNextPocketFind.formatted()) 步拾獲下一件")
                    .font(AppTheme.diegeticLabel(11))
                    .foregroundStyle(AppTheme.forestTeal)
            }
            Spacer(minLength: 4)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showFullCompendium.toggle() }
            } label: {
                Text(showFullCompendium ? "只看已拾獲" : "看全圖鑑")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.forestTeal)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#FFFDF8"), in: Capsule())
                    .overlay(Capsule().stroke(Color(hex: "#D5C5AE").opacity(0.75), lineWidth: 0.9))
            }
            .buttonStyle(.plain)
        }
    }

    /// All five weather sets, always visible; a complete set glows and can be claimed with a tap.
    private var weatherSetBadges: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(coordinator.curioSetProgress) { set in
                let claimable = set.isComplete && !set.isClaimed
                Button {
                    if claimable { coordinator.claimCurioSetReward(weather: set.weather) }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: set.isClaimed ? "seal.fill" : set.weather.sfSymbol)
                            .font(.system(size: 11, weight: .bold))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(set.weather.displayName)
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            Text(claimable ? "領取 +\(set.rewardCoins)" : (set.isClaimed ? "已封蠟" : "\(set.foundCount)/\(set.totalCount)"))
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .opacity(0.85)
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(claimable ? .white : (set.isClaimed ? AppTheme.clothBookmark : AppTheme.deepPineInk))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(claimable ? AppTheme.forestTeal : Color(hex: set.isClaimed ? "#F6E7DA" : "#FFFDF8"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(claimable ? AppTheme.pawStrollChain : Color(hex: "#D5C5AE").opacity(0.75), lineWidth: claimable ? 1.6 : 0.9)
                    )
                    .shadow(color: claimable ? AppTheme.pawStrollChain.opacity(0.45) : .clear, radius: 6)
                }
                .buttonStyle(.plain)
                .disabled(!claimable)
                .accessibilityLabel("\(set.weather.displayName)拾遺套組 \(set.foundCount) / \(set.totalCount)\(claimable ? "，可領取 \(set.rewardCoins) 步數幣" : "")")
            }
        }
    }

    @ViewBuilder
    private func cubby(for spec: CurioSpec) -> some View {
        let entry = coordinator.ledger.foragedCurios.first(where: { $0.curioID == spec.id })
        VStack(spacing: 5) {
            if let entry {
                PaintedCurioStampView(curioID: spec.id, size: 44)
                    .shadow(color: Color.black.opacity(0.18), radius: 2, y: 2)
                    .accessibilityHidden(true)
                Text(spec.name)
                    .font(AppTheme.serifTitle(13))
                    .foregroundStyle(CedarPalette.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text("\(entry.placeLabel) · \(spec.weatherTag.displayName)")
                    .font(AppTheme.diegeticLabel(9.5))
                    .foregroundStyle(CedarPalette.softInk)
                    .lineLimit(1)
                curioGiftControl(for: entry)
            } else {
                PaintedCurioStampView(curioID: spec.id, size: 40)
                    .saturation(0)
                    .opacity(0.22)
                    .blendMode(.multiply)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.55), lineWidth: 1).offset(x: -0.6, y: -0.6)
                    )
                    .accessibilityHidden(true)
                Label(spec.weatherTag.displayName, systemImage: spec.weatherTag.sfSymbol)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(CedarPalette.softInk.opacity(0.85))
                    .labelStyle(.titleAndIcon)
                Text(spec.placeCategory)
                    .font(AppTheme.handwritten(11.5))
                    .foregroundStyle(CedarPalette.softInk.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 124)
        .background(recessedBack)
        .accessibilityElement(children: entry == nil ? .ignore : .contain)
        .accessibilityLabel(entry == nil ? "尚未拾獲：\(spec.weatherTag.displayName)時的\(spec.placeCategory)" : spec.name)
    }

    /// Recessed cedar box: a warm back panel with a soft top-left inner shadow.
    private var recessedBack: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(LinearGradient(colors: [CedarPalette.cubbyBackDeep, CedarPalette.cubbyBack], startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.black.opacity(0.28), Color.black.opacity(0.0)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
                    .blur(radius: 1.5)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            )
            .padding(3)
    }

    private var shelfDivider: some View {
        LinearGradient(colors: [CedarPalette.plankBottom, CedarPalette.plankTop, CedarPalette.plankBottom], startPoint: .leading, endPoint: .trailing)
            .frame(width: 6)
            .accessibilityHidden(true)
    }

    private var shelfPlank: some View {
        LinearGradient(colors: [CedarPalette.plankTop, CedarPalette.plankBottom], startPoint: .top, endPoint: .bottom)
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .shadow(color: Color.black.opacity(0.25), radius: 2, y: 2)
            .padding(.vertical, 3)
            .accessibilityHidden(true)
    }

    private var emptyShelf: some View {
        VStack(spacing: 6) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 22))
                .foregroundStyle(CedarPalette.softInk.opacity(0.5))
                .accessibilityHidden(true)
            Text("木格櫃還空著。帶著夥伴走滿 1,400 步，牠就會替你撿回第一件拾遺。")
                .font(AppTheme.handwritten(14))
                .foregroundStyle(CedarPalette.ink.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .padding(.horizontal, 12)
        .background(recessedBack)
    }

    @ViewBuilder
    private func curioGiftControl(for entry: ForagedCurioEntry) -> some View {
        if coordinator.isCurioGifted(entry) {
            Label("已送給夥伴", systemImage: "gift.fill")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(CedarPalette.softInk)
        } else if !invitedCompanionIDs.isEmpty {
            Menu {
                ForEach(invitedCompanionIDs, id: \.self) { petID in
                    Button(coordinator.displayName(for: petID)) {
                        coordinator.giftCurio(entryID: entry.id, to: petID)
                    }
                }
            } label: {
                Label("送給夥伴", systemImage: "gift")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.forestTeal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#FFFDF8").opacity(0.9), in: Capsule())
            }
        }
    }
}

// MARK: - Shop ownership helper

enum PouchShopOwnership {
    @MainActor
    static func isOwned(_ item: ShopItemSpec, ledger: WalletAndCurioLedger) -> Bool {
        ledger.ownedOutfitIDs.contains(item.id) ||
            ledger.ownedGoodieIDs.contains(item.id) ||
            ledger.ownedRoomThemeIDs.contains(item.id) ||
            (item.id == "room.rain_veranda" && ledger.verandaUnlocked)
    }

    /// The free starter theme, listed so a player can always switch back to it.
    static let springThemeItem = ShopItemSpec(
        id: SeasonalRoomTheme.springSunlit.rawValue,
        name: SeasonalRoomTheme.springSunlit.title,
        category: .rooms,
        priceCoins: 0,
        slotType: "interior_theme",
        swatchHex: "#CFA679",
        secondaryHex: "#EFE6D4",
        summary: "最初的暖木日光，隨時都能換回來。",
        capacitySlots: 1
    )
}

// MARK: - Pouch shop drawer

private struct PouchShopDrawer: View {
    @Bindable var coordinator: GameCoordinator
    @Binding var selectedCategory: ShopItemSpec.Category
    @Environment(\.dismiss) private var dismiss

    private var filteredItems: [ShopItemSpec] {
        let paid = ShopCatalog.items.filter { $0.category == selectedCategory && $0.priceCoins > 0 }
        if selectedCategory == .rooms {
            return [PouchShopOwnership.springThemeItem] + paid
        }
        return paid
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                CraftStallBanner(coinBalance: coordinator.ledger.coinBalance)
                    .padding(.horizontal, 18)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ShopItemSpec.Category.allCases, id: \.self) { cat in
                            Button(cat.rawValue) {
                                selectedCategory = cat
                            }
                            .font(AppTheme.diegeticLabel(12))
                            .foregroundStyle(selectedCategory == cat ? .white : AppTheme.deepPineInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(selectedCategory == cat ? AppTheme.forestTeal : AppTheme.warmPaper, in: Capsule())
                        }
                    }
                    .padding(.horizontal, 18)
                }

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredItems) { item in
                            itemRow(item)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, 10)
            .background(AppTheme.parchmentTray)
            .navigationTitle("街角紀念小舖")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .milestoneCelebrationOverlay(coordinator: coordinator)
        // Sheets inherit the environment; reset it so this presentation hosts its own overlay.
        .environment(\.milestoneCelebrationHosted, false)
    }

    @ViewBuilder
    private func itemArt(_ item: ShopItemSpec) -> some View {
        Group {
            if item.category == .wardrobe {
                PaintedOutfitMiniatureView(itemID: item.id, swatchHex: item.swatchHex, secondaryHex: item.secondaryHex, size: 46)
            } else if item.category == .goodies {
                PaintedGoodiePropView(goodieID: item.id, hasLovedPatina: false, hasStitchedPatch: false, isWide: false)
                    .scaleEffect(0.42)
                    .frame(width: 48, height: 44)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [Color(hex: item.secondaryHex), Color(hex: item.swatchHex)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: item.category == .treats ? "takeoutbag.and.cup.and.straw.fill" : (item.id == "room.rain_veranda" ? "house.lodge.fill" : "sun.max.fill"))
                            .foregroundStyle(.white.opacity(0.92))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.deepPineInk.opacity(0.25)))
            }
        }
        .background(AppTheme.parchmentTray, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func itemRow(_ item: ShopItemSpec) -> some View {
        let owned = item.priceCoins == 0 || PouchShopOwnership.isOwned(item, ledger: coordinator.ledger)
        let theme = SeasonalRoomTheme(rawValue: item.id)
        let affordable = coordinator.ledger.coinBalance >= item.priceCoins
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                itemArt(item)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(AppTheme.serifTitle(15))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Text(item.summary)
                        .font(AppTheme.serifBody(12))
                        .foregroundStyle(AppTheme.softInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                trailingControl(item: item, owned: owned, theme: theme, affordable: affordable)
            }
            if !owned && !affordable {
                ShopWalkGoalBar(
                    label: nil,
                    priceCoins: item.priceCoins,
                    balance: coordinator.ledger.coinBalance,
                    carrySteps: coordinator.ledger.stepCarryRemainder
                )
                .padding(.leading, 58)
            }
        }
        .padding(12)
        .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme != nil && coordinator.ledger.activeRoomTheme == theme ? AppTheme.pawStrollChain.opacity(0.8) : AppTheme.timberWarm.opacity(0.40), lineWidth: 1.1)
        )
    }

    @ViewBuilder
    private func trailingControl(item: ShopItemSpec, owned: Bool, theme: SeasonalRoomTheme?, affordable: Bool) -> some View {
        if owned, let theme {
            let isActive = coordinator.ledger.activeRoomTheme == theme
            Button {
                guard !isActive else { return }
                coordinator.selectRoomTheme(theme)
                CozySoundEngine.shared.playPaperFlip()
                HapticsEngine.shared.playBrushStrokeTick()
                coordinator.showWhisper("陽光室換上了「\(theme.title)」的光影。")
            } label: {
                Text(isActive ? "使用中 ✦" : "套用屋景")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(isActive ? AppTheme.brassDark : .white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(isActive ? AppTheme.pawStrollChain.opacity(0.14) : AppTheme.forestTeal, in: Capsule())
                    .overlay(Capsule().stroke(isActive ? AppTheme.pawStrollChain.opacity(0.6) : .clear, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isActive ? "\(theme.title)，使用中" : "套用\(theme.title)")
        } else if owned {
            Text("已擁有")
                .font(AppTheme.diegeticLabel(12))
                .foregroundStyle(AppTheme.vineGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.parchmentTray, in: Capsule())
        } else {
            WoodPlaqueButton(
                title: "\(item.priceCoins)幣",
                tone: affordable ? .forestTeal : .warmCream,
                fontSize: 12.5,
                horizontalPadding: 13,
                verticalPadding: 7
            ) {
                if coordinator.purchaseItem(item) {
                    CozySoundEngine.shared.playCompassChime()
                    HapticsEngine.shared.playCurioUnpack()
                }
            }
            .disabled(!affordable)
            .opacity(affordable ? 1.0 : 0.55)
        }
    }
}

/// Illustrated craft-stall header: a striped scalloped awning over the stall counter.
private struct CraftStallBanner: View {
    let coinBalance: Int

    var body: some View {
        VStack(spacing: 0) {
            Canvas { ctx, size in
                let stripes = 8
                let w = size.width / CGFloat(stripes)
                let bodyH = size.height * 0.62
                for i in 0..<stripes {
                    let rect = CGRect(x: CGFloat(i) * w, y: 0, width: w, height: bodyH)
                    ctx.fill(Path(rect), with: .color(i % 2 == 0 ? Color(hex: "#B84A39") : Color(hex: "#FBF1E1")))
                    let scallop = Path(ellipseIn: CGRect(x: CGFloat(i) * w, y: bodyH - w * 0.5, width: w, height: w))
                    ctx.fill(scallop, with: .color(i % 2 == 0 ? Color(hex: "#B84A39") : Color(hex: "#FBF1E1")))
                }
                ctx.stroke(Path(CGRect(x: 0, y: 0, width: size.width, height: 2)), with: .color(Color(hex: "#7E522F")), lineWidth: 3)
            }
            .frame(height: 30)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))

            HStack(spacing: 12) {
                PaintedPouchIconView(size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("巷口手作小攤")
                        .font(AppTheme.serifTitle(16))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Text("每一枚步數幣，都是一段慢慢走過的路")
                        .font(AppTheme.handwritten(12.5))
                        .foregroundStyle(AppTheme.softInk)
                }
                Spacer(minLength: 4)
                Text("\(coinBalance) 幣")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.forestTeal)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(AppTheme.parchmentTray, in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.brassDark.opacity(0.5), lineWidth: 1))
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(
                UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12)
                    .fill(LinearGradient(colors: [Color(hex: "#F3DFC2"), Color(hex: "#E2C49B")], startPoint: .top, endPoint: .bottom))
            )
        }
        .shadow(color: Color(hex: "#2D241E").opacity(0.12), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("巷口手作小攤，袋中 \(coinBalance) 枚步數幣")
    }
}
