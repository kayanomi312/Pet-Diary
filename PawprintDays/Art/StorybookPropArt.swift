import SwiftUI

// MARK: - 1. Hand-Crafted Painterly Home Furnishings (5 Goodies + 2-State Loved Patina)
struct PaintedGoodiePropView: View {
    let goodieID: String?
    let hasLovedPatina: Bool
    let hasStitchedPatch: Bool
    let isWide: Bool

    private var customAssetName: String? {
        goodieID?.replacingOccurrences(of: ".", with: "_")
    }

    var body: some View {
        ZStack {
            if let assetName = customAssetName, let img = UIImage(named: assetName) {
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.deepPineInk.opacity(0.22), .clear],
                                center: .center,
                                startRadius: 6,
                                endRadius: isWide ? 74 : 58
                            )
                        )
                        .frame(width: isWide ? 148 : 114, height: 22)
                        .offset(y: 4)

                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: isWide ? 158 : 128, height: 76)
                        .overlay(alignment: .topTrailing) {
                            if hasLovedPatina && hasStitchedPatch {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.pawInRange)
                                    .frame(width: 18, height: 16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(AppTheme.warmPaper, style: StrokeStyle(lineWidth: 1.2, dash: [2.5, 2]))
                                    )
                                    .offset(x: -14, y: 12)
                            }
                        }
                }
            } else {
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
                    case "goodie.hearth_brazier":
                        drawHearthBrazier(in: &ctx, size: size, ink: ink)
                    case "goodie.cedar_perch":
                        drawCedarPerch(in: &ctx, size: size, ink: ink)
                    case "goodie.woven_hammock":
                        drawWovenHammock(in: &ctx, size: size, ink: ink)
                    case "goodie.moss_planter":
                        drawMossPlanter(in: &ctx, size: size, ink: ink)
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
        }
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

    private func drawHearthBrazier(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        // Warm glowing hearth halo on floor
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.14, y: h * 0.42, width: w * 0.72, height: h * 0.46)),
            with: .radialGradient(
                Gradient(colors: [Color(hex: "#F5A65B").opacity(0.38), .clear]),
                center: CGPoint(x: w * 0.50, y: h * 0.60),
                startRadius: 4,
                endRadius: w * 0.38
            )
        )
        // Terracotta ceramic charcoal hibachi pot
        let pot = Path(roundedRect: CGRect(x: w * 0.26, y: h * 0.24, width: w * 0.48, height: h * 0.56), cornerRadius: 12)
        ctx.fill(
            pot,
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#C96A46"), Color(hex: "#8F4125")]),
                startPoint: CGPoint(x: w * 0.26, y: h * 0.24),
                endPoint: CGPoint(x: w * 0.74, y: h * 0.80)
            )
        )
        ctx.stroke(pot, with: .color(ink), lineWidth: 1.3)
        // Glowing ember bed at rim
        let rim = Path(ellipseIn: CGRect(x: w * 0.30, y: h * 0.17, width: w * 0.40, height: h * 0.20))
        ctx.fill(rim, with: .color(Color(hex: "#4A2C22")))
        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.36, y: h * 0.20, width: w * 0.28, height: h * 0.13)), with: .color(Color(hex: "#F49A42")))
        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.43, y: h * 0.22, width: w * 0.14, height: h * 0.08)), with: .color(Color(hex: "#FFE39C")))
        ctx.stroke(rim, with: .color(ink), lineWidth: 1.1)
    }

    private func drawCedarPerch(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        // Wooden vertical side pillars
        for px in [w * 0.22, w * 0.70] {
            let pillar = Path(roundedRect: CGRect(x: px, y: h * 0.16, width: w * 0.08, height: h * 0.62), cornerRadius: 2)
            ctx.fill(pillar, with: .color(Color(hex: "#8C603B")))
            ctx.stroke(pillar, with: .color(ink), lineWidth: 1.1)
        }
        // Lower & upper cedar plank tiers
        let lowerPlank = Path(roundedRect: CGRect(x: w * 0.14, y: h * 0.56, width: w * 0.72, height: h * 0.15), cornerRadius: 4)
        let upperPlank = Path(roundedRect: CGRect(x: w * 0.10, y: h * 0.16, width: w * 0.80, height: h * 0.18), cornerRadius: 5)
        ctx.fill(lowerPlank, with: .color(Color(hex: "#B58454")))
        ctx.stroke(lowerPlank, with: .color(ink), lineWidth: 1.2)
        ctx.fill(upperPlank, with: .color(Color(hex: "#C79664")))
        ctx.stroke(upperPlank, with: .color(ink), lineWidth: 1.3)
        // Soft linen runner on top perch
        let runner = Path(roundedRect: CGRect(x: w * 0.22, y: h * 0.13, width: w * 0.56, height: h * 0.10), cornerRadius: 4)
        ctx.fill(runner, with: .color(Color(hex: "#F2E7D3")))
        ctx.stroke(runner, with: .color(ink.opacity(0.6)), lineWidth: 0.9)
    }

    private func drawWovenHammock(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        // Curved bamboo cradle supports
        var leftLeg = Path()
        leftLeg.move(to: CGPoint(x: w * 0.16, y: h * 0.76))
        leftLeg.addLine(to: CGPoint(x: w * 0.10, y: h * 0.24))
        var rightLeg = Path()
        rightLeg.move(to: CGPoint(x: w * 0.84, y: h * 0.76))
        rightLeg.addLine(to: CGPoint(x: w * 0.90, y: h * 0.24))
        ctx.stroke(leftLeg, with: .color(Color(hex: "#8A6238")), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        ctx.stroke(rightLeg, with: .color(Color(hex: "#8A6238")), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))

        // Draped woven canvas sling
        var sling = Path()
        sling.move(to: CGPoint(x: w * 0.11, y: h * 0.26))
        sling.addQuadCurve(to: CGPoint(x: w * 0.89, y: h * 0.26), control: CGPoint(x: w * 0.50, y: h * 0.52))
        sling.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.70), control: CGPoint(x: w * 0.74, y: h * 0.68))
        sling.addQuadCurve(to: CGPoint(x: w * 0.11, y: h * 0.26), control: CGPoint(x: w * 0.26, y: h * 0.68))
        sling.closeSubpath()
        ctx.fill(
            sling,
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#F5EAD4"), Color(hex: "#D9BD8E")]),
                startPoint: CGPoint(x: 0, y: h * 0.24),
                endPoint: CGPoint(x: 0, y: h * 0.70)
            )
        )
        ctx.stroke(sling, with: .color(ink), lineWidth: 1.3)
    }

    private func drawMossPlanter(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        // Shallow stoneware dish
        let dish = Path(roundedRect: CGRect(x: w * 0.18, y: h * 0.44, width: w * 0.64, height: h * 0.34), cornerRadius: 9)
        ctx.fill(dish, with: .color(Color(hex: "#D2BFA2")))
        ctx.stroke(dish, with: .color(ink), lineWidth: 1.2)
        // Lush moss mounds
        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.22, y: h * 0.26, width: w * 0.36, height: h * 0.28)), with: .color(Color(hex: "#58855E")))
        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.22, width: w * 0.34, height: h * 0.30)), with: .color(Color(hex: "#6E9E72")))
        // Delicate fern sprouts
        for fx in [w * 0.34, w * 0.52, w * 0.66] {
            var stem = Path()
            stem.move(to: CGPoint(x: fx, y: h * 0.32))
            stem.addQuadCurve(to: CGPoint(x: fx + 5, y: h * 0.10), control: CGPoint(x: fx - 3, y: h * 0.18))
            ctx.stroke(stem, with: .color(Color(hex: "#3E6B47")), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: fx + 2, y: h * 0.07, width: 6, height: 6)), with: .color(Color(hex: "#8FC488")))
        }
    }

    private func drawEmptyCedarMat(in ctx: inout GraphicsContext, size: CGSize, ink: Color) {
        let w = size.width, h = size.height
        let shadowRect = CGRect(x: w * 0.12, y: h * 0.46, width: w * 0.76, height: h * 0.34)
        ctx.fill(Path(ellipseIn: shadowRect), with: .color(AppTheme.timberDeep.opacity(0.14)))

        // Outer braided honey-straw rim
        let outerMat = CGRect(x: w * 0.13, y: h * 0.41, width: w * 0.74, height: h * 0.35)
        ctx.fill(
            Path(ellipseIn: outerMat),
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#EDE0C4"), Color(hex: "#D6BC8E")]),
                startPoint: CGPoint(x: outerMat.midX, y: outerMat.minY),
                endPoint: CGPoint(x: outerMat.midX, y: outerMat.maxY)
            )
        )
        ctx.stroke(Path(ellipseIn: outerMat), with: .color(Color(hex: "#8F653C").opacity(0.55)), lineWidth: 1.3)

        // Inner soft woven linen center
        let innerMat = outerMat.insetBy(dx: w * 0.08, dy: h * 0.055)
        ctx.fill(
            Path(ellipseIn: innerMat),
            with: .radialGradient(
                Gradient(colors: [Color(hex: "#FAF3E4"), Color(hex: "#E8D5B3")]),
                center: CGPoint(x: innerMat.midX - w * 0.06, y: innerMat.midY - h * 0.03),
                startRadius: 2,
                endRadius: innerMat.width * 0.6
            )
        )

        // Subtle straw weave texture lines
        for row in 0..<3 {
            let insetX = w * (0.04 + CGFloat(row) * 0.065)
            let insetY = h * (0.028 + CGFloat(row) * 0.045)
            let weaveRect = outerMat.insetBy(dx: insetX, dy: insetY)
            if weaveRect.width > 8 && weaveRect.height > 4 {
                ctx.stroke(
                    Path(ellipseIn: weaveRect),
                    with: .color(Color(hex: "#A5794E").opacity(row == 0 ? 0.34 : 0.22)),
                    style: StrokeStyle(lineWidth: 1.0, lineCap: .round, dash: [4, 3])
                )
            }
        }

        // Warm wood-tone blanket stitching along the linen border
        let stitchRect = outerMat.insetBy(dx: w * 0.055, dy: h * 0.038)
        ctx.stroke(
            Path(ellipseIn: stitchRect),
            with: .color(Color(hex: "#9B683B").opacity(0.62)),
            style: StrokeStyle(lineWidth: 1.35, lineCap: .round, dash: [5, 4])
        )
    }
}

