#if DEBUG
import SwiftUI

struct AnimationGalleryView: View {
    enum Backdrop: String, CaseIterable {
        case sunroom = "Sunroom floor"
        case street = "Street"
        case white = "White"
        case black = "Black"
    }

    @Environment(\.dismiss) private var dismiss
    @State private var petID = PetCatalog.allPets[0].id
    @State private var clipName = "idle"
    @State private var backdrop = Backdrop.sunroom
    @State private var speed = 1.0
    @State private var isPlaying = true
    @State private var onion = false
    @State private var mirrored = false
    @State private var showOutfit = false
    @State private var step = 0
    @State private var started = Date()
    @State private var playhead = 0.0

    private var clips: [String: CelClip] {
        CelLibrary.legacy.merging(CelLibrary.manifest(for: petID)?.clips ?? [:]) { _, authored in authored }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Pet", selection: $petID) {
                    ForEach(PetCatalog.allPets, id: \.id) { pet in Text(pet.name).tag(pet.id) }
                }
                Picker("Clip", selection: $clipName) {
                    ForEach(clips.keys.sorted(), id: \.self) { name in Text(name).tag(name) }
                }
                if let clip = clips[clipName] {
                    let player = CelClipPlayer(clip)
                    TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isPlaying)) { timeline in
                        let elapsed = playhead + max(0, timeline.date.timeIntervalSince(started)) * speed
                        let index = isPlaying ? player.step(at: elapsed) : min(step, player.order.count - 1)
                        preview(player: player, index: index, elapsed: isPlaying ? elapsed : player.startTime(of: index))
                        Text("Drawing \(player.order[index]) of \(clip.frames)")
                            .font(.caption.monospacedDigit())
                    }
                    Stepper("Step through clip") {
                        stepFrame(by: 1, player: player)
                    } onDecrement: {
                        stepFrame(by: -1, player: player)
                    }
                    Button(isPlaying ? "Pause" : "Play") {
                        let now = Date()
                        if isPlaying {
                            step = player.step(at: playhead + now.timeIntervalSince(started) * speed)
                        } else {
                            playhead = player.startTime(of: min(step, player.order.count - 1))
                            started = now
                        }
                        isPlaying.toggle()
                    }
                }
                Slider(value: $speed, in: 0.25...2, step: 0.25) {
                    Text("Playback speed")
                } minimumValueLabel: {
                    Text("0.25×")
                } maximumValueLabel: {
                    Text("2×")
                }
                Text(speed, format: .number.precision(.fractionLength(2))) + Text("×")
                Picker("Background", selection: $backdrop) {
                    ForEach(Backdrop.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Toggle("Onion skin", isOn: $onion)
                Toggle("Mirror", isOn: $mirrored)
                Toggle("Outfit", isOn: $showOutfit)
            }
            .navigationTitle("Animation Gallery")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .onChange(of: petID) { _, _ in
            if clips[clipName] == nil { clipName = "idle" }
            reset()
        }
        .onChange(of: clipName) { _, _ in reset() }
        .onChange(of: speed) { previousSpeed, _ in
            let now = Date()
            if isPlaying { playhead += now.timeIntervalSince(started) * previousSpeed }
            started = now
        }
    }

    private func stepFrame(by offset: Int, player: CelClipPlayer) {
        let current = isPlaying ? player.step(at: playhead + Date().timeIntervalSince(started) * speed) : step
        step = min(player.order.count - 1, max(0, current + offset))
        isPlaying = false
    }

    private func reset() {
        playhead = 0
        started = .now
        step = 0
    }

    private func preview(player: CelClipPlayer, index: Int, elapsed: Double) -> some View {
        let prefix = CelLibrary.prefix(for: petID)
        let manifest = CelLibrary.manifest(for: petID)
        let neck = player.clip.anchors?.neck ?? manifest?.anchors?.neck
        let strideLength = player.clip.strideLengthUV ?? manifest?.strideLengthUV
        let gait = CelStride(lengthUV: strideLength, player: player)
        return ZStack {
            switch backdrop {
            case .sunroom:
                Image("bg_home_sunroom").resizable().scaledToFill()
                if player.clip.bank.hasPrefix("w") {
                    Canvas { context, size in
                        var grid = Path()
                        let sign = (player.clip.bank == "wr") != mirrored ? -1.0 : 1.0
                        let travel = gait.map { elapsed / $0.cycleDuration * $0.lengthUV } ?? 0
                        let xOffset = sign * (travel * size.width).truncatingRemainder(dividingBy: 16)
                        let zOffset = (travel * size.height * 0.27).truncatingRemainder(dividingBy: 12)
                        let depthWalk = ["wf", "wb"].contains(player.clip.bank)
                        for x in stride(from: -16.0 + (depthWalk ? 0 : xOffset), through: size.width + 16, by: 16) {
                            grid.move(to: CGPoint(x: x, y: size.height * 0.72))
                            grid.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        let yOffset = depthWalk ? zOffset * (player.clip.bank == "wf" ? -1 : 1) : 0
                        for y in stride(from: size.height * 0.72 + yOffset, through: size.height + 12, by: 12) {
                            grid.move(to: CGPoint(x: 0, y: y))
                            grid.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        context.stroke(grid, with: .color(.white.opacity(0.5)), lineWidth: 1)
                    }
                }
            case .street: TaiwaneseBakeryStorybookBackdrop(weather: .clearMorning)
            case .white: Color.white
            case .black: Color.black
            }

            ZStack {
                if onion {
                    ForEach([-1, 1], id: \.self) { offset in
                        if let frame = player.neighbor(of: index, offset: offset),
                           let image = CelFrameImageCache.shared.image(named: player.clip.asset(prefix: prefix, frame: frame)) {
                            Image(uiImage: image).resizable().scaledToFit().opacity(0.3)
                        }
                    }
                }
                ProceduralPetRigView(pet: PetCatalog.pet(id: petID),
                                     outfitID: showOutfit ? ShopCatalog.items.first(where: { $0.slotType == "socket_neck" })?.id : nil,
                                     applyMetalPaperShader: false, isStaticSnapshot: true,
                                     previewFrame: player.clip.asset(prefix: prefix, frame: player.order[index]),
                                     previewNeck: neck)
            }
            .frame(width: 215, height: 215)
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
        }
        .frame(height: 230)
        .clipped()
    }
}
#endif
