import ArgumentParser
import FoundationModels

struct SessionRespondCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "respond",
        abstract: "Send a prompt to a session and get a response"
    )

    @Argument(help: "Session name")
    var name: String

    @Argument(help: "Prompt text")
    var prompt: String?

    @Option(name: .long, help: "Read prompt from file")
    var file: String?

    @OptionGroup var generationOptions: GenerationOptionGroup
    @OptionGroup var modelOptions: ModelOptionGroup
    @OptionGroup var toolOptions: ToolOptionGroup

    @Flag(name: .long, help: "Stream response incrementally")
    var stream: Bool = false

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let store = SessionStore()

        let metadata = try store.loadMetadata(name: name)
        let transcript = try store.loadTranscript(name: name)

        // Use metadata values as fallbacks for model/tool options
        let guardrailsFallback = metadata.guardrails.flatMap { GuardrailsOption(rawValue: $0) } ?? .default
        let model = try modelOptions.createModel(fallbackGuardrails: guardrailsFallback)

        let tools: [any Tool]
        if !toolOptions.tool.isEmpty {
            tools = try toolOptions.resolveTools()
        } else if let savedTools = metadata.tools, !savedTools.isEmpty {
            tools = try ToolRegistry.resolve(names: savedTools, approval: ToolApproval(mode: toolOptions.toolApproval))
        } else {
            tools = []
        }

        let session: LanguageModelSession
        if transcript.isEmpty, let instructions = metadata.instructions {
            session = LanguageModelSession(model: model, tools: tools, instructions: instructions)
        } else {
            session = LanguageModelSession(model: model, tools: tools, transcript: transcript)
        }

        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let options = generationOptions.makeOptions()

        do {
            if stream {
                let responseStream = session.streamResponse(to: promptText, options: options)
                try await ResponseStreamer.stream(responseStream)
            } else {
                let response = try await session.respond(to: promptText, options: options)
                let formatter = OutputFormatter(format: format)
                print(formatter.output(response.content))
            }
        } catch {
            throw AppError.generationError(error)
        }

        // Save updated transcript
        try store.saveTranscript(session.transcript, name: name)
    }
}
