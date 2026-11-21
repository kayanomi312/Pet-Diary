import SwiftUI

/// 黃銅懷錶羅盤（左下角實體道具 — 含微幅擺動指針、弧面玻璃反光與彈跳按壓手感）
struct BrassPocketCompassButton: View {
    let destinationLabel: String
    let iconSystemName: String
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let needleSwing = sin(t * 1.6) * 8.0

            VStack(spacing: 3) {
                ZStack {
                    // 懷錶吊環與黃銅錶冠
                    Circle()
                        .stroke(AppTheme.brassDark, lineWidth: 2.8)
                        .frame(width: 15, height: 15)
                        .offset(y: -32)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.brassLight)
                        .frame(width: 8, height: 5)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(AppTheme.brassDark, lineWidth: 0.9))
                        .offset(y: -27)

                    // 立體底座陰影唇邊
                    Circle()
                        .fill(Color(hex: "#5A3F13"))
                        .frame(width: 60, height: 60)
                        .offset(y: 3)

                    // 黃銅外殼
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "#F0D38E"), AppTheme.brassLight, AppTheme.brassDark],
                                center: .topLeading,
                                startRadius: 3,
                                endRadius: 36
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(Circle().stroke(AppTheme.deepPineInk.opacity(0.28), lineWidth: 1.1))
                        .shadow(color: AppTheme.deepPineInk.opacity(0.26), radius: 6, y: 3)

                    // 象牙白羅盤面
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "#FFFDF7"), AppTheme.warmPaper, Color(hex: "#EAE0CA")],
                                center: .center,
                                startRadius: 4,
                                endRadius: 26
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(Circle().stroke(AppTheme.brassDark.opacity(0.65), lineWidth: 1.3))

                    // 八方位刻度
                    ForEach(0..<8, id: \.self) { idx in
                        Rectangle()
                            .fill(idx % 2 == 0 ? AppTheme.deepPineInk.opacity(0.55) : AppTheme.timberWarm.opacity(0.45))
                            .frame(width: idx % 2 == 0 ? 1.6 : 1.0, height: idx % 2 == 0 ? 5 : 3)
                            .offset(y: -19)
                            .rotationEffect(.degrees(Double(idx) * 45))
                    }

                    // 微微晃動的古銅羅盤針
                    Capsule()
                        .fill(AppTheme.clothBookmark.opacity(0.42))
                        .frame(width: 3, height: 32)
                        .rotationEffect(.degrees(28 + needleSwing))

                    Image(systemName: iconSystemName)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(AppTheme.forestTeal)

                    // 弧面玻璃高光
                    Ellipse()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 24, height: 10)
                        .rotationEffect(.degrees(-25))
                        .offset(x: -7, y: -13)
                }
                .frame(width: 68, height: 68)
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .offset(y: isPressed ? 2.5 : 0)
                .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isPressed)

                Text(iconSystemName == "house.fill" ? "回陽光室" : "去散步")
                    .font(AppTheme.diegeticLabel(11))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.warmPaper.opacity(0.94), in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.brassDark.opacity(0.45), lineWidth: 0.9))
                    .shadow(color: AppTheme.deepPineInk.opacity(0.14), radius: 3, y: 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isPressed = true
            HapticsEngine.shared.playBrushStrokeTick()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(110))
                isPressed = false
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0.9, perform: onLongPress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(destinationLabel)
        .accessibilityHint("輕點前往，長按一秒開啟無障礙鄰近足印列表。")
        .accessibilityAddTraits(.isButton)
    }
}

/// 散步夥伴圓章（右下角實體道具 — 綠藤隨 1,400 步口袋拾遺生長，剩 200 步泛暖金微光）
struct CompanionMedallionView: View {
    let pet: PetSpec?
    let outfitID: String?
    let progressSteps: Int
    let isNearFind: Bool
    let onTap: () -> Void

    @State private var pulse = false

    private var progressFraction: Double {
        min(1.0, Double(progressSteps) / Double(StepCoinLedgerEngine.stepsPerPocketFind))
    }

    private var remainingSteps: Int {
        StepCoinLedgerEngine.stepsRemainingForPocketFind(progress: progressSteps)
    }

