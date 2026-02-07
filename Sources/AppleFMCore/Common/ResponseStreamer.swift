import Darwin
import FoundationModels

/// ストリーミングレスポンスを差分出力する共通ユーティリティ
///
/// String.count + dropFirst() は O(n) だが、モデルの生成速度がボトルネックであり
/// 実用上のパフォーマンス問題にはならない。バッファ管理の複雑化を避け現状維持とする。
public struct ResponseStreamer {
    @discardableResult
    public static func stream(_ responseStream: LanguageModelSession.ResponseStream<String>) async throws -> String {
        var previousLength = 0
        var finalText = ""
        for try await partial in responseStream {
            let current = partial.content
            if current.count > previousLength {
                print(String(current.dropFirst(previousLength)), terminator: "")
                fflush(stdout)
                previousLength = current.count
            }
            finalText = partial.content
        }
        print()
        return finalText
    }
}
