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
                .rotationEffect(.degrees(pulse ? 2.5 : -2.5))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