    var body: some View {
        Button {
            HapticsEngine.shared.playBrushStrokeTick()
            onTap()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isNearFind {
                        Circle()
                            .fill(AppTheme.pawStrollChain.opacity(pulse ? 0.42 : 0.16))
                            .frame(width: 74, height: 74)
                            .scaleEffect(pulse ? 1.14 : 0.95)
                    }

                    // 溫潤木紋外框底影
                    Circle()
                        .fill(AppTheme.timberDeep.opacity(0.32))
                        .frame(width: 62, height: 62)
                        .offset(y: 3)

                    Circle()
                        .fill(AppTheme.warmPaper)
                        .frame(width: 62, height: 62)
                        .shadow(color: AppTheme.deepPineInk.opacity(0.24), radius: 5, y: 3)

                    Circle()
                        .stroke(AppTheme.timberWarm.opacity(0.30), lineWidth: 5)
                        .frame(width: 58, height: 58)

                    Circle()
                        .trim(from: 0, to: max(0.06, progressFraction))
                        .stroke(
                            isNearFind ? AppTheme.pawStrollChain : AppTheme.vineGreen,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 58, height: 58)

                    // 藤蔓小嫩葉點綴在進度端點
                    Image(systemName: isNearFind ? "sparkles" : "leaf.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isNearFind ? AppTheme.pawStrollChain : AppTheme.vineGreen)
                        .padding(3)
                        .background(AppTheme.warmPaper, in: Circle())
                        .offset(y: -29)
                        .rotationEffect(.degrees(progressFraction * 360.0))

                    if let pet {
                        ProceduralPetRigView(
                            pet: pet,
                            outfitID: outfitID,
                            pose: .notice,
                            isHappySquint: isNearFind,
                            applyMetalPaperShader: false,
                            isStaticSnapshot: true
                        )
                        .frame(width: 68, height: 68)
                        .offset(y: 12)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .offset(y: isNearFind && pulse ? -1.5 : 0)
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.forestTeal.opacity(0.75))
                    }
                }
                .frame(width: 68, height: 68)

                Text(isNearFind ? "快拾獲啦!" : (pet != nil ? "\(pet!.name) · \(remainingSteps)步" : "散步夥伴"))
                    .font(AppTheme.diegeticLabel(10))
                    .foregroundStyle(isNearFind ? Color(hex: "#FFFDF7") : AppTheme.deepPineInk)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        (isNearFind ? AppTheme.pawStrollChain : AppTheme.warmPaper.opacity(0.94)),
                        in: Capsule()
                    )
                    .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 0.9))
                    .shadow(color: AppTheme.deepPineInk.opacity(0.14), radius: 3, y: 1)
            }
        }
        .buttonStyle(TactileGameButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityLabel(
            pet != nil
            ? "\(pet!.name) 散步夥伴圓章。再走 \(remainingSteps) 步就能撿到口袋拾遺。"
            : "打開精裝速寫日記與選擇散步夥伴。"
        )
    }
}

/// 陽光室角落實體道具（藤編玩具籃、陶瓷茶壺）
struct DiegeticCornerPropButton: View {
    let title: String
    let systemImage: String
    let fillColor: Color
    let badgeText: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(fillColor)
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppTheme.deepPineInk.opacity(0.24), lineWidth: 1.2)
                        )
                        .shadow(color: AppTheme.deepPineInk.opacity(0.22), radius: 5, y: 3)

                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AppTheme.deepPineInk)
                        .frame(width: 56, height: 56)

                    if let badgeText {
                        Text(badgeText)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AppTheme.forestTeal, in: Capsule())
                            .offset(x: 6, y: -4)
                    }
                }
                Text(title)
                    .font(AppTheme.diegeticLabel(11))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(AppTheme.warmPaper.opacity(0.92), in: Capsule())
            }
            .frame(minWidth: 64, minHeight: 64)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

/// 棉紙手撕暗角覆層（#FAF6EE 暖棉紙疊色 + 柔和紙邊光暈）
struct DeckledPaperVignetteOverlay: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                AppTheme.warmPaper
                    .opacity(0.22)
                    .blendMode(.multiply)

                RadialGradient(
                    colors: [
                        .clear,
                        .clear,
                        AppTheme.warmPaper.opacity(0.35),
                        AppTheme.warmPaper.opacity(0.75)
                    ],
                    center: .center,
                    startRadius: min(geo.size.width, geo.size.height) * 0.36,
                    endRadius: max(geo.size.width, geo.size.height) * 0.62
                )
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

