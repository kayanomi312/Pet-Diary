import SwiftUI

/// 拾遺木格櫃與刺繡步數幣袋（繁體中文）
struct CurioCubbiesView: View {
    @Bindable var coordinator: GameCoordinator
    @State private var selectedCategory: ShopItemSpec.Category = .wardrobe
    @State private var showPouchShop: Bool = false
    @State private var showVisitOptInPreview: Bool = false
    @State private var showWalkingSettings: Bool = false
    @State private var showFullCompendium: Bool = true
    @State private var confirmResetDiary: Bool = false

    private var discoveredCurioIDs: Set<String> {
        Set(coordinator.ledger.foragedCurios.map(\.curioID))
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            // 溫潤柔和暖棉紙與淺檜木色展示空間（告別過重深褐壓迫背景）
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
                        Text("已收藏 \(coordinator.ledger.foragedCurios.count) 件街區拾遺 · 袋中 \(coordinator.ledger.coinBalance) 步數幣")
                            .font(AppTheme.diegeticLabel(11))
                            .foregroundStyle(AppTheme.softInk)
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 統一暖棉紙展示櫃區塊（柔光淺暖木色系，與街區、陽光室、日記 100% 視覺一致！）
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("街區拾遺圖鑑 · \(discoveredCurioIDs.count)/\(CurioCatalog.all.count)")
                                        .font(AppTheme.serifTitle(16.5))
                                        .foregroundStyle(Color(hex: "#2F2A26"))
                                    Text("今日拾遺 \(coordinator.todaysPocketFindCount)/\(coordinator.dailyPocketFindCap) 件 · 再走 \(coordinator.stepsUntilNextPocketFind) 步拾獲下一件")
                                        .font(AppTheme.diegeticLabel(11))
                                        .foregroundStyle(AppTheme.forestTeal)
                                }
                                Spacer(minLength: 4)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showFullCompendium.toggle()
                                    }
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

                            if showFullCompendium {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(CurioCatalog.all) { spec in
                                        let foundEntry = coordinator.ledger.foragedCurios.first(where: { $0.curioID == spec.id })
                                        if let entry = foundEntry {
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    PaintedCurioStampView(curioID: spec.id, size: 42)
                                                    Spacer()
                                                    Text(entry.localDateISO)
                                                        .font(.system(size: 9.5, design: .monospaced))
                                                        .foregroundStyle(AppTheme.softInk)
                                                }
                                                Text(spec.name)
                                                    .font(AppTheme.serifTitle(14))
                                                    .foregroundStyle(AppTheme.deepPineInk)
                                                Text("\(entry.placeLabel) · \(spec.weatherTag.displayName)")
                                                    .font(AppTheme.diegeticLabel(10.5))
                                                    .foregroundStyle(AppTheme.forestTeal)
                                                Text(spec.journalNote)
                                                    .font(AppTheme.handwritten(12))
                                                    .foregroundStyle(AppTheme.softInk)
                                                    .lineLimit(2)
                                            }
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .fill(Color(hex: "#FFFDF8"))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                            .stroke(Color(hex: "#D5C5AE").opacity(0.70), lineWidth: 0.9)
                                                    )
                                            )
                                            .shadow(color: Color(hex: "#2D241E").opacity(0.07), radius: 6, y: 2)
                                        } else {
                                            // Undiscovered silhouette cubby in soft warm linen!
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    PaintedCurioStampView(curioID: spec.id, size: 38)
                                                        .saturation(0.0)
                                                        .opacity(0.30)
                                                    Spacer()
                                                    Image(systemName: spec.weatherTag.sfSymbol)
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(Color(hex: "#9A8A76"))
                                                }
                                                Text("尚未拾獲的小物")
                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    .foregroundStyle(Color(hex: "#6B5E50"))
                                                Text("\(spec.weatherTag.displayName)的「\(spec.placeCategory)」附近也許能撿到…")
                                                    .font(AppTheme.handwritten(11.5))
                                                    .foregroundStyle(Color(hex: "#8A7B68"))
                                                    .lineLimit(2)
                                            }
                                            .padding(12)
                                            .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
                                            .background(Color(hex: "#EFE7D8").opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color(hex: "#D5C5AE").opacity(0.55), lineWidth: 0.9)
                                            )
                                        }
                                    }
                                }
                            } else if coordinator.ledger.foragedCurios.isEmpty {
                                VStack(spacing: 10) {
                                    Text("拾遺展示櫃還空著，帶著散步夥伴累積 1,400 步就能帶回第一件拾遺小物。")
                                        .font(AppTheme.handwritten(14))
                                        .foregroundStyle(Color(hex: "#6B5E50"))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color(hex: "#EFE7D8").opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
                            } else {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(coordinator.ledger.foragedCurios) { entry in
                                        let spec = CurioCatalog.curio(id: entry.curioID)
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                PaintedCurioStampView(curioID: entry.curioID, size: 42)
                                                Spacer()
                                                Text(entry.localDateISO)
                                                    .font(.system(size: 9.5, design: .monospaced))
                                                    .foregroundStyle(AppTheme.softInk)
                                            }
                                            Text(spec.name)
                                                .font(AppTheme.serifTitle(14))
                                                .foregroundStyle(AppTheme.deepPineInk)
                                            Text("\(entry.placeLabel) · \(spec.weatherTag.displayName)")
                                                .font(AppTheme.diegeticLabel(10.5))
                                                .foregroundStyle(AppTheme.forestTeal)
                                            Text(spec.journalNote)
                                                .font(AppTheme.handwritten(12))
                                                .foregroundStyle(AppTheme.softInk)
                                                .lineLimit(2)
                                        }
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(hex: "#FFFDF8"))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(Color(hex: "#D5C5AE").opacity(0.70), lineWidth: 0.9)
                                                )
                                        )
                                        .shadow(color: Color(hex: "#2D241E").opacity(0.07), radius: 6, y: 2)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(hex: "#FAF5EB").opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color(hex: "#D5C5AE").opacity(0.65), lineWidth: 0.9)
                                )
                                .shadow(color: Color(hex: "#2D241E").opacity(0.08), radius: 10, y: 4)
                        )

                        // 刺繡步數幣袋卡片（立體手繪錢袋 ＋ 街角紀念小舖）
                        StorybookPaperCard(cornerRadius: 20, accentColor: AppTheme.brassDark, paddingAmount: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    PaintedPouchIconView(size: 46)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("刺繡步數幣袋")
                                            .font(AppTheme.serifTitle(17))
                                            .foregroundStyle(AppTheme.deepPineInk)
                                        Text("每 200 步換 1 枚 · 跨日餘步 \(coordinator.ledger.stepCarryRemainder)/200")
                                            .font(AppTheme.serifBody(12))
                                            .foregroundStyle(AppTheme.softInk)
                                    }
                                    Spacer()
                                    Text("\(coordinator.ledger.coinBalance) 幣")
                                        .font(.system(size: 20, weight: .bold, design: .serif))
                                        .foregroundStyle(AppTheme.forestTeal)
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.parchmentTray, in: Capsule())
                                        .overlay(Capsule().stroke(AppTheme.brassDark.opacity(0.5), lineWidth: 1.1))
                                }

                                if let activePack = coordinator.ledger.activeOutingPack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "backpack.fill")
                                            .foregroundStyle(AppTheme.vineGreen)
                                        Text("下次散步已備妥：\(activePack.title)")
                                            .font(AppTheme.diegeticLabel(12))
                                            .foregroundStyle(AppTheme.vineGreen)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.vineGreen.opacity(0.10), in: Capsule())
                                }

                                WoodPlaqueButton(
                                    title: "打開街角紀念小舖",
                                    systemImage: "bag.fill",
                                    tone: .forestTeal,
                                    fontSize: 13.5,
                                    verticalPadding: 11,
                                    fullWidth: true
                                ) {
                                    CozySoundEngine.shared.playCompassChime()
                                    showPouchShop = true
                                }

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

                                // 摺疊式散步設定（讓主畫面維持純粹的收藏展示櫃氣氛）
                                Divider()

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
                    .padding(16)
                    .padding(.bottom, 92)
                }
            }
        }
        .sheet(isPresented: $showPouchShop) {
            PouchShopDrawer(coordinator: coordinator, selectedCategory: $selectedCategory)
                .presentationDetents([.medium, .large])
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
}

