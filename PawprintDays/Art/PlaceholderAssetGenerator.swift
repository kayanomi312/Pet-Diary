import SwiftUI

enum PetRigPose: String, Sendable {
    case notice
    case respond
    case resting
}

/// 7-Layer 60fps Painterly 2.5D Skeletal Rig — Rain-Washed Taiwanese Storybook Realism:
/// - Layered translucent gouache washes + warm sunlit rim + underside shadow
/// - Delicate dry colored-pencil crosshatching & organic ink outlines
/// - Inner-ear blush, cat whiskers, tabby forehead markings, dog brow dots & paw toe creases
/// - 3.5s FFD breathing, 0.65–1.55 Hz tail/wing sway, +-12° live IK finger tracking,
///   60% head / 40% chest weighted `socket_neck` wardrobe binding, and `PaperGrainAndLUT.metal`
struct ProceduralPetRigView: View {
    let pet: PetSpec
    var outfitID: String? = nil
    var pose: PetRigPose = .notice
    var weatherMode: WeatherMode = .lightRain
    var fingerFocusNormalized: CGPoint? = nil
    var isHappySquint: Bool = false
    var brushRuffleAmount: CGFloat = 0.0
    var mentorshipParticle: HabitFamily? = nil
    var applyMetalPaperShader: Bool = true
    var isStaticSnapshot: Bool = false

