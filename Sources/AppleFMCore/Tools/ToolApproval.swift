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

    public init(mode: ToolApprovalMode = .ask) {
        self.mode = mode
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
            // stdin が tty でない場合（パイプ入力）は拒否
            guard isatty(fileno(Darwin.stdin)) != 0 else {
                FileHandle.standardError.write(
                    Data("[applefm] Tool '\(toolName)' requires approval. Use --tool-approval auto for non-interactive use.\n".utf8)
                )
                return false
            }
            FileHandle.standardError.write(
                Data("[applefm] Tool '\(toolName)' wants to execute:\n  \(description)\nAllow? [y/N] ".utf8)
            )
            guard let input = Swift.readLine()?.lowercased() else {
                return false
            }
            return input == "y" || input == "yes"
        }
    }
}
