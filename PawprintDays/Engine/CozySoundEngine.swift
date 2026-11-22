import Foundation
import AVFoundation
import Observation

/// Lightweight 100% procedural cozy foley, pet purr/chirp, rain ambience & gentle pentatonic kalimba BGM synthesizer via AVAudioEngine.
/// - Zero bundled audio files, tiny memory footprint.
/// - Uses `.ambient` + `.mixWithOthers` so it ALWAYS respects the iPhone Silent Switch
///   and never interrupts the user's music or podcasts while commuting.
@MainActor
@Observable
final class CozySoundEngine {
    static let shared = CozySoundEngine()

    private static let soundEnabledKey = "pawprintdays.audio.soundEnabled.v1"
    private static let musicEnabledKey = "pawprintdays.audio.musicEnabled.v1"

    var isSoundEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: Self.soundEnabledKey)
            if !isSoundEnabled {
                stopRainAmbience()
                stopCozyMusic()
            }
        }
    }

    var isMusicEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: Self.musicEnabledKey)
            if !isMusicEnabled {
                stopCozyMusic()
            } else if isSoundEnabled {
                setCozyMusic(active: true, weather: currentMusicWeather)
            }
        }
    }

    private var engine: AVAudioEngine?
    private var foleyPlayer: AVAudioPlayerNode?
    private var rainPlayer: AVAudioPlayerNode?
    private var musicPlayer: AVAudioPlayerNode?
    private var roomReverb: AVAudioUnitReverb?
    private var format: AVAudioFormat?
    private var isEngineRunning: Bool = false
    private var isRainPlaying: Bool = false
    private var isMusicPlaying: Bool = false
    private var currentMusicWeather: WeatherMode = .clearMorning

    private init() {
        if UserDefaults.standard.object(forKey: Self.soundEnabledKey) != nil {
            self.isSoundEnabled = UserDefaults.standard.bool(forKey: Self.soundEnabledKey)
        }
        if UserDefaults.standard.object(forKey: Self.musicEnabledKey) != nil {
            self.isMusicEnabled = UserDefaults.standard.bool(forKey: Self.musicEnabledKey)
        }
        setupSessionAndEngine()
    }

    private func setupSessionAndEngine() {
        #if targetEnvironment(simulator)
        return
        #else
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])

            let eng = AVAudioEngine()
            let foley = AVAudioPlayerNode()
            let rain = AVAudioPlayerNode()
            let music = AVAudioPlayerNode()
            let reverb = AVAudioUnitReverb()
            reverb.loadFactoryPreset(.smallRoom)
            reverb.wetDryMix = 14.0

            eng.attach(foley)
            eng.attach(rain)
            eng.attach(music)
            eng.attach(reverb)

            let sampleRate: Double = 44_100
            guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
            eng.connect(foley, to: reverb, format: fmt)
            eng.connect(music, to: reverb, format: fmt)
            eng.connect(reverb, to: eng.mainMixerNode, format: fmt)
            eng.connect(rain, to: eng.mainMixerNode, format: fmt)
            eng.mainMixerNode.outputVolume = 0.65

            try eng.start()
            self.engine = eng
            self.foleyPlayer = foley
            self.rainPlayer = rain
            self.musicPlayer = music
            self.roomReverb = reverb
            self.format = fmt
            self.isEngineRunning = true
        } catch {
            self.isEngineRunning = false
        }
        #endif
    }

    private func ensureRunning() -> (AVAudioPlayerNode, AVAudioFormat)? {
        guard isSoundEnabled else { return nil }
        if !isEngineRunning { setupSessionAndEngine() }
        guard isEngineRunning, let player = foleyPlayer, let fmt = format else { return nil }
        if let eng = engine, !eng.isRunning { try? eng.start() }
        if !player.isPlaying { player.play() }
        return (player, fmt)
    }

    // MARK: - Cozy Foley & Species Vocalizations

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

    /// Soft wooden floor paw-tap cue when calling a pet over in the 2.5D Sunroom
    func playPawTap() {
        guard let (player, fmt) = ensureRunning() else { return }
        let buffer = synthesizeWoodTapBuffer(format: fmt, duration: 0.11, gain: 0.14)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Soft velvet grooming brush / towel-dry swish
    func playBrushSwish() {
        guard let (player, fmt) = ensureRunning() else { return }
        let buffer = synthesizeFilteredNoise(format: fmt, duration: 0.22, cutoffAlpha: 0.08, gain: 0.11)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Gentle warm feline purr rumble (26 Hz amplitude-modulated soft warmth)
    func playPetPurr() {
        guard let (player, fmt) = ensureRunning() else { return }
        let buffer = synthesizePurrBuffer(format: fmt, duration: 0.52, gain: 0.12)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Soft cheerful puppy/spirit chirp (ascending gentle pentatonic trill)
    func playPetChirp() {
        guard let (player, fmt) = ensureRunning() else { return }
        let buffer = synthesizeChirpBuffer(format: fmt, duration: 0.24, gain: 0.10)
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

    // MARK: - Ambient Rain & Gentle Pentatonic Kalimba Lullaby

    func setRainAmbience(active: Bool) {
        guard isSoundEnabled && active else {
            stopRainAmbience()
            return
        }
        guard !isRainPlaying, isEngineRunning, let rain = rainPlayer, let fmt = format else { return }
        if let eng = engine, !eng.isRunning { try? eng.start() }
        let loopBuffer = synthesizeRainLoop(format: fmt, duration: 2.4, gain: 0.042)
        rain.scheduleBuffer(loopBuffer, at: nil, options: [.loops], completionHandler: nil)
        rain.play()
        isRainPlaying = true
    }

    func stopRainAmbience() {
        guard isRainPlaying else { return }
        rainPlayer?.stop()
        isRainPlaying = false
    }

    /// Soft procedural kalimba / music-box loop that harmonizes gently with the Sunroom weather
    func setCozyMusic(active: Bool, weather: WeatherMode) {
        currentMusicWeather = weather
        guard isSoundEnabled && isMusicEnabled && active else {
            stopCozyMusic()
            return
        }
        guard isEngineRunning, let music = musicPlayer, let fmt = format else { return }
        if let eng = engine, !eng.isRunning { try? eng.start() }
        music.stop()
        let loopBuffer = synthesizeKalimbaLoop(format: fmt, weather: weather, gain: 0.055)
        music.scheduleBuffer(loopBuffer, at: nil, options: [.loops], completionHandler: nil)
        music.play()
        isMusicPlaying = true
    }

    func stopCozyMusic() {
        guard isMusicPlaying else { return }
        musicPlayer?.stop()
        isMusicPlaying = false
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

    private func synthesizeWoodTapBuffer(format: AVAudioFormat, duration: Double, gain: Float) -> AVAudioPCMBuffer {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        let sr = format.sampleRate
        for i in 0..<Int(count) {
            let t = Double(i) / sr
            let env = exp(-t * 42.0)
            let tone = sin(2.0 * .pi * 240.0 * t) * 0.7 + sin(2.0 * .pi * 510.0 * t) * 0.3
            ptr[i] = Float(tone * env) * gain
        }
        return buffer
    }

    private func synthesizePurrBuffer(format: AVAudioFormat, duration: Double, gain: Float) -> AVAudioPCMBuffer {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        let sr = format.sampleRate
        for i in 0..<Int(count) {
            let t = Double(i) / sr
            let env = sin(min(1.0, t / duration) * .pi)
            let mod = 0.55 + 0.45 * sin(2.0 * .pi * 26.0 * t)
            let carrier = sin(2.0 * .pi * 78.0 * t) * 0.65 + sin(2.0 * .pi * 156.0 * t) * 0.35
            ptr[i] = Float(carrier * mod * env) * gain
        }
        return buffer
    }

    private func synthesizeChirpBuffer(format: AVAudioFormat, duration: Double, gain: Float) -> AVAudioPCMBuffer {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        let sr = format.sampleRate
        var phase = 0.0
        for i in 0..<Int(count) {
            let t = Double(i) / sr
            let p = t / duration
            let freq = 480.0 + 260.0 * sin(p * .pi * 0.85)
            phase += 2.0 * .pi * freq / sr
            let env = sin(p * .pi) * exp(-p * 1.4)
            ptr[i] = Float(sin(phase) * env) * gain
        }
        return buffer
    }

    private func synthesizeKalimbaLoop(format: AVAudioFormat, weather: WeatherMode, gain: Float) -> AVAudioPCMBuffer {
        // Gentle 8-second cozy pentatonic lullaby bar (8 notes spaced 1.0s apart with warm resonant decay)
        let duration = 8.0
        let count = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        let sr = format.sampleRate
        let notes: [Double] = {
            switch weather {
            case .lightRain, .postRain:
                return [329.63, 392.00, 440.00, 493.88, 392.00, 329.63, 293.66, 392.00] // dreamy rain E-minor/G
            case .dusk:
                return [261.63, 329.63, 392.00, 493.88, 440.00, 392.00, 329.63, 293.66] // warm Cmaj7 dusk
            default:
                return [261.63, 329.63, 392.00, 523.25, 440.00, 392.00, 329.63, 392.00] // sunlit morning C-pentatonic
            }
        }()

        for i in 0..<Int(count) {
            ptr[i] = 0
        }

        for (idx, freq) in notes.enumerated() {
            let startSample = Int(Double(idx) * 1.0 * sr)
            let noteLen = Int(1.85 * sr)
            for k in 0..<noteLen {
                let sampleIdx = (startSample + k) % Int(count)
                let t = Double(k) / sr
                let attack = min(1.0, t / 0.018)
                let decay = exp(-t * 3.4)
                let tone = sin(2.0 * .pi * freq * t) * 0.78 + sin(2.0 * .pi * freq * 2.0 * t) * 0.18
                ptr[sampleIdx] += Float(tone * attack * decay) * gain
            }
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
            let edge = min(Double(i) / 2000.0, Double(n - 1 - i) / 2000.0, 1.0)
            ptr[i] = pink * Float(edge) * gain
        }
        return buffer
    }
}
