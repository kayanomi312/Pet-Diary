import SwiftUI
import MapKit

struct StreetOverworldView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @Bindable var coordinator: GameCoordinator
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedFarAnchor: AnchorSiteRecord? = nil
    @State private var hasCenteredOnRealGPS: Bool = false
    @State private var showStartStrollSheet: Bool = false
    @State private var showStreetToolsPopover: Bool = false
    @State private var dismissedGoalIcon: String? = nil
    @State private var visibleMapRect: MKMapRect? = nil

    private var isLocationDenied: Bool {
        let status = coordinator.locationService.authorizationStatus
        return status == .denied || status == .restricted
    }

    init(coordinator: GameCoordinator) {
        self.coordinator = coordinator
        let origin = coordinator.locationService.currentLocation.coordinate
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: origin,
                    latitudinalMeters: 360,
                    longitudinalMeters: 360
                )
            )
        )
    }

    var body: some View {
        let anchors = coordinator.visibleAnchors
        let visiblePinCount = anchors.count { anchor in
            visibleMapRect?.contains(MKMapPoint(CLLocationCoordinate2D(latitude: anchor.lat, longitude: anchor.lon))) ?? true
        }

        ZStack {
            Map(position: $cameraPosition) {
                if coordinator.locationService.liveTrail.count >= 2 {
                    let coords = coordinator.locationService.liveTrail.map(\.clCoordinate)
                    MapPolyline(coordinates: coords)
                        .stroke(
                            AppTheme.pawMetToday.opacity(0.72),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [2, 10])
                        )
                    MapPolyline(coordinates: coords)
                        .stroke(
                            AppTheme.forestTeal.opacity(0.32),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                }

                MapCircle(
                    center: coordinator.locationService.currentLocation.coordinate,
                    radius: AnchorRotationEngine.maxActivationRadiusM
                )
                .foregroundStyle(AppTheme.pawInRange.opacity(0.08))
                .stroke(AppTheme.pawInRange.opacity(0.42), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))

                Annotation("", coordinate: coordinator.locationService.currentLocation.coordinate) {
                    PlayerLanternMapPinView(
                        walkingCompanion: coordinator.activeStroll?.companionPetID.map(PetCatalog.pet(id:)),
                        headingDegrees: coordinator.locationService.headingDegrees
                    )
                    .accessibilityLabel("你目前的散步位置")
                }

                ForEach(anchors, id: \.siteID) { anchor in
                    let state = coordinator.pawState(for: anchor)
                    let distance = coordinator.distanceMeters(to: anchor)
                    let compact = state == .distant && distance > 120 && visiblePinCount >= 4
                    let showRegularPortrait = (anchor.totalVisitsCount > 0 || anchor.isFamiliarCorner)
                    Annotation(
                        "",
                        coordinate: CLLocationCoordinate2D(latitude: anchor.lat, longitude: anchor.lon)
                    ) {
                        PawAnchorStampView(
                            label: anchor.customLabel,
                            state: state,
                            distanceM: Int(distance),
                            isFamiliarCorner: anchor.isFamiliarCorner,
                            familiarityStars: min(3, anchor.totalVisitsCount / 3),
                            regularPetID: showRegularPortrait ? anchor.regularPetID : nil,
                            isCompact: compact
                        ) {
                            let check = coordinator.attemptOpenAnchor(anchor)
                            if case .tooFar = check {
                                selectedFarAnchor = anchor
                            }
                        }
                        .zIndex((state == .inRange || state == .strollChain) ? 2 : 1)
                    }
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleMapRect = context.rect
            }
            .mapStyle(
                .standard(
                    elevation: .flat,
                    emphasis: .muted,
                    pointsOfInterest: .excludingAll,
                    showsTraffic: false
                )
            )
            .ignoresSafeArea()

            DeckledPaperVignetteOverlay()

            VStack(spacing: 8) {
                // MARK: Single Clean Top Bar (Zero multi-row button soup!)
                let todayCount = Set(coordinator.encounters.filter { $0.localDateISO == coordinator.currentLocalDateISO }.map(\.siteID)).count
                HStack(spacing: 8) {
                    CozyGlassPill(horizontalPadding: 11, verticalPadding: 6) {
                        HStack(spacing: 6) {
                            CuteWeatherFaceIcon(weather: coordinator.activeWeather, size: 20)
                            Text(CivilCalendarHelper.displayDate(from: coordinator.currentLocalDateISO))
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#2F2A26"))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            Text("·")
                                .foregroundStyle(Color(hex: "#B5A590"))
                            HStack(spacing: 3) {
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(todayCount >= 3 ? AppTheme.forestTeal : Color(hex: "#DF7A62"))
                                Text("\(todayCount)/3")
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(todayCount >= 3 ? AppTheme.forestTeal : Color(hex: "#5A4D43"))
                            }
                        }
                    }

                    Spacer(minLength: 4)

                    if isLocationDenied || coordinator.locationService.isReducedAccuracy {
                        locationWarning
                    }

                    // Compact coin balance pill
                    Button {
                        CozySoundEngine.shared.playPaperFlip()
                        coordinator.currentScreen = .curioCubbies
                    } label: {
                        CozyGlassPill(horizontalPadding: 9, verticalPadding: 6) {
                            HStack(spacing: 4) {
                                PaintedPouchIconView(size: 16)
                                Text("\(coordinator.ledger.coinBalance)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "#4A3114"))
                            }
                        }
                    }
                    .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                topNotice
                    .padding(.horizontal, 16)

                Spacer()

                // 常散步玩家的「街角順路探望」溫馨小札（當日已互動過的街角再次經過時）
                if let revisit = coordinator.activeQuietRevisit {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            HStack(spacing: -18) {
                                ProceduralPetRigView(
                                    pet: PetCatalog.pet(id: revisit.petID),
                                    outfitID: coordinator.resident(for: revisit.petID)?.activeOutfitID,
                                    pose: .resting,
                                    weatherMode: coordinator.activeWeather,
                                    applyMetalPaperShader: false,
                                    isStaticSnapshot: true
                                )
                                .frame(width: 68, height: 68)

                                if let secID = revisit.secondaryPetID {
                                    ProceduralPetRigView(
                                        pet: PetCatalog.pet(id: secID),
                                        outfitID: coordinator.resident(for: secID)?.activeOutfitID,
                                        pose: .notice,
                                        weatherMode: coordinator.activeWeather,
                                        applyMetalPaperShader: false,
                                        isStaticSnapshot: true
                                    )
                                    .frame(width: 64, height: 64)
                                }
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(revisit.timeBandLabel)
                                        .font(AppTheme.diegeticLabel(11))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.forestTeal, in: Capsule())
                                    Text(revisit.familiarityLabel)
                                        .font(AppTheme.diegeticLabel(11))
                                        .foregroundStyle(AppTheme.timberDeep)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.parchmentTray, in: Capsule())
                                }
                                Text(revisit.vignetteLine)
                                    .font(AppTheme.serifBody(14))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        HStack {
                            Spacer()
                            Button("揮揮手繼續走") {
                                withAnimation { coordinator.activeQuietRevisit = nil }
                            }
                            .font(AppTheme.diegeticLabel(12))
                            .foregroundStyle(AppTheme.forestTeal)
                        }
                    }
                    .padding(14)
                    .background(AppTheme.warmPaper.opacity(0.97), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.timberWarm.opacity(0.5), lineWidth: 1.2))
                    .shadow(color: AppTheme.deepPineInk.opacity(0.20), radius: 10, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }

                if let far = selectedFarAnchor {
                    let meters = Int(coordinator.distanceMeters(to: far))
                    let walkMin = max(1, Int(ceil(Double(meters) / 75.0)))
                    StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.timberWarm, paddingAmount: 13) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(far.customLabel)
                                    .font(AppTheme.serifTitle(15))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text("距離 \(meters) 公尺（約步行 \(walkMin) 分鐘）— 走近 75 公尺內即可向奇幻靈獸打招呼。")
                                    .font(AppTheme.serifBody(12.5))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) { selectedFarAnchor = nil }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.softInk)
                                    .frame(width: 28, height: 28)
                                    .background(Color(hex: "#EFE7D8"), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("關閉距離提示")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                // Mathematically centered Primary Action Row sitting gracefully above the Unified Bottom Dock!
                ZStack {
                    // Center: ONE clear primary Hero CTA, locked to exact horizontal center!
                    if coordinator.activeStroll == nil {
                        CozyHeroActionButton(
                            title: "出發散步",
                            systemImage: "figure.walk",
                            style: .amber
                        ) {
                            CozySoundEngine.shared.playPaperFlip()
                            showStartStrollSheet = true
                        }
                    } else {
                        CozyHeroActionButton(
                            title: "回到家了",
                            systemImage: "flag.checkered",
                            style: .terracotta
                        ) {
                            _ = coordinator.endStrollSession()
                        }
                    }

                    HStack(alignment: .center) {
                        // Left: Compact Walk Buddy Medallion
                        let activePet = coordinator.activeWalkCompanionID.map(PetCatalog.pet(id:))
                        Button {
                            HapticsEngine.shared.playBrushStrokeTick()
                            if let id = coordinator.activeWalkCompanionID {
                                coordinator.currentScreen = .tactileCare(petID: id)
                            } else {
                                showStartStrollSheet = true
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(Circle().fill(Color(hex: "#FFFDF8").opacity(0.92)))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(AppTheme.timberWarm.opacity(0.20), lineWidth: 2.2)
                                    )
                                    .overlay(
                                        Circle()
                                            .trim(from: 0, to: min(1.0, Double(coordinator.ledger.pocketFindStepProgress) / Double(StepCoinLedgerEngine.stepsPerPocketFind)))
                                            .stroke(coordinator.isNearPocketFind ? AppTheme.pawStrollChain : AppTheme.forestTeal, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                            .rotationEffect(.degrees(-90))
                                    )
                                    .shadow(color: Color(hex: "#2D241E").opacity(0.13), radius: 8, y: 3)

                                if let pet = activePet, let img = UIImage(named: pet.id.replacingOccurrences(of: ".", with: "_")) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 34, height: 34)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(AppTheme.forestTeal)
                                }
                            }
                        }
                        .buttonStyle(TactileGameButtonStyle(pressScale: 0.92, pressOffsetY: 1.5))
                        .accessibilityLabel(activePet.map { "散步夥伴：\($0.name)" } ?? "選擇散步夥伴")

                        Spacer()

                        // Right: Sleek GPS recenter + tidy Corner Tools menu
                        HStack(spacing: 8) {
                            CozyIconCircleButton(
                                systemImage: "location.fill",
                                tint: AppTheme.forestTeal,
                                size: 40,
                                accessibilityLabelText: "回到目前位置"
                            ) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    cameraPosition = .region(
                                        MKCoordinateRegion(
                                            center: coordinator.locationService.currentLocation.coordinate,
                                            latitudinalMeters: 340,
                                            longitudinalMeters: 340
                                        )
                                    )
                                }
                            }

                            CozyIconCircleButton(
                                systemImage: "ellipsis",
                                tint: Color(hex: "#3A312B"),
                                isActive: showStreetToolsPopover,
                                size: 40,
                                accessibilityLabelText: "街區更多工具"
                            ) {
                                CozySoundEngine.shared.playPaperFlip()
                                withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
                                    showStreetToolsPopover.toggle()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 86)
            }

            // Unified Warm Stationery Tools Popover (replaces stark iOS system Menu!)
            if showStreetToolsPopover {
                Color.black.opacity(0.06)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.18)) { showStreetToolsPopover = false }
                    }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CozyPopoverMenuCard(
                            items: [
                                CozyPopoverMenuItem(
                                    id: "pin_corner",
                                    title: "標記這個巷口",
                                    systemImage: "mappin.and.ellipse",
                                    tint: AppTheme.forestTeal
                                ) {
                                    CozySoundEngine.shared.playPaperFlip()
                                    if let pinned = coordinator.pinFamiliarCornerAhead() {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            cameraPosition = .region(
                                                MKCoordinateRegion(
                                                    center: CLLocationCoordinate2D(latitude: pinned.lat, longitude: pinned.lon),
                                                    latitudinalMeters: 320,
                                                    longitudinalMeters: 320
                                                )
                                            )
                                        }
                                    }
                                },
                                CozyPopoverMenuItem(
                                    id: "nearby_list",
                                    title: "附近街角一覽",
                                    systemImage: "list.bullet",
                                    tint: Color(hex: "#C98D26")
                                ) {
                                    coordinator.showAccessibleNearbyList = true
                                }
                            ],
                            onDismiss: {
                                withAnimation(.easeOut(duration: 0.18)) { showStreetToolsPopover = false }
                            }
                        )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 140)
                }
                .transition(reduceMotion ? .opacity : .scale(scale: 0.92, anchor: .bottomTrailing).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $coordinator.showAccessibleNearbyList) {
            AccessibleNearbyListSheet(coordinator: coordinator)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showStartStrollSheet) {
            StartStrollSatchelSheet(coordinator: coordinator)
                .presentationDetents([.large])
        }
        .sheet(item: $coordinator.completedStrollSummary) { summary in
            StrollSummaryPostcardSheet(
                summary: summary,
                weather: coordinator.activeWeather,
                onDismiss: { coordinator.completedStrollSummary = nil }
            )
            .presentationDetents([.large])
        }
        .onChange(of: coordinator.pendingOpenStartStrollSheet) { _, shouldOpen in
            if shouldOpen {
                coordinator.pendingOpenStartStrollSheet = false
                if coordinator.activeStroll == nil {
                    showStartStrollSheet = true
                }
            }
        }
        .onAppear {
            if coordinator.pendingOpenStartStrollSheet {
                coordinator.pendingOpenStartStrollSheet = false
                if coordinator.activeStroll == nil {
                    showStartStrollSheet = true
                }
            }
        }
        .onChange(of: coordinator.locationService.currentLocation) { _, newLoc in
            if !coordinator.locationService.useSimulatedPosition && !hasCenteredOnRealGPS {
                hasCenteredOnRealGPS = true
                withAnimation(.easeInOut(duration: 0.7)) {
                    cameraPosition = .region(
                        MKCoordinateRegion(center: newLoc.coordinate, latitudinalMeters: 360, longitudinalMeters: 360)
                    )
                }
            }
        }
    }

    private var locationWarning: some View {
        Button {
            HapticsEngine.shared.playBrushStrokeTick()
            if isLocationDenied, let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                openURL(settingsURL)
            } else {
                coordinator.locationService.requestFreshAccurateFix()
            }
        } label: {
            CozyGlassPill(horizontalPadding: 9, verticalPadding: 6) {
                Label(isLocationDenied ? "定位未開" : "定位範圍較廣", systemImage: "location.slash")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#965032"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1))
        .accessibilityHint(isLocationDenied ? "前往設定開啟定位" : "要求精準定位")
    }

    @ViewBuilder
    private var topNotice: some View {
        if coordinator.showOnboardingPaperSlip {
            CozyWelcomeOnboardingCard(
                onAllowLocation: {
                    coordinator.locationService.requestForegroundLocation()
                    coordinator.showOnboardingPaperSlip = false
                },
                onDismissLater: { coordinator.showOnboardingPaperSlip = false }
            )
        } else if let unpacked = coordinator.newlyUnpackedCurio {
            let spec = CurioCatalog.curio(id: unpacked.curioID)
            noticeRow {
                PaintedCurioStampView(curioID: unpacked.curioID, size: 29)
                VStack(alignment: .leading, spacing: 1) {
                    Text("口袋拾遺 · \(spec.name)")
                        .font(AppTheme.diegeticLabel(12))
                    Text(spec.journalNote)
                        .font(AppTheme.handwritten(11))
                        .foregroundStyle(AppTheme.softInk)
                }
                .lineLimit(1)
                Spacer(minLength: 0)
                noticeButton("收進木格") { coordinator.newlyUnpackedCurio = nil }
            }
        } else if let whisper = coordinator.transientWhisper {
            notice(icon: "sparkle", text: whisper)
        } else if let chainTargetID = coordinator.activeStrollChainTargetID,
                  let target = coordinator.anchors.first(where: { $0.siteID == chainTargetID }),
                  let guideID = coordinator.ledger.activeStrollChainGuidePetID {
            noticeRow {
                noticeLabel(icon: "sparkles", text: "\(PetCatalog.pet(id: guideID).name)望向「\(target.customLabel)」")
                Spacer(minLength: 0)
                noticeButton("看位置") {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: target.lat, longitude: target.lon),
                            latitudinalMeters: 340, longitudinalMeters: 340
                        ))
                    }
                }
            }
        } else if let stroll = coordinator.activeStroll {
            let companion = stroll.companionPetID.map(coordinator.displayName(for:)) ?? "自由漫步"
            let pack = stroll.packedCharm == .none ? "" : " · \(stroll.packedCharm.title)"
            notice(icon: "figure.walk", text: "\(companion) · \(stroll.sessionSteps.formatted()) 步\(pack)")
        } else if coordinator.activeQuietRevisit == nil,
                  let hint = coordinator.nextGoalHint, dismissedGoalIcon != hint.icon {
            noticeRow {
                noticeLabel(
                    icon: hint.icon,
                    text: coordinator.isStreetLocationUnavailable ? "到陽光室窗邊也能結識新朋友。" : hint.text
                )
                Spacer(minLength: 0)
                if coordinator.isStreetLocationUnavailable {
                    noticeButton("去陽光室") {
                        CozySoundEngine.shared.playPaperFlip()
                        coordinator.solveHomeRoomNow()
                        coordinator.currentScreen = .home
                    }
                }
                Button {
                    dismissedGoalIcon = hint.icon
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("隱藏這個提示")
            }
        }
    }

    private func notice(icon: String, text: String) -> some View {
        noticeRow { noticeLabel(icon: icon, text: text) }
    }

    private func noticeLabel(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(AppTheme.handwritten(13))
            .lineLimit(2)
    }

    private func noticeButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.diegeticLabel(11))
                .foregroundStyle(AppTheme.forestTeal)
                .fixedSize()
                .padding(.horizontal, 9)
                .frame(minHeight: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func noticeRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 6, content: content)
            .foregroundStyle(AppTheme.deepPineInk)
            .padding(.horizontal, 11)
            .padding(.vertical, 4)
            .frame(minHeight: 34)
            .background(AppTheme.warmPaper.opacity(0.95), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.timberWarm.opacity(0.4), lineWidth: 0.9))
    }
}

