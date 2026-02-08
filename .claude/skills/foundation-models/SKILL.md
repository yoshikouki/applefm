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
- **Tools**: 3-5 個が推奨上限。description は短く。ツール呼び出し時のレイテンシは 20-34倍増加。
- **Guardrails**: デフォルトで安全性チェックあり。`permissiveContentTransformations` で緩和可能。**日本語プロンプトでは permissive 推奨** (文化的トピックのブロックが過度)。
- **Languages**: 15言語対応 (da, de, en, es, fr, it, ja, ko, nb, nl, pt, sv, tr, vi, zh)。英語が最高品質 (A)、日本語は B- (事実の正確性に課題)。
- **Temperature**: 0.0 で完全に決定論的。2.0 でも品質崩壊しない (Apple FM 固有特性)。
- **Guided Generation**: フラット〜1段ネストは 100% 精度。配列内オブジェクト 5+プロパティで構造崩壊。Enum 遵守率 100%。
- **Performance**: 生成速度 ~35 トークン/秒。Cold start 5-15秒、Warm 0.3-2秒。レイテンシのばらつき大 (3-10倍)。

## Model Characteristics (実機テスト結果)

モデルの性能特性、パラメータ推奨値、既知の制限事項: `references/model-characteristics.md`

個別調査レポート (生データ):
- テキスト生成品質: `references/research/01-text-generation.md`
- パラメータ感度: `references/research/02-parameter-sensitivity.md`
- 構造化出力精度: `references/research/03-structured-output.md`
- ツール呼び出し精度: `references/research/04-tool-calling.md`
- マルチターン会話: `references/research/05-multi-turn.md`
- 多言語対応: `references/research/06-multilingual.md`
- パフォーマンス測定: `references/research/07-performance.md`
- FileReadTool 修正検証: `references/research/08-bugfix-verification.md`
- ガードレール修正検証: `references/research/09-guardrails-verification.md`
- コードレビューシナリオ: `references/research/10-code-review-scenario.md`
- ドキュメント生成シナリオ: `references/research/11-doc-generation-scenario.md`
- データ変換・抽出シナリオ: `references/research/12-data-extraction-scenario.md`

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
- **モデル特性ガイド (実機テスト)**: `references/model-characteristics.md`