// MARK: - 2. Individually Illustrated Painterly Curio Stamps (Vintage Postage Seal Medallions)
struct PaintedCurioStampView: View {
    let curioID: String
    var size: CGFloat = 38

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let ink = Color(hex: "#2C3536").opacity(0.80)

            // Vintage postage-stamp scalloped medallion border + warm watercolor halo
            let outerRect = CGRect(x: 1.5, y: 1.5, width: w - 3, height: h - 3)
            ctx.fill(
                Path(ellipseIn: outerRect),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: "#FFFDF7"), Color(hex: "#EFE5D2")]),
                    center: CGPoint(x: w * 0.42, y: h * 0.36),
                    startRadius: 2,
                    endRadius: w * 0.52
                )
            )
            ctx.stroke(
                Path(ellipseIn: outerRect.insetBy(dx: 1.8, dy: 1.8)),
                with: .color(AppTheme.timberWarm.opacity(0.55)),
                style: StrokeStyle(lineWidth: 1.0, dash: [2.5, 2.2])
            )
            ctx.stroke(Path(ellipseIn: outerRect), with: .color(ink.opacity(0.55)), lineWidth: 1.1)

            switch curioID {
            case "curio.bakery_twine":
                // Soft rosy wash behind twine
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.20, width: w * 0.64, height: h * 0.60)), with: .color(AppTheme.pawInRange.opacity(0.14)))
                // Coiled red-and-white bakery twine + cute knotted bow
                let coil = CGRect(x: w * 0.22, y: h * 0.28, width: w * 0.56, height: h * 0.46)
                ctx.stroke(Path(ellipseIn: coil), with: .color(AppTheme.pawInRange), style: StrokeStyle(lineWidth: 3.4, dash: [4.5, 3]))
                ctx.stroke(Path(ellipseIn: coil.insetBy(dx: 4, dy: 4)), with: .color(AppTheme.warmPaper), lineWidth: 2.2)
                ctx.stroke(Path(ellipseIn: coil.insetBy(dx: 7, dy: 7)), with: .color(AppTheme.pawInRange.opacity(0.85)), style: StrokeStyle(lineWidth: 2.0, dash: [3, 2.5]))
                ctx.stroke(Path(ellipseIn: coil), with: .color(ink), lineWidth: 0.9)
                // Little bow tie at top
                let knot = Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.20, width: w * 0.12, height: h * 0.12))
                ctx.fill(knot, with: .color(AppTheme.pawInRange))
                ctx.stroke(knot, with: .color(ink), lineWidth: 0.8)

            case "curio.rain_pebble":
                // Cool rain wash + polished slate river pebble with wet sheen & pale quartz vein
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.14, y: h * 0.52, width: w * 0.72, height: h * 0.30)), with: .color(AppTheme.deepPineInk.opacity(0.12)))
                let stone = Path(ellipseIn: CGRect(x: w * 0.16, y: h * 0.25, width: w * 0.68, height: h * 0.48))
                ctx.fill(
                    stone,
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: "#9BB5BD"), Color(hex: "#597580"), Color(hex: "#3B525B")]),
                        center: CGPoint(x: w * 0.36, y: h * 0.36),
                        startRadius: 1,
                        endRadius: w * 0.44
                    )
                )
                // Natural quartz mineral streak
                var vein = Path()
                vein.move(to: CGPoint(x: w * 0.26, y: h * 0.58))
                vein.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.38), control: CGPoint(x: w * 0.52, y: h * 0.56))
                ctx.stroke(vein, with: .color(AppTheme.warmPaper.opacity(0.55)), lineWidth: 1.3)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.28, y: h * 0.33, width: w * 0.20, height: h * 0.09)), with: .color(.white.opacity(0.75)))
                ctx.stroke(stone, with: .color(ink), lineWidth: 1.2)

            case "curio.ginkgo_leaf":
                // Golden fan-shaped ginkgo leaf with radiating veins
                var fan = Path()
                fan.move(to: CGPoint(x: w * 0.50, y: h * 0.72))
                fan.addCurve(to: CGPoint(x: w * 0.17, y: h * 0.36), control1: CGPoint(x: w * 0.26, y: h * 0.64), control2: CGPoint(x: w * 0.15, y: h * 0.48))
                fan.addQuadCurve(to: CGPoint(x: w * 0.48, y: h * 0.24), control: CGPoint(x: w * 0.31, y: h * 0.16))
                fan.addLine(to: CGPoint(x: w * 0.50, y: h * 0.40))
                fan.addLine(to: CGPoint(x: w * 0.52, y: h * 0.24))
                fan.addQuadCurve(to: CGPoint(x: w * 0.83, y: h * 0.36), control: CGPoint(x: w * 0.69, y: h * 0.16))
                fan.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.72), control1: CGPoint(x: w * 0.85, y: h * 0.48), control2: CGPoint(x: w * 0.74, y: h * 0.64))
                fan.closeSubpath()
                ctx.fill(
                    fan,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "#E8BC52"), Color(hex: "#C98D26")]),
                        startPoint: CGPoint(x: w * 0.5, y: h * 0.2),
                        endPoint: CGPoint(x: w * 0.5, y: h * 0.74)
                    )
                )
                // Delicate fan veins
                for vx in [0.30, 0.40, 0.60, 0.70] {
                    var v = Path()
                    v.move(to: CGPoint(x: w * 0.50, y: h * 0.66))
                    v.addLine(to: CGPoint(x: w * vx, y: h * 0.32))
                    ctx.stroke(v, with: .color(Color(hex: "#9C6B16").opacity(0.45)), lineWidth: 0.9)
                }
                ctx.stroke(fan, with: .color(ink), lineWidth: 1.1)
                var stem = Path()
                stem.move(to: CGPoint(x: w * 0.50, y: h * 0.72))
                stem.addQuadCurve(to: CGPoint(x: w * 0.47, y: h * 0.88), control: CGPoint(x: w * 0.52, y: h * 0.80))
                ctx.stroke(stem, with: .color(Color(hex: "#7A583B")), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

            case "curio.dusk_sea_glass":
                // Frosted sea-green beach glass gem with sunlit inner glow
                var gem = Path()
                gem.move(to: CGPoint(x: w * 0.25, y: h * 0.34))
                gem.addQuadCurve(to: CGPoint(x: w * 0.73, y: h * 0.27), control: CGPoint(x: w * 0.50, y: h * 0.15))
                gem.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.68), control: CGPoint(x: w * 0.87, y: h * 0.50))
                gem.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.71), control: CGPoint(x: w * 0.48, y: h * 0.83))
                gem.closeSubpath()
                ctx.fill(
                    gem,
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: "#A5D6CE"), Color(hex: "#4C8E87")]),
                        center: CGPoint(x: w * 0.42, y: h * 0.42),
                        startRadius: 1,
                        endRadius: w * 0.38
                    )
                )
                ctx.stroke(gem, with: .color(.white.opacity(0.75)), lineWidth: 1.6)
                ctx.stroke(gem, with: .color(ink), lineWidth: 1.0)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.34, y: h * 0.36, width: w * 0.14, height: h * 0.08)), with: .color(.white.opacity(0.65)))

            case "curio.cedar_pinecone":
                // Layered cedar pinecone with warm amber highlights
                let cone = Path(ellipseIn: CGRect(x: w * 0.26, y: h * 0.18, width: w * 0.48, height: h * 0.64))
                ctx.fill(
                    cone,
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: "#A87B50"), Color(hex: "#734D2E")]),
                        center: CGPoint(x: w * 0.44, y: h * 0.36),
                        startRadius: 2,
                        endRadius: w * 0.36
                    )
                )
                for row in 0..<4 {
                    var arc = Path()
                    let y = h * (0.30 + CGFloat(row) * 0.12)
                    arc.move(to: CGPoint(x: w * 0.29, y: y))
                    arc.addQuadCurve(to: CGPoint(x: w * 0.71, y: y), control: CGPoint(x: w * 0.50, y: y + 5.5))
                    ctx.stroke(arc, with: .color(Color(hex: "#4A321E")), lineWidth: 1.2)
                }
                ctx.stroke(cone, with: .color(ink), lineWidth: 1.1)

            case "curio.tram_ticket":
                // Vintage Taiwan local railway cardboard stub with punch notch & stamp stripe
                let stub = Path(roundedRect: CGRect(x: w * 0.15, y: h * 0.27, width: w * 0.70, height: h * 0.46), cornerRadius: 3)
                ctx.fill(stub, with: .color(Color(hex: "#E4D7BC")))
                ctx.fill(Path(CGRect(x: w * 0.15, y: h * 0.27, width: w * 0.70, height: h * 0.12)), with: .color(AppTheme.clothBookmark.opacity(0.75)))
                ctx.stroke(stub, with: .color(ink), lineWidth: 1.1)
                // Conductor punch notch on right side
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.79, y: h * 0.45, width: w * 0.12, height: h * 0.12)), with: .color(Color(hex: "#EFE5D2")))
                var line = Path()
                line.move(to: CGPoint(x: w * 0.24, y: h * 0.50))
                line.addLine(to: CGPoint(x: w * 0.72, y: h * 0.50))
                line.move(to: CGPoint(x: w * 0.24, y: h * 0.62))
                line.addLine(to: CGPoint(x: w * 0.56, y: h * 0.62))
                ctx.stroke(line, with: .color(AppTheme.forestTeal), lineWidth: 1.4)

            case "curio.umbrella_ribbon":
                // Folded rain-blue tie ribbon + gleaming brass snap button
                let ribbon = Path(roundedRect: CGRect(x: w * 0.16, y: h * 0.36, width: w * 0.68, height: h * 0.28), cornerRadius: 6)
                ctx.fill(
                    ribbon,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "#5C838D"), Color(hex: "#3B5B64")]),
                        startPoint: CGPoint(x: 0, y: h * 0.36),
                        endPoint: CGPoint(x: 0, y: h * 0.64)
                    )
                )
                ctx.stroke(ribbon, with: .color(AppTheme.warmPaper.opacity(0.45)), style: StrokeStyle(lineWidth: 0.9, dash: [3, 2]))
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.62, y: h * 0.42, width: w * 0.16, height: h * 0.16)), with: .color(AppTheme.brassLight))
                ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.62, y: h * 0.42, width: w * 0.16, height: h * 0.16)), with: .color(ink), lineWidth: 0.9)
                ctx.stroke(ribbon, with: .color(ink), lineWidth: 1.1)

            case "curio.amber_ember_stone":
                let stone = Path(ellipseIn: CGRect(x: w * 0.20, y: h * 0.26, width: w * 0.60, height: h * 0.48))
                ctx.fill(stone, with: .radialGradient(Gradient(colors: [Color(hex: "#F6B46E"), Color(hex: "#C45B32")]), center: CGPoint(x: w * 0.42, y: h * 0.40), startRadius: 1, endRadius: w * 0.36))
                ctx.stroke(stone, with: .color(ink), lineWidth: 1.1)

            case "curio.origami_star":
                var star = Path()
                for i in 0..<10 {
                    let angle = Double(i) * .pi / 5.0 - .pi / 2.0
                    let r = (i % 2 == 0) ? w * 0.32 : w * 0.14
                    let pt = CGPoint(x: w * 0.5 + CGFloat(cos(angle)) * r, y: h * 0.5 + CGFloat(sin(angle)) * r)
                    if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
                }
                star.closeSubpath()
                ctx.fill(star, with: .color(Color(hex: "#323B46")))
                ctx.stroke(star, with: .color(Color(hex: "#E6C167")), lineWidth: 1.4)

            case "curio.wisp_marble":
                let orb = Path(ellipseIn: CGRect(x: w * 0.22, y: h * 0.22, width: w * 0.56, height: h * 0.56))
                ctx.fill(orb, with: .radialGradient(Gradient(colors: [Color(hex: "#C5B4F5"), Color(hex: "#6E5BA6"), Color(hex: "#3D3166")]), center: CGPoint(x: w * 0.40, y: h * 0.38), startRadius: 1, endRadius: w * 0.34))
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.33, y: h * 0.32, width: w * 0.14, height: h * 0.09)), with: .color(.white.opacity(0.75)))
                ctx.stroke(orb, with: .color(ink), lineWidth: 1.1)

            case "curio.cloud_feather":
                for dx in [-6.0, 0.0, 6.0] {
                    ctx.fill(Path(ellipseIn: CGRect(x: w * 0.5 + dx - 7, y: h * 0.32, width: 14, height: 14)), with: .color(.white.opacity(0.85)))
                }
                var stalk = Path()
                stalk.move(to: CGPoint(x: w * 0.50, y: h * 0.44))
                stalk.addLine(to: CGPoint(x: w * 0.50, y: h * 0.78))
                ctx.stroke(stalk, with: .color(Color(hex: "#8A959E")), lineWidth: 1.3)

            case "curio.fern_bookmark":
                var curl = Path()
                curl.move(to: CGPoint(x: w * 0.36, y: h * 0.78))
                curl.addCurve(to: CGPoint(x: w * 0.58, y: h * 0.26), control1: CGPoint(x: w * 0.34, y: h * 0.44), control2: CGPoint(x: w * 0.46, y: h * 0.24))
                curl.addArc(center: CGPoint(x: w * 0.58, y: h * 0.36), radius: w * 0.10, startAngle: .degrees(-90), endAngle: .degrees(160), clockwise: false)
                ctx.stroke(curl, with: .color(Color(hex: "#497C57")), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))

            case "curio.brass_button":
                let btn = Path(ellipseIn: CGRect(x: w * 0.22, y: h * 0.22, width: w * 0.56, height: h * 0.56))
                ctx.fill(btn, with: .radialGradient(Gradient(colors: [Color(hex: "#F2D485"), Color(hex: "#B58534")]), center: CGPoint(x: w * 0.40, y: h * 0.36), startRadius: 1, endRadius: w * 0.35))
                ctx.stroke(btn, with: .color(ink), lineWidth: 1.1)
                for (hx, hy) in [(0.42, 0.44), (0.58, 0.44), (0.42, 0.58), (0.58, 0.58)] {
                    ctx.fill(Path(ellipseIn: CGRect(x: w * hx - 1.5, y: h * hy - 1.5, width: 3, height: 3)), with: .color(Color(hex: "#5E4215")))
                }

            case "curio.bat_pod_seed":
                var wing = Path()
                wing.move(to: CGPoint(x: w * 0.50, y: h * 0.68))
                wing.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.30), control: CGPoint(x: w * 0.24, y: h * 0.56))
                wing.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.46), control: CGPoint(x: w * 0.36, y: h * 0.24))
                wing.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.30), control: CGPoint(x: w * 0.64, y: h * 0.24))
                wing.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.68), control: CGPoint(x: w * 0.76, y: h * 0.56))
                ctx.fill(wing, with: .color(Color(hex: "#726186")))
                ctx.stroke(wing, with: .color(ink), lineWidth: 1.0)

            case "curio.porcelain_shard":
                var shard = Path()
                shard.move(to: CGPoint(x: w * 0.24, y: h * 0.36))
                shard.addQuadCurve(to: CGPoint(x: w * 0.74, y: h * 0.28), control: CGPoint(x: w * 0.52, y: h * 0.20))
                shard.addLine(to: CGPoint(x: w * 0.66, y: h * 0.72))
                shard.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.36), control: CGPoint(x: w * 0.36, y: h * 0.74))
                ctx.fill(shard, with: .color(Color(hex: "#EEF5F5")))
                var glaze = Path()
                glaze.move(to: CGPoint(x: w * 0.34, y: h * 0.44))
                glaze.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.42), control: CGPoint(x: w * 0.48, y: h * 0.58))
                ctx.stroke(glaze, with: .color(Color(hex: "#3E6F82")), lineWidth: 2.0)
                ctx.stroke(shard, with: .color(ink), lineWidth: 1.0)

            default:
                // Fragrant Taiwan cypress sprig with layered needles
                var twig = Path()
                twig.move(to: CGPoint(x: w * 0.24, y: h * 0.78))
                twig.addQuadCurve(to: CGPoint(x: w * 0.74, y: h * 0.22), control: CGPoint(x: w * 0.48, y: h * 0.48))
                ctx.stroke(twig, with: .color(Color(hex: "#456B4E")), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                for idx in 0..<5 {
                    let frac = CGFloat(idx) * 0.13 + 0.26
                    let px = w * frac
                    let py = h * (1.0 - frac)
                    ctx.fill(Path(ellipseIn: CGRect(x: px - 6, y: py - 3, width: 12, height: 6)), with: .color(idx % 2 == 0 ? Color(hex: "#588A62") : Color(hex: "#72A27A")))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

/// Interactive 24h Steaming Ginger Tea Foreground Tray (`treat.ginger_tea`) for the 2.5D Sunroom!
struct SteamingGingerTeaTrayView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            TimelineView(.animation(minimumInterval: AppTheme.Motion.interval(fps: 24.0, reduceMotion: reduceMotion))) { timeline in
                let t = reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    let w = size.width, h = size.height
                    let ink = Color(hex: "#2C3536").opacity(0.78)

                    // Soft wooden serving tray
                    let tray = Path(roundedRect: CGRect(x: w * 0.08, y: h * 0.64, width: w * 0.84, height: h * 0.26), cornerRadius: 9)
                    ctx.fill(
                        tray,
                        with: .linearGradient(
                            Gradient(colors: [Color(hex: "#BA8A58"), Color(hex: "#8E6036")]),
                            startPoint: CGPoint(x: 0, y: h * 0.64),
                            endPoint: CGPoint(x: 0, y: h * 0.90)
                        )
                    )
                    ctx.stroke(tray, with: .color(ink), lineWidth: 1.2)

                    // Celadon ceramic teapot body
                    let pot = Path(ellipseIn: CGRect(x: w * 0.20, y: h * 0.34, width: w * 0.36, height: h * 0.38))
                    ctx.fill(
                        pot,
                        with: .radialGradient(
                            Gradient(colors: [Color(hex: "#8BB0B4"), Color(hex: "#4B7478")]),
                            center: CGPoint(x: w * 0.34, y: h * 0.44),
                            startRadius: 2,
                            endRadius: w * 0.24
                        )
                    )
                    ctx.stroke(pot, with: .color(ink), lineWidth: 1.2)
                    // Lid knob
                    ctx.fill(Path(ellipseIn: CGRect(x: w * 0.34, y: h * 0.29, width: w * 0.08, height: h * 0.08)), with: .color(Color(hex: "#DFC394")))
                    ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.34, y: h * 0.29, width: w * 0.08, height: h * 0.08)), with: .color(ink), lineWidth: 1.0)
                    // Spout
                    var spout = Path()
                    spout.move(to: CGPoint(x: w * 0.54, y: h * 0.50))
                    spout.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.38), control: CGPoint(x: w * 0.61, y: h * 0.48))
                    ctx.stroke(spout, with: .color(Color(hex: "#4B7478")), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))

                    // Warm ginger teacup on right side of tray
                    let cup = Path(roundedRect: CGRect(x: w * 0.64, y: h * 0.48, width: w * 0.18, height: h * 0.22), cornerRadius: 5)
                    ctx.fill(cup, with: .color(Color(hex: "#F5EAD4")))
                    ctx.fill(Path(ellipseIn: CGRect(x: w * 0.66, y: h * 0.47, width: w * 0.14, height: h * 0.06)), with: .color(Color(hex: "#D69445")))
                    ctx.stroke(cup, with: .color(ink), lineWidth: 1.1)

                    // Rising watercolor steam wisps
                    for idx in 0..<3 {
                        let phase = (t * 0.42 + Double(idx) * 0.33).truncatingRemainder(dividingBy: 1.0)
                        let baseX = idx == 2 ? w * 0.73 : w * (0.36 + Double(idx) * 0.08)
                        let riseY = h * 0.32 - CGFloat(phase) * h * 0.28
                        let drift = CGFloat(sin(t * 1.4 + Double(idx) * 2.1)) * 4.0
                        let alpha = sin(phase * .pi) * 0.62
                        var wisp = Path()
                        wisp.move(to: CGPoint(x: baseX, y: riseY + 8))
                        wisp.addQuadCurve(to: CGPoint(x: baseX + drift, y: riseY - 6), control: CGPoint(x: baseX - drift, y: riseY))
                        ctx.stroke(wisp, with: .color(Color.white.opacity(alpha)), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                    }
                }
                .frame(width: 108, height: 74)
            }
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.94, pressOffsetY: 1))
        .accessibilityLabel("雨天暖薑茶盤，點擊品茶")
    }
}

