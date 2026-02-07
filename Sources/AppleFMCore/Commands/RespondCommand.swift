import ArgumentParser
import FoundationModels

struct RespondCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "respond",
        abstract: "One-shot response (creates a temporary session)"
    )

    @Argument(help: "Prompt text")
    var prompt: String?

    @Option(name: .long, help: "Read prompt from file")
    var file: String?

    @Option(name: .long, help: "System instructions")
    var instructions: String?

    @OptionGroup var generationOptions: GenerationOptionGroup
    @OptionGroup var modelOptions: ModelOptionGroup
    @OptionGroup var toolOptions: ToolOptionGroup

    @Flag(inversion: .prefixedNo, help: "Stream response incrementally")
    var stream: Bool?

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat?

    func validate() throws {
        if stream == true && format == .json {
            throw ValidationError("--stream and --format json cannot be used together.")
        }
    }

    func run() async throws {
        let settings = SettingsStore().load()

        let effectiveStream = stream ?? settings.stream ?? false
        let effectiveFormat = format ?? settings.format.flatMap { OutputFormat(rawValue: $0) } ?? .text

        if effectiveStream && effectiveFormat == .json {
            throw ValidationError("--stream and --format json cannot be used together.")
        }

        let genOpts = generationOptions.withSettings(settings)
        let model = try modelOptions.withSettings(settings).createModel()
        let tools = try toolOptions.withSettings(settings).resolveTools()
        let effectiveInstructions = instructions ?? settings.instructions
        let session: LanguageModelSession
        if let effectiveInstructions {
            session = LanguageModelSession(model: model, tools: tools, instructions: effectiveInstructions)
        } else {
            session = LanguageModelSession(model: model, tools: tools)
        }

        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let options = genOpts.makeOptions()

        do {
            if effectiveStream {
                let responseStream = session.streamResponse(to: promptText, options: options)
                try await ResponseStreamer.stream(responseStream)
            } else {
                let response = try await session.respond(to: promptText, options: options)
                let formatter = OutputFormatter(format: effectiveFormat)
                print(formatter.output(response.content))
            }
        } catch {
            throw AppError.generationError(error)
        }
    }
}
