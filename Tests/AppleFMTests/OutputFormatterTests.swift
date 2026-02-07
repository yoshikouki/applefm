import Testing
@testable import AppleFMCore

@Suite("OutputFormatter Tests")
struct OutputFormatterTests {

    @Test("text format outputs plain value")
    func textFormatPlainValue() {
        let formatter = OutputFormatter(format: .text)
        let result = formatter.output("Hello, world!")
        #expect(result == "Hello, world!")
    }

    @Test("json format wraps value in content key")
    func jsonFormatPlainValue() throws {
        let formatter = OutputFormatter(format: .json)
        let result = formatter.output("Hello, world!")
        #expect(result.contains("\"content\""))
        #expect(result.contains("Hello, world!"))
    }

    @Test("text format outputs key-value pairs")
    func textFormatKeyValuePairs() {
        let formatter = OutputFormatter(format: .text)
        let result = formatter.output([
            "status": "available",
            "details": "Ready",
        ])
        #expect(result.contains("status: available"))
        #expect(result.contains("details: Ready"))
    }

    @Test("json format outputs key-value pairs as JSON object")
    func jsonFormatKeyValuePairs() {
        let formatter = OutputFormatter(format: .json)
        let result = formatter.output([
            "status": "available",
        ])
        #expect(result.contains("\"status\""))
        #expect(result.contains("\"available\""))
    }

    @Test("text format outputs list items separated by newlines")
    func textFormatList() {
        let formatter = OutputFormatter(format: .text)
        let result = formatter.outputList(["en", "ja", "fr"])
        #expect(result == "en\nja\nfr")
    }

    @Test("json format outputs list as JSON array")
    func jsonFormatList() {
        let formatter = OutputFormatter(format: .json)
        let result = formatter.outputList(["en", "ja"])
        #expect(result.contains("["))
        #expect(result.contains("\"en\""))
        #expect(result.contains("\"ja\""))
    }

    @Test("encodable output in json format")
    func encodableJsonOutput() {
        let formatter = OutputFormatter(format: .json)
        let metadata = SessionMetadata(name: "test", instructions: "Be helpful")
        let result = formatter.outputEncodable(metadata)
        #expect(result.contains("\"name\""))
        #expect(result.contains("\"test\""))
        #expect(result.contains("\"instructions\""))
    }
}
