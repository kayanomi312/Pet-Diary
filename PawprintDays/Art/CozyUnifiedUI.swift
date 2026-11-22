import SwiftUI

/// 統一溫潤日式繪本 UI 設計系統（輕量毛玻璃暖棉紙、細緻線條、柔和陰影、零雜亂雙層邊框）
struct CozyGlassPill<Content: View>: View {
    var accentTint: Color? = nil
    var horizontalPadding: CGFloat = 12
    var verticalPadding: CGFloat = 7
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule(style: .continuous)
                            .fill((accentTint ?? Color(hex: "#FFFDF8")).opacity(accentTint != nil ? 0.90 : 0.86))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color(hex: "#CBBAA0").opacity(0.55), lineWidth: 0.85)
                    )
                    .shadow(color: Color(hex: "#2D241E").opacity(0.11), radius: 10, x: 0, y: 4)
            }
    }
}

struct CozyIconCircleButton: View {
    let systemImage: String
    var tint: Color = Color(hex: "#3A312B")
    var isActive: Bool = false
    var size: CGFloat = 40
    var accessibilityLabelText: String
    let action: () -> Void

    var body: some View {
        Button {
            HapticsEngine.shared.playBrushStrokeTick()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(isActive ? Color.white : tint)
                .frame(width: size, height: size)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(isActive ? AppTheme.forestTeal.opacity(0.95) : Color(hex: "#FFFDF8").opacity(0.88))
                        )
                        .overlay(
                            Circle()
                                .stroke(isActive ? Color.white.opacity(0.25) : Color(hex: "#CBBAA0").opacity(0.55), lineWidth: 0.85)
                        )
                        .shadow(color: Color(hex: "#2D241E").opacity(0.12), radius: 10, x: 0, y: 4)
                }
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.92, pressOffsetY: 1.5))
        .accessibilityLabel(accessibilityLabelText)
    }
}

/// 每頁唯一主視覺行動鈕（溫潤立體漸層、乾淨無雜亂虛線）
struct CozyHeroActionButton: View {
    let title: String
    let systemImage: String
    var style: HeroStyle = .amber
    let action: () -> Void

    enum HeroStyle {
        case amber      // 出發散步
        case terracotta // 回到家了
        case sage       // 完成佈置／確認

        var gradient: [Color] {
            switch self {
            case .amber:      return [Color(hex: "#F2C05C"), Color(hex: "#DF9A36")]
            case .terracotta: return [Color(hex: "#E6836B"), Color(hex: "#CE604A")]
            case .sage:       return [Color(hex: "#5B9279"), Color(hex: "#3E6F5A")]
            }
        }

        var foreground: Color {
            switch self {
            case .amber:      return Color(hex: "#3B2810")
            case .terracotta: return .white
            case .sage:       return .white
            }
        }
    }

    var body: some View {
        Button {
            HapticsEngine.shared.playBrushStrokeTick()
            action()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 14.5, weight: .bold))
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .background {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: style.gradient,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1.0)
                            .padding(0.5)
                    )
                    .shadow(color: style.gradient[1].opacity(0.36), radius: 12, x: 0, y: 5)
            }
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 2))
    }
}

/// 統一底部懸浮棉紙導覽列（街區 / 陽光室 / 日記 / 小舖）— 讓玩家在任何主畫面都一目瞭然、一鍵直達！
struct CozyFloatingDockBar: View {
    @Binding var currentScreen: AppScreen
    var coinBalance: Int
    var hasReadyMentorship: Bool = false
    var onSelectTab: ((AppScreen) -> Void)? = nil

    private struct DockTab: Identifiable {
        let id: String
        let title: String
        let icon: String
        let target: AppScreen
    }

