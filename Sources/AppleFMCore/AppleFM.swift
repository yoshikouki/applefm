import ArgumentParser

public struct AppleFM: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "applefm",
        abstract: "A thin CLI wrapper for Apple Foundation Models",
        version: "1.0.0",
        subcommands: [
            ModelCommand.self,
            SessionCommand.self,
        ]
    )

    public init() {}
}
