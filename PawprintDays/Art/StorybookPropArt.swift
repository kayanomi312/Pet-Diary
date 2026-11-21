import SwiftUI

// MARK: - 1. Hand-Crafted Painterly Home Furnishings (5 Goodies + 2-State Loved Patina)
struct PaintedGoodiePropView: View {
    let goodieID: String?
    let hasLovedPatina: Bool
    let hasStitchedPatch: Bool
    let isWide: Bool

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let ink = Color(hex: "#2C3536").opacity(0.76)

            // Ground shadow
            ctx.fill(
                Path(ellipseIn: CGRect(x: w * 0.06, y: h * 0.72, width: w * 0.88, height: h * 0.24)),
                with: .color(AppTheme.deepPineInk.opacity(0.16))
            )

            switch goodieID {
            case "goodie.wool_blanket":
                drawWoolBlanket(in: &ctx, size: size, ink: ink)
            case "goodie.bakery_box":
                drawBakeryBox(in: &ctx, size: size, ink: ink)
            case "goodie.cloth_ball":
                drawClothBall(in: &ctx, size: size, ink: ink)
            case "goodie.window_cushion":
                drawWindowCushion(in: &ctx, size: size, ink: ink)
            case "goodie.folded_towel":
                drawFoldedTowel(in: &ctx, size: size, ink: ink)
            default:
                drawEmptyCedarMat(in: &ctx, size: size, ink: ink)
            }

