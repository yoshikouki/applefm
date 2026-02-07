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
    var format: OutputFormat?

    func run() async throws {
        let settings = SettingsStore().load()

        let effectiveFormat = format ?? settings.format.flatMap { OutputFormat(rawValue: $0) } ?? .text

        let store = SessionStore()

        if store.sessionExists(name: name) {
            throw AppError.invalidInput("Session '\(name)' already exists.")
        }

        let model = try modelOptions.withSettings(settings).createModel()
        let effectiveToolOptions = toolOptions.withSettings(settings)
        let tools = try effectiveToolOptions.resolveTools()
        let effectiveInstructions = instructions ?? settings.instructions
        let session: LanguageModelSession
        if let effectiveInstructions {
            session = LanguageModelSession(model: model, tools: tools, instructions: effectiveInstructions)
        } else {
            session = LanguageModelSession(model: model, tools: tools)
        }

        let metadata = SessionMetadata(
            name: name,
            instructions: effectiveInstructions,
            guardrails: modelOptions.guardrails?.rawValue ?? settings.guardrails,
            adapterPath: modelOptions.adapter ?? settings.adapter,
            tools: effectiveToolOptions.tool.isEmpty ? nil : effectiveToolOptions.tool
        )
        try store.saveMetadata(metadata)
        try store.saveTranscript(session.transcript, name: name)

        let formatter = OutputFormatter(format: effectiveFormat)
        print(formatter.output([
            "session": name,
            "status": "created",
        ]))
    }
}
