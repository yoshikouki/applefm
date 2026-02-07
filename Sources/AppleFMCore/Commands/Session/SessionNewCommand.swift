import ArgumentParser
import FoundationModels

struct SessionNewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Create a new session"
    )

    @Argument(help: "Session name")
    var name: String

    @Option(name: .long, help: "System instructions for the session")
    var instructions: String?

    @Option(name: .long, help: "Guardrails level (default or permissive)")
    var guardrails: GuardrailsOption = .default

    @Option(name: .long, help: "Path to adapter file")
    var adapter: String?

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let store = SessionStore()

        if store.sessionExists(name: name) {
            throw AppError.invalidInput("Session '\(name)' already exists.")
        }

        let model = try ModelFactory.createModel(guardrails: guardrails, adapterPath: adapter)
        let session: LanguageModelSession
        if let instructions {
            session = LanguageModelSession(model: model, instructions: instructions)
        } else {
            session = LanguageModelSession(model: model)
        }

        let metadata = SessionMetadata(name: name, instructions: instructions)
        try store.saveMetadata(metadata)
        try store.saveTranscript(session.transcript, name: name)

        let formatter = OutputFormatter(format: format)
        print(formatter.output([
            "session": name,
            "status": "created",
        ]))
    }
}