private struct PouchShopDrawer: View {
    @Bindable var coordinator: GameCoordinator
    @Binding var selectedCategory: ShopItemSpec.Category
    @Environment(\.dismiss) private var dismiss

    private var filteredItems: [ShopItemSpec] {
        ShopCatalog.items.filter { $0.category == selectedCategory && $0.priceCoins > 0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Text("步數幣袋餘額：\(coordinator.ledger.coinBalance) 幣")
                        .font(AppTheme.serifTitle(15))
                        .foregroundStyle(AppTheme.forestTeal)
                    Spacer()
                    Text("日常照護永久免費")
                        .font(AppTheme.handwritten(13))
                        .foregroundStyle(AppTheme.softInk)
                }
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
                            let owned =
                                coordinator.ledger.ownedOutfitIDs.contains(item.id) ||
                                coordinator.ledger.ownedGoodieIDs.contains(item.id) ||
                                coordinator.ledger.ownedRoomThemeIDs.contains(item.id) ||
                                (item.id == "room.rain_veranda" && coordinator.ledger.verandaUnlocked)
                            HStack(spacing: 12) {
                                Group {
                                    if item.category == .wardrobe {
                                        PaintedOutfitMiniatureView(
                                            itemID: item.id,
                                            swatchHex: item.swatchHex,
                                            secondaryHex: item.secondaryHex,
                                            size: 46
                                        )
                                    } else if item.category == .goodies {
                                        PaintedGoodiePropView(
                                            goodieID: item.id,
                                            hasLovedPatina: false,
                                            hasStitchedPatch: false,
                                            isWide: false
                                        )
                                        .scaleEffect(0.42)
                                        .frame(width: 48, height: 44)
                                    } else {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(hex: item.swatchHex))
                                            .frame(width: 46, height: 46)
                                            .overlay(
                                                Image(systemName: item.category == .treats ? "takeoutbag.and.cup.and.straw.fill" : "sun.max.fill")
                                                    .foregroundStyle(.white.opacity(0.9))
                                            )
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.deepPineInk.opacity(0.25)))
                                    }
                                }
                                .background(AppTheme.parchmentTray, in: RoundedRectangle(cornerRadius: 12))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name)
                                        .font(AppTheme.serifTitle(15))
                                        .foregroundStyle(AppTheme.deepPineInk)
                                    Text(item.summary)
                                        .font(AppTheme.serifBody(12))
                                        .foregroundStyle(AppTheme.softInk)
                                }
                                Spacer()
                                if owned {
                                    Text("已擁有")
                                        .font(AppTheme.diegeticLabel(12))
                                        .foregroundStyle(AppTheme.vineGreen)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.parchmentTray, in: Capsule())
                                } else {
                                    WoodPlaqueButton(
                                        title: "\(item.priceCoins)幣",
                                        tone: coordinator.ledger.coinBalance >= item.priceCoins ? .forestTeal : .warmCream,
                                        fontSize: 12.5,
                                        horizontalPadding: 13,
                                        verticalPadding: 7
                                    ) {
                                        if coordinator.purchaseItem(item) {
                                            CozySoundEngine.shared.playCompassChime()
                                            HapticsEngine.shared.playCurioUnpack()
                                        }
                                    }
                                    .disabled(coordinator.ledger.coinBalance < item.priceCoins)
                                    .opacity(coordinator.ledger.coinBalance >= item.priceCoins ? 1.0 : 0.5)
                                }
                            }
                            .padding(12)
                            .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.timberWarm.opacity(0.40), lineWidth: 1.1))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)
                }
            }
            .padding(.top, 10)
            .background(AppTheme.parchmentTray)
            .navigationTitle("街角紀念小舖")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
