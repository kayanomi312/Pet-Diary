import SwiftUI
import MapKit

struct StreetOverworldView: View {
    @Bindable var coordinator: GameCoordinator
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedFarAnchor: AnchorSiteRecord? = nil
    @State private var hasCenteredOnRealGPS: Bool = false
    @State private var showStartStrollSheet: Bool = false

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

                ForEach(coordinator.visibleAnchors, id: \.siteID) { anchor in
                    let state = coordinator.pawState(for: anchor)
                    let dist = Int(coordinator.distanceMeters(to: anchor))
                    let showRegularPortrait = (anchor.totalVisitsCount > 0 || anchor.isFamiliarCorner)
                    Annotation(
                        "",
                        coordinate: CLLocationCoordinate2D(latitude: anchor.lat, longitude: anchor.lon)
                    ) {
                        PawAnchorStampView(
                            label: anchor.customLabel,
                            state: state,
                            distanceM: dist,
                            isFamiliarCorner: anchor.isFamiliarCorner,
                            familiarityStars: min(3, anchor.totalVisitsCount / 3),
                            regularPetID: showRegularPortrait ? anchor.regularPetID : nil
                        ) {
                            let check = coordinator.attemptOpenAnchor(anchor)
                            if case .tooFar = check {
                                selectedFarAnchor = anchor
                            }
                        }
                    }
                }
            }
            .mapStyle(
                .standard(
                    elevation: .flat,
                    emphasis: .muted,
                    pointsOfInterest: .including([.park, .publicTransport, .library, .cafe, .bakery]),
                    showsTraffic: false
                )
            )
            .ignoresSafeArea()

            DeckledPaperVignetteOverlay()

            VStack {
                ClothBookmarkBar(
                    onOpenSketchbook: { coordinator.currentScreen = .sketchbook },
                    onOpenCubbies: { coordinator.currentScreen = .curioCubbies },
                    onOpenFixture: { coordinator.showFixtureDrawer = true },
                    dayTitle: CivilCalendarHelper.displayDate(from: coordinator.currentLocalDateISO),
                    weather: coordinator.activeWeather,
                    coinBalance: coordinator.ledger.coinBalance
                )
                .padding(.top, 8)

                // 今日街角散步印章進度條 ＋ 精準 GPS 訊號小燈（點擊即可立即重新精準定位並回中心）
                let todayCount = Set(coordinator.encounters.filter { $0.localDateISO == coordinator.currentLocalDateISO }.map(\.siteID)).count
                HStack(spacing: 7) {
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { idx in
                            Image(systemName: idx < todayCount ? "pawprint.fill" : "pawprint")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(idx < todayCount ? Color(hex: "#E68068") : AppTheme.timberWarm.opacity(0.50))
                        }
                        Text(todayCount >= 3 ? "今日巡禮 ✦" : "街角 \(todayCount)/3")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundStyle(todayCount >= 3 ? AppTheme.forestTeal : Color(hex: "#3E2F28"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#FFFDF7"))
                            .overlay(Capsule().stroke(todayCount >= 3 ? AppTheme.pawStrollChain : Color(hex: "#D5BEA0"), lineWidth: 1.1))
                            .shadow(color: AppTheme.deepPineInk.opacity(0.12), radius: 3, y: 1.5)
                    )

                    // 即時 GPS 精準度徽章
                    Button {
                        HapticsEngine.shared.playBrushStrokeTick()
                        coordinator.locationService.requestFreshAccurateFix()
                        withAnimation(.easeInOut(duration: 0.55)) {
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: coordinator.locationService.currentLocation.coordinate,
                                    latitudinalMeters: 320,
                                    longitudinalMeters: 320
                                )
                            )
                        }
                    } label: {
                        let quality = coordinator.locationService.gpsSignalQuality
                        let accText: String = {
                            if coordinator.locationService.isReducedAccuracy {
                                return "請開精準定位"
                            }
                            if let acc = coordinator.locationService.gpsAccuracyMeters, !coordinator.locationService.useSimulatedPosition {
                                return "\(quality.rawValue) ±\(Int(acc))m"
                            }
                            return quality == .simulated ? "點此啟用真實GPS" : quality.rawValue
                        }()
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color(hex: quality.badgeColorHex))
                                .frame(width: 7, height: 7)
                            Text(accText)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#3E2F28"))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#FFFDF7"))
                                .overlay(Capsule().stroke(Color(hex: quality.badgeColorHex).opacity(0.65), lineWidth: 1.1))
                                .shadow(color: AppTheme.deepPineInk.opacity(0.12), radius: 3, y: 1.5)
                        )
                    }
                    .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1.5))

                    Spacer(minLength: 36)
                }
                .padding(.horizontal, 16)
                .padding(.top, 3)

                // 正在進行「出發散步」時的專屬同行橫幅（顯示即時步數、帆布袋小物與「回到家了」結算鈕）
                if let stroll = coordinator.activeStroll {
                    StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.forestTeal, paddingAmount: 10) {
                        HStack(spacing: 10) {
                            if let compID = stroll.companionPetID {
                                ProceduralPetRigView(
                                    pet: PetCatalog.pet(id: compID),
                                    outfitID: coordinator.resident(for: compID)?.activeOutfitID,
                                    pose: .notice,
                                    weatherMode: coordinator.activeWeather,
                                    applyMetalPaperShader: false,
                                    isStaticSnapshot: true
                                )
                                .frame(width: 40, height: 40)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(AppTheme.vineGreen)
                                        .frame(width: 7, height: 7)
                                    Text("散步同行中 · \(stroll.sessionSteps.formatted()) 步")
                                        .font(AppTheme.diegeticLabel(12))
                                        .foregroundStyle(AppTheme.deepPineInk)
                                }
                                Text(stroll.packedCharm == .none ? "空手輕鬆漫步 · 隨停不扣物" : "帆布袋：\(stroll.packedCharm.title)")
                                    .font(AppTheme.serifBody(11))
                                    .foregroundStyle(AppTheme.forestTeal)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 4)
                            WoodPlaqueButton(
                                title: "回到家了",
                                systemImage: "flag.checkered",
                                tone: .terracotta,
                                fontSize: 11.5,
                                horizontalPadding: 10,
                                verticalPadding: 6
                            ) {
                                _ = coordinator.endStrollSession()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if coordinator.showOnboardingPaperSlip {
                    CozyWelcomeOnboardingCard(
                        onAllowLocation: {
                            coordinator.locationService.requestForegroundLocation()
                            coordinator.showOnboardingPaperSlip = false
                        },
                        onDismissLater: {
                            coordinator.showOnboardingPaperSlip = false
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if coordinator.locationService.isTravelingTooFastForPaws {
                    TornPaperSlipView(text: "車速較快（超過 12 km/h）——小動物會在街角靜靜等你下車步行再見。")
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                }

                if let whisper = coordinator.transientWhisper {
                    TornPaperSlipView(text: whisper)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // 進行中的金色漫步連鎖溫柔提示條（無懲罰，可隨時略過）
                if let chainTargetID = coordinator.activeStrollChainTargetID,
                   let chainTarget = coordinator.anchors.first(where: { $0.siteID == chainTargetID }),
                   let guideID = coordinator.ledger.activeStrollChainGuidePetID {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppTheme.pawStrollChain)
                        Text("\(PetCatalog.pet(id: guideID).name)正望向「\(chainTarget.customLabel)」— 順路過去可遇見雙寵街頭場景")
                            .font(AppTheme.handwritten(13))
                            .foregroundStyle(AppTheme.deepPineInk)
                            .lineLimit(2)
                        Spacer(minLength: 4)
                        Button {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                cameraPosition = .region(
                                    MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(latitude: chainTarget.lat, longitude: chainTarget.lon),
                                        latitudinalMeters: 340,
                                        longitudinalMeters: 340
                                    )
                                )
                            }
                        } label: {
                            Text("看位置")
                                .font(AppTheme.diegeticLabel(11))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(AppTheme.pawStrollChain, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.warmPaper.opacity(0.95), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.pawStrollChain.opacity(0.7), lineWidth: 1.3))
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }

                // 口袋拾遺開箱卡片（每 1,400 步觸發）
                if let unpacked = coordinator.newlyUnpackedCurio {
                    let spec = CurioCatalog.curio(id: unpacked.curioID)
                    HStack(spacing: 12) {
                        PaintedCurioStampView(curioID: unpacked.curioID, size: 46)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("口袋拾遺 · \(spec.name)")
                                .font(AppTheme.serifTitle(15))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text(spec.journalNote)
                                .font(AppTheme.handwritten(12))
                                .foregroundStyle(AppTheme.softInk)
                                .lineLimit(2)
                        }
                        Spacer()
                        Button("收進木格") {
                            withAnimation { coordinator.newlyUnpackedCurio = nil }
                        }
                        .font(AppTheme.diegeticLabel(11))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.forestTeal, in: Capsule())
                    }
                    .padding(12)
                    .background(AppTheme.warmPaper.opacity(0.97), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.pawStrollChain.opacity(0.65), lineWidth: 1.5))
                    .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 8, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .transition(.scale.combined(with: .opacity))
                }

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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let far = selectedFarAnchor {
                    StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.timberWarm, paddingAmount: 13) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(far.customLabel)
                                    .font(AppTheme.serifTitle(15))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text("距離 \(Int(coordinator.distanceMeters(to: far))) 公尺 — 走近 75 公尺內即可打招呼。")
                                    .font(AppTheme.serifBody(12.5))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            WoodPlaqueButton(
                                title: "模擬走過去",
                                systemImage: "figure.walk",
                                tone: .forestTeal,
                                fontSize: 12,
                                horizontalPadding: 12,
                                verticalPadding: 8
                            ) {
                                let target = AnchorRotationEngine.coordinateAhead(
                                    from: CLLocationCoordinate2D(latitude: far.lat, longitude: far.lon),
                                    meters: 14,
                                    bearingDegrees: 210
                                )
                                coordinator.locationService.walkSimulated(to: target, stepsSegments: 6)
                                _ = coordinator.ingestSteps(steps: 240, placeLabel: far.customLabel)
                                selectedFarAnchor = nil
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    cameraPosition = .region(
                                        MKCoordinateRegion(center: target, latitudinalMeters: 300, longitudinalMeters: 300)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                HStack(alignment: .bottom) {
                    BrassPocketCompassButton(
                        destinationLabel: "回到陽光室家園",
                        iconSystemName: "house.fill",
                        onTap: {
                            CozySoundEngine.shared.playCompassChime()
                            coordinator.solveHomeRoomNow()
                            coordinator.currentScreen = .home
                        },
                        onLongPress: {
                            coordinator.showAccessibleNearbyList = true
                        }
                    )

                    Spacer()

                    // 中央主操作：超可愛糖霜奶油「出發散步」＋ 旁側手繪街角路標釘選鈕
                    HStack(spacing: 9) {
                        if coordinator.activeStroll == nil {
                            CutePlushButton(
                                title: "出發散步",
                                tone: .butterHoney,
                                fontSize: 14,
                                horizontalPadding: 15,
                                verticalPadding: 10,
                                icon: { CuteStrollBackpackIcon(size: 21) },
                                action: {
                                    CozySoundEngine.shared.playPaperFlip()
                                    showStartStrollSheet = true
                                }
                            )
                        } else {
                            CutePlushButton(
                                title: "回到家了",
                                tone: .strawberryCream,
                                fontSize: 13.5,
                                horizontalPadding: 14,
                                verticalPadding: 10,
                                icon: { CuteCottageIcon(size: 20) },
                                action: {
                                    _ = coordinator.endStrollSession()
                                }
                            )
                        }

                        // 旁側手繪肉球路標釘選鈕
                        Button {
                            CozySoundEngine.shared.playPaperFlip()
                            HapticsEngine.shared.playBrushStrokeTick()
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
                        } label: {
                            CutePawSignpostIcon(size: 24)
                                .frame(width: 44, height: 44)
                                .background(
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "#C9B493"))
                                            .offset(y: 3)
                                        Circle()
                                            .fill(Color(hex: "#FFFDF7"))
                                        Circle()
                                            .stroke(Color(hex: "#E2C9A2"), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                                            .padding(3)
                                        Circle()
                                            .stroke(Color(hex: "#B5956B").opacity(0.65), lineWidth: 1.2)
                                    }
                                )
                                .padding(.bottom, 3)
                                .shadow(color: AppTheme.deepPineInk.opacity(0.20), radius: 5, y: 3)
                        }
                        .buttonStyle(TactileGameButtonStyle(pressScale: 0.91, pressOffsetY: 2.5))
                        .accessibilityLabel("前方 60 公尺釘選熟悉街角")
                    }
                    .padding(.bottom, 16)

                    Spacer()

                    let activePet = coordinator.activeWalkCompanionID.map(PetCatalog.pet(id:))
                    let activeOutfit = coordinator.activeWalkCompanionID.flatMap { coordinator.resident(for: $0)?.activeOutfitID }
                    CompanionMedallionView(
                        pet: activePet,
                        outfitID: activeOutfit,
                        progressSteps: coordinator.ledger.pocketFindStepProgress,
                        isNearFind: coordinator.isNearPocketFind,
                        onTap: {
                            if let id = coordinator.activeWalkCompanionID {
                                coordinator.currentScreen = .tactileCare(petID: id)
                            } else {
                                coordinator.currentScreen = .sketchbook
                            }
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
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
        .overlay(alignment: .topTrailing) {
            // 輕巧定位回歸鈕（置於右上角「日記」下方，與左上角今日進度條左右對稱、不遮擋地圖中央足印）
            Button {
                HapticsEngine.shared.playBrushStrokeTick()
                withAnimation(.easeInOut(duration: 0.5)) {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coordinator.locationService.currentLocation.coordinate,
                            latitudinalMeters: 340,
                            longitudinalMeters: 340
                        )
                    )
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.forestTeal)
                    .frame(width: 38, height: 38)
                    .background(
                        ZStack {
                            Circle().fill(Color(hex: "#C8B392")).offset(y: 2.5)
                            Circle().fill(AppTheme.warmPaper.opacity(0.97))
                            Circle().stroke(AppTheme.timberWarm.opacity(0.55), lineWidth: 1.1)
                        }
                    )
                    .padding(.bottom, 2.5)
                    .shadow(color: AppTheme.deepPineInk.opacity(0.16), radius: 4, y: 2)
            }
            .buttonStyle(TactileGameButtonStyle())
            .padding(.trailing, 16)
            .padding(.top, 56)
            .accessibilityLabel("回到我目前的散步位置")
        }
    }
}

