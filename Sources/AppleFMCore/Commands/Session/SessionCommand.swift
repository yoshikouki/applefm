import ArgumentParser

struct SessionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "session",
        abstract: "Manage language model sessions",
        subcommands: [
            SessionNewCommand.self,
            SessionRespondCommand.self,
        ]
    )
}
