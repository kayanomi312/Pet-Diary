import SwiftUI
import UIKit

/// 不可變歷史水彩明信片烘焙器（將當下天氣、衣飾與動物完整定格成靜態 PNG）
@MainActor
enum DiarySnapshotBaker {
    static func bakeEncounterPostcardPNG(
        pet: PetSpec,
        outfitID: String?,
        secondaryPet: PetSpec? = nil,
        secondaryOutfitID: String? = nil,
        weather: WeatherMode,
        placeLabel: String,
        localDateISO: String,
        isWideSpread: Bool = false
    ) -> Data? {
        let postcard = BakedPostcardCanvas(
            pet: pet,
            outfitID: outfitID,
            secondaryPet: secondaryPet,
            secondaryOutfitID: secondaryOutfitID,
            weather: weather,
            placeLabel: placeLabel,
            localDateISO: localDateISO,
            isWideSpread: isWideSpread
        )
        let renderer = ImageRenderer(content: postcard)
        renderer.scale = 2.0
        guard let uiImage = renderer.uiImage else { return nil }
        return uiImage.pngData()
    }
}

private struct BakedPostcardCanvas: View {
    let pet: PetSpec
    let outfitID: String?
    let secondaryPet: PetSpec?
    let secondaryOutfitID: String?
    let weather: WeatherMode
    let placeLabel: String
    let localDateISO: String
    let isWideSpread: Bool

    private var canvasWidth: CGFloat { isWideSpread ? 380 : 300 }

    var body: some View {
        ZStack {
            TaiwaneseBakeryStorybookBackdrop(weather: weather, isStatic: true)

            if let secondaryPet {
                HStack(spacing: -24) {
                    ProceduralPetRigView(
                        pet: pet,
                        outfitID: outfitID,
                        pose: .respond,
                        weatherMode: weather,
                        isHappySquint: true,
                        applyMetalPaperShader: false,
                        isStaticSnapshot: true
                    )
                    .frame(width: 158, height: 158)

                    ProceduralPetRigView(
                        pet: secondaryPet,
                        outfitID: secondaryOutfitID,
                        pose: .notice,
                        weatherMode: weather,
                        isHappySquint: true,
                        applyMetalPaperShader: false,
                        isStaticSnapshot: true
                    )
                    .frame(width: 158, height: 158)
                }
                .offset(y: 10)
            } else {
                ProceduralPetRigView(
                    pet: pet,
                    outfitID: outfitID,
                    pose: .respond,
                    weatherMode: weather,
                    isHappySquint: true,
                    applyMetalPaperShader: false,
                    isStaticSnapshot: true
                )
                .frame(width: 185, height: 185)
                .offset(y: 6)
            }

            VStack {
                HStack {
                    Text(isWideSpread ? "\(weather.displayName) · 炭筆跨頁" : weather.displayName)
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundStyle(AppTheme.deepPineInk.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.warmPaper.opacity(0.86), in: Capsule())
                    Spacer()
                    Text(localDateISO)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.softInk)
                }
                .padding(10)
                Spacer()
                HStack {
                    Text(placeLabel)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(AppTheme.deepPineInk)
                    Spacer()
                    Text(outfitCaption)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.forestTeal)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.warmPaper.opacity(0.92))
            }
        }
        .frame(width: canvasWidth, height: 220)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.warmPaper, lineWidth: 6))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var outfitCaption: String {
        if let secondaryPet {
            return "\(pet.name) 與 \(secondaryPet.name)"
        }
        if let outfitID, let item = ShopCatalog.item(id: outfitID) {
            return item.name
        }
        return "素頸"
    }

    private var backdropColors: [Color] {
        switch weather {
        case .lightRain, .postRain:
            return [Color(hex: "#D6E1E5"), Color(hex: "#EDEAE0")]
        case .dusk:
            return [Color(hex: "#F2DEC6"), Color(hex: "#E5CEB8")]
        case .clearMorning:
            return [Color(hex: "#F5F1E3"), Color(hex: "#E5EDE6")]
        case .overcast:
            return [Color(hex: "#EAE7DF"), Color(hex: "#DFDFD7")]
        }
    }
}
