import SwiftUI
import MapKit

struct StreetOverworldView: View {
    @Bindable var coordinator: GameCoordinator
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedFarAnchor: AnchorSiteRecord? = nil

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
                    ZStack {
                        Circle()
                            .fill(AppTheme.warmPaper)
                            .frame(width: 22, height: 22)
                            .shadow(color: AppTheme.deepPineInk.opacity(0.3), radius: 3)
                        Circle()
                            .fill(AppTheme.forestTeal)
                            .frame(width: 12, height: 12)
                    }
                    .accessibilityLabel("你目前的散步位置")
                }

                ForEach(coordinator.visibleAnchors, id: \.siteID) { anchor in
                    let state = coordinator.pawState(for: anchor)
                    let dist = Int(coordinator.distanceMeters(to: anchor))
                    Annotation(
                        "",
                        coordinate: CLLocationCoordinate2D(latitude: anchor.lat, longitude: anchor.lon)
                    ) {
                        PawAnchorStampView(
                            label: anchor.customLabel,
                            state: state,
                            distanceM: dist,
                            isFamiliarCorner: anchor.isFamiliarCorner
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
                    weather: coordinator.activeWeather
                )
                .padding(.top, 8)

                if coordinator.showOnboardingPaperSlip {
                    TornPaperSlipView(
                        text: "前方的街角有一枚等待相遇的小腳印。允許散步定位即可在巷口向動物打招呼；就算暫不開啟，也能寫私密日記。",
                        subtitle: "100% 留存本機 · 無須註冊帳號"
                    )
                    .overlay(alignment: .bottomTrailing) {
                        HStack(spacing: 10) {
                            Button("稍後") {
                                coordinator.showOnboardingPaperSlip = false
                            }
                            .font(AppTheme.diegeticLabel(12))
                            .foregroundStyle(AppTheme.softInk)

                            Button("開啟散步定位") {
                                coordinator.locationService.requestForegroundLocation()
                                coordinator.showOnboardingPaperSlip = false
                            }
                            .font(AppTheme.diegeticLabel(12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.forestTeal, in: Capsule())
                        }
                        .padding(10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
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
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(far.customLabel)
                                .font(AppTheme.serifTitle(15))
                                .foregroundStyle(AppTheme.deepPineInk)
                            Text("距離 \(Int(coordinator.distanceMeters(to: far))) 公尺 — 走近 75 公尺內即可打招呼。")
                                .font(AppTheme.serifBody(13))
                                .foregroundStyle(AppTheme.softInk)
                        }
                        Spacer()
                        Button("模擬走過去") {
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
                        .font(AppTheme.diegeticLabel(12))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.forestTeal, in: Capsule())
                    }
                    .padding(14)
                    .background(AppTheme.warmPaper.opacity(0.96), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                HStack(alignment: .bottom) {
                    BrassPocketCompassButton(
                        destinationLabel: "回到陽光室家園",
                        iconSystemName: "house.fill",
                        onTap: {
                            coordinator.solveHomeRoomNow()
                            coordinator.currentScreen = .home
                        },
                        onLongPress: {
                            coordinator.showAccessibleNearbyList = true
                        }
                    )

                    Spacer()

                    Button {
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
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 13, weight: .semibold))
                            Text("前方 60m 釘選熟悉街角")
                                .font(AppTheme.diegeticLabel(12))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(AppTheme.forestTeal, in: Capsule())
                        .shadow(color: AppTheme.deepPineInk.opacity(0.24), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 10)

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
    }
}

private struct PawAnchorStampView: View {
    let label: String
    let state: PawState
    let distanceM: Int
    let isFamiliarCorner: Bool
    let onTap: () -> Void

    @State private var ripple = false

    private var fillColor: Color {
        switch state {
        case .distant: return AppTheme.pawDistant
        case .inRange: return AppTheme.pawInRange
        case .metToday: return AppTheme.pawMetToday
        case .strollChain: return AppTheme.pawStrollChain
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack {
                    if state == .inRange || state == .strollChain {
                        Circle()
                            .stroke(fillColor.opacity(ripple ? 0.0 : 0.72), lineWidth: state == .strollChain ? 3.2 : 2.5)
                            .frame(width: ripple ? 68 : 42, height: ripple ? 68 : 42)
                    }

                    Circle()
                        .fill(AppTheme.warmPaper)
                        .frame(width: 46, height: 46)
                        .shadow(color: AppTheme.deepPineInk.opacity(0.28), radius: 5, y: 2)

                    Circle()
                        .fill(fillColor)
                        .frame(width: 38, height: 38)

                    Image(systemName: state == .metToday ? "leaf.fill" : (state == .strollChain ? "sparkles" : "pawprint.fill"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("\(label) · \(distanceM)m")
                    .font(AppTheme.diegeticLabel(11))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.warmPaper.opacity(0.95), in: Capsule())
                    .overlay(Capsule().stroke(fillColor.opacity(0.65), lineWidth: 1))
            }
            .frame(minWidth: 64, minHeight: 64)
        }
        .buttonStyle(.plain)
        .onAppear {
            if state == .inRange || state == .strollChain {
                withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    ripple = true
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
            List {
                Section("探索真實周遭街角") {
                    Button {
                        Task {
                            await coordinator.discoverRealNeighborhoodAnchors(
                                around: coordinator.locationService.currentLocation.coordinate
                            )
                        }
                    } label: {
                        Label(
                            coordinator.isDiscoveringAnchors ? "正在尋找附近可步行街角…" : "探索目前位置的真實街角足印",
                            systemImage: "location.magnifyingglass"
                        )
                    }
                    .disabled(coordinator.isDiscoveringAnchors)
                }

                Section("附近街角足印") {
                    ForEach(coordinator.visibleAnchors, id: \.siteID) { anchor in
                        let dist = Int(coordinator.distanceMeters(to: anchor))
                        let state = coordinator.pawState(for: anchor)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(anchor.customLabel)
                                    .font(AppTheme.serifTitle(16))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text("\(dist) 公尺 · \(state == .strollChain ? "金色漫步連鎖！" : state == .inRange ? "已在 75m 範圍內" : state == .metToday ? "今日已打招呼" : "需再走近一些")")
                                    .font(AppTheme.serifBody(13))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            if state == .inRange || (state == .strollChain && dist <= 75) {
                                Button("打招呼") {
                                    dismiss()
                                    _ = coordinator.attemptOpenAnchor(anchor)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.forestTeal)
                            } else if state == .distant || state == .strollChain {
                                Button("模擬走近") {
                                    let target = AnchorRotationEngine.coordinateAhead(
                                        from: CLLocationCoordinate2D(latitude: anchor.lat, longitude: anchor.lon),
                                        meters: 15,
                                        bearingDegrees: 180
                                    )
                                    coordinator.locationService.walkSimulated(to: target)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("隱藏", role: .destructive) {
                                coordinator.hideAnchor(siteID: anchor.siteID)
                            }
                            if let mergeTarget = coordinator.visibleAnchors.first(where: { $0.siteID != anchor.siteID }) {
                                Button("合併至鄰近") {
                                    coordinator.mergeAnchor(sourceSiteID: anchor.siteID, intoTargetSiteID: mergeTarget.siteID)
                                }
                                .tint(AppTheme.forestTeal)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.warmPaper)
            .navigationTitle("鄰近街角列表")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
