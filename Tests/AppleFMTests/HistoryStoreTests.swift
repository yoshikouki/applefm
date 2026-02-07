import Testing
import Foundation
@testable import AppleFMCore

@Suite("HistoryStore Tests")
struct HistoryStoreTests {
    let testDir: URL

    init() throws {
        testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("applefm-tests-\(UUID().uuidString)")
    }

    @Test("append creates file and writes entry")
    func appendCreatesFile() throws {
        let store = HistoryStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        let entry = HistoryEntry(sessionId: "test-id", ts: 1000, text: "Hello", cwd: "/tmp")
        try store.append(entry)

        let entries = try store.loadAll()
        #expect(entries.count == 1)
        #expect(entries[0].sessionId == "test-id")
        #expect(entries[0].ts == 1000)
        #expect(entries[0].text == "Hello")
        #expect(entries[0].cwd == "/tmp")
    }

    @Test("append multiple entries")
    func appendMultiple() throws {
        let store = HistoryStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try store.append(HistoryEntry(sessionId: "s1", ts: 1, text: "first", cwd: "/a"))
        try store.append(HistoryEntry(sessionId: "s2", ts: 2, text: "second", cwd: "/b"))
        try store.append(HistoryEntry(sessionId: "s3", ts: 3, text: "third", cwd: "/c"))

        let entries = try store.loadAll()
        #expect(entries.count == 3)
        #expect(entries[0].text == "first")
        #expect(entries[2].text == "third")
    }

    @Test("directory has 0700 permissions")
    func directoryPermissions() throws {
        let store = HistoryStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try store.append(HistoryEntry(sessionId: "x", ts: 1, text: "test", cwd: "/"))
        let attrs = try FileManager.default.attributesOfItem(atPath: testDir.path)
        let perms = attrs[.posixPermissions] as? Int
        #expect(perms == 0o700)
    }

    @Test("history file has 0600 permissions")
    func filePermissions() throws {
        let store = HistoryStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try store.append(HistoryEntry(sessionId: "x", ts: 1, text: "test", cwd: "/"))
        let historyURL = testDir.appendingPathComponent("history.jsonl")
        let attrs = try FileManager.default.attributesOfItem(atPath: historyURL.path)
        let perms = attrs[.posixPermissions] as? Int
        #expect(perms == 0o600)
    }

    @Test("existing file retains 0600 permissions after append")
    func existingFilePermissions() throws {
        let store = HistoryStore(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try store.append(HistoryEntry(sessionId: "x", ts: 1, text: "first", cwd: "/"))
        try store.append(HistoryEntry(sessionId: "y", ts: 2, text: "second", cwd: "/"))
        let historyURL = testDir.appendingPathComponent("history.jsonl")
        let attrs = try FileManager.default.attributesOfItem(atPath: historyURL.path)
        let perms = attrs[.posixPermissions] as? Int
        #expect(perms == 0o600)
    }

    @Test("append creates directory if not exists")
    func createsDirectory() throws {
        let nested = testDir.appendingPathComponent("nested")
        let store = HistoryStore(baseDirectory: nested)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try store.append(HistoryEntry(sessionId: "x", ts: 1, text: "test", cwd: "/"))
        #expect(FileManager.default.fileExists(atPath: nested.path))
    }
}
