import ArgumentParser
import FoundationModels

struct ModelLanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "languages",
        abstract: "List supported languages"
    )

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let model = SystemLanguageModel.default
        let languages = model.supportedLanguages
            .compactMap { $0.languageCode?.identifier }
            .sorted()

        let formatter = OutputFormatter(format: format)
        print(formatter.outputList(languages))
    }
}
