import ArgumentParser

struct ConfigPresetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "preset",
        abstract: "Apply a built-in preset or list available presets"
    )

    @Argument(help: "Preset name to apply (omit to list available presets)")
    var name: String?

    func run() async throws {
        if let name {
            guard let preset = Settings.presets.first(where: { $0.name == name }) else {
                let available = Settings.presets.map(\.name).joined(separator: ", ")
                throw AppError.invalidInput("Unknown preset '\(name)'. Available: \(available)")
            }
            let store = SettingsStore()
            var settings = store.load()
            var changes: [String] = []
            for (key, value) in preset.values {
                let old = settings.value(forKey: key)
                try settings.setValue(value, forKey: key)
                if let old {
                    changes.append("  \(key): \(old) -> \(value)")
                } else {
                    changes.append("  \(key): \(value)")
                }
            }
            try store.save(settings)
            print("Applied preset '\(preset.name)': \(preset.description)")
            for change in changes {
                print(change)
            }
        } else {
            print("Available presets:")
            for preset in Settings.presets {
                let keys = preset.values.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
                print("  \(preset.name) - \(preset.description) (\(keys))")
            }
        }
    }
}
