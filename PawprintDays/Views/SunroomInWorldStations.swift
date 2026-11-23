import SwiftUI

// MARK: - 1. Physical In-World Tea & Biscuit Tray (Swirl Directly on the Sunroom Floor to Brew!)

struct InWorldTeaStationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let stageDate: Date
    let recipe: TeaRecipeSpec
    let onCycleRecipe: () -> Void
    let onBrewCompleted: (TeaRecipeSpec) -> Void

    @State private var brewProgress: CGFloat = 0.0
    @State private var lastPoint: CGPoint? = nil
    @State private var isSwirling: Bool = false
    @State private var steamBurst: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // Wooden cedar tea tray shadow & base
                Ellipse()
                    .fill(AppTheme.deepPineInk.opacity(0.20))
                    .frame(width: 82, height: 26)
                    .offset(y: 22)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#C59563"), Color(hex: "#8E6239")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 78, height: 24)
                    .overlay(Ellipse().stroke(Color(hex: "#6B4522").opacity(0.65), lineWidth: 1.2))
                    .offset(y: 19)

                // Rising animated steam wisps
                if isSwirling || steamBurst {
                    if SpriteFXLibrary.contains(.steam) {
                        let age = reduceMotion ? 0 : stageDate.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: SpriteFXKind.steam.duration)
                        Canvas { context, size in
                            SpriteFXLibrary.draw(.steam, age: age, in: CGRect(origin: .zero, size: size),
                                                 context: context)
                        }
                        .frame(width: 38, height: 38)
                        .offset(y: -24)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                    } else {
                        HStack(spacing: 5) {
                            ForEach(0..<3, id: \.self) { i in
                                Capsule()
                                    .fill(Color.white.opacity(steamBurst ? 0.85 : 0.60))
                                    .frame(width: 3, height: steamBurst ? 18 : 12)
                                    .offset(y: steamBurst ? -26 - CGFloat(i % 2) * 6 : -18)
                            }
                        }
                        .transition(.opacity)
                    }
                }

                // Live circular pour-over progress ring while swirling
                if brewProgress > 0.01 {
                    Circle()
                        .trim(from: 0, to: min(1.0, brewProgress))
                        .stroke(
                            Color(hex: recipe.tintHex),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                }

                // Hand-crafted ceramic teapot & cup illustration
                ZStack {
                    // Teapot handle & spout
                    Circle()
                        .stroke(Color(hex: "#EFE5D2"), lineWidth: 3.5)
                        .frame(width: 14, height: 14)
                        .offset(x: -18, y: 2)
                    Capsule()
                        .fill(Color(hex: "#EFE5D2"))
                        .frame(width: 16, height: 5)
                        .rotationEffect(.degrees(-28))
                        .offset(x: 17, y: -1)

                    // Ceramic body
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "#FFFDF8"), Color(hex: recipe.tintHex).opacity(0.42)],
                                center: .topLeading,
                                startRadius: 3,
                                endRadius: 24
                            )
                        )
                        .frame(width: 36, height: 32)
                        .overlay(Circle().stroke(Color(hex: "#6B5642").opacity(0.55), lineWidth: 1.2))
                        .offset(y: 3)

                    // Lid knob
                    Circle()
                        .fill(Color(hex: recipe.tintHex))
                        .frame(width: 10, height: 8)
                        .overlay(Circle().stroke(Color(hex: "#6B5642").opacity(0.55), lineWidth: 1))
                        .offset(y: -14)

                    // Tiny teacup beside teapot
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "#FFFDF6"))
                        .frame(width: 15, height: 11)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "#7A5B3E").opacity(0.6), lineWidth: 1))
                        .offset(x: 20, y: 12)
                }
                .rotationEffect(.degrees(isSwirling ? 14 : 0))
                .animation(AppTheme.Motion.resolved(.bouncy, reduceMotion: reduceMotion), value: isSwirling)
            }
            .frame(width: 84, height: 68)
            .contentShape(Circle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        isSwirling = true
                        if let prev = lastPoint {
                            let d = hypot(value.location.x - prev.x, value.location.y - prev.y)
                            brewProgress = min(1.0, brewProgress + d / 240.0)
                            if Int(brewProgress * 10) != Int((brewProgress - d / 240.0) * 10) {
                                HapticsEngine.shared.playBrushStrokeTick()
                            }
                        }
                        lastPoint = value.location
                        if brewProgress >= 1.0 {
                            triggerBrewComplete()
                        }
                    }
                    .onEnded { _ in
                        isSwirling = false
                        lastPoint = nil
                        if brewProgress > 0.15 && brewProgress < 1.0 {
                            withAnimation(.easeOut(duration: 0.25)) { brewProgress = 0 }
                        }
                    }
            )
            .onTapGesture {
                // Quick tap also gently nudges & cycles recipe or shows prompt
                HapticsEngine.shared.playBrushStrokeTick()
                CozySoundEngine.shared.playTeapotClink()
                onCycleRecipe()
            }

            // Compact diegetic recipe tag (tap to switch tea flavor!)
            Button(action: {
                HapticsEngine.shared.playBrushStrokeTick()
                CozySoundEngine.shared.playPaperFlip()
                onCycleRecipe()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: recipe.icon)
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(Color(hex: recipe.tintHex))
                    Text(isSwirling ? "畫圈手沖 \(Int(brewProgress * 100))%" : recipe.name)
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A3628"))
                        .lineLimit(1)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color(hex: "#FFFDF7").opacity(0.94), in: Capsule())
                .overlay(Capsule().stroke(Color(hex: recipe.tintHex).opacity(0.55), lineWidth: 1))
                .shadow(color: AppTheme.deepPineInk.opacity(0.14), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("手沖茶盤：畫圈泡茶，輕點切換\(recipe.name)")
        }
    }

    private func triggerBrewComplete() {
        brewProgress = 0
        lastPoint = nil
        isSwirling = false
        withAnimation(AppTheme.Motion.resolved(.bouncy, reduceMotion: reduceMotion)) {
            steamBurst = true
        }
        onBrewCompleted(recipe)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.4)) { steamBurst = false }
        }
    }
}

