import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 精裝手繪日記本（繁體中文：每日自動活動摘要、月曆總覽、單日地點抹除）
/// 完全不需要打字或上傳照片：每一頁都由當天的散步、相遇與拾遺自動寫成。
struct HardcoverSketchbookView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    enum DiaryTab: String, CaseIterable {
        case pages = "每日紀錄"
        case month = "月曆總覽"
    }

    @Bindable var coordinator: GameCoordinator
    @State private var activeTab: DiaryTab = .pages
    @State private var showSearch: Bool = false
    @State private var searchText: String = ""
    @State private var selectedPetFilter: String? = nil
    @State private var focusDateISO: String? = nil
    @State private var confirmEraseDateISO: String? = nil
    @State private var renameTargetSiteID: String? = nil
    @State private var renameText: String = ""
    @State private var backupExportURL: URL? = nil
    @State private var showBackupImporter: Bool = false
    @State private var showBackupPopover: Bool = false

    private var filteredDays: [DiaryDayRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return coordinator.diaryDays.filter { day in
            let dayEncounters = coordinator.encounters.filter { $0.localDateISO == day.localDateISO }
            if let petFilter = selectedPetFilter {
                let appeared = dayEncounters.contains(where: { $0.petID == petFilter || $0.secondaryPetID == petFilter }) || day.companionPetID == petFilter
                if !appeared { return false }
            }
            if !query.isEmpty {
                let matchesDate = day.localDateISO.lowercased().contains(query)
                let matchesEnc = dayEncounters.contains { enc in
                    PetCatalog.pet(id: enc.petID).name.lowercased().contains(query) ||
                    enc.siteDisplayLabel.lowercased().contains(query) ||
                    enc.narrativeLine.lowercased().contains(query)
                }
                return matchesDate || matchesEnc
            }
            return true
        }
    }

    /// 只列出已經遇見／邀請回家的夥伴，未相遇的動物不劇透。
    private var metResidents: [PetResidentState] {
        coordinator.residents.filter { $0.inviteState != .unmet }
    }

    private var discoveryIndex: DiaryDiscoveryIndex {
        DiaryDiscoveryIndex(residents: coordinator.residents, foraged: coordinator.ledger.foragedCurios)
    }

    private var isFilterActive: Bool {
        selectedPetFilter != nil || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            // 精裝布面精裝日記本底頁＋左側書脊裝訂陰影
            LinearGradient(
                colors: [Color(hex: "#EDE2CD"), Color(hex: "#E5D7BE")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            HStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: "#5B3E26").opacity(0.28), Color(hex: "#8F6A29").opacity(0.08), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 18)
                .ignoresSafeArea()
                Spacer()
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("足印手繪日記")
                            .font(AppTheme.serifTitle(22))
                            .foregroundStyle(AppTheme.deepPineInk)
                        Text("已自動寫下 \(coordinator.diaryDays.count) 頁時光")
                            .font(AppTheme.diegeticLabel(11))
                            .foregroundStyle(AppTheme.softInk)
                    }

                    Spacer()

                    if activeTab == .pages {
                        CozyIconCircleButton(
                            systemImage: "magnifyingglass",
                            tint: Color(hex: "#2F2A26"),
                            isActive: showSearch || isFilterActive,
                            size: 36,
                            accessibilityLabelText: showSearch ? "收合搜尋" : "搜尋日記"
                        ) {
                            CozySoundEngine.shared.playPaperFlip()
                            withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
                                showSearch.toggle()
                                if !showSearch {
                                    searchText = ""
                                    selectedPetFilter = nil
                                }
                            }
                        }
                    }

                    CozyIconCircleButton(
                        systemImage: "ellipsis",
                        tint: Color(hex: "#2F2A26"),
                        isActive: showBackupPopover,
                        size: 36,
                        accessibilityLabelText: "日記備份與還原"
                    ) {
                        CozySoundEngine.shared.playPaperFlip()
                        withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
                            showBackupPopover.toggle()
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // 手縫布書籤頁籤（取代制式 iOS Segmented Picker）
                StitchedClothTabBar(selection: $activeTab) { tab in
                    switch tab {
                    case .pages: return "book.pages.fill"
                    case .month: return "calendar"
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                switch activeTab {
                case .pages:
                    pagesListSection
                case .month:
                    MonthSpreadGridView(
                        days: coordinator.diaryDays,
                        encounters: coordinator.encounters,
                        curios: coordinator.ledger.foragedCurios,
                        discoveries: discoveryIndex,
                        referenceDate: coordinator.currentSimulatedDate,
                        onSelectDate: { iso in
                            searchText = ""
                            selectedPetFilter = nil
                            showSearch = false
                            focusDateISO = iso
                            activeTab = .pages
                        }
                    )
                }
            }

            if showBackupPopover {
                Color.black.opacity(0.06)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.18)) { showBackupPopover = false }
                    }
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 0) {
                            if let url = backupExportURL {
                                ShareLink(item: url) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(AppTheme.forestTeal)
                                            .frame(width: 26, height: 26)
                                            .background(Circle().fill(AppTheme.forestTeal.opacity(0.11)))
                                        Text("分享本機備份檔 (.json)")
                                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color(hex: "#2F2A26"))
                                        Spacer(minLength: 4)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    withAnimation(.easeOut(duration: 0.18)) { showBackupPopover = false }
                                })
                            }
                            Divider()
                                .overlay(Color(hex: "#E2D6C3").opacity(0.75))
                                .padding(.horizontal, 12)
                            Button {
                                HapticsEngine.shared.playBrushStrokeTick()
                                withAnimation(.easeOut(duration: 0.18)) { showBackupPopover = false }
                                showBackupImporter = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "tray.and.arrow.down")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#C98D26"))
                                        .frame(width: 26, height: 26)
                                        .background(Circle().fill(Color(hex: "#C98D26").opacity(0.11)))
                                    Text("從備份檔還原手記")
                                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#2F2A26"))
                                    Spacer(minLength: 4)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(width: 220)
                        .padding(.vertical, 4)
                        .background {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: "#FFFDF8").opacity(0.95)))
                                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(hex: "#D5C5AE").opacity(0.70), lineWidth: 0.9))
                                .shadow(color: Color(hex: "#2B211A").opacity(0.16), radius: 16, y: 8)
                        }
                    }
                    .padding(.top, 56)
                    .padding(.trailing, 18)
                    Spacer()
                }
                .transition(reduceMotion ? .opacity : .scale(scale: 0.92, anchor: .topTrailing).combined(with: .opacity))
            }
        }
        .confirmationDialog(
            "確定抹除這一天的地點與散步路線嗎？",
            isPresented: Binding(
                get: { confirmEraseDateISO != nil },
                set: { if !$0 { confirmEraseDateISO = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("抹除地點資料（保留室友與步數幣）", role: .destructive) {
                if let iso = confirmEraseDateISO {
                    coordinator.erasePlaceDataForSingleDay(localDateISO: iso)
                }
                confirmEraseDateISO = nil
            }
            Button("取消", role: .cancel) { confirmEraseDateISO = nil }
        } message: {
            Text("只會清除此頁的地點名稱與水彩軌跡。你遇見的動物夥伴、默契紀錄、拾遺小物與步數幣都將完整保留。")
        }
        .sheet(isPresented: Binding(
            get: { renameTargetSiteID != nil },
            set: { if !$0 { renameTargetSiteID = nil } }
        )) {
            KawaiiCornerRenameSheet(
                name: $renameText,
                onSave: {
                    if let siteID = renameTargetSiteID {
                        coordinator.renameAnchor(siteID: siteID, newLabel: renameText)
                    }
                    renameTargetSiteID = nil
                },
                onCancel: { renameTargetSiteID = nil }
            )
            .presentationDetents([.height(250)])
        }
        .fileImporter(
            isPresented: $showBackupImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let first = urls.first {
                let count = DiaryExportService.restoreJSONBackup(from: first, coordinator: coordinator)
                coordinator.showWhisper(count > 0 ? "已從備份安全還原 \(count) 筆手記與約定！" : "備份內容已是最新，未覆蓋任何紀錄。")
            }
        }
        .onAppear {
            backupExportURL = DiaryExportService.exportJSONBackup(coordinator: coordinator)
            // 翻開日記本，就自然完成「寫日記」的每日心願，不需要任何輸入。
            coordinator.markDailyWishCompleted(.writeDiary)
        }
    }

    private var pagesListSection: some View {
        VStack(spacing: 8) {
            if showSearch {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.softInk)
                        TextField("搜尋動物名字、街角或日期…", text: $searchText)
                            .font(AppTheme.serifBody(14))
                            .foregroundStyle(AppTheme.deepPineInk)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.softInk)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("清除搜尋")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.timberWarm.opacity(0.35)))
                    .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            BookmarkFilterPill(title: "全部日子", active: selectedPetFilter == nil) {
                                selectedPetFilter = nil
                            }
                            ForEach(metResidents, id: \.petID) { resident in
                                let name = PetCatalog.pet(id: resident.petID).name
                                BookmarkFilterPill(title: name, active: selectedPetFilter == resident.petID) {
                                    selectedPetFilter = (selectedPetFilter == resident.petID) ? nil : resident.petID
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            let index = discoveryIndex
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 18) {
                        if filteredDays.isEmpty {
                            Text(coordinator.diaryDays.isEmpty
                                 ? "日記本還空著——出門散步後，每一天都會自動寫成一頁。"
                                 : "沒有找到符合的日子，換個關鍵字再翻翻看。")
                                .font(AppTheme.handwritten(14))
                                .foregroundStyle(AppTheme.softInk)
                                .multilineTextAlignment(.center)
                                .padding(24)
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 16))
                        }
                        ForEach(filteredDays, id: \.localDateISO) { day in
                            SketchbookDayPageCard(
                                day: day,
                                encounters: coordinator.encounters.filter { $0.localDateISO == day.localDateISO },
                                newPets: index.newPets(on: day.localDateISO),
                                curios: index.curios(on: day.localDateISO),
                                outfitIDForPet: { petID in
                                    coordinator.residents.first(where: { $0.petID == petID })?.activeOutfitID
                                },
                                onRequestErasePlace: { confirmEraseDateISO = day.localDateISO },
                                onRenameStop: { siteID, currentLabel in
                                    renameTargetSiteID = siteID
                                    renameText = currentLabel
                                },
                                onRemoveEncounter: { uuid in
                                    coordinator.removeEncounter(uuid: uuid)
                                },
                                pinnedPostcardEncounterID: coordinator.indoorState.pinnedPostcardEncounterID,
                                onTogglePinPostcard: { encounterID in
                                    let isCurrentlyPinned = (coordinator.indoorState.pinnedPostcardEncounterID == encounterID)
                                    coordinator.pinPostcardToSunroomWall(encounterID: isCurrentlyPinned ? nil : encounterID)
                                }
                            )
                            .id(day.localDateISO)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 104)
                }
                .onAppear { scrollToFocusedDay(proxy) }
                .onChange(of: focusDateISO) { _, _ in scrollToFocusedDay(proxy) }
            }
        }
    }

    private func scrollToFocusedDay(_ proxy: ScrollViewProxy) {
        guard let iso = focusDateISO else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
                proxy.scrollTo(iso, anchor: .top)
            }
            focusDateISO = nil
        }
    }
}