            // 2-State Loved Patina (25+ uses): cozy recessed paw dent or colorful stitched quilt patch
            if hasLovedPatina && goodieID != nil {
                if hasStitchedPatch {
                    let patchRect = CGRect(x: w * 0.62, y: h * 0.28, width: w * 0.20, height: h * 0.34)
                    let patchPath = Path(roundedRect: patchRect, cornerRadius: 4)
                    ctx.fill(patchPath, with: .color(AppTheme.pawInRange))
                    ctx.stroke(patchPath, with: .color(AppTheme.warmPaper), style: StrokeStyle(lineWidth: 1.3, dash: [3, 2.5]))
                    ctx.stroke(patchPath, with: .color(ink), lineWidth: 1.0)
                } else {
                    // Cozy worn paw-dent indentation + frayed thread hint
                    let dent = CGRect(x: w * 0.36, y: h * 0.34, width: w * 0.28, height: h * 0.26)
                    ctx.fill(Path(ellipseIn: dent), with: .color(AppTheme.timberDeep.opacity(0.16)))
                    var fray = Path()
                    fray.move(to: CGPoint(x: w * 0.78, y: h * 0.66))
                    fray.addLine(to: CGPoint(x: w * 0.86, y: h * 0.72))
                    fray.move(to: CGPoint(x: w * 0.74, y: h * 0.69))
                    fray.addLine(to: CGPoint(x: w * 0.82, y: h * 0.76))
                    ctx.stroke(fray, with: .color(AppTheme.timberDeep.opacity(0.55)), lineWidth: 1.2)
                }
            }
        }
        .frame(width: isWide ? 156 : 122, height: 52)
    }

    private func drawWoolBlanket(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        let baseRect = CGRect(x: w * 0.08, y: h * 0.20, width: w * 0.84, height: h * 0.56)
        let path = Path(roundedRect: baseRect, cornerRadius: 14)
        ctx.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#618099"), Color(hex: "#466278")]),
                startPoint: CGPoint(x: 0, y: baseRect.minY),
                endPoint: CGPoint(x: 0, y: baseRect.maxY)
            )
        )
        // Woven tartan stripe crosslines
        for i in 1...3 {
            let x = baseRect.minX + baseRect.width * CGFloat(i) / 4.0
            var vLine = Path()
            vLine.move(to: CGPoint(x: x, y: baseRect.minY + 3))
            vLine.addLine(to: CGPoint(x: x, y: baseRect.maxY - 3))
            ctx.stroke(vLine, with: .color(Color(hex: "#D6C5A9").opacity(0.42)), lineWidth: 2)
        }
        var hLine = Path()
        hLine.move(to: CGPoint(x: baseRect.minX + 6, y: baseRect.midY))
        hLine.addLine(to: CGPoint(x: baseRect.maxX - 6, y: baseRect.midY))
        ctx.stroke(hLine, with: .color(Color(hex: "#D6C5A9").opacity(0.45)), lineWidth: 2)
        // Braided fringe tassels on edges
        for side in [baseRect.minX - 6, baseRect.maxX] {
            for row in 0..<4 {
                let y = baseRect.minY + 7 + CGFloat(row) * 6.5
                var t = Path()
                t.move(to: CGPoint(x: side, y: y))
                t.addLine(to: CGPoint(x: side + 6, y: y))
                ctx.stroke(t, with: .color(Color(hex: "#D6C5A9")), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
            }
        }
        ctx.stroke(path, with: .color(ink), lineWidth: 1.4)
    }

    private func drawFoldedTowel(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        let lower = CGRect(x: w * 0.12, y: h * 0.34, width: w * 0.76, height: h * 0.42)
        let upper = CGRect(x: w * 0.16, y: h * 0.16, width: w * 0.68, height: h * 0.36)
        ctx.fill(Path(roundedRect: lower, cornerRadius: 8), with: .color(Color(hex: "#D8CEBC")))
        ctx.stroke(Path(roundedRect: lower, cornerRadius: 8), with: .color(ink), lineWidth: 1.2)
        ctx.fill(Path(roundedRect: upper, cornerRadius: 8), with: .color(Color(hex: "#EDE5D6")))
        // Woven sage linen accent stripe
        let stripe = CGRect(x: upper.minX + 6, y: upper.midY - 3, width: upper.width - 12, height: 6)
        ctx.fill(Path(stripe), with: .color(Color(hex: "#7E988E").opacity(0.75)))
        ctx.stroke(Path(roundedRect: upper, cornerRadius: 8), with: .color(ink), lineWidth: 1.3)
    }

    private func drawBakeryBox(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        let box = CGRect(x: w * 0.14, y: h * 0.24, width: w * 0.72, height: h * 0.54)
        ctx.fill(
            Path(roundedRect: box, cornerRadius: 4),
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#D4AB7A"), Color(hex: "#BA8E5A")]),
                startPoint: CGPoint(x: 0, y: box.minY),
                endPoint: CGPoint(x: 0, y: box.maxY)
            )
        )
        // Open angled cardboard flaps
        var leftFlap = Path()
        leftFlap.move(to: CGPoint(x: box.minX, y: box.minY))
        leftFlap.addLine(to: CGPoint(x: box.minX - 10, y: box.minY - 8))
        leftFlap.addLine(to: CGPoint(x: box.minX + 18, y: box.minY - 8))
        leftFlap.addLine(to: CGPoint(x: box.minX + 20, y: box.minY))
        leftFlap.closeSubpath()
        ctx.fill(leftFlap, with: .color(Color(hex: "#DFB889")))
        ctx.stroke(leftFlap, with: .color(ink), lineWidth: 1.1)

        var rightFlap = Path()
        rightFlap.move(to: CGPoint(x: box.maxX, y: box.minY))
        rightFlap.addLine(to: CGPoint(x: box.maxX + 10, y: box.minY - 8))
        rightFlap.addLine(to: CGPoint(x: box.maxX - 18, y: box.minY - 8))
        rightFlap.addLine(to: CGPoint(x: box.maxX - 20, y: box.minY))
        rightFlap.closeSubpath()
        ctx.fill(rightFlap, with: .color(Color(hex: "#DFB889")))
        ctx.stroke(rightFlap, with: .color(ink), lineWidth: 1.1)

        // Red-and-white bakery twine ribbon across box front
        var twine = Path()
        twine.move(to: CGPoint(x: box.midX, y: box.minY))
        twine.addLine(to: CGPoint(x: box.midX, y: box.maxY))
        ctx.stroke(twine, with: .color(AppTheme.pawInRange), style: StrokeStyle(lineWidth: 2.0, dash: [4, 3]))
        ctx.stroke(Path(roundedRect: box, cornerRadius: 4), with: .color(ink), lineWidth: 1.3)
    }

    private func drawClothBall(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        // Soft woven mat + stitched patchwork ball
        let mat = CGRect(x: w * 0.14, y: h * 0.56, width: w * 0.72, height: h * 0.22)
        ctx.fill(Path(ellipseIn: mat), with: .color(Color(hex: "#E6D8C0")))
        ctx.stroke(Path(ellipseIn: mat), with: .color(ink.opacity(0.6)), lineWidth: 1.1)

        let r: CGFloat = 17
        let ballRect = CGRect(x: w * 0.5 - r, y: h * 0.14, width: r * 2, height: r * 2)
        ctx.fill(Path(ellipseIn: ballRect), with: .color(Color(hex: "#C85A32")))
        // Patchwork seam arc
        var seam = Path()
        seam.move(to: CGPoint(x: ballRect.midX, y: ballRect.minY))
        seam.addQuadCurve(to: CGPoint(x: ballRect.midX, y: ballRect.maxY), control: CGPoint(x: ballRect.maxX - 3, y: ballRect.midY))
        ctx.stroke(seam, with: .color(Color(hex: "#F4E5C9")), style: StrokeStyle(lineWidth: 1.6, dash: [3, 2]))
        var seam2 = Path()
        seam2.move(to: CGPoint(x: ballRect.minX + 2, y: ballRect.midY))
        seam2.addQuadCurve(to: CGPoint(x: ballRect.maxX - 2, y: ballRect.midY), control: CGPoint(x: ballRect.midX, y: ballRect.minY + 4))
        ctx.stroke(seam2, with: .color(Color(hex: "#F4E5C9")), style: StrokeStyle(lineWidth: 1.4, dash: [3, 2]))
        ctx.stroke(Path(ellipseIn: ballRect), with: .color(ink), lineWidth: 1.4)
    }

    private func drawWindowCushion(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        let frame = CGRect(x: w * 0.06, y: h * 0.34, width: w * 0.88, height: h * 0.44)
        let pad = CGRect(x: w * 0.10, y: h * 0.16, width: w * 0.80, height: h * 0.44)
        ctx.fill(Path(roundedRect: frame, cornerRadius: 8), with: .color(Color(hex: "#A87444")))
        ctx.stroke(Path(roundedRect: frame, cornerRadius: 8), with: .color(ink), lineWidth: 1.3)
        ctx.fill(Path(roundedRect: pad, cornerRadius: 12), with: .color(Color(hex: "#F0E3CC")))
        ctx.stroke(Path(roundedRect: pad, cornerRadius: 12), with: .color(ink), lineWidth: 1.3)
        // Quilted button tufts
        for frac in [0.30, 0.50, 0.70] {
            let bx = pad.minX + pad.width * frac
            ctx.fill(Path(ellipseIn: CGRect(x: bx - 3, y: pad.midY - 3, width: 6, height: 6)), with: .color(Color(hex: "#B57B48")))
        }
    }

    private func drawEmptyCedarMat(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        let mat = CGRect(x: w * 0.14, y: h * 0.42, width: w * 0.72, height: h * 0.34)
        ctx.fill(Path(ellipseIn: mat), with: .color(AppTheme.warmPaper.opacity(0.65)))
        ctx.stroke(Path(ellipseIn: mat), with: .color(ink.opacity(0.4)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
    }
}

// MARK: - 2. Individually Illustrated Painterly Curio Stamps (All 8 Place & Weather Curios)
struct PaintedCurioStampView: View {
    let curioID: String
    var size: CGFloat = 38

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let ink = Color(hex: "#2C3536").opacity(0.78)

            // Soft parchment stamp halo
            ctx.fill(Path(ellipseIn: CGRect(x: 2, y: 2, width: w - 4, height: h - 4)), with: .color(AppTheme.parchmentTray))

            switch curioID {
            case "curio.bakery_twine":
                // Coiled red-and-white bakery twine + bow
                let coil = CGRect(x: w * 0.22, y: h * 0.26, width: w * 0.56, height: h * 0.48)
                ctx.stroke(Path(ellipseIn: coil), with: .color(AppTheme.pawInRange), style: StrokeStyle(lineWidth: 3.5, dash: [5, 3]))
                ctx.stroke(Path(ellipseIn: coil.insetBy(dx: 4, dy: 4)), with: .color(AppTheme.warmPaper), lineWidth: 2)
                ctx.stroke(Path(ellipseIn: coil), with: .color(ink), lineWidth: 0.9)

            case "curio.rain_pebble":
                // Rain-polished slate river pebble with wet sheen
                let stone = Path(ellipseIn: CGRect(x: w * 0.16, y: h * 0.26, width: w * 0.68, height: h * 0.48))
                ctx.fill(
                    stone,
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: "#84A0A8"), Color(hex: "#4C6670")]),
                        center: CGPoint(x: w * 0.38, y: h * 0.38),
                        startRadius: 2,
                        endRadius: w * 0.42
                    )
                )
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.30, y: h * 0.34, width: w * 0.18, height: h * 0.09)), with: .color(.white.opacity(0.65)))
                ctx.stroke(stone, with: .color(ink), lineWidth: 1.2)

            case "curio.ginkgo_leaf":
                // Golden fan-shaped ginkgo leaf with stem
                var fan = Path()
                fan.move(to: CGPoint(x: w * 0.50, y: h * 0.72))
                fan.addCurve(to: CGPoint(x: w * 0.18, y: h * 0.36), control1: CGPoint(x: w * 0.26, y: h * 0.64), control2: CGPoint(x: w * 0.16, y: h * 0.48))
                fan.addQuadCurve(to: CGPoint(x: w * 0.48, y: h * 0.26), control: CGPoint(x: w * 0.32, y: h * 0.18))
                fan.addLine(to: CGPoint(x: w * 0.50, y: h * 0.40))
                fan.addLine(to: CGPoint(x: w * 0.52, y: h * 0.26))
                fan.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.36), control: CGPoint(x: w * 0.68, y: h * 0.18))
                fan.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.72), control1: CGPoint(x: w * 0.84, y: h * 0.48), control2: CGPoint(x: w * 0.74, y: h * 0.64))
                fan.closeSubpath()
                ctx.fill(fan, with: .color(Color(hex: "#D6A53E")))
                ctx.stroke(fan, with: .color(ink), lineWidth: 1.1)
                var stem = Path()
                stem.move(to: CGPoint(x: w * 0.50, y: h * 0.72))
                stem.addLine(to: CGPoint(x: w * 0.50, y: h * 0.88))
                ctx.stroke(stem, with: .color(Color(hex: "#7A583B")), lineWidth: 1.8)

            case "curio.dusk_sea_glass":
                // Frosted sea-green beach glass gem
                var gem = Path()
                gem.move(to: CGPoint(x: w * 0.26, y: h * 0.34))
                gem.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.28), control: CGPoint(x: w * 0.50, y: h * 0.16))
                gem.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.68), control: CGPoint(x: w * 0.86, y: h * 0.50))
                gem.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.70), control: CGPoint(x: w * 0.48, y: h * 0.82))
                gem.closeSubpath()
                ctx.fill(gem, with: .color(Color(hex: "#599891").opacity(0.82)))
                ctx.stroke(gem, with: .color(.white.opacity(0.7)), lineWidth: 1.4)
                ctx.stroke(gem, with: .color(ink), lineWidth: 1.0)

            case "curio.cedar_pinecone":
                // Layered cedar pinecone scales
                let cone = Path(ellipseIn: CGRect(x: w * 0.26, y: h * 0.18, width: w * 0.48, height: h * 0.64))
                ctx.fill(cone, with: .color(Color(hex: "#8A6240")))
                for row in 0..<3 {
                    var arc = Path()
                    let y = h * (0.34 + CGFloat(row) * 0.15)
                    arc.move(to: CGPoint(x: w * 0.30, y: y))
                    arc.addQuadCurve(to: CGPoint(x: w * 0.70, y: y), control: CGPoint(x: w * 0.50, y: y + 6))
                    ctx.stroke(arc, with: .color(Color(hex: "#4A321E")), lineWidth: 1.3)
                }
                ctx.stroke(cone, with: .color(ink), lineWidth: 1.1)

            case "curio.tram_ticket":
                // Vintage Taiwan local railway cardboard stub
                let stub = Path(roundedRect: CGRect(x: w * 0.16, y: h * 0.28, width: w * 0.68, height: h * 0.44), cornerRadius: 3)
                ctx.fill(stub, with: .color(Color(hex: "#DDD0B6")))
                ctx.stroke(stub, with: .color(ink), lineWidth: 1.1)
                var line = Path()
                line.move(to: CGPoint(x: w * 0.26, y: h * 0.46))
                line.addLine(to: CGPoint(x: w * 0.74, y: h * 0.46))
                line.move(to: CGPoint(x: w * 0.26, y: h * 0.58))
                line.addLine(to: CGPoint(x: w * 0.60, y: h * 0.58))
                ctx.stroke(line, with: .color(AppTheme.forestTeal), lineWidth: 1.4)

            case "curio.umbrella_ribbon":
                // Blue umbrella tie ribbon + snap button
                let ribbon = Path(roundedRect: CGRect(x: w * 0.18, y: h * 0.36, width: w * 0.64, height: h * 0.26), cornerRadius: 6)
                ctx.fill(ribbon, with: .color(Color(hex: "#4B6F78")))
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.64, y: h * 0.43, width: 7, height: 7)), with: .color(AppTheme.brassLight))
                ctx.stroke(ribbon, with: .color(ink), lineWidth: 1.1)

            default:
                // Fragrant cypress sprig
                var twig = Path()
                twig.move(to: CGPoint(x: w * 0.28, y: h * 0.78))
                twig.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.22), control: CGPoint(x: w * 0.50, y: h * 0.50))
                ctx.stroke(twig, with: .color(Color(hex: "#4E7858")), lineWidth: 2.2)
                for idx in 0..<4 {
                    let frac = CGFloat(idx) * 0.15 + 0.30
                    let px = w * frac
                    let py = h * (1.0 - frac)
                    ctx.fill(Path(ellipseIn: CGRect(x: px - 6, y: py - 3, width: 12, height: 6)), with: .color(Color(hex: "#588A62")))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 3. Hand-Crafted Painterly Taiwanese Bakery Sidewalk Scene (60fps Animated Noren, Lantern & Rain Ripples)
struct TaiwaneseBakeryStorybookBackdrop: View {
    let weather: WeatherMode
    var isStatic: Bool = false

    var body: some View {
        Group {
            if isStatic {
                sceneCanvas(time: 1.0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    sceneCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
    }

    @ViewBuilder
    private func sceneCanvas(time: Double) -> some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let ink = Color(hex: "#2C3536").opacity(0.68)

            // 1. Translucent watercolor sky wash
            let skyColors: [Color] = {
                switch weather {
                case .lightRain, .postRain: return [Color(hex: "#9FB7C2"), Color(hex: "#DCE2DC"), Color(hex: "#ECE8DD")]
                case .dusk:                 return [Color(hex: "#D99C6B"), Color(hex: "#EBC89E"), Color(hex: "#E5D2BC")]
                case .clearMorning:         return [Color(hex: "#DCEAE3"), Color(hex: "#F4F0E2"), Color(hex: "#FAF6EE")]
                case .overcast:             return [Color(hex: "#CFD4D2"), Color(hex: "#E5E4DC"), Color(hex: "#EFECE3")]
                }
            }()
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(Gradient(colors: skyColors), startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.65))
            )

            // 2. Soft rain-washed street trees on left side
            ctx.fill(Path(ellipseIn: CGRect(x: -w * 0.22, y: h * 0.28, width: w * 0.56, height: h * 0.36)), with: .color(Color(hex: "#6F8E75").opacity(0.32)))
            ctx.fill(Path(ellipseIn: CGRect(x: -w * 0.14, y: h * 0.36, width: w * 0.44, height: h * 0.28)), with: .color(Color(hex: "#58785F").opacity(0.28)))

            // 3. Warm wooden bakery storefront & glowing display windows
            let shopLeft = w * 0.18
            let shopTop = h * 0.14
            let shopRect = CGRect(x: shopLeft, y: shopTop, width: w * 0.86, height: h * 0.49)
            ctx.fill(
                Path(shopRect),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#FFF4D9"), Color(hex: "#F4DFBA")]),
                    startPoint: CGPoint(x: shopRect.midX, y: shopRect.minY),
                    endPoint: CGPoint(x: shopRect.midX, y: shopRect.maxY)
                )
            )

            // Bakery shelves with hand-painted bread loaves & biscuit jars inside window
            let shelfY1 = shopTop + shopRect.height * 0.36
            let shelfY2 = shopTop + shopRect.height * 0.56
            ctx.fill(Path(CGRect(x: shopLeft + 18, y: shelfY1, width: shopRect.width - 30, height: 6)), with: .color(AppTheme.timberWarm.opacity(0.8)))
            ctx.fill(Path(CGRect(x: shopLeft + 18, y: shelfY2, width: shopRect.width - 30, height: 6)), with: .color(AppTheme.timberWarm.opacity(0.8)))

            for idx in 0..<4 {
                let lx = shopLeft + 44 + CGFloat(idx) * 68
                let loaf = Path(ellipseIn: CGRect(x: lx, y: shelfY1 - 24, width: 50, height: 26))
                ctx.fill(loaf, with: .color(Color(hex: "#D4A062").opacity(0.85)))
                ctx.stroke(loaf, with: .color(ink.opacity(0.45)), lineWidth: 1.0)
                // Glass cookie jars on lower shelf
                let jar = Path(roundedRect: CGRect(x: lx + 8, y: shelfY2 - 34, width: 32, height: 34), cornerRadius: 6)
                ctx.fill(jar, with: .color(Color(hex: "#E6ECEB").opacity(0.65)))
                ctx.fill(Path(roundedRect: CGRect(x: lx + 12, y: shelfY2 - 20, width: 24, height: 18), cornerRadius: 4), with: .color(Color(hex: "#B58558").opacity(0.55)))
                ctx.stroke(jar, with: .color(ink.opacity(0.4)), lineWidth: 1.0)
            }

            // Timber window mullions & lower cedar wainscoting
            let wainscotTop = shopTop + shopRect.height * 0.72
            ctx.fill(Path(CGRect(x: shopLeft, y: wainscotTop, width: shopRect.width, height: shopRect.maxY - wainscotTop)), with: .color(Color(hex: "#B38557")))
            for slat in 0..<10 {
                let sx = shopLeft + CGFloat(slat) * 32
                var line = Path()
                line.move(to: CGPoint(x: sx, y: wainscotTop))
                line.addLine(to: CGPoint(x: sx, y: shopRect.maxY))
                ctx.stroke(line, with: .color(AppTheme.timberDeep.opacity(0.32)), lineWidth: 1.0)
            }
            // Main cedar pillar & horizontal sash
            ctx.fill(Path(CGRect(x: shopLeft - 4, y: shopTop, width: 22, height: shopRect.height)), with: .color(Color(hex: "#9B6E45")))
            ctx.stroke(Path(CGRect(x: shopLeft - 4, y: shopTop, width: 22, height: shopRect.height)), with: .color(ink), lineWidth: 1.2)
            ctx.fill(Path(CGRect(x: shopLeft + shopRect.width * 0.44, y: shopTop, width: 14, height: shopRect.height)), with: .color(Color(hex: "#9B6E45")))
            ctx.fill(Path(CGRect(x: shopLeft, y: wainscotTop - 6, width: shopRect.width, height: 10)), with: .color(Color(hex: "#8F633C")))

            // 4. Hand-drawn Taiwanese timber roof eaves & dark ceramic roof tiles
            let eaveH = h * 0.115
            ctx.fill(
                Path(CGRect(x: 0, y: 0, width: w, height: eaveH)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#9C6E44"), Color(hex: "#78502E")]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: eaveH)
                )
            )
            // Roof tile ribs
            for col in 0..<12 {
                let rx = CGFloat(col) * (w / 11.0)
                var rib = Path()
                rib.move(to: CGPoint(x: rx + 14, y: 0))
                rib.addLine(to: CGPoint(x: rx, y: eaveH - 6))
                ctx.stroke(rib, with: .color(AppTheme.timberDeep.opacity(0.45)), lineWidth: 1.4)
            }
            ctx.fill(Path(CGRect(x: 0, y: eaveH - 9, width: w, height: 9)), with: .color(Color(hex: "#6B4527")))

            // 5. Gently swaying Forest-Teal Bakery Noren (暖簾)
            let breeze = sin(time * 1.4) * 3.5
            let panelCount = 5
            let panelW = (w - shopLeft - 14) / CGFloat(panelCount)
            for idx in 0..<panelCount {
                let px = shopLeft + 10 + CGFloat(idx) * panelW
                var flap = Path()
                flap.move(to: CGPoint(x: px + 2, y: eaveH))
                flap.addLine(to: CGPoint(x: px + panelW - 3, y: eaveH))
                flap.addQuadCurve(
                    to: CGPoint(x: px + panelW - 3 + CGFloat(breeze), y: eaveH + 64),
                    control: CGPoint(x: px + panelW - 2 + CGFloat(breeze * 0.5), y: eaveH + 34)
                )
                flap.addLine(to: CGPoint(x: px + 2 + CGFloat(breeze), y: eaveH + 64))
                flap.closeSubpath()
                ctx.fill(
                    flap,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "#255E62"), Color(hex: "#194347")]),
                        startPoint: CGPoint(x: px, y: eaveH),
                        endPoint: CGPoint(x: px, y: eaveH + 64)
                    )
                )
                ctx.stroke(flap, with: .color(ink), lineWidth: 1.1)
            }

            // 6. Swaying glowing Taiwanese Amber Paper Lantern
            let lanternSwing = sin(time * 1.1) * 2.5
            let lx = shopLeft - 18 + CGFloat(lanternSwing)
            let ly = eaveH + 54
            var cord = Path()
            cord.move(to: CGPoint(x: shopLeft - 18, y: eaveH))
            cord.addLine(to: CGPoint(x: lx, y: ly - 32))
            ctx.stroke(cord, with: .color(AppTheme.timberDeep), lineWidth: 2.0)

            // Warm radial lantern aura
            let glowR: CGFloat = weather == .dusk ? 96 : 72
            ctx.fill(
                Path(ellipseIn: CGRect(x: lx - glowR, y: ly - glowR, width: glowR * 2, height: glowR * 2)),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: "#FFE699").opacity(0.45), Color(hex: "#F2A846").opacity(0.15), .clear]),
                    center: CGPoint(x: lx, y: ly),
                    startRadius: 6,
                    endRadius: glowR
                )
            )
            let lanternRect = CGRect(x: lx - 28, y: ly - 32, width: 56, height: 64)
            ctx.fill(
                Path(ellipseIn: lanternRect),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: "#FFF8D4"), Color(hex: "#F2A846"), Color(hex: "#C76D2A")]),
                    center: CGPoint(x: lx, y: ly),
                    startRadius: 4,
                    endRadius: 34
                )
            )
            // Lantern bamboo ribs
            for ry in [-14.0, 0.0, 14.0] {
                var rib = Path()
                rib.move(to: CGPoint(x: lx - 24, y: ly + ry))
                rib.addQuadCurve(to: CGPoint(x: lx + 24, y: ly + ry), control: CGPoint(x: lx, y: ly + ry + 5))
                ctx.stroke(rib, with: .color(Color(hex: "#8F4A1E").opacity(0.45)), lineWidth: 1.0)
            }
            ctx.stroke(Path(ellipseIn: lanternRect), with: .color(ink), lineWidth: 1.2)
            ctx.fill(Path(roundedRect: CGRect(x: lx - 12, y: ly - 35, width: 24, height: 6), cornerRadius: 2), with: .color(AppTheme.timberDeep))
            ctx.fill(Path(roundedRect: CGRect(x: lx - 11, y: ly + 29, width: 22, height: 6), cornerRadius: 2), with: .color(AppTheme.timberDeep))

            // 7. Wet Slate Flagstones & Rustic Wooden Stool
            let groundTop = h * 0.62
            ctx.fill(
                Path(CGRect(x: 0, y: groundTop, width: w, height: h - groundTop)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#CFC9BC"), Color(hex: "#A8A49B"), Color(hex: "#8E9390")]),
                    startPoint: CGPoint(x: 0, y: groundTop),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )
            // Stone curb seam lines
            for row in 0..<3 {
                let y = groundTop + CGFloat(row) * 52
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: w, y: y))
                ctx.stroke(line, with: .color(ink.opacity(0.28)), lineWidth: 1.3)
            }

            // Warm amber lantern puddle reflection on wet stone
            ctx.fill(
                Path(ellipseIn: CGRect(x: lx - 48, y: groundTop + 26, width: 108, height: 24)),
                with: .color(Color(hex: "#F2B85B").opacity(0.26))
            )

            // Rustic Wooden Stool tucked on right edge
            let stoolX = w * 0.78
            let stoolY = groundTop + 14
            var leg1 = Path(); leg1.move(to: CGPoint(x: stoolX - 18, y: stoolY)); leg1.addLine(to: CGPoint(x: stoolX - 24, y: stoolY + 42))
            var leg2 = Path(); leg2.move(to: CGPoint(x: stoolX + 18, y: stoolY)); leg2.addLine(to: CGPoint(x: stoolX + 24, y: stoolY + 42))
            ctx.stroke(leg1, with: .color(Color(hex: "#7D5432")), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            ctx.stroke(leg2, with: .color(Color(hex: "#7D5432")), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            let seat = Path(roundedRect: CGRect(x: stoolX - 28, y: stoolY - 8, width: 56, height: 13), cornerRadius: 5)
            ctx.fill(seat, with: .color(Color(hex: "#B58353")))
            ctx.stroke(seat, with: .color(ink), lineWidth: 1.2)

            // 8. Rain streaks + expanding puddle ripples during rainy weather
            if weather.isRainy {
                for i in 0..<42 {
                    let xBase = CGFloat((i * 43) % Int(max(1, w)))
                    let yOff = CGFloat((time * 180 + Double(i * 37)).truncatingRemainder(dividingBy: Double(max(1, h))))
                    var drop = Path()
                    drop.move(to: CGPoint(x: xBase, y: yOff))
                    drop.addLine(to: CGPoint(x: xBase - 9, y: yOff + 26))
                    ctx.stroke(drop, with: .color(AppTheme.warmPaper.opacity(0.45)), lineWidth: 1.1)
                }
                for rIdx in 0..<3 {
                    let phase = (time * 0.65 + Double(rIdx) * 0.33).truncatingRemainder(dividingBy: 1.0)
                    let rx = w * (0.20 + CGFloat(rIdx) * 0.30)
                    let ry = groundTop + 42 + CGFloat(rIdx) * 24
                    let radW = CGFloat(phase) * 34 + 6
                    let radH = radW * 0.28
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: rx - radW, y: ry - radH, width: radW * 2, height: radH * 2)),
                        with: .color(AppTheme.warmPaper.opacity((1.0 - phase) * 0.45)),
                        lineWidth: 1.1
                    )
                }
            }
        }
    }
}

