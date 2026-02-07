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

    @Option(name: .long, help: "Temperature for sampling (0.0-2.0)")
    var temperature: Double?

    @Option(name: .long, help: "Sampling mode (greedy)")
    var sampling: SamplingModeOption?

    @Option(name: .long, help: "Random sampling probability threshold (0.0-1.0)")
    var samplingThreshold: Double?

    @Option(name: .long, help: "Random sampling top-k count")
    var samplingTop: Int?

    @Option(name: .long, help: "Random sampling seed")
    var samplingSeed: UInt64?

    @Option(name: .long, help: "Guardrails level (default or permissive)")
    var guardrails: GuardrailsOption = .default

    @Option(name: .long, help: "Path to adapter file")
    var adapter: String?

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .json

    func run() async throws {
        let store = SessionStore()

        _ = try store.loadMetadata(name: name)
        let transcript = try store.loadTranscript(name: name)

        let model = try ModelFactory.createModel(guardrails: guardrails, adapterPath: adapter)
        let session = LanguageModelSession(model: model, transcript: transcript)
        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let generationSchema = try SchemaLoader.load(from: schema)
        let samplingMode = ModelFactory.resolveSamplingMode(
            mode: sampling, threshold: samplingThreshold, top: samplingTop, seed: samplingSeed
        )
        let options = ModelFactory.makeGenerationOptions(maxTokens: maxTokens, temperature: temperature, sampling: samplingMode)

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
