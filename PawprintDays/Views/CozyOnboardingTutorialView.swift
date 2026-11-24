import SwiftUI
import CoreLocation
import CoreMotion

/// 溫潤日式手繪繪本「新手互動教學引導」（4 頁完整圖解，自動於首次開啟出現，也可於設定隨時重看）
struct CozyOnboardingTutorialView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @Bindable var coordinator: GameCoordinator
    @State private var currentPage: Int = 0

    private let totalPages = 4

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#F8F3E8"), Color(hex: "#EFE6D4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Skip & Step Counter
                HStack {
                    Text("新手引導 · \(currentPage + 1) / \(totalPages)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.forestTeal)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#FFFDF8"), in: Capsule())
                        .overlay(Capsule().stroke(Color(hex: "#D5C5AE").opacity(0.65), lineWidth: 0.85))

                    Spacer()

                    if currentPage < totalPages - 1 {
                        Button {
                            CozySoundEngine.shared.playPaperFlip()
                            HapticsEngine.shared.playBrushStrokeTick()
                            coordinator.completeInteractiveTutorial()
                        } label: {
                            Text("略過引導")
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(hex: "#7A6D5E"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // Main Interactive Pager
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    walkingGuidePage.tag(1)
                    sunroomGuidePage.tag(2)
                    diaryAndPermissionsPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppTheme.Motion.resolved(.settle, reduceMotion: reduceMotion), value: currentPage)

                // Bottom Progress Dots + Unified Action Bar
                VStack(spacing: 14) {
                    HStack(spacing: 7) {
                        ForEach(0..<totalPages, id: \.self) { idx in
                            Capsule(style: .continuous)
                                .fill(idx == currentPage ? AppTheme.forestTeal : Color(hex: "#CBBAA0").opacity(0.55))
                                .frame(width: idx == currentPage ? 22 : 7, height: 7)
                                .animation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion), value: currentPage)
                        }
                    }

                    HStack(spacing: 12) {
                        if currentPage > 0 {
                            Button {
                                CozySoundEngine.shared.playPaperFlip()
                                withAnimation { currentPage -= 1 }
                            } label: {
                                Text("上一頁")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "#4A3F35"))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 13)
                                    .background(Color(hex: "#FFFDF8"), in: Capsule())
                                    .overlay(Capsule().stroke(Color(hex: "#CBBAA0").opacity(0.65), lineWidth: 0.9))
                            }
                            .buttonStyle(TactileGameButtonStyle(pressScale: 0.95, pressOffsetY: 1))
                        }

                        if currentPage < totalPages - 1 {
                            CozyHeroActionButton(
                                title: "繼續下一頁",
                                systemImage: "arrow.right",
                                style: .sage
                            ) {
                                CozySoundEngine.shared.playPaperFlip()
                                withAnimation { currentPage += 1 }
                            }
                        } else {
                            CozyHeroActionButton(
                                title: "開始我的第一趟散步",
                                systemImage: "figure.walk",
                                style: .amber
                            ) {
                                CozySoundEngine.shared.playCompassChime()
                                HapticsEngine.shared.playCurioUnpack()
                                coordinator.completeInteractiveTutorial()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 26)
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Page 1: Welcome
    private var welcomePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                HStack(spacing: -20) {
                    ProceduralPetRigView(
                        pet: PetCatalog.pet(id: "pet.03"),
                        pose: .respond,
                        weatherMode: .clearMorning,
                        isHappySquint: true,
                        applyMetalPaperShader: false
                    )
                    .frame(width: 146, height: 146)

                    ProceduralPetRigView(
                        pet: PetCatalog.pet(id: "pet.02"),
                        pose: .notice,
                        weatherMode: .clearMorning,
                        applyMetalPaperShader: false
                    )
                    .frame(width: 138, height: 138)
                }
                .accessibilityHidden(true)
                .padding(.top, 10)

                pageHeading(
                    title: "歡迎來到《足印日記》",
                    tagline: "走過真實的街角，遇見藏在巷口的小靈獸"
                )

                StorybookPaperCard(cornerRadius: 20, showWashiTape: true, paddingAmount: 16) {
                    Text("六位奇幻小夥伴躲在公園、咖啡館與屋簷下。慢慢走，牠們就會出來打招呼。")
                        .font(AppTheme.handwritten(15.5))
                        .foregroundStyle(AppTheme.softInk)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Page 2: Real Walking & Street Encounters
    private var walkingGuidePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(AppTheme.pawInRange.opacity(0.14))
                        .frame(width: 112, height: 112)
                    Circle()
                        .stroke(AppTheme.pawInRange.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                        .frame(width: 132, height: 132)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(AppTheme.pawInRange)
                }
                .accessibilityHidden(true)
                .padding(.top, 16)

                pageHeading(
                    title: "走近街角，打聲招呼",
                    tagline: "手機放進口袋，用雙腳去相遇"
                )

                StorybookPaperCard(cornerRadius: 20, paddingAmount: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        storyLine(icon: "mappin.circle.fill", tint: AppTheme.pawInRange, text: "走到 75 公尺內，足印亮起就輕點它")
                        storyLine(icon: "hand.raised.fill", tint: AppTheme.forestTeal, text: "伸手、陪坐或滾顆布球，找出牠最愛的招呼")
                        storyLine(icon: "figure.walk", tint: AppTheme.pawStrollChain, text: "每 200 步換 1 枚步數幣，偶爾還會撿到小物")
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Page 3: Sunroom
    private var sunroomGuidePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                HStack(spacing: -16) {
                    ProceduralPetRigView(
                        pet: PetCatalog.pet(id: "pet.07"),
                        pose: .notice,
                        weatherMode: .clearMorning,
                        applyMetalPaperShader: false
                    )
                    .frame(width: 138, height: 138)

                    ProceduralPetRigView(
                        pet: PetCatalog.pet(id: "pet.08"),
                        pose: .respond,
                        weatherMode: .clearMorning,
                        isHappySquint: true,
                        applyMetalPaperShader: false
                    )
                    .frame(width: 138, height: 138)
                }
                .accessibilityHidden(true)
                .padding(.top, 10)

                pageHeading(
                    title: "邀牠們回陽光室",
                    tagline: "泡茶、梳毛、午睡，一起慢慢變熟"
                )

                StorybookPaperCard(cornerRadius: 20, paddingAmount: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        storyLine(icon: "heart.fill", tint: Color(hex: "#D66D50"), text: "相伴的日子越多，就會解鎖新的回憶與習慣")
                        storyLine(icon: "seal.fill", tint: AppTheme.clothBookmark, text: "想出門的日子蓋一枚章，集滿 7 枚有小禮物")
                        storyLine(icon: "bag.fill", tint: AppTheme.pawStrollChain, text: "用步數幣在小舖替陽光室換上新屋景")
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Page 4: Diary & Permissions
    private var diaryAndPermissionsPage: some View {
        let locStatus = coordinator.locationService.authorizationStatus
        let locGranted = locStatus == .authorizedWhenInUse || locStatus == .authorizedAlways
        let locDenied = locStatus == .denied || locStatus == .restricted
        let motionStatus = coordinator.pedometerService.authorizationStatus
        let motionDenied = motionStatus == .denied || motionStatus == .restricted
        let motionLinked = coordinator.ledger.pedometerOptIn && motionStatus == .authorized

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(AppTheme.forestTeal.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(AppTheme.forestTeal)
                }
                .accessibilityHidden(true)
                .padding(.top, 14)

                pageHeading(
                    title: "每一步，都是一頁日記",
                    tagline: "散步會自動畫成水彩明信片，收進你的足印日記"
                )

                StorybookPaperCard(cornerRadius: 20, showWashiTape: true, paddingAmount: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("出發前，開啟兩個小幫手")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.deepPineInk)

                        permissionRow(
                            title: "定位",
                            detail: "找到附近的街角足印",
                            granted: locGranted,
                            denied: locDenied,
                            grantedLabel: "已開啟 ✓",
                            requestLabel: "開啟定位"
                        ) {
                            coordinator.locationService.requestForegroundLocation()
                        }

                        Divider().overlay(Color(hex: "#E2D6C3"))

                        permissionRow(
                            title: "動作與計步",
                            detail: "把日常步數換成步數幣",
                            granted: motionLinked,
                            denied: motionDenied,
                            grantedLabel: "已連結 ✓",
                            requestLabel: "連結計步"
                        ) {
                            Task { await coordinator.optInAndSyncPedometer() }
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
    }

    private func pageHeading(title: String, tagline: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(AppTheme.serifTitle(23))
                .foregroundStyle(AppTheme.deepPineInk)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(tagline)
                .font(AppTheme.handwritten(15))
                .foregroundStyle(AppTheme.forestTeal)
                .multilineTextAlignment(.center)
        }
    }

    /// One breezy storybook line: a soft icon and a single short sentence.
    private func storyLine(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .center, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.12)))
                .accessibilityHidden(true)
            Text(text)
                .font(AppTheme.serifBody(13.5))
                .foregroundStyle(AppTheme.deepPineInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// A permission row whose button reflects the real system/ledger state, never an optimistic tap.
    private func permissionRow(
        title: String,
        detail: String,
        granted: Bool,
        denied: Bool,
        grantedLabel: String,
        requestLabel: String,
        request: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.deepPineInk)
                Text(detail)
                    .font(AppTheme.serifBody(11.5))
                    .foregroundStyle(AppTheme.softInk)
            }
            Spacer()
            Button(granted ? grantedLabel : (denied ? "前往設定" : requestLabel)) {
                if granted { return }
                if denied, let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                } else {
                    request()
                }
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(granted ? AppTheme.forestTeal : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(granted ? AppTheme.forestTeal.opacity(0.14) : (denied ? AppTheme.pawInRange : AppTheme.forestTeal))
            )
            .buttonStyle(.plain)
            .disabled(granted)
            .accessibilityHint(granted ? "已授權" : (denied ? "開啟系統設定" : "請求權限"))
        }
    }
}
