import Foundation
import FoundationModels

struct ShellTool: Tool {
    let name = "shell"
    let description = "Execute a shell command and return its output"
    let approval: ToolApproval
    let timeoutSeconds: Int

    init(approval: ToolApproval = ToolApproval(), timeoutSeconds: Int = 60) {
        self.approval = approval
        self.timeoutSeconds = timeoutSeconds
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

        let timedOut = await withTimeout(seconds: timeoutSeconds) {
            process.waitUntilExit()
        }
        if timedOut {
            process.terminate()
            return "Error: Command timed out after \(timeoutSeconds) seconds."
        }

        // Read pipe data after process exits
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        if process.terminationStatus != 0 {
            return "Exit code: \(process.terminationStatus)\nStdout:\n\(stdout)\nStderr:\n\(stderr)"
        }
        return stdout
    }

    /// Runs a blocking closure on a background thread with a timeout.
    /// Returns true if the operation timed out.
    private func withTimeout(seconds: Int, operation: @escaping @Sendable () -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            let completed = LockedFlag()

            DispatchQueue.global().async {
                operation()
                if completed.setIfUnset() {
                    continuation.resume(returning: false)
                }
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(seconds)) {
                if completed.setIfUnset() {
                    continuation.resume(returning: true)
                }
            }
        }
    }
}

/// Thread-safe one-shot flag to prevent double-resuming continuations
private final class LockedFlag: @unchecked Sendable {
    private var _completed = false
    private let lock = NSLock()

    /// Atomically sets the flag. Returns true if this call was the first to set it.
    func setIfUnset() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if _completed { return false }
        _completed = true
        return true
    }
}
