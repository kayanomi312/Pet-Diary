import SwiftUI

/// 黃銅懷錶羅盤（左下角實體道具）
struct BrassPocketCompassButton: View {
    let destinationLabel: String
    let iconSystemName: String
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        ZStack {
            // 懷錶吊環
            Circle()
                .stroke(AppTheme.brassDark, lineWidth: 2.5)
                .frame(width: 14, height: 14)
                .offset(y: -31)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.brassLight, AppTheme.brassDark],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 34
                    )
                )
                .frame(width: 58, height: 58)
                .shadow(color: AppTheme.deepPineInk.opacity(0.28), radius: 6, y: 3)

            Circle()
                .fill(AppTheme.warmPaper)
                .frame(width: 46, height: 46)
                .overlay(Circle().stroke(AppTheme.brassDark.opacity(0.55), lineWidth: 1.2))

            ForEach(0..<4, id: \.self) { idx in
                Rectangle()
                    .fill(AppTheme.deepPineInk.opacity(0.45))
                    .frame(width: 1.5, height: 5)
                    .offset(y: -18)
                    .rotationEffect(.degrees(Double(idx) * 90))
            }

            Image(systemName: iconSystemName)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(AppTheme.forestTeal)
        }
        .frame(width: 68, height: 68)
        .contentShape(Circle())
        .onTapGesture(perform: onTap)
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

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isNearFind {
                    Circle()
                        .fill(AppTheme.pawStrollChain.opacity(pulse ? 0.38 : 0.16))
                        .frame(width: 72, height: 72)
                        .scaleEffect(pulse ? 1.12 : 0.96)
                }

                Circle()
                    .fill(AppTheme.warmPaper)
                    .frame(width: 60, height: 60)
                    .shadow(color: AppTheme.deepPineInk.opacity(0.24), radius: 5, y: 3)

                Circle()
                    .stroke(AppTheme.timberWarm.opacity(0.28), lineWidth: 4.5)
                    .frame(width: 58, height: 58)

                Circle()
                    .trim(from: 0, to: max(0.06, progressFraction))
                    .stroke(
                        isNearFind ? AppTheme.pawStrollChain : AppTheme.vineGreen,
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 58, height: 58)

                if let pet {
                    ProceduralPetRigView(
                        pet: pet,
                        outfitID: outfitID,
                        pose: .notice,
                        isHappySquint: isNearFind,
                        applyMetalPaperShader: false,
                        isStaticSnapshot: true
                    )
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
                    .offset(y: isNearFind && pulse ? -1.5 : 0)
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.forestTeal.opacity(0.7))
                }
            }
            .frame(width: 68, height: 68)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityLabel(
            pet != nil
            ? "\(pet!.name) 散步夥伴圓章。再走 \(StepCoinLedgerEngine.stepsRemainingForPocketFind(progress: progressSteps)) 步就能撿到口袋拾遺。"
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

/// 手撕棉紙低語條（WCAG AAA 11.4:1 戶外高對比）
struct TornPaperSlipView: View {
    @Environment(\.colorSchemeContrast) private var contrast
    let text: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(AppTheme.serifBody(16))
                .foregroundStyle(AppTheme.deepPineInk)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.diegeticLabel(12))
                    .foregroundStyle(AppTheme.forestTeal)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(contrast == .increased ? Color.white : AppTheme.warmPaper.opacity(0.96))
                .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    contrast == .increased ? AppTheme.deepPineInk : AppTheme.timberWarm.opacity(0.45),
                    lineWidth: contrast == .increased ? 2.0 : 1.0
                )
        )
    }
}

/// 頂部布書籤列（日記本、拾遺木格與步數幣袋、測試工具）
struct ClothBookmarkBar: View {
    let onOpenSketchbook: () -> Void
    let onOpenCubbies: () -> Void
    let onOpenFixture: () -> Void
    let dayTitle: String
    let weather: WeatherMode

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: weather.sfSymbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.forestTeal)
                Text(dayTitle)
                    .font(AppTheme.serifBody(13))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(AppTheme.warmPaper.opacity(0.94), in: Capsule())
            .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.38), lineWidth: 1))
            .onTapGesture(perform: onOpenFixture)
            .accessibilityLabel("\(dayTitle)，\(weather.displayName)。點擊開啟測試與天氣切換面板。")

            Spacer()

            Button(action: onOpenSketchbook) {
                HStack(spacing: 5) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 13))
                    Text("日記")
                        .font(AppTheme.diegeticLabel(12))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.forestTeal, in: Capsule())
                .shadow(color: AppTheme.deepPineInk.opacity(0.18), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            Button(action: onOpenCubbies) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.warmPaper.opacity(0.94), in: Circle())
                    .overlay(Circle().stroke(AppTheme.timberWarm.opacity(0.45), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("拾遺木格與步數幣袋")
        }
        .padding(.horizontal, 16)
    }
}
