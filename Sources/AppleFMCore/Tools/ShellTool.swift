import Foundation
import FoundationModels

struct ShellTool: Tool {
    let name = "shell"
    let description = "Execute a shell command and return its output"
    let approval: ToolApproval

    init(approval: ToolApproval = ToolApproval()) {
        self.approval = approval
    }

    @Generable(description: "Arguments for shell command execution")
    struct Arguments {
        @Guide(description: "The shell command to execute")
        var command: String
    }

    func call(arguments: Arguments) async throws -> String {
        guard approval.requestApproval(toolName: name, description: arguments.command) else {
            return "Tool execution denied by user."
        }

        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", arguments.command]
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        try process.run()
        process.waitUntilExit()
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        if process.terminationStatus != 0 {
            return "Exit code: \(process.terminationStatus)\nStdout:\n\(stdout)\nStderr:\n\(stderr)"
        }
        return stdout
    }
}
