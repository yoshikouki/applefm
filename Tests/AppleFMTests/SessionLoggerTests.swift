import Testing
import Foundation
@testable import AppleFMCore

@Suite("SessionLogger Tests")
struct SessionLoggerTests {
    let testDir: URL

    init() throws {
        testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("applefm-tests-\(UUID().uuidString)")
    }

    @Test("log writes entry to file")
    func logWritesEntry() throws {
        let logger = SessionLogger(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        let entry = SessionLogEntry(ts: 1000, type: "user", text: "Hello")
        try logger.log(entry, sessionId: "test-session")

        let files = try logger.findLogFiles(sessionId: "test-session")
        #expect(files.count == 1)
        #expect(files[0].lastPathComponent.hasPrefix("log-"))
        #expect(files[0].lastPathComponent.hasSuffix("-test-session.jsonl"))
    }

    @Test("log file name includes date")
    func logFileNameFormat() throws {
        let logger = SessionLogger(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try logger.log(SessionLogEntry(type: "user", text: "test"), sessionId: "my-session")

        let files = try logger.findLogFiles(sessionId: "my-session")
        #expect(files.count == 1)
        // Format: log-yyyy-MM-dd-my-session.jsonl
        let name = files[0].lastPathComponent
        let dateRegex = try Regex("^log-\\d{4}-\\d{2}-\\d{2}-my-session\\.jsonl$")
        #expect(name.contains(dateRegex))
    }

    @Test("deleteLog removes log files")
    func deleteLog() throws {
        let logger = SessionLogger(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try logger.log(SessionLogEntry(type: "user", text: "test"), sessionId: "del-session")
        #expect(try logger.findLogFiles(sessionId: "del-session").count == 1)

        try logger.deleteLog(sessionId: "del-session")
        #expect(try logger.findLogFiles(sessionId: "del-session").count == 0)
    }

    @Test("findLogFiles returns empty for nonexistent session")
    func findLogFilesEmpty() throws {
        let logger = SessionLogger(baseDirectory: testDir)
        let files = try logger.findLogFiles(sessionId: "nonexistent")
        #expect(files.isEmpty)
    }

    @Test("multiple entries appended to same file")
    func multipleEntries() throws {
        let logger = SessionLogger(baseDirectory: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        try logger.log(SessionLogEntry(type: "user", text: "hello"), sessionId: "multi")
        try logger.log(SessionLogEntry(type: "assistant", text: "hi"), sessionId: "multi")

        let files = try logger.findLogFiles(sessionId: "multi")
        #expect(files.count == 1)

        let content = try String(contentsOf: files[0], encoding: .utf8)
        let lines = content.split(separator: "\n")
        #expect(lines.count == 2)
    }
}
