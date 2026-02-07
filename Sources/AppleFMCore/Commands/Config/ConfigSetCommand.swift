import ArgumentParser

struct ConfigSetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set a default value"
    )

    @Argument(help: "Setting key")
    var key: String

    @Argument(help: "Setting value")
    var value: String

    func run() async throws {
        let store = SettingsStore()
        var settings = store.load()
        try settings.setValue(value, forKey: key)
        try store.save(settings)
    }
}
