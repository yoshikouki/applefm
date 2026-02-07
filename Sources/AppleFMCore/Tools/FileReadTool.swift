import Foundation
import FoundationModels

struct FileReadTool: Tool {
    let name = "file_read"
    let description = "Read the contents of a file at the given path"
    let approval: ToolApproval

    private static let sensitivePaths = [".ssh/", ".gnupg/", ".env", ".netrc", ".aws/", ".kube/config"]

    init(approval: ToolApproval = ToolApproval()) {
        self.approval = approval
    }

    @Generable(description: "Arguments for file reading")
    struct Arguments {
        @Guide(description: "Absolute or relative path to the file to read")
        var path: String
    }

    func call(arguments: Arguments) async throws -> String {
        guard approval.requestApproval(toolName: name, description: "Read file: \(arguments.path)") else {
            return "Tool execution denied by user."
        }

        if Self.sensitivePaths.contains(where: { arguments.path.contains($0) }) {
            FileHandle.standardError.write(
                Data("[applefm] Warning: reading potentially sensitive path: \(arguments.path)\n".utf8)
            )
        }

        let url = URL(fileURLWithPath: arguments.path)
        return try String(contentsOf: url, encoding: .utf8)
    }
}
