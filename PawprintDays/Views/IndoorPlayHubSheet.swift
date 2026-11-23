import SwiftUI

// MARK: - Reusable Hybrid Offspring & Glowing Mystical Egg Views (Used in Nursery AND 2.5D Sunroom!)

/// Renders a raised Mystical Child combining:
/// - Body animation cel rig from `inheritedBodyPetID`
/// - Subtle watercolor coat tint from `inheritedTintPetID`
/// - Dual magical aura halo mixing BOTH parents' elemental colors!
struct HybridOffspringRigView: View {
    let offspring: MysticalOffspringRecord
    let weather: WeatherMode
    var isStatic: Bool = false
    var size: CGFloat = 104

    private var bodySpec: PetSpec { PetCatalog.pet(id: offspring.inheritedBodyPetID) }
    private var tintSpec: PetSpec { PetCatalog.pet(id: offspring.inheritedTintPetID) }

    var body: some View {
        ZStack {
            // Dual-parent blended mystical watercolor aura glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: tintSpec.accentHex).opacity(0.26),
                            Color(hex: bodySpec.accentHex).opacity(0.14),
                            .clear
                        ],
                        center: .center,
                        startRadius: size * 0.08,
                        endRadius: size * 0.54
                    )
                )
                .frame(width: size * 1.08, height: size * 1.08)

            if offspring.growthStage == .egg {
                GlowingMysticalEggView(
                    primaryHex: bodySpec.accentHex,
                    secondaryHex: tintSpec.accentHex,
                    size: size * 0.68
                )
            } else {
                ProceduralPetRigView(
                    pet: bodySpec,
                    pose: .notice,
                    weatherMode: weather,
                    isHappySquint: offspring.growthStage == .hatchling,
                    applyMetalPaperShader: false,
                    isStaticSnapshot: isStatic
                )
                .frame(width: size, height: size)
                // Gentle watercolor coat wash blending the second parent's hue!
                .colorMultiply(blendedCoatWash)
                .overlay(alignment: .topTrailing) {
                    // Inherited secondary parent sparkle crest
                    Image(systemName: tintSpec.kind.badgeSymbol)
                        .font(.system(size: max(9, size * 0.13), weight: .bold))
                        .foregroundStyle(Color(hex: tintSpec.accentHex))
                        .padding(3)
                        .background(Color(hex: "#FFFDF8").opacity(0.92), in: Circle())
                        .shadow(color: AppTheme.deepPineInk.opacity(0.16), radius: 2, y: 1)
                        .offset(x: -size * 0.10, y: size * 0.10)
                }
            }
        }
    }

    /// Soft pastel blend (82% pure white + 18% second-parent accent) so watercolor art stays crisp and harmonious.
    private var blendedCoatWash: Color {
        let ui = UIColor(Color(hex: tintSpec.accentHex))
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let mix: CGFloat = 0.22
        return Color(
            red: Double(1.0 * (1 - mix) + r * mix),
            green: Double(1.0 * (1 - mix) + g * mix),
            blue: Double(1.0 * (1 - mix) + b * mix)
        )
    }
}

/// Hand-crafted watercolor glowing Mystical Egg nestled on a woven straw cushion!
struct GlowingMysticalEggView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let primaryHex: String
    let secondaryHex: String
    var size: CGFloat = 72
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Soft straw nest base
            Ellipse()
                .fill(Color(hex: "#DFC394"))
                .frame(width: size * 0.96, height: size * 0.36)
                .overlay(Ellipse().stroke(Color(hex: "#9E784B").opacity(0.55), lineWidth: 1.1))
                .offset(y: size * 0.30)

            // Warm aura halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: secondaryHex).opacity(pulse ? 0.36 : 0.16), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: size * 0.56
                    )
                )
                .frame(width: size * 1.1, height: size * 1.1)

            // Painted speckled watercolor egg
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFFDF6"), Color(hex: primaryHex).opacity(0.32), Color(hex: secondaryHex).opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.62, height: size * 0.78)
                .overlay(
                    ZStack {
                        Circle().fill(Color(hex: primaryHex).opacity(0.55)).frame(width: size * 0.12).offset(x: -size * 0.08, y: -size * 0.08)
                        Circle().fill(Color(hex: secondaryHex).opacity(0.55)).frame(width: size * 0.09).offset(x: size * 0.10, y: size * 0.06)
                        Image(systemName: "sparkles")
                            .font(.system(size: size * 0.16, weight: .bold))
                            .foregroundStyle(Color(hex: "#FFFDF8").opacity(0.9))
                            .offset(y: -size * 0.14)
                    }
                )
                .overlay(Ellipse().stroke(Color(hex: "#6B5642").opacity(0.45), lineWidth: 1.2))
                .rotationEffect(.degrees(reduceMotion ? 0 : (pulse ? 2.5 : -2.5)))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Unified Cozy Indoor Play & Mystical Nursery Hub Sheet