// MARK: - 自動新發現索引（初次遇見的夥伴、拾遺首次紀錄）

private struct DiscoveredCurio: Identifiable {
    let entry: ForagedCurioEntry
    let isFirstEver: Bool
    var id: UUID { entry.id }
}

private struct DiaryDiscoveryIndex {
    let residents: [PetResidentState]
    let foraged: [ForagedCurioEntry]
    private let firstEntryIDByCurio: [String: UUID]

    init(residents: [PetResidentState], foraged: [ForagedCurioEntry]) {
        self.residents = residents
        self.foraged = foraged
        // 拾遺清單為新到舊（insert at 0）；同日以陣列中較後面者視為較早。
        var best: [String: (date: String, index: Int, id: UUID)] = [:]
        for (i, entry) in foraged.enumerated() {
            if let current = best[entry.curioID] {
                if entry.localDateISO < current.date || (entry.localDateISO == current.date && i > current.index) {
                    best[entry.curioID] = (entry.localDateISO, i, entry.id)
                }
            } else {
                best[entry.curioID] = (entry.localDateISO, i, entry.id)
            }
        }
        self.firstEntryIDByCurio = best.mapValues(\.id)
    }

    func newPets(on iso: String) -> [PetResidentState] {
        residents.filter { $0.firstMetDateISO == iso }
    }

