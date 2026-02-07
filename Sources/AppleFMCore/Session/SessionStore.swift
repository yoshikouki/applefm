import Foundation
import FoundationModels

/// ~/.applefm/sessions/ にセッションを永続化する
public struct SessionStore: Sendable {
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

    // MARK: - Validation

    /// セッション名を検証する（英数字・ハイフン・アンダースコアのみ、1-100文字）
    public static func validateSessionName(_ name: String) throws {
        guard !name.isEmpty, name.count <= 100 else {
            throw AppError.invalidInput("Session name must be 1-100 characters.")
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard name.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw AppError.invalidInput("Session name may only contain alphanumeric characters, hyphens, and underscores.")
        }
    }

    // MARK: - Metadata

    public func saveMetadata(_ metadata: SessionMetadata) throws {
        try Self.validateSessionName(metadata.name)
        try ensureDirectoryExists()
        let url = metadataURL(for: metadata.name)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)
        try data.write(to: url, options: .atomic)
    }

    public func loadMetadata(name: String) throws -> SessionMetadata {
        try Self.validateSessionName(name)
        let url = metadataURL(for: name)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AppError.sessionNotFound(name)
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SessionMetadata.self, from: data)
    }

    // MARK: - Transcript

    public func saveTranscript(_ transcript: Transcript, name: String) throws {
        try Self.validateSessionName(name)
        try ensureDirectoryExists()
        let url = transcriptURL(for: name)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(transcript)
        try data.write(to: url, options: .atomic)
    }

    public func loadTranscript(name: String) throws -> Transcript {
        try Self.validateSessionName(name)
        let url = transcriptURL(for: name)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AppError.sessionNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Transcript.self, from: data)
    }

    // MARK: - List / Delete

    public func listSessions() throws -> [SessionMetadata] {
        let dir = baseDirectory
        guard FileManager.default.fileExists(atPath: dir.path) else {
            return []
        }
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        let metadataFiles = files.filter { $0.pathExtension == "json" }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return metadataFiles.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(SessionMetadata.self, from: data)
        }.sorted { $0.createdAt < $1.createdAt }
    }

    public func deleteSession(name: String) throws {
        try Self.validateSessionName(name)
        let meta = metadataURL(for: name)
        let transcript = transcriptURL(for: name)
        let fm = FileManager.default
        if fm.fileExists(atPath: meta.path) {
            try fm.removeItem(at: meta)
        }
        if fm.fileExists(atPath: transcript.path) {
            try fm.removeItem(at: transcript)
        }
    }

    public func sessionExists(name: String) -> Bool {
        guard (try? Self.validateSessionName(name)) != nil else {
            return false
        }
        return FileManager.default.fileExists(atPath: metadataURL(for: name).path)
    }

    // MARK: - Private

    private func metadataURL(for name: String) -> URL {
        baseDirectory.appendingPathComponent("\(name).json")
    }

    private func transcriptURL(for name: String) -> URL {
        baseDirectory.appendingPathComponent("\(name).transcript")
    }

    private func ensureDirectoryExists() throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: baseDirectory.path) {
            try fm.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
    }
}
