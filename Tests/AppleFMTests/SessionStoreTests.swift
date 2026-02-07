import Testing
import Foundation
@testable import AppleFMCore

@Suite("SessionStore Tests")
struct SessionStoreTests {
    let testDir: URL

    init() throws {
        testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("applefm-tests-\(UUID().uuidString)")
    }

    @Test("save and load metadata round-trip")
    func saveLoadMetadata() throws {
        let store = SessionStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        let metadata = SessionMetadata(name: "test-session", instructions: "Be concise")

        try store.saveMetadata(metadata)
        let loaded = try store.loadMetadata(name: "test-session")

        #expect(loaded.name == "test-session")
        #expect(loaded.instructions == "Be concise")
    }

    @Test("sessionExists returns true for existing session")
    func sessionExists() throws {
        let store = SessionStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        let metadata = SessionMetadata(name: "existing")

        try store.saveMetadata(metadata)
        #expect(store.sessionExists(name: "existing"))
        #expect(!store.sessionExists(name: "nonexistent"))
    }

    @Test("listSessions returns all sessions")
    func listSessions() throws {
        let store = SessionStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try store.saveMetadata(SessionMetadata(name: "alpha"))
        try store.saveMetadata(SessionMetadata(name: "beta"))

        let sessions = try store.listSessions()
        #expect(sessions.count == 2)

        let names = sessions.map(\.name)
        #expect(names.contains("alpha"))
        #expect(names.contains("beta"))
    }

    @Test("deleteSession removes files")
    func deleteSession() throws {
        let store = SessionStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try store.saveMetadata(SessionMetadata(name: "to-delete"))

        #expect(store.sessionExists(name: "to-delete"))
        try store.deleteSession(name: "to-delete")
        #expect(!store.sessionExists(name: "to-delete"))
    }

    @Test("loadMetadata throws for nonexistent session")
    func loadNonexistent() {
        let store = SessionStore(baseDirectory: testDir)
        #expect(throws: AppError.self) {
            try store.loadMetadata(name: "nonexistent")
        }
    }

    @Test("listSessions returns empty for nonexistent directory")
    func listEmptyDirectory() throws {
        let store = SessionStore(baseDirectory: testDir.appendingPathComponent("nope"))
        let sessions = try store.listSessions()
        #expect(sessions.isEmpty)
    }

    // MARK: - Validation Tests

    @Test("rejects session name with path traversal")
    func rejectsPathTraversal() {
        #expect(throws: AppError.self) {
            try SessionStore.validateSessionName("../escape")
        }
    }

    @Test("rejects empty session name")
    func rejectsEmptyName() {
        #expect(throws: AppError.self) {
            try SessionStore.validateSessionName("")
        }
    }

    @Test("rejects session name with spaces")
    func rejectsSpaces() {
        #expect(throws: AppError.self) {
            try SessionStore.validateSessionName("has space")
        }
    }

    @Test("rejects session name with slashes")
    func rejectsSlashes() {
        #expect(throws: AppError.self) {
            try SessionStore.validateSessionName("path/name")
        }
    }

    @Test("accepts valid session name with hyphens and underscores")
    func acceptsValidName() throws {
        try SessionStore.validateSessionName("valid-session_01")
    }

    @Test("rejects session name exceeding 100 characters")
    func rejectsTooLong() {
        let longName = String(repeating: "a", count: 101)
        #expect(throws: AppError.self) {
            try SessionStore.validateSessionName(longName)
        }
    }

    @Test("accepts session name at exactly 100 characters")
    func acceptsMaxLength() throws {
        let name = String(repeating: "a", count: 100)
        try SessionStore.validateSessionName(name)
    }

    @Test("metadata with extended fields round-trips correctly")
    func metadataExtendedFields() throws {
        let store = SessionStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        let metadata = SessionMetadata(
            name: "extended",
            instructions: "test",
            guardrails: "permissive",
            adapterPath: "/path/to/adapter",
            tools: ["shell", "file-read"]
        )
        try store.saveMetadata(metadata)
        let loaded = try store.loadMetadata(name: "extended")

        #expect(loaded.guardrails == "permissive")
        #expect(loaded.adapterPath == "/path/to/adapter")
        #expect(loaded.tools == ["shell", "file-read"])
    }
}
