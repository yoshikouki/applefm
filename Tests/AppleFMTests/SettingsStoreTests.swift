import Testing
import Foundation
@testable import AppleFMCore

@Suite("SettingsStore Tests")
struct SettingsStoreTests {
    let testDir: URL

    init() throws {
        testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("applefm-settings-tests-\(UUID().uuidString)")
    }

    @Test("load returns empty settings when file does not exist")
    func loadNoFile() {
        let store = SettingsStore(baseDirectory: testDir)
        let settings = store.load()
        #expect(settings == Settings())
    }

    @Test("save and load round-trip")
    func saveLoadRoundTrip() throws {
        let store = SettingsStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        var settings = Settings()
        settings.temperature = 0.7
        settings.maxTokens = 1000
        settings.stream = true

        try store.save(settings)
        let loaded = store.load()

        #expect(loaded.temperature == 0.7)
        #expect(loaded.maxTokens == 1000)
        #expect(loaded.stream == true)
    }

    @Test("reset removes the settings file")
    func resetRemovesFile() throws {
        let store = SettingsStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try store.save(Settings(temperature: 0.5))
        #expect(store.load().temperature == 0.5)

        try store.reset()
        #expect(store.load().temperature == nil)
    }

    @Test("reset does not throw when file does not exist")
    func resetNoFile() throws {
        let store = SettingsStore(baseDirectory: testDir)
        try store.reset()
    }

    @Test("save overwrites existing settings")
    func saveOverwrites() throws {
        let store = SettingsStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try store.save(Settings(temperature: 0.5))
        try store.save(Settings(temperature: 0.9))

        let loaded = store.load()
        #expect(loaded.temperature == 0.9)
    }

    @Test("all fields are optional in JSON")
    func emptyJsonLoads() throws {
        let store = SettingsStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: testDir.appendingPathComponent("settings.json"))

        let loaded = store.load()
        #expect(loaded == Settings())
    }
}

@Suite("Settings Tests")
struct SettingsTests {
    @Test("setValue parses integer correctly")
    func setValueInt() throws {
        var settings = Settings()
        try settings.setValue("1000", forKey: "maxTokens")
        #expect(settings.maxTokens == 1000)
    }

    @Test("setValue parses double correctly")
    func setValueDouble() throws {
        var settings = Settings()
        try settings.setValue("0.7", forKey: "temperature")
        #expect(settings.temperature == 0.7)
    }

    @Test("setValue parses bool correctly")
    func setValueBool() throws {
        var settings = Settings()
        try settings.setValue("true", forKey: "stream")
        #expect(settings.stream == true)
    }

    @Test("setValue parses comma-separated tools")
    func setValueTools() throws {
        var settings = Settings()
        try settings.setValue("shell,file-read", forKey: "tools")
        #expect(settings.tools == ["shell", "file-read"])
    }

    @Test("setValue rejects unknown key")
    func setValueUnknownKey() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("value", forKey: "unknown")
        }
    }

    @Test("setValue rejects invalid integer")
    func setValueInvalidInt() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("abc", forKey: "maxTokens")
        }
    }

    @Test("setValue rejects invalid boolean")
    func setValueInvalidBool() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("maybe", forKey: "stream")
        }
    }

    @Test("removeValue clears a single key")
    func removeValue() throws {
        var settings = Settings(maxTokens: 1000, temperature: 0.7)
        try settings.removeValue(forKey: "temperature")
        #expect(settings.temperature == nil)
        #expect(settings.maxTokens == 1000)
    }

    @Test("removeValue rejects unknown key")
    func removeValueUnknownKey() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.removeValue(forKey: "unknown")
        }
    }

    @Test("value(forKey:) returns nil for unset keys")
    func valueForKeyNil() {
        let settings = Settings()
        #expect(settings.value(forKey: "temperature") == nil)
    }

    @Test("value(forKey:) returns string representation")
    func valueForKey() {
        let settings = Settings(temperature: 0.7, stream: true)
        #expect(settings.value(forKey: "temperature") == "0.7")
        #expect(settings.value(forKey: "stream") == "true")
    }

    @Test("allValues returns only set keys")
    func allValues() {
        let settings = Settings(temperature: 0.7, guardrails: "permissive")
        let values = settings.allValues()
        #expect(values.count == 2)
        let keys = values.map(\.key)
        #expect(keys.contains("temperature"))
        #expect(keys.contains("guardrails"))
    }

    @Test("validKeys contains all expected keys")
    func validKeysComplete() {
        let expected = ["maxTokens", "temperature", "sampling", "samplingThreshold",
                        "samplingTop", "samplingSeed", "guardrails", "adapter",
                        "tools", "toolApproval", "format", "stream", "instructions"]
        for key in expected {
            #expect(Settings.validKeys.contains(key))
        }
    }
}
