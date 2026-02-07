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

    @OptionGroup var generationOptions: GenerationOptionGroup
    @OptionGroup var modelOptions: ModelOptionGroup

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat?

    func run() async throws {
        let settings = SettingsStore().load()

        let effectiveFormat = format ?? settings.format.flatMap { OutputFormat(rawValue: $0) } ?? .json

        let model = try modelOptions.withSettings(settings).createModel()
        let effectiveInstructions = instructions ?? settings.instructions
        let session: LanguageModelSession
        if let effectiveInstructions {
            session = LanguageModelSession(model: model, instructions: effectiveInstructions)
        } else {
            session = LanguageModelSession(model: model)
        }

        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let generationSchema = try SchemaLoader.load(from: schema)
        let options = generationOptions.withSettings(settings).makeOptions()

        do {
            let response = try await session.respond(
                to: promptText,
                schema: generationSchema,
                options: options
            )
            let formatter = OutputFormatter(format: effectiveFormat)
            print(formatter.output(String(describing: response.content)))
        } catch {
            throw AppError.generationError(error)
        }
    }
}
