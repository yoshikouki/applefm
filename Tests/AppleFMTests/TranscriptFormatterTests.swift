import Testing
import Foundation
import FoundationModels
@testable import AppleFMCore

@Suite("TranscriptFormatter Tests")
struct TranscriptFormatterTests {

    @Test("initializer with text format")
    func initWithTextFormat() {
        let formatter = TranscriptFormatter(format: .text)
        #expect(formatter.format == .text)
    }

    @Test("initializer with json format")
    func initWithJsonFormat() {
        let formatter = TranscriptFormatter(format: .json)
        #expect(formatter.format == .json)
    }

    @Test("default initializer uses text format")
    func defaultInit() {
        let formatter = TranscriptFormatter()
        #expect(formatter.format == .text)
    }

    @Test("text format with empty transcript")
    func textFormatEmptyTranscript() throws {
        let formatter = TranscriptFormatter(format: .text)
        let session = LanguageModelSession()
        let result = formatter.formatTranscript(session.transcript)
        // Empty transcript should produce an empty string (no entries to format)
        #expect(result == "")
    }

    @Test("json format with empty transcript")
    func jsonFormatEmptyTranscript() throws {
        let formatter = TranscriptFormatter(format: .json)
        let session = LanguageModelSession()
        let result = formatter.formatTranscript(session.transcript)
        // Empty transcript in JSON format should produce "[\n\n]" or "[]"
        #expect(result.contains("["))
        #expect(result.contains("]"))
    }
}