// MARK: - 3. Ultra-Detailed Painterly Taiwanese Bakery Sidewalk Scene
struct TaiwaneseBakeryStorybookBackdrop: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let weather: WeatherMode
    var isStatic: Bool = false

    var body: some View {
        Group {
            if let uiBg = UIImage(named: "bg_street_bakery_corner") {
                GeometryReader { geo in
                    ZStack {
                        Image(uiImage: uiBg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .overlay(bakeryWeatherWash)

                        if isStatic {
                            bakeryAtmosphereOverlay(time: 1.0)
                        } else {
                            TimelineView(.animation(minimumInterval: AppTheme.Motion.interval(fps: 30.0, reduceMotion: reduceMotion))) { timeline in
                                bakeryAtmosphereOverlay(time: reduceMotion ? 1.0 : timeline.date.timeIntervalSinceReferenceDate)
                            }
                        }
                    }
                }
            } else if isStatic {
                sceneCanvas(time: 1.0)
            } else {
                TimelineView(.animation(minimumInterval: AppTheme.Motion.interval(fps: 30.0, reduceMotion: reduceMotion))) { timeline in
                    sceneCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
    }

    @ViewBuilder
    private var bakeryWeatherWash: some View {
        switch weather {
        case .clearMorning:
            LinearGradient(
                colors: [Color(hex: "#FFF9E8").opacity(0.10), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
        case .overcast:
            Color(hex: "#D5DFDF").opacity(0.22)
                .blendMode(.multiply)
        case .lightRain, .postRain:
            LinearGradient(
                colors: [Color(hex: "#9BB5C6").opacity(0.26), Color(hex: "#849EAE").opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)
        case .dusk:
            LinearGradient(
                colors: [Color(hex: "#C97D4E").opacity(0.28), Color(hex: "#E5AF72").opacity(0.20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)
        }
    }

    @ViewBuilder
    private func bakeryAtmosphereOverlay(time: Double) -> some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let groundTop = h * 0.56

            // 1. Warm bakery display window glow (stronger at dusk & rainy days)
            let windowGlowAlpha: Double = {
                switch weather {
                case .dusk: return 0.36
                case .lightRain: return 0.24
                case .postRain, .overcast: return 0.16
                case .clearMorning: return 0.11
                }
            }()
            let windowCenter = CGPoint(x: w * 0.58, y: h * 0.34)
            let windowRadius = max(w, h) * 0.36
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: windowCenter.x - windowRadius,
                    y: windowCenter.y - windowRadius * 0.72,
                    width: windowRadius * 2,
                    height: windowRadius * 1.44
                )),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(hex: "#FFE7A8").opacity(windowGlowAlpha),
                        Color(hex: "#F2A846").opacity(windowGlowAlpha * 0.42),
                        .clear
                    ]),
                    center: windowCenter,
                    startRadius: 8,
                    endRadius: windowRadius
                )
            )

            // 2. Swaying glowing amber paper lantern halo (left eave)
            let sway = CGFloat(sin(time * 1.15)) * 4.5
            let pulse = 0.88 + 0.12 * sin(time * 2.1)
            let lx = w * 0.17 + sway
            let ly = h * 0.19
            let glowR: CGFloat = (weather == .dusk ? 132 : (weather.isRainy ? 104 : 88)) * CGFloat(pulse)
            let lanternAlpha: Double = weather == .dusk ? 0.54 : (weather.isRainy ? 0.42 : 0.30)
            ctx.fill(
                Path(ellipseIn: CGRect(x: lx - glowR, y: ly - glowR, width: glowR * 2, height: glowR * 2)),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(hex: "#FFF0B8").opacity(lanternAlpha),
                        Color(hex: "#F4AE4B").opacity(lanternAlpha * 0.45),
                        .clear
                    ]),
                    center: CGPoint(x: lx, y: ly),
                    startRadius: 6,
                    endRadius: glowR
                )
            )

            // Soft lantern warmth spilling onto mossy cobblestones below
            ctx.fill(
                Path(ellipseIn: CGRect(x: lx - 62, y: groundTop + 18, width: 148, height: 34)),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(hex: "#F5C062").opacity(weather.isRainy || weather == .dusk ? 0.30 : 0.14),
                        Color(hex: "#F2B85B").opacity(0.08),
                        .clear
                    ]),
                    center: CGPoint(x: lx + 12, y: groundTop + 35),
                    startRadius: 4,
                    endRadius: 72
                )
            )

            // 3. Weather-responsive particles: rain streaks + puddle ripples OR drifting osmanthus petals
            if weather.isRainy {
                let streakCount = weather == .lightRain ? 48 : 24
                for i in 0..<streakCount {
                    let xBase = CGFloat((i * 47 + 13) % Int(max(1, w)))
                    let speed = weather == .lightRain ? 210.0 : 155.0
                    let yOff = CGFloat((time * speed + Double(i * 41)).truncatingRemainder(dividingBy: Double(max(1, h))))
                    var drop = Path()
                    drop.move(to: CGPoint(x: xBase, y: yOff))
                    drop.addLine(to: CGPoint(x: xBase + 7, y: yOff + 28))
                    ctx.stroke(
                        drop,
                        with: .color(Color(hex: "#EDF5FA").opacity(weather == .lightRain ? 0.44 : 0.28)),
                        style: StrokeStyle(lineWidth: 1.15, lineCap: .round)
                    )
                }

                // Expanding watercolor puddle ripples on the cobblestone sidewalk (y >= 0.56)
                for rIdx in 0..<5 {
                    let phase = (time * 0.62 + Double(rIdx) * 0.21).truncatingRemainder(dividingBy: 1.0)
                    let rx = w * (0.14 + CGFloat(rIdx) * 0.18)
                    let ry = groundTop + 28 + CGFloat((rIdx * 19) % 44)
                    let radW = CGFloat(phase) * 36 + 6
                    let radH = radW * 0.28
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: rx - radW, y: ry - radH, width: radW * 2, height: radH * 2)),
                        with: .color(Color(hex: "#EEF6FA").opacity((1.0 - phase) * 0.46)),
                        lineWidth: 1.15
                    )
                }
            } else {
                // Soft warm upper-left sunbeam glow on clear morning & dusk
                if weather == .clearMorning || weather == .dusk {
                    var beam = Path()
                    beam.move(to: CGPoint(x: 0, y: 0))
                    beam.addLine(to: CGPoint(x: w * 0.48, y: 0))
                    beam.addLine(to: CGPoint(x: w * 0.92, y: h * 0.68))
                    beam.addLine(to: CGPoint(x: w * 0.20, y: h * 0.68))
                    beam.closeSubpath()
                    ctx.fill(
                        beam,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(hex: weather == .dusk ? "#FFD796" : "#FFFDF0").opacity(0.16),
                                .clear
                            ]),
                            startPoint: CGPoint(x: w * 0.12, y: 0),
                            endPoint: CGPoint(x: w * 0.66, y: h * 0.68)
                        )
                    )
                }

                // Drifting golden osmanthus petals
                let petalCount = weather == .overcast ? 5 : 11
                for i in 0..<petalCount {
                    let phase = (time * 0.13 + Double(i) * 0.16).truncatingRemainder(dividingBy: 1.0)
                    let px = w * (0.06 + CGFloat((i * 29) % 88) / 100.0)
                        + CGFloat(phase) * 28
                        + CGFloat(sin(time * 1.15 + Double(i))) * 14
                    let py = h * 0.10 + CGFloat(phase) * h * 0.74
                    let alpha = sin(phase * .pi) * (weather == .overcast ? 0.42 : 0.72)
                    let petalColor = weather == .dusk ? Color(hex: "#F7C568") : Color(hex: "#FFF1B8")
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px, y: py, width: 6.5, height: 4.2)),
                        with: .color(petalColor.opacity(alpha))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func sceneCanvas(time: Double) -> some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let ink = Color(hex: "#2C3536").opacity(0.68)

            // 1. Translucent watercolor sky wash + soft distant Taiwanese hills
            let skyColors: [Color] = {
                switch weather {
                case .lightRain, .postRain: return [Color(hex: "#8FAAB7"), Color(hex: "#CBD8D9"), Color(hex: "#EAE6DC")]
                case .dusk:                 return [Color(hex: "#CC8258"), Color(hex: "#E9BE8C"), Color(hex: "#F2DEC0")]
                case .clearMorning:         return [Color(hex: "#C5DFD8"), Color(hex: "#ECEAD8"), Color(hex: "#FAF6EE")]
                case .overcast:             return [Color(hex: "#C0C8C7"), Color(hex: "#DFE1DA"), Color(hex: "#EFECE3")]
                }
            }()
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(Gradient(colors: skyColors), startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.64))
            )

            // Soft misty distant mountain silhouette & old-street neighbor roofs on left
            var mountain = Path()
            mountain.move(to: CGPoint(x: 0, y: h * 0.42))
            mountain.addQuadCurve(to: CGPoint(x: w * 0.34, y: h * 0.36), control: CGPoint(x: w * 0.14, y: h * 0.25))
            mountain.addLine(to: CGPoint(x: w * 0.34, y: h * 0.62))
            mountain.addLine(to: CGPoint(x: 0, y: h * 0.62))
            mountain.closeSubpath()
            ctx.fill(mountain, with: .color(Color(hex: "#7E9A96").opacity(0.24)))

            // 2. Layered watercolor street trees on left side (with swaying leaf clusters)
            let treeSway = CGFloat(sin(time * 0.9)) * 2.5
            ctx.fill(Path(ellipseIn: CGRect(x: -w * 0.24 + treeSway, y: h * 0.24, width: w * 0.56, height: h * 0.34)), with: .color(Color(hex: "#6B8C72").opacity(0.36)))
            ctx.fill(Path(ellipseIn: CGRect(x: -w * 0.14 - treeSway * 0.6, y: h * 0.34, width: w * 0.44, height: h * 0.26)), with: .color(Color(hex: "#52745A").opacity(0.30)))
            // Tiny golden sunlit leaf flecks
            if !weather.isRainy {
                for i in 0..<6 {
                    let fx = w * (0.02 + CGFloat(i) * 0.04) + treeSway
                    let fy = h * (0.31 + CGFloat((i * 19) % 14) / 100.0)
                    ctx.fill(Path(ellipseIn: CGRect(x: fx, y: fy, width: 10, height: 6)), with: .color(Color(hex: "#DCE3AE").opacity(0.38)))
                }
            }

            // 3. Warm wooden bakery storefront & glowing display windows
            let shopLeft = w * 0.17
            let shopTop = h * 0.13
            let shopRect = CGRect(x: shopLeft, y: shopTop, width: w * 0.87, height: h * 0.50)
            ctx.fill(
                Path(shopRect),
                with: .linearGradient(
                    Gradient(colors: weather == .dusk
                             ? [Color(hex: "#FFE7B8"), Color(hex: "#F2CB8D")]
                             : [Color(hex: "#FFF6DE"), Color(hex: "#F2DCBA")]),
                    startPoint: CGPoint(x: shopRect.midX, y: shopRect.minY),
                    endPoint: CGPoint(x: shopRect.midX, y: shopRect.maxY)
                )
            )

            // Interior warm hanging pendant lamps inside bakery window
            for pIdx in 0..<2 {
                let px = shopLeft + shopRect.width * (0.26 + CGFloat(pIdx) * 0.42)
                let py = shopTop + shopRect.height * 0.22
                var wire = Path()
                wire.move(to: CGPoint(x: px, y: shopTop))
                wire.addLine(to: CGPoint(x: px, y: py))
                ctx.stroke(wire, with: .color(AppTheme.timberDeep.opacity(0.6)), lineWidth: 1.4)
                // Warm pool of pendant light
                ctx.fill(
                    Path(ellipseIn: CGRect(x: px - 54, y: py - 20, width: 108, height: 108)),
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: "#FFF2B2").opacity(0.45), .clear]),
                        center: CGPoint(x: px, y: py + 12),
                        startRadius: 4,
                        endRadius: 54
                    )
                )
                var shade = Path()
                shade.move(to: CGPoint(x: px - 14, y: py + 8))
                shade.addQuadCurve(to: CGPoint(x: px + 14, y: py + 8), control: CGPoint(x: px, y: py - 10))
                shade.closeSubpath()
                ctx.fill(shade, with: .color(Color(hex: "#395D60")))
                ctx.fill(Path(ellipseIn: CGRect(x: px - 5, y: py + 5, width: 10, height: 8)), with: .color(Color(hex: "#FFFCE0")))
            }

            // Bakery cedar display shelves with scored artisan loaves & brass-lid cookie jars
            let shelfY1 = shopTop + shopRect.height * 0.40
            let shelfY2 = shopTop + shopRect.height * 0.59
            ctx.fill(Path(CGRect(x: shopLeft + 18, y: shelfY1, width: shopRect.width - 30, height: 7)), with: .color(AppTheme.timberWarm.opacity(0.85)))
            ctx.fill(Path(CGRect(x: shopLeft + 18, y: shelfY2, width: shopRect.width - 30, height: 7)), with: .color(AppTheme.timberWarm.opacity(0.85)))

            for idx in 0..<4 {
                let lx = shopLeft + 40 + CGFloat(idx) * 68
                let loafRect = CGRect(x: lx, y: shelfY1 - 24, width: 52, height: 26)
                let loaf = Path(ellipseIn: loafRect)
                ctx.fill(
                    loaf,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "#E5B472"), Color(hex: "#BD8042")]),
                        startPoint: CGPoint(x: lx, y: loafRect.minY),
                        endPoint: CGPoint(x: lx, y: loafRect.maxY)
                    )
                )
                // Baker's slash score marks on crust
                for sIdx in 0..<3 {
                    var score = Path()
                    let sx = lx + 14 + CGFloat(sIdx) * 11
                    score.move(to: CGPoint(x: sx, y: loafRect.minY + 4))
                    score.addLine(to: CGPoint(x: sx - 4, y: loafRect.minY + 12))
                    ctx.stroke(score, with: .color(Color(hex: "#FFF0D0").opacity(0.75)), lineWidth: 1.2)
                }
                ctx.stroke(loaf, with: .color(ink.opacity(0.45)), lineWidth: 1.0)

                // Glass cookie jars with brass lids on lower shelf
                let jarRect = CGRect(x: lx + 9, y: shelfY2 - 34, width: 32, height: 34)
                let jar = Path(roundedRect: jarRect, cornerRadius: 6)
                ctx.fill(jar, with: .color(Color(hex: "#EAF0EF").opacity(0.68)))
                ctx.fill(Path(roundedRect: CGRect(x: lx + 13, y: shelfY2 - 19, width: 24, height: 17), cornerRadius: 4), with: .color(Color(hex: "#B58354").opacity(0.62)))
                ctx.fill(Path(roundedRect: CGRect(x: lx + 11, y: shelfY2 - 38, width: 28, height: 6), cornerRadius: 2), with: .color(AppTheme.brassLight))
                ctx.stroke(jar, with: .color(ink.opacity(0.42)), lineWidth: 1.0)
            }

            // Timber window mullions, lower cedar wainscoting & potted windowsill rosemary
            let wainscotTop = shopTop + shopRect.height * 0.72
            ctx.fill(
                Path(CGRect(x: shopLeft, y: wainscotTop, width: shopRect.width, height: shopRect.maxY - wainscotTop)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#BB8D5F"), Color(hex: "#9B6D43")]),
                    startPoint: CGPoint(x: 0, y: wainscotTop),
                    endPoint: CGPoint(x: 0, y: shopRect.maxY)
                )
            )
            for slat in 0..<11 {
                let sx = shopLeft + CGFloat(slat) * 30
                var line = Path()
                line.move(to: CGPoint(x: sx, y: wainscotTop))
                line.addLine(to: CGPoint(x: sx, y: shopRect.maxY))
                ctx.stroke(line, with: .color(AppTheme.timberDeep.opacity(0.32)), lineWidth: 1.0)
            }
            // Main cedar pillars & horizontal sill
            ctx.fill(Path(CGRect(x: shopLeft - 4, y: shopTop, width: 22, height: shopRect.height)), with: .color(Color(hex: "#966A41")))
            ctx.stroke(Path(CGRect(x: shopLeft - 4, y: shopTop, width: 22, height: shopRect.height)), with: .color(ink), lineWidth: 1.2)
            ctx.fill(Path(CGRect(x: shopLeft + shopRect.width * 0.44, y: shopTop, width: 14, height: shopRect.height)), with: .color(Color(hex: "#966A41")))
            ctx.fill(Path(CGRect(x: shopLeft, y: wainscotTop - 7, width: shopRect.width, height: 11)), with: .color(Color(hex: "#8A5E38")))

            // Terracotta potted herbs resting on the wooden window sill
            let potX = shopLeft + shopRect.width * 0.62
            let potY = wainscotTop - 25
            for leafIdx in -2...2 {
                let lx = potX + 14 + CGFloat(leafIdx) * 5
                ctx.fill(Path(ellipseIn: CGRect(x: lx - 5, y: potY - 12 - CGFloat(abs(leafIdx)) * 1.5, width: 10, height: 18)), with: .color(leafIdx % 2 == 0 ? Color(hex: "#4F7D56") : Color(hex: "#67966B")))
            }
            let herbPot = Path(roundedRect: CGRect(x: potX, y: potY, width: 28, height: 20), cornerRadius: 4)
            ctx.fill(herbPot, with: .color(AppTheme.pawInRange))
            ctx.stroke(herbPot, with: .color(ink), lineWidth: 1.1)

            // 4. Hand-drawn Taiwanese timber roof eaves & curved dark ceramic roof tiles
            let eaveH = h * 0.115
            ctx.fill(
                Path(CGRect(x: 0, y: 0, width: w, height: eaveH)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#585A5B"), Color(hex: "#3E4345")]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: eaveH)
                )
            )
            // Scalloped ceramic roof tile ribs & damp highlight
            let tileW = w / 11.0
            for col in 0..<12 {
                let rx = CGFloat(col) * tileW
                var rib = Path()
                rib.move(to: CGPoint(x: rx + 12, y: 0))
                rib.addLine(to: CGPoint(x: rx, y: eaveH - 9))
                ctx.stroke(rib, with: .color(Color.white.opacity(weather.isRainy ? 0.24 : 0.14)), lineWidth: 1.4)
                ctx.fill(Path(ellipseIn: CGRect(x: rx - 4, y: eaveH - 15, width: tileW * 0.85, height: 12)), with: .color(Color(hex: "#2F3537")))
            }
            ctx.fill(Path(CGRect(x: 0, y: eaveH - 8, width: w, height: 9)), with: .color(Color(hex: "#7D5432")))

            // 5. Gently swaying Forest-Teal Bakery Noren (暖簾) with cream paw/wheat crest
            let breeze = sin(time * 1.4) * 3.5
            let panelCount = 5
            let panelW = (w - shopLeft - 14) / CGFloat(panelCount)
            for idx in 0..<panelCount {
                let px = shopLeft + 10 + CGFloat(idx) * panelW
                var flap = Path()
                flap.move(to: CGPoint(x: px + 2, y: eaveH))
                flap.addLine(to: CGPoint(x: px + panelW - 3, y: eaveH))
                flap.addQuadCurve(
                    to: CGPoint(x: px + panelW - 3 + CGFloat(breeze), y: eaveH + 66),
                    control: CGPoint(x: px + panelW - 2 + CGFloat(breeze * 0.5), y: eaveH + 34)
                )
                flap.addLine(to: CGPoint(x: px + 2 + CGFloat(breeze), y: eaveH + 66))
                flap.closeSubpath()
                ctx.fill(
                    flap,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "#276267"), Color(hex: "#194347")]),
                        startPoint: CGPoint(x: px, y: eaveH),
                        endPoint: CGPoint(x: px, y: eaveH + 66)
                    )
                )
                // Delicate white cloth crest circle on center noren panels
                if idx == 1 || idx == 3 {
                    let cx = px + panelW * 0.5 + CGFloat(breeze * 0.55)
                    let cy = eaveH + 34
                    ctx.stroke(Path(ellipseIn: CGRect(x: cx - 10, y: cy - 10, width: 20, height: 20)), with: .color(AppTheme.warmPaper.opacity(0.65)), lineWidth: 1.2)
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - 3, y: cy - 3, width: 6, height: 6)), with: .color(AppTheme.warmPaper.opacity(0.75)))
                }
                ctx.stroke(flap, with: .color(ink), lineWidth: 1.1)
            }

            // Hanging cedar wooden shop plaque tucked on right eave
            let signRect = CGRect(x: w - 42, y: eaveH + 74, width: 24, height: 68)
            ctx.fill(Path(roundedRect: signRect, cornerRadius: 4), with: .color(Color(hex: "#B58353")))
            ctx.stroke(Path(roundedRect: signRect, cornerRadius: 4), with: .color(ink), lineWidth: 1.1)
            ctx.draw(Text("巷\n口\n麵\n包").font(.system(size: 10, weight: .bold, design: .serif)).foregroundStyle(AppTheme.deepPineInk), at: CGPoint(x: signRect.midX, y: signRect.midY))

            // 6. Swaying glowing Taiwanese Amber Paper Lantern
            let lanternSwing = sin(time * 1.1) * 2.5
            let lx = shopLeft - 18 + CGFloat(lanternSwing)
            let ly = eaveH + 56
            var cord = Path()
            cord.move(to: CGPoint(x: shopLeft - 18, y: eaveH))
            cord.addLine(to: CGPoint(x: lx, y: ly - 32))
            ctx.stroke(cord, with: .color(AppTheme.timberDeep), lineWidth: 2.0)

            let glowR: CGFloat = weather == .dusk ? 112 : 82
            ctx.fill(
                Path(ellipseIn: CGRect(x: lx - glowR, y: ly - glowR, width: glowR * 2, height: glowR * 2)),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: "#FFE9A3").opacity(0.50), Color(hex: "#F2A846").opacity(0.18), .clear]),
                    center: CGPoint(x: lx, y: ly),
                    startRadius: 6,
                    endRadius: glowR
                )
            )
            let lanternRect = CGRect(x: lx - 28, y: ly - 32, width: 56, height: 64)
            ctx.fill(
                Path(ellipseIn: lanternRect),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: "#FFFBE0"), Color(hex: "#F4AE4B"), Color(hex: "#C76D2A")]),
                    center: CGPoint(x: lx, y: ly),
                    startRadius: 4,
                    endRadius: 34
                )
            )
            for ry in [-14.0, 0.0, 14.0] {
                var rib = Path()
                rib.move(to: CGPoint(x: lx - 24, y: ly + ry))
                rib.addQuadCurve(to: CGPoint(x: lx + 24, y: ly + ry), control: CGPoint(x: lx, y: ly + ry + 5))
                ctx.stroke(rib, with: .color(Color(hex: "#8F4A1E").opacity(0.45)), lineWidth: 1.0)
            }
            ctx.stroke(Path(ellipseIn: lanternRect), with: .color(ink), lineWidth: 1.2)
            ctx.fill(Path(roundedRect: CGRect(x: lx - 12, y: ly - 35, width: 24, height: 6), cornerRadius: 2), with: .color(AppTheme.timberDeep))
            ctx.fill(Path(roundedRect: CGRect(x: lx - 11, y: ly + 29, width: 22, height: 6), cornerRadius: 2), with: .color(AppTheme.timberDeep))

            // 7. Hand-Tinted Cobblestone Flagstones & Rustic Wooden Stool
            let groundTop = h * 0.56
            ctx.fill(
                Path(CGRect(x: 0, y: groundTop, width: w, height: h - groundTop)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#D5CEC0"), Color(hex: "#B2ADA3"), Color(hex: "#8E9390")]),
                    startPoint: CGPoint(x: 0, y: groundTop),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )
            // Flagstone paving grid with gentle moss seams
            for row in 0..<4 {
                let y = groundTop + CGFloat(row) * 52
                var hLine = Path()
                hLine.move(to: CGPoint(x: 0, y: y))
                hLine.addLine(to: CGPoint(x: w, y: y))
                ctx.stroke(hLine, with: .color(ink.opacity(0.24)), lineWidth: 1.3)
                for col in 0..<5 {
                    let xOff = (row % 2 == 0) ? 0 : 38
                    let x = CGFloat(col) * 92 + CGFloat(xOff)
                    var vLine = Path()
                    vLine.move(to: CGPoint(x: x, y: y))
                    vLine.addLine(to: CGPoint(x: x - 10, y: y + 52))
                    ctx.stroke(vLine, with: .color(ink.opacity(0.18)), lineWidth: 1.1)
                }
            }

            // Warm amber lantern puddle reflection on wet stone
            ctx.fill(
                Path(ellipseIn: CGRect(x: lx - 54, y: groundTop + 22, width: 122, height: 28)),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: "#F5C062").opacity(0.36), Color(hex: "#F2B85B").opacity(0.12), .clear]),
                    center: CGPoint(x: lx + 6, y: groundTop + 36),
                    startRadius: 4,
                    endRadius: 62
                )
            )

            // Rustic Wooden Stool tucked on right edge
            let stoolX = w * 0.79
            let stoolY = groundTop + 14
            ctx.fill(Path(ellipseIn: CGRect(x: stoolX - 30, y: stoolY + 36, width: 60, height: 12)), with: .color(AppTheme.deepPineInk.opacity(0.18)))
            var leg1 = Path(); leg1.move(to: CGPoint(x: stoolX - 18, y: stoolY)); leg1.addLine(to: CGPoint(x: stoolX - 24, y: stoolY + 42))
            var leg2 = Path(); leg2.move(to: CGPoint(x: stoolX + 18, y: stoolY)); leg2.addLine(to: CGPoint(x: stoolX + 24, y: stoolY + 42))
            ctx.stroke(leg1, with: .color(Color(hex: "#7D5432")), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            ctx.stroke(leg2, with: .color(Color(hex: "#7D5432")), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            let seat = Path(roundedRect: CGRect(x: stoolX - 28, y: stoolY - 8, width: 56, height: 13), cornerRadius: 5)
            ctx.fill(seat, with: .color(Color(hex: "#BA8958")))
            ctx.stroke(seat, with: .color(ink), lineWidth: 1.2)

            // 8. Rain streaks + ripples (rainy) OR drifting golden osmanthus petals (clear/dusk)
            if weather.isRainy {
                for i in 0..<46 {
                    let xBase = CGFloat((i * 43) % Int(max(1, w)))
                    let yOff = CGFloat((time * 185 + Double(i * 37)).truncatingRemainder(dividingBy: Double(max(1, h))))
                    var drop = Path()
                    drop.move(to: CGPoint(x: xBase, y: yOff))
                    drop.addLine(to: CGPoint(x: xBase - 9, y: yOff + 26))
                    ctx.stroke(drop, with: .color(AppTheme.warmPaper.opacity(0.45)), lineWidth: 1.1)
                }
                for rIdx in 0..<4 {
                    let phase = (time * 0.65 + Double(rIdx) * 0.25).truncatingRemainder(dividingBy: 1.0)
                    let rx = w * (0.16 + CGFloat(rIdx) * 0.23)
                    let ry = groundTop + 36 + CGFloat(rIdx % 2) * 26
                    let radW = CGFloat(phase) * 34 + 6
                    let radH = radW * 0.28
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: rx - radW, y: ry - radH, width: radW * 2, height: radH * 2)),
                        with: .color(AppTheme.warmPaper.opacity((1.0 - phase) * 0.45)),
                        lineWidth: 1.1
                    )
                }
            } else {
                // Soft drifting golden osmanthus petals
                for i in 0..<9 {
                    let phase = (time * 0.14 + Double(i) * 0.17).truncatingRemainder(dividingBy: 1.0)
                    let px = w * (0.08 + CGFloat((i * 31) % 86) / 100.0) + CGFloat(sin(time * 1.1 + Double(i))) * 18
                    let py = h * 0.12 + CGFloat(phase) * h * 0.72
                    let alpha = sin(phase * .pi) * 0.65
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px, y: py, width: 6, height: 4)),
                        with: .color(Color(hex: weather == .dusk ? "#F7CB73" : "#FFF3C4").opacity(alpha))
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
        .buttonStyle(TactileGameButtonStyle())
        .accessibilityLabel("打開藤編玩具籃")
    }
}

