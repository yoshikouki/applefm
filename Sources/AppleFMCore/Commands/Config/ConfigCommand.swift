import ArgumentParser

struct ConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Manage default settings",
        subcommands: [
            ConfigListCommand.self,
            ConfigGetCommand.self,
            ConfigSetCommand.self,
            ConfigResetCommand.self,
            ConfigDescribeCommand.self,
            ConfigInitCommand.self,
            ConfigPresetCommand.self,
        ],
        defaultSubcommand: ConfigListCommand.self
    )
}