    func curios(on iso: String) -> [DiscoveredCurio] {
        foraged
            .filter { $0.localDateISO == iso }
            .map { DiscoveredCurio(entry: $0, isFirstEver: firstEntryIDByCurio[$0.curioID] == $0.id) }
    }

    /// 該日有任何新發現（初遇夥伴或拾得小物）
    func discoveryDates() -> Set<String> {
        var dates = Set<String>()
        for r in residents { if let d = r.firstMetDateISO { dates.insert(d) } }
        for c in foraged { dates.insert(c.localDateISO) }
        return dates
    }
}

private struct MonthSpreadGridView: View {
    let days: [DiaryDayRecord]
    let encounters: [EncounterLog]
    let curios: [ForagedCurioEntry]
    let discoveries: DiaryDiscoveryIndex
    let referenceDate: Date
    let onSelectDate: (String) -> Void

    @State private var displayedYear: Int
    @State private var displayedMonth: Int
    @State private var monthlyPDFURL: URL? = nil

    private let weekdayHeaders = ["日", "一", "二", "三", "四", "五", "六"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    init(
        days: [DiaryDayRecord],
        encounters: [EncounterLog],
        curios: [ForagedCurioEntry],
        discoveries: DiaryDiscoveryIndex,
        referenceDate: Date,
        onSelectDate: @escaping (String) -> Void
    ) {
        self.days = days
        self.encounters = encounters
        self.curios = curios
        self.discoveries = discoveries
        self.referenceDate = referenceDate
        self.onSelectDate = onSelectDate
        let comps = Calendar.current.dateComponents([.year, .month], from: referenceDate)
        self._displayedYear = State(initialValue: comps.year ?? 2026)
        self._displayedMonth = State(initialValue: comps.month ?? 11)
    }

    private var monthPrefix: String {
        String(format: "%04d-%02d-", displayedYear, displayedMonth)
    }

    private var monthDayMap: [Int: DiaryDayRecord] {
        var map: [Int: DiaryDayRecord] = [:]
        for d in days where d.localDateISO.hasPrefix(monthPrefix) {
            let dayNum = CivilCalendarHelper.dayNumber(from: d.localDateISO)
            map[dayNum] = d
        }
        return map
    }

    private var calendarCells: [Int?] {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = displayedYear
        comps.month = displayedMonth
        comps.day = 1
        guard let firstOfMonth = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }
        let leadingBlanks = cal.component(.weekday, from: firstOfMonth) - 1 // 1 = Sun -> 0 blanks
        var cells: [Int?] = Array(repeating: nil, count: max(0, leadingBlanks))
        for d in range { cells.append(d) }
        return cells
    }

