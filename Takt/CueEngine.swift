import AVFoundation

/// Beeps and voice announcements. While a workout runs, a silent loop keeps the
/// audio session alive so the timer keeps going with the screen locked.
final class CueEngine {
    private let synth = AVSpeechSynthesizer()
    private let tickPlayer = CueEngine.player(Tone.wav(frequency: 880, duration: 0.12))
    private let goPlayer = CueEngine.player(Tone.wav(frequency: 1320, duration: 0.45))
    private let finishPlayer = CueEngine.player(Tone.wav(frequency: 1046, duration: 1.0))
    private let silencePlayer = CueEngine.player(Tone.wav(frequency: 0, duration: 1.0, amplitude: 0))

    private var soundEnabled = true
    private var voiceEnabled = true

    func begin() {
        let defaults = UserDefaults.standard
        soundEnabled = defaults.object(forKey: Settings.sound) as? Bool ?? true
        voiceEnabled = defaults.object(forKey: Settings.voice) as? Bool ?? true

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        // mixWithOthers: your music keeps playing, cues are layered on top.
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
        silencePlayer?.numberOfLoops = -1
        silencePlayer?.play()
    }

    func end() {
        silencePlayer?.stop()
        synth.stopSpeaking(at: .immediate)
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    func tick() { play(tickPlayer) }
    func go() { play(goPlayer) }
    func finish() { play(finishPlayer) }

    func say(_ text: String) {
        guard voiceEnabled, !text.isEmpty else { return }
        synth.stopSpeaking(at: .immediate)
        synth.speak(Voices.utterance(text))
    }

    private func play(_ player: AVAudioPlayer?) {
        guard soundEnabled, let player else { return }
        player.currentTime = 0
        player.play()
    }

    private static func player(_ data: Data) -> AVAudioPlayer? {
        let player = try? AVAudioPlayer(data: data)
        player?.prepareToPlay()
        return player
    }
}

enum Settings {
    static let sound = "soundEnabled"
    static let voice = "voiceEnabled"
    static let voiceID = "voiceIdentifier"
}

/// German system voices, best quality first. Premium/enhanced voices have to be downloaded once in
/// iOS Settings → Accessibility → Spoken Content → Voices → German.
enum Voices {
    static var german: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            // Eloquence and novelty voices sound robotic, leave them out.
            .filter { $0.language.hasPrefix("de") && !$0.identifier.contains("eloquence") && !$0.identifier.contains("speech.synthesis") }
            .sorted { ($0.quality.rawValue, $0.name) > ($1.quality.rawValue, $1.name) }
    }

    /// The voice picked in settings, otherwise the best installed one.
    static var selected: AVSpeechSynthesisVoice? {
        if let id = UserDefaults.standard.string(forKey: Settings.voiceID),
           let voice = AVSpeechSynthesisVoice(identifier: id) {
            return voice
        }
        return german.first ?? AVSpeechSynthesisVoice(language: "de-DE")
    }

    static func utterance(_ text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selected
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        return utterance
    }

    static func label(_ voice: AVSpeechSynthesisVoice) -> String {
        switch voice.quality {
        case .premium: "\(voice.name) (Premium)"
        case .enhanced: "\(voice.name) (Erweitert)"
        default: "\(voice.name) (Einfach)"
        }
    }
}

/// Generates short sine tones as in-memory WAV files, so the app ships without sound assets.
enum Tone {
    static func wav(frequency: Double, duration: Double, amplitude: Double = 0.6, sampleRate: Double = 44_100) -> Data {
        let count = Int(duration * sampleRate)
        let fade = min(count / 10, Int(0.01 * sampleRate))
        var data = Data()

        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }

        let byteCount = UInt32(count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(36 + byteCount)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16))
        append(UInt16(1)); append(UInt16(1))                      // PCM, mono
        append(UInt32(sampleRate)); append(UInt32(sampleRate * 2)) // sample rate, byte rate
        append(UInt16(2)); append(UInt16(16))                      // block align, bits per sample
        data.append(contentsOf: Array("data".utf8)); append(byteCount)

        for i in 0..<count {
            var envelope = 1.0
            if i < fade { envelope = Double(i) / Double(fade) }
            else if i > count - fade { envelope = Double(count - i) / Double(fade) }
            let value = sin(2 * .pi * frequency * Double(i) / sampleRate) * amplitude * envelope
            append(Int16(value * Double(Int16.max)))
        }
        return data
    }
}