    var body: some View {
        Group {
            if isStaticSnapshot {
                rigCanvas(time: 1.2)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    rigCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .modifier(PaperGrainShaderModifier(weatherMode: weatherMode, enabled: applyMetalPaperShader))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityStoryLabel)
    }

    private var accessibilityStoryLabel: String {
        let outfitText: String
        if let outfitID, let item = ShopCatalog.item(id: outfitID) {
            outfitText = "，正配戴\(item.name)"
        } else {
            outfitText = ""
        }
        return "\(pet.name)，\(pet.personalityWord)的\(pet.kind.rawValue)\(outfitText)。"
    }

    @ViewBuilder
    private func rigCanvas(time: Double) -> some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let minDim = min(w, h)
            let cx = w * 0.50
            let cy = h * 0.56

            // Procedural 60fps skeletal kinematics
            let breathCycle = sin(time * (2.0 * .pi / 3.5))
            let breathScaleY = 1.0 + breathCycle * 0.028 + Double(brushRuffleAmount) * 0.022
            let breathScaleX = 1.0 - breathCycle * 0.015
            let tailFreq = pet.kind.isCatFamily ? 0.62 : 1.48
            let tailAngle = sin(time * 2.0 * .pi * tailFreq) * (pet.kind.isCatFamily ? 13.0 : 21.0)

            let ikOffsetX = Double(fingerFocusNormalized?.x ?? 0.0)
            let ikOffsetY = Double(fingerFocusNormalized?.y ?? 0.0)
            let headAngleDeg = max(-12.0, min(12.0, ikOffsetX * 12.0 + sin(time * 0.65) * 1.5))
            let headLeanX = ikOffsetX * minDim * 0.032
            let headLeanY = ikOffsetY * minDim * 0.020 + breathCycle * minDim * 0.008

            let blinkPhase = time.truncatingRemainder(dividingBy: 5.2)
            let isBlinking = !isStaticSnapshot && (blinkPhase > 4.95 && blinkPhase < 5.12)

            let primaryColor = Color(hex: pet.primaryCoatHex)
            let accentColor = Color(hex: pet.accentHex)
            let detailColor = Color(hex: pet.earDetailHex)
            let pencilInk = Color(hex: "#2C3536").opacity(0.78)
            let warmBlush = Color(hex: "#D99687").opacity(0.32)

            let restingDrop: CGFloat = (pose == .resting) ? minDim * 0.06 : 0.0
            let isStockyDog = (pet.id == "pet.06")
            let isSlenderHound = (pet.id == "pet.08")

            // =========================================================
            // L1_Shadow — Layered soft watercolor puddle shadow
            // =========================================================
            let outerShadow = CGRect(
                x: cx - minDim * 0.34,
                y: cy + minDim * 0.21 + restingDrop * 0.5,
                width: minDim * 0.68,
                height: minDim * 0.14
            )
            let innerShadow = CGRect(
                x: cx - minDim * 0.24,
                y: cy + minDim * 0.23 + restingDrop * 0.5,
                width: minDim * 0.48,
                height: minDim * 0.09
            )
            context.fill(Path(ellipseIn: outerShadow), with: .color(AppTheme.deepPineInk.opacity(0.08)))
            context.fill(Path(ellipseIn: innerShadow), with: .color(AppTheme.deepPineInk.opacity(0.14)))

            // =========================================================
            // L2_Tail_Wing — Gouache tail sway + Hem's veined seedpod wings
            // =========================================================
            context.drawLayer { layer in
                let pivot = CGPoint(x: cx + minDim * 0.17, y: cy + minDim * 0.09 + restingDrop)
                layer.translateBy(x: pivot.x, y: pivot.y)
                layer.rotate(by: .degrees(tailAngle))
                layer.translateBy(x: -pivot.x, y: -pivot.y)

                if pet.kind == .batCat {
                    var wing = Path()
                    wing.move(to: CGPoint(x: cx - minDim * 0.04, y: cy - minDim * 0.04 + restingDrop))
                    wing.addQuadCurve(
                        to: CGPoint(x: cx + minDim * 0.35, y: cy - minDim * 0.20 + restingDrop),
                        control: CGPoint(x: cx + minDim * 0.16, y: cy - minDim * 0.29 + restingDrop)
                    )
                    wing.addQuadCurve(
                        to: CGPoint(x: cx + minDim * 0.28, y: cy + minDim * 0.10 + restingDrop),
                        control: CGPoint(x: cx + minDim * 0.38, y: cy - minDim * 0.02 + restingDrop)
                    )
                    wing.addQuadCurve(
                        to: CGPoint(x: cx + minDim * 0.04, y: cy + minDim * 0.08 + restingDrop),
                        control: CGPoint(x: cx + minDim * 0.16, y: cy + minDim * 0.16 + restingDrop)
                    )
                    wing.closeSubpath()
                    layer.fill(
                        wing,
                        with: .linearGradient(
                            Gradient(colors: [accentColor.opacity(0.92), primaryColor.opacity(0.85)]),
                            startPoint: CGPoint(x: cx, y: cy - minDim * 0.22),
                            endPoint: CGPoint(x: cx + minDim * 0.32, y: cy + minDim * 0.10)
                        )
                    )
                    layer.stroke(wing, with: .color(pencilInk), lineWidth: minDim * 0.011)

                    for i in 1...3 {
                        var rib = Path()
                        rib.move(to: CGPoint(x: cx + minDim * 0.02, y: cy - minDim * 0.01 + restingDrop))
                        rib.addQuadCurve(
                            to: CGPoint(
                                x: cx + minDim * (0.18 + CGFloat(i) * 0.045),
                                y: cy - minDim * (0.17 - CGFloat(i) * 0.075) + restingDrop
                            ),
                            control: CGPoint(x: cx + minDim * 0.14, y: cy - minDim * 0.09 + restingDrop)
                        )
                        layer.stroke(rib, with: .color(detailColor.opacity(0.65)), lineWidth: minDim * 0.007)
                    }
                }

                var tail = Path()
                tail.move(to: CGPoint(x: pivot.x - minDim * 0.02, y: pivot.y))
                if pet.id == "pet.02" {
                    tail.addCurve(
                        to: CGPoint(x: pivot.x + minDim * 0.14, y: pivot.y - minDim * 0.25),
                        control1: CGPoint(x: pivot.x + minDim * 0.18, y: pivot.y - minDim * 0.02),
                        control2: CGPoint(x: pivot.x + minDim * 0.25, y: pivot.y - minDim * 0.18)
                    )
                    tail.addQuadCurve(
                        to: CGPoint(x: pivot.x + minDim * 0.08, y: pivot.y - minDim * 0.21),
                        control: CGPoint(x: pivot.x + minDim * 0.09, y: pivot.y - minDim * 0.28)
                    )
                } else {
                    tail.addCurve(
                        to: CGPoint(x: pivot.x + minDim * 0.19, y: pivot.y - minDim * 0.23),
                        control1: CGPoint(x: pivot.x + minDim * 0.16, y: pivot.y + minDim * 0.04),
                        control2: CGPoint(x: pivot.x + minDim * 0.23, y: pivot.y - minDim * 0.10)
                    )
                }
                layer.stroke(
                    tail,
                    with: .color(primaryColor),
                    style: StrokeStyle(lineWidth: minDim * (isStockyDog ? 0.068 : 0.056), lineCap: .round)
                )
                // Tabby rings on Sesame's tail
                if pet.id == "pet.01" {
                    layer.stroke(
                        tail,
                        with: .color(detailColor.opacity(0.55)),
                        style: StrokeStyle(lineWidth: minDim * 0.042, lineCap: .butt, dash: [minDim * 0.018, minDim * 0.028])
                    )
                }
                if pet.id == "pet.02" {
                    let tipRect = CGRect(x: pivot.x + minDim * 0.055, y: pivot.y - minDim * 0.23, width: minDim * 0.052, height: minDim * 0.052)
                    layer.fill(Path(ellipseIn: tipRect), with: .color(accentColor))
                }
                layer.stroke(
                    tail,
                    with: .color(pencilInk),
                    style: StrokeStyle(lineWidth: minDim * 0.010, lineCap: .round)
                )
            }

            // =========================================================
            // L3_Torso_Coat — Gouache depth gradient + crosshatch shading
            // =========================================================
            let torsoCenter = CGPoint(x: cx + minDim * 0.03, y: cy + minDim * 0.08 + restingDrop)
            context.drawLayer { layer in
                layer.translateBy(x: torsoCenter.x, y: torsoCenter.y)
                layer.scaleBy(x: breathScaleX, y: breathScaleY)
                layer.translateBy(x: -torsoCenter.x, y: -torsoCenter.y)

                let bodyWidth = minDim * (isStockyDog ? 0.54 : (isSlenderHound ? 0.48 : (pet.kind.isCatFamily ? 0.45 : 0.50)))
                let bodyHeight = minDim * (pose == .resting ? 0.27 : (isStockyDog ? 0.36 : (isSlenderHound ? 0.31 : 0.35)))
                let bodyRect = CGRect(
                    x: torsoCenter.x - bodyWidth * 0.5,
                    y: torsoCenter.y - bodyHeight * 0.5,
                    width: bodyWidth,
                    height: bodyHeight
                )
                let bodyPath = Path(roundedRect: bodyRect, cornerRadius: bodyHeight * 0.48)

                // Soft gouache wash gradient (sunlit top -> cool shaded underside)
                layer.fill(
                    bodyPath,
                    with: .linearGradient(
                        Gradient(colors: [primaryColor.opacity(0.94), primaryColor, detailColor.opacity(0.72)]),
                        startPoint: CGPoint(x: torsoCenter.x, y: bodyRect.minY),
                        endPoint: CGPoint(x: torsoCenter.x, y: bodyRect.maxY)
                    )
                )

                // Warm top rim highlight (storybook lantern / skylight bounce)
                let rimRect = CGRect(
                    x: torsoCenter.x - bodyWidth * 0.36,
                    y: bodyRect.minY + minDim * 0.018,
                    width: bodyWidth * 0.62,
                    height: bodyHeight * 0.22
                )
                layer.fill(Path(ellipseIn: rimRect), with: .color(AppTheme.warmPaper.opacity(0.18)))

                // Plum's cloud-soft curly coat tufts
                if pet.id == "pet.07" {
                    for idx in 0..<5 {
                        let puff = CGRect(
                            x: torsoCenter.x - bodyWidth * 0.36 + CGFloat(idx) * minDim * 0.092,
                            y: torsoCenter.y - bodyHeight * 0.54 + (idx.isMultiple(of: 2) ? 0 : minDim * 0.015),
                            width: minDim * 0.115,
                            height: minDim * 0.09
                        )
                        layer.fill(Path(ellipseIn: puff), with: .color(primaryColor))
                        layer.stroke(Path(ellipseIn: puff), with: .color(pencilInk.opacity(0.35)), lineWidth: minDim * 0.006)
                    }
                }

                // Tuxedo crisp white bib for Juniper vs soft belly wash for others
                if pet.id == "pet.02" {
                    let bibRect = CGRect(
                        x: torsoCenter.x - bodyWidth * 0.44,
                        y: torsoCenter.y - bodyHeight * 0.22,
                        width: bodyWidth * 0.34,
                        height: bodyHeight * 0.58
                    )
                    layer.fill(Path(ellipseIn: bibRect), with: .color(accentColor))
                } else {
                    let bellyRect = CGRect(
                        x: torsoCenter.x - bodyWidth * 0.32,
                        y: torsoCenter.y - bodyHeight * 0.02,
                        width: bodyWidth * 0.52,
                        height: bodyHeight * 0.42
                    )
                    layer.fill(Path(ellipseIn: bellyRect), with: .color(accentColor.opacity(0.28)))
                }

                // Dry colored-pencil crosshatching along shaded lower flank
                for hatch in 0..<5 {
                    let hx = torsoCenter.x + bodyWidth * 0.02 + CGFloat(hatch) * minDim * 0.032
                    let hy = torsoCenter.y + bodyHeight * 0.18
                    var stroke = Path()
                    stroke.move(to: CGPoint(x: hx, y: hy))
                    stroke.addLine(to: CGPoint(x: hx - minDim * 0.022, y: hy + minDim * 0.048))
                    layer.stroke(stroke, with: .color(pencilInk.opacity(0.22)), lineWidth: minDim * 0.006)
                }

                // Species-specific sculptural details
                if pet.kind == .dragonCat {
                    // Cinder's terracotta Taiwanese roof-tile back scales (#C85A32) with ember glow
                    for idx in 0..<4 {
                        let sx = torsoCenter.x - bodyWidth * 0.13 + CGFloat(idx) * (minDim * 0.074)
                        let sy = torsoCenter.y - bodyHeight * 0.49 + CGFloat(idx) * (minDim * 0.012)
                        var tile = Path()
                        tile.move(to: CGPoint(x: sx, y: sy + minDim * 0.042))
                        tile.addQuadCurve(
                            to: CGPoint(x: sx + minDim * 0.068, y: sy + minDim * 0.032),
                            control: CGPoint(x: sx + minDim * 0.034, y: sy - minDim * 0.042)
                        )
                        tile.closeSubpath()
                        layer.fill(tile, with: .color(accentColor))
                        layer.stroke(tile, with: .color(AppTheme.duskAmber.opacity(0.65)), lineWidth: minDim * 0.005)
                        layer.stroke(tile, with: .color(pencilInk), lineWidth: minDim * 0.008)
                    }
                } else if pet.id == "pet.01" {
                    // Sesame's soft hand-painted grey tabby stripes
                    for idx in 0..<4 {
                        let sx = torsoCenter.x - minDim * 0.08 + CGFloat(idx) * minDim * 0.065
                        var stripe = Path()
                        stripe.move(to: CGPoint(x: sx, y: torsoCenter.y - bodyHeight * 0.44))
                        stripe.addQuadCurve(
                            to: CGPoint(x: sx - minDim * 0.024, y: torsoCenter.y - bodyHeight * 0.05),
                            control: CGPoint(x: sx + minDim * 0.022, y: torsoCenter.y - bodyHeight * 0.24)
                        )
                        layer.stroke(stripe, with: .color(detailColor.opacity(0.60)), style: StrokeStyle(lineWidth: minDim * 0.019, lineCap: .round))
                    }
                }

                layer.stroke(bodyPath, with: .color(pencilInk), lineWidth: minDim * 0.013)
            }

            // =========================================================
            // L4_Socket_Back — Optional Forager's Canvas Satchel
            // =========================================================
            if outfitID == "outfit.forager_satchel", let satchel = ShopCatalog.item(id: "outfit.forager_satchel") {
                let bagRect = CGRect(
                    x: torsoCenter.x - minDim * 0.05,
                    y: torsoCenter.y - minDim * 0.14,
                    width: minDim * 0.19,
                    height: minDim * 0.15
                )
                let bagPath = Path(roundedRect: bagRect, cornerRadius: minDim * 0.032)
                context.fill(bagPath, with: .color(Color(hex: satchel.swatchHex)))
                var flap = Path()
                flap.move(to: CGPoint(x: bagRect.minX, y: bagRect.minY + bagRect.height * 0.38))
                flap.addQuadCurve(
                    to: CGPoint(x: bagRect.maxX, y: bagRect.minY + bagRect.height * 0.38),
                    control: CGPoint(x: bagRect.midX, y: bagRect.minY + bagRect.height * 0.62)
                )
                context.stroke(flap, with: .color(pencilInk), lineWidth: minDim * 0.008)
                context.stroke(bagPath, with: .color(pencilInk), lineWidth: minDim * 0.010)
            }

            // =========================================================
            // L5_Head_Muzzle — Live IK finger tracking (+-12 deg) + Storybook face
            // =========================================================
            let headCenter = CGPoint(
                x: cx - minDim * 0.14 + headLeanX,
                y: cy - minDim * 0.12 + headLeanY + restingDrop * 0.7
            )
            let headSize = minDim * (pet.kind.isCatFamily ? 0.31 : (isSlenderHound ? 0.31 : 0.33))

            context.drawLayer { layer in
                layer.translateBy(x: headCenter.x, y: headCenter.y)
                layer.rotate(by: .degrees(headAngleDeg))
                layer.translateBy(x: -headCenter.x, y: -headCenter.y)

                drawEars(in: &layer, headCenter: headCenter, headSize: headSize, primaryColor: primaryColor, accentColor: accentColor, detailColor: detailColor, inkOutline: pencilInk)

                let headRect = CGRect(
                    x: headCenter.x - headSize * 0.52,
                    y: headCenter.y - headSize * 0.48,
                    width: headSize * (isSlenderHound ? 1.12 : 1.05),
                    height: headSize * 0.94
                )
                let headPath = Path(ellipseIn: headRect)
                layer.fill(
                    headPath,
                    with: .radialGradient(
                        Gradient(colors: [primaryColor.opacity(0.92), primaryColor, detailColor.opacity(0.75)]),
                        center: CGPoint(x: headCenter.x - headSize * 0.10, y: headCenter.y - headSize * 0.18),
                        startRadius: headSize * 0.06,
                        endRadius: headSize * 0.62
                    )
                )

                // Forehead tabby markings for Sesame (matching App Icon!)
                if pet.id == "pet.01" {
                    for idx in -1...1 {
                        var mark = Path()
                        let mx = headCenter.x - headSize * 0.05 + CGFloat(idx) * headSize * 0.11
                        mark.move(to: CGPoint(x: mx, y: headCenter.y - headSize * 0.44))
                        mark.addLine(to: CGPoint(x: mx + CGFloat(idx) * headSize * 0.02, y: headCenter.y - headSize * 0.25))
                        layer.stroke(mark, with: .color(detailColor.opacity(0.72)), style: StrokeStyle(lineWidth: headSize * 0.048, lineCap: .round))
                    }
                }

                // Soft muzzle gouache patch
                let muzzleColor = (pet.id == "pet.07") ? accentColor : detailColor
                let muzzleOpacity: Double = (pet.id == "pet.07") ? 0.92 : (pet.kind.isCatFamily ? 0.20 : 0.65)
                let muzzleRect = CGRect(
                    x: headCenter.x - headSize * 0.34,
                    y: headCenter.y + headSize * 0.03,
                    width: headSize * 0.48,
                    height: headSize * 0.32
                )
                layer.fill(Path(ellipseIn: muzzleRect), with: .color(muzzleColor.opacity(muzzleOpacity)))

                // Soft storybook cheek blushes
                let leftCheek = CGRect(x: headCenter.x - headSize * 0.40, y: headCenter.y + headSize * 0.04, width: headSize * 0.16, height: headSize * 0.10)
                let rightCheek = CGRect(x: headCenter.x + headSize * 0.11, y: headCenter.y + headSize * 0.04, width: headSize * 0.16, height: headSize * 0.10)
                layer.fill(Path(ellipseIn: leftCheek), with: .color(warmBlush))
                layer.fill(Path(ellipseIn: rightCheek), with: .color(warmBlush))

                layer.stroke(headPath, with: .color(pencilInk), lineWidth: minDim * 0.013)

                // L7 Eyes + gentle dog brow dots
                let leftEye = CGPoint(x: headCenter.x - headSize * 0.22, y: headCenter.y - headSize * 0.05)
                let rightEye = CGPoint(x: headCenter.x + headSize * 0.08, y: headCenter.y - headSize * 0.05)

                if !pet.kind.isCatFamily {
                    for pt in [leftEye, rightEye] {
                        let browRect = CGRect(x: pt.x - headSize * 0.045, y: pt.y - headSize * 0.15, width: headSize * 0.09, height: headSize * 0.045)
                        layer.fill(Path(ellipseIn: browRect), with: .color(accentColor.opacity(0.65)))
                    }
                }

                if isHappySquint || pose == .resting {
                    drawCrescentEye(in: &layer, at: leftEye, radius: headSize * 0.09, color: pencilInk)
                    drawCrescentEye(in: &layer, at: rightEye, radius: headSize * 0.09, color: pencilInk)
                } else if isBlinking {
                    drawBlinkEye(in: &layer, at: leftEye, radius: headSize * 0.08, color: pencilInk)
                    drawBlinkEye(in: &layer, at: rightEye, radius: headSize * 0.08, color: pencilInk)
                } else {
                    for pt in [leftEye, rightEye] {
                        let r = headSize * 0.068
                        layer.fill(Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)), with: .color(AppTheme.deepPineInk))
                        let gl = r * 0.42
                        layer.fill(Path(ellipseIn: CGRect(x: pt.x - r * 0.38, y: pt.y - r * 0.46, width: gl, height: gl)), with: .color(AppTheme.warmPaper))
                    }
                }

