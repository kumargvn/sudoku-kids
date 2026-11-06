import AVFoundation
import UIKit

/// Sounds and vibrations for game events. Both can be turned off in Settings.
@MainActor
enum Feedback {
    static var soundOn = true
    static var hapticsOn = true

    static func tap() {
        if hapticsOn { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        if soundOn { SoundPlayer.shared.play(.tap) }
    }

    static func place() {
        if hapticsOn { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        if soundOn { SoundPlayer.shared.play(.place) }
    }

    static func oops() {
        if hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        if soundOn { SoundPlayer.shared.play(.wrong) }
    }

    static func hint() {
        if hapticsOn { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        if soundOn { SoundPlayer.shared.play(.hint) }
    }

    static func win() {
        if hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        if soundOn { SoundPlayer.shared.play(.win) }
    }

    static func trophy() {
        if hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        if soundOn { SoundPlayer.shared.play(.trophy) }
    }
}

/// Plays short synthesized chimes, so the app needs no audio files.
/// Uses the "ambient" audio session: it respects the silent switch and mixes with other audio.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    enum Effect: CaseIterable {
        case tap, place, wrong, hint, win, trophy

        /// (frequency in Hz, length in seconds) for each note.
        var notes: [(Double, Double)] {
            switch self {
            case .tap: return [(880, 0.035)]
            case .place: return [(659, 0.07), (988, 0.10)]
            case .wrong: return [(247, 0.12), (196, 0.16)]
            case .hint: return [(784, 0.08), (1047, 0.14)]
            case .win: return [(523, 0.11), (659, 0.11), (784, 0.11), (1047, 0.30)]
            case .trophy: return [(1047, 0.08), (1319, 0.08), (1568, 0.22)]
            }
        }

        var volume: Float { self == .tap ? 0.12 : 0.22 }
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]
    private var isReady = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        for effect in Effect.allCases {
            buffers[effect] = makeBuffer(effect.notes, volume: effect.volume)
        }
    }

    func play(_ effect: Effect) {
        if !isReady { start() }
        guard isReady, engine.isRunning, let buffer = buffers[effect] else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    private func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        do {
            try engine.start()
            isReady = true
        } catch {
            isReady = false
        }
    }

    private func makeBuffer(_ notes: [(Double, Double)], volume: Float) -> AVAudioPCMBuffer? {
        let rate = format.sampleRate
        let total = notes.reduce(0) { $0 + Int($1.1 * rate) }
        guard total > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(total)

        var offset = 0
        for (frequency, length) in notes {
            let frames = Int(length * rate)
            let attack = max(1, Int(0.005 * rate))
            for k in 0..<frames {
                let t = Double(k) / rate
                let envelope = k < attack
                    ? Double(k) / Double(attack)
                    : exp(-4.0 * Double(k - attack) / Double(max(frames - attack, 1)))
                // A sine plus a soft overtone sounds like a little bell.
                let sample = sin(2 * .pi * frequency * t) + 0.3 * sin(4 * .pi * frequency * t)
                channel[offset + k] = Float(sample * envelope) * volume
            }
            offset += frames
        }
        return buffer
    }
}

/// Reads hints and lessons out loud for kids who are still learning to read.
@MainActor
final class Speaker {
    static let shared = Speaker()
    private let synthesizer = AVSpeechSynthesizer()

    func say(_ text: String) {
        _ = synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.15
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        synthesizer.speak(utterance)
    }

    func stop() {
        _ = synthesizer.stopSpeaking(at: .immediate)
    }
}
