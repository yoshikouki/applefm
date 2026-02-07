import Darwin
import FoundationModels

/// ストリーミングレスポンスを差分出力する共通ユーティリティ
public struct ResponseStreamer {
    public static func stream(_ responseStream: LanguageModelSession.ResponseStream<String>) async throws {
        var previousLength = 0
        for try await partial in responseStream {
            let current = partial.content
            if current.count > previousLength {
                print(String(current.dropFirst(previousLength)), terminator: "")
                fflush(stdout)
                previousLength = current.count
            }
        }
        print()
    }
}
