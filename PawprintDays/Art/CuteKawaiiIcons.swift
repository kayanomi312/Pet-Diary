import SwiftUI

// MARK: - 1. Cute Kawaii Hand-Drawn Weather Face Charm
struct CuteWeatherFaceIcon: View {
    let weather: WeatherMode
    var size: CGFloat = 26

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let ink = Color(hex: "#3A2E2A")
            let cheek = Color(hex: "#F2998D").opacity(0.75)

            switch weather {
            case .clearMorning:
                // Scalloped soft rays
                let cx = w * 0.5, cy = h * 0.5
                for idx in 0..<8 {
                    let ang = Double(idx) * .pi / 4.0
                    let rx = cx + CGFloat(cos(ang)) * w * 0.40
                    let ry = cy + CGFloat(sin(ang)) * h * 0.40
                    ctx.fill(Path(ellipseIn: CGRect(x: rx - 2.6, y: ry - 2.6, width: 5.2, height: 5.2)), with: .color(Color(hex: "#F4BE4F")))
                }
                let sun = Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.18, width: w * 0.64, height: h * 0.64))
                ctx.fill(sun, with: .radialGradient(Gradient(colors: [Color(hex: "#FFE799"), Color(hex: "#F5B841")]), center: CGPoint(x: w * 0.44, y: h * 0.40), startRadius: 1, endRadius: w * 0.36))
                ctx.stroke(sun, with: .color(ink.opacity(0.65)), lineWidth: 1.1)
                drawKawaiiFace(in: &ctx, center: CGPoint(x: cx, y: cy + 0.5), scale: w * 0.32, ink: ink, cheek: cheek)

            case .lightRain, .postRain:
                // Cute raindrops
                for dx in [0.30, 0.52, 0.72] {
                    var drop = Path()
                    drop.move(to: CGPoint(x: w * dx, y: h * 0.68))
                    drop.addLine(to: CGPoint(x: w * dx - 1.5, y: h * 0.88))
                    ctx.stroke(drop, with: .color(Color(hex: "#6AA4C4")), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                }
                drawFluffyCloud(in: &ctx, rect: CGRect(x: w * 0.10, y: h * 0.14, width: w * 0.80, height: h * 0.52), fill: Color(hex: "#EBF4F8"), ink: ink)
                drawKawaiiFace(in: &ctx, center: CGPoint(x: w * 0.50, y: h * 0.44), scale: w * 0.28, ink: ink, cheek: cheek)

            case .dusk:
                // Sleepy honey crescent moon + tiny star
                var moon = Path()
                moon.addArc(center: CGPoint(x: w * 0.46, y: h * 0.52), radius: w * 0.34, startAngle: .degrees(-65), endAngle: .degrees(145), clockwise: false)
                moon.addQuadCurve(to: CGPoint(x: w * 0.60, y: h * 0.21), control: CGPoint(x: w * 0.42, y: h * 0.56))
                moon.closeSubpath()
                ctx.fill(moon, with: .color(Color(hex: "#F7C86A")))
                ctx.stroke(moon, with: .color(ink.opacity(0.65)), lineWidth: 1.1)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.68, y: h * 0.22, width: 4.5, height: 4.5)), with: .color(Color(hex: "#FFE799")))
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.32, y: h * 0.52, width: 3.4, height: 2.2)), with: .color(cheek))

            case .overcast:
                drawFluffyCloud(in: &ctx, rect: CGRect(x: w * 0.08, y: h * 0.22, width: w * 0.84, height: h * 0.56), fill: Color(hex: "#FFFDF7"), ink: ink)
                drawKawaiiFace(in: &ctx, center: CGPoint(x: w * 0.50, y: h * 0.54), scale: w * 0.30, ink: ink, cheek: cheek)
            }
        }
        .frame(width: size, height: size)
    }

    private func drawFluffyCloud(in ctx: inout GraphicsContext, rect: CGRect, fill: Color, ink: Color) {
        let base = Path(roundedRect: CGRect(x: rect.minX, y: rect.midY - rect.height * 0.12, width: rect.width, height: rect.height * 0.62), cornerRadius: rect.height * 0.32)
        let puff1 = Path(ellipseIn: CGRect(x: rect.minX + rect.width * 0.14, y: rect.minY, width: rect.width * 0.44, height: rect.height * 0.68))
        let puff2 = Path(ellipseIn: CGRect(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.08, width: rect.width * 0.38, height: rect.height * 0.60))
        ctx.fill(puff1, with: .color(fill))
        ctx.fill(puff2, with: .color(fill))
        ctx.fill(base, with: .color(fill))
        ctx.stroke(base, with: .color(ink.opacity(0.55)), lineWidth: 1.0)
    }

    private func drawKawaiiFace(in ctx: inout GraphicsContext, center: CGPoint, scale: CGFloat, ink: Color, cheek: Color) {
        // Tiny dot eyes
        let eyeY = center.y - scale * 0.10
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - scale * 0.42 - 1.2, y: eyeY - 1.2, width: 2.4, height: 2.4)), with: .color(ink))
        ctx.fill(Path(ellipseIn: CGRect(x: center.x + scale * 0.42 - 1.2, y: eyeY - 1.2, width: 2.4, height: 2.4)), with: .color(ink))
        // Rosy cheeks
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - scale * 0.72, y: center.y + scale * 0.04, width: scale * 0.34, height: scale * 0.22)), with: .color(cheek))
        ctx.fill(Path(ellipseIn: CGRect(x: center.x + scale * 0.38, y: center.y + scale * 0.04, width: scale * 0.34, height: scale * 0.22)), with: .color(cheek))
        // Tiny cute "w" smile
        var smile = Path()
        smile.move(to: CGPoint(x: center.x - scale * 0.18, y: center.y + scale * 0.08))
        smile.addQuadCurve(to: CGPoint(x: center.x + scale * 0.18, y: center.y + scale * 0.08), control: CGPoint(x: center.x, y: center.y + scale * 0.32))
        ctx.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
    }
}

