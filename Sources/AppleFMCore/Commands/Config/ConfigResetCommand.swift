import ArgumentParser

struct ConfigResetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Reset settings (specify key for individual, omit for all)"
    )

    @Argument(help: "Setting key to reset (omit to reset all)")
    var key: String?

    func run() async throws {
        let store = SettingsStore()
        if let key {
            var settings = store.load()
            try settings.removeValue(forKey: key)
            try store.save(settings)
        } else {
            try store.reset()
        }
    }
}
