import ArgumentParser

struct ConfigListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all settings"
    )

    @Flag(name: .long, help: "Show all keys including unset ones")
    var all = false

    func run() async throws {
        let store = SettingsStore()
        let settings = store.load()

        if all {
            for key in Settings.validKeys.sorted() {
                let meta = Settings.keyMetadata[key]
                if let v = settings.value(forKey: key) {
                    print("\(key): \(v)")
                } else {
                    let desc = meta?.description ?? ""
                    print("\(key): (not set)  # \(desc)")
                }
            }
        } else {
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
}