    private var monthStepsTotal: Int {
        days.filter { $0.localDateISO.hasPrefix(monthPrefix) }.reduce(0) { $0 + $1.acceptedSteps }
    }

    private var monthCuriosCount: Int {
        curios.filter { $0.localDateISO.hasPrefix(monthPrefix) }.count
    }

    private var monthEncounters: [EncounterLog] {
        encounters.filter { $0.localDateISO.hasPrefix(monthPrefix) }
    }

    private var monthLocationCount: Int {
        Set(monthEncounters.filter { !$0.placeRedacted }.map(\.siteID)).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Month navigation header (< 2026年11月 >)
                HStack {
                    Button { shiftMonth(by: -1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.deepPineInk)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.warmPaper, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("上一個月")

                    Spacer()

                    Text("\(String(displayedYear))年\(displayedMonth)月")
                        .font(AppTheme.serifTitle(20))
                        .foregroundStyle(AppTheme.deepPineInk)

                    Spacer()

                    Button { shiftMonth(by: 1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.deepPineInk)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.warmPaper, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("下一個月")
                }

                // Sun..Sat column headers
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(weekdayHeaders, id: \.self) { label in
                        Text(label)
                            .font(AppTheme.diegeticLabel(11))
                            .foregroundStyle(label == "日" || label == "六" ? AppTheme.clothBookmark : AppTheme.softInk)
                            .frame(maxWidth: .infinity)
                    }
                }

                // True 7-Column Calendar Grid
                let map = monthDayMap
                let discoverySet = discoveries.discoveryDates()
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(calendarCells.enumerated()), id: \.offset) { _, dayNum in
                        if let dayNum {
                            if let record = map[dayNum] {
                                let dayEncs = encounters.filter { $0.localDateISO == record.localDateISO }
                                Button {
                                    onSelectDate(record.localDateISO)
                                } label: {
                                    VStack(spacing: 3) {
                                        HStack(spacing: 2) {
                                            Text("\(dayNum)")
                                                .font(.system(size: 12, weight: .bold, design: .serif))
                                                .foregroundStyle(AppTheme.deepPineInk)
                                            if discoverySet.contains(record.localDateISO) {
                                                Circle()
                                                    .fill(AppTheme.pawStrollChain)
                                                    .frame(width: 5, height: 5)
                                                    .shadow(color: AppTheme.pawStrollChain.opacity(0.6), radius: 2)
                                                    .accessibilityLabel("這天有新發現")
                                            }
                                        }
                                        Image(systemName: record.weatherMode.sfSymbol)
                                            .font(.system(size: 10))
                                            .foregroundStyle(AppTheme.forestTeal)

                                        HStack(spacing: 2) {
                                            ForEach(dayEncs.prefix(3), id: \.encounterUUID) { enc in
                                                Circle()
                                                    .fill(Color(hex: PetCatalog.pet(id: enc.petID).primaryCoatHex))
                                                    .frame(width: 5.5, height: 5.5)
                                            }
                                        }
                                        .frame(height: 6)
                                    }
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity, minHeight: 58)
                                    .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 1.0)
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                // Gentle cream blank paper day cell
                                VStack {
                                    Text("\(dayNum)")
                                        .font(.system(size: 11, weight: .regular, design: .serif))
                                        .foregroundStyle(AppTheme.softInk.opacity(0.48))
                                    Spacer()
                                }
                                .padding(.top, 6)
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .background(AppTheme.warmPaper.opacity(0.42), in: RoundedRectangle(cornerRadius: 10))
                            }
                        } else {
                            Color.clear.frame(height: 58)
                        }
                    }
                }

                // Warm Monthly Reflection Footer + Printable Watercolor PDF Storybook Export!
                StorybookPaperCard(cornerRadius: 18, accentColor: AppTheme.timberWarm, showWashiTape: true, paddingAmount: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("本月散步小結")
                            .font(AppTheme.serifTitle(16))
                            .foregroundStyle(AppTheme.deepPineInk)
                        if map.isEmpty {
                            Text("這個月還沒有足跡，帶著夥伴出門走走吧。")
                                .font(AppTheme.handwritten(14))
                                .foregroundStyle(AppTheme.softInk)
                        } else {
                            Text("這個月一共散步了 \(map.count) 天，走了 \(monthStepsTotal.formatted()) 步。")
                                .font(AppTheme.handwritten(14))
                                .foregroundStyle(AppTheme.forestTeal)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                summaryStat(value: map.count.formatted(), label: "散步天數")
                                summaryStat(value: monthStepsTotal.formatted(), label: "總步數")
                                summaryStat(value: monthLocationCount.formatted(), label: "走訪街角")
                                summaryStat(value: monthEncounters.count.formatted(), label: "街角相遇")
                                summaryStat(value: monthCuriosCount.formatted(), label: "拾得小物")
                            }
                        }

                        if let pdfURL = monthlyPDFURL {
                            ShareLink(item: pdfURL) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.richtext.fill")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("匯出・分享本月水彩繪本 PDF")
                                        .font(AppTheme.diegeticLabel(12.5))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(AppTheme.forestTeal, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 104)
        }
        .onAppear { regenerateMonthlyPDF() }
        .onChange(of: displayedYear) { _, _ in regenerateMonthlyPDF() }
        .onChange(of: displayedMonth) { _, _ in regenerateMonthlyPDF() }
    }

    private func summaryStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.deepPineInk)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(AppTheme.diegeticLabel(10.5))
                .foregroundStyle(AppTheme.softInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.parchmentTray.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
    }

    private func shiftMonth(by delta: Int) {
        var m = displayedMonth + delta
        var y = displayedYear
        while m < 1 { m += 12; y -= 1 }
        while m > 12 { m -= 12; y += 1 }
        displayedYear = y
        displayedMonth = m
    }

    private func regenerateMonthlyPDF() {
        monthlyPDFURL = DiaryExportService.exportMonthlyPDF(
            year: displayedYear,
            month: displayedMonth,
            days: days,
            encounters: encounters,
            curios: curios
        )
    }
}