// MARK: - 2. Physical In-World Origami Bench + Direct Swipe-to-Fold Mat (Zero Modal Sheet!)

struct InWorldOrigamiTableView: View {
    let onTapTable: () -> Void

    var body: some View {
        Button(action: onTapTable) {
            VStack(spacing: 2) {
                ZStack {
                    // Soft shadow
                    Ellipse()
                        .fill(AppTheme.deepPineInk.opacity(0.18))
                        .frame(width: 58, height: 18)
                        .offset(y: 16)

                    // Low cedar craft stool
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [Color(hex: "#C89B6E"), Color(hex: "#9B6F46")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 54, height: 22)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#6F4B2A").opacity(0.6), lineWidth: 1.1))
                        .offset(y: 8)

                    // Colorful stacked washi origami squares on top
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#5B8E94"))
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(-12))
                        .offset(x: -7, y: -3)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#C85A32"))
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(8))
                        .offset(x: 6, y: -2)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#E6B44C"))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .rotationEffect(.degrees(-3))
                        .offset(y: -5)
                }
                .frame(width: 62, height: 42)

                Text("摺紙桌")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#4A3628"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#FFFDF7").opacity(0.92), in: Capsule())
                    .overlay(Capsule().stroke(Color(hex: "#D9A441").opacity(0.6), lineWidth: 0.9))
            }
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.92, pressOffsetY: 1))
        .accessibilityLabel("陽光室摺紙手作桌")
    }
}

