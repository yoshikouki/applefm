import ArgumentParser

struct ConfigDescribeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "describe",
        abstract: "Describe a setting key or list all keys"
    )

    @Argument(help: "Setting key to describe (omit to list all)")
    var key: String?

    func run() async throws {
        let store = SettingsStore()
        let settings = store.load()

        if let key {
            guard let meta = Settings.keyMetadata[key] else {
                if let suggestion = Settings.suggestKey(for: key) {
                    throw AppError.invalidInput("Unknown setting key: '\(key)'. Did you mean '\(suggestion)'?")
                }
                throw AppError.invalidInput("Unknown setting key: '\(key)'. Valid keys: \(Settings.validKeys.sorted().joined(separator: ", "))")
            }
            printDetail(meta, currentValue: settings.value(forKey: key))
        } else {
            for k in Settings.validKeys.sorted() {
                guard let meta = Settings.keyMetadata[k] else { continue }
                let current = settings.value(forKey: k)
                let valueStr = current ?? "(not set)"
                print("\(meta.key) (\(meta.type)): \(meta.description) [\(valueStr)]")
            }
        }
    }

    private func printDetail(_ meta: KeyMetadata, currentValue: String?) {
        print("Key:         \(meta.key)")
        print("Type:        \(meta.type)")
        print("Description: \(meta.description)")
        if let valid = meta.validValues {
            print("Valid:       \(valid.joined(separator: ", "))")
        }
        if let range = meta.range {
            print("Range:       \(range)")
        }
        print("Current:     \(currentValue ?? "(not set)")")
    }
}
