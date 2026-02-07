import ArgumentParser

public struct AppleFM: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "applefm",
        abstract: "A thin CLI wrapper for Apple Foundation Models",
        version: "1.1.1",
        subcommands: [
            ModelCommand.self,
            SessionCommand.self,
            ConfigCommand.self,
            ChatCommand.self,
            RespondCommand.self,
            GenerateCommand.self,
        ],
        defaultSubcommand: RespondCommand.self
    )

    public init() {}
}
