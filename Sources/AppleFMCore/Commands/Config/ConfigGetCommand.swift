import ArgumentParser

struct ConfigGetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a setting value"
    )

    @Argument(help: "Setting key")
    var key: String

    func run() async throws {
        guard Settings.validKeys.contains(key) else {
            throw AppError.invalidInput("Unknown setting key: '\(key)'. Valid keys: \(Settings.validKeys.sorted().joined(separator: ", "))")
        }
        let store = SettingsStore()
        let settings = store.load()
        if let value = settings.value(forKey: key) {
            print(value)
        }
    }
}