// MARK: - 4. Hand-Drawn Corner Keepsakes (Wicker Toy Basket & Steaming Ceramic Teapot)
struct WickerBasketCornerButton: View {
    let badgeText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Canvas { ctx, size in
                        let w = size.width, h = size.height
                        let ink = Color(hex: "#2C3536").opacity(0.76)

                        // Peeking red cloth ball inside basket
                        let ball = CGRect(x: w * 0.44, y: h * 0.14, width: 18, height: 18)
                        ctx.fill(Path(ellipseIn: ball), with: .color(AppTheme.pawInRange))
                        ctx.stroke(Path(ellipseIn: ball), with: .color(ink), lineWidth: 1.1)

                        // Peeking folded linen corner
                        let cloth = Path(roundedRect: CGRect(x: w * 0.18, y: h * 0.18, width: 18, height: 14), cornerRadius: 4)
                        ctx.fill(cloth, with: .color(Color(hex: "#EDE5D6")))
                        ctx.stroke(cloth, with: .color(ink), lineWidth: 1.0)

                        // Tapered woven rattan basket body
                        var bodyPath = Path()
                        bodyPath.move(to: CGPoint(x: w * 0.12, y: h * 0.36))
                        bodyPath.addLine(to: CGPoint(x: w * 0.88, y: h * 0.36))
                        bodyPath.addLine(to: CGPoint(x: w * 0.78, y: h * 0.86))
                        bodyPath.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.86), control: CGPoint(x: w * 0.50, y: h * 0.92))
                        bodyPath.closeSubpath()
                        ctx.fill(
                            bodyPath,
                            with: .linearGradient(
                                Gradient(colors: [Color(hex: "#D5AA70"), Color(hex: "#B5864D")]),
                                startPoint: CGPoint(x: 0, y: h * 0.36),
                                endPoint: CGPoint(x: 0, y: h * 0.88)
                            )
                        )
                        // Cross-woven rattan ribs
                        for row in 1...3 {
                            let y = h * (0.36 + CGFloat(row) * 0.13)
                            var hl = Path()
                            hl.move(to: CGPoint(x: w * 0.16, y: y))
                            hl.addLine(to: CGPoint(x: w * 0.84, y: y))
                            ctx.stroke(hl, with: .color(AppTheme.timberDeep.opacity(0.35)), lineWidth: 1.1)
                        }
                        for col in 1...4 {
                            let x = w * (0.14 + CGFloat(col) * 0.14)
                            var vl = Path()
                            vl.move(to: CGPoint(x: x, y: h * 0.38))
                            vl.addLine(to: CGPoint(x: x, y: h * 0.84))
                            ctx.stroke(vl, with: .color(AppTheme.timberDeep.opacity(0.30)), lineWidth: 1.0)
                        }
                        ctx.stroke(bodyPath, with: .color(ink), lineWidth: 1.3)

                        // Braided basket rim
                        let rim = Path(roundedRect: CGRect(x: w * 0.08, y: h * 0.30, width: w * 0.84, height: 10), cornerRadius: 5)
                        ctx.fill(rim, with: .color(Color(hex: "#DFB880")))
                        ctx.stroke(rim, with: .color(ink), lineWidth: 1.2)
                    }
                    .frame(width: 60, height: 58)
                    .shadow(color: AppTheme.deepPineInk.opacity(0.20), radius: 5, y: 3)

                    Text(badgeText)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(AppTheme.forestTeal, in: Capsule())
                        .offset(x: 4, y: -2)
                }

                Text("藤編籃")
                    .font(AppTheme.diegeticLabel(11))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.warmPaper.opacity(0.92), in: Capsule())
            }
            .frame(minWidth: 64, minHeight: 64)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("打開藤編玩具籃")
    }
}