private struct PlayerLanternMapPinView: View {
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
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct PawAnchorStampView: View {
    let label: String
    let state: PawState
    let distanceM: Int
    let isFamiliarCorner: Bool
    var familiarityStars: Int = 0
    var regularPetID: String? = nil
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
            VStack(spacing: 3) {
                ZStack {
                    if state == .inRange || state == .strollChain {
                        Circle()
                            .stroke(fillColor.opacity(ripple ? 0.0 : 0.78), lineWidth: state == .strollChain ? 3.5 : 2.6)
                            .frame(width: ripple ? 76 : 44, height: ripple ? 76 : 44)
                    }

                    // 可愛小貓耳從地圖足印徽章頂端探出來！
                    CatEarAccentShape(
                        fillColor: Color(hex: "#FFFDF7"),
                        innerEarColor: fillColor.opacity(0.72),
                        strokeColor: fillColor.opacity(0.75)
                    )
                    .scaleEffect(0.68)
                    .offset(y: -21)

                    // 3D 奶霜糖果底影
                    Circle()
                        .fill(Color(hex: "#4A362B").opacity(0.28))
                        .frame(width: 48, height: 48)
                        .offset(y: 3)

                    // 暖棉紙外框 + 糖果細邊
                    Circle()
                        .fill(Color(hex: "#FFFDF7"))
                        .frame(width: 48, height: 48)
                        .overlay(Circle().stroke(fillColor.opacity(0.75), lineWidth: 1.5))
                        .shadow(color: AppTheme.deepPineInk.opacity(0.24), radius: 5, y: 2)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [fillColor.opacity(0.88), fillColor],
                                center: .topLeading,
                                startRadius: 3,
                                endRadius: 24
                            )
                        )
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.45), style: StrokeStyle(lineWidth: 1.1, dash: [3, 2]))
                                .padding(2)
                        )

                    Image(systemName: state == .metToday ? "leaf.fill" : (state == .strollChain ? "sparkles" : "pawprint.fill"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    // 熟悉街角顯示正在守候的常客小頭像；或在 75m 內冒出愛心提示「可以打招呼囉！」
                    if let regID = regularPetID, let regImg = UIImage(named: regID.replacingOccurrences(of: ".", with: "_")) {
                        Image(uiImage: regImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 24, height: 24)
                            .background(Color(hex: "#FFFDF7"))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.pawStrollChain, lineWidth: 1.2))
                            .shadow(color: AppTheme.deepPineInk.opacity(0.22), radius: 2, y: 1)
                            .offset(x: 20, y: -18)
                    } else if state == .inRange {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "#FF7B89"))
                            .padding(3.5)
                            .background(Color(hex: "#FFFDF7"), in: Circle())
                            .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 2, y: 1)
                            .offset(x: 20, y: -18)
                    }
                }
                .offset(y: (state == .inRange || state == .strollChain) && bob ? -5.0 : 0)

                HStack(spacing: 4) {
                    if isFamiliarCorner {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "#E67960"))
                    }
                    Text("\(label) · \(distanceM)m")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#3E2F28"))
                    if familiarityStars > 0 {
                        Text(String(repeating: "★", count: familiarityStars))
                            .font(.system(size: 9))
                            .foregroundStyle(AppTheme.pawStrollChain)
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 3.5)
                .background(
                    ZStack {
                        Capsule().fill(fillColor.opacity(0.32)).offset(y: 1.8)
                        Capsule().fill(Color(hex: "#FFFDF7"))
                        Capsule().stroke(fillColor.opacity(0.75), lineWidth: 1.1)
                    }
                )
            }
            .frame(minWidth: 64, minHeight: 70)
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.90, pressOffsetY: 2))
        .onAppear {
            if state == .inRange || state == .strollChain {
                withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    ripple = true
                }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
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
                        StorybookPaperCard(cornerRadius: 16, accentColor: AppTheme.timberWarm, paddingAmount: 12) {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(anchor.customLabel)
                                        .font(AppTheme.serifTitle(16))
                                        .foregroundStyle(AppTheme.deepPineInk)
                                    Text("\(dist) 公尺 · \(state == .strollChain ? "金色漫步連鎖！" : state == .inRange ? "已在 75m 範圍內" : state == .metToday ? "今日已打招呼" : "需再走近一些")")
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
                                    CutePlushButton(
                                        title: "模擬走近",
                                        tone: .milkCream,
                                        fontSize: 12,
                                        horizontalPadding: 10,
                                        verticalPadding: 7,
                                        icon: { Image(systemName: "figure.walk").font(.system(size: 10, weight: .bold)) },
                                        action: {
                                            let target = AnchorRotationEngine.coordinateAhead(
                                                from: CLLocationCoordinate2D(latitude: anchor.lat, longitude: anchor.lon),
                                                meters: 15,
                                                bearingDegrees: 180
                                            )
                                            coordinator.locationService.walkSimulated(to: target)
                                        }
                                    )
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
    let onAllowLocation: () -> Void
    let onDismissLater: () -> Void
    @State private var step: Int = 0

    private let steps: [(title: String, body: String, icon: String)] = [
        (
            "歡迎來到《足印日記》",
            "在熟悉的老街騎樓與公園角落，藏著赤炎龍貓、黑曜惡魔貓與星靈犬等 8 位溫柔的奇幻鄰居，正靜靜等著與你相遇。",
            "pawprint.fill"
        ),
        (
            "手機放口袋就能輕鬆累積",
            "不用特別按開始，日常走路就會把步數存成步數幣；想有儀式感時也能點「出發散步」，帶上不倒數、不浪費的帆布袋小物！",
            "figure.walk"
        ),
        (
            "100% 本機私密 · 開啟散步定位",
            "所有足跡與日記都只留在這支 iPhone 上，無須註冊帳號。允許精準散步定位，就能在真實街角遇見小動物。",
            "location.fill"
        )
    ]

    var body: some View {
        let current = steps[step]
        StorybookPaperCard(cornerRadius: 20, accentColor: AppTheme.forestTeal, showWashiTape: true, paddingAmount: 14) {
            VStack(alignment: .leading, spacing: 10) {
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
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
