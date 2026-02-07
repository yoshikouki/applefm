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

    // MARK: - Metadata

    public func saveMetadata(_ metadata: SessionMetadata) throws {
        try ensureDirectoryExists()
        let url = metadataURL(for: metadata.name)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)
        try data.write(to: url)
    }

    public func loadMetadata(name: String) throws -> SessionMetadata {
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
        try ensureDirectoryExists()
        let url = transcriptURL(for: name)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(transcript)
        try data.write(to: url)
    }

    public func loadTranscript(name: String) throws -> Transcript {
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
        FileManager.default.fileExists(atPath: metadataURL(for: name).path)
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
