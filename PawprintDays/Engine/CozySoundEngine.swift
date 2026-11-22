import Foundation
import AVFoundation
import Observation

/// Lightweight 100% procedural cozy foley, pet purr/chirp, rain ambience & gentle pentatonic kalimba BGM synthesizer via AVAudioEngine.
/// - Zero bundled audio files, tiny memory footprint.
/// - Uses `.ambient` + `.mixWithOthers` so it ALWAYS respects the iPhone Silent Switch
///   and never interrupts the user's music or podcasts while commuting.
/// - Strictly uses 2-channel stereo buffers matching `AVAudioUnitReverb` and guards every
///   `AVAudioPlayerNode.play()` against stopped/reconfigured audio graphs so ObjC NSExceptions can never occur.
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
    private var reverbBusMixer: AVAudioMixerNode?
    private var roomReverb: AVAudioUnitReverb?
    private var format: AVAudioFormat?
    private var isEngineRunning: Bool = false
    private var isRainPlaying: Bool = false
    private var isMusicPlaying: Bool = false
    private var currentMusicWeather: WeatherMode = .clearMorning
    private var observersInstalled: Bool = false

    private init() {
        if UserDefaults.standard.object(forKey: Self.soundEnabledKey) != nil {
            self.isSoundEnabled = UserDefaults.standard.bool(forKey: Self.soundEnabledKey)
        }
        if UserDefaults.standard.object(forKey: Self.musicEnabledKey) != nil {
            self.isMusicEnabled = UserDefaults.standard.bool(forKey: Self.musicEnabledKey)
        }
        installAudioLifecycleObservers()
        setupSessionAndEngine()
    }

    private func installAudioLifecycleObservers() {
        guard !observersInstalled else { return }
        observersInstalled = true
        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAudioGraphReset()
            }
        }
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAudioGraphReset()
            }
        }
    }

    private func handleAudioGraphReset() {
        foleyPlayer?.stop()
        rainPlayer?.stop()
        musicPlayer?.stop()
        engine?.stop()
        engine = nil
        foleyPlayer = nil
        rainPlayer = nil
        musicPlayer = nil
        reverbBusMixer = nil
        roomReverb = nil
        format = nil
        isEngineRunning = false
        isRainPlaying = false
        isMusicPlaying = false
    }

    private func setupSessionAndEngine() {
        #if targetEnvironment(simulator)
        return
        #else
        handleAudioGraphReset()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])

            // Stereo 2-channel standard float format required by AVAudioUnitReverb!
            let sampleRate: Double = 44_100
            guard let stereoFmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return }

            // Primary graph: warm small-room wooden cottage reverb
            if buildAndStartGraph(format: stereoFmt, useReverb: true) {
                return
            }
            // Safe fallback: direct mixer connection without reverb if hardware route rejects AU reverb
            _ = buildAndStartGraph(format: stereoFmt, useReverb: false)
        } catch {
            self.isEngineRunning = false
        }
        #endif
    }

    @discardableResult
    private func buildAndStartGraph(format fmt: AVAudioFormat, useReverb: Bool) -> Bool {
        let eng = AVAudioEngine()
        let foley = AVAudioPlayerNode()
        let rain = AVAudioPlayerNode()
        let music = AVAudioPlayerNode()
        eng.attach(foley)
        eng.attach(rain)
        eng.attach(music)

        var attachedMixer: AVAudioMixerNode? = nil
        var attachedReverb: AVAudioUnitReverb? = nil
        if useReverb {
            // Route multiple players through a dedicated AVAudioMixerNode before single-input AVAudioUnitReverb!
            let subMixer = AVAudioMixerNode()
            let reverb = AVAudioUnitReverb()
            reverb.loadFactoryPreset(.smallRoom)
            reverb.wetDryMix = 14.0
            eng.attach(subMixer)
            eng.attach(reverb)
            eng.connect(foley, to: subMixer, format: fmt)
            eng.connect(music, to: subMixer, format: fmt)
            eng.connect(subMixer, to: reverb, format: fmt)
            eng.connect(reverb, to: eng.mainMixerNode, format: fmt)
            attachedMixer = subMixer
            attachedReverb = reverb
        } else {
            eng.connect(foley, to: eng.mainMixerNode, format: fmt)
            eng.connect(music, to: eng.mainMixerNode, format: fmt)
        }
        eng.connect(rain, to: eng.mainMixerNode, format: fmt)
        eng.mainMixerNode.outputVolume = 0.65

        do {
            eng.prepare()
            try eng.start()
            guard eng.isRunning,
                  !eng.outputConnectionPoints(for: foley, outputBus: 0).isEmpty,
                  !eng.outputConnectionPoints(for: music, outputBus: 0).isEmpty,
                  !eng.outputConnectionPoints(for: rain, outputBus: 0).isEmpty else {
                eng.stop()
                return false
            }
            self.engine = eng
            self.foleyPlayer = foley
            self.rainPlayer = rain
            self.musicPlayer = music
            self.reverbBusMixer = attachedMixer
            self.roomReverb = attachedReverb
            self.format = fmt
            self.isEngineRunning = true
            return true
        } catch {
            eng.stop()
            self.isEngineRunning = false
            return false
        }
    }

    private func ensureEngineStarted() -> (AVAudioEngine, AVAudioFormat)? {
        guard isSoundEnabled else { return nil }
        if !isEngineRunning || engine == nil || format == nil {
            setupSessionAndEngine()
        }
        guard let eng = engine, let fmt = format else { return nil }
        if !eng.isRunning {
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: [])
                try eng.start()
            } catch {
                handleAudioGraphReset()
                return nil
            }
        }
        guard eng.isRunning else { return nil }
        return (eng, fmt)
    }

    private func ensureRunning() -> (AVAudioPlayerNode, AVAudioFormat)? {
        guard let (eng, fmt) = ensureEngineStarted(),
              let player = foleyPlayer,
              player.engine === eng,
              !eng.outputConnectionPoints(for: player, outputBus: 0).isEmpty else { return nil }
        if !player.isPlaying {
            player.play()
        }
        return (player, fmt)
    }

    // MARK: - Cozy Foley & Species Vocalizations

    /// Warm brass compass / arrival chime (gentle C5 + G5 soft bell decay)
    func playCompassChime() {
        guard let (player, fmt) = ensureRunning(),
              let buffer = synthesizeBellBuffer(format: fmt, frequencies: [523.25, 783.99], duration: 0.42, gain: 0.14) else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Crisp cotton-rag paper flip + warm wooden ink stamp thud
    func playPaperFlip() {
        guard let (player, fmt) = ensureRunning(),
              let buffer = synthesizePaperBuffer(format: fmt, duration: 0.19, gain: 0.16) else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Soft wooden floor paw-tap cue when calling a pet over in the 2.5D Sunroom
    func playPawTap() {
        guard let (player, fmt) = ensureRunning(),
              let buffer = synthesizeWoodTapBuffer(format: fmt, duration: 0.11, gain: 0.14) else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Soft velvet grooming brush / towel-dry swish
    func playBrushSwish() {
        guard let (player, fmt) = ensureRunning(),
              let buffer = synthesizeFilteredNoise(format: fmt, duration: 0.22, cutoffAlpha: 0.08, gain: 0.11) else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Gentle warm feline purr rumble (26 Hz amplitude-modulated soft warmth)
    func playPetPurr() {
        guard let (player, fmt) = ensureRunning(),
              let buffer = synthesizePurrBuffer(format: fmt, duration: 0.52, gain: 0.12) else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Soft cheerful puppy/spirit chirp (ascending gentle pentatonic trill)
    func playPetChirp() {
        guard let (player, fmt) = ensureRunning(),
              let buffer = synthesizeChirpBuffer(format: fmt, duration: 0.24, gain: 0.10) else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Warm ceramic teapot chime (F5 + A5)
    func playTeapotClink() {
        guard let (player, fmt) = ensureRunning(),
              let buffer = synthesizeBellBuffer(format: fmt, frequencies: [698.46, 880.0], duration: 0.36, gain: 0.12) else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Gentle wardrobe ribbon snap / heirloom bell glint
    func playWardrobeSnap(withBell: Bool = false) {
        guard let (player, fmt) = ensureRunning() else { return }
        let freqs: [Double] = withBell ? [1046.5, 1567.98] : [587.33, 880.0]
        guard let buffer = synthesizeBellBuffer(format: fmt, frequencies: freqs, duration: 0.28, gain: 0.11) else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    // MARK: - Ambient Rain & Gentle Pentatonic Kalimba Lullaby

    func setRainAmbience(active: Bool) {
        guard isSoundEnabled && active else {
            stopRainAmbience()
            return
        }
        guard !isRainPlaying,
              let (eng, fmt) = ensureEngineStarted(),
              let rain = rainPlayer,
              rain.engine === eng,
              !eng.outputConnectionPoints(for: rain, outputBus: 0).isEmpty,
              let loopBuffer = synthesizeRainLoop(format: fmt, duration: 2.4, gain: 0.042) else { return }
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
        guard let (eng, fmt) = ensureEngineStarted(),
              let music = musicPlayer,
              music.engine === eng,
              !eng.outputConnectionPoints(for: music, outputBus: 0).isEmpty,
              let loopBuffer = synthesizeKalimbaLoop(format: fmt, weather: weather, gain: 0.055) else { return }
        music.stop()
        music.scheduleBuffer(loopBuffer, at: nil, options: [.loops], completionHandler: nil)
        music.play()
        isMusicPlaying = true
    }

    func stopCozyMusic() {
        guard isMusicPlaying else { return }
        musicPlayer?.stop()
        isMusicPlaying = false
    }

    // MARK: - Procedural Stereo DSP Buffer Builders

    private func mirrorLeftToStereo(_ buffer: AVAudioPCMBuffer) {
        let chCount = Int(buffer.format.channelCount)
        guard chCount >= 2,
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else { return }
        let n = Int(buffer.frameLength)
        right.update(from: left, count: n)
    }

    private func synthesizeBellBuffer(format: AVAudioFormat, frequencies: [Double], duration: Double, gain: Float) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return nil }
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
        mirrorLeftToStereo(buffer)
        return buffer
    }

    private func synthesizeWoodTapBuffer(format: AVAudioFormat, duration: Double, gain: Float) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return nil }
        buffer.frameLength = count
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        let sr = format.sampleRate
        for i in 0..<Int(count) {
            let t = Double(i) / sr
            let env = exp(-t * 42.0)
            let tone = sin(2.0 * .pi * 240.0 * t) * 0.7 + sin(2.0 * .pi * 510.0 * t) * 0.3
            ptr[i] = Float(tone * env) * gain
        }
        mirrorLeftToStereo(buffer)
        return buffer
    }

    private func synthesizePurrBuffer(format: AVAudioFormat, duration: Double, gain: Float) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return nil }
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
        mirrorLeftToStereo(buffer)
        return buffer
    }

    private func synthesizeChirpBuffer(format: AVAudioFormat, duration: Double, gain: Float) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return nil }
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
        mirrorLeftToStereo(buffer)
        return buffer
    }

    private func synthesizeKalimbaLoop(format: AVAudioFormat, weather: WeatherMode, gain: Float) -> AVAudioPCMBuffer? {
        let duration = 8.0
        let count = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return nil }
        buffer.frameLength = count
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        let sr = format.sampleRate
        let notes: [Double] = {
            switch weather {
            case .lightRain, .postRain:
                return [329.63, 392.00, 440.00, 493.88, 392.00, 329.63, 293.66, 392.00]
            case .dusk:
                return [261.63, 329.63, 392.00, 493.88, 440.00, 392.00, 329.63, 293.66]
            default:
                return [261.63, 329.63, 392.00, 523.25, 440.00, 392.00, 329.63, 392.00]
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
        mirrorLeftToStereo(buffer)
        return buffer
    }

    private func synthesizePaperBuffer(format: AVAudioFormat, duration: Double, gain: Float) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return nil }
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
        mirrorLeftToStereo(buffer)
        return buffer
    }

    private func synthesizeFilteredNoise(format: AVAudioFormat, duration: Double, cutoffAlpha: Float, gain: Float) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return nil }
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
        mirrorLeftToStereo(buffer)
        return buffer
    }

    private func synthesizeRainLoop(format: AVAudioFormat, duration: Double, gain: Float) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return nil }
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
        mirrorLeftToStereo(buffer)
        return buffer
    }
}