private struct PlayerLanternMapPinView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var walkingCompanion: PetSpec? = nil
    var headingDegrees: Double? = nil
    @State private var pulse = false

    var body: some View {
        ZStack {
            // 即時羅盤朝向柔和光扇（當真實羅盤可用時指向你面朝的方向）
            if let headingDegrees {
                Path { p in
                    p.move(to: CGPoint(x: 34, y: 34))
                    p.addArc(center: CGPoint(x: 34, y: 34), radius: 32, startAngle: .degrees(-115), endAngle: .degrees(-65), clockwise: false)
                    p.closeSubpath()
                }
                .fill(
                    RadialGradient(
                        colors: [AppTheme.forestTeal.opacity(0.42), .clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: 34
                    )
                )
                .frame(width: 68, height: 68)
                .rotationEffect(.degrees(headingDegrees))
            }

            Circle()
                .fill(Color(hex: "#5DA689").opacity(pulse ? 0.08 : 0.28))
                .frame(width: pulse ? 44 : 24, height: pulse ? 44 : 24)

            Circle()
                .fill(Color(hex: "#FFFDF7"))
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(AppTheme.brassDark.opacity(0.75), lineWidth: 1.5))
                .shadow(color: AppTheme.deepPineInk.opacity(0.32), radius: 4, y: 2)

            Circle()
                .fill(Color(hex: "#4A8F74"))
                .frame(width: 13, height: 13)

            Circle()
                .fill(Color.white.opacity(0.75))
                .frame(width: 4, height: 4)
                .offset(x: -2.5, y: -2.5)

            // 出發散步時，同行奇幻夥伴活靈活現地在你的提燈旁小步漫步！
            if let comp = walkingCompanion {
                ProceduralPetRigView(
                    pet: comp,
                    pose: .notice,
                    applyMetalPaperShader: false,
                    isStaticSnapshot: false,
                    playfulAction: .walking
                )
                .frame(width: 42, height: 42)
                .scaleEffect(x: (headingDegrees ?? 0) > 180 ? 1.0 : -1.0, y: 1.0)
                .background(
                    Circle()
                        .fill(AppTheme.warmPaper)
                        .overlay(Circle().stroke(AppTheme.pawStrollChain, lineWidth: 1.5))
                        .shadow(color: AppTheme.deepPineInk.opacity(0.24), radius: 3, y: 2)
                )
                .offset(x: 24, y: -14)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct PawAnchorStampView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let label: String
    let state: PawState
    let distanceM: Int
    let isFamiliarCorner: Bool
    var familiarityStars: Int = 0
    var regularPetID: String? = nil
    var isCompact = false
    let onTap: () -> Void

    @State private var ripple = false
    @State private var bob = false

    private var fillColor: Color {
        switch state {
        case .distant: return Color(hex: "#6B8B94")
        case .inRange: return Color(hex: "#E67960")
        case .metToday: return Color(hex: "#967B68")
        case .strollChain: return Color(hex: "#E3A73B")
        }
    }

    var body: some View {
        Button {
            HapticsEngine.shared.playBrushStrokeTick()
            onTap()
        } label: {
            if isCompact {
                VStack(spacing: 2) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(fillColor, in: Circle())
                        .overlay(Circle().strokeBorder(AppTheme.warmPaper, lineWidth: 1.2))

                    Text(label)
                        .font(AppTheme.diegeticLabel(9))
                        .foregroundStyle(AppTheme.deepPineInk)
                        .lineLimit(1)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(AppTheme.warmPaper.opacity(0.9), in: Capsule())
                }
                .frame(minWidth: 44, maxWidth: 68, minHeight: 44)
                .contentShape(Rectangle())
            } else {
                VStack(spacing: 3) {
                    ZStack {
                        // 可愛小貓耳從地圖足印徽章頂端探出來！
                        CatEarAccentShape(
                            fillColor: Color(hex: "#FFFDF8"),
                            innerEarColor: fillColor.opacity(0.72),
                            strokeColor: fillColor.opacity(0.60)
                        )
                        .scaleEffect(0.64)
                        .offset(y: -19)

                        // Refined, balanced watercolor paw badge (fixed 46x46 frame so ripple never shifts label!)
                        Circle()
                            .fill(Color(hex: "#FFFDF8"))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(fillColor.opacity(0.55), lineWidth: 1.2))
                            .shadow(color: Color(hex: "#2D241E").opacity(0.18), radius: 6, y: 3)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [fillColor.opacity(0.92), fillColor],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 35, height: 35)

                        Image(systemName: state == .metToday ? "leaf.fill" : (state == .strollChain ? "sparkles" : "pawprint.fill"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)

                        // 熟悉街角顯示正在守候的常客小頭像；或在 75m 內冒出愛心提示「可以打招呼囉！」
                        if let regID = regularPetID, let regImg = UIImage(named: regID.replacingOccurrences(of: ".", with: "_")) {
                            Image(uiImage: regImg)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 22, height: 22)
                                .background(Color(hex: "#FFFDF8"))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppTheme.pawStrollChain, lineWidth: 1.2))
                                .shadow(color: AppTheme.deepPineInk.opacity(0.22), radius: 2, y: 1)
                                .offset(x: 18, y: -16)
                        } else if state == .inRange {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundStyle(Color(hex: "#FF7B89"))
                                .padding(3.5)
                                .background(Color(hex: "#FFFDF8"), in: Circle())
                                .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 2, y: 1)
                                .offset(x: 18, y: -16)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .background {
                        if state == .inRange || state == .strollChain {
                            Circle()
                                .stroke(fillColor.opacity(ripple ? 0.0 : 0.72), lineWidth: state == .strollChain ? 3.0 : 2.2)
                                .frame(width: 48, height: 48)
                                .scaleEffect(ripple ? 1.65 : 0.95)
                        }
                    }
                    .offset(y: (state == .inRange || state == .strollChain) && bob ? -3.5 : 0)

                    // Perfectly centered, crisp warm-ivory label pill!
                    HStack(spacing: 4) {
                        if isFamiliarCorner {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: "#E67960"))
                        }
                        Text("\(label) · \(distanceM)m")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#2F2A26"))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if familiarityStars > 0 {
                            Text(String(repeating: "★", count: familiarityStars))
                                .font(.system(size: 9))
                                .foregroundStyle(AppTheme.pawStrollChain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .frame(maxWidth: 152)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(hex: "#FFFDF8").opacity(0.95))
                            .overlay(Capsule(style: .continuous).stroke(fillColor.opacity(0.45), lineWidth: 0.9))
                            .shadow(color: Color(hex: "#2D241E").opacity(0.14), radius: 4, y: 2)
                    )
                }
                .frame(minWidth: 64, minHeight: 70)
            }
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.90, pressOffsetY: 2))
        .onAppear {
            if state == .inRange || state == .strollChain {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    ripple = true
                }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    bob = true
                }
            }
        }
        .accessibilityLabel("\(label)，距離 \(distanceM) 公尺")
    }
}