// MARK: - 2. Cute Stitched Hardcover Diary Book with Dangling Paw Ribbon
struct CuteDiaryBookIcon: View {
    var size: CGFloat = 22

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let ink = Color(hex: "#3A2B24").opacity(0.82)

            // Dangling berry bookmark ribbon
            var ribbon = Path()
            ribbon.move(to: CGPoint(x: w * 0.62, y: h * 0.78))
            ribbon.addLine(to: CGPoint(x: w * 0.62, y: h * 0.98))
            ribbon.addLine(to: CGPoint(x: w * 0.70, y: h * 0.91))
            ribbon.addLine(to: CGPoint(x: w * 0.78, y: h * 0.98))
            ribbon.addLine(to: CGPoint(x: w * 0.78, y: h * 0.78))
            ribbon.closeSubpath()
            ctx.fill(ribbon, with: .color(Color(hex: "#E36B5E")))

            // Cream page block
            let pages = Path(roundedRect: CGRect(x: w * 0.16, y: h * 0.14, width: w * 0.72, height: h * 0.72), cornerRadius: 4)
            ctx.fill(pages, with: .color(Color(hex: "#FFF9EE")))
            ctx.stroke(pages, with: .color(ink), lineWidth: 1.1)

            // Soft sage-mint linen cover
            let cover = Path(roundedRect: CGRect(x: w * 0.14, y: h * 0.08, width: w * 0.70, height: h * 0.72), cornerRadius: 5)
            ctx.fill(cover, with: .color(Color(hex: "#6DA688")))
            ctx.stroke(cover, with: .color(ink), lineWidth: 1.2)

