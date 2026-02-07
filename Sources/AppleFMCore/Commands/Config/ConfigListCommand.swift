import ArgumentParser

struct ConfigListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all settings"
    )

    func run() async throws {
        let store = SettingsStore()
        let settings = store.load()
        let values = settings.allValues()
        if values.isEmpty {
            print("No settings configured.")
        } else {
            for (key, value) in values {
                print("\(key): \(value)")
            }
        }
    }
}
