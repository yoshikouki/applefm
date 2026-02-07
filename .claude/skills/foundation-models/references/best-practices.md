# Best Practices

## Context Window Management

オンデバイスモデルのコンテキストウィンドウは有限。

### 超過時のエラー

```swift
do {
    let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.exceededContextWindowSize(let context) {
    // タスクを分割して再試行
}
```

### 長文タスクの分割パターン

```swift
// 1. 記事をセクションに分割
let sections = splitArticle(article)
// 2. 各セクションを新しいセッションで要約
var summaries: [String] = []
for section in sections {
    let session = LanguageModelSession()
    let response = try await session.respond(to: "Summarize: \(section)")
    summaries.append(response.content)
}
// 3. 要約を統合
let finalSession = LanguageModelSession()
let finalSummary = try await finalSession.respond(
    to: "Combine these summaries: \(summaries.joined(separator: "\n"))"
)
```

### ツール呼び出しの分割

```swift
// Session 1: ツール引数を生成
let argsSession = LanguageModelSession()
let args = try await argsSession.respond(to: query, generating: ToolArgs.self)

// 通常のコードでツールを実行
let toolResult = try await myTool.execute(args.content)

// Session 2: ツール結果を処理
let processSession = LanguageModelSession()
let response = try await processSession.respond(
    to: "Process this result: \(toolResult)"
)
```

### Prewarm

```swift
let session = LanguageModelSession(instructions: "...")
// プロンプトのプレフィックスをキャッシュしてレイテンシ削減
session.prewarm(promptPrefix: "Given the following context...")
```

## Safety & Guardrails

### Default Guardrails

デフォルトでモデルの入出力に安全性チェックが適用される。

```swift
do {
    let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.guardrailViolation(let context) {
    // センシティブなコンテンツが検出された
} catch LanguageModelSession.GenerationError.refusal(let refusal, let context) {
    // モデルがリクエストを拒否した
    for try await explanation in refusal.explanationStream {
        print(explanation) // 拒否理由
    }
}
```

### Permissive Mode

センシティブなソース素材を扱う場合 (チャットアプリのタグ付け等)。

```swift
let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
let session = LanguageModelSession(model: model)
```

- String 生成時のみ有効。Guided Generation では通常のガードレールが適用される。
- permissive モードでもモデル自体の安全レイヤーは残る。

## Language & Locale

### ロケール確認

```swift
if SystemLanguageModel.default.supportsLocale() {
    // 現在のロケールがサポートされている
}

// 特定のロケール
if SystemLanguageModel.default.supportsLocale(Locale(identifier: "ja_JP")) {
    // 日本語がサポートされている
}
```

### Instructions でロケール指定

```swift
func localeInstructions(for locale: Locale = .current) -> String {
    if Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
        return ""
    } else {
        return "The person's locale is \(locale.identifier)."
    }
}

let session = LanguageModelSession(instructions: """
    \(localeInstructions())
    You MUST respond in Japanese.
    """)
```

- "The person's locale is ..." フレーズは英語で記述（トレーニングに由来）
- "MUST", "ALWAYS" で強調すると遵守率が上がる

### 未サポート言語のハンドリング

```swift
do {
    let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(let context) {
    // 未サポート言語を通知
}
```

## Session Management

### Single Request 制約

```swift
// Session は同時に 1 リクエストのみ
guard !session.isResponding else {
    // 前のリクエストが完了するまで待つ
    return
}
let response = try await session.respond(to: prompt)
```

### Instruments でのプロファイリング

1. Xcode > Product > Profile
2. Blank template を選択
3. "+ Instrument" > Foundation Models instrument を追加
4. File > Record Trace

Activity Monitor と Power Profiler も併用してリソース消費を確認。

## Agent Architecture Tips

### Session per Task

タスクごとに新しいセッションを作成し、コンテキスト超過を防ぐ。

```swift
func executeAgentStep(task: AgentTask) async throws -> String {
    let session = LanguageModelSession(
        tools: task.requiredTools,
        instructions: task.instructions
    )
    let response = try await session.respond(to: task.prompt)
    return response.content
}
```

### Transcript for Continuity

セッション間の連続性が必要な場合は Transcript を引き継ぐ。

```swift
var currentTranscript: Transcript?

func continueConversation(prompt: String) async throws -> String {
    let session: LanguageModelSession
    if let transcript = currentTranscript {
        session = LanguageModelSession(tools: myTools, transcript: transcript)
    } else {
        session = LanguageModelSession(tools: myTools, instructions: myInstructions)
    }
    let response = try await session.respond(to: prompt)
    currentTranscript = session.transcript
    return response.content
}
```

### Structured Agent Loop

```swift
@Generable
enum AgentAction {
    case search(query: String)
    case respond(message: String)
    case done(result: String)
}

func runAgent(goal: String) async throws -> String {
    let session = LanguageModelSession(
        tools: [SearchTool()],
        instructions: "You are an agent. Decide what action to take next."
    )

    var context = goal
    while true {
        let action = try await session.respond(
            to: context,
            generating: AgentAction.self
        )
        switch action.content {
        case .search(let query):
            let result = try await performSearch(query)
            context = "Search result: \(result). What next?"
        case .respond(let message):
            context = "You said: \(message). Continue?"
        case .done(let result):
            return result
        }
    }
}
```