private struct SketchbookDayPageCard: View {
    let day: DiaryDayRecord
    let encounters: [EncounterLog]
    let newPets: [PetResidentState]
    let curios: [DiscoveredCurio]
    let outfitIDForPet: (String) -> String?
    let onRequestErasePlace: () -> Void
    let onRenameStop: (String, String) -> Void
    let onRemoveEncounter: (UUID) -> Void
    let pinnedPostcardEncounterID: UUID?
    let onTogglePinPostcard: (UUID) -> Void

    private var companionPetID: String? {
        day.companionPetID ?? encounters.first?.petID
    }

    private var visitedLabels: [String] {
        var seen = Set<String>()
        var labels: [String] = []
        for enc in encounters where !enc.placeRedacted {
            if seen.insert(enc.siteDisplayLabel).inserted { labels.append(enc.siteDisplayLabel) }
        }
        return labels
    }

    private var visitedCornerCount: Int {
        Set(encounters.filter { !$0.placeRedacted }.map(\.siteID)).count
    }

    private var isQuietDay: Bool {
        day.acceptedSteps == 0 && encounters.isEmpty
    }

    private var headline: String {
        if isQuietDay { return "在陽光室度過安靜療癒的一天" }
        if let id = companionPetID {
            let name = PetCatalog.pet(id: id).name
            return day.acceptedSteps > 0
                ? "與 \(name) 散步了 \(day.acceptedSteps.formatted()) 步"
                : "與 \(name) 在街角相遇"
        }
        return "出門散步了 \(day.acceptedSteps.formatted()) 步"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            summaryBanner

            if !visitedLabels.isEmpty || !encounters.isEmpty {
                locationsSection
            }

            if !newPets.isEmpty || !curios.isEmpty {
                discoveriesSection
            }

            if !day.revisitNotes.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    sectionLabel("當日足跡", systemImage: "pawprint.fill", tint: AppTheme.timberDeep)
                    ForEach(day.revisitNotes, id: \.self) { note in
                        Text("• \(note)")
                            .font(AppTheme.serifBody(13))
                            .foregroundStyle(AppTheme.softInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.parchmentTray.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
            }

            let trailPoints = LocationService.decodeTrailGeoJSON(day.routeTrackGeoJSON)
            if trailPoints.count >= 2, MiniInkWashRouteCanvas.hasVisibleSpread(trailPoints) {
                VStack(alignment: .leading, spacing: 5) {
                    sectionLabel("散步墨彩路線", systemImage: "scribble.variable", tint: AppTheme.softInk)
                    MiniInkWashRouteCanvas(points: trailPoints)
                        .frame(height: 84)
                        .background(AppTheme.parchmentTray.opacity(0.65), in: RoundedRectangle(cornerRadius: 12))
                }
            }

            HStack {
                Text(day.weatherAttribution)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.softInk)
                Spacer()
                if day.deletionState != .placeErased {
                    Button("抹除本日地點", action: onRequestErasePlace)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.clothBookmark)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFFDF8"), Color(hex: "#F8F2E7")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: "#D5C5AE").opacity(0.65), lineWidth: 0.9)
                )
        )
        .shadow(color: Color(hex: "#2D241E").opacity(0.09), radius: 10, y: 4)
    }

    // MARK: Banner

    private var summaryBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            companionPortrait

            VStack(alignment: .leading, spacing: 5) {
                Text(CivilCalendarHelper.displayDate(from: day.localDateISO))
                    .font(AppTheme.diegeticLabel(11.5))
                    .foregroundStyle(AppTheme.softInk)
                Text(headline)
                    .font(AppTheme.serifTitle(17))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .fixedSize(horizontal: false, vertical: true)

                FlowChipRow {
                    infoPill(systemImage: day.weatherMode.sfSymbol, text: day.weatherMode.displayName, tint: AppTheme.forestTeal)
                    if day.acceptedSteps > 0 {
                        infoPill(systemImage: "figure.walk", text: "\(day.acceptedSteps.formatted()) 步", tint: AppTheme.timberDeep)
                    }
                    if visitedCornerCount > 0 {
                        infoPill(systemImage: "mappin.and.ellipse", text: "走訪 \(visitedCornerCount) 個街角", tint: AppTheme.timberDeep)
                    }
                    if day.completedNeighborhoodLoop {
                        infoPill(systemImage: "rosette", text: "街區巡禮章", tint: AppTheme.pawStrollChain)
                    }
                    if day.deletionState == .placeErased {
                        infoPill(systemImage: "eraser", text: "已抹除地點", tint: AppTheme.clothBookmark)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var companionPortrait: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#F3ECE0"))
                .overlay(Circle().stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 1))
            if let id = companionPetID {
                ProceduralPetRigView(
                    pet: PetCatalog.pet(id: id),
                    outfitID: outfitIDForPet(id),
                    pose: .respond,
                    applyMetalPaperShader: false,
                    isStaticSnapshot: true
                )
                .padding(4)
                .clipShape(Circle())
            } else {
                Image(systemName: isQuietDay ? "sun.max.fill" : "pawprint.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.pawStrollChain)
            }
        }
        .frame(width: 66, height: 66)
        .accessibilityHidden(true)
    }

    private func infoPill(systemImage: String, text: String, tint: Color) -> some View {
        HStack(spacing: 3.5) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12), in: Capsule())
    }

    private func sectionLabel(_ title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10.5, weight: .semibold))
            Text(title)
                .font(AppTheme.diegeticLabel(12))
        }
        .foregroundStyle(tint)
    }

    // MARK: Locations & postcards

    private var locationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("走訪街角", systemImage: "map.fill", tint: AppTheme.forestTeal)

            if !visitedLabels.isEmpty {
                FlowChipRow {
                    ForEach(visitedLabels, id: \.self) { label in
                        Text(label)
                            .font(AppTheme.diegeticLabel(11.5))
                            .foregroundStyle(AppTheme.deepPineInk)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.parchmentTray, in: Capsule())
                            .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.3), lineWidth: 0.8))
                    }
                }
            }

            ForEach(encounters, id: \.encounterUUID) { enc in
                encounterBlock(enc)
            }
        }
    }

    @ViewBuilder
    private func encounterBlock(_ enc: EncounterLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let pngData = enc.bakedSnapshotPNGData,
               let uiImage = UIImage(data: pngData) {
                let shareImg = Image(uiImage: uiImage)
                let isPinned = (pinnedPostcardEncounterID == enc.encounterUUID)

                ZStack(alignment: .top) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: AppTheme.deepPineInk.opacity(0.16), radius: 5, y: 3)

                    WashiTapeStrip(color: Color(hex: "#E6CFA3"), angle: -2.0, width: 72)
                        .offset(y: -7)
                }
                .padding(.top, 6)

                HStack(spacing: 8) {
                    Button {
                        onTogglePinPostcard(enc.encounterUUID)
                    } label: {
                        HStack(spacing: 3.5) {
                            Image(systemName: isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 10.5, weight: .bold))
                            Text(isPinned ? "已掛牆上" : "掛進陽光室")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(isPinned ? .white : AppTheme.forestTeal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5.5)
                        .background(
                            (isPinned ? AppTheme.forestTeal : Color(hex: "#FFFDF7").opacity(0.94)),
                            in: Capsule()
                        )
                        .overlay(Capsule().stroke(isPinned ? Color.clear : AppTheme.timberWarm.opacity(0.55), lineWidth: 1))
                    }
                    .buttonStyle(TactileGameButtonStyle(pressScale: 0.93, pressOffsetY: 1))

                    ShareLink(
                        item: shareImg,
                        preview: SharePreview("\(PetCatalog.pet(id: enc.petID).name)的街角明信片", image: shareImg)
                    ) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11, weight: .bold))
                            Text("珍藏分享")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.deepPineInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5.5)
                        .background(Color(hex: "#FFFDF7").opacity(0.94), in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.55), lineWidth: 1))
                    }
                    Spacer(minLength: 0)
                }
            }

            HStack(alignment: .top) {
                Text(enc.narrativeLine)
                    .font(AppTheme.serifBody(14))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Menu {
                    if !enc.placeRedacted {
                        Button("重新命名街角") {
                            onRenameStop(enc.siteID, enc.siteDisplayLabel)
                        }
                    }
                    Button("移除這則相遇", role: .destructive) {
                        onRemoveEncounter(enc.encounterUUID)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(AppTheme.softInk)
                        .padding(6)
                }
                .accessibilityLabel("相遇選項")
            }
        }
    }

    // MARK: Discoveries

    private var discoveriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("今日新發現", systemImage: "sparkles", tint: AppTheme.pawStrollChain)

            ForEach(newPets, id: \.petID) { resident in
                let spec = PetCatalog.pet(id: resident.petID)
                HStack(spacing: 10) {
                    ProceduralPetRigView(
                        pet: spec,
                        outfitID: resident.activeOutfitID,
                        pose: .respond,
                        applyMetalPaperShader: false,
                        isStaticSnapshot: true
                    )
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(hex: "#F3ECE0")))
                    .clipShape(Circle())
                    Text("初次遇見 \(spec.name)（\(spec.kind.rawValue)）")
                        .font(AppTheme.serifBody(13.5))
                        .foregroundStyle(AppTheme.deepPineInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }

            if !curios.isEmpty {
                FlowChipRow {
                    ForEach(curios) { item in
                        let spec = CurioCatalog.curio(id: item.entry.curioID)
                        HStack(spacing: 5) {
                            PaintedCurioStampView(curioID: item.entry.curioID, size: 22)
                            Text(spec.name)
                                .font(AppTheme.diegeticLabel(11))
                                .foregroundStyle(AppTheme.deepPineInk)
                            if item.isFirstEver {
                                Text("✦ 首次拾獲")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.pawStrollChain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.parchmentTray, in: Capsule())
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.pawStrollChain.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// 自動換行的小標籤列
private struct FlowChipRow<Content: View>: View {
    var spacing: CGFloat = 6
    @ViewBuilder let content: () -> Content

    var body: some View {
        FlowWrapLayout(spacing: spacing) { content() }
    }
}

private struct FlowWrapLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, usedWidth: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? usedWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct MiniInkWashRouteCanvas: View {
    let points: [CoordinatePoint]

    /// 軌跡幾乎沒有位移時不畫（避免空盒子裡只剩一條死板的橫線）
    static func hasVisibleSpread(_ points: [CoordinatePoint]) -> Bool {
        let lats = points.map(\.latitude)
        let lons = points.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return false }
        return (maxLat - minLat) > 0.00003 || (maxLon - minLon) > 0.00003
    }

    var body: some View {
        Canvas { ctx, size in
            let lats = points.map(\.latitude)
            let lons = points.map(\.longitude)
            guard let minLat = lats.min(), let maxLat = lats.max(),
                  let minLon = lons.min(), let maxLon = lons.max() else { return }

            // 以等比例縮放並置中，路線形狀不被拉扁
            let midLat = (minLat + maxLat) / 2
            let lonScale = max(0.2, cos(midLat * .pi / 180))
            let latSpan = max(0.00005, maxLat - minLat)
            let lonSpan = max(0.00005, (maxLon - minLon) * lonScale)
            let pad: CGFloat = 16
            let availW = max(1, size.width - pad * 2)
            let availH = max(1, size.height - pad * 2)
            let scale = min(availW / CGFloat(lonSpan), availH / CGFloat(latSpan))
            let drawnW = CGFloat(lonSpan) * scale
            let drawnH = CGFloat(latSpan) * scale
            let originX = (size.width - drawnW) / 2
            let originY = (size.height - drawnH) / 2

            let mapped: [CGPoint] = points.map { pt in
                let x = originX + CGFloat((pt.longitude - minLon) * lonScale / lonSpan) * drawnW
                let y = originY + drawnH - CGFloat((pt.latitude - minLat) / latSpan) * drawnH
                return CGPoint(x: x, y: y)
            }

            // 以中點二次曲線平滑路線
            var path = Path()
            path.move(to: mapped[0])
            if mapped.count == 2 {
                path.addLine(to: mapped[1])
            } else {
                for i in 1..<mapped.count - 1 {
                    let mid = CGPoint(x: (mapped[i].x + mapped[i + 1].x) / 2, y: (mapped[i].y + mapped[i + 1].y) / 2)
                    if i == 1 {
                        path.addLine(to: CGPoint(x: (mapped[0].x + mapped[1].x) / 2, y: (mapped[0].y + mapped[1].y) / 2))
                    }
                    path.addQuadCurve(to: mid, control: mapped[i])
                }
                path.addLine(to: mapped[mapped.count - 1])
            }

            // 暈開的水彩底墨 + 乾筆墨線
            ctx.stroke(path, with: .color(AppTheme.forestTeal.opacity(0.14)),
                       style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round))
            ctx.stroke(path, with: .color(AppTheme.pawMetToday.opacity(0.22)),
                       style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            ctx.stroke(path, with: .color(AppTheme.pawMetToday.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

            drawPaw(ctx, at: mapped[0], color: AppTheme.forestTeal)
            drawPaw(ctx, at: mapped[mapped.count - 1], color: AppTheme.pawStrollChain)
        }
        .accessibilityLabel("今日散步路線")
    }

    private func drawPaw(_ ctx: GraphicsContext, at p: CGPoint, color: Color) {
        let halo = Path(ellipseIn: CGRect(x: p.x - 9, y: p.y - 9, width: 18, height: 18))
        ctx.fill(halo, with: .color(color.opacity(0.18)))
        let pad = Path(ellipseIn: CGRect(x: p.x - 3.6, y: p.y - 1.2, width: 7.2, height: 5.6))
        ctx.fill(pad, with: .color(color))
        for (dx, dy) in [(-4.6, -3.4), (-1.6, -5.6), (1.6, -5.6), (4.6, -3.4)] as [(CGFloat, CGFloat)] {
            let toe = Path(ellipseIn: CGRect(x: p.x + dx - 1.5, y: p.y + dy - 1.5, width: 3, height: 3))
            ctx.fill(toe, with: .color(color))
        }
    }
}

private struct BookmarkFilterPill: View {
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.diegeticLabel(12))
                .foregroundStyle(active ? .white : AppTheme.deepPineInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(active ? AppTheme.forestTeal : AppTheme.warmPaper, in: Capsule())
                .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct KawaiiCornerRenameSheet: View {
    @Binding var name: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.timberWarm, paddingAmount: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("替這個散步街角取個專屬於你的名字")
                            .font(AppTheme.serifBody(13.5))
                            .foregroundStyle(AppTheme.softInk)
                        TextField("例如：巷口老麵包店、午後大榕樹", text: $name)
                            .font(AppTheme.serifTitle(16))
                            .foregroundStyle(AppTheme.deepPineInk)
                            .padding(10)
                            .background(AppTheme.parchmentTray.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                HStack(spacing: 12) {
                    CutePlushButton(
                        title: "取消",
                        tone: .milkCream,
                        fontSize: 13,
                        horizontalPadding: 18,
                        verticalPadding: 9,
                        icon: { Image(systemName: "xmark").font(.system(size: 11, weight: .bold)) },
                        action: onCancel
                    )
                    CutePlushButton(
                        title: "儲存街角名稱",
                        tone: .matchaMint,
                        fontSize: 13,
                        horizontalPadding: 18,
                        verticalPadding: 9,
                        icon: { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)) },
                        action: onSave
                    )
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.parchmentTray)
            .navigationTitle("重新命名街角")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

