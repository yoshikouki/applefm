import ArgumentParser

struct ModelCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "model",
        abstract: "Query model information and availability",
        subcommands: [
            ModelAvailabilityCommand.self,
            ModelLanguagesCommand.self,
            ModelSupportsLocaleCommand.self,
        ]
    )
}
