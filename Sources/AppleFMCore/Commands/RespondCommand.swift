import ArgumentParser
import Darwin
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

    @Option(name: .long, help: "Maximum response tokens")
    var maxTokens: Int?

    @Flag(name: .long, help: "Stream response incrementally")
    var stream: Bool = false

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw AppError.modelNotAvailable("Model is not available.")
        }

        let session: LanguageModelSession
        if let instructions {
            session = LanguageModelSession(instructions: instructions)
        } else {
            session = LanguageModelSession()
        }

        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)

        var options = GenerationOptions()
        if let maxTokens {
            options.maximumResponseTokens = maxTokens
        }

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
    }
}
