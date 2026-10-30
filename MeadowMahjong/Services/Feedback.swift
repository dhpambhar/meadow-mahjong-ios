import AVFoundation
import Observation
import UIKit

/// Sounds and haptics for game events, following the player's settings.
@MainActor
@Observable
final class Feedback {
    @ObservationIgnored private let progress: PlayerProgress

    /// C major pentatonic, so any run of match sounds is pleasant. Climbs with the combo.
    private static let scale = [72, 74, 76, 79, 81, 84, 86, 88, 91, 93]

    init(progress: PlayerProgress) {
        self.progress = progress
    }

    func select() {
        impact(.light)
        tone(84, decay: 16, volume: 0.15)
    }

    func blocked() {
        if progress.hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        tone(52, decay: 14, volume: 0.25)
    }

    func match(combo: Int) {
        impact(combo >= 4 ? .heavy : .medium)
        tone(Self.scale[min(max(combo, 1), Self.scale.count) - 1], decay: 4, volume: 0.45)
    }

    func praise(tier: Int) {
        guard tier >= 4 else { return }
        arpeggio([79, 84, 88], gap: 0.07, volume: 0.3)
    }

    func hint() {
        impact(.soft)
        arpeggio([88, 93], gap: 0.09, volume: 0.25)
    }

    func shuffle() {
        impact(.rigid)
        arpeggio([72, 76, 79, 76, 72], gap: 0.05, volume: 0.2)
    }

    func undo() {
        impact(.light)
        tone(67, decay: 8, volume: 0.25)
    }

    func stuck() {
        if progress.hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.error) }
        arpeggio([67, 64, 60], gap: 0.12, volume: 0.25)
    }

    func win() {
        if progress.hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        arpeggio([72, 76, 79, 84, 88, 91], gap: 0.09, volume: 0.4)
    }

    func star(_ index: Int) {
        impact(.medium)
        tone([84, 88, 91][min(index, 2)], decay: 3.5, volume: 0.4)
    }

    // MARK: -

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard progress.hapticsOn else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func tone(_ midi: Int, decay: Double, volume: Float) {
        guard progress.soundOn else { return }
        ChimePlayer.shared.play(midi: midi, decay: decay, volume: volume)
    }

    private func arpeggio(_ notes: [Int], gap: Double, volume: Float) {
        guard progress.soundOn else { return }
        for (i, note) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + gap * Double(i)) {
                ChimePlayer.shared.play(midi: note, decay: 4, volume: volume)
            }
        }
    }
}

/// Soft bell tones made at runtime, so the app ships no audio files.
final class ChimePlayer {
    static let shared = ChimePlayer()

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var voices: [AVAudioPlayerNode] = []
    private var nextVoice = 0
    private var cache: [String: AVAudioPCMBuffer] = [:]

    private init() {
        // Ambient: mixes with the player's music and stays quiet on silent mode.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for _ in 0..<6 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            voices.append(node)
        }
        try? engine.start()
    }

    func play(midi: Int, decay: Double, volume: Float) {
        if !engine.isRunning { try? engine.start() }
        guard engine.isRunning, let buffer = buffer(midi: midi, decay: decay) else { return }
        let node = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        node.volume = volume
        node.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !node.isPlaying { node.play() }
    }

    private func buffer(midi: Int, decay: Double) -> AVAudioPCMBuffer? {
        let key = "\(midi)-\(decay)"
        if let cached = cache[key] { return cached }
        let sampleRate = format.sampleRate
        let frames = AVAudioFrameCount(sampleRate * min(1.4, 7 / decay))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        let f = 440 * pow(2, Double(midi - 69) / 12)
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let attack = min(1, t / 0.004)
            let body = sin(2 * .pi * f * t) * exp(-decay * t)
            let shimmer = 0.3 * sin(2 * .pi * 2 * f * t) * exp(-decay * 1.8 * t)
            let bell = 0.12 * sin(2 * .pi * 3.01 * f * t) * exp(-decay * 2.5 * t)
            data[i] = Float(attack * (body + shimmer + bell) * 0.32)
        }
        cache[key] = buffer
        return buffer
    }
}
