import AVFoundation
import NaturalLanguage
import AppKit

/// Speaks text with AVSpeechSynthesizer, with full control over rate.
/// Supports live rate changes by restarting from the current word.
class SpeechReader: NSObject, AVSpeechSynthesizerDelegate, ObservableObject {
    static let shared = SpeechReader()

    private let synth = AVSpeechSynthesizer()

    /// Rate stored on AVSpeech 0.0–1.0 scale. Default 0.5.
    private(set) var rate: Float = 0.5
    private let minRate: Float = AVSpeechUtteranceMinimumSpeechRate
    private let maxRate: Float = AVSpeechUtteranceMaximumSpeechRate
    private let step: Float = 0.03

    /// Currently spoken text and offset, for live rate changes.
    private var currentText: String = ""
    private var spokenOffset: Int = 0          // absolute offset in currentText currently being spoken
    private var utteranceStartOffset: Int = 0  // offset where the active utterance began
    private var currentLanguage: String?

    var onRateChange: ((Float) -> Void)?

    override init() {
        super.init()
        synth.delegate = self
        rate = loadRate()
    }

    var isSpeaking: Bool { synth.isSpeaking }

    // MARK: - Speak / stop

    func toggleSpeak(_ text: String) {
        if synth.isSpeaking {
            stop()
        } else {
            speak(text)
        }
    }

    func speak(_ text: String, fromOffset offset: Int = 0) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if offset == 0 {
            currentText = trimmed
            currentLanguage = detectLanguage(trimmed)
        }
        spokenOffset = offset
        utteranceStartOffset = offset

        let startIndex = currentText.index(currentText.startIndex, offsetBy: min(offset, currentText.count))
        let toSpeak = String(currentText[startIndex...])

        let utterance = AVSpeechUtterance(string: toSpeak)
        utterance.rate = rate
        if let lang = currentLanguage, let voice = bestVoice(for: lang) {
            utterance.voice = voice
        }

        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        currentText = ""
        spokenOffset = 0
    }

    // MARK: - Rate control (live)

    func increase() { setRate(rate + step) }
    func decrease() { setRate(rate - step) }

    private func setRate(_ newRate: Float) {
        rate = min(max(newRate, minRate), maxRate)
        saveRate(rate)
        onRateChange?(rate)

        // If currently speaking, restart from the current word at the new rate
        if synth.isSpeaking && !currentText.isEmpty {
            speak(currentText, fromOffset: spokenOffset)
        }
    }

    /// Approximate words-per-minute for display.
    /// AVSpeech default 0.5 ≈ 175 wpm. Scale is roughly linear in this range.
    func wpm() -> Int {
        // Empirical: rate 0.0 ≈ 1 wpm region is unusable; map 0.4–0.7 to ~120–280.
        // Use linear: wpm = rate * 350
        return max(50, Int((rate * 350).rounded()))
    }

    // MARK: - Delegate (track progress for live rate change)

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance) {
        // characterRange is relative to the current utterance substring.
        // Convert to absolute offset in currentText.
        spokenOffset = utteranceStartOffset + characterRange.location
    }

    // MARK: - Language detection & voice selection

    private func detectLanguage(_ text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue ?? "en"
    }

    private func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        // Match language prefix (e.g. "es" matches "es-ES", "es-419")
        let matching = voices.filter { $0.language.lowercased().hasPrefix(language.lowercased()) }
        // Prefer premium/enhanced quality
        if let premium = matching.first(where: { $0.quality == .premium }) { return premium }
        if let enhanced = matching.first(where: { $0.quality == .enhanced }) { return enhanced }
        return matching.first ?? AVSpeechSynthesisVoice(language: language)
    }

    // MARK: - Persistence

    private func loadRate() -> Float {
        let v = UserDefaults.standard.float(forKey: "speechRate")
        return v == 0 ? 0.5 : v
    }
    private func saveRate(_ r: Float) {
        UserDefaults.standard.set(r, forKey: "speechRate")
    }
}
