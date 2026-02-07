import Foundation

/// ~/.applefm/settings.json を管理する
public struct SettingsStore: Sendable {
    public let baseDirectory: URL

    public init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            self.baseDirectory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".applefm")
        }
    }

    private var settingsURL: URL {
        baseDirectory.appendingPathComponent("settings.json")
    }

    public func load() -> Settings {
        guard FileManager.default.fileExists(atPath: settingsURL.path),
              let data = try? Data(contentsOf: settingsURL),
              let settings = try? JSONDecoder().decode(Settings.self, from: data) else {
            return Settings()
        }
        return settings
    }

    public func save(_ settings: Settings) throws {
        try ensureDirectoryExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)
        try data.write(to: settingsURL, options: .atomic)
    }

    public func reset() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: settingsURL.path) {
            try fm.removeItem(at: settingsURL)
        }
    }

    private func ensureDirectoryExists() throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: baseDirectory.path) {
            try fm.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        }
    }
}
