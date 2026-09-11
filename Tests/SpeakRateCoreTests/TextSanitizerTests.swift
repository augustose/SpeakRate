import XCTest
@testable import SpeakRateCore

final class TextSanitizerTests: XCTestCase {

    // MARK: - URLs

    func testReplacesHTTPSURLWithPlaceholderSpanish() {
        let result = TextSanitizer.sanitize("Cloná https://github.com/x/y para empezar", language: "es")
        XCTAssertEqual(result, "Cloná enlace para empezar")
    }

    func testReplacesHTTPURLWithPlaceholderEnglish() {
        let result = TextSanitizer.sanitize("Visit http://example.com/docs?page=1 for details", language: "en")
        XCTAssertEqual(result, "Visit link for details")
    }

    func testReplacesWWWURL() {
        let result = TextSanitizer.sanitize("Andá a www.ejemplo.com/ayuda ahora", language: "es")
        XCTAssertEqual(result, "Andá a enlace ahora")
    }

    // MARK: - Emails

    func testReplacesEmail() {
        let result = TextSanitizer.sanitize("Escribí a soporte@empresa.com hoy", language: "es")
        XCTAssertEqual(result, "Escribí a correo hoy")
    }

    // MARK: - Paths

    func testReplacesUnixDirectoryPath() {
        let result = TextSanitizer.sanitize("Instalalo en /usr/local/bin sin más", language: "es")
        XCTAssertEqual(result, "Instalalo en directorio sin más")
    }

    func testReplacesPathEndingInFileAsFile() {
        let result = TextSanitizer.sanitize("Abrí ~/Documents/report.pdf primero", language: "es")
        XCTAssertEqual(result, "Abrí archivo primero")
    }

    func testReplacesWindowsPath() {
        let result = TextSanitizer.sanitize("Look in C:\\Users\\john\\data please", language: "en")
        XCTAssertEqual(result, "Look in directory please")
    }

    func testReplacesStandaloneFilename() {
        let result = TextSanitizer.sanitize("Editá config.json y guardá", language: "es")
        XCTAssertEqual(result, "Editá archivo y guardá")
    }

    // MARK: - Inline code, hashes, UUIDs

    func testReplacesBacktickInlineCode() {
        let result = TextSanitizer.sanitize("Corré `npm install --save-dev` en la terminal", language: "es")
        XCTAssertEqual(result, "Corré código en la terminal")
    }

    func testBacktickContentWithURLIsSingleCodePlaceholder() {
        let result = TextSanitizer.sanitize("Usá `curl https://api.example.com/v1` así", language: "es")
        XCTAssertEqual(result, "Usá código así")
    }

    func testReplacesLongHexHash() {
        let result = TextSanitizer.sanitize("El commit a3f8c91d2b4e6f70a1b2c3d4e5f60718 falló", language: "es")
        XCTAssertEqual(result, "El commit código falló")
    }

    func testReplacesUUID() {
        let result = TextSanitizer.sanitize("El id 550e8400-e29b-41d4-a716-446655440000 expiró", language: "es")
        XCTAssertEqual(result, "El id código expiró")
    }

    // MARK: - Technical symbol runs

    func testRemovesArrowAndSymbolRuns() {
        let result = TextSanitizer.sanitize("Paso uno --> paso dos ### fin ***", language: "es")
        XCTAssertEqual(result, "Paso uno paso dos fin")
    }

    func testRemovesHorizontalRuleLines() {
        let result = TextSanitizer.sanitize("Título\n----------\nCuerpo del texto", language: "es")
        XCTAssertEqual(result, "Título\nCuerpo del texto")
    }

    // MARK: - Clean text untouched

    func testPlainTextIsUnchanged() {
        let text = "Hola, esto es una frase normal con puntuación. ¿Todo bien?"
        XCTAssertEqual(TextSanitizer.sanitize(text, language: "es"), text)
    }

    func testDecimalNumbersAndVersionsSurvive() {
        let text = "La versión 2.5 salió en 2024 y cuesta 9.99 dólares"
        XCTAssertEqual(TextSanitizer.sanitize(text, language: "es"), text)
    }

    // MARK: - Localization fallback

    func testUnknownLanguageFallsBackToEnglish() {
        let result = TextSanitizer.sanitize("Siehe https://beispiel.de bitte", language: "de")
        XCTAssertEqual(result, "Siehe link bitte")
    }

    func testFrenchPlaceholders() {
        let result = TextSanitizer.sanitize("Voir https://exemple.fr et écrire à jean@exemple.fr", language: "fr")
        XCTAssertEqual(result, "Voir lien et écrire à courriel")
    }

    // MARK: - Mixed

    func testMixedSentence() {
        let result = TextSanitizer.sanitize(
            "Bajá el script de https://example.com/tool y ponelo en /usr/local/bin, después corré `tool --init`",
            language: "es")
        XCTAssertEqual(result, "Bajá el script de enlace y ponelo en directorio, después corré código")
    }
}
