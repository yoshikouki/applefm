import ArgumentParser
import FoundationModels

struct SessionTranscriptCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "transcript",
        abstract: "Show session transcript"
    )

    @Argument(help: "Session name")
    var name: String

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let store = SessionStore()

        _ = try store.loadMetadata(name: name)
        let transcript = try store.loadTranscript(name: name)

        let transcriptFormatter = TranscriptFormatter(format: format)
        let output = transcriptFormatter.formatTranscript(transcript)

        if output.isEmpty {
            print("Transcript is empty.")
        } else {
            print(output)
        }
    }
}
