import Foundation

/// コマンド履歴エントリ
public struct HistoryEntry: Codable, Sendable {
    public let sessionId: String
    public let ts: Int
    public let text: String
    public let cwd: String

    public init(sessionId: String, ts: Int? = nil, text: String, cwd: String? = nil) {
        self.sessionId = sessionId
        self.ts = ts ?? Int(Date().timeIntervalSince1970)
        self.text = text
        self.cwd = cwd ?? FileManager.default.currentDirectoryPath
    }
}

/// ~/.applefm/history.jsonl への追記を担当
public struct HistoryStore: Sendable {
    public let baseDirectory: URL

    public init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            self.baseDirectory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".applefm")
        }
    }

    private var historyURL: URL {
        baseDirectory.appendingPathComponent("history.jsonl")
    }

    public func append(_ entry: HistoryEntry) throws {
        try ensureDirectoryExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(entry)
        guard var line = String(data: data, encoding: .utf8) else { return }
        line += "\n"

        let fm = FileManager.default
        if fm.fileExists(atPath: historyURL.path) {
            let handle = try FileHandle(forWritingTo: historyURL)
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
        } else {
            try Data(line.utf8).write(to: historyURL, options: .atomic)
            // Set file permissions to 0600
            try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: historyURL.path)
        }
    }

    /// テスト用: 全エントリを読み込む
    public func loadAll() throws -> [HistoryEntry] {
        let data = try Data(contentsOf: historyURL)
        guard let content = String(data: data, encoding: .utf8) else { return [] }
        let decoder = JSONDecoder()
        return content.split(separator: "\n").compactMap { line in
            try? decoder.decode(HistoryEntry.self, from: Data(line.utf8))
        }
    }

    private func ensureDirectoryExists() throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: baseDirectory.path) {
            try fm.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        }
    }
}
