import ArgumentParser
import Foundation
import FoundationModels

struct ModelSupportsLocaleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "supports-locale",
        abstract: "Check if a locale is supported"
    )

    @Argument(help: "Locale identifier (e.g., en_US, ja_JP)")
    var localeIdentifier: String

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let model = SystemLanguageModel.default
        let locale = Locale(identifier: localeIdentifier)
        let supported = model.supportsLocale(locale)

        let formatter = OutputFormatter(format: format)
        switch format {
        case .text:
            print(formatter.output([
                "locale": localeIdentifier,
                "supported": supported ? "true" : "false",
            ]))
        case .json:
            struct Result: Encodable {
                let locale: String
                let supported: Bool
            }
            print(formatter.outputEncodable(Result(locale: localeIdentifier, supported: supported)))
        }
    }
}
