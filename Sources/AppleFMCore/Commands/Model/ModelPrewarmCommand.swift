import ArgumentParser
import FoundationModels

struct ModelPrewarmCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prewarm",
        abstract: "Prewarm the model for reduced latency"
    )

    @Option(name: .long, help: "Optional prompt prefix to optimize for")
    var promptPrefix: String?

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let model = try ModelFactory.createModel()
        let session = LanguageModelSession(model: model)
        if let promptPrefix {
            session.prewarm(promptPrefix: Prompt(promptPrefix))
        } else {
            session.prewarm()
        }
        let formatter = OutputFormatter(format: format)
        print(formatter.output("Model prewarmed successfully."))
    }
}
