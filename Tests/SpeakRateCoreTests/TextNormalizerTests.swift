import XCTest
@testable import SpeakRateCore

final class TextNormalizerTests: XCTestCase {

    // MARK: - Terminal punctuation at line ends

    func testAddsPeriodToLineWithoutTerminalPunctuation() {
        let result = TextNormalizer.normalize("Design and build Copilot Studio agents\nCreate Power Automate flows")
        XCTAssertEqual(result, "Design and build Copilot Studio agents.\nCreate Power Automate flows.")
    }

    func testKeepsLineAlreadyEndingInPeriod() {
        let result = TextNormalizer.normalize("First sentence.\nSecond sentence.")
        XCTAssertEqual(result, "First sentence.\nSecond sentence.")
    }

    func testKeepsLinesEndingInOtherTerminalPunctuation() {
        let result = TextNormalizer.normalize("Really?\nYes!\nItems:\nalmost;\nwait,")
        XCTAssertEqual(result, "Really?\nYes!\nItems:\nalmost;\nwait,")
    }

    func testDoesNotTouchSingleLineWithoutNewline() {
        let result = TextNormalizer.normalize("Hello world")
        XCTAssertEqual(result, "Hello world.")
    }

    func testIgnoresBlankLines() {
        let result = TextNormalizer.normalize("First paragraph\n\nSecond paragraph")
        XCTAssertEqual(result, "First paragraph.\n\nSecond paragraph.")
    }

    func testHandlesTrailingWhitespaceBeforeNewline() {
        let result = TextNormalizer.normalize("Line with trailing spaces   \nNext line")
        XCTAssertEqual(result, "Line with trailing spaces.\nNext line.")
    }

    func testKeepsClosingQuoteOrParenAfterPunctuation() {
        let result = TextNormalizer.normalize("He said \"stop.\"\n(Done!)")
        XCTAssertEqual(result, "He said \"stop.\"\n(Done!)")
    }

    // MARK: - Bullet and list markers

    func testRemovesBulletMarkers() {
        let result = TextNormalizer.normalize("• Summarize meeting notes\n- Extract action items\n* Create summaries")
        XCTAssertEqual(result, "Summarize meeting notes.\nExtract action items.\nCreate summaries.")
    }

    func testRemovesNumberedListMarkers() {
        let result = TextNormalizer.normalize("1. First step\n2) Second step")
        XCTAssertEqual(result, "First step.\nSecond step.")
    }

    func testDoesNotRemoveNumberThatIsNotAListMarker() {
        let result = TextNormalizer.normalize("2026 was a good year")
        XCTAssertEqual(result, "2026 was a good year.")
    }

    // MARK: - Inline markdown emphasis

    func testStripsBoldMarkers() {
        let result = TextNormalizer.normalize("Create **Power Automate flows** now")
        XCTAssertEqual(result, "Create Power Automate flows now.")
    }

    func testStripsUnderscoreEmphasis() {
        let result = TextNormalizer.normalize("This is __important__ stuff")
        XCTAssertEqual(result, "This is important stuff.")
    }

    func testStripsMarkdownHeadingMarkers() {
        let result = TextNormalizer.normalize("## Meetings\nSummarize notes")
        XCTAssertEqual(result, "Meetings.\nSummarize notes.")
    }

    // MARK: - Edge cases

    func testEmptyStringStaysEmpty() {
        XCTAssertEqual(TextNormalizer.normalize(""), "")
    }

    func testWhitespaceOnlyStringStaysUnchangedOrEmpty() {
        let result = TextNormalizer.normalize("   \n  \n")
        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), "")
    }
}
