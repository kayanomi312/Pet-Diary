import SwiftUI

// MARK: - 1. Physical In-World Tea & Biscuit Tray (Swirl Directly on the Sunroom Floor to Brew!)

struct InWorldTeaStationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let stageDate: Date
    let recipe: TeaRecipeSpec
    var isPhotoMode: Bool = false
    let onCycleRecipe: () -> Void
    let onBrewCompleted: (TeaRecipeSpec) -> Void

    @State private var brewProgress: CGFloat = 0.0
    @State private var lastPoint: CGPoint? = nil
    @State private var isSwirling: Bool = false
    @State private var steamBurst: Bool = false
    @State private var showRecipeHint: Bool = false
    @State private var hideHintTask: Task<Void, Never>? = nil

    private var shouldShowPill: Bool {
        !isPhotoMode && (isSwirling || brewProgress > 0.01 || showRecipeHint)
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // Low cedar chabudai tea tray + plump kyusu teapot, teacup & paw-biscuit plate
                Canvas { ctx, size in
                    let w = size.width
                    let h = size.height
                    let ink = Color(hex: "#583E2A").opacity(0.68)

                    // Soft floor contact shadow
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: w * 0.06, y: h * 0.70, width: w * 0.88, height: h * 0.28)),
                        with: .color(AppTheme.deepPineInk.opacity(0.18))
                    )

                    // Cute stubby chabudai wooden legs
                    for lx in [w * 0.20, w * 0.74] {
                        let leg = Path(roundedRect: CGRect(x: lx, y: h * 0.68, width: 6, height: 11), cornerRadius: 2.5)
                        ctx.fill(leg, with: .color(Color(hex: "#7D522D")))
                        ctx.stroke(leg, with: .color(ink), lineWidth: 0.9)
                    }

                    // Low cedar chabudai tabletop rim & warm surface
                    let trayOuter = Path(ellipseIn: CGRect(x: w * 0.06, y: h * 0.50, width: w * 0.88, height: h * 0.34))
                    ctx.fill(
                        trayOuter,
                        with: .linearGradient(
                            Gradient(colors: [Color(hex: "#D3A472"), Color(hex: "#9E6D41")]),
                            startPoint: CGPoint(x: w * 0.5, y: h * 0.48),
                            endPoint: CGPoint(x: w * 0.5, y: h * 0.86)
                        )
                    )
                    ctx.stroke(trayOuter, with: .color(ink), lineWidth: 1.15)

                    let trayInner = Path(ellipseIn: CGRect(x: w * 0.12, y: h * 0.54, width: w * 0.76, height: h * 0.25))
                    ctx.fill(trayInner, with: .color(Color(hex: "#E2BA8B").opacity(0.75)))
                    ctx.stroke(trayInner, with: .color(Color(hex: "#8F6038").opacity(0.35)), lineWidth: 0.8)

                    // Tiny paw-biscuit ceramic plate (front-left on chabudai)
                    let plateRect = CGRect(x: w * 0.14, y: h * 0.59, width: w * 0.25, height: h * 0.16)
                    ctx.fill(Path(ellipseIn: plateRect), with: .color(Color(hex: "#FFFDF6")))
                    ctx.stroke(Path(ellipseIn: plateRect), with: .color(ink.opacity(0.6)), lineWidth: 0.9)
                    // Miniature honey paw-shaped biscuit
                    let biscuitMain = Path(ellipseIn: CGRect(x: w * 0.21, y: h * 0.635, width: w * 0.10, height: h * 0.075))
                    ctx.fill(biscuitMain, with: .color(Color(hex: "#E8B064")))
                    for (bx, by) in [(0.195, 0.61), (0.245, 0.60), (0.295, 0.615)] {
                        ctx.fill(Path(ellipseIn: CGRect(x: w * bx, y: h * by, width: 3.4, height: 3.2)), with: .color(Color(hex: "#E8B064")))
                    }

                    // Petite stoneware teacup with warm tea inside (front-right on chabudai)
                    let cupRect = CGRect(x: w * 0.66, y: h * 0.53, width: w * 0.19, height: h * 0.18)
                    let cup = Path(roundedRect: cupRect, cornerRadius: 5.5)
                    ctx.fill(
                        cup,
                        with: .linearGradient(
                            Gradient(colors: [Color(hex: "#FFFDF8"), Color(hex: "#EAE0CE")]),
                            startPoint: CGPoint(x: cupRect.minX, y: cupRect.minY),
                            endPoint: CGPoint(x: cupRect.maxX, y: cupRect.maxY)
                        )
                    )
                    ctx.stroke(cup, with: .color(ink.opacity(0.7)), lineWidth: 1.0)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: cupRect.minX + 2.5, y: cupRect.minY + 1.5, width: cupRect.width - 5, height: 4.5)),
                        with: .color(Color(hex: recipe.tintHex).opacity(0.75))
                    )
                }
                .frame(width: 90, height: 74)

                // Rising animated steam wisps
                if isSwirling || steamBurst {
                    if SpriteFXLibrary.contains(.steam) {
                        let age = reduceMotion ? 0 : stageDate.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: SpriteFXKind.steam.duration)
                        Canvas { context, size in
                            SpriteFXLibrary.draw(.steam, age: age, in: CGRect(origin: .zero, size: size),
                                                 context: context)
                        }
                        .frame(width: 40, height: 40)
                        .offset(y: -26)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                    } else {
                        HStack(spacing: 5) {
                            ForEach(0..<3, id: \.self) { i in
                                Capsule()
                                    .fill(Color.white.opacity(steamBurst ? 0.85 : 0.60))
                                    .frame(width: 3, height: steamBurst ? 18 : 12)
                                    .offset(y: steamBurst ? -28 - CGFloat(i % 2) * 6 : -20)
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
                        .frame(width: 68, height: 68)
                        .rotationEffect(.degrees(-90))
                }

                // Plump ceramic kyusu teapot (tilts warmly when swirling)
                ZStack {
                    // Classic wooden side kyusu handle (left)
                    Capsule()
                        .fill(LinearGradient(colors: [Color(hex: "#C5905A"), Color(hex: "#8F5D33")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 18, height: 6)
                        .overlay(Capsule().stroke(Color(hex: "#5C3D22").opacity(0.65), lineWidth: 0.9))
                        .rotationEffect(.degrees(16))
                        .offset(x: -20, y: 1)

                    // Delicate curved spout (right)
                    Capsule()
                        .fill(Color(hex: "#F4EBDC"))
                        .frame(width: 16, height: 6)
                        .overlay(Capsule().stroke(Color(hex: "#6B523E").opacity(0.55), lineWidth: 0.9))
                        .rotationEffect(.degrees(-32))
                        .offset(x: 18, y: -3)

                    // Plump glazed ceramic kyusu body
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "#FFFDF8"), Color(hex: recipe.tintHex).opacity(0.50)],
                                center: .topLeading,
                                startRadius: 3,
                                endRadius: 24
                            )
                        )
                        .frame(width: 36, height: 29)
                        .overlay(
                            Ellipse()
                                .fill(Color.white.opacity(0.42))
                                .frame(width: 11, height: 6)
                                .offset(x: -7, y: -6)
                        )
                        .overlay(Ellipse().stroke(Color(hex: "#6B523E").opacity(0.60), lineWidth: 1.15))
                        .offset(y: 1)

                    // Snug ceramic lid + round finial knob
                    Ellipse()
                        .fill(Color(hex: "#FAF4E8"))
                        .frame(width: 22, height: 7)
                        .overlay(Ellipse().stroke(Color(hex: "#6B523E").opacity(0.52), lineWidth: 0.9))
                        .offset(y: -11)

                    Circle()
                        .fill(Color(hex: recipe.tintHex))
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color(hex: "#6B523E").opacity(0.6), lineWidth: 0.9))
                        .offset(y: -15)
                }
                .offset(x: -1, y: -3)
                .rotationEffect(.degrees(isSwirling ? 14 : 0))
                .animation(AppTheme.Motion.resolved(.bouncy, reduceMotion: reduceMotion), value: isSwirling)
            }
            .frame(width: 90, height: 74)
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
                HapticsEngine.shared.playBrushStrokeTick()
                CozySoundEngine.shared.playTeapotClink()
                onCycleRecipe()
                flashRecipeHint()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("手沖茶盤：畫圈泡茶，輕點切換\(recipe.name)")
            .accessibilityAddTraits(.isButton)

            if shouldShowPill {
                Button(action: {
                    HapticsEngine.shared.playBrushStrokeTick()
                    CozySoundEngine.shared.playPaperFlip()
                    onCycleRecipe()
                    flashRecipeHint()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: recipe.icon)
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(Color(hex: recipe.tintHex))
                        Text(isSwirling || brewProgress > 0.01 ? "畫圈手沖 \(Int(brewProgress * 100))%" : recipe.name)
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#4A3628"))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color(hex: "#FFFDF7").opacity(0.96), in: Capsule())
                    .overlay(Capsule().stroke(Color(hex: recipe.tintHex).opacity(0.55), lineWidth: 1))
                    .shadow(color: AppTheme.deepPineInk.opacity(0.14), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.90)))
                .accessibilityLabel("目前茶品：\(recipe.name)，輕點切換口味")
            }
        }
        .animation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion), value: shouldShowPill)
    }

    private func flashRecipeHint() {
        hideHintTask?.cancel()
        withAnimation(AppTheme.Motion.resolved(.snappy, reduceMotion: reduceMotion)) {
            showRecipeHint = true
        }
        hideHintTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                showRecipeHint = false
            }
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
    var isPhotoMode: Bool = false
    let onTapTable: () -> Void

    var body: some View {
        Button(action: onTapTable) {
            Canvas { ctx, size in
                let w = size.width
                let h = size.height
                let ink = Color(hex: "#583E2A").opacity(0.66)

                // Soft contact shadow
                ctx.fill(
                    Path(ellipseIn: CGRect(x: w * 0.06, y: h * 0.72, width: w * 0.88, height: h * 0.24)),
                    with: .color(AppTheme.deepPineInk.opacity(0.18))
                )

                // Miniature cedar craft table legs
                for lx in [w * 0.16, w * 0.76] {
                    let leg = Path(roundedRect: CGRect(x: lx, y: h * 0.66, width: 5.5, height: 11), cornerRadius: 2)
                    ctx.fill(leg, with: .color(Color(hex: "#865933")))
                    ctx.stroke(leg, with: .color(ink), lineWidth: 0.9)
                }

                // Warm cedar craft tabletop
                let topRect = CGRect(x: w * 0.07, y: h * 0.48, width: w * 0.86, height: h * 0.28)
                let tabletop = Path(roundedRect: topRect, cornerRadius: 7)
                ctx.fill(
                    tabletop,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "#D5A776"), Color(hex: "#A57548")]),
                        startPoint: CGPoint(x: w * 0.5, y: topRect.minY),
                        endPoint: CGPoint(x: w * 0.5, y: topRect.maxY)
                    )
                )
                ctx.stroke(tabletop, with: .color(ink), lineWidth: 1.1)

                // Patterned washi paper stack (fanned sage, persimmon, butter-gold)
                // 1) Sage teal sheet with tiny cream dots
                ctx.drawLayer { layer in
                    layer.translateBy(x: w * 0.31, y: h * 0.44)
                    layer.rotate(by: .degrees(-13))
                    let sheet = Path(roundedRect: CGRect(x: -11, y: -9, width: 22, height: 18), cornerRadius: 2.5)
                    layer.fill(sheet, with: .color(Color(hex: "#5C9196")))
                    layer.stroke(sheet, with: .color(ink.opacity(0.6)), lineWidth: 0.8)
                    for (dx, dy) in [(-5.0, -3.0), (2.0, -4.0), (-2.0, 3.0), (5.0, 2.0)] {
                        layer.fill(Path(ellipseIn: CGRect(x: dx, y: dy, width: 2.4, height: 2.4)), with: .color(Color(hex: "#FFF9EC").opacity(0.75)))
                    }
                }
                // 2) Terracotta sheet with warm stripe accent
                ctx.drawLayer { layer in
                    layer.translateBy(x: w * 0.42, y: h * 0.42)
                    layer.rotate(by: .degrees(9))
                    let sheet = Path(roundedRect: CGRect(x: -11, y: -9, width: 22, height: 18), cornerRadius: 2.5)
                    layer.fill(sheet, with: .color(Color(hex: "#D16D4A")))
                    layer.stroke(sheet, with: .color(ink.opacity(0.6)), lineWidth: 0.8)
                    var stripe = Path()
                    stripe.move(to: CGPoint(x: -9, y: -2))
                    stripe.addLine(to: CGPoint(x: 9, y: -2))
                    stripe.move(to: CGPoint(x: -9, y: 3))
                    stripe.addLine(to: CGPoint(x: 9, y: 3))
                    layer.stroke(stripe, with: .color(Color(hex: "#FCE7C8").opacity(0.65)), lineWidth: 1.0)
                }
                // 3) Butter-gold top sheet with delicate blossom dot
                ctx.drawLayer { layer in
                    layer.translateBy(x: w * 0.36, y: h * 0.38)
                    layer.rotate(by: .degrees(-3))
                    let sheet = Path(roundedRect: CGRect(x: -11, y: -9, width: 22, height: 18), cornerRadius: 2.5)
                    layer.fill(sheet, with: .color(Color(hex: "#F1C463")))
                    layer.stroke(sheet, with: .color(ink.opacity(0.65)), lineWidth: 0.85)
                    layer.fill(Path(ellipseIn: CGRect(x: -2.5, y: -2.5, width: 5, height: 5)), with: .color(Color(hex: "#FFFDF6").opacity(0.85)))
                }

                // Tiny folded origami paper crane silhouette perched on right side of table
                var crane = Path()
                let cx = w * 0.72
                let cy = h * 0.41
                // Left wing, neck/head, right wing, tail
                crane.move(to: CGPoint(x: cx - 10, y: cy - 3))
                crane.addLine(to: CGPoint(x: cx - 2, y: cy + 5))
                crane.addLine(to: CGPoint(x: cx + 5, y: cy + 5))
                crane.addLine(to: CGPoint(x: cx + 11, y: cy - 7)) // raised tail
                crane.addLine(to: CGPoint(x: cx + 4, y: cy - 1))
                crane.addLine(to: CGPoint(x: cx + 1, y: cy - 12)) // outstretched top wing
                crane.addLine(to: CGPoint(x: cx - 3, y: cy - 1))
                crane.addLine(to: CGPoint(x: cx - 7, y: cy - 10)) // neck
                crane.addLine(to: CGPoint(x: cx - 11, y: cy - 8)) // tiny beak
                crane.addLine(to: CGPoint(x: cx - 6, y: cy - 3))
                crane.closeSubpath()
                ctx.fill(crane, with: .color(Color(hex: "#FFF8EC")))
                ctx.stroke(crane, with: .color(Color(hex: "#C85A32").opacity(0.75)), style: StrokeStyle(lineWidth: 0.95, lineJoin: .round))
            }
            .frame(width: 68, height: 50)
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
            HStack(spacing: 6) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
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
                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                                .foregroundStyle(selectedKind == kind ? .white : Color(hex: "#4A3628"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(selectedKind == kind ? Color(hex: kind.colorHex) : Color(hex: "#F2EBDD"), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#9B8B7A"))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("關閉摺紙桌")
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
    var isPhotoMode: Bool = false
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
                    // Charming woven canvas & rattan adventure satchel with brass buckle & leather strap
                    Canvas { ctx, size in
                        let w = size.width
                        let h = size.height
                        let ink = Color(hex: "#583B24").opacity(0.72)

                        // Soft shadow on porch floor
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: w * 0.14, y: h * 0.78, width: w * 0.72, height: h * 0.20)),
                            with: .color(AppTheme.deepPineInk.opacity(0.20))
                        )

                        // Curved leather shoulder strap looping behind top
                        var strap = Path()
                        strap.move(to: CGPoint(x: w * 0.28, y: h * 0.30))
                        strap.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.30), control: CGPoint(x: w * 0.50, y: h * 0.04))
                        ctx.stroke(strap, with: .color(Color(hex: "#8F5A31")), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
                        ctx.stroke(strap, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))

                        // Woven canvas/rattan body
                        let bodyRect = CGRect(x: w * 0.14, y: h * 0.28, width: w * 0.72, height: h * 0.56)
                        let bodyPath = Path(roundedRect: bodyRect, cornerRadius: 11)
                        ctx.fill(
                            bodyPath,
                            with: .linearGradient(
                                Gradient(colors: [Color(hex: "#EAD8B6"), Color(hex: "#C9A572")]),
                                startPoint: CGPoint(x: bodyRect.midX, y: bodyRect.minY),
                                endPoint: CGPoint(x: bodyRect.midX, y: bodyRect.maxY)
                            )
                        )
                        // Subtle rattan cross-weave lines
                        for i in 0..<4 {
                            let y = bodyRect.minY + bodyRect.height * (0.36 + CGFloat(i) * 0.16)
                            var weave = Path()
                            weave.move(to: CGPoint(x: bodyRect.minX + 3, y: y))
                            weave.addLine(to: CGPoint(x: bodyRect.maxX - 3, y: y))
                            ctx.stroke(weave, with: .color(Color(hex: "#9E7548").opacity(0.26)), style: StrokeStyle(lineWidth: 1.0, dash: [3, 2]))
                        }
                        ctx.stroke(bodyPath, with: .color(ink), lineWidth: 1.2)

                        // Warm saddle-leather top flap
                        var flap = Path()
                        flap.move(to: CGPoint(x: bodyRect.minX + 1, y: bodyRect.minY + 9))
                        flap.addQuadCurve(to: CGPoint(x: bodyRect.midX, y: bodyRect.minY), control: CGPoint(x: bodyRect.minX + 6, y: bodyRect.minY))
                        flap.addQuadCurve(to: CGPoint(x: bodyRect.maxX - 1, y: bodyRect.minY + 9), control: CGPoint(x: bodyRect.maxX - 6, y: bodyRect.minY))
                        flap.addLine(to: CGPoint(x: bodyRect.maxX - 2, y: bodyRect.minY + bodyRect.height * 0.44))
                        flap.addQuadCurve(
                            to: CGPoint(x: bodyRect.minX + 2, y: bodyRect.minY + bodyRect.height * 0.44),
                            control: CGPoint(x: bodyRect.midX, y: bodyRect.minY + bodyRect.height * 0.56)
                        )
                        flap.closeSubpath()
                        ctx.fill(
                            flap,
                            with: .linearGradient(
                                Gradient(colors: [Color(hex: "#B87C48"), Color(hex: "#8F592E")]),
                                startPoint: CGPoint(x: bodyRect.midX, y: bodyRect.minY),
                                endPoint: CGPoint(x: bodyRect.midX, y: bodyRect.minY + bodyRect.height * 0.55)
                            )
                        )
                        ctx.stroke(flap, with: .color(ink), lineWidth: 1.1)

                        // Center vertical leather buckle strap + gleaming brass buckle
                        let strapRect = CGRect(x: w * 0.45, y: bodyRect.minY + bodyRect.height * 0.28, width: w * 0.10, height: bodyRect.height * 0.42)
                        ctx.fill(Path(roundedRect: strapRect, cornerRadius: 2), with: .color(Color(hex: "#7A4923")))
                        let buckleRect = CGRect(x: w * 0.415, y: bodyRect.minY + bodyRect.height * 0.41, width: w * 0.17, height: h * 0.14)
                        let buckle = Path(roundedRect: buckleRect, cornerRadius: 2.5)
                        ctx.fill(buckle, with: .color(Color(hex: "#F2CE6E")))
                        ctx.stroke(buckle, with: .color(Color(hex: "#8A6320")), lineWidth: 1.0)
                        ctx.fill(Path(roundedRect: buckleRect.insetBy(dx: 2.5, dy: 2.2), cornerRadius: 1), with: .color(Color(hex: "#7A4923")))

                        // Cute tiny green leaf charm tucked by the side
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: bodyRect.maxX - 6, y: bodyRect.minY + 12, width: 7, height: 10)),
                            with: .color(Color(hex: "#6B9B72"))
                        )
                    }
                    .frame(width: 48, height: 48)
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

    private var completedCount: Int {
        board.wishes.filter { $0.isCompleted }.count
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .center, spacing: 6) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("今日小小願望")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#2F2A26"))

                        // Visual 3-stamp progress strip (done/3)
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { idx in
                                let stamped = idx < completedCount
                                ZStack {
                                    Circle()
                                        .fill(stamped ? Color(hex: "#C85A32").opacity(0.18) : Color(hex: "#F2E9D8"))
                                        .frame(width: 17, height: 17)
                                    Circle()
                                        .stroke(
                                            stamped ? Color(hex: "#C85A32") : Color(hex: "#CBB89D"),
                                            style: StrokeStyle(lineWidth: 1.0, dash: stamped ? [] : [2.5, 2])
                                        )
                                        .frame(width: 17, height: 17)
                                    if stamped {
                                        Image(systemName: "pawprint.fill")
                                            .font(.system(size: 8.5, weight: .bold))
                                            .foregroundStyle(Color(hex: "#C85A32"))
                                    }
                                }
                            }
                            Text("\(completedCount)/3")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#7A5D45"))
                                .padding(.leading, 2)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("今日願望進度 \(completedCount) / 3")
                    }

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(AppTheme.softInk)
                            .padding(6)
                            .background(Color(hex: "#F3EBDC"), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("關閉今日小小願望")
                }

                Rectangle()
                    .fill(Color(hex: "#E6D9C3"))
                    .frame(height: 1)

                ForEach(board.wishes) { wish in
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(wish.isCompleted ? AppTheme.forestTeal.opacity(0.14) : Color(hex: "#F6ECD9"))
                                .frame(width: 24, height: 24)
                            Image(systemName: wish.isCompleted ? "checkmark.seal.fill" : wish.kind.systemImage)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(wish.isCompleted ? AppTheme.forestTeal : Color(hex: "#C98D26"))
                        }

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
                                HStack(spacing: 2) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 8.5, weight: .bold))
                                    Text("+\(wish.kind.rewardCoins)幣")
                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#E49B3E"), Color(hex: "#C87826")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    in: Capsule()
                                )
                                .shadow(color: Color(hex: "#D98A36").opacity(0.32), radius: 3, y: 1.5)
                            }
                            .buttonStyle(TactileGameButtonStyle(pressScale: 0.90, pressOffsetY: 1))
                        } else if wish.isClaimed {
                            Text("已領 ✓")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.forestTeal)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color(hex: "#E6F0EC"), in: Capsule())
                        } else {
                            Text("+\(wish.kind.rewardCoins)幣")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#A87430"))
                                .padding(.horizontal, 6.5)
                                .padding(.vertical, 2.5)
                                .background(Color(hex: "#FBF1DC"), in: Capsule())
                                .overlay(Capsule().stroke(Color(hex: "#E6CC9B"), lineWidth: 0.8))
                        }
                    }
                }
            }
            .padding(.horizontal, 13)
            .padding(.top, 16)
            .padding(.bottom, 13)
            .frame(width: 274)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#FFFDF6"))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#DECBA9"), lineWidth: 1.1))
                    .shadow(color: Color(hex: "#2B211A").opacity(0.16), radius: 14, y: 6)
            )
            .padding(.top, 8)

            // Cute patterned sage-washi tape strip holding the memo slip
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    Circle()
                        .fill(Color(hex: "#FFFDF6").opacity(0.55))
                        .frame(width: 3.5, height: 3.5)
                }
            }
            .frame(width: 68, height: 15)
            .background(Color(hex: "#9BBBA6").opacity(0.86), in: RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#789B84").opacity(0.35), lineWidth: 0.7))
            .rotationEffect(.degrees(-2.2))
            .shadow(color: Color(hex: "#2B211A").opacity(0.10), radius: 2, y: 1)
            .allowsHitTesting(false)
        }
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

    private var ownedRoomThemes: [SeasonalRoomTheme] {
        SeasonalRoomTheme.allCases.filter { coordinator.ledger.ownedRoomThemeIDs.contains($0.rawValue) }
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
                    .minimumScaleFactor(0.85)
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

            // Warm heart-patch mending CTA when the selected spot has loved patina and is not yet patched
            if activeSpot?.hasLovedPatina == true && activeSpot?.hasStitchedPatch == false {
                Button {
                    HapticsEngine.shared.playBrushStrokeTick()
                    CozySoundEngine.shared.playCompassChime()
                    _ = coordinator.mendGoodiePatch(spotIndex: selectedSpotIndex)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("縫上暖心補丁 · 10幣")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#DF8454"), Color(hex: "#C26036")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "#FFF7EC").opacity(0.65), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .padding(2)
                    )
                    .shadow(color: Color(hex: "#C26036").opacity(0.24), radius: 4, y: 2)
                }
                .buttonStyle(TactileGameButtonStyle(pressScale: 0.96, pressOffsetY: 1))
                .opacity(coordinator.ledger.coinBalance >= ShopCatalog.patchMendPriceCoins ? 1.0 : 0.65)
                .padding(.horizontal, 14)
            }

            // Compact Room Theme Switcher strip
            if !ownedRoomThemes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text("季節光景")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#7A6252"))
                            .padding(.trailing, 2)

                        ForEach(ownedRoomThemes, id: \.rawValue) { theme in
                            let isActive = coordinator.ledger.activeRoomTheme == theme
                            Button {
                                HapticsEngine.shared.playBrushStrokeTick()
                                CozySoundEngine.shared.playPaperFlip()
                                coordinator.selectRoomTheme(theme)
                            } label: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: theme.wallHex), Color(hex: theme.floorTopHex)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 11, height: 11)
                                        .overlay(Circle().stroke(Color(hex: "#6B523E").opacity(0.45), lineWidth: 0.7))

                                    Text(theme.title)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .lineLimit(1)

                                    if isActive {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 10.5, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .foregroundStyle(isActive ? .white : Color(hex: "#4A3628"))
                                .padding(.horizontal, 8.5)
                                .padding(.vertical, 4.5)
                                .background(
                                    Capsule()
                                        .fill(isActive ? AppTheme.forestTeal : Color(hex: "#F5EEE0"))
                                        .overlay(
                                            Capsule()
                                                .stroke(isActive ? Color.clear : Color(hex: "#D5C5AE"), lineWidth: 0.85)
                                        )
                                )
                            }
                            .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1))
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }

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
                .fill(Color(hex: "#FFFDF8"))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color(hex: "#D5C5AE"), lineWidth: 1.1))
                .shadow(color: Color(hex: "#2B211A").opacity(0.18), radius: 14, y: -2)
        )
        .compositingGroup()
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
