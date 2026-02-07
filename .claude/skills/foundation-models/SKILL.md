---
name: foundation-models
description: Apple Foundation Models framework の API リファレンスと実装パターンを提供する。オンデバイス LLM を使った機能を実装するときに使う。
---

# Foundation Models

Apple のオンデバイス大規模言語モデル (LLM) を利用するためのフレームワーク。macOS/iOS 上で動作する `SystemLanguageModel` を通じて、テキスト生成・構造化出力・ツール呼び出しを行う。

## Framework Import

```swift
import FoundationModels
```

## Core Types

| Type | Role |
|---|---|
| `SystemLanguageModel` | オンデバイス LLM へのアクセス |
| `LanguageModelSession` | モデルとの対話セッション (`Observable`) |
| `Instructions` | モデルの振る舞いを制御する指示 |
| `Transcript` | セッション履歴 (prompt/response/tool call) |
| `Tool` protocol | モデルが呼び出せるカスタムツール |
| `@Generable` macro | 構造化出力用の型定義 |
| `@Guide` macro | Generable プロパティの制約 |
| `ResponseStream` | ストリーミングレスポンス |

## Quick Patterns

### Model Availability Check

```swift
let model = SystemLanguageModel.default
guard model.isAvailable else { return }
// Or detailed check:
// model.availability -> .available / .notAvailable(reason)
```

### Basic Session

```swift
let session = LanguageModelSession(instructions: "You are a helpful assistant.")
let response = try await session.respond(to: "Hello")
print(response.content) // String
```

### Guided Generation

```swift
@Generable(description: "A task for the agent")
struct AgentTask {
    @Guide(description: "Action to take", .anyOf(["search", "summarize", "reply"]))
    var action: String
    @Guide(description: "Brief reasoning for the action")
    var reasoning: String
}

let response = try await session.respond(to: prompt, generating: AgentTask.self)
// response.content is AgentTask
```

### Tool Calling

```swift
struct SearchTool: Tool {
    let name = "search"
    let description = "Search for information"

    @Generable
    struct Arguments {
        @Guide(description: "The search query")
        let query: String
    }

    func call(arguments: Arguments) async throws -> String {
        // Perform search, return result
    }
}

let session = LanguageModelSession(
    tools: [SearchTool()],
    instructions: "Use the search tool when needed."
)
let response = try await session.respond(to: "Find info about Swift concurrency")
```

### Streaming

```swift
let stream = session.streamResponse(to: prompt, generating: AgentTask.self)
for try await partial in stream {
    // partial is AgentTask.PartiallyGenerated (all properties optional)
}
let final = try await stream.collect() // LanguageModelSession.Response<AgentTask>
```

### Multi-turn Conversation

```swift
// Reuse the same session for context retention
let session = LanguageModelSession(instructions: "You are a coding assistant.")
let r1 = try await session.respond(to: "What is Swift?")
let r2 = try await session.respond(to: "Show me an example.")
// r2 retains context from r1
```

### Transcript Persistence

```swift
// Save transcript
let transcript = session.transcript
// Restore session from transcript
let restoredSession = LanguageModelSession(tools: [...], transcript: transcript)
```

## Key Constraints

- **Context window**: 有限。超過時は `exceededContextWindowSize` エラー。タスク分割で対処。
- **Single request**: セッションは同時に1リクエストのみ (`isResponding` で確認)。
- **Tools**: 3-5 個が推奨上限。description は短く。
- **Guardrails**: デフォルトで安全性チェックあり。`permissiveContentTransformations` で緩和可能。
- **Languages**: `model.supportsLocale()` で確認。`Instructions` でロケール指定。

## References

- API 型・メソッド詳細: `references/api-reference.md`
- Tool calling パターン: `references/tool-calling.md`
- Guided Generation 詳細: `references/guided-generation.md`
- ベストプラクティス: `references/best-practices.md`
- Navigator 全展開カバレッジ: `references/navigator-coverage.md`
- Essentials 記事まとめ: `references/essentials.md`
- Prompting 記事まとめ: `references/prompting.md`
- Tool API 詳細: `references/tool-api.md`
- Tool メンバー一覧: `references/tool-members.md`
- SystemLanguageModel 詳細: `references/systemlanguagemodel.md`
- SystemLanguageModel メンバー一覧: `references/systemlanguagemodel-members.md`
- LanguageModelSession メンバー一覧: `references/languagemodelsession-members.md`
- Transcript メンバー一覧: `references/transcript-members.md`
- カスタム Adapter: `references/adapter.md`
- Content Tagging: `references/content-tagging.md`
