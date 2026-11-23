import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

/// 精裝手繪日記本（繁體中文：單日書頁、月曆跨頁、年度約定「改天再來一次」、單日地點抹除）
struct HardcoverSketchbookView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    enum DiaryTab: String, CaseIterable {
        case pages = "日記頁"
        case month = "月曆跨頁"
        case traditions = "年度約定"
    }

    @Bindable var coordinator: GameCoordinator
    @State private var activeTab: DiaryTab = .pages
    @State private var searchText: String = ""
    @State private var selectedPetFilter: String? = nil
    @State private var noteDrafts: [String: String] = [:]
    @State private var confirmEraseDateISO: String? = nil
    @State private var renameTargetSiteID: String? = nil
    @State private var renameText: String = ""
    @State private var backupExportURL: URL? = nil
    @State private var showBackupImporter: Bool = false
    @State private var showBackupPopover: Bool = false

    private var filteredDays: [DiaryDayRecord] {
        coordinator.diaryDays.filter { day in
            let dayEncounters = coordinator.encounters.filter { $0.localDateISO == day.localDateISO }
            if let petFilter = selectedPetFilter {
                let appeared = dayEncounters.contains(where: { $0.petID == petFilter || $0.secondaryPetID == petFilter }) || day.companionPetID == petFilter
                if !appeared { return false }
            }
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let q = searchText.lowercased()
                let matchesNote = day.personalNote.lowercased().contains(q)
                let matchesDate = day.localDateISO.lowercased().contains(q)
                let matchesEnc = dayEncounters.contains { enc in
                    PetCatalog.pet(id: enc.petID).name.lowercased().contains(q) ||
                    enc.siteDisplayLabel.lowercased().contains(q) ||
                    enc.narrativeLine.lowercased().contains(q)
                }
                return matchesNote || matchesDate || matchesEnc
            }
            return true
        }
    }

    private var starredDays: [DiaryDayRecord] {
        coordinator.diaryDays.filter(\.isStarredTradition)
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
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("足印手繪日記")
                            .font(AppTheme.serifTitle(22))
                            .foregroundStyle(AppTheme.deepPineInk)
                        Text("已記錄 \(coordinator.diaryDays.count) 頁時光 · 100% 留存本機")
                            .font(AppTheme.diegeticLabel(11))
                            .foregroundStyle(AppTheme.softInk)
                    }

                    Spacer()

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
                    case .traditions: return "star.fill"
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
                        referenceDate: coordinator.currentSimulatedDate,
                        onSelectDate: { iso in
                            searchText = iso
                            activeTab = .pages
                        }
                    )
                case .traditions:
                    AnnualTraditionsRibbonView(
                        starredDays: starredDays,
                        allEncounters: coordinator.encounters,
                        latestDay: coordinator.diaryDays.first,
                        pillarPets: coordinator.residents.filter { $0.milestoneTier >= 6 }
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
        }
    }

    private var pagesListSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.softInk)
                TextField("搜尋動物名字、街角或手寫短記…", text: $searchText)
                    .font(AppTheme.serifBody(14))
                    .foregroundStyle(AppTheme.deepPineInk)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.softInk)
                    }
                    .buttonStyle(.plain)
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
                    ForEach(PetCatalog.allPets) { pet in
                        BookmarkFilterPill(title: pet.name, active: selectedPetFilter == pet.id) {
                            selectedPetFilter = (selectedPetFilter == pet.id) ? nil : pet.id
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 4)

            ScrollView {
                LazyVStack(spacing: 18) {
                    ForEach(filteredDays, id: \.localDateISO) { day in
                        SketchbookDayPageCard(
                            day: day,
                            encounters: coordinator.encounters.filter { $0.localDateISO == day.localDateISO },
                            curios: coordinator.ledger.foragedCurios.filter { $0.localDateISO == day.localDateISO },
                            noteText: Binding(
                                get: { noteDrafts[day.localDateISO] ?? day.personalNote },
                                set: { newValue in
                                    noteDrafts[day.localDateISO] = newValue
                                    coordinator.savePersonalNote(for: day.localDateISO, note: newValue)
                                }
                            ),
                            onToggleTradition: { coordinator.toggleStarredTradition(for: day.localDateISO) },
                            onRequestErasePlace: { confirmEraseDateISO = day.localDateISO },
                            onRenameStop: { siteID, currentLabel in
                                renameTargetSiteID = siteID
                                renameText = currentLabel
                            },
                            onRemoveEncounter: { uuid in
                                coordinator.removeEncounter(uuid: uuid)
                            },
                            onSavePhoto: { jpegData in
                                coordinator.saveWalkPhoto(for: day.localDateISO, jpegData: jpegData)
                            },
                            pinnedPostcardEncounterID: coordinator.indoorState.pinnedPostcardEncounterID,
                            onTogglePinPostcard: { encounterID in
                                let isCurrentlyPinned = (coordinator.indoorState.pinnedPostcardEncounterID == encounterID)
                                coordinator.pinPostcardToSunroomWall(encounterID: isCurrentlyPinned ? nil : encounterID)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
}

private struct MonthSpreadGridView: View {
    let days: [DiaryDayRecord]
    let encounters: [EncounterLog]
    let curios: [ForagedCurioEntry]
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
        referenceDate: Date,
        onSelectDate: @escaping (String) -> Void
    ) {
        self.days = days
        self.encounters = encounters
        self.curios = curios
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

                    Text("\(displayedYear)年\(displayedMonth)月")
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
                                            if record.isStarredTradition {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundStyle(AppTheme.pawStrollChain)
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
                                            .stroke(record.isStarredTradition ? AppTheme.pawStrollChain : AppTheme.timberWarm.opacity(0.45), lineWidth: record.isStarredTradition ? 1.4 : 1.0)
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
                        Text("本月共散步 \(map.count) 天 · \(monthStepsTotal.formatted()) 步 · 收藏 \(monthCuriosCount) 件拾遺")
                            .font(AppTheme.handwritten(14))
                            .foregroundStyle(AppTheme.forestTeal)

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
            .padding(.bottom, 100)
        }
        .onAppear { regenerateMonthlyPDF() }
        .onChange(of: displayedYear) { _, _ in regenerateMonthlyPDF() }
        .onChange(of: displayedMonth) { _, _ in regenerateMonthlyPDF() }
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

private struct AnnualTraditionsRibbonView: View {
    let starredDays: [DiaryDayRecord]
    let allEncounters: [EncounterLog]
    let latestDay: DiaryDayRecord?
    let pillarPets: [PetResidentState]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 里程碑 6（第 25 天 · 街角柱石）週年紀念跨頁（回連至第一天相遇日期）
                if !pillarPets.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("街角柱石 · 相伴紀念跨頁")
                            .font(AppTheme.serifTitle(19))
                            .foregroundStyle(AppTheme.forestTeal)
                        ForEach(pillarPets, id: \.petID) { pet in
                            let spec = PetCatalog.pet(id: pet.petID)
                            HStack(spacing: 12) {
                                ProceduralPetRigView(
                                    pet: spec,
                                    outfitID: pet.activeOutfitID,
                                    pose: .respond,
                                    applyMetalPaperShader: false,
                                    isStaticSnapshot: true
                                )
                                .frame(width: 72, height: 72)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(spec.name) · 相伴 \(pet.sharedDaysCount) 天")
                                        .font(AppTheme.serifTitle(16))
                                        .foregroundStyle(AppTheme.deepPineInk)
                                    if let firstISO = pet.firstMetDateISO {
                                        Text("初遇於 \(CivilCalendarHelper.displayDate(from: firstISO))")
                                            .font(AppTheme.diegeticLabel(11))
                                            .foregroundStyle(AppTheme.forestTeal)
                                    }
                                    Text(spec.matureKindness)
                                        .font(AppTheme.handwritten(13))
                                        .foregroundStyle(AppTheme.softInk)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.pawStrollChain.opacity(0.55), lineWidth: 1.5))
                        }
                    }
                }

                Text("「改天再來一次」年度約定")
                    .font(AppTheme.serifTitle(20))
                    .foregroundStyle(AppTheme.deepPineInk)
                Text("在任一頁點亮星號，就能把那天的舊插畫與日後壯大的家園並排回味。")
                    .font(AppTheme.handwritten(14))
                    .foregroundStyle(AppTheme.softInk)

                if starredDays.isEmpty {
                    Text("目前還沒有標記年度約定。輕點任一頁右上角的星星，珍藏屬於你們的小日子。")
                        .font(AppTheme.serifBody(14))
                        .foregroundStyle(AppTheme.softInk)
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    ForEach(starredDays, id: \.localDateISO) { day in
                        let originalEnc = allEncounters.first(where: { $0.localDateISO == day.localDateISO })
                        let latestEnc = latestDay.flatMap { latest in
                            allEncounters.first(where: { $0.localDateISO == latest.localDateISO && $0.localDateISO != day.localDateISO })
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "star.fill").foregroundStyle(AppTheme.pawStrollChain)
                                Text(CivilCalendarHelper.displayDate(from: day.localDateISO))
                                    .font(AppTheme.serifTitle(16))
                                    .foregroundStyle(AppTheme.deepPineInk)
                            }
                            HStack(spacing: 10) {
                                traditionPhotoCard(title: "當時的那一天", enc: originalEnc)
                                traditionPhotoCard(title: "後來的新篇章", enc: latestEnc)
                            }
                            if !day.personalNote.isEmpty {
                                Text("「\(day.personalNote)」")
                                    .font(AppTheme.handwritten(14))
                                    .foregroundStyle(AppTheme.deepPineInk)
                            }
                        }
                        .padding(14)
                        .background(AppTheme.warmPaper, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func traditionPhotoCard(title: String, enc: EncounterLog?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.diegeticLabel(11))
                .foregroundStyle(AppTheme.forestTeal)
            if let data = enc?.bakedSnapshotPNGData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.parchmentTray)
                    .frame(height: 92)
                    .overlay(
                        Text("靜待下個季節\n再並肩續寫")
                            .font(AppTheme.handwritten(11))
                            .foregroundStyle(AppTheme.softInk)
                            .multilineTextAlignment(.center)
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SketchbookDayPageCard: View {
    let day: DiaryDayRecord
    let encounters: [EncounterLog]
    let curios: [ForagedCurioEntry]
    @Binding var noteText: String
    let onToggleTradition: () -> Void
    let onRequestErasePlace: () -> Void
    let onRenameStop: (String, String) -> Void
    let onRemoveEncounter: (UUID) -> Void
    let onSavePhoto: (Data?) -> Void
    let pinnedPostcardEncounterID: UUID?
    let onTogglePinPostcard: (UUID) -> Void

    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(CivilCalendarHelper.displayDate(from: day.localDateISO))
                        .font(AppTheme.serifTitle(18))
                        .foregroundStyle(AppTheme.deepPineInk)
                    HStack(spacing: 6) {
                        Text(day.weatherMode.displayName)
                        if day.acceptedSteps > 0 {
                            Text("· \(day.acceptedSteps.formatted()) 步")
                        }
                        if day.completedNeighborhoodLoop {
                            Text("· 街區巡禮章")
                                .foregroundStyle(AppTheme.forestTeal)
                        }
                        if day.deletionState == .placeErased {
                            Text("· 已抹除地點")
                                .foregroundStyle(AppTheme.clothBookmark)
                        }
                    }
                    .font(AppTheme.diegeticLabel(12))
                    .foregroundStyle(AppTheme.softInk)
                }

                Spacer()

                Button(action: onToggleTradition) {
                    Image(systemName: day.isStarredTradition ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundStyle(day.isStarredTradition ? AppTheme.pawStrollChain : AppTheme.softInk)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            if encounters.isEmpty {
                Text("安靜留白的一頁——還沒有街角相遇的明信片。")
                    .font(AppTheme.handwritten(14))
                    .foregroundStyle(AppTheme.softInk)
                    .padding(.vertical, 6)
            } else {
                ForEach(encounters, id: \.encounterUUID) { enc in
                    VStack(alignment: .leading, spacing: 8) {
                        if let pngData = enc.bakedSnapshotPNGData,
                           let uiImage = UIImage(data: pngData) {
                            let shareImg = Image(uiImage: uiImage)
                            ZStack(alignment: .top) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .shadow(color: AppTheme.deepPineInk.opacity(0.16), radius: 5, y: 3)
                                    .overlay(alignment: .bottomTrailing) {
                                        let isPinned = (pinnedPostcardEncounterID == enc.encounterUUID)
                                        HStack(spacing: 6) {
                                            Button {
                                                onTogglePinPostcard(enc.encounterUUID)
                                            } label: {
                                                HStack(spacing: 3.5) {
                                                    Image(systemName: isPinned ? "pin.fill" : "pin")
                                                        .font(.system(size: 10.5, weight: .bold))
                                                    Text(isPinned ? "已掛牆上" : "掛進陽光室")
                                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                                }
                                                .foregroundStyle(isPinned ? .white : AppTheme.forestTeal)
                                                .padding(.horizontal, 9)
                                                .padding(.vertical, 5)
                                                .background(
                                                    (isPinned ? AppTheme.forestTeal : Color(hex: "#FFFDF7").opacity(0.94)),
                                                    in: Capsule()
                                                )
                                                .overlay(Capsule().stroke(isPinned ? Color.clear : AppTheme.timberWarm.opacity(0.55), lineWidth: 1))
                                                .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 3, y: 1.5)
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
                                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                                }
                                                .foregroundStyle(AppTheme.deepPineInk)
                                                .padding(.horizontal, 9)
                                                .padding(.vertical, 5)
                                                .background(Color(hex: "#FFFDF7").opacity(0.94), in: Capsule())
                                                .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.55), lineWidth: 1))
                                                .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 3, y: 1.5)
                                            }
                                        }
                                        .padding(8)
                                    }

                                WashiTapeStrip(color: Color(hex: "#E6CFA3"), angle: -2.0, width: 72)
                                    .offset(y: -7)
                            }
                            .padding(.top, 6)
                        }

                        HStack(alignment: .top) {
                            Text(enc.narrativeLine)
                                .font(AppTheme.serifBody(14))
                                .foregroundStyle(AppTheme.deepPineInk)
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
                        }
                    }
                }
            }

            let trailPoints = LocationService.decodeTrailGeoJSON(day.routeTrackGeoJSON)
            if trailPoints.count >= 2 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("散步墨彩縮圖")
                        .font(AppTheme.diegeticLabel(11))
                        .foregroundStyle(AppTheme.softInk)
                    MiniInkWashRouteCanvas(points: trailPoints)
                        .frame(height: 54)
                        .background(AppTheme.parchmentTray.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                }
            }

            if !day.revisitNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("順路探望小札")
                        .font(AppTheme.diegeticLabel(11))
                        .foregroundStyle(AppTheme.timberDeep)
                    ForEach(day.revisitNotes, id: \.self) { note in
                        Text("• \(note)")
                            .font(AppTheme.serifBody(13))
                            .foregroundStyle(AppTheme.softInk)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.parchmentTray.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
            }

            if !curios.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(curios) { entry in
                            let spec = CurioCatalog.curio(id: entry.curioID)
                            HStack(spacing: 5) {
                                PaintedCurioStampView(curioID: entry.curioID, size: 22)
                                Text(spec.name)
                                    .font(AppTheme.diegeticLabel(11))
                                    .foregroundStyle(AppTheme.deepPineInk)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.parchmentTray, in: Capsule())
                        }
                    }
                }
            }

            // Optional Real-World Walk Polaroid Photo Mount (100% private on-device)
            if let jpegData = day.photoJPEGData, let photo = UIImage(data: jpegData) {
                VStack(alignment: .leading, spacing: 6) {
                    ZStack(alignment: .top) {
                        VStack(spacing: 6) {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 158)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            HStack {
                                Text("散步拍立得 · \(CivilCalendarHelper.displayDate(from: day.localDateISO))")
                                    .font(AppTheme.handwritten(12))
                                    .foregroundStyle(AppTheme.softInk)
                                Spacer()
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    Text("更換")
                                        .font(AppTheme.diegeticLabel(11))
                                        .foregroundStyle(AppTheme.forestTeal)
                                }
                                Button("取下") {
                                    onSavePhoto(nil)
                                }
                                .font(AppTheme.diegeticLabel(11))
                                .foregroundStyle(AppTheme.clothBookmark)
                            }
                        }
                        .padding(8)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.timberWarm.opacity(0.35), lineWidth: 1))
                        .shadow(color: AppTheme.deepPineInk.opacity(0.14), radius: 5, y: 3)

                        WashiTapeStrip(color: Color(hex: "#C5D7C6"), angle: 1.8, width: 64)
                            .offset(y: -7)
                    }
                    .padding(.top, 6)
                }
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 12, weight: .semibold))
                        Text("貼上一張今天的散步拍立得（僅留存本機）")
                            .font(AppTheme.diegeticLabel(11.5))
                    }
                    .foregroundStyle(AppTheme.forestTeal)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(AppTheme.parchmentTray.opacity(0.72), in: Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("鋼筆手記")
                    .font(AppTheme.diegeticLabel(11))
                    .foregroundStyle(AppTheme.forestTeal)
                TextField("用鋼筆寫下一句今日心情…", text: $noteText, axis: .vertical)
                    .font(AppTheme.handwritten(15))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(AppTheme.parchmentTray.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let rawData = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: rawData) {
                    let maxDim: CGFloat = 1080
                    let scale = min(1.0, maxDim / max(uiImage.size.width, uiImage.size.height))
                    let targetSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
                    let renderer = UIGraphicsImageRenderer(size: targetSize)
                    let resized = renderer.image { _ in uiImage.draw(in: CGRect(origin: .zero, size: targetSize)) }
                    let compressed = resized.jpegData(compressionQuality: 0.72)
                    await MainActor.run {
                        onSavePhoto(compressed)
                        selectedPhotoItem = nil
                    }
                }
            }
        }
    }
}

private struct MiniInkWashRouteCanvas: View {
    let points: [CoordinatePoint]

    var body: some View {
        Canvas { ctx, size in
            let lats = points.map(\.latitude)
            let lons = points.map(\.longitude)
            guard let minLat = lats.min(), let maxLat = lats.max(),
                  let minLon = lons.min(), let maxLon = lons.max() else { return }

            let latSpan = max(0.0002, maxLat - minLat)
            let lonSpan = max(0.0002, maxLon - minLon)
            let pad: CGFloat = 12

            var path = Path()
            for (idx, pt) in points.enumerated() {
                let x = pad + CGFloat((pt.longitude - minLon) / lonSpan) * (size.width - pad * 2)
                let y = size.height - pad - CGFloat((pt.latitude - minLat) / latSpan) * (size.height - pad * 2)
                if idx == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(
                path,
                with: .color(AppTheme.pawMetToday.opacity(0.8)),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [2, 6])
            )
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