            // Spine strap
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.14, y: h * 0.08, width: w * 0.14, height: h * 0.72), cornerRadius: 3), with: .color(Color(hex: "#4C8066")))

            // Little cream pawprint emblem on cover
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.40, width: w * 0.20, height: h * 0.17)), with: .color(Color(hex: "#FFFDF7")))
            for (dx, dy) in [(0.42, 0.30), (0.51, 0.26), (0.60, 0.30)] {
                ctx.fill(Path(ellipseIn: CGRect(x: w * dx, y: h * dy, width: w * 0.08, height: h * 0.08)), with: .color(Color(hex: "#FFFDF7")))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 3. Cute Cozy Cottage Home Icon (Replaces SF house.fill in Compass)
struct CuteCottageIcon: View {
    var size: CGFloat = 26

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let ink = Color(hex: "#3A2B24").opacity(0.80)

            // Tiny chimney + heart smoke puff
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.66, y: h * 0.18, width: w * 0.13, height: h * 0.24), cornerRadius: 2), with: .color(Color(hex: "#C47A53")))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.70, y: h * 0.06, width: w * 0.12, height: h * 0.10)), with: .color(Color(hex: "#F2998D").opacity(0.75)))

            // Warm butter-cream cottage wall
            let wall = Path(roundedRect: CGRect(x: w * 0.20, y: h * 0.44, width: w * 0.60, height: h * 0.44), cornerRadius: 5)
            ctx.fill(wall, with: .color(Color(hex: "#FFF5DF")))
            ctx.stroke(wall, with: .color(ink), lineWidth: 1.2)

            // Plump terracotta sloped roof
            var roof = Path()
            roof.move(to: CGPoint(x: w * 0.08, y: h * 0.48))
            roof.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.14), control: CGPoint(x: w * 0.26, y: h * 0.26))
            roof.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.48), control: CGPoint(x: w * 0.74, y: h * 0.26))
            roof.closeSubpath()
            ctx.fill(roof, with: .color(Color(hex: "#DF7356")))
            ctx.stroke(roof, with: .color(ink), lineWidth: 1.2)

            // Cozy arched door + glowing honey window
            let door = Path(roundedRect: CGRect(x: w * 0.42, y: h * 0.58, width: w * 0.18, height: h * 0.30), cornerRadius: 6)
            ctx.fill(door, with: .color(Color(hex: "#9E6A42")))
            ctx.stroke(door, with: .color(ink), lineWidth: 1.0)

            let win = Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.33, width: w * 0.12, height: h * 0.12))
            ctx.fill(win, with: .color(Color(hex: "#FFE799")))
            ctx.stroke(win, with: .color(ink), lineWidth: 0.9)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 4. Cute Adventure Stroll Backpack Icon (Replaces SF figure.walk)
struct CuteStrollBackpackIcon: View {
    var size: CGFloat = 22

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let ink = Color(hex: "#3A2B24").opacity(0.82)

            // Top handle loop
            var loop = Path()
            loop.addArc(center: CGPoint(x: w * 0.50, y: h * 0.20), radius: w * 0.14, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            ctx.stroke(loop, with: .color(ink), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))

            // Chubby cream-linen backpack body
            let pack = Path(roundedRect: CGRect(x: w * 0.16, y: h * 0.20, width: w * 0.68, height: h * 0.70), cornerRadius: 8)
            ctx.fill(pack, with: .color(Color(hex: "#FFF6E3")))
            ctx.stroke(pack, with: .color(ink), lineWidth: 1.2)

            // Flap + cute strawberry-terracotta front pocket
            let flap = Path(roundedRect: CGRect(x: w * 0.16, y: h * 0.20, width: w * 0.68, height: h * 0.30), cornerRadius: 7)
            ctx.fill(flap, with: .color(Color(hex: "#F2A85A")))
            ctx.stroke(flap, with: .color(ink), lineWidth: 1.1)

            let pocket = Path(roundedRect: CGRect(x: w * 0.28, y: h * 0.56, width: w * 0.44, height: h * 0.24), cornerRadius: 5)
            ctx.fill(pocket, with: .color(Color(hex: "#E67C68")))
            ctx.stroke(pocket, with: .color(ink), lineWidth: 1.0)

            // Brass clasp dot
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.44, width: w * 0.12, height: h * 0.12)), with: .color(Color(hex: "#FFE799")))
            ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.44, width: w * 0.12, height: h * 0.12)), with: .color(ink), lineWidth: 0.9)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 5. Cute Paw Signpost Pin Icon
struct CutePawSignpostIcon: View {
    var size: CGFloat = 22

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let ink = Color(hex: "#3A2B24").opacity(0.82)

            // Wooden post
            let post = Path(roundedRect: CGRect(x: w * 0.44, y: h * 0.50, width: w * 0.12, height: h * 0.42), cornerRadius: 2)
            ctx.fill(post, with: .color(Color(hex: "#A87444")))
            ctx.stroke(post, with: .color(ink), lineWidth: 1.0)

            // Round plump heart-paw head
            let head = Path(ellipseIn: CGRect(x: w * 0.16, y: h * 0.08, width: w * 0.68, height: h * 0.56))
            ctx.fill(head, with: .color(Color(hex: "#FFF9EE")))
            ctx.stroke(head, with: .color(ink), lineWidth: 1.2)

