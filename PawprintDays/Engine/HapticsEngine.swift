import Foundation
import CoreHaptics
import UIKit

@MainActor
final class HapticsEngine {
    static let shared = HapticsEngine()

    private var engine: CHHapticEngine?
    private var activePurrPlayer: CHHapticPatternPlayer?
    private let supportsHaptics: Bool

    private init() {
        self.supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        prepareEngineIfNeeded()
    }

    private func prepareEngineIfNeeded() {
        guard supportsHaptics else { return }
        if engine == nil {
            do {
                let newEngine = try CHHapticEngine()
                newEngine.playsHapticsOnly = true
                newEngine.resetHandler = { [weak self] in
                    Task { @MainActor in
                        try? self?.engine?.start()
                    }
                }
                try newEngine.start()
                self.engine = newEngine
            } catch {
                self.engine = nil
            }
        } else {
            try? engine?.start()
        }
    }

    /// 1. Entering 75m Paw Range: double 20ms soft tap (0.45 intensity)
    func playPawRangeCue() {
        if playBundledAHAP(named: "paw_range") { return }
        let gen = UIImpactFeedbackGenerator(style: .soft)
        gen.impactOccurred(intensity: 0.45)
    }

    /// 2. Hold-to-Greet Cat Purr: continuous 26 Hz wave ramping 0.18 -> 0.60 over 2.5s
    func startHoldToGreetPurr() {
        stopHoldToGreetPurr()
        guard supportsHaptics else { return }
        prepareEngineIfNeeded()
        guard let engine else { return }

        if let url = Bundle.main.url(forResource: "cat_purr", withExtension: "ahap"),
           let pattern = try? CHHapticPattern(contentsOf: url),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: CHHapticTimeImmediate)
            activePurrPlayer = player
            return
        }

        // Programmatic fallback if .ahap is absent in test bundle
        let continuous = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.14)
            ],
            relativeTime: 0,
            duration: 2.5
        )
        let ramp = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.18),
                .init(relativeTime: 1.25, value: 0.40),
                .init(relativeTime: 2.5, value: 0.60)
            ],
            relativeTime: 0
        )
        if let pattern = try? CHHapticPattern(events: [continuous], parameterCurves: [ramp]),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: CHHapticTimeImmediate)
            activePurrPlayer = player
        }
    }

    func stopHoldToGreetPurr() {
        try? activePurrPlayer?.stop(atTime: CHHapticTimeImmediate)
        activePurrPlayer = nil
    }

    /// 3. Dog Ball Roll: 3.2 Hz warm thump
    func playDogBallRoll() {
        if playBundledAHAP(named: "dog_ball_roll") { return }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred(intensity: 0.55)
    }

    /// 4. Curio Unpack: crisp paper flip + ink-stamp thud
    func playCurioUnpack() {
        if playBundledAHAP(named: "curio_unpack") { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    func playBrushStrokeTick() {
        guard supportsHaptics else { return }
        let gen = UISelectionFeedbackGenerator()
        gen.selectionChanged()
    }

    @discardableResult
    private func playBundledAHAP(named resource: String) -> Bool {
        guard supportsHaptics else { return false }
        prepareEngineIfNeeded()
        guard let engine,
              let url = Bundle.main.url(forResource: resource, withExtension: "ahap") else {
            return false
        }
        do {
            try engine.playPattern(from: url)
            return true
        } catch {
            return false
        }
    }
}
