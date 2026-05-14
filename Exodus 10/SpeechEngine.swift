import AVFoundation

// MARK: - Speech Engine (formerly GameplayAudioEngine)
// Handles all AVSpeechSynthesizer-based audio: beat ticks, note prompts, phrases, startup alerts

final class SpeechEngine {
    private let synthesizer = AVSpeechSynthesizer()
    private let defaultVoice = AVSpeechSynthesisVoice(language: "en-US")
    private let startupVoice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Fred-compact")

    func playBeat(volume: Double) {
        speak(
            "tick",
            volume: max(0.0, min(volume, 1.0)),
            rate: 0.44,
            pitch: 1.15,
            voice: defaultVoice
        )
    }

    func playNotePrompt(_ note: String, volume: Double) {
        let spoken = note
            .replacingOccurrences(of: "#", with: " sharp ")
            .replacingOccurrences(of: "b", with: " flat ")
            .replacingOccurrences(of: "+", with: " and ")
        speak(
            spoken,
            volume: max(0.0, min(volume, 1.0)),
            rate: 0.46,
            pitch: 0.95,
            voice: defaultVoice
        )
    }

    func speakPhrase(_ phrase: String, volume: Double, rate: Float = 0.45, pitch: Float = 1.05) {
        speak(
            phrase,
            volume: max(0.0, min(volume, 1.0)),
            rate: rate,
            pitch: pitch,
            voice: defaultVoice
        )
    }

    func speakStartupAlert(_ phrase: String, volume: Double) {
        speak(
            phrase,
            volume: max(0.0, min(volume, 1.0)),
            rate: 0.38,
            pitch: 0.35,
            voice: startupVoice ?? defaultVoice
        )
    }

    private func speak(
        _ text: String,
        volume: Double,
        rate: Float,
        pitch: Float,
        voice: AVSpeechSynthesisVoice?
    ) {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? defaultVoice
        utterance.volume = Float(volume)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}
