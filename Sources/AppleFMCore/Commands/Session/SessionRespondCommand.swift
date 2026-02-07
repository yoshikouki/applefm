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

    @Option(name: .long, help: "Maximum response tokens")
    var maxTokens: Int?

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let store = SessionStore()

        _ = try store.loadMetadata(name: name) // Verify session exists
        let transcript = try store.loadTranscript(name: name)

        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw AppError.modelNotAvailable("Model is not available.")
        }

        let session = LanguageModelSession(transcript: transcript)

        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)

        let response: LanguageModelSession.Response<String>
        if let maxTokens {
            var options = GenerationOptions()
            options.maximumResponseTokens = maxTokens
            response = try await session.respond(to: promptText, options: options)
        } else {
            response = try await session.respond(to: promptText)
        }

        // Save updated transcript
        try store.saveTranscript(session.transcript, name: name)

        let formatter = OutputFormatter(format: format)
        print(formatter.output(response.content))
    }
}
