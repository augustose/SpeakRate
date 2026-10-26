import Foundation

/// Normalizes punctuation so text-to-speech pauses naturally: lines that end
/// without terminal punctuation get a period, and list/markdown markers that
/// TTS reads literally (bullets, numbering, emphasis) are removed.
public enum TextNormalizer {

    /// Characters that already make the synthesizer pause at a line end.
    private static let terminalPunctuation: Set<Character> = [".", "!", "?", ":", ";", ",", "…"]

    /// Closing characters that may follow terminal punctuation ("stop." or (Done!)).
    private static let closingCharacters: Set<Character> = ["\"", "'", ")", "]", "}", "”", "’", "»"]

    public static func normalize(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n").map { normalizeLine($0) }
        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func normalizeLine(_ line: String) -> String {
        var s = line.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return "" }

        // Leading bullet markers (•, -, *, –) and numbered list markers (1. / 2)).
        s = s.replacingOccurrences(of: #"^[•\-*–]\s+"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"^\d{1,3}[.)]\s+"#, with: "", options: .regularExpression)

        // Markdown heading markers and inline emphasis.
        s = s.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "**", with: "")
        s = s.replacingOccurrences(of: "__", with: "")

        guard !s.isEmpty else { return "" }
        return endsWithTerminalPunctuation(s) ? s : s + "."
    }

    private static func endsWithTerminalPunctuation(_ line: String) -> Bool {
        var chars = Substring(line)
        while let last = chars.last, closingCharacters.contains(last) {
            chars = chars.dropLast()
        }
        guard let last = chars.last else { return false }
        return terminalPunctuation.contains(last)
    }
}