            // Cute berry paw inside
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.37, y: h * 0.35, width: w * 0.26, height: h * 0.18)), with: .color(Color(hex: "#E06D5A")))
            for (dx, dy) in [(0.32, 0.24), (0.45, 0.19), (0.58, 0.24)] {
                ctx.fill(Path(ellipseIn: CGRect(x: w * dx, y: h * dy, width: w * 0.10, height: h * 0.10)), with: .color(Color(hex: "#E06D5A")))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 6. Cute Care Playground Toy Icons (Fish Biscuit, Teaser Wand, Blanket, Dance Note, Belly Poke)
struct CuteCareToyIcon: View {
    enum Kind {
        case bellyPoke
        case teaserWand
        case fishSnack
        case cozyBlanket
        case happyTwirl
        case walkBuddy
    }

    let kind: Kind
    var size: CGFloat = 26

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let ink = Color(hex: "#3A2B24").opacity(0.80)

            switch kind {
            case .bellyPoke:
                // Plump rosy paw pad
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.46, width: w * 0.52, height: h * 0.40)), with: .color(Color(hex: "#F4A499")))
                ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.46, width: w * 0.52, height: h * 0.40)), with: .color(ink), lineWidth: 1.1)
                for (dx, dy) in [(0.14, 0.26), (0.34, 0.14), (0.56, 0.14), (0.74, 0.26)] {
                    let toe = Path(ellipseIn: CGRect(x: w * dx, y: h * dy, width: w * 0.16, height: h * 0.18))
                    ctx.fill(toe, with: .color(Color(hex: "#F4A499")))
                    ctx.stroke(toe, with: .color(ink), lineWidth: 1.0)
                }

            case .teaserWand:
                // Wooden stick + pastel pink feather + gold bell
                var stick = Path()
                stick.move(to: CGPoint(x: w * 0.14, y: h * 0.86))
                stick.addLine(to: CGPoint(x: w * 0.68, y: h * 0.22))
                ctx.stroke(stick, with: .color(Color(hex: "#B5814E")), style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
                let feather = Path(ellipseIn: CGRect(x: w * 0.52, y: h * 0.22, width: w * 0.38, height: h * 0.24))
                ctx.fill(feather, with: .color(Color(hex: "#F29C8E")))
                ctx.stroke(feather, with: .color(ink), lineWidth: 1.0)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.62, y: h * 0.14, width: w * 0.16, height: h * 0.16)), with: .color(Color(hex: "#F5C85B")))

            case .fishSnack:
                // Adorable golden taiyaki fish biscuit
                var tail = Path()
                tail.move(to: CGPoint(x: w * 0.68, y: h * 0.50))
                tail.addLine(to: CGPoint(x: w * 0.90, y: h * 0.30))
                tail.addLine(to: CGPoint(x: w * 0.90, y: h * 0.70))
                tail.closeSubpath()
                ctx.fill(tail, with: .color(Color(hex: "#E5A557")))
                ctx.stroke(tail, with: .color(ink), lineWidth: 1.1)
                let body = Path(ellipseIn: CGRect(x: w * 0.12, y: h * 0.26, width: w * 0.62, height: h * 0.48))
                ctx.fill(body, with: .color(Color(hex: "#F2BE72")))
                ctx.stroke(body, with: .color(ink), lineWidth: 1.1)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.26, y: h * 0.42, width: 3.2, height: 3.2)), with: .color(ink))

            case .cozyBlanket:
                // Pastel folded quilted blanket + mini star
                let quilt = Path(roundedRect: CGRect(x: w * 0.12, y: h * 0.28, width: w * 0.76, height: h * 0.52), cornerRadius: 8)
                ctx.fill(quilt, with: .color(Color(hex: "#9ABBD0")))
                ctx.stroke(quilt, with: .color(Color(hex: "#FFF9EE")), style: StrokeStyle(lineWidth: 1.4, dash: [3, 2]))
                ctx.stroke(quilt, with: .color(ink), lineWidth: 1.1)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.64, y: h * 0.12, width: 6, height: 6)), with: .color(Color(hex: "#F5C85B")))

            case .happyTwirl:
                // Sparkling music notes
                let head1 = Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.58, width: w * 0.24, height: h * 0.20))
                let head2 = Path(ellipseIn: CGRect(x: w * 0.56, y: h * 0.50, width: w * 0.24, height: h * 0.20))
                ctx.fill(head1, with: .color(Color(hex: "#E67365")))
                ctx.fill(head2, with: .color(Color(hex: "#F0AE4A")))
                var stems = Path()
                stems.move(to: CGPoint(x: w * 0.40, y: h * 0.66))
                stems.addLine(to: CGPoint(x: w * 0.40, y: h * 0.24))
                stems.addLine(to: CGPoint(x: w * 0.78, y: h * 0.18))
                stems.addLine(to: CGPoint(x: w * 0.78, y: h * 0.58))
                ctx.stroke(stems, with: .color(ink), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

            case .walkBuddy:
                // Cute glowing leash heart-bell
                let heart = Path(ellipseIn: CGRect(x: w * 0.22, y: h * 0.22, width: w * 0.56, height: h * 0.56))
                ctx.fill(heart, with: .color(Color(hex: "#67A885")))
                ctx.stroke(heart, with: .color(ink), lineWidth: 1.2)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.36, y: h * 0.44, width: w * 0.28, height: h * 0.20)), with: .color(Color(hex: "#FFFDF7")))
                for dx in [0.34, 0.46, 0.58] {
                    ctx.fill(Path(ellipseIn: CGRect(x: w * dx, y: h * 0.33, width: w * 0.08, height: h * 0.08)), with: .color(Color(hex: "#FFFDF7")))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 7. Cute Plump Candy-Storybook Button (Rounded Ears/Stitches + Glossy Top Highlight + Jelly Press)
enum CutePlushTone {
    case butterHoney
    case strawberryCream
    case matchaMint
    case milkCream
    case berryRose

    var fillTop: Color {
        switch self {
        case .butterHoney:     return Color(hex: "#F8CF70")
        case .strawberryCream: return Color(hex: "#EB8472")
        case .matchaMint:      return Color(hex: "#5D9E83")
        case .milkCream:       return Color(hex: "#FFFDF7")
        case .berryRose:       return Color(hex: "#C8677E")
        }
    }

    var fillBottom: Color {
        switch self {
        case .butterHoney:     return Color(hex: "#E2A63B")
        case .strawberryCream: return Color(hex: "#D2614E")
        case .matchaMint:      return Color(hex: "#3E7D65")
        case .milkCream:       return Color(hex: "#F4EBD7")
        case .berryRose:       return Color(hex: "#A54960")
        }
    }

    var lip: Color {
        switch self {
        case .butterHoney:     return Color(hex: "#AD761B")
        case .strawberryCream: return Color(hex: "#9B3D2E")
        case .matchaMint:      return Color(hex: "#265947")
        case .milkCream:       return Color(hex: "#CFC0A3")
        case .berryRose:       return Color(hex: "#732C3F")
        }
    }

    var text: Color {
        switch self {
        case .milkCream:   return Color(hex: "#3A2C25")
        case .butterHoney: return Color(hex: "#4A3114")
        default:           return Color(hex: "#FFFDF8")
        }
    }
}

struct CutePlushButton<Icon: View>: View {
    let title: String
    var tone: CutePlushTone = .matchaMint
    var fontSize: CGFloat = 13
    var horizontalPadding: CGFloat = 14
    var verticalPadding: CGFloat = 9
    var fullWidth: Bool = false
    let icon: () -> Icon
    let action: () -> Void

    var body: some View {
        Button {
            HapticsEngine.shared.playBrushStrokeTick()
            action()
        } label: {
            HStack(spacing: 6) {
                icon()
                Text(title)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(tone.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                ZStack {
                    Capsule()
                        .fill(tone.lip)
                        .offset(y: 3.5)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tone.fillTop, tone.fillBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Soft candy gloss highlight along top curve
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.42), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .padding(2)

                    // Cute stitched inner line
                    Capsule()
                        .stroke(Color.white.opacity(tone == .milkCream ? 0.8 : 0.45), style: StrokeStyle(lineWidth: 1.0, dash: [3.5, 2.5]))
                        .padding(3)

                    Capsule()
                        .stroke(Color(hex: "#4A382E").opacity(0.24), lineWidth: 1.1)
                }
            )
            .padding(.bottom, 3.5)
            .shadow(color: Color(hex: "#4A382E").opacity(0.18), radius: 5, y: 3)
        }
        .buttonStyle(TactileGameButtonStyle(pressScale: 0.92, pressOffsetY: 2.5))
    }
}

// MARK: - 8. Cute Cat-Ear Top Decoration (For Pet Nameplates & Special Cards)
struct CatEarAccentShape: View {
    var fillColor: Color = Color(hex: "#FFFDF7")
    var innerEarColor: Color = Color(hex: "#F4B4A8")
    var strokeColor: Color = Color(hex: "#B89872")

    var body: some View {
        HStack(spacing: 34) {
            singleEar(angle: -14)
            singleEar(angle: 14)
        }
    }

    private func singleEar(angle: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(fillColor)
                .frame(width: 15, height: 15)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(strokeColor, lineWidth: 1.1))
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(innerEarColor)
                .frame(width: 7, height: 7)
        }
        .rotationEffect(.degrees(45 + angle))
    }
}