struct CeramicTeapotCornerButton: View {
    let isSteaming: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { ctx, size in
                        let w = size.width, h = size.height
                        let ink = Color(hex: "#2C3536").opacity(0.76)

                        // Rising delicate steam wisps
                        let steamAlpha = isSteaming ? 0.65 : 0.30
                        for idx in 0..<2 {
                            let phase = (t * 0.65 + Double(idx) * 0.5).truncatingRemainder(dividingBy: 1.0)
                            var curl = Path()
                            let sx = w * (0.20 + CGFloat(idx) * 0.08)
                            let sy = h * 0.38 - CGFloat(phase) * 18
                            curl.move(to: CGPoint(x: sx, y: sy + 10))
                            curl.addQuadCurve(to: CGPoint(x: sx + 4, y: sy), control: CGPoint(x: sx - 5, y: sy + 5))
                            ctx.stroke(curl, with: .color(AppTheme.warmPaper.opacity(steamAlpha * (1.0 - phase))), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                        }

                        // Cane overhead handle
                        var handle = Path()
                        handle.move(to: CGPoint(x: w * 0.30, y: h * 0.44))
                        handle.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.46), control: CGPoint(x: w * 0.56, y: h * 0.12))
                        ctx.stroke(handle, with: .color(AppTheme.timberWarm), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
                        ctx.stroke(handle, with: .color(ink), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))

