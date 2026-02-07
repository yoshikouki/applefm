import FoundationModels

public enum ToolRegistry {
    public static let allToolNames = ["shell", "file-read"]

    public static func resolve(names: [String]) throws -> [any Tool] {
        try names.map { name in
            switch name {
            case "shell":
                return ShellTool()
            case "file-read", "file_read":
                return FileReadTool()
            default:
                throw AppError.invalidInput("Unknown tool: '\(name)'. Available tools: \(allToolNames.joined(separator: ", "))")
            }
        }
    }
}
