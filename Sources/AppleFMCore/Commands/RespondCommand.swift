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

    @Flag(name: .long, help: "Stream response incrementally")
    var stream: Bool = false

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func validate() throws {
        if stream && format == .json {
            throw ValidationError("--stream and --format json cannot be used together.")
        }
    }

    func run() async throws {
        let model = try modelOptions.createModel()
        let tools = try toolOptions.resolveTools()
        let session: LanguageModelSession
        if let instructions {
            session = LanguageModelSession(model: model, tools: tools, instructions: instructions)
        } else {
            session = LanguageModelSession(model: model, tools: tools)
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
    }
}
