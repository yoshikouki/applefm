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

    @OptionGroup var generationOptions: GenerationOptionGroup
    @OptionGroup var modelOptions: ModelOptionGroup

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .json

    func run() async throws {
        let store = SessionStore()

        let metadata = try store.loadMetadata(name: name)
        let transcript = try store.loadTranscript(name: name)

        let guardrailsFallback = metadata.guardrails.flatMap { GuardrailsOption(rawValue: $0) } ?? .default
        let model = try modelOptions.createModel(fallbackGuardrails: guardrailsFallback)

        let session: LanguageModelSession
        if transcript.isEmpty, let instructions = metadata.instructions {
            session = LanguageModelSession(model: model, instructions: instructions)
        } else {
            session = LanguageModelSession(model: model, transcript: transcript)
        }

        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let generationSchema = try SchemaLoader.load(from: schema)
        let options = generationOptions.makeOptions()

        do {
            let response = try await session.respond(
                to: promptText,
                schema: generationSchema,
                options: options
            )

            // Save updated transcript
            try store.saveTranscript(session.transcript, name: name)

            let formatter = OutputFormatter(format: format)
            print(formatter.output(String(describing: response.content)))
        } catch {
            throw AppError.generationError(error)
        }
    }
}