                // Nose + gentle ":3" storybook smile
                let nosePt = CGPoint(x: headCenter.x - headSize * 0.08, y: headCenter.y + headSize * 0.10)
                let noseR = headSize * 0.052
                layer.fill(Path(ellipseIn: CGRect(x: nosePt.x - noseR, y: nosePt.y - noseR * 0.7, width: noseR * 2, height: noseR * 1.35)), with: .color(AppTheme.deepPineInk))

                var smile = Path()
                smile.move(to: CGPoint(x: nosePt.x, y: nosePt.y + headSize * 0.03))
                smile.addLine(to: CGPoint(x: nosePt.x, y: nosePt.y + headSize * 0.07))
                smile.move(to: CGPoint(x: nosePt.x - headSize * 0.09, y: nosePt.y + headSize * 0.09))
                smile.addQuadCurve(to: CGPoint(x: nosePt.x, y: nosePt.y + headSize * 0.07), control: CGPoint(x: nosePt.x - headSize * 0.04, y: nosePt.y + headSize * 0.14))
                smile.addQuadCurve(to: CGPoint(x: nosePt.x + headSize * 0.09, y: nosePt.y + headSize * 0.09), control: CGPoint(x: nosePt.x + headSize * 0.04, y: nosePt.y + headSize * 0.14))
                layer.stroke(smile, with: .color(pencilInk), style: StrokeStyle(lineWidth: minDim * 0.0085, lineCap: .round, lineJoin: .round))