/// Lightweight live in-room folding square floating over the Sunroom floor — swipe 3 times and watch it fly to the window beam!
struct InWorldOrigamiFoldOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onCraftComplete: (OrigamiCraftKind) -> Void
    let onClose: () -> Void

    @State private var selectedKind: OrigamiCraftKind = .crane
    @State private var foldStep: Int = 0 // 0 -> 1 -> 2 -> 3 (flying up!)
    @State private var isFlyingUp: Bool = false

    private var promptText: String {
        switch foldStep {
        case 0: return "向右滑動，對摺和紙 (1/3)"
        case 1: return "向上滑動，摺出角翼 (2/3)"
        case 2: return "再滑一下，吹氣放飛！(3/3)"
        default: return "飛上陽光室窗樑囉 ✦"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(OrigamiCraftKind.allCases) { kind in
                    Button {
                        HapticsEngine.shared.playBrushStrokeTick()
                        selectedKind = kind
                        foldStep = 0
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: kind.sfSymbol)
                                .font(.system(size: 10, weight: .bold))
                            Text(kind.title)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(selectedKind == kind ? .white : Color(hex: "#4A3628"))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(selectedKind == kind ? Color(hex: kind.colorHex) : Color(hex: "#F2EBDD"), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#9B8B7A"))
                }
                .buttonStyle(.plain)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "#FFFDF8").opacity(0.92))
                    .frame(width: 180, height: 148)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#D5C5AE"), lineWidth: 1.1))
                    .shadow(color: AppTheme.deepPineInk.opacity(0.16), radius: 12, y: 6)

                // Live 3D folding washi paper square
                ZStack {
                    RoundedRectangle(cornerRadius: foldStep == 0 ? 8 : (foldStep == 1 ? 18 : 28))
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: selectedKind.colorHex).opacity(0.92), Color(hex: selectedKind.colorHex).opacity(0.68)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: foldStep == 0 ? 88 : (foldStep == 1 ? 74 : 58),
                            height: foldStep == 0 ? 88 : (foldStep == 1 ? 74 : 58)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: foldStep == 0 ? 8 : (foldStep == 1 ? 18 : 28))
                                .stroke(Color.white.opacity(0.75), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                .padding(4)
                        )
                        .rotationEffect(.degrees(foldStep == 1 ? 45 : (foldStep == 2 ? -15 : 0)))
                        .rotation3DEffect(.degrees(Double(foldStep) * 180), axis: (x: 0.4, y: 1.0, z: 0))

                    Image(systemName: selectedKind.sfSymbol)
                        .font(.system(size: foldStep >= 2 ? 28 : 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(y: isFlyingUp ? -240 : 0)
                .scaleEffect(isFlyingUp ? 0.55 : 1.0)
                .opacity(isFlyingUp ? 0.0 : 1.0)
                .animation(AppTheme.Motion.resolved(.gentle, reduceMotion: reduceMotion), value: foldStep)
                .animation(.easeIn(duration: 0.55), value: isFlyingUp)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 18)
                    .onEnded { _ in
                        advanceFold()
                    }
            )
            .onTapGesture {
                advanceFold()
            }

            Text(promptText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#4A3628"))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(hex: "#FFFDF8").opacity(0.95), in: Capsule())
                .overlay(Capsule().stroke(Color(hex: "#D5C5AE"), lineWidth: 0.9))
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: "#D5C5AE").opacity(0.7), lineWidth: 1))
        .shadow(color: Color(hex: "#2B211A").opacity(0.18), radius: 16, y: 8)
    }

    private func advanceFold() {
        guard !isFlyingUp else { return }
        HapticsEngine.shared.playBrushStrokeTick()
        CozySoundEngine.shared.playPaperFlip()
        if foldStep < 2 {
            foldStep += 1
        } else {
            foldStep = 3
            withAnimation(.easeIn(duration: 0.52)) {
                isFlyingUp = true
            }
            let finished = selectedKind
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(480))
                onCraftComplete(finished)
                isFlyingUp = false
                foldStep = 0
                onClose()
            }
        }
    }
}

// MARK: - 3. Physical Porch Adventure Satchel (Direct In-Room Solo Errand Dispatch & Return!)