                        // Curved spout on left
                        var spout = Path()
                        spout.move(to: CGPoint(x: w * 0.28, y: h * 0.64))
                        spout.addQuadCurve(to: CGPoint(x: w * 0.10, y: h * 0.44), control: CGPoint(x: w * 0.14, y: h * 0.62))
                        spout.addLine(to: CGPoint(x: w * 0.16, y: h * 0.42))
                        spout.addQuadCurve(to: CGPoint(x: w * 0.32, y: h * 0.54), control: CGPoint(x: w * 0.22, y: h * 0.54))
                        spout.closeSubpath()
                        ctx.fill(spout, with: .color(Color(hex: "#EDE5D6")))
                        ctx.stroke(spout, with: .color(ink), lineWidth: 1.2)

                        // Glazed ceramic teapot body
                        let pot = Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.42, width: w * 0.58, height: h * 0.46))
                        ctx.fill(
                            pot,
                            with: .radialGradient(
                                Gradient(colors: [Color(hex: "#FAF6EE"), Color(hex: "#E6DEC8"), Color(hex: "#C4B9A2")]),
                                center: CGPoint(x: w * 0.46, y: h * 0.54),
                                startRadius: 3,
                                endRadius: 28
                            )
                        )
                        // Celadon glaze belly band
                        var glaze = Path()
                        glaze.move(to: CGPoint(x: w * 0.27, y: h * 0.66))
                        glaze.addQuadCurve(to: CGPoint(x: w * 0.80, y: h * 0.66), control: CGPoint(x: w * 0.53, y: h * 0.74))
                        ctx.stroke(glaze, with: .color(AppTheme.ceramicGlaze.opacity(0.65)), lineWidth: 4.5)
                        ctx.stroke(pot, with: .color(ink), lineWidth: 1.3)

                        // Teapot lid & finial knob
                        let lid = Path(ellipseIn: CGRect(x: w * 0.38, y: h * 0.38, width: w * 0.30, height: 10))
                        ctx.fill(lid, with: .color(AppTheme.ceramicGlaze))
                        ctx.stroke(lid, with: .color(ink), lineWidth: 1.1)
                        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.50, y: h * 0.33, width: 7, height: 7)), with: .color(AppTheme.timberDeep))
                    }
                    .frame(width: 62, height: 58)
                    .shadow(color: AppTheme.deepPineInk.opacity(0.20), radius: 5, y: 3)
                }

                Text("陶瓷茶壺")
                    .font(AppTheme.diegeticLabel(11))
                    .foregroundStyle(AppTheme.deepPineInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.warmPaper.opacity(0.92), in: Capsule())
            }
            .frame(minWidth: 64, minHeight: 64)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("打開陶瓷茶壺與散步夥伴抽屜")
    }
}