private struct AccessibleNearbyListSheet: View {
    @Bindable var coordinator: GameCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    CutePlushButton(
                        title: coordinator.isDiscoveringAnchors ? "正在尋找附近可步行街角…" : "探索目前位置的真實街角足印",
                        tone: .butterHoney,
                        fontSize: 13,
                        horizontalPadding: 14,
                        verticalPadding: 10,
                        icon: { Image(systemName: "location.magnifyingglass").font(.system(size: 12, weight: .bold)) },
                        action: {
                            Task {
                                await coordinator.discoverRealNeighborhoodAnchors(
                                    around: coordinator.locationService.currentLocation.coordinate
                                )
                            }
                        }
                    )
                    .disabled(coordinator.isDiscoveringAnchors)

                    Text("附近街角足印（\(coordinator.visibleAnchors.count) 處）")
                        .font(AppTheme.diegeticLabel(12))
                        .foregroundStyle(AppTheme.softInk)
                        .padding(.top, 4)

                    ForEach(coordinator.visibleAnchors, id: \.siteID) { anchor in
                        let dist = Int(coordinator.distanceMeters(to: anchor))
                        let state = coordinator.pawState(for: anchor)
                        let check = coordinator.proximityCheck(for: anchor)
                        let statusSubtitle: String = {
                            if state == .strollChain { return "金色漫步連鎖！" }
                            switch check {
                            case .eligible: return "已在 75m 範圍內"
                            case .alreadyMetToday: return "今日已打招呼"
                            case .staleFix, .poorAccuracy: return "定位確認中…"
                            case .movingTooFast: return "移動速度較快"
                            case .tooFar: return "需再走近一些"
                            }
                        }()
                        StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.timberWarm, paddingAmount: 12) {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(anchor.customLabel)
                                        .font(AppTheme.serifTitle(16))
                                        .foregroundStyle(AppTheme.deepPineInk)
                                    Text("\(dist) 公尺 · \(statusSubtitle)")
                                        .font(AppTheme.serifBody(12.5))
                                        .foregroundStyle(AppTheme.softInk)
                                }
                                Spacer(minLength: 4)
                                if state == .inRange || (state == .strollChain && dist <= 75) {
                                    CutePlushButton(
                                        title: "打招呼",
                                        tone: .matchaMint,
                                        fontSize: 12,
                                        horizontalPadding: 11,
                                        verticalPadding: 7,
                                        icon: { Image(systemName: "pawprint.fill").font(.system(size: 10, weight: .bold)) },
                                        action: {
                                            dismiss()
                                            _ = coordinator.attemptOpenAnchor(anchor)
                                        }
                                    )
                                } else if state == .distant || state == .strollChain {
                                    let walkMin = max(1, Int(ceil(Double(dist) / 75.0)))
                                    Text("步行約 \(walkMin) 分")
                                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.softInk)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: "#EFE7D8"), in: Capsule())
                                }
                                Menu {
                                    if let mergeTarget = coordinator.visibleAnchors.first(where: { $0.siteID != anchor.siteID }) {
                                        Button("合併至「\(mergeTarget.customLabel)」") {
                                            coordinator.mergeAnchor(sourceSiteID: anchor.siteID, intoTargetSiteID: mergeTarget.siteID)
                                        }
                                    }
                                    Button("隱藏此街角", role: .destructive) {
                                        coordinator.hideAnchor(siteID: anchor.siteID)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.system(size: 18))
                                        .foregroundStyle(AppTheme.softInk)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.parchmentTray)
            .navigationTitle("鄰近街角列表")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

