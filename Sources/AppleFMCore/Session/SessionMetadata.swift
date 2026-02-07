import Foundation

/// セッションのメタデータ
public struct SessionMetadata: Codable, Sendable {
    public let name: String
    public let createdAt: Date
    public var instructions: String?

    public init(name: String, instructions: String? = nil) {
        self.name = name
        self.createdAt = Date()
        self.instructions = instructions
    }
}
