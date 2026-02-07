import FoundationModels

public enum ToolRegistry {
    public static let allToolNames = ["shell", "file-read"]

    public static func resolve(names: [String], approval: ToolApproval = ToolApproval()) throws -> [any Tool] {
        try names.map { name in
            switch name {
            case "shell":
                return ShellTool(approval: approval)
            case "file-read", "file_read":
                return FileReadTool(approval: approval)
            default:
                throw AppError.invalidInput("Unknown tool: '\(name)'. Available tools: \(allToolNames.joined(separator: ", "))")
            }
        }
    }
}