struct InWorldPorchSatchelView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let activeErrand: ActivePetErrand?
    let now: Date
    let coinBalance: Int
    let onSendSupply: (ErrandSupplyPack) -> Void
    let onCollectReturned: () -> Void

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            // Inline 3-pack floating snack bubbles right beside the doorway when tapped!
            if isExpanded && activeErrand == nil {
                VStack(spacing: 5) {
                    ForEach(ErrandSupplyPack.allCases) { pack in
                        let canAfford = coinBalance >= pack.costCoins
                        Button {
                            guard canAfford else { return }
                            withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
                                isExpanded = false
                            }
                            onSendSupply(pack)
                        } label: {
                            HStack(spacing: 5) {
                                Text(pack.title)
                                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                Text(pack.costCoins == 0 ? "免費" : "\(pack.costCoins)幣")
                                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(pack.costCoins == 0 ? AppTheme.forestTeal : Color(hex: "#C98D26"))
                            }
                            .foregroundStyle(Color(hex: "#2F2A26"))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#FFFDF8").opacity(0.96), in: Capsule())
                            .overlay(Capsule().stroke(Color(hex: "#D5C5AE"), lineWidth: 1))
                            .shadow(color: AppTheme.deepPineInk.opacity(0.16), radius: 4, y: 2)
                        }
                        .buttonStyle(TactileGameButtonStyle(pressScale: 0.93, pressOffsetY: 1))
                        .opacity(canAfford ? 1.0 : 0.45)
                    }
                }
                .transition(reduceMotion ? .opacity : .scale(scale: 0.85, anchor: .bottom).combined(with: .opacity))
            }

            // Main physical doorway prop
            if let errand = activeErrand {
                if errand.isReadyToReturn(at: now) {
                    Button(action: onCollectReturned) {
                        VStack(spacing: 2) {
                            Image(systemName: "envelope.open.fill")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color(hex: "#D98A36"), in: Circle())
                                .overlay(Circle().stroke(Color(hex: "#FFFDF8"), lineWidth: 2))
                                .shadow(color: Color(hex: "#D98A36").opacity(0.45), radius: 8, y: 3)
                            Text("收明信片 ✦")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#D98A36"), in: Capsule())
                        }
                    }
                    .buttonStyle(TactileGameButtonStyle(pressScale: 0.90, pressOffsetY: 1))
                } else {
                    let mins = max(1, Int(ceil(errand.remainingSeconds(at: now) / 60.0)))
                    VStack(spacing: 2) {
                        Image(systemName: "backpack.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.forestTeal)
                            .padding(8)
                            .background(Color(hex: "#FFFDF8").opacity(0.94), in: Circle())
                            .overlay(Circle().stroke(AppTheme.forestTeal.opacity(0.6), lineWidth: 1.2))
                        Text("探險 \(mins)分")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.forestTeal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#FFFDF8").opacity(0.92), in: Capsule())
                    }
                }
            } else {
                Button {
                    HapticsEngine.shared.playBrushStrokeTick()
                    CozySoundEngine.shared.playPaperFlip()
                    withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
                        isExpanded.toggle()
                    }
                } label: {
                    VStack(spacing: 2) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [Color(hex: "#D8A46C"), Color(hex: "#A87442")], startPoint: .top, endPoint: .bottom))
                                .frame(width: 34, height: 32)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#6B4522"), lineWidth: 1.2))
                            Image(systemName: "backpack.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(hex: "#FFFDF6"))
                        }
                        .shadow(color: AppTheme.deepPineInk.opacity(0.20), radius: 3, y: 2)

                        Text("玄關背包")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#4A3628"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#FFFDF7").opacity(0.92), in: Capsule())
                            .overlay(Capsule().stroke(AppTheme.timberWarm.opacity(0.5), lineWidth: 0.9))
                    }
                }
                .buttonStyle(TactileGameButtonStyle(pressScale: 0.92, pressOffsetY: 1))
                .accessibilityLabel("玄關小背包：派靈獸獨自出門探險")
            }
        }
    }
}

// MARK: - 4. Lightweight In-World Floating Radial Care Card for Tapped Egg / Baby (Zero Full-Screen Nursery Sheet!)

struct InWorldOffspringFloatingCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let offspring: MysticalOffspringRecord
    let anchors: [AnchorSiteRecord]
    let onNurture: (PersonalityAxis, String) -> Void
    let onRename: (String) -> Void
    let onGraduate: (String) -> Void
    let onDismiss: () -> Void

    @State private var isEditingName: Bool = false
    @State private var draftName: String = ""
    @State private var showGraduateCorners: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                if isEditingName {
                    TextField("替孩子取名", text: $draftName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#F2EBDD"), in: RoundedRectangle(cornerRadius: 8))
                    Button("好") {
                        onRename(draftName)
                        isEditingName = false
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.forestTeal, in: Capsule())
                } else {
                    Text("\(offspring.name) \(offspring.gender.symbol)")
                        .font(AppTheme.serifTitle(16))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Text(offspring.growthStage.title)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.forestTeal)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color(hex: "#E6F0EC"), in: Capsule())
                    Button {
                        draftName = offspring.name
                        isEditingName = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.softInk)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 4)

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(hex: "#9B8B7A"))
                }
                .buttonStyle(.plain)
            }

            // Compact 4-axis mini personality badges
            HStack(spacing: 6) {
                axisTinyBadge(.brave, value: offspring.bravePoints)
                axisTinyBadge(.gentle, value: offspring.gentlePoints)
                axisTinyBadge(.playful, value: offspring.playfulPoints)
                axisTinyBadge(.mystical, value: offspring.mysticalPoints)
            }

            Text(offspring.nextMilestoneHint)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.softInk)
                .frame(maxWidth: .infinity, alignment: .leading)

            if offspring.growthStage != .grown {
                HStack(spacing: 8) {
                    tactileCareButton(
                        title: offspring.growthStage == .egg ? "暖手貼貼" : "溫柔撫摸",
                        icon: "heart.fill",
                        hex: PersonalityAxis.gentle.colorHex
                    ) {
                        onNurture(.gentle, offspring.growthStage == .egg ? "用暖手烘暖靈卵" : "溫柔摸摸頭")
                    }
                    tactileCareButton(
                        title: offspring.growthStage == .egg ? "輕敲聽聲" : "羽毛逗玩",
                        icon: "sparkles",
                        hex: PersonalityAxis.playful.colorHex
                    ) {
                        onNurture(.playful, offspring.growthStage == .egg ? "輕輕敲蛋殼說哈囉" : "玩小羽毛逗玩")
                    }
                    tactileCareButton(
                        title: "唸奇譚故事",
                        icon: "book.fill",
                        hex: PersonalityAxis.mystical.colorHex
                    ) {
                        onNurture(.mystical, "在暖毯旁唸繪本故事")
                    }
                }
            } else {
                // Grown companion: show awakened archetype + option to graduate to a real corner!
                if let archID = offspring.awakenedArchetypeID,
                   let arch = OffspringCatalog.archetype(id: archID) {
                    Text("✦ 覺醒「\(arch.title)」· \(arch.summary)")
                        .font(AppTheme.serifBody(12))
                        .foregroundStyle(Color(hex: "#4A3628"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if showGraduateCorners {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(anchors.prefix(5), id: \.siteID) { anchor in
                                Button {
                                    onGraduate(anchor.siteID)
                                    onDismiss()
                                } label: {
                                    Text("守護「\(anchor.customLabel)」")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.forestTeal, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else if !anchors.isEmpty {
                    Button {
                        withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
                            showGraduateCorners = true
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "mappin.and.ellipse")
                            Text("送牠去守護熟悉街角")
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AppTheme.forestTeal, in: Capsule())
                    }
                    .buttonStyle(TactileGameButtonStyle(pressScale: 0.96, pressOffsetY: 1))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: "#FFFDF8").opacity(0.97))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color(hex: "#D5C5AE"), lineWidth: 1.1))
                .shadow(color: Color(hex: "#2B211A").opacity(0.20), radius: 14, y: 6)
        )
    }

    private func axisTinyBadge(_ axis: PersonalityAxis, value: Int) -> some View {
        HStack(spacing: 3) {
            Circle().fill(Color(hex: axis.colorHex)).frame(width: 6, height: 6)
            Text("\(axis.title)\(value)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#4A3628"))
        }
        .padding(.horizontal, 6.5)
        .padding(.vertical, 3)
        .background(Color(hex: "#F5EEE0"), in: Capsule())
    }

    private func tactileCareButton(title: String, icon: String, hex: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(hex: hex), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.93, pressOffsetY: 1.5))
    }
}

// MARK: - 5. Compact Inline Floating Sticky-Note Slip for Daily Wishes (Zero Modal Sheet!)

struct InWorldWishStickySlip: View {
    let board: DailyWishesBoard
    let onClaim: (DailyWishKind) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("今日小小願望")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#2F2A26"))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.softInk)
                }
                .buttonStyle(.plain)
            }

            ForEach(board.wishes) { wish in
                HStack(spacing: 8) {
                    Image(systemName: wish.isCompleted ? "checkmark.circle.fill" : wish.kind.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(wish.isCompleted ? AppTheme.forestTeal : Color(hex: "#C98D26"))
                        .frame(width: 20)

                    Text(wish.kind.title)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(wish.isClaimed ? AppTheme.softInk : Color(hex: "#2F2A26"))
                        .strikethrough(wish.isClaimed)
                        .lineLimit(2)

                    Spacer(minLength: 4)

                    if wish.isCompleted && !wish.isClaimed {
                        Button {
                            onClaim(wish.kind)
                        } label: {
                            Text("+\(wish.kind.rewardCoins)幣")
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#D98A36"), in: Capsule())
                        }
                        .buttonStyle(TactileGameButtonStyle(pressScale: 0.90, pressOffsetY: 1))
                    } else if wish.isClaimed {
                        Text("已領")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.forestTeal)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 266)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "#FFFDF8").opacity(0.96))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(hex: "#D5C5AE"), lineWidth: 1))
                .shadow(color: Color(hex: "#2B211A").opacity(0.16), radius: 14, y: 6)
        )
    }
}

