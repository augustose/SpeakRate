import Foundation

/// Replaces non-pronounceable technical content (URLs, paths, code, hashes)
/// with short localized placeholders so text-to-speech skips the noise.
public enum TextSanitizer {

    private struct Placeholders {
        let link: String
        let email: String
        let file: String
        let directory: String
        let code: String
    }

    private static let placeholderTable: [String: Placeholders] = [
        "en": Placeholders(link: "link", email: "email", file: "file", directory: "directory", code: "code"),
        "es": Placeholders(link: "enlace", email: "correo", file: "archivo", directory: "directorio", code: "código"),
        "fr": Placeholders(link: "lien", email: "courriel", file: "fichier", directory: "dossier", code: "code"),
    ]

    private static let fileExtensions = [
        "json", "txt", "md", "pdf", "csv", "xml", "yml", "yaml", "swift", "py",
        "js", "ts", "html", "css", "sh", "zip", "tar", "gz", "png", "jpg",
        "jpeg", "gif", "svg", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
        "log", "plist", "toml", "ini", "conf", "sql", "rb", "go", "rs",
        "java", "c", "h", "cpp", "hpp", "app", "dmg", "pkg", "icns",
    ]

    public static func sanitize(_ text: String, language: String) -> String {
        let p = placeholderTable[String(language.prefix(2)).lowercased()] ?? placeholderTable["en"]!
        var s = text

        // 1. Horizontal-rule lines (----, ====, ****) — drop the whole line.
        s = replace(s, #"(?m)^[ \t]*[-=_*]{3,}[ \t]*\n?"#, with: "")

        // 2. Inline code between backticks (may contain URLs/paths — handle first).
        s = replace(s, #"`[^`\n]+`"#, with: p.code)

        // 3. URLs.
        s = replace(s, #"https?://[^\s,]+"#, with: p.link)
        s = replace(s, #"\bwww\.[^\s,]+"#, with: p.link)

        // 4. Emails.
        s = replace(s, #"\b[\w.+-]+@[\w-]+(\.[\w-]+)+\b"#, with: p.email)

        // 5. Windows paths (C:\Users\...).
        s = replacePaths(s, #"\b[A-Za-z]:\\[^\s,]+"#, separator: "\\", placeholders: p)

        // 6. Unix paths (/usr/local/bin, ~/Documents/x.pdf). Lookbehind avoids
        //    matching fractions/dates like 24/09/2026 or and/or.
        s = replacePaths(s, #"(?<![\w)])(?:~/|/)[\w.-]+(?:/[\w.-]+)+/?"#, separator: "/", placeholders: p)

        // 7. UUIDs, then long hex hashes (require a letter so plain numbers survive).
        s = replace(s, #"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b"#, with: p.code)
        s = replace(s, #"\b(?=[0-9a-fA-F]*[a-fA-F])[0-9a-fA-F]{12,}\b"#, with: p.code)

        // 8. Standalone filenames with a known extension (config.json).
        let extPattern = fileExtensions.joined(separator: "|")
        s = replace(s, #"\b[\w-]+\.(?:"# + extPattern + #")\b"#, with: p.file)

        // 9. Technical symbol runs (-->, ==>, ###, ***) that TTS spells out.
        s = replace(s, #"(?<=\s|^)[-=>*#_~<]{2,}(?=\s|$)"#, with: "")

        // 10. Tidy whitespace left behind by removals.
        s = replace(s, #"[ \t]{2,}"#, with: " ")
        s = replace(s, #"[ \t]+\n"#, with: "\n")
        s = replace(s, #"\n[ \t]+"#, with: "\n")
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helpers

    private static func replace(_ text: String, _ pattern: String, with replacement: String) -> String {
        return text.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }

    /// Replaces each path match with the file or directory placeholder,
    /// depending on whether its last component has a file extension.
    private static func replacePaths(_ text: String, _ pattern: String, separator: String, placeholders p: Placeholders) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let ns = text as NSString
        var result = text
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let path = ns.substring(with: match.range)
            let last = path.components(separatedBy: separator).last ?? path
            let isFile = last.range(of: #"\.[A-Za-z0-9]{1,5}$"#, options: .regularExpression) != nil
            let placeholder = isFile ? p.file : p.directory
            result = (result as NSString).replacingCharacters(in: match.range, with: placeholder)
        }
        return result
    }
}
