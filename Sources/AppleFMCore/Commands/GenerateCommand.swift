import ArgumentParser
import Foundation
import FoundationModels

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "One-shot structured generation (creates a temporary session)"
    )

    @Argument(help: "Prompt text")
    var prompt: String?

    @Option(name: .long, help: "Read prompt from file")
    var file: String?

    @Option(name: .long, help: "Path to JSON schema file")
    var schema: String

    @Option(name: .long, help: "System instructions")
    var instructions: String?

    @Option(name: .long, help: "Maximum response tokens")
    var maxTokens: Int?

    @Option(name: .long, help: "Temperature for sampling (0.0-2.0)")
    var temperature: Double?

    @Option(name: .long, help: "Guardrails level (default or permissive)")
    var guardrails: GuardrailsOption = .default

    @Option(name: .long, help: "Path to adapter file")
    var adapter: String?

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .json

    func run() async throws {
        let model = try ModelFactory.createModel(guardrails: guardrails, adapterPath: adapter)
        let session: LanguageModelSession
        if let instructions {
            session = LanguageModelSession(model: model, instructions: instructions)
        } else {
            session = LanguageModelSession(model: model)
        }

        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let generationSchema = try SchemaLoader.load(from: schema)
        let options = ModelFactory.makeGenerationOptions(maxTokens: maxTokens, temperature: temperature)

        do {
            let response = try await session.respond(
                to: promptText,
                schema: generationSchema,
                options: options
            )
            let formatter = OutputFormatter(format: format)
            print(formatter.output(String(describing: response.content)))
        } catch {
            throw AppError.generationError(error)
        }
    }
}