// MARK: - 6. Live Inline Bottom Furniture Carousel for Decorate Mode (Zero Modal Sheet!)

struct InWorldFurnitureCarouselBar: View {
    @Bindable var coordinator: GameCoordinator
    @Binding var selectedSpotIndex: Int
    let onResetPositions: () -> Void
    let onDone: () -> Void

    private var ownedGoodies: [ShopItemSpec] {
        ShopCatalog.items.filter { $0.category == .goodies && coordinator.ledger.ownedGoodieIDs.contains($0.id) }
    }

    private var activeSpot: HomeSpotPlacement? {
        coordinator.homeSpots.first(where: { $0.spotIndex == selectedSpotIndex })
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("拖曳家具移動 · 點下方即時更換「\(activeSpot?.spotName ?? "位置")」")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#4A3628"))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Button("重設") {
                    onResetPositions()
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.softInk)

                Button("完成") {
                    onDone()
                }
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(AppTheme.forestTeal, in: Capsule())
            }
            .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ownedGoodies) { item in
                        let isEquipped = activeSpot?.equippedGoodieID == item.id
                        Button {
                            HapticsEngine.shared.playBrushStrokeTick()
                            CozySoundEngine.shared.playPawTap()
                            coordinator.placeGoodie(spotIndex: selectedSpotIndex, goodieID: item.id)
                        } label: {
                            VStack(spacing: 3) {
                                PaintedGoodiePropView(goodieID: item.id, hasLovedPatina: false, hasStitchedPatch: false, isWide: false)
                                    .scaleEffect(0.52)
                                    .frame(width: 52, height: 34)
                                Text(item.name)
                                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(isEquipped ? .white : Color(hex: "#3A312B"))
                                    .lineLimit(1)
                            }
                            .frame(width: 68)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isEquipped ? AppTheme.forestTeal : Color(hex: "#F6EFE1"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(isEquipped ? Color.clear : Color(hex: "#D5C5AE"), lineWidth: 0.9)
                                    )
                            )
                        }
                        .buttonStyle(TactileGameButtonStyle(pressScale: 0.93, pressOffsetY: 1))
                    }
                }
                .padding(.horizontal, 14)
            }
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: "#FFFDF8").opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color(hex: "#D5C5AE"), lineWidth: 1))
                .shadow(color: Color(hex: "#2B211A").opacity(0.16), radius: 14, y: -2)
        )
        .padding(.horizontal, 12)
    }
}

// MARK: - 7. Physical Floating Watercolor Postcard Toast on Errand Return

struct InWorldErrandPostcardToast: View {
    let postcard: CompletedErrandPostcard
    let petDisplayName: String
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onDismiss) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: "#D98A36"))
                    Text("\(petDisplayName)從「\(postcard.destinationLabel)」寄回明信片")
                        .font(AppTheme.serifTitle(15))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Spacer()
                    Text("+\(postcard.coinsEarned) 幣")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#C98D26"), in: Capsule())
                }

                Text(postcard.storyLine)
                    .font(AppTheme.serifBody(13))
                    .foregroundStyle(Color(hex: "#4A3628"))
                    .multilineTextAlignment(.leading)

                if let curioID = postcard.foundCurioID {
                    HStack(spacing: 6) {
                        PaintedCurioStampView(curioID: curioID, size: 22)
                        Text("帶回街區拾遺「\(CurioCatalog.curio(id: curioID).name)」✦")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.forestTeal)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(hex: "#FFFDF8"))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color(hex: "#D9A441"), lineWidth: 1.3))
                    .shadow(color: Color(hex: "#2B211A").opacity(0.22), radius: 16, y: 8)
            )
        }
        .buttonStyle(.plain)
    }
}
