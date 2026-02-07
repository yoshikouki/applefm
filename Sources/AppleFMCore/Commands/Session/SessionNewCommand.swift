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

    @OptionGroup var modelOptions: ModelOptionGroup
    @OptionGroup var toolOptions: ToolOptionGroup

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let store = SessionStore()

        if store.sessionExists(name: name) {
            throw AppError.invalidInput("Session '\(name)' already exists.")
        }

        let model = try modelOptions.createModel()
        let tools = try toolOptions.resolveTools()
        let session: LanguageModelSession
        if let instructions {
            session = LanguageModelSession(model: model, tools: tools, instructions: instructions)
        } else {
            session = LanguageModelSession(model: model, tools: tools)
        }

        let metadata = SessionMetadata(
            name: name,
            instructions: instructions,
            guardrails: modelOptions.guardrails?.rawValue,
            adapterPath: modelOptions.adapter,
            tools: toolOptions.tool.isEmpty ? nil : toolOptions.tool
        )
        try store.saveMetadata(metadata)
        try store.saveTranscript(session.transcript, name: name)

        let formatter = OutputFormatter(format: format)
        print(formatter.output([
            "session": name,
            "status": "created",
        ]))
    }
}
