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

SwiftUI の `List` で表示可能。`Codable` に準拠しており JSON シリアライズで永続化可能。

---

## Prompt

プロンプトを構築するための型。

```swift
struct Prompt
```

- `String` から暗黙変換可能（`ExpressibleByStringLiteral`）
- `@PromptBuilder` で構築可能

### PromptBuilder

```swift
@resultBuilder
struct PromptBuilder {
    static func buildBlock(_ components: PromptRepresentable...) -> Prompt
    static func buildOptional(_ component: PromptRepresentable?) -> Prompt
    static func buildEither(first: PromptRepresentable) -> Prompt
    static func buildEither(second: PromptRepresentable) -> Prompt
}
```

---

## GenerationOptions

生成パラメータの制御。

```swift
struct GenerationOptions
```

### Initializer

```swift
init(
    sampling: GenerationOptions.SamplingMode? = nil,
    temperature: Double? = nil,
    maximumResponseTokens: Int? = nil
)
```

### Properties

| Property | Type | Description |
|---|---|---|
| `maximumResponseTokens` | `Int?` | レスポンスの最大トークン数 |
| `temperature` | `Double?` | 温度パラメータ (0.0-1.0)。高いと多様性が増す |
| `sampling` | `SamplingMode?` | サンプリング戦略 |

### SamplingMode

```swift
struct GenerationOptions.SamplingMode {
    static var greedy: SamplingMode  // 最も確率の高いトークンを常に選択
    static func random(probabilityThreshold: Double, seed: UInt64?) -> SamplingMode
    static func random(top: Int, seed: UInt64?) -> SamplingMode
}
```

---

## GeneratedContent

Dynamic Schema 使用時のレスポンス型。

```swift
struct GeneratedContent
```

### Methods

```swift
// プロパティ名で値を取得
func value<T>(_: T.Type, forProperty property: String) throws -> T
```

---

## Availability 詳細

### UnavailableReason

```swift
enum UnavailableReason {
    case deviceNotEligible      // デバイスが対応していない
    case modelNotReady          // モデルがまだダウンロード/準備されていない
    case appleIntelligenceNotEnabled  // Apple Intelligence が無効
}
```

---

## GenerationError 詳細

```swift
enum GenerationError {
    case exceededContextWindowSize(Context)
    case guardrailViolation(Context)
    case rateLimited(Context)             // レート制限に到達
    case refusal(Refusal, Context)
    case unsupportedLanguageOrLocale(Context)
}
```

`Refusal` は `explanationStream` プロパティで拒否理由をストリームとして取得可能。

---

## respond() / streamResponse() 全オーバーロード一覧

### respond() — 同期（await）

```swift
// 1. String レスポンス
func respond(
    to prompt: String,
    options: GenerationOptions? = nil
) async throws -> LanguageModelSession.Response<String>

// 2. Prompt レスポンス
func respond(
    to prompt: Prompt,
    options: GenerationOptions? = nil
) async throws -> LanguageModelSession.Response<String>

// 3. Guided Generation (型指定)
func respond<T: Generable>(
    to prompt: String,
    generating: T.Type,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions? = nil
) async throws -> LanguageModelSession.Response<T>

// 4. Guided Generation (Prompt)
func respond<T: Generable>(
    to prompt: Prompt,
    generating: T.Type,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions? = nil
) async throws -> LanguageModelSession.Response<T>

// 5. Dynamic Schema
func respond(
    to prompt: String,
    schema: GenerationSchema,
    options: GenerationOptions? = nil
) async throws -> LanguageModelSession.Response<GeneratedContent>

// 6. Dynamic Schema (Prompt)
func respond(
    to prompt: Prompt,
    schema: GenerationSchema,
    options: GenerationOptions? = nil
) async throws -> LanguageModelSession.Response<GeneratedContent>

// 7. Instructions のみ（promptなし）
func respond(
    options: GenerationOptions? = nil
) async throws -> LanguageModelSession.Response<String>
```

### streamResponse() — ストリーミング

```swift
// 1. String ストリーミング
func streamResponse(
    to prompt: String,
    options: GenerationOptions? = nil
) -> ResponseStream<String>

// 2. Prompt ストリーミング
func streamResponse(
    to prompt: Prompt,
    options: GenerationOptions? = nil
) -> ResponseStream<String>

// 3. Guided Generation ストリーミング
func streamResponse<T: Generable>(
    to prompt: String,
    generating: T.Type,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions? = nil
) -> ResponseStream<T>

// 4. Guided Generation ストリーミング (Prompt)
func streamResponse<T: Generable>(
    to prompt: Prompt,
    generating: T.Type,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions? = nil
) -> ResponseStream<T>

// 5. Dynamic Schema ストリーミング
func streamResponse(
    to prompt: String,
    schema: GenerationSchema,
    options: GenerationOptions? = nil
) -> ResponseStream<GeneratedContent>

// 6. Dynamic Schema ストリーミング (Prompt)
func streamResponse(
    to prompt: Prompt,
    schema: GenerationSchema,
    options: GenerationOptions? = nil
) -> ResponseStream<GeneratedContent>
```