// MARK: - 5. Ambient Sunroom Dust Motes / Rain-Streaked Window Glass
struct SunroomAtmosphereParticlesView: View {
    let weather: WeatherMode

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let w = size.width, h = size.height
                if weather.isRainy {
                    // Soft rain streaks drifting down the upper window half
                    for idx in 0..<18 {
                        let rx = w * (0.12 + CGFloat((idx * 37) % 76) / 100.0)
                        let phase = (t * 0.35 + Double(idx) * 0.19).truncatingRemainder(dividingBy: 1.0)
                        let ry = h * 0.14 + CGFloat(phase) * h * 0.34
                        var drop = Path()
                        drop.move(to: CGPoint(x: rx, y: ry))
                        drop.addLine(to: CGPoint(x: rx - 2, y: ry + 12))
                        ctx.stroke(drop, with: .color(AppTheme.warmPaper.opacity(0.45 * sin(phase * .pi))), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                    }
                } else {
                    // Warm sunlit floating dust motes dancing slowly in sunbeams
                    for idx in 0..<14 {
                        let phase = (t * 0.14 + Double(idx) * 0.23).truncatingRemainder(dividingBy: 1.0)
                        let x = w * (0.18 + CGFloat((idx * 29) % 66) / 100.0) + CGFloat(sin(t * 0.7 + Double(idx))) * 14
                        let y = h * 0.18 + CGFloat(phase) * h * 0.45
                        let r: CGFloat = 2.0 + CGFloat(idx % 3) * 0.8
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                            with: .color(Color(hex: "#FFF8DC").opacity(0.55 * sin(phase * .pi)))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 6. Tactile Care Cozy Sunlit Cedar Floor & Braided Rug Backdrop
struct TactileCareFloorBackdrop: View {
    let weather: WeatherMode

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height

            // Warm honey cedar plank background
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: weather.isRainy
                             ? [Color(hex: "#E6E4DC"), Color(hex: "#D5C8B4")]
                             : [Color(hex: "#F4EBD7"), Color(hex: "#DFC8A6")]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )

            // Cedar wood plank lines
            for idx in 0..<9 {
                let y = h * 0.12 + CGFloat(idx) * (h * 0.10)
                var plank = Path()
                plank.move(to: CGPoint(x: 0, y: y))
                plank.addLine(to: CGPoint(x: w, y: y))
                ctx.stroke(plank, with: .color(AppTheme.timberDeep.opacity(0.10)), lineWidth: 1.0)
            }

            // Soft diagonal windowpane sunlight patch across the floor
            if !weather.isRainy {
                var beam = Path()
                beam.move(to: CGPoint(x: w * 0.08, y: 0))
                beam.addLine(to: CGPoint(x: w * 0.72, y: 0))
                beam.addLine(to: CGPoint(x: w * 0.96, y: h * 0.75))
                beam.addLine(to: CGPoint(x: w * 0.24, y: h * 0.75))
                beam.closeSubpath()
                ctx.fill(beam, with: .color(Color(hex: "#FFFDF2").opacity(0.32)))
            }

            // Hand-loomed concentric braided oval rug centered under the pet
            let rugCenter = CGPoint(x: w * 0.50, y: h * 0.62)
            let rings: [(CGFloat, CGFloat, Color)] = [
                (w * 0.84, 152, Color(hex: "#617D92").opacity(0.38)),
                (w * 0.70, 122, Color(hex: "#D7C5A5").opacity(0.55)),
                (w * 0.54, 92,  Color(hex: "#B87D56").opacity(0.35))
            ]
            for (rw, rh, col) in rings {
                let rect = CGRect(x: rugCenter.x - rw * 0.5, y: rugCenter.y - rh * 0.5, width: rw, height: rh)
                ctx.fill(Path(ellipseIn: rect), with: .color(col))
                ctx.stroke(Path(ellipseIn: rect), with: .color(AppTheme.timberDeep.opacity(0.20)), style: StrokeStyle(lineWidth: 1.4, dash: [5, 3]))
            }
        }
    }
}
