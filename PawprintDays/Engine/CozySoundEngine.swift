import Foundation
import AVFoundation
import Observation

/// Lightweight 100% procedural cozy foley & rain ambience synthesizer via AVAudioEngine.
/// - Zero bundled audio files, tiny memory footprint.
/// - Uses `.ambient` + `.mixWithOthers` so it ALWAYS respects the iPhone Silent Switch
///   and never interrupts the user's music or podcasts while commuting.
@MainActor
@Observable
final class CozySoundEngine {
    static let shared = CozySoundEngine()

    var isSoundEnabled: Bool = true {
        didSet {
            if !isSoundEnabled {
                stopRainAmbience()
            }
        }
    }

    private var engine: AVAudioEngine?
    private var foleyPlayer: AVAudioPlayerNode?
    private var rainPlayer: AVAudioPlayerNode?
    private var format: AVAudioFormat?
    private var isEngineRunning: Bool = false
    private var isRainPlaying: Bool = false

    private init() {
        setupSessionAndEngine()
    }

    private func setupSessionAndEngine() {
        #if targetEnvironment(simulator)
        // Keep Simulator unit tests & preview launches completely quiet and zero-overhead
        return
        #else
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])

            let eng = AVAudioEngine()
            let foley = AVAudioPlayerNode()
            let rain = AVAudioPlayerNode()
            eng.attach(foley)
            eng.attach(rain)

            let sampleRate: Double = 44_100
            guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
            eng.connect(foley, to: eng.mainMixerNode, format: fmt)
            eng.connect(rain, to: eng.mainMixerNode, format: fmt)
            eng.mainMixerNode.outputVolume = 0.65

            try eng.start()
            self.engine = eng
            self.foleyPlayer = foley
            self.rainPlayer = rain
            self.format = fmt
            self.isEngineRunning = true
        } catch {
            self.isEngineRunning = false
        }
        #endif
    }

    private func ensureRunning() -> (AVAudioPlayerNode, AVAudioFormat)? {
        guard isSoundEnabled else { return nil }
        if !isEngineRunning {
            setupSessionAndEngine()
        }
        guard isEngineRunning, let player = foleyPlayer, let fmt = format else { return nil }
        if let eng = engine, !eng.isRunning {
            try? eng.start()
        }
        if !player.isPlaying {
            player.play()
        }
        return (player, fmt)
    }

    /// Warm brass compass / arrival chime (gentle C5 + G5 soft bell decay)
    func playCompassChime() {
        guard let (player, fmt) = ensureRunning() else { return }
        let buffer = synthesizeBellBuffer(format: fmt, frequencies: [523.25, 783.99], duration: 0.42, gain: 0.14)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Crisp cotton-rag paper flip + warm wooden ink stamp thud
    func playPaperFlip() {
        guard let (player, fmt) = ensureRunning() else { return }
        let buffer = synthesizePaperBuffer(format: fmt, duration: 0.19, gain: 0.16)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Soft velvet grooming brush / towel-dry swish
    func playBrushSwish() {
        guard let (player, fmt) = ensureRunning() else { return }
        let buffer = synthesizeFilteredNoise(format: fmt, duration: 0.22, cutoffAlpha: 0.08, gain: 0.11)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Warm ceramic teapot chime (F5 + A5)
    func playTeapotClink() {
        guard let (player, fmt) = ensureRunning() else { return }
        let buffer = synthesizeBellBuffer(format: fmt, frequencies: [698.46, 880.0], duration: 0.36, gain: 0.12)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Gentle wardrobe ribbon snap / heirloom bell glint
    func playWardrobeSnap(withBell: Bool = false) {
        guard let (player, fmt) = ensureRunning() else { return }
        let freqs: [Double] = withBell ? [1046.5, 1567.98] : [587.33, 880.0]
        let buffer = synthesizeBellBuffer(format: fmt, frequencies: freqs, duration: 0.28, gain: 0.11)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Soft, non-fatiguing rain drizzle loop when viewing rainy scenes
    func setRainAmbience(active: Bool) {
        guard isSoundEnabled && active else {
            stopRainAmbience()
            return
        }
        guard !isRainPlaying, isEngineRunning, let rain = rainPlayer, let fmt = format else { return }
        if let eng = engine, !eng.isRunning {
            try? eng.start()
        }
        let loopBuffer = synthesizeRainLoop(format: fmt, duration: 2.4, gain: 0.045)
        rain.scheduleBuffer(loopBuffer, at: nil, options: [.loops], completionHandler: nil)
        rain.play()
        isRainPlaying = true
    }

    func stopRainAmbience() {
        guard isRainPlaying else { return }
        rainPlayer?.stop()
        isRainPlaying = false
    }

    // MARK: - Procedural DSP Buffer Builders
    private func synthesizeBellBuffer(format: AVAudioFormat, frequencies: [Double], duration: Double, gain: Float) -> AVAudioPCMBuffer {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        let sr = format.sampleRate

        for i in 0..<Int(count) {
            let t = Double(i) / sr
            let attack = min(1.0, t / 0.012)
            let decay = exp(-t * 8.5)
            var sample = 0.0
            for (idx, f) in frequencies.enumerated() {
                let weight = idx == 0 ? 1.0 : 0.45
                sample += sin(2.0 * .pi * f * t) * weight
            }
            ptr[i] = Float(sample * attack * decay) * gain
        }
        return buffer
    }

    private func synthesizePaperBuffer(format: AVAudioFormat, duration: Double, gain: Float) -> AVAudioPCMBuffer {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        let sr = format.sampleRate
        var lp: Float = 0

        for i in 0..<Int(count) {
            let t = Double(i) / sr
            let white = Float.random(in: -1...1)
            lp = lp + 0.16 * (white - lp)
            let rustleEnv = Float(sin(min(1.0, t / 0.11) * .pi)) * (t < 0.11 ? 1.0 : 0.0)
            // Soft low stamp thud around 0.11s
            let thudT = max(0.0, t - 0.105)
            let thud = (t >= 0.105) ? Float(sin(2.0 * .pi * 115.0 * thudT) * exp(-thudT * 38.0)) * 0.9 : 0.0
            ptr[i] = (lp * rustleEnv * 0.7 + thud) * gain
        }
        return buffer
    }

    private func synthesizeFilteredNoise(format: AVAudioFormat, duration: Double, cutoffAlpha: Float, gain: Float) -> AVAudioPCMBuffer {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        let n = Int(count)
        var lp: Float = 0
        for i in 0..<n {
            let phase = Double(i) / Double(max(1, n))
            let env = Float(sin(phase * .pi))
            let white = Float.random(in: -1...1)
            lp = lp + cutoffAlpha * (white - lp)
            ptr[i] = lp * env * gain
        }
        return buffer
    }

    private func synthesizeRainLoop(format: AVAudioFormat, duration: Double, gain: Float) -> AVAudioPCMBuffer {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        let n = Int(count)
        var b0: Float = 0, b1: Float = 0, b2: Float = 0
        for i in 0..<n {
            let white = Float.random(in: -1...1)
            b0 = 0.997 * b0 + white * 0.029
            b1 = 0.985 * b1 + white * 0.032
            b2 = 0.950 * b2 + white * 0.048
            let pink = (b0 + b1 + b2 + white * 0.018) * 0.35
            // Seamless crossfade edges for clean loop
            let edge = min(Double(i) / 2000.0, Double(n - 1 - i) / 2000.0, 1.0)
            ptr[i] = pink * Float(edge) * gain
        }
        return buffer
    }
}
