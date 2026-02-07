import Foundation

/// セッション詳細ログエントリ
public struct SessionLogEntry: Codable, Sendable {
    public let ts: Int
    public let type: String
    public let text: String?
    public let tokens: TokenCount?
    public let tool: String?
    public let command: String?
    public let path: String?
    public let approved: Bool?
    public let exitCode: Int?
    public let sensitive: Bool?
    public let code: String?
    public let message: String?

    public struct TokenCount: Codable, Sendable {
        public let input: Int?
        public let output: Int?

        public init(input: Int? = nil, output: Int? = nil) {
            self.input = input
            self.output = output
        }
    }

    public init(
        ts: Int? = nil,
        type: String,
        text: String? = nil,
        tokens: TokenCount? = nil,
        tool: String? = nil,
        command: String? = nil,
        path: String? = nil,
        approved: Bool? = nil,
        exitCode: Int? = nil,
        sensitive: Bool? = nil,
        code: String? = nil,
        message: String? = nil
    ) {
        self.ts = ts ?? Int(Date().timeIntervalSince1970)
        self.type = type
        self.text = text
        self.tokens = tokens
        self.tool = tool
        self.command = command
        self.path = path
        self.approved = approved
        self.exitCode = exitCode
        self.sensitive = sensitive
        self.code = code
        self.message = message
    }
}

/// ~/.applefm/sessions/log-<date>-<sessionId>.jsonl を管理
public struct SessionLogger: Sendable {
    public let baseDirectory: URL

    public init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            self.baseDirectory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".applefm")
                .appendingPathComponent("sessions")
        }
    }

    public func log(_ entry: SessionLogEntry, sessionId: String) throws {
        guard !sessionId.isEmpty,
              !sessionId.contains("/"),
              !sessionId.contains(".."),
              sessionId.count <= 200 else {
            throw AppError.invalidInput("Invalid session ID for logging.")
        }
        try ensureDirectoryExists()
        let url = logFileURL(sessionId: sessionId)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(entry)
        guard var line = String(data: data, encoding: .utf8) else { return }
        line += "\n"

        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
        } else {
            try Data(line.utf8).write(to: url, options: .atomic)
        }
        try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    public func deleteLog(sessionId: String) throws {
        let fm = FileManager.default
        for url in try findLogFiles(sessionId: sessionId) {
            try fm.removeItem(at: url)
        }
    }

    public func findLogFiles(sessionId: String) throws -> [URL] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: baseDirectory.path) else { return [] }
        let files = try fm.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil)
        let suffix = "-\(sessionId).jsonl"
        return files.filter { $0.lastPathComponent.hasPrefix("log-") && $0.lastPathComponent.hasSuffix(suffix) }
    }

    // MARK: - Private

    private func logFileURL(sessionId: String) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        return baseDirectory.appendingPathComponent("log-\(dateStr)-\(sessionId).jsonl")
    }

    private func ensureDirectoryExists() throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: baseDirectory.path) {
            try fm.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        }
    }
}
