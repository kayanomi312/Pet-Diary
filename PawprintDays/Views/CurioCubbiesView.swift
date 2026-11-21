import SwiftUI

/// 拾遺木格櫃與刺繡步數幣袋（繁體中文）
struct CurioCubbiesView: View {
    @Bindable var coordinator: GameCoordinator
    @State private var selectedCategory: ShopItemSpec.Category = .wardrobe
    @State private var showPouchShop: Bool = false
    @State private var showVisitOptInPreview: Bool = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#E8DCC8"), Color(hex: "#D6C3A5")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        coordinator.currentScreen = .home
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("陽光室")
                                .font(AppTheme.diegeticLabel(13))
                        }
                        .foregroundStyle(AppTheme.deepPineInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.warmPaper, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("拾遺木格櫃")
                        .font(AppTheme.serifTitle(20))
                        .foregroundStyle(AppTheme.deepPineInk)

                    Spacer()

                    Button {
                        coordinator.currentScreen = .sketchbook
                    } label: {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.forestTeal)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.warmPaper, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("沿途撿回的街區小物")
                                .font(AppTheme.serifTitle(16))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Spacer()
                            Text("再走 \(coordinator.stepsUntilNextPocketFind) 步拾獲下一件")
                                .font(AppTheme.diegeticLabel(11))
                                .foregroundStyle(AppTheme.forestTeal)
                        }

                        if coordinator.ledger.foragedCurios.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "leaf.circle")
                                    .font(.system(size: 32))
                                    .foregroundStyle(AppTheme.timberDeep.opacity(0.6))
                                Text("紅檜木格還空著，帶著散步夥伴累積 1,400 步就能帶回第一件拾遺小物。")
                                    .font(AppTheme.handwritten(15))
                                    .foregroundStyle(AppTheme.softInk)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(AppTheme.warmPaper.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(coordinator.ledger.foragedCurios) { entry in
                                    let spec = CurioCatalog.curio(id: entry.curioID)
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            PaintedCurioStampView(curioID: entry.curioID, size: 38)
                                            Spacer()
                                            Text(entry.localDateISO)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundStyle(AppTheme.softInk)
                                        }
                                        Text(spec.name)
                                            .font(AppTheme.serifTitle(14))
                                            .foregroundStyle(AppTheme.deepPineInk)
                                        Text("\(entry.placeLabel) · \(spec.weatherTag.displayName)")
                                            .font(AppTheme.diegeticLabel(11))
                                            .foregroundStyle(AppTheme.forestTeal)
                                        Text(spec.journalNote)
                                            .font(AppTheme.handwritten(12))
                                            .foregroundStyle(AppTheme.softInk)
                                            .lineLimit(2)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.timberWarm.opacity(0.55), lineWidth: 2))
                                }
                            }
                        }

                        // 刺繡步數幣袋（平時不打擾與動物互動）
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("刺繡步數幣袋")
                                        .font(AppTheme.serifTitle(17))
                                        .foregroundStyle(AppTheme.deepPineInk)
                                    Text("每 200 步換 1 枚步數幣 · 跨日餘步 \(coordinator.ledger.stepCarryRemainder)/200")
                                        .font(AppTheme.serifBody(12))
                                        .foregroundStyle(AppTheme.softInk)
                                }
                                Spacer()
                                Text("\(coordinator.ledger.coinBalance) 幣")
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .foregroundStyle(AppTheme.forestTeal)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.parchmentTray, in: Capsule())
                            }

                            if let activePack = coordinator.ledger.activeOutingPack {
                                Text("下次散步已備妥：\(activePack.title)")
                                    .font(AppTheme.diegeticLabel(12))
                                    .foregroundStyle(AppTheme.vineGreen)
                            }

                            Button {
                                showPouchShop = true
                            } label: {
                                Label("打開街角紀念小舖", systemImage: "bag.fill")
                                    .font(AppTheme.diegeticLabel(13))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(AppTheme.forestTeal, in: Capsule())
                            }
                            .buttonStyle(.plain)

                            HStack(spacing: 10) {
                                Button {
                                    Task { await coordinator.optInAndSyncPedometer() }
                                } label: {
                                    Label(
                                        coordinator.pedometerService.isSyncing
                                            ? "同步步數中…"
                                            : (coordinator.ledger.pedometerOptIn ? "同步每日步數" : "用日常步數換步數幣"),
                                        systemImage: "figure.walk"
                                    )
                                    .font(AppTheme.diegeticLabel(12))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.parchmentTray, in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .disabled(coordinator.pedometerService.isSyncing)

                                Button {
                                    _ = coordinator.ingestSteps(steps: 1_400, intervalStartUTC: Date(), placeLabel: "鄰里散步")
                                } label: {
                                    Text("+1,400 步(模擬)")
                                        .font(AppTheme.diegeticLabel(12))
                                        .foregroundStyle(AppTheme.forestTeal)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(AppTheme.parchmentTray, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }

                            Divider()

                            Toggle(isOn: Binding(
                                get: { coordinator.ledger.mobilityRollModeEnabled },
                                set: { coordinator.toggleMobilityRollMode($0) }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("緩步里程與停留模式（無障礙平權）")
                                        .font(AppTheme.serifTitle(14))
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
                                        .font(AppTheme.serifTitle(14))
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
                        }
                        .padding(16)
                        .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.brassDark.opacity(0.45), lineWidth: 1.5))
                        .padding(.top, 8)
                    }
                    .padding(16)
                }
            }
        }
        .sheet(isPresented: $showPouchShop) {
            PouchShopDrawer(coordinator: coordinator, selectedCategory: $selectedCategory)
                .presentationDetents([.medium, .large])
        }
        .alert("替我記住停留較久的街角", isPresented: $showVisitOptInPreview) {
            Button("開啟長停留日記備註") {
                coordinator.toggleOptionalBackgroundVisits(true)
            }
            Button("先不用", role: .cancel) {}
        } message: {
            Text("只會留存在這支 iPhone 上的儲存範例：\n「11月18日 星期三 · 麵包店，午後。在熟悉的小街角安靜停駐了一會兒。」\n\n街角相遇完全不需要背景定位，且你隨時能單日抹除。")
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
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: item.swatchHex))
                                    .frame(width: 44, height: 44)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.deepPineInk.opacity(0.25)))

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
                                    Button("\(item.priceCoins)幣") {
                                        _ = coordinator.purchaseItem(item)
                                    }
                                    .font(AppTheme.diegeticLabel(13))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        coordinator.ledger.coinBalance >= item.priceCoins ? AppTheme.forestTeal : AppTheme.softInk.opacity(0.5),
                                        in: Capsule()
                                    )
                                    .disabled(coordinator.ledger.coinBalance < item.priceCoins)
                                }
                            }
                            .padding(12)
                            .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14))
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
