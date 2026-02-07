import ArgumentParser
import Darwin
import Foundation

/// ツール承認モード
public enum ToolApprovalMode: String, CaseIterable, Sendable {
    case ask
    case auto
}

extension ToolApprovalMode: ExpressibleByArgument {}

/// ツール呼び出し時のユーザー承認を管理する
public struct ToolApproval: Sendable {
    public let mode: ToolApprovalMode
    let isInteractive: @Sendable () -> Bool
    let readInput: @Sendable () -> String?
    let writeStderr: @Sendable (String) -> Void

    public init(
        mode: ToolApprovalMode = .ask,
        isInteractive: @escaping @Sendable () -> Bool = { isatty(fileno(Darwin.stdin)) != 0 },
        readInput: @escaping @Sendable () -> String? = { Swift.readLine()?.lowercased() },
        writeStderr: @escaping @Sendable (String) -> Void = { message in
            FileHandle.standardError.write(Data(message.utf8))
        }
    ) {
        self.mode = mode
        self.isInteractive = isInteractive
        self.readInput = readInput
        self.writeStderr = writeStderr
    }

    /// ツール実行前にユーザーの承認を求める
    /// - Parameters:
    ///   - toolName: ツール名
    ///   - description: 実行内容の説明
    /// - Returns: 承認された場合 true
    public func requestApproval(toolName: String, description: String) -> Bool {
        switch mode {
        case .auto:
            return true
        case .ask:
            guard isInteractive() else {
                writeStderr("[applefm] Tool '\(toolName)' requires approval. Use --tool-approval auto for non-interactive use.\n")
                return false
            }
            writeStderr("[applefm] Tool '\(toolName)' wants to execute:\n  \(description)\nAllow? [y/N] ")
            guard let input = readInput() else {
                return false
            }
            return input == "y" || input == "yes"
        }
    }
}