/// 溫暖 3 步驟首次見面繪本導覽卡（介紹《貓與龍》奇幻街角世界觀、雙層無壓力散步與 100% 本機隱私）
private struct CozyWelcomeOnboardingCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onAllowLocation: () -> Void
    let onDismissLater: () -> Void
    @State private var step: Int = 0

    private let steps: [(title: String, body: String, icon: String)] = [
        (
            "歡迎來到《足印日記》",
            "老街騎樓和公園角落，住著八位奇幻鄰居。",
            "pawprint.fill"
        ),
        (
            "手機放口袋就能輕鬆累積",
            "平時走路就能存步數幣。也可以帶上帆布袋，出發散步。",
            "figure.walk"
        ),
        (
            "100% 本機私密 · 開啟散步定位",
            "足跡和日記留在這支 iPhone。開啟定位即可拜訪街角。",
            "location.fill"
        )
    ]

    var body: some View {
        let current = steps[step]
        StorybookPaperCard(cornerRadius: 20, accentColor: AppTheme.forestTeal, paddingAmount: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: current.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.forestTeal, in: Circle())

                    Text(current.title)
                        .font(AppTheme.serifTitle(16))
                        .foregroundStyle(AppTheme.deepPineInk)

                    Spacer()

                    HStack(spacing: 4) {
                        ForEach(0..<steps.count, id: \.self) { idx in
                            Circle()
                                .fill(idx == step ? AppTheme.forestTeal : AppTheme.timberWarm.opacity(0.4))
                                .frame(width: 6, height: 6)
                        }
                    }
                }

                Text(current.body)
                    .font(AppTheme.serifBody(13.5))
                    .foregroundStyle(AppTheme.softInk)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button("稍後再說", action: onDismissLater)
                        .font(AppTheme.diegeticLabel(12))
                        .foregroundStyle(AppTheme.softInk)

                    Spacer()

                    if step < steps.count - 1 {
                        CutePlushButton(
                            title: "下一頁",
                            tone: .butterHoney,
                            fontSize: 12.5,
                            horizontalPadding: 13,
                            verticalPadding: 7,
                            icon: { Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold)) },
                            action: {
                                CozySoundEngine.shared.playPaperFlip()
                                withAnimation(AppTheme.Motion.resolved(.settle, reduceMotion: reduceMotion)) {
                                    step += 1
                                }
                            }
                        )
                    } else {
                        CutePlushButton(
                            title: "開啟散步定位",
                            tone: .matchaMint,
                            fontSize: 12.5,
                            horizontalPadding: 13,
                            verticalPadding: 7,
                            icon: { Image(systemName: "location.fill").font(.system(size: 11, weight: .bold)) },
                            action: onAllowLocation
                        )
                    }
                }
            }
        }
    }
}
