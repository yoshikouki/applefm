import ArgumentParser
import Darwin
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

    @Option(name: .long, help: "Maximum response tokens")
    var maxTokens: Int?

    @Option(name: .long, help: "Temperature for sampling (0.0-2.0)")
    var temperature: Double?

    @Option(name: .long, help: "Guardrails level (default or permissive)")
    var guardrails: GuardrailsOption = .default

    @Option(name: .long, help: "Path to adapter file")
    var adapter: String?

    @Option(name: .long, help: "Enable built-in tool (shell, file-read). Repeatable.")
    var tool: [String] = []

    @Flag(name: .long, help: "Stream response incrementally")
    var stream: Bool = false

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let store = SessionStore()

        _ = try store.loadMetadata(name: name) // Verify session exists
        let transcript = try store.loadTranscript(name: name)

        let model = try ModelFactory.createModel(guardrails: guardrails, adapterPath: adapter)
        let tools = try ToolRegistry.resolve(names: tool)
        let session = LanguageModelSession(model: model, tools: tools, transcript: transcript)
        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let options = ModelFactory.makeGenerationOptions(maxTokens: maxTokens, temperature: temperature)

        do {
            if stream {
                let responseStream = session.streamResponse(to: promptText, options: options)
                for try await partial in responseStream {
                    print(partial, terminator: "")
                    fflush(stdout)
                }
                print()
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