                // Delicate hand-drawn cat whiskers
                if pet.kind.isCatFamily {
                    for side in [-1.0, 1.0] {
                        let baseX = headCenter.x + CGFloat(side) * headSize * (side < 0 ? 0.34 : 0.24)
                        for idx in -1...1 {
                            var whisker = Path()
                            let wy = headCenter.y + headSize * 0.09 + CGFloat(idx) * headSize * 0.065
                            whisker.move(to: CGPoint(x: baseX, y: wy))
                            whisker.addLine(to: CGPoint(x: baseX + CGFloat(side) * headSize * 0.24, y: wy + CGFloat(idx) * headSize * 0.04))
                            layer.stroke(whisker, with: .color(pencilInk.opacity(0.55)), style: StrokeStyle(lineWidth: minDim * 0.0055, lineCap: .round))
                        }
                    }
                }
            }

            // =========================================================
            // L6_Socket_Neck — 60% head / 40% chest weighted wardrobe
            // =========================================================
            if let outfitID,
               let item = ShopCatalog.item(id: outfitID),
               item.slotType == "socket_neck" {
                let neckBaseX = w * pet.socketNeckU
                let neckBaseY = h * pet.socketNeckV + restingDrop * 0.55
                let weightedX = neckBaseX + headLeanX * 0.60
                let weightedY = neckBaseY + headLeanY * 0.60 + breathCycle * minDim * 0.006 * 0.40
                let weightedAngle = headAngleDeg * 0.60

                context.drawLayer { layer in
                    layer.translateBy(x: weightedX, y: weightedY)
                    layer.rotate(by: .degrees(weightedAngle))
                    layer.translateBy(x: -weightedX, y: -weightedY)

                    let swatch = Color(hex: item.swatchHex)
                    let secondary = Color(hex: item.secondaryHex)

                    let strapRect = CGRect(
                        x: weightedX - minDim * 0.135,
                        y: weightedY - minDim * 0.032,
                        width: minDim * 0.27,
                        height: minDim * 0.064
                    )
                    let strapPath = Path(roundedRect: strapRect, cornerRadius: minDim * 0.028)
                    layer.fill(strapPath, with: .color(swatch))
                    layer.stroke(strapPath, with: .color(pencilInk), lineWidth: minDim * 0.009)

                    if outfitID.contains("bandana") {
                        var triangle = Path()
                        triangle.move(to: CGPoint(x: weightedX - minDim * 0.105, y: weightedY + minDim * 0.01))
                        triangle.addLine(to: CGPoint(x: weightedX + minDim * 0.085, y: weightedY + minDim * 0.01))
                        triangle.addLine(to: CGPoint(x: weightedX - minDim * 0.015, y: weightedY + minDim * 0.145))
                        triangle.closeSubpath()
                        layer.fill(triangle, with: .color(swatch))
                        // Rice-stitch trim along bandana edge
                        layer.stroke(triangle, with: .color(secondary.opacity(0.85)), style: StrokeStyle(lineWidth: minDim * 0.006, dash: [minDim * 0.012, minDim * 0.010]))
                        layer.stroke(triangle, with: .color(pencilInk), lineWidth: minDim * 0.009)
                    } else if outfitID == "outfit.occasion_collar" {
                        let bellRect = CGRect(x: weightedX - minDim * 0.038, y: weightedY + minDim * 0.02, width: minDim * 0.076, height: minDim * 0.076)
                        layer.fill(
                            Path(ellipseIn: bellRect),
                            with: .radialGradient(
                                Gradient(colors: [AppTheme.warmPaper, secondary, AppTheme.brassDark]),
                                center: CGPoint(x: bellRect.midX - minDim * 0.01, y: bellRect.midY - minDim * 0.01),
                                startRadius: 1,
                                endRadius: minDim * 0.05
                            )
                        )
                        layer.stroke(Path(ellipseIn: bellRect), with: .color(pencilInk), lineWidth: minDim * 0.008)
                    } else {
                        var leftBow = Path()
                        leftBow.move(to: CGPoint(x: weightedX - minDim * 0.02, y: weightedY + minDim * 0.02))
                        leftBow.addLine(to: CGPoint(x: weightedX - minDim * 0.095, y: weightedY + minDim * 0.105))
                        leftBow.addLine(to: CGPoint(x: weightedX - minDim * 0.03, y: weightedY + minDim * 0.115))
                        leftBow.closeSubpath()
                        layer.fill(leftBow, with: .color(swatch))
                        layer.stroke(leftBow, with: .color(pencilInk), lineWidth: minDim * 0.008)

                        var rightBow = Path()
                        rightBow.move(to: CGPoint(x: weightedX + minDim * 0.01, y: weightedY + minDim * 0.02))
                        rightBow.addLine(to: CGPoint(x: weightedX + minDim * 0.075, y: weightedY + minDim * 0.105))
                        rightBow.addLine(to: CGPoint(x: weightedX + minDim * 0.01, y: weightedY + minDim * 0.115))
                        rightBow.closeSubpath()
                        layer.fill(rightBow, with: .color(secondary))
                        layer.stroke(rightBow, with: .color(pencilInk), lineWidth: minDim * 0.008)

                        let knotRect = CGRect(x: weightedX - minDim * 0.026, y: weightedY - minDim * 0.01, width: minDim * 0.052, height: minDim * 0.052)
                        layer.fill(Path(ellipseIn: knotRect), with: .color(swatch))
                        layer.stroke(Path(ellipseIn: knotRect), with: .color(pencilInk), lineWidth: minDim * 0.008)
                    }
                }
            }

            // =========================================================
            // L7_Forepaws — Penciled toe creases + Sesame's signature white left paw
            // =========================================================
            let pawY = cy + minDim * 0.21 + restingDrop * 0.5
            let leftFrontPawRect = CGRect(x: cx - minDim * 0.175, y: pawY - minDim * 0.038, width: minDim * 0.115, height: minDim * 0.080)
            let rightFrontPawRect = CGRect(x: cx - minDim * 0.03, y: pawY - minDim * 0.032, width: minDim * 0.105, height: minDim * 0.076)

            let leftPawColor: Color = {
                switch pet.id {
                case "pet.01": return Color(hex: "#F8FAFC")
                case "pet.03": return Color(hex: "#F5E9D6")
                case "pet.06": return Color(hex: "#E2D9C8")
                default: return primaryColor
                }
            }()
            let rightPawColor: Color = {
                switch pet.id {
                case "pet.03": return Color(hex: "#F5E9D6")
                case "pet.06": return Color(hex: "#E2D9C8")
                default: return primaryColor
                }
            }()

            drawPaw(in: &context, rect: rightFrontPawRect, fill: rightPawColor, ink: pencilInk, minDim: minDim)
            drawPaw(in: &context, rect: leftFrontPawRect, fill: leftPawColor, ink: pencilInk, minDim: minDim)

            // =========================================================
            // Shared-Prop Mentorship Subtle Particle Cue
            // =========================================================
            if let habit = mentorshipParticle {
                let moteColor: Color = {
                    switch habit {
                    case .nest: return AppTheme.pawInRange
                    case .shield: return AppTheme.forestTeal
                    case .offer: return AppTheme.pawStrollChain
                    case .wait: return AppTheme.vineGreen
                    }
                }()
                for idx in 0..<4 {
                    let phase = (time * 0.55 + Double(idx) * 0.25).truncatingRemainder(dividingBy: 1.0)
                    let px = cx + CGFloat(idx - 1) * minDim * 0.14 + CGFloat(sin(time + Double(idx))) * minDim * 0.03
                    let py = cy - minDim * 0.10 - CGFloat(phase) * minDim * 0.26
                    let r = minDim * 0.017 * (1.0 - CGFloat(phase) * 0.4)
                    context.fill(
                        Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                        with: .color(moteColor.opacity(0.68 * (1.0 - phase)))
                    )
                }
            }
        }
    }

    private func drawPaw(in context: inout GraphicsContext, rect: CGRect, fill: Color, ink: Color, minDim: CGFloat) {
        context.fill(Path(ellipseIn: rect), with: .color(fill))
        context.stroke(Path(ellipseIn: rect), with: .color(ink), lineWidth: minDim * 0.010)
        // Two delicate toe crease ticks
        for offset in [-0.18, 0.12] {
            var tick = Path()
            let tx = rect.midX + rect.width * CGFloat(offset)
            tick.move(to: CGPoint(x: tx, y: rect.maxY - rect.height * 0.32))
            tick.addLine(to: CGPoint(x: tx, y: rect.maxY - rect.height * 0.06))
            context.stroke(tick, with: .color(ink.opacity(0.65)), style: StrokeStyle(lineWidth: minDim * 0.006, lineCap: .round))
        }
    }

    private func drawEars(
        in layer: inout GraphicsContext,
        headCenter: CGPoint,
        headSize: CGFloat,
        primaryColor: Color,
        accentColor: Color,
        detailColor: Color,
        inkOutline: Color
    ) {
        let innerEarBlush = Color(hex: "#DDA799").opacity(0.68)

        if pet.kind.isCatFamily {
            let earHeight = (pet.kind == .batCat) ? headSize * 0.56 : headSize * 0.44
            var leftEar = Path()
            leftEar.move(to: CGPoint(x: headCenter.x - headSize * 0.41, y: headCenter.y - headSize * 0.21))
            leftEar.addLine(to: CGPoint(x: headCenter.x - headSize * 0.32, y: headCenter.y - headSize * 0.22 - earHeight))
            leftEar.addLine(to: CGPoint(x: headCenter.x - headSize * 0.07, y: headCenter.y - headSize * 0.38))
            leftEar.closeSubpath()
            layer.fill(leftEar, with: .color(primaryColor))

            var leftInner = Path()
            leftInner.move(to: CGPoint(x: headCenter.x - headSize * 0.34, y: headCenter.y - headSize * 0.24))
            leftInner.addLine(to: CGPoint(x: headCenter.x - headSize * 0.29, y: headCenter.y - headSize * 0.22 - earHeight * 0.65))
            leftInner.addLine(to: CGPoint(x: headCenter.x - headSize * 0.14, y: headCenter.y - headSize * 0.35))
            leftInner.closeSubpath()
            layer.fill(leftInner, with: .color(innerEarBlush))
            layer.stroke(leftEar, with: .color(inkOutline), lineWidth: headSize * 0.038)

            var rightEar = Path()
            rightEar.move(to: CGPoint(x: headCenter.x + headSize * 0.04, y: headCenter.y - headSize * 0.38))
            rightEar.addLine(to: CGPoint(x: headCenter.x + headSize * 0.29, y: headCenter.y - headSize * 0.22 - earHeight))
            rightEar.addLine(to: CGPoint(x: headCenter.x + headSize * 0.39, y: headCenter.y - headSize * 0.20))
            rightEar.closeSubpath()
            layer.fill(rightEar, with: .color(primaryColor))

            var rightInner = Path()
            rightInner.move(to: CGPoint(x: headCenter.x + headSize * 0.11, y: headCenter.y - headSize * 0.35))
            rightInner.addLine(to: CGPoint(x: headCenter.x + headSize * 0.26, y: headCenter.y - headSize * 0.22 - earHeight * 0.65))
            rightInner.addLine(to: CGPoint(x: headCenter.x + headSize * 0.33, y: headCenter.y - headSize * 0.23))
            rightInner.closeSubpath()
            layer.fill(rightInner, with: .color(innerEarBlush))
            layer.stroke(rightEar, with: .color(inkOutline), lineWidth: headSize * 0.038)
        } else if pet.kind == .marshHound {
            let leftReed = CGRect(x: headCenter.x - headSize * 0.62, y: headCenter.y - headSize * 0.22, width: headSize * 0.28, height: headSize * 0.62)
            let rightReed = CGRect(x: headCenter.x + headSize * 0.28, y: headCenter.y - headSize * 0.20, width: headSize * 0.28, height: headSize * 0.60)
            layer.fill(Path(roundedRect: leftReed, cornerRadius: headSize * 0.14), with: .color(accentColor))
            layer.stroke(Path(roundedRect: leftReed, cornerRadius: headSize * 0.14), with: .color(inkOutline), lineWidth: headSize * 0.036)
            layer.fill(Path(roundedRect: rightReed, cornerRadius: headSize * 0.14), with: .color(accentColor))
            layer.stroke(Path(roundedRect: rightReed, cornerRadius: headSize * 0.14), with: .color(inkOutline), lineWidth: headSize * 0.036)
        } else {
            let leftFlop = CGRect(x: headCenter.x - headSize * 0.58, y: headCenter.y - headSize * 0.28, width: headSize * 0.26, height: headSize * 0.46)
            let earColor = (pet.id == "pet.06" || pet.id == "pet.07") ? detailColor : accentColor
            layer.fill(Path(roundedRect: leftFlop, cornerRadius: headSize * 0.12), with: .color(earColor))
            layer.stroke(Path(roundedRect: leftFlop, cornerRadius: headSize * 0.12), with: .color(inkOutline), lineWidth: headSize * 0.038)

            var rightEar = Path()
            rightEar.move(to: CGPoint(x: headCenter.x + headSize * 0.12, y: headCenter.y - headSize * 0.34))
            rightEar.addQuadCurve(to: CGPoint(x: headCenter.x + headSize * 0.46, y: headCenter.y - headSize * 0.02), control: CGPoint(x: headCenter.x + headSize * 0.44, y: headCenter.y - headSize * 0.44))
            rightEar.addQuadCurve(to: CGPoint(x: headCenter.x + headSize * 0.22, y: headCenter.y - headSize * 0.05), control: CGPoint(x: headCenter.x + headSize * 0.36, y: headCenter.y + headSize * 0.06))
            rightEar.closeSubpath()
            layer.fill(rightEar, with: .color(earColor))
            layer.stroke(rightEar, with: .color(inkOutline), lineWidth: headSize * 0.038)
        }
    }

    private func drawCrescentEye(in layer: inout GraphicsContext, at point: CGPoint, radius: CGFloat, color: Color) {
        var arc = Path()
        arc.move(to: CGPoint(x: point.x - radius, y: point.y + radius * 0.2))
        arc.addQuadCurve(to: CGPoint(x: point.x + radius, y: point.y + radius * 0.2), control: CGPoint(x: point.x, y: point.y - radius * 0.9))
        layer.stroke(arc, with: .color(color), style: StrokeStyle(lineWidth: radius * 0.42, lineCap: .round))
    }

    private func drawBlinkEye(in layer: inout GraphicsContext, at point: CGPoint, radius: CGFloat, color: Color) {
        var line = Path()
        line.move(to: CGPoint(x: point.x - radius, y: point.y))
        line.addLine(to: CGPoint(x: point.x + radius, y: point.y))
        layer.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: radius * 0.38, lineCap: .round))
    }
}

struct PaperGrainShaderModifier: ViewModifier {
    let weatherMode: WeatherMode
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.colorEffect(
                ShaderLibrary.paperGrainAndWeather(.float(weatherMode.shaderValue))
            )
        } else {
            content
        }
    }
}
