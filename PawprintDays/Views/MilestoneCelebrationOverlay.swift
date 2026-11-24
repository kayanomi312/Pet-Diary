import SwiftUI

/// A joyful hanko-stamped storybook page that celebrates a milestone (bond tier-up, a new roommate,
/// a full cozy stamp card, a completed weather curio set, a new room theme or the veranda).
///
/// Attach anywhere with `.milestoneCelebrationOverlay(coordinator:)`. The modifier is nesting-safe:
/// when an ancestor already hosts the overlay, inner hosts stay silent. To host it app-wide during
/// integration, add one line to `RootStageView`'s outer ZStack:
///
///     .milestoneCelebrationOverlay(coordinator: coordinator)
struct MilestoneCelebrationOverlay: View {
    let celebration: MilestoneCelebration
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pageIn = false
    @State private var stamped = false
    @State private var petalsOut = false

    private var accent: Color { Color(hex: celebration.accentHex) }

    var body: some View {
        ZStack {
            Color(hex: "#2B211A").opacity(pageIn ? 0.34 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: close)
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    storybookPage
                    WashiTapeStrip(color: accent.opacity(0.55), angle: -2.5, width: 78)
                        .offset(y: -8)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: 340)
                .padding(.horizontal, 24)
                .scaleEffect(pageIn ? 1 : (reduceMotion ? 1 : 0.88))
                .offset(y: pageIn ? 0 : (reduceMotion ? 0 : 26))
                .opacity(pageIn ? 1 : 0)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onAppear {
            CozySoundEngine.shared.playCompassChime()
            withAnimation(AppTheme.Motion.resolved(.gentle, reduceMotion: reduceMotion)) {
                pageIn = true
            }
            withAnimation(AppTheme.Motion.resolved(.bouncy, reduceMotion: reduceMotion).delay(reduceMotion ? 0 : 0.28)) {
                stamped = true
            }
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.9).delay(0.36)) {
                    petalsOut = true
                }
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 0.3))
                HapticsEngine.shared.playCurioUnpack()
            }
        }
    }

    private var storybookPage: some View {
        VStack(spacing: 14) {
            hankoSeal
                .padding(.top, 10)

            VStack(spacing: 6) {
                Text(celebration.title)
                    .font(AppTheme.serifTitle(21))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(celebration.subtitle)
                    .font(AppTheme.diegeticLabel(12))
                    .foregroundStyle(accent.opacity(0.95))
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Text(celebration.detail)
                .font(AppTheme.handwritten(15))
                .foregroundStyle(AppTheme.softInk)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)

            if let badge = celebration.rewardBadge {
                HStack(spacing: 6) {
                    PaintedPouchIconView(size: 22)
                        .accessibilityHidden(true)
                    Text(badge)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.forestTeal)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppTheme.parchmentTray, in: Capsule())
                .overlay(Capsule().stroke(AppTheme.brassDark.opacity(0.45), lineWidth: 1))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("獎勵 \(badge)")
            }

            WoodPlaqueButton(
                title: "收進日記 ✦",
                systemImage: "book.closed.fill",
                tone: .forestTeal,
                fontSize: 14,
                verticalPadding: 12,
                fullWidth: true,
                action: close
            )
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFFDF8"), Color(hex: "#F6EEDF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(hex: "#D5C5AE").opacity(0.8), lineWidth: 1)
                )
                .overlay(
                    // Deckled inner border, like a pressed storybook page.
                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                        .stroke(accent.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                        .padding(7)
                )
                .shadow(color: Color(hex: "#2D241E").opacity(0.22), radius: 22, y: 10)
        )
    }

    private var hankoSeal: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { idx in
                let angle = Double(idx) * (360.0 / 12.0) * .pi / 180.0
                let radius: CGFloat = petalsOut ? 74 : 18
                Capsule()
                    .fill(idx % 2 == 0 ? AppTheme.pawStrollChain.opacity(0.85) : accent.opacity(0.7))
                    .frame(width: idx % 3 == 0 ? 9 : 6, height: idx % 3 == 0 ? 5 : 4)
                    .rotationEffect(.radians(angle))
                    .offset(x: cos(angle) * radius, y: sin(angle) * radius)
                    .opacity(petalsOut ? 0 : (stamped ? 0.9 : 0))
            }

            Circle()
                .fill(AppTheme.clothBookmark.opacity(0.10))
                .frame(width: 104, height: 104)
                .scaleEffect(stamped ? 1 : 0.6)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#FFF9F0"))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.clothBookmark, lineWidth: 3)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.clothBookmark.opacity(0.55), lineWidth: 1)
                    .padding(5)
                VStack(spacing: 2) {
                    Image(systemName: celebration.symbol)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(accent)
                    Text("足印")
                        .font(.system(size: 11, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.clothBookmark)
                }
            }
            .frame(width: 78, height: 78)
            .rotationEffect(.degrees(stamped ? -6 : -18))
            .scaleEffect(stamped ? 1 : (reduceMotion ? 1 : 1.7))
            .opacity(stamped ? 1 : 0)
        }
        .frame(height: 112)
        .accessibilityHidden(true)
    }

    private func close() {
        CozySoundEngine.shared.playPaperFlip()
        withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
            pageIn = false
        }
        onDismiss()
    }
}

// MARK: - Attachable modifier

private struct MilestoneCelebrationHostedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True below a view that already hosts the milestone celebration overlay.
    var milestoneCelebrationHosted: Bool {
        get { self[MilestoneCelebrationHostedKey.self] }
        set { self[MilestoneCelebrationHostedKey.self] = newValue }
    }
}

struct MilestoneCelebrationOverlayModifier: ViewModifier {
    @Bindable var coordinator: GameCoordinator
    var isEnabled: Bool = true
    @Environment(\.milestoneCelebrationHosted) private var hostedAbove
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .environment(\.milestoneCelebrationHosted, true)
            .overlay {
                if isEnabled, !hostedAbove, let celebration = coordinator.pendingMilestoneCelebration {
                    MilestoneCelebrationOverlay(celebration: celebration) {
                        coordinator.dismissMilestoneCelebration()
                    }
                    .id(celebration.id)
                    .transition(.opacity)
                    .zIndex(50)
                }
            }
            .animation(AppTheme.Motion.resolved(.gentle, reduceMotion: reduceMotion), value: coordinator.pendingMilestoneCelebration?.id)
    }
}

extension View {
    /// Shows `coordinator.pendingMilestoneCelebration` as a storybook overlay and dismisses it on tap.
    /// Pass `isEnabled: false` while a sheet presented from this view hosts the overlay instead.
    func milestoneCelebrationOverlay(coordinator: GameCoordinator, isEnabled: Bool = true) -> some View {
        modifier(MilestoneCelebrationOverlayModifier(coordinator: coordinator, isEnabled: isEnabled))
    }
}

#Preview("Stamp card") {
    MilestoneCelebrationOverlay(
        celebration: MilestoneCelebration(
            id: "preview",
            kind: .stampCard,
            title: "足印集章卡蓋滿了",
            subtitle: "第 1 張 · 七枚小印章",
            detail: "不必天天打卡，只要想出門的時候就出門。新的一張已經悄悄攤開。",
            symbol: "seal.fill",
            accentHex: "#B84A39",
            rewardBadge: "+15 步數幣"
        ),
        onDismiss: {}
    )
    .background(AppTheme.parchmentTray)
}
