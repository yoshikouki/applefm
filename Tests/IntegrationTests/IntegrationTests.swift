import Testing
import Foundation
@testable import AppleFMCore

@Suite("Integration Tests")
struct IntegrationTests {

    static let isEnabled: Bool = {
        ProcessInfo.processInfo.environment["APPLEFM_INTEGRATION_TESTS"] != nil
    }()

    // MARK: - SessionStore Validation

    @Test("SessionStore rejects invalid session names")
    func sessionStoreValidation() {
        let store = SessionStore(baseDirectory: FileManager.default.temporaryDirectory
            .appendingPathComponent("applefm-inttest-\(UUID().uuidString)"))
        defer { try? FileManager.default.removeItem(at: store.baseDirectory) }

        #expect(throws: AppError.self) {
            try store.saveMetadata(SessionMetadata(name: "../escape"))
        }
        #expect(throws: AppError.self) {
            try store.saveMetadata(SessionMetadata(name: ""))
        }
        #expect(throws: AppError.self) {
            try store.saveMetadata(SessionMetadata(name: "has space"))
        }
    }

    @Test("SessionStore accepts valid session names")
    func sessionStoreValidNames() throws {
        let store = SessionStore(baseDirectory: FileManager.default.temporaryDirectory
            .appendingPathComponent("applefm-inttest-\(UUID().uuidString)"))
        defer { try? FileManager.default.removeItem(at: store.baseDirectory) }

        let metadata = SessionMetadata(name: "valid-session_01")
        try store.saveMetadata(metadata)
        let loaded = try store.loadMetadata(name: "valid-session_01")
        #expect(loaded.name == "valid-session_01")
    }

    @Test("SessionMetadata preserves guardrails and tools")
    func sessionMetadataFields() throws {
        let store = SessionStore(baseDirectory: FileManager.default.temporaryDirectory
            .appendingPathComponent("applefm-inttest-\(UUID().uuidString)"))
        defer { try? FileManager.default.removeItem(at: store.baseDirectory) }

        let metadata = SessionMetadata(
            name: "meta-test",
            instructions: "Be helpful",
            guardrails: "permissive",
            adapterPath: "/path/to/adapter",
            tools: ["shell", "file-read"]
        )
        try store.saveMetadata(metadata)
        let loaded = try store.loadMetadata(name: "meta-test")
        #expect(loaded.guardrails == "permissive")
        #expect(loaded.adapterPath == "/path/to/adapter")
        #expect(loaded.tools == ["shell", "file-read"])
        #expect(loaded.instructions == "Be helpful")
    }

    @Test("SessionMetadata backward compatibility with missing optional fields")
    func sessionMetadataBackwardCompat() throws {
        let store = SessionStore(baseDirectory: FileManager.default.temporaryDirectory
            .appendingPathComponent("applefm-inttest-\(UUID().uuidString)"))
        defer { try? FileManager.default.removeItem(at: store.baseDirectory) }

        // Simulate old format without new fields
        let oldJson = """
        {
            "name": "old-session",
            "createdAt": "2026-01-01T00:00:00Z"
        }
        """
        try FileManager.default.createDirectory(at: store.baseDirectory, withIntermediateDirectories: true)
        try Data(oldJson.utf8).write(to: store.baseDirectory.appendingPathComponent("old-session.json"))

        let loaded = try store.loadMetadata(name: "old-session")
        #expect(loaded.name == "old-session")
        #expect(loaded.guardrails == nil)
        #expect(loaded.adapterPath == nil)
        #expect(loaded.tools == nil)
        #expect(loaded.instructions == nil)
    }

    // MARK: - Device-dependent tests (gated)

    @Test("model availability returns valid status", .enabled(if: isEnabled))
    func modelAvailability() async throws {
        let model = SystemLanguageModel.default
        // Just verify the availability can be queried without crash
        let availability = model.availability
        switch availability {
        case .available:
            #expect(true)
        case .unavailable:
            #expect(true) // Still valid - device may not support it
        @unknown default:
            #expect(true)
        }
    }

    @Test("one-shot respond returns non-empty response", .enabled(if: isEnabled))
    func oneShotRespond() async throws {
        let model = SystemLanguageModel(useCase: .general, guardrails: .default)
        guard model.isAvailable else {
            return // Skip if model not available
        }
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: "Say hello in exactly one word.")
        #expect(!response.content.isEmpty)
    }

    @Test("session lifecycle: new → respond → transcript → delete", .enabled(if: isEnabled))
    func sessionLifecycle() async throws {
        let model = SystemLanguageModel(useCase: .general, guardrails: .default)
        guard model.isAvailable else {
            return
        }

        let store = SessionStore(baseDirectory: FileManager.default.temporaryDirectory
            .appendingPathComponent("applefm-inttest-\(UUID().uuidString)"))
        defer { try? FileManager.default.removeItem(at: store.baseDirectory) }

        // Create session
        let session = LanguageModelSession(model: model, instructions: "Reply briefly.")
        let metadata = SessionMetadata(name: "lifecycle-test", instructions: "Reply briefly.")
        try store.saveMetadata(metadata)
        try store.saveTranscript(session.transcript, name: "lifecycle-test")
        #expect(store.sessionExists(name: "lifecycle-test"))

        // Respond
        let response = try await session.respond(to: "Say hi.")
        #expect(!response.content.isEmpty)
        try store.saveTranscript(session.transcript, name: "lifecycle-test")

        // Verify transcript is not empty
        let transcript = try store.loadTranscript(name: "lifecycle-test")
        #expect(!transcript.isEmpty)

        // Delete
        try store.deleteSession(name: "lifecycle-test")
        #expect(!store.sessionExists(name: "lifecycle-test"))
    }
}

import FoundationModels
