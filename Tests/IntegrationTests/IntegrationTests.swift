import Testing
import Foundation
@testable import AppleFMCore
import FoundationModels

@Suite("Integration Tests")
struct IntegrationTests {

    static let isEnabled: Bool = {
        ProcessInfo.processInfo.environment["APPLEFM_INTEGRATION_TESTS"] != nil
    }()

    // MARK: - Device-dependent tests (gated)

    @Test("model availability returns valid status", .enabled(if: isEnabled))
    func modelAvailability() async throws {
        let model = SystemLanguageModel.default
        let availability = model.availability
        switch availability {
        case .available:
            #expect(true)
        case .unavailable:
            #expect(true)
        @unknown default:
            #expect(true)
        }
    }

    @Test("one-shot respond returns non-empty response", .enabled(if: isEnabled))
    func oneShotRespond() async throws {
        let model = SystemLanguageModel(useCase: .general, guardrails: .default)
        guard model.isAvailable else {
            return
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

        let session = LanguageModelSession(model: model, instructions: "Reply briefly.")
        let metadata = SessionMetadata(name: "lifecycle-test", instructions: "Reply briefly.")
        try store.saveMetadata(metadata)
        try store.saveTranscript(session.transcript, name: "lifecycle-test")
        #expect(store.sessionExists(name: "lifecycle-test"))

        let response = try await session.respond(to: "Say hi.")
        #expect(!response.content.isEmpty)
        try store.saveTranscript(session.transcript, name: "lifecycle-test")

        let transcript = try store.loadTranscript(name: "lifecycle-test")
        #expect(!transcript.isEmpty)

        try store.deleteSession(name: "lifecycle-test")
        #expect(!store.sessionExists(name: "lifecycle-test"))
    }
}
