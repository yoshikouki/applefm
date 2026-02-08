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

    @Test("load returns default settings when JSON is corrupted")
    func loadCorruptedJson() throws {
        let store = SettingsStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        try Data("{ invalid json".utf8).write(to: testDir.appendingPathComponent("settings.json"))

        let loaded = store.load()
        #expect(loaded == Settings())
    }

    @Test("load returns default settings when file contains unexpected type")
    func loadUnexpectedType() throws {
        let store = SettingsStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        try Data("[]".utf8).write(to: testDir.appendingPathComponent("settings.json"))

        let loaded = store.load()
        #expect(loaded == Settings())
    }

    @Test("directory has 0700 permissions after save")
    func directoryPermissions() throws {
        let store = SettingsStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try store.save(Settings(temperature: 0.5))
        let attrs = try FileManager.default.attributesOfItem(atPath: testDir.path)
        let perms = attrs[.posixPermissions] as? Int
        #expect(perms == 0o700)
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

@Suite("OptionGroup withSettings Tests")
struct OptionGroupWithSettingsTests {
    @Test("ToolOptionGroup withSettings applies toolApproval when not set by CLI")
    func toolApprovalFromSettings() throws {
        let settings = Settings(toolApproval: "auto")
        let group = try ToolOptionGroup.parse([])
        let result = group.withSettings(settings)
        #expect(result.toolApproval == .auto)
    }

    @Test("ToolOptionGroup withSettings does not override CLI-specified toolApproval")
    func toolApprovalCLIOverride() throws {
        let settings = Settings(toolApproval: "auto")
        let group = try ToolOptionGroup.parse(["--tool-approval", "ask"])
        let result = group.withSettings(settings)
        #expect(result.toolApproval == .ask)
    }

    @Test("ToolOptionGroup withSettings leaves nil when settings has no toolApproval")
    func toolApprovalBothNil() throws {
        let settings = Settings()
        let group = try ToolOptionGroup.parse([])
        let result = group.withSettings(settings)
        #expect(result.toolApproval == nil)
    }

    @Test("ToolOptionGroup withSettings applies tools from settings")
    func toolsFromSettings() throws {
        let settings = Settings(tools: ["shell"])
        let group = try ToolOptionGroup.parse([])
        let result = group.withSettings(settings)
        #expect(result.tool == ["shell"])
    }

    @Test("ToolOptionGroup withSettings does not override CLI-specified tools")
    func toolsCLIOverride() throws {
        let settings = Settings(tools: ["shell"])
        let group = try ToolOptionGroup.parse(["--tool", "file-read"])
        let result = group.withSettings(settings)
        #expect(result.tool == ["file-read"])
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
                        "tools", "toolApproval", "format", "stream", "instructions", "logEnabled",
                        "language"]
        for key in expected {
            #expect(Settings.validKeys.contains(key))
        }
    }

    // MARK: - Validation Tests

    @Test("setValue rejects invalid guardrails value")
    func setValueInvalidGuardrails() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("foo", forKey: "guardrails")
        }
    }

    @Test("setValue accepts valid guardrails values")
    func setValueValidGuardrails() throws {
        var settings = Settings()
        try settings.setValue("default", forKey: "guardrails")
        #expect(settings.guardrails == "default")
        try settings.setValue("permissive", forKey: "guardrails")
        #expect(settings.guardrails == "permissive")
    }

    @Test("setValue rejects invalid format value")
    func setValueInvalidFormat() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("xml", forKey: "format")
        }
    }

    @Test("setValue rejects invalid toolApproval value")
    func setValueInvalidToolApproval() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("never", forKey: "toolApproval")
        }
    }

    @Test("setValue rejects invalid sampling value")
    func setValueInvalidSampling() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("random", forKey: "sampling")
        }
    }

    @Test("setValue rejects temperature out of range")
    func setValueTemperatureRange() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("5.0", forKey: "temperature")
        }
        #expect(throws: AppError.self) {
            try settings.setValue("-1.0", forKey: "temperature")
        }
    }

    @Test("setValue rejects samplingThreshold out of range")
    func setValueSamplingThresholdRange() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("1.5", forKey: "samplingThreshold")
        }
    }

    @Test("setValue rejects invalid tool name")
    func setValueInvalidTool() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("shell,invalid", forKey: "tools")
        }
    }

    @Test("suggestKey returns close match")
    func suggestKeyMatch() {
        #expect(Settings.suggestKey(for: "temprature") == "temperature")
        #expect(Settings.suggestKey(for: "maxToken") == "maxTokens")
    }

    @Test("suggestKey returns nil for distant input")
    func suggestKeyNoMatch() {
        #expect(Settings.suggestKey(for: "zzzzzzz") == nil)
    }

    @Test("Did you mean in error message for unknown key typo")
    func didYouMeanInError() {
        var settings = Settings()
        do {
            try settings.setValue("0.7", forKey: "temprature")
            #expect(Bool(false), "Should have thrown")
        } catch let error as AppError {
            let message = "\(error)"
            #expect(message.contains("Did you mean"))
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    // MARK: - logEnabled Tests

    @Test("setValue parses logEnabled boolean")
    func setValueLogEnabled() throws {
        var settings = Settings()
        try settings.setValue("false", forKey: "logEnabled")
        #expect(settings.logEnabled == false)
        try settings.setValue("true", forKey: "logEnabled")
        #expect(settings.logEnabled == true)
    }

    @Test("value(forKey:) returns logEnabled")
    func valueForKeyLogEnabled() {
        let settings = Settings(logEnabled: false)
        #expect(settings.value(forKey: "logEnabled") == "false")
    }

    @Test("isLogEnabled defaults to true")
    func isLogEnabledDefault() {
        let settings = Settings()
        #expect(settings.isLogEnabled == true)
    }

    @Test("isLogEnabled respects setting")
    func isLogEnabledSetting() {
        let settings = Settings(logEnabled: false)
        #expect(settings.isLogEnabled == false)
    }

    // MARK: - KeyMetadata Tests

    @Test("all valid keys have metadata")
    func allKeysHaveMetadata() {
        for key in Settings.validKeys {
            #expect(Settings.keyMetadata[key] != nil, "Missing metadata for key: \(key)")
        }
    }

    // MARK: - Preset Tests

    // MARK: - language Tests

    @Test("setValue parses language correctly")
    func setValueLanguage() throws {
        var settings = Settings()
        try settings.setValue("ja", forKey: "language")
        #expect(settings.language == "ja")
        try settings.setValue("en", forKey: "language")
        #expect(settings.language == "en")
    }

    @Test("setValue rejects invalid language")
    func setValueInvalidLanguage() {
        var settings = Settings()
        #expect(throws: AppError.self) {
            try settings.setValue("fr", forKey: "language")
        }
    }

    @Test("value(forKey:) returns language")
    func valueForKeyLanguage() {
        let settings = Settings(language: "ja")
        #expect(settings.value(forKey: "language") == "ja")
    }

    @Test("removeValue clears language")
    func removeValueLanguage() throws {
        var settings = Settings(language: "ja")
        try settings.removeValue(forKey: "language")
        #expect(settings.language == nil)
    }

    // MARK: - effectiveInstructions Tests

    @Test("effectiveInstructions with language only")
    func effectiveInstructionsLanguageOnly() {
        let settings = Settings(language: "ja")
        let result = settings.effectiveInstructions(cliInstructions: nil, cliLanguage: nil)
        #expect(result == "Respond in Japanese.")
    }

    @Test("effectiveInstructions with language and base instructions")
    func effectiveInstructionsLanguageAndBase() {
        let settings = Settings(instructions: "Be concise.", language: "en")
        let result = settings.effectiveInstructions(cliInstructions: nil, cliLanguage: nil)
        #expect(result == "Respond in English. Be concise.")
    }

    @Test("effectiveInstructions CLI language overrides settings")
    func effectiveInstructionsCLILanguageOverride() {
        let settings = Settings(language: "ja")
        let result = settings.effectiveInstructions(cliInstructions: nil, cliLanguage: "en")
        #expect(result == "Respond in English.")
    }

    @Test("effectiveInstructions CLI instructions overrides settings")
    func effectiveInstructionsCLIInstructionsOverride() {
        let settings = Settings(instructions: "Settings instructions")
        let result = settings.effectiveInstructions(cliInstructions: "CLI instructions", cliLanguage: nil)
        #expect(result == "CLI instructions")
    }

    @Test("effectiveInstructions returns nil when all nil")
    func effectiveInstructionsAllNil() {
        let settings = Settings()
        let result = settings.effectiveInstructions(cliInstructions: nil, cliLanguage: nil)
        #expect(result == nil)
    }

    // MARK: - Preset Tests

    @Test("presets contain expected names")
    func presetsExist() {
        let names = Settings.presets.map(\.name)
        #expect(names.contains("creative"))
        #expect(names.contains("precise"))
        #expect(names.contains("balanced"))
    }
}