struct CeramicTeapotCornerButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isSteaming: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                TimelineView(.animation(minimumInterval: AppTheme.Motion.interval(fps: 20.0, reduceMotion: reduceMotion))) { timeline in
                    let t = reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate
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
        .buttonStyle(TactileGameButtonStyle())
        .accessibilityLabel("打開陶瓷茶壺與散步夥伴抽屜")
    }
}

// MARK: - 5. Sunroom window light, dust, rain and curtain folds
struct SunroomAmbientLayers: View {
    let weather: WeatherMode
    let date: Date
    let reduceMotion: Bool

    private var atmosphere: (rain: Float, light: Float, dusk: Float) {
        switch weather {
        case .clearMorning: return (0, 1, 0)
        case .overcast: return (0, 0.28, 0)
        case .lightRain: return (1, 0.12, 0)
        case .postRain: return (0.38, 0.57, 0)
        case .dusk: return (0, 0.64, 1)
        }
    }

    var body: some View {
        let time = reduceMotion ? 0 : date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000)
        let weather = atmosphere
        ZStack {
            Rectangle()
                .fill(.white)
                .colorEffect(ShaderLibrary.sunroomAmbient(
                    .boundingRect, .float(time), .float(weather.rain), .float(weather.light), .float(weather.dusk)
                ))
                .id(self.weather)
                .transition(.opacity)
        }
        .animation(reduceMotion ? AppTheme.Motion.reduced : .easeInOut(duration: AppTheme.Motion.relaxed),
                   value: self.weather)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - 6. Tactile Care Cozy Sunlit Cedar Floor, Dappled Leaves & Hand-Braided Rug Backdrop
struct TactileCareFloorBackdrop: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let weather: WeatherMode

