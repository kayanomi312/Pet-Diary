import Foundation
import CoreHaptics
import UIKit
import Observation

@MainActor
@Observable
final class HapticsEngine {
    static let shared = HapticsEngine()

    private static let hapticsEnabledKey = "pawprintdays.haptics.enabled.v1"

    var isHapticsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: Self.hapticsEnabledKey)
            if !isHapticsEnabled {
                stopHoldToGreetPurr()
            }
        }
    }

    private var engine: CHHapticEngine?
    private var engineNeedsStart: Bool = true
    private var activePurrPlayer: CHHapticPatternPlayer?
    private let supportsHaptics: Bool

    // Reused UIKit feedback generators (zero per-tap allocation overhead)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let selectionGen = UISelectionFeedbackGenerator()
    private let notificationGen = UINotificationFeedbackGenerator()

    private init() {
        self.supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        if UserDefaults.standard.object(forKey: Self.hapticsEnabledKey) != nil {
            self.isHapticsEnabled = UserDefaults.standard.bool(forKey: Self.hapticsEnabledKey)
        }
        prepareEngineIfNeeded()
    }

    private func prepareEngineIfNeeded() {
        guard supportsHaptics && isHapticsEnabled else { return }
        if engine == nil {
            do {
                let newEngine = try CHHapticEngine()
                newEngine.playsHapticsOnly = true
                newEngine.stoppedHandler = { [weak self] _ in
                    Task { @MainActor in
                        self?.engineNeedsStart = true
                    }
                }
                newEngine.resetHandler = { [weak self] in
                    Task { @MainActor in
                        self?.engineNeedsStart = true
                        try? self?.engine?.start()
                        self?.engineNeedsStart = false
                    }
                }
                try newEngine.start()
                self.engine = newEngine
                self.engineNeedsStart = false
            } catch {
                self.engine = nil
                self.engineNeedsStart = true
            }
        } else if engineNeedsStart {
            do {
                try engine?.start()
                engineNeedsStart = false
            } catch {
                engineNeedsStart = true
            }
        }
    }

    /// 1. Entering 75m Paw Range: double 20ms soft tap (0.45 intensity)
    func playPawRangeCue() {
        guard isHapticsEnabled else { return }
        if playBundledAHAP(named: "paw_range") { return }
        softImpact.prepare()
        softImpact.impactOccurred(intensity: 0.45)
    }

    /// 2. Hold-to-Greet Cat Purr: continuous 26 Hz wave ramping 0.18 -> 0.60 over 2.5s
    func startHoldToGreetPurr() {
        stopHoldToGreetPurr()
        guard supportsHaptics && isHapticsEnabled else { return }
        prepareEngineIfNeeded()
        guard let engine else { return }

        if let url = Bundle.main.url(forResource: "cat_purr", withExtension: "ahap"),
           let pattern = try? CHHapticPattern(contentsOf: url),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: CHHapticTimeImmediate)
            activePurrPlayer = player
            return
        }

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
        guard isHapticsEnabled else { return }
        if playBundledAHAP(named: "dog_ball_roll") { return }
        mediumImpact.prepare()
        mediumImpact.impactOccurred(intensity: 0.55)
    }

    /// 4. Curio Unpack: crisp paper flip + ink-stamp thud
    func playCurioUnpack() {
        guard isHapticsEnabled else { return }
        if playBundledAHAP(named: "curio_unpack") { return }
        notificationGen.prepare()
        notificationGen.notificationOccurred(.success)
    }

    func playBrushStrokeTick() {
        guard supportsHaptics && isHapticsEnabled else { return }
        selectionGen.prepare()
        selectionGen.selectionChanged()
    }

    @discardableResult
    private func playBundledAHAP(named resource: String) -> Bool {
        guard supportsHaptics && isHapticsEnabled else { return false }
        prepareEngineIfNeeded()
        guard let engine,
              let url = Bundle.main.url(forResource: resource, withExtension: "ahap") else {
            return false
        }
        do {
            try engine.playPattern(from: url)
            return true
        } catch {
            engineNeedsStart = true
            return false
        }
    }
}
