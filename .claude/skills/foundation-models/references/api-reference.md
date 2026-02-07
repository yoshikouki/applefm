# Foundation Models API Reference

## SystemLanguageModel

オンデバイス LLM へのエントリポイント。

```swift
class SystemLanguageModel
```

### Properties

| Property | Type | Description |
|---|---|---|
| `.default` | `SystemLanguageModel` | ベースモデル (汎用) |
| `isAvailable` | `Bool` | モデルが利用可能か |
| `availability` | `Availability` | 詳細な可用性状態 |
| `supportedLanguages` | `Set<Locale.Language>` | サポート言語一覧 |

### Initializers

```swift
// Use case 指定
init(useCase: SystemLanguageModel.UseCase, guardrails: SystemLanguageModel.Guardrails)

// Adapter 指定 (カスタムモデル)
init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
```

### Availability Enum

```swift
@frozen enum Availability {
    case available
    case notAvailable(reason: ...)
}
```

### UseCase

```swift
struct UseCase {
    static let general: SystemLanguageModel.UseCase
}
```

### Guardrails

```swift
struct Guardrails {
    static let `default`: SystemLanguageModel.Guardrails
    static let permissiveContentTransformations: SystemLanguageModel.Guardrails
}
```

### Adapter

カスタムアダプターでモデルを特化。Python でのトレーニングが必要。

```swift
struct Adapter {
    init(fileURL: URL) throws
    init(name: String) throws  // BackgroundAssets 経由
    static func compatibleAdapterIdentifiers(name: String) -> [String]
    static func isCompatible(_ assetPack: AssetPack) -> Bool
}
```

> Adapter は OS/モデルバージョンごとに再トレーニングが必要。ストレージ消費大。

### Methods

```swift
func supportsLocale(_ locale: Locale = .current) -> Bool
```

---

## LanguageModelSession

モデルとの対話を管理するセッション。`Observable` に準拠。

```swift
final class LanguageModelSession
```

### Initializers

```swift
// 基本
convenience init(
    model: SystemLanguageModel = .default,
    tools: [any Tool] = [],
    instructions: Instructions? = nil
)

// String ベース instructions
convenience init(
    model: SystemLanguageModel = .default,
    tools: [any Tool] = [],
    instructions: String? = nil
)

// InstructionsBuilder
convenience init(
    model: SystemLanguageModel = .default,
    tools: [any Tool] = [],
    @InstructionsBuilder instructions: () throws -> Instructions
) rethrows

// Transcript から復元
convenience init(
    model: SystemLanguageModel = .default,
    tools: [any Tool] = [],
    transcript: Transcript
)
```

### Generation Methods

```swift
// String レスポンス
func respond(to: String, options: GenerationOptions?) async throws
    -> LanguageModelSession.Response<String>

// Guided Generation (型指定)
func respond<T: Generable>(
    to: String,
    generating: T.Type,
    includeSchemaInPrompt: Bool,
    options: GenerationOptions?
) async throws -> LanguageModelSession.Response<T>

// Dynamic Schema
func respond(
    to: String,
    schema: GenerationSchema,
    options: GenerationOptions?
) async throws -> LanguageModelSession.Response<GeneratedContent>

// Streaming
func streamResponse(to: String) -> ResponseStream<String>
func streamResponse<T: Generable>(to: String, generating: T.Type) -> ResponseStream<T>
```

### Properties

| Property | Type | Description |
|---|---|---|
| `transcript` | `Transcript` | セッション履歴 |
| `isResponding` | `Bool` | リクエスト処理中か |

### Methods

```swift
// プリウォーム (レイテンシ削減)
func prewarm(promptPrefix: Prompt?)
```

### GenerationError

```swift
enum GenerationError {
    case exceededContextWindowSize(Context)
    case guardrailViolation(Context)
    case refusal(Refusal, Context)
    case unsupportedLanguageOrLocale(Context)
}
```

`Refusal` は `explanationStream` プロパティで拒否理由をストリームとして取得可能。

---

## ResponseStream

ストリーミングレスポンス。`AsyncSequence` に準拠。

```swift
struct ResponseStream<Content>
```

### Methods

```swift
// ストリーム完了後のレスポンスを取得
func collect() async throws -> sending LanguageModelSession.Response<Content>
```

`for try await partial in stream` で `PartiallyGenerated` (全プロパティ optional) を逐次受信。

---

## Instructions

モデルへの指示を定義。

```swift
struct Instructions
```

- `String` から暗黙変換可能
- `@InstructionsBuilder` で構築可能
- `InstructionsRepresentable` プロトコルに準拠

---

## Transcript

セッションの履歴。`Identifiable` なエントリのリスト。

```swift
struct Transcript
```

### Entry Types

```swift
case instructions(Transcript.Instructions)
case prompt(Transcript.Prompt)
case toolCall(Transcript.ToolCall)
case toolOutput(Transcript.ToolOutput)
case response(Transcript.Response)
```

SwiftUI の `List` で表示可能。