    var body: some View {
        Group {
            if let uiBg = UIImage(named: "bg_tactile_care_nook") {
                GeometryReader { geo in
                    ZStack {
                        Image(uiImage: uiBg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .overlay(careWeatherTint)

                        TimelineView(.animation(minimumInterval: AppTheme.Motion.interval(fps: 20.0, reduceMotion: reduceMotion))) { timeline in
                            careSunlightOverlay(time: reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate)
                        }
                    }
                }
            } else {
                fallbackCanvas
            }
        }
    }

    @ViewBuilder
    private func careSunlightOverlay(time t: Double) -> some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            if !weather.isRainy {
                // Subtle swaying dappled sunlight from upper-left -> lower-right (\)
                let sway = CGFloat(sin(t * 0.72)) * 9.0
                let breath = 0.86 + 0.14 * sin(t * 1.15)
                let beamTopColor = weather == .dusk
                    ? Color(hex: "#FFD99B").opacity(0.24 * breath)
                    : Color(hex: "#FFFDF2").opacity((weather == .overcast ? 0.10 : 0.22) * breath)
                var beam = Path()
                beam.move(to: CGPoint(x: -w * 0.04 + sway * 0.4, y: 0))
                beam.addLine(to: CGPoint(x: w * 0.54 + sway * 0.4, y: 0))
                beam.addLine(to: CGPoint(x: w * 0.94 + sway, y: h * 0.76))
                beam.addLine(to: CGPoint(x: w * 0.24 + sway, y: h * 0.76))
                beam.closeSubpath()
                ctx.fill(
                    beam,
                    with: .linearGradient(
                        Gradient(colors: [beamTopColor, Color(hex: "#FFF7DC").opacity(0.04), .clear]),
                        startPoint: CGPoint(x: w * 0.16, y: 0),
                        endPoint: CGPoint(x: w * 0.68, y: h * 0.76)
                    )
                )

                // Gentle warm sunlit dust bokeh motes drifting softly
                let moteCount = weather == .overcast ? 4 : 8
                for i in 0..<moteCount {
                    let phase = (t * 0.12 + Double(i) * 0.19).truncatingRemainder(dividingBy: 1.0)
                    let mx = w * (0.15 + CGFloat((i * 23) % 68) / 100.0) + sway * 0.5
                    let my = h * (0.14 + CGFloat((i * 17) % 52) / 100.0) - CGFloat(phase) * 18
                    let r: CGFloat = 2.4 + CGFloat(i % 3) * 1.1
                    let alpha = sin(phase * .pi) * (weather == .dusk ? 0.48 : 0.36)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: mx - r, y: my - r, width: r * 2, height: r * 2)),
                        with: .color(Color(hex: weather == .dusk ? "#FFE299" : "#FFFDF4").opacity(alpha))
                    )
                }
            } else {
                // Soft cool rainy window-light wash from upper-left
                var rainGlow = Path()
                rainGlow.move(to: CGPoint(x: 0, y: 0))
                rainGlow.addLine(to: CGPoint(x: w * 0.58, y: 0))
                rainGlow.addLine(to: CGPoint(x: w * 0.86, y: h * 0.58))
                rainGlow.addLine(to: CGPoint(x: w * 0.14, y: h * 0.58))
                rainGlow.closeSubpath()
                ctx.fill(
                    rainGlow,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "#E5F1F6").opacity(0.16), .clear]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: w * 0.68, y: h * 0.58)
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var careWeatherTint: some View {
        switch weather {
        case .clearMorning:
            Color(hex: "#FFF9EA").opacity(0.06)
                .blendMode(.screen)
        case .overcast:
            Color(hex: "#DCE4E2").opacity(0.18)
                .blendMode(.multiply)
        case .lightRain, .postRain:
            Color(hex: "#B8CBD6").opacity(0.24)
                .blendMode(.multiply)
        case .dusk:
            LinearGradient(
                colors: [Color(hex: "#E8B072").opacity(0.24), Color(hex: "#C98552").opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.multiply)
        }
    }

    private var fallbackCanvas: some View {
        TimelineView(.animation(minimumInterval: AppTheme.Motion.interval(fps: 20.0, reduceMotion: reduceMotion))) { timeline in
            let t = reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let w = size.width, h = size.height

                // Warm honey cedar plank background
                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(colors: weather.isRainy
                                 ? [Color(hex: "#E1E2DA"), Color(hex: "#CBBCA6")]
                                 : (weather == .dusk
                                    ? [Color(hex: "#F2DEC0"), Color(hex: "#D5B187")]
                                    : [Color(hex: "#F6EEDB"), Color(hex: "#DEC6A2")])),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: 0, y: h)
                    )
                )

                // Cedar wood plank seams
                for idx in 0..<10 {
                    let y = h * 0.10 + CGFloat(idx) * (h * 0.095)
                    var plank = Path()
                    plank.move(to: CGPoint(x: 0, y: y))
                    plank.addLine(to: CGPoint(x: w, y: y))
                    ctx.stroke(plank, with: .color(AppTheme.timberDeep.opacity(0.11)), lineWidth: 1.1)
                }

                // Soft diagonal windowpane sunlight patch (upper-left -> lower-right)
                if !weather.isRainy {
                    let sway = CGFloat(sin(t * 0.8)) * 7
                    var beam = Path()
                    beam.move(to: CGPoint(x: w * 0.04 + sway * 0.4, y: 0))
                    beam.addLine(to: CGPoint(x: w * 0.64 + sway * 0.4, y: 0))
                    beam.addLine(to: CGPoint(x: w * 0.96 + sway, y: h * 0.78))
                    beam.addLine(to: CGPoint(x: w * 0.22 + sway, y: h * 0.78))
                    beam.closeSubpath()
                    ctx.fill(
                        beam,
                        with: .linearGradient(
                            Gradient(colors: [Color(hex: "#FFFDF2").opacity(0.32), Color(hex: "#FFF8DC").opacity(0.08)]),
                            startPoint: CGPoint(x: w * 0.2, y: 0),
                            endPoint: CGPoint(x: w * 0.65, y: h * 0.78)
                        )
                    )
                }

                // Hand-loomed concentric braided oval rug centered under the pet
                let rugCenter = CGPoint(x: w * 0.50, y: h * 0.57)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: rugCenter.x - w * 0.44, y: rugCenter.y - 78, width: w * 0.88, height: 168)),
                    with: .color(AppTheme.timberDeep.opacity(0.11))
                )
                let rings: [(CGFloat, CGFloat, Color)] = [
                    (w * 0.86, 160, Color(hex: "#587488").opacity(0.45)),
                    (w * 0.74, 132, Color(hex: "#E4D4B8").opacity(0.75)),
                    (w * 0.60, 104, Color(hex: "#C2845A").opacity(0.44)),
                    (w * 0.44, 74,  Color(hex: "#EFE5D2").opacity(0.68))
                ]
                for (rw, rh, col) in rings {
                    let rect = CGRect(x: rugCenter.x - rw * 0.5, y: rugCenter.y - rh * 0.5, width: rw, height: rh)
                    ctx.fill(Path(ellipseIn: rect), with: .color(col))
                    ctx.stroke(Path(ellipseIn: rect), with: .color(AppTheme.timberDeep.opacity(0.24)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                }
            }
        }
    }
}
