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
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = 0.52
        synth.speak(utterance)
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
