import ArgumentParser
import Foundation
import FoundationModels

struct SessionGenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate structured output using a JSON schema"
    )

    @Argument(help: "Session name")
    var name: String

    @Argument(help: "Prompt text")
    var prompt: String?

    @Option(name: .long, help: "Read prompt from file")
    var file: String?

    @Option(name: .long, help: "Path to JSON schema file")
    var schema: String

    @Option(name: .long, help: "Maximum response tokens")
    var maxTokens: Int?

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .json

    func run() async throws {
        let store = SessionStore()

        _ = try store.loadMetadata(name: name)
        let transcript = try store.loadTranscript(name: name)

        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw AppError.modelNotAvailable("Model is not available.")
        }

        let session = LanguageModelSession(transcript: transcript)
        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let generationSchema = try SchemaLoader.load(from: schema)

        var options = GenerationOptions()
        if let maxTokens {
            options.maximumResponseTokens = maxTokens
        }

        let response = try await session.respond(
            to: promptText,
            schema: generationSchema,
            options: options
        )

        // Save updated transcript
        try store.saveTranscript(session.transcript, name: name)

        // Output the generated content
        let formatter = OutputFormatter(format: format)
        print(formatter.output(String(describing: response.content)))
    }
}
