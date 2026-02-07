# Tool Calling

モデルの機能を拡張し、外部コードとの連携を実現する。

## Tool Protocol

```swift
protocol Tool<Arguments, Output>: Sendable {
    associatedtype Arguments: ConvertibleFromGeneratedContent
    associatedtype Output: PromptRepresentable

    var name: String { get }
    var description: String { get }

    func call(arguments: Arguments) async throws -> Output
}
```

## Basic Tool Implementation

```swift
struct SearchDatabase: Tool {
    let name = "searchDatabase"
    let description = "Search the recipe database"

    @Generable
    struct Arguments {
        @Guide(description: "Search query")
        let query: String
        @Guide(description: "Max results", .range(1...10))
        let limit: Int
    }

    func call(arguments: Arguments) async throws -> String {
        // Perform search
        return "Found: ..."
    }
}
```

## Tool with Complex Output

Output は `PromptRepresentable` に準拠する型。`String`, `[String]`, `Generable` 型が使用可能。

```swift
struct GetContacts: Tool {
    let name = "getContacts"
    let description = "Get contacts from address book"

    @Generable
    struct Arguments {
        @Guide(description: "Number of contacts", .range(1...10))
        let count: Int
    }

    func call(arguments: Arguments) async throws -> [String] {
        // Fetch contacts
        return ["Alice", "Bob"]
    }
}
```

## Session with Tools

```swift
let session = LanguageModelSession(
    tools: [SearchDatabase(), GetContacts()],
    instructions: """
        You help people find recipes and share them with friends.
        Use searchDatabase to find recipes.
        Use getContacts to find people to share with.
        """
)

let response = try await session.respond(to: "Find a bread recipe and share it with Alice")
```

## Stateful Tools

Tool のライフサイクルは開発者が制御する。呼び出し間で状態を保持可能。

```swift
class ConversationLogger: Tool {
    let name = "logConversation"
    let description = "Log a conversation entry"

    @Generable
    struct Arguments {
        @Guide(description: "The message to log")
        let message: String
    }

    private var logs: [String] = []

    func call(arguments: Arguments) async throws -> String {
        logs.append(arguments.message)
        return "Logged: \(arguments.message)"
    }
}
```

## Transcript Inspection

ツール呼び出しの履歴は Transcript から確認可能。

```swift
for entry in session.transcript {
    switch entry {
    case .toolCall(let call):
        print("Tool: \(call.toolName), Args: \(call.arguments)")
    case .toolOutput(let output):
        print("Output: \(output)")
    default:
        break
    }
}
```

## Tool Calling Best Practices

- **ツール数**: 3-5 個に制限。多いとコンテキストを消費。
- **description**: 短いフレーズ。長い説明は避ける。
- **@Guide description**: 短いフレーズ。
- **不要なツールは除外**: タスクに必要なツールだけを渡す。
- **必須ツールは先に実行**: モデルが常に必要とする情報は、ツールを直接実行して結果をプロンプトに含める。
- **コンテキスト超過時の分割**: ツール引数の生成と結果の処理を別セッションに分ける。

```swift
// Anti-pattern: Always-needed data via tool
// Better: Run tool first, include in prompt
let data = try await myTool.call(arguments: .init(query: "needed"))
let session = LanguageModelSession(instructions: "Context: \(data)")
let response = try await session.respond(to: prompt)
```

## Concurrent Tool Execution

ツールは `Sendable` 必須。フレームワークが並列実行する場合がある。一方のツール出力が他方の入力に必要な場合は逐次実行される。
