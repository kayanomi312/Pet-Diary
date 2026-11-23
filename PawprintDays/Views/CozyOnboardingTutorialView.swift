import SwiftUI
import CoreLocation

/// 溫潤日式手繪繪本「新手互動教學引導」（4 頁完整圖解，自動於首次開啟出現，也可於設定隨時重看）
struct CozyOnboardingTutorialView: View {
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
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: currentPage)

                // Bottom Progress Dots + Unified Action Bar
                VStack(spacing: 14) {
                    HStack(spacing: 7) {
                        ForEach(0..<totalPages, id: \.self) { idx in
                            Capsule(style: .continuous)
                                .fill(idx == currentPage ? AppTheme.forestTeal : Color(hex: "#CBBAA0").opacity(0.55))
                                .frame(width: idx == currentPage ? 22 : 7, height: 7)
                                .animation(.spring(response: 0.28, dampingFraction: 0.78), value: currentPage)
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

    // MARK: - Page 1: Welcome & 6 Mystical Creatures
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
                .padding(.top, 10)

                VStack(spacing: 8) {
                    Text("歡迎來到《足印日記》")
                        .font(AppTheme.serifTitle(25))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Text("一部陪你慢慢走過真實街角的奇幻水彩散步繪本")
                        .font(AppTheme.handwritten(15.5))
                        .foregroundStyle(AppTheme.forestTeal)
                        .multilineTextAlignment(.center)
                }

                StorybookPaperCard(cornerRadius: 20, showWashiTape: true, paddingAmount: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("藏在鄰里巷口的 6 位奇幻小靈獸")
                            .font(.system(size: 14.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.deepPineInk)
                        Text("赤瓦火龍貓「餘燼」、黑曜惡魔貓「杜松」、暮光夜魔貓「摺翼」、藍火小魔犬「鈕扣」、銀月星靈犬「梅子」與鹿角森靈犬「蘆葦」，正安靜躲在你熟悉的公園、咖啡館與轉角屋簷下，等你走近相遇。")
                            .font(AppTheme.serifBody(13.5))
                            .foregroundStyle(AppTheme.softInk)
                            .lineSpacing(3)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Page 2: Real Walking & Street Encounters
    private var walkingGuidePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
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

                VStack(spacing: 6) {
                    Text("第一步：真實散步與街角相遇")
                        .font(AppTheme.serifTitle(22))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Text("把手機放進口袋，用雙腳遇見奇幻夥伴")
                        .font(AppTheme.handwritten(14.5))
                        .foregroundStyle(AppTheme.forestTeal)
                }

                StorybookPaperCard(cornerRadius: 20, paddingAmount: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        tutorialBullet(
                            icon: "mappin.circle.fill",
                            tint: AppTheme.pawInRange,
                            title: "走近 75 公尺內輕點足印",
                            detail: "當你實際步行進入街角 75 公尺範圍，地圖足印會亮起暖橘色光暈，點擊即可進入街角水彩劇場。"
                        )
                        tutorialBullet(
                            icon: "hand.raised.fill",
                            tint: AppTheme.forestTeal,
                            title: "溫柔的互動問候",
                            detail: "長按伸手感受小靈獸一步步靠近的呼嚕，也能滑動滾出縫布球，或在雨天按住撐傘一起躲雨。"
                        )
                        tutorialBullet(
                            icon: "figure.walk",
                            tint: Color(hex: "#C98D26"),
                            title: "步數自動換幣與街區拾遺",
                            detail: "每走 200 步自動累積 1 枚步數幣；帶著夥伴走滿 1,400 步，牠還會替你撿回街區拾遺小物！"
                        )
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Page 3: 2.5D Mystical Sunroom
    private var sunroomGuidePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
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
                .padding(.top, 10)

                VStack(spacing: 6) {
                    Text("第二步：溫馨 2.5D 奇幻陽光室")
                        .font(AppTheme.serifTitle(22))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Text("邀請街角遇見的小靈獸住進你的木造陽光室")
                        .font(AppTheme.handwritten(14.5))
                        .foregroundStyle(AppTheme.forestTeal)
                }

                StorybookPaperCard(cornerRadius: 20, paddingAmount: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        tutorialBullet(
                            icon: "house.fill",
                            tint: AppTheme.forestTeal,
                            title: "自由漫步、呼喚與丟布球",
                            detail: "點擊木地板可喚最近的小靈獸走過來，也能按下「丟布球」看牠們在室內追球打鬧。"
                        )
                        tutorialBullet(
                            icon: "heart.fill",
                            tint: Color(hex: "#D66D50"),
                            title: "近距離互動陪玩與換裝",
                            detail: "輕點小靈獸進入照護畫面，摸頭、抓下巴、戳肚皮、梳毛，或替牠戴上手工緞帶與領巾（日常照護永久免費）。"
                        )
                        tutorialBullet(
                            icon: "slider.horizontal.3",
                            tint: Color(hex: "#C98D26"),
                            title: "自由佈置家飾與跨物種傳承",
                            detail: "用步數幣在「小舖」添購小暖爐、竹編吊床、苔蘚盆景與暖薑茶盤，拖曳擺放在陽光室各處！"
                        )
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Page 4: Private Sketchbook & Permissions
    private var diaryAndPermissionsPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
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

                VStack(spacing: 6) {
                    Text("第三步：私密手繪日記與出發準備")
                        .font(AppTheme.serifTitle(22))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Text("100% 留存本機 · 絕無錯過懲罰或每日壓力")
                        .font(AppTheme.handwritten(14.5))
                        .foregroundStyle(AppTheme.forestTeal)
                }

                StorybookPaperCard(cornerRadius: 20, paddingAmount: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        tutorialBullet(
                            icon: "photo.on.rectangle.angled",
                            tint: AppTheme.forestTeal,
                            title: "水彩明信片、鋼筆手記與月曆繪本",
                            detail: "每趟散步會自動印成水彩明信片，還可貼上當日拍立得、寫下心情，並匯出成可列印的月份 PDF 繪本。"
                        )
                    }
                }

                StorybookPaperCard(cornerRadius: 20, showWashiTape: true, paddingAmount: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("出發前開啟兩項散步權限（可隨時調整）")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.deepPineInk)

                        HStack(spacing: 10) {
                            let locStatus = coordinator.locationService.authorizationStatus
                            let locGranted = locStatus == .authorizedWhenInUse || locStatus == .authorizedAlways
                            let locDenied = locStatus == .denied || locStatus == .restricted
                            VStack(alignment: .leading, spacing: 2) {
                                Text("精準定位權限")
                                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text("用來發現真實街角足印與 75m 距離")
                                    .font(AppTheme.serifBody(11.5))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            Button(locGranted ? "已開啟 ✓" : (locDenied ? "前往設定" : "開啟定位")) {
                                if locDenied, let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                    openURL(settingsURL)
                                } else {
                                    coordinator.locationService.requestForegroundLocation()
                                }
                            }
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(locGranted ? AppTheme.forestTeal : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(locGranted ? AppTheme.forestTeal.opacity(0.14) : (locDenied ? AppTheme.pawInRange : AppTheme.forestTeal))
                            )
                            .buttonStyle(.plain)
                        }

                        Divider().overlay(Color(hex: "#E2D6C3"))

                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("動作與計步權限")
                                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text("將日常步數自動換成步數幣與拾遺")
                                    .font(AppTheme.serifBody(11.5))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            Button(coordinator.ledger.pedometerOptIn ? "已連結 ✓" : "連結計步") {
                                Task { await coordinator.optInAndSyncPedometer() }
                            }
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(coordinator.ledger.pedometerOptIn ? AppTheme.forestTeal : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(coordinator.ledger.pedometerOptIn ? AppTheme.forestTeal.opacity(0.14) : AppTheme.forestTeal)
                            )
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
    }

    private func tutorialBullet(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.12)))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.deepPineInk)
                Text(detail)
                    .font(AppTheme.serifBody(12.5))
                    .foregroundStyle(AppTheme.softInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