    private let tabs: [DockTab] = [
        DockTab(id: "street", title: "街區", icon: "map.fill", target: .street),
        DockTab(id: "home", title: "陽光室", icon: "house.fill", target: .home),
        DockTab(id: "diary", title: "日記", icon: "book.closed.fill", target: .sketchbook),
        DockTab(id: "shop", title: "小舖", icon: "bag.fill", target: .curioCubbies)
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                let isSelected = (currentScreen == tab.target)
                Button {
                    guard !isSelected else { return }
                    HapticsEngine.shared.playBrushStrokeTick()
                    CozySoundEngine.shared.playPaperFlip()
                    if let onSelectTab {
                        onSelectTab(tab.target)
                    } else {
                        currentScreen = tab.target
                    }
                } label: {
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 17, weight: isSelected ? .bold : .medium))
                            if tab.id == "home" && hasReadyMentorship && !isSelected {
                                Circle()
                                    .fill(Color(hex: "#E67960"))
                                    .frame(width: 7, height: 7)
                                    .offset(x: 4, y: -2)
                            }
                        }
                        Text(tab.title)
                            .font(.system(size: 10.5, weight: isSelected ? .bold : .medium, design: .rounded))
                    }
                    .foregroundStyle(isSelected ? Color.white : Color(hex: "#5A4D43"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if isSelected {
                            Capsule(style: .continuous)
                                .fill(AppTheme.forestTeal)
                                .shadow(color: AppTheme.forestTeal.opacity(0.28), radius: 6, y: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .fill(Color(hex: "#FFFDF8").opacity(0.88))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color(hex: "#CBBAA0").opacity(0.55), lineWidth: 0.9)
                )
                .shadow(color: Color(hex: "#2B211A").opacity(0.15), radius: 16, x: 0, y: 6)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
        .animation(.spring(response: 0.30, dampingFraction: 0.78), value: currentScreen)
    }
}

// MARK: - Unified Stationery Popover Menu (Replaces stark iOS system Liquid Glass Menu!)
struct CozyPopoverMenuItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    var tint: Color = AppTheme.forestTeal
    var isDestructive: Bool = false
    let action: () -> Void
}

struct CozyPopoverMenuCard: View {
    let items: [CozyPopoverMenuItem]
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                Button {
                    HapticsEngine.shared.playBrushStrokeTick()
                    onDismiss()
                    item.action()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(item.isDestructive ? Color(hex: "#C85A32") : item.tint)
                            .frame(width: 26, height: 26)
                            .background(
                                Circle()
                                    .fill((item.isDestructive ? Color(hex: "#C85A32") : item.tint).opacity(0.11))
                            )
                        Text(item.title)
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(item.isDestructive ? Color(hex: "#B5482B") : Color(hex: "#2F2A26"))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if idx < items.count - 1 {
                    Divider()
                        .overlay(Color(hex: "#E2D6C3").opacity(0.75))
                        .padding(.horizontal, 12)
                }
            }
        }
        .frame(width: 214)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: "#FFFDF8").opacity(0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: "#D5C5AE").opacity(0.70), lineWidth: 0.9)
                )
                .shadow(color: Color(hex: "#2B211A").opacity(0.16), radius: 16, x: 0, y: 8)
        }
    }
}

// MARK: - Unified Segmented Pill Bar (Matches CozyFloatingDockBar & TactileCare Tray!)
struct CozySegmentedPillOption: Identifiable {
    let id: Int
    let title: String
    var systemImage: String? = nil
}

struct CozySegmentedPillBar: View {
    let options: [CozySegmentedPillOption]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { opt in
                let isSelected = (selection == opt.id)
                Button {
                    guard !isSelected else { return }
                    HapticsEngine.shared.playBrushStrokeTick()
                    CozySoundEngine.shared.playPaperFlip()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        selection = opt.id
                    }
                } label: {
                    HStack(spacing: 5) {
                        if let icon = opt.systemImage {
                            Image(systemName: icon)
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        Text(opt.title)
                            .font(.system(size: 12.5, weight: isSelected ? .bold : .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(isSelected ? Color.white : Color(hex: "#5A4D43"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if isSelected {
                            Capsule(style: .continuous)
                                .fill(AppTheme.forestTeal)
                                .shadow(color: AppTheme.forestTeal.opacity(0.24), radius: 5, y: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            Capsule(style: .continuous)
                .fill(Color(hex: "#EFE7D8").opacity(0.92))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color(hex: "#D5C5AE").opacity(0.65), lineWidth: 0.85)
                )
        }
    }
}