struct IndoorPlayHubSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    enum HubTab: Int, CaseIterable {
        case wishes = 0
        case tea = 1
        case origami = 2
        case errands = 3
        case nursery = 4
    }

    @Bindable var coordinator: GameCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int

    // Tea Kitchen interactive swirl-brew state
    @State private var selectedRecipe: TeaRecipeSpec = TeaKitchenCatalog.allRecipes[0]
    @State private var brewProgress: CGFloat = 0.0
    @State private var lastBrewDragPoint: CGPoint? = nil

    // Origami 3-step folding state
    @State private var selectedOrigami: OrigamiCraftKind = .star
    @State private var origamiFoldStep: Int = 0 // 0 -> 1 -> 2 -> 3 (complete!)

    // Errand dispatch state
    @State private var selectedErrandPetID: String = "pet.03"
    @State private var selectedErrandSupply: ErrandSupplyPack = .bakeryBun

    // Nursery rename state
    @State private var renamingOffspringID: UUID? = nil
    @State private var renameDraft: String = ""

    private func lockedFeatureCard(_ feature: GameCoordinator.GameFeature) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: "#9A8A76"))
            Text("尚未開放")
                .font(AppTheme.serifTitle(16))
                .foregroundStyle(AppTheme.deepPineInk)
            Text(feature.lockedHint)
                .font(AppTheme.handwritten(13.5))
                .foregroundStyle(AppTheme.softInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Color(hex: "#EFE7D8").opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
    }

    init(coordinator: GameCoordinator, initialTab: HubTab = .wishes) {
        self.coordinator = coordinator
        self._selectedTab = State(initialValue: initialTab.rawValue)
        let invitedFirst = coordinator.residents.first(where: { $0.inviteState == .invitedHome })?.petID ?? "pet.03"
        self._selectedErrandPetID = State(initialValue: invitedFirst)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        tabChip(id: 0, title: "今日願望", icon: "star.fill", badge: coordinator.unclaimedCompletedWishesCount)
                        tabChip(id: 1, title: "茶點台", icon: "cup.and.saucer.fill")
                        tabChip(id: 2, title: "摺紙手作", icon: "paperplane.fill")
                        tabChip(id: 3, title: "靈獸探險", icon: "backpack.fill", badge: (coordinator.indoorState.activeErrand?.isReadyToReturn(at: coordinator.currentSimulatedDate) == true) ? 1 : 0)
                        tabChip(id: 4, title: "奇幻育兒", icon: "sparkles", badge: coordinator.indoorState.offsprings.filter { $0.growthStage != .grown }.count)
                    }
                    .padding(.horizontal, 16)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        switch selectedTab {
                        case 0: wishesSection
                        case 1: teaKitchenSection
                        case 2: origamiSection
                        case 3:
                            if coordinator.isFeatureUnlocked(.errands) { errandsSection } else { lockedFeatureCard(.errands) }
                        default:
                            if coordinator.isFeatureUnlocked(.nesting) { nurserySection } else { lockedFeatureCard(.nesting) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .padding(.top, 8)
            .background(Color(hex: "#F5EEE0"))
            .navigationTitle("陽光室手作與育兒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("闔上") { dismiss() }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.forestTeal)
                }
            }
        }
    }

    private func tabChip(id: Int, title: String, icon: String, badge: Int = 0) -> some View {
        let active = (selectedTab == id)
        return Button {
            HapticsEngine.shared.playBrushStrokeTick()
            CozySoundEngine.shared.playPaperFlip()
            withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
                selectedTab = id
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11.5, weight: .semibold))
                Text(title)
                    .font(.system(size: 12.5, weight: active ? .bold : .semibold, design: .rounded))
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(active ? AppTheme.forestTeal : .white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(active ? Color.white : Color(hex: "#D66D50"), in: Capsule())
                }
            }
            .foregroundStyle(active ? .white : Color(hex: "#4A3F35"))
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(active ? AppTheme.forestTeal : Color(hex: "#FFFDF8"))
                    .overlay(Capsule(style: .continuous).stroke(Color(hex: "#D5C5AE").opacity(active ? 0 : 0.70), lineWidth: 0.9))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab 1: Gentle Daily Wishes
    @ViewBuilder
    private var wishesSection: some View {
        let board = coordinator.todayWishesBoard
        StorybookPaperCard(cornerRadius: 18, showWashiTape: true, paddingAmount: 15) {
            VStack(alignment: .leading, spacing: 6) {
                Text("今日三個小小願望")
                    .font(AppTheme.serifTitle(17))
                    .foregroundStyle(AppTheme.deepPineInk)
                Text("無論雨天在家或外出散步都能輕鬆完成，沒有任何錯過懲罰。")
                    .font(AppTheme.serifBody(12.5))
                    .foregroundStyle(AppTheme.softInk)
            }
        }

        ForEach(board.wishes) { item in
            StorybookPaperCard(cornerRadius: 16, paddingAmount: 13) {
                HStack(spacing: 12) {
                    Image(systemName: item.kind.systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(item.isCompleted ? AppTheme.forestTeal : Color(hex: "#8A7B68"))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill((item.isCompleted ? AppTheme.forestTeal : Color(hex: "#CBBAA0")).opacity(0.14)))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.kind.title)
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.deepPineInk)
                        Text(item.isClaimed ? "已領取 +\(item.kind.rewardCoins) 步數幣" : (item.isCompleted ? "已完成！點擊領取小禮物" : "完成可獲得 +\(item.kind.rewardCoins) 步數幣"))
                            .font(AppTheme.serifBody(12))
                            .foregroundStyle(item.isCompleted ? AppTheme.forestTeal : AppTheme.softInk)
                    }

                    Spacer(minLength: 4)

                    if item.isClaimed {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.forestTeal)
                    } else if item.isCompleted {
                        WoodPlaqueButton(title: "領 +\(item.kind.rewardCoins)幣", tone: .brassGold, fontSize: 12, horizontalPadding: 12, verticalPadding: 7) {
                            _ = coordinator.claimDailyWishReward(item.kind)
                        }
                    } else {
                        Text("進行中")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "#8A7B68"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#EFE7D8"), in: Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Tab 2: Sunroom Tea & Biscuit Kitchen
    @ViewBuilder
    private var teaKitchenSection: some View {
        let unlocked = Set(coordinator.indoorState.unlockedTeaRecipeIDs)
        StorybookPaperCard(cornerRadius: 18, showWashiTape: true, paddingAmount: 15) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("陽光室手沖茶點台")
                        .font(AppTheme.serifTitle(17))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Spacer()
                    Text("配方圖鑑 \(unlocked.count)/\(TeaKitchenCatalog.allRecipes.count)")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.forestTeal)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#EFE7D8"), in: Capsule())
                }
                Text("選一道暖心茶點，用指尖在下方茶杯畫圈注水或翻烤，香氣會吸引窗外奇幻訪客並提升幼靈「溫柔」特質！")
                    .font(AppTheme.serifBody(12.5))
                    .foregroundStyle(AppTheme.softInk)
            }
        }

        // Recipe selector chips
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TeaKitchenCatalog.allRecipes) { recipe in
                    let isSel = (selectedRecipe.id == recipe.id)
                    let isKnown = unlocked.contains(recipe.id)
                    Button {
                        selectedRecipe = recipe
                        brewProgress = 0
                        HapticsEngine.shared.playBrushStrokeTick()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: recipe.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: recipe.tintHex))
                            Text(recipe.name)
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.deepPineInk)
                            if isKnown {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.forestTeal)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(isSel ? Color(hex: "#FFF7E4") : Color(hex: "#FFFDF8"))
                                .overlay(Capsule().stroke(isSel ? AppTheme.forestTeal : Color(hex: "#D5C5AE").opacity(0.65), lineWidth: isSel ? 1.8 : 0.9))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        // Interactive circular swirl-to-brew tactile pad
        StorybookPaperCard(cornerRadius: 20, paddingAmount: 18) {
            VStack(spacing: 14) {
                Text(selectedRecipe.name)
                    .font(AppTheme.serifTitle(18))
                    .foregroundStyle(AppTheme.deepPineInk)
                Text(selectedRecipe.aromaNote)
                    .font(AppTheme.handwritten(13.5))
                    .foregroundStyle(AppTheme.softInk)
                    .multilineTextAlignment(.center)

                ZStack {
                    Circle()
                        .fill(Color(hex: selectedRecipe.tintHex).opacity(0.12))
                        .frame(width: 144, height: 144)
                    Circle()
                        .stroke(Color(hex: "#D5C5AE").opacity(0.45), lineWidth: 7)
                        .frame(width: 132, height: 132)
                    Circle()
                        .trim(from: 0, to: brewProgress)
                        .stroke(Color(hex: selectedRecipe.tintHex), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 132, height: 132)

                    VStack(spacing: 5) {
                        Image(systemName: selectedRecipe.icon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Color(hex: selectedRecipe.tintHex))
                        Text(brewProgress >= 1.0 ? "香氣四溢 ✦" : "\(Int(brewProgress * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.deepPineInk)
                    }
                }
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            guard brewProgress < 1.0 else { return }
                            if let prev = lastBrewDragPoint {
                                let d = hypot(value.location.x - prev.x, value.location.y - prev.y)
                                if d > 4 {
                                    brewProgress = min(1.0, brewProgress + d / 560.0)
                                    if Int(brewProgress * 100) % 20 == 0 {
                                        HapticsEngine.shared.playBrushStrokeTick()
                                    }
                                    if brewProgress >= 1.0 {
                                        coordinator.brewTeaRecipe(selectedRecipe)
                                    }
                                }
                            }
                            lastBrewDragPoint = value.location
                        }
                        .onEnded { _ in
                            lastBrewDragPoint = nil
                        }
                )
                .onTapGesture {
                    // Accessible tap fallback
                    guard brewProgress < 1.0 else { return }
                    HapticsEngine.shared.playBrushStrokeTick()
                    withAnimation(.easeOut(duration: 0.2)) {
                        brewProgress = min(1.0, brewProgress + 0.34)
                    }
                    if brewProgress >= 1.0 {
                        coordinator.brewTeaRecipe(selectedRecipe)
                    }
                }

                Text(brewProgress >= 1.0 ? "已端上陽光室茶席！點下方可再沖一壺" : selectedRecipe.brewPrompt)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.forestTeal)

                if brewProgress >= 1.0 {
                    WoodPlaqueButton(title: "再沖泡一壺新茶點", systemImage: "arrow.clockwise", tone: .warmCream, fontSize: 12.5) {
                        withAnimation { brewProgress = 0 }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Tab 3: Juniper's Origami Folding Workshop
    @ViewBuilder
    private var origamiSection: some View {
        StorybookPaperCard(cornerRadius: 18, showWashiTape: true, paddingAmount: 15) {
            VStack(alignment: .leading, spacing: 6) {
                Text("杜松的手作和紙摺紙")
                    .font(AppTheme.serifTitle(17))
                    .foregroundStyle(AppTheme.deepPineInk)
                Text("摺好的紙鶴、小星與迷你紙龍會掛在陽光室窗樑上隨風輕晃，也能提升幼靈的「好奇」與「靈性」！")
                    .font(AppTheme.serifBody(12.5))
                    .foregroundStyle(AppTheme.softInk)
            }
        }

        HStack(spacing: 8) {
            ForEach(OrigamiCraftKind.allCases) { kind in
                let isSel = (selectedOrigami == kind)
                Button {
                    selectedOrigami = kind
                    origamiFoldStep = 0
                    HapticsEngine.shared.playBrushStrokeTick()
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: kind.sfSymbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(hex: kind.colorHex))
                        Text(kind.title)
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.deepPineInk)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 14).fill(isSel ? Color(hex: "#FFF7E4") : Color(hex: "#FFFDF8"))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSel ? AppTheme.forestTeal : Color(hex: "#D5C5AE").opacity(0.65), lineWidth: isSel ? 1.8 : 0.9))
                    )
                }
                .buttonStyle(.plain)
            }
        }

        StorybookPaperCard(cornerRadius: 20, paddingAmount: 18) {
            let stepPrompts = [
                "第 1 摺：向右滑動或輕點和紙，摺出對角線",
                "第 2 摺：再次滑動或輕點，收起兩側小翼角",
                "第 3 摺：最後輕壓摺痕，完成作品掛上窗樑！",
                "完成囉！已掛上陽光室窗樑 ✦"
            ]
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: origamiFoldStep == 0 ? 12 : (origamiFoldStep == 1 ? 26 : 42))
                        .fill(Color(hex: selectedOrigami.colorHex).opacity(0.20 + Double(origamiFoldStep) * 0.14))
                        .frame(width: 122 - CGFloat(origamiFoldStep) * 8, height: 122 - CGFloat(origamiFoldStep) * 8)
                        .rotationEffect(.degrees(Double(origamiFoldStep) * 15))
                        .overlay(
                            RoundedRectangle(cornerRadius: origamiFoldStep == 0 ? 12 : (origamiFoldStep == 1 ? 26 : 42))
                                .stroke(Color(hex: selectedOrigami.colorHex), lineWidth: 1.6)
                                .rotationEffect(.degrees(Double(origamiFoldStep) * 15))
                        )
                    Image(systemName: selectedOrigami.sfSymbol)
                        .font(.system(size: 32 + CGFloat(origamiFoldStep) * 4, weight: .semibold))
                        .foregroundStyle(Color(hex: selectedOrigami.colorHex))
                }
                .frame(height: 136)
                .contentShape(Rectangle())
                .onTapGesture { advanceOrigamiFold() }
                .gesture(
                    DragGesture(minimumDistance: 24)
                        .onEnded { _ in advanceOrigamiFold() }
                )

                Text(stepPrompts[min(origamiFoldStep, 3)])
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.forestTeal)

                if origamiFoldStep >= 3 {
                    WoodPlaqueButton(title: "再摺一件新掛飾", systemImage: "plus", tone: .warmCream, fontSize: 12.5) {
                        withAnimation(AppTheme.Motion.resolved(.settle, reduceMotion: reduceMotion)) {
                            origamiFoldStep = 0
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func advanceOrigamiFold() {
        guard origamiFoldStep < 3 else { return }
        CozySoundEngine.shared.playPaperFlip()
        HapticsEngine.shared.playBrushStrokeTick()
        withAnimation(AppTheme.Motion.resolved(.settle, reduceMotion: reduceMotion)) {
            origamiFoldStep += 1
        }
        if origamiFoldStep == 3 {
            coordinator.craftOrigami(selectedOrigami)
        }
    }

    // MARK: - Tab 4: Solo Pet Errands (Tabikaeru-Style Rainy-Day Exploration)
    @ViewBuilder
    private var errandsSection: some View {
        let invited = coordinator.residents.filter { $0.inviteState == .invitedHome }

        if let active = coordinator.indoorState.activeErrand {
            let ready = active.isReadyToReturn(at: coordinator.currentSimulatedDate)
            let minsLeft = max(1, Int(ceil(active.remainingSeconds(at: coordinator.currentSimulatedDate) / 60.0)))
            StorybookPaperCard(cornerRadius: 20, showWashiTape: true, paddingAmount: 16) {
                VStack(spacing: 12) {
                    ProceduralPetRigView(
                        pet: PetCatalog.pet(id: active.petID),
                        pose: .respond,
                        weatherMode: coordinator.activeWeather,
                        isHappySquint: ready,
                        applyMetalPaperShader: false,
                        isStaticSnapshot: true
                    )
                    .frame(width: 88, height: 88)

                    Text("\(coordinator.displayName(for: active.petID))正在「\(active.destinationLabel)」探險")
                        .font(AppTheme.serifTitle(16.5))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Text(ready ? "已經背著滿滿收穫回到門口囉！" : "攜帶「\(active.supply.title)」· 約 \(minsLeft) 分鐘後返家")
                        .font(AppTheme.handwritten(13.5))
                        .foregroundStyle(AppTheme.forestTeal)

                    if ready {
                        CozyHeroActionButton(title: "迎接返家領明信片", systemImage: "envelope.open.fill", style: .amber) {
                            _ = coordinator.collectReturnedErrand()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            StorybookPaperCard(cornerRadius: 18, showWashiTape: true, paddingAmount: 15) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("靈獸獨自出門小探險")
                        .font(AppTheme.serifTitle(17))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Text("下雨天或不方便出門時，替小靈獸準備小點心與雨傘，讓牠獨自去街區散步帶回明信片、拾遺與步數幣！")
                        .font(AppTheme.serifBody(12.5))
                        .foregroundStyle(AppTheme.softInk)
                }
            }

            // Pick invited pet
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(invited, id: \.petID) { res in
                        let spec = PetCatalog.pet(id: res.petID)
                        let sel = (selectedErrandPetID == res.petID)
                        Button {
                            selectedErrandPetID = res.petID
                            HapticsEngine.shared.playBrushStrokeTick()
                        } label: {
                            HStack(spacing: 6) {
                                Text(coordinator.displayName(for: res.petID))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                Text(spec.gender.symbol)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(hex: spec.gender.badgeHex))
                            }
                            .foregroundStyle(sel ? .white : AppTheme.deepPineInk)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(sel ? AppTheme.forestTeal : Color(hex: "#FFFDF8")))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Pick supply pack
            ForEach(ErrandSupplyPack.allCases) { pack in
                let sel = (selectedErrandSupply == pack)
                Button {
                    selectedErrandSupply = pack
                    HapticsEngine.shared.playBrushStrokeTick()
                } label: {
                    StorybookPaperCard(cornerRadius: 16, paddingAmount: 13) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(pack.title)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.deepPineInk)
                                    Text(pack.costCoins == 0 ? "免費" : "\(pack.costCoins) 幣")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.forestTeal)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: "#EFE7D8"), in: Capsule())
                                }
                                Text(pack.summary)
                                    .font(AppTheme.serifBody(12))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            Image(systemName: sel ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(sel ? AppTheme.forestTeal : Color(hex: "#CBBAA0"))
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            WoodPlaqueButton(title: "替牠背上行囊出發探險", systemImage: "figure.walk", tone: .forestTeal, fontSize: 14, verticalPadding: 12, fullWidth: true) {
                _ = coordinator.sendPetOnErrand(petID: selectedErrandPetID, supply: selectedErrandSupply)
            }
        }

        if !coordinator.indoorState.errandHistory.isEmpty {
            Text("近期探險返家明信片")
                .font(AppTheme.serifTitle(15))
                .foregroundStyle(AppTheme.deepPineInk)
                .padding(.top, 4)

            ForEach(coordinator.indoorState.errandHistory.prefix(5)) { card in
                StorybookPaperCard(cornerRadius: 15, paddingAmount: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(card.destinationLabel) · +\(card.coinsEarned)幣")
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.forestTeal)
                            Spacer()
                            Text(card.localDateISO)
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundStyle(AppTheme.softInk)
                        }
                        Text(card.storyLine)
                            .font(AppTheme.handwritten(13))
                            .foregroundStyle(AppTheme.deepPineInk)
                    }
                }
            }
        }
    }

    // MARK: - Tab 5: Mystical Nursery, Hybrid Pairing & Slow 4-5 Day Personality Raising!
    @ViewBuilder
    private var nurserySection: some View {
        StorybookPaperCard(cornerRadius: 18, showWashiTape: true, paddingAmount: 15) {
            VStack(alignment: .leading, spacing: 6) {
                Text("奇幻育兒室 · 結緣築巢與性格培育")
                    .font(AppTheme.serifTitle(17))
                    .foregroundStyle(AppTheme.deepPineInk)
                Text("邀請不同性別（♂ × ♀）的奇幻夥伴即可跨物種築巢誕生靈卵！接下來 4–5 天內，你的散步與室內陪伴活動會真實塑造幼靈的性格與雙親混合靈光。")
                    .font(AppTheme.serifBody(12.5))
                    .foregroundStyle(AppTheme.softInk)
            }
        }

        // Raised / Growing Offspring Cards
        let children = coordinator.indoorState.offsprings
        if !children.isEmpty {
            ForEach(children) { child in
                offspringCard(child)
            }
        }

        // Nesting Pair Selector (Any opposite-gender invited pair!)
        let pairs = coordinator.eligibleNestingPairs
        StorybookPaperCard(cornerRadius: 18, paddingAmount: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("可結緣築巢的奇幻伴侶（♂ × ♀）")
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.deepPineInk)

                if pairs.isEmpty {
                    Text("目前陽光室還需要至少 1 位男孩子（♂ 杜松／餘燼／鈕扣）與 1 位女孩子（♀ 摺翼／梅子／蘆葦）。外出散步或在窗邊迎接新訪客吧！")
                        .font(AppTheme.serifBody(12.5))
                        .foregroundStyle(AppTheme.softInk)
                } else {
                    ForEach(pairs) { pair in
                        let fSpec = PetCatalog.pet(id: pair.fatherID)
                        let mSpec = PetCatalog.pet(id: pair.motherID)
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 4) {
                                    Text("\(coordinator.displayName(for: fSpec.id)) ♂")
                                        .foregroundStyle(Color(hex: PetGender.male.badgeHex))
                                    Text("×")
                                        .foregroundStyle(AppTheme.softInk)
                                    Text("\(coordinator.displayName(for: mSpec.id)) ♀")
                                        .foregroundStyle(Color(hex: PetGender.female.badgeHex))
                                }
                                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                Text("可能覺醒混合特質：「\(pair.blendedHabit)」")
                                    .font(AppTheme.serifBody(11.5))
                                    .foregroundStyle(AppTheme.softInk)
                            }
                            Spacer()
                            WoodPlaqueButton(title: "結緣築巢", systemImage: "sparkles", tone: .forestTeal, fontSize: 12, horizontalPadding: 11, verticalPadding: 7) {
                                _ = coordinator.startMysticalNest(fatherID: pair.fatherID, motherID: pair.motherID)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func offspringCard(_ child: MysticalOffspringRecord) -> some View {
        let arch = child.awakenedArchetypeID.flatMap(OffspringCatalog.archetype(id:))
        StorybookPaperCard(cornerRadius: 20, paddingAmount: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    HybridOffspringRigView(offspring: child, weather: coordinator.activeWeather, isStatic: true, size: 78)

                    VStack(alignment: .leading, spacing: 4) {
                        if renamingOffspringID == child.id {
                            HStack(spacing: 6) {
                                TextField("輸入幼靈名字", text: $renameDraft)
                                    .textFieldStyle(.roundedBorder)
                                    .font(AppTheme.serifBody(13))
                                Button("存") {
                                    coordinator.renameOffspring(id: child.id, newName: renameDraft)
                                    renamingOffspringID = nil
                                }
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(AppTheme.forestTeal, in: Capsule())
                            }
                        } else {
                            HStack(spacing: 5) {
                                Text(child.name)
                                    .font(AppTheme.serifTitle(17))
                                    .foregroundStyle(AppTheme.deepPineInk)
                                Text(child.gender.symbol)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(hex: child.gender.badgeHex))
                                Button {
                                    renameDraft = child.name
                                    renamingOffspringID = child.id
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(AppTheme.forestTeal)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("\(child.growthStage.title) · 混合特質「\(child.blendedHabitTitle)」")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.forestTeal)

                        Text("雙親：\(coordinator.displayName(for: child.fatherPetID)) × \(coordinator.displayName(for: child.motherPetID))")
                            .font(AppTheme.serifBody(11.5))
                            .foregroundStyle(AppTheme.softInk)

                        Text(child.nextMilestoneHint)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "#B57B2E"))
                    }
                    Spacer(minLength: 0)
                }

                // 4-Axis Personality Shaping Bars
                let maxPts = max(6, max(child.bravePoints, max(child.gentlePoints, max(child.playfulPoints, child.mysticalPoints))))
                VStack(spacing: 5) {
                    personalityBar(axis: .brave, value: child.bravePoints, maxVal: maxPts)
                    personalityBar(axis: .gentle, value: child.gentlePoints, maxVal: maxPts)
                    personalityBar(axis: .playful, value: child.playfulPoints, maxVal: maxPts)
                    personalityBar(axis: .mystical, value: child.mysticalPoints, maxVal: maxPts)
                }

                if let arch {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("✦ 覺醒性格：\(arch.title)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.forestTeal)
                        Text(arch.summary)
                            .font(AppTheme.handwritten(12.5))
                            .foregroundStyle(AppTheme.softInk)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#F4EDE0"), in: RoundedRectangle(cornerRadius: 12))

                    // Grown child graduation / room toggle
                    HStack(spacing: 8) {
                        if let label = child.graduatedAnchorLabel {
                            Text("正守護「\(label)」")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.forestTeal)
                            Spacer()
                            WoodPlaqueButton(title: "接回陽光室", tone: .warmCream, fontSize: 11.5, horizontalPadding: 11, verticalPadding: 6) {
                                coordinator.toggleOffspringSunroomStay(id: child.id)
                            }
                        } else if let anchor = coordinator.visibleAnchors.first {
                            WoodPlaqueButton(title: "派往守護「\(anchor.customLabel)」", systemImage: "mappin.and.ellipse", tone: .warmCream, fontSize: 11.5, horizontalPadding: 11, verticalPadding: 6, fullWidth: true) {
                                coordinator.graduateOffspringToCorner(id: child.id, siteID: anchor.siteID)
                            }
                        }
                    }
                } else {
                    // 4 Interactive Raising Activities (each visibly shapes a different Personality Axis!)
                    Text("互動培育（不同陪伴方式會塑造獨特個性）")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.softInk)
                    HStack(spacing: 6) {
                        nurturePill(childID: child.id, axis: .brave, label: "看街景", icon: "binoculars.fill")
                        nurturePill(childID: child.id, axis: .gentle, label: "烘暖巢", icon: "heart.fill")
                        nurturePill(childID: child.id, axis: .playful, label: "逗著玩", icon: "wand.and.stars")
                        nurturePill(childID: child.id, axis: .mystical, label: "聽奇譚", icon: "sparkles")
                    }
                }
            }
        }
    }

    private func personalityBar(axis: PersonalityAxis, value: Int, maxVal: Int) -> some View {
        HStack(spacing: 8) {
            Text(axis.title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: axis.colorHex))
                .frame(width: 30, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: "#EFE7D8"))
                    Capsule()
                        .fill(Color(hex: axis.colorHex))
                        .frame(width: max(8, geo.size.width * CGFloat(value) / CGFloat(max(1, maxVal))))
                }
            }
            .frame(height: 7)
            Text("\(value)")
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.softInk)
                .frame(width: 22, alignment: .trailing)
        }
    }

    private func nurturePill(childID: UUID, axis: PersonalityAxis, label: String, icon: String) -> some View {
        Button {
            _ = coordinator.nurtureOffspring(id: childID, axis: axis, activityLabel: label)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color(hex: axis.colorHex))
                Text(label)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.deepPineInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#F8F2E7"))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: axis.colorHex).opacity(0.35), lineWidth: 0.9))
            )
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.93, pressOffsetY: 1))
    }
}