/// 手撕棉紙低語條（WCAG AAA 11.4:1 戶外高對比 ＋ GPU 冷壓棉紙肌理 ＋ 縫線邊框）
struct TornPaperSlipView: View {
    @Environment(\.colorSchemeContrast) private var contrast
    let text: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.pawStrollChain)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 3) {
                    Text(text)
                        .font(AppTheme.serifBody(15.5))
                        .foregroundStyle(AppTheme.deepPineInk)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppTheme.diegeticLabel(11.5))
                            .foregroundStyle(AppTheme.forestTeal)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(contrast == .increased ? Color.white : AppTheme.warmPaper.opacity(0.97))
                    .colorEffect(ShaderLibrary.storybookPaperSurface())
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(AppTheme.timberWarm.opacity(0.24), style: StrokeStyle(lineWidth: 0.9, dash: [4, 3]))
                    .padding(3.5)
            }
            .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(
                    contrast == .increased ? AppTheme.deepPineInk : AppTheme.timberWarm.opacity(0.55),
                    lineWidth: contrast == .increased ? 2.0 : 1.2
                )
        )
    }
}

/// 頂部繪本遊戲書籤列（手繪天氣木牌、刺繡步數幣袋、硬殼日記本按鈕）
struct ClothBookmarkBar: View {
    let onOpenSketchbook: () -> Void
    let onOpenCubbies: () -> Void
    let onOpenFixture: () -> Void
    let dayTitle: String
    let weather: WeatherMode
    var coinBalance: Int? = nil

    var body: some View {
        HStack(spacing: 8) {
            // 左側：手繪天氣與日期木牌（點擊可開啟天氣與時間光影面板）
            Button {
                HapticsEngine.shared.playBrushStrokeTick()
                onOpenFixture()
            } label: {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(weatherBadgeTint.opacity(0.22))
                            .frame(width: 24, height: 24)
                        Image(systemName: weather.sfSymbol)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(weatherBadgeTint)
                    }
                    Text(dayTitle)
                        .font(AppTheme.serifBody(13))
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.deepPineInk)
                        .lineLimit(1)
                }
                .padding(.leading, 6)
                .padding(.trailing, 12)
                .padding(.vertical, 5)
                .background(
                    ZStack {
                        Capsule().fill(Color(hex: "#C8B392")).offset(y: 2.5)
                        Capsule().fill(AppTheme.warmPaper.opacity(0.97))
                        Capsule().stroke(AppTheme.timberWarm.opacity(0.55), lineWidth: 1.1)
                    }
                )
                .padding(.bottom, 2.5)
                .shadow(color: AppTheme.deepPineInk.opacity(0.16), radius: 4, y: 2)
            }
            .buttonStyle(TactileGameButtonStyle(pressScale: 0.95, pressOffsetY: 1.5))
            .accessibilityLabel("\(dayTitle)，\(weather.displayName)。點擊開啟測試與天氣切換面板。")

            Spacer(minLength: 4)

            // 右側 1：刺繡步數幣袋與拾遺木格按鈕
            Button {
                CozySoundEngine.shared.playPaperFlip()
                HapticsEngine.shared.playBrushStrokeTick()
                onOpenCubbies()
            } label: {
                HStack(spacing: 4) {
                    PaintedPouchIconView(size: 22)
                    if let coinBalance {
                        Text("\(coinBalance)")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundStyle(AppTheme.deepPineInk)
                    }
                }
                .padding(.horizontal, coinBalance != nil ? 10 : 8)
                .padding(.vertical, 6)
                .background(
                    ZStack {
                        Capsule().fill(Color(hex: "#B59563")).offset(y: 2.5)
                        Capsule().fill(AppTheme.warmPaper.opacity(0.97))
                        Capsule().stroke(AppTheme.brassDark.opacity(0.55), lineWidth: 1.1)
                    }
                )
                .padding(.bottom, 2.5)
                .shadow(color: AppTheme.deepPineInk.opacity(0.16), radius: 4, y: 2)
            }
            .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1.5))
            .accessibilityLabel("拾遺木格與步數幣袋")

            // 右側 2：精裝日記本縫線書籤鈕
            WoodPlaqueButton(
                title: "日記",
                systemImage: "book.closed.fill",
                tone: .forestTeal,
                fontSize: 12,
                horizontalPadding: 12,
                verticalPadding: 7,
                action: {
                    CozySoundEngine.shared.playPaperFlip()
                    onOpenSketchbook()
                }
            )
        }
        .padding(.horizontal, 16)
    }

    private var weatherBadgeTint: Color {
        switch weather {
        case .clearMorning: return AppTheme.pawStrollChain
        case .lightRain, .postRain: return AppTheme.forestTeal
        case .dusk: return AppTheme.pawInRange
        case .overcast: return AppTheme.softInk
        }
    }
}
