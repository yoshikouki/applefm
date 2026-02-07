import Foundation

/// セッションのメタデータ
public struct SessionMetadata: Codable, Sendable {
    public let name: String
    public let createdAt: Date
    public var instructions: String?
    public var guardrails: String?
    public var adapterPath: String?
    public var tools: [String]?

    public init(
        name: String,
        instructions: String? = nil,
        guardrails: String? = nil,
        adapterPath: String? = nil,
        tools: [String]? = nil
    ) {
        self.name = name
        self.createdAt = Date()
        self.instructions = instructions
        self.guardrails = guardrails
        self.adapterPath = adapterPath
        self.tools = tools
    }
}
