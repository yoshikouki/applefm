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
        let metadata = SessionMetadata(name: "test-session", instructions: "Be concise")

        try store.saveMetadata(metadata)
        let loaded = try store.loadMetadata(name: "test-session")

        #expect(loaded.name == "test-session")
        #expect(loaded.instructions == "Be concise")

        // Cleanup
        try? FileManager.default.removeItem(at: testDir)
    }

    @Test("sessionExists returns true for existing session")
    func sessionExists() throws {
        let store = SessionStore(baseDirectory: testDir)
        let metadata = SessionMetadata(name: "existing")

        try store.saveMetadata(metadata)
        #expect(store.sessionExists(name: "existing"))
        #expect(!store.sessionExists(name: "nonexistent"))

        try? FileManager.default.removeItem(at: testDir)
    }

    @Test("listSessions returns all sessions")
    func listSessions() throws {
        let store = SessionStore(baseDirectory: testDir)

        try store.saveMetadata(SessionMetadata(name: "alpha"))
        try store.saveMetadata(SessionMetadata(name: "beta"))

        let sessions = try store.listSessions()
        #expect(sessions.count == 2)

        let names = sessions.map(\.name)
        #expect(names.contains("alpha"))
        #expect(names.contains("beta"))

        try? FileManager.default.removeItem(at: testDir)
    }

    @Test("deleteSession removes files")
    func deleteSession() throws {
        let store = SessionStore(baseDirectory: testDir)
        try store.saveMetadata(SessionMetadata(name: "to-delete"))

        #expect(store.sessionExists(name: "to-delete"))
        try store.deleteSession(name: "to-delete")
        #expect(!store.sessionExists(name: "to-delete"))

        try? FileManager.default.removeItem(at: testDir)
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
}
