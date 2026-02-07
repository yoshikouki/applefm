import Foundation

/// プロンプト入力の解決（引数 > ファイル > stdin）
public struct PromptInput: Sendable {

    /// プロンプトテキストを解決する
    /// - Parameters:
    ///   - argument: コマンドライン引数で渡されたテキスト
    ///   - filePath: --file で指定されたパス
    /// - Returns: 解決されたプロンプト文字列
    public static func resolve(argument: String?, filePath: String?) throws -> String {
        // 1. コマンドライン引数
        if let argument, !argument.isEmpty {
            return argument
        }

        // 2. ファイル
        if let filePath {
            return try readFile(at: filePath)
        }

        // 3. 標準入力
        if let stdin = readStdin() {
            return stdin
        }

        throw AppError.invalidInput("No prompt provided. Pass as argument, --file, or pipe via stdin.")
    }

    static func readFile(at path: String) throws -> String {
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw AppError.fileError("Cannot read file: \(path) (\(error.localizedDescription))")
        }
    }

    static func readStdin() -> String? {
        guard !isatty(fileno(stdin)).boolValue else {
            return nil
        }
        var lines: [String] = []
        while let line = readLine(strippingNewline: false) {
            lines.append(line)
        }
        let result = lines.joined()
        return result.isEmpty ? nil : result
    }
}

extension Int32 {
    fileprivate var boolValue: Bool { self != 0 }
}
