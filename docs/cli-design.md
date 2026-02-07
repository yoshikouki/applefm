# applefm CLI Design

## コマンドツリー

```
applefm
├── model
│   ├── availability        → SystemLanguageModel.default.availability
│   ├── languages           → .supportedLanguages
│   ├── supports-locale     → .supportsLocale(_:)
│   └── prewarm             → session.prewarm(promptPrefix:)
├── session
│   ├── new <name>          → LanguageModelSession(model:tools:instructions:)
│   ├── respond <name>      → session.respond(to:options:) / streamResponse
│   ├── generate <name>     → session.respond(to:schema:options:)
│   ├── transcript <name>   → session.transcript
│   ├── list                → ~/.applefm/sessions/ 列挙
│   └── delete <name>       → セッション削除
├── respond                 → ワンショット (一時 session)
└── generate                → ワンショット guided generation
```

## API マッピング

| CLI コマンド | Foundation Models API | 説明 |
|---|---|---|
| `model availability` | `SystemLanguageModel.default.availability` | モデルの可用性を確認 |
| `model languages` | `SystemLanguageModel.default.supportedLanguages` | サポート言語一覧 |
| `model supports-locale` | `SystemLanguageModel.default.supportsLocale(_:)` | ロケールサポート確認 |
| `model prewarm` | `session.prewarm(promptPrefix:)` | モデルのプリウォーム |
| `session new` | `LanguageModelSession(model:tools:instructions:)` | 新規セッション作成 |
| `session respond` | `session.respond(to:options:)` / `streamResponse(to:)` | セッション内で生成 |
| `session generate` | `session.respond(to:schema:options:)` | 構造化出力生成 |
| `session transcript` | `session.transcript` | 履歴表示 |
| `session list` | ファイルシステム | セッション一覧 |
| `session delete` | ファイルシステム | セッション削除 |
| `respond` | 一時 `LanguageModelSession` + `respond` | ワンショット生成 |
| `generate` | 一時 `LanguageModelSession` + `respond(schema:)` | ワンショット構造化出力 |

## 共通オプション

| オプション | 型 | デフォルト | 説明 |
|---|---|---|---|
| `--format` | `text` / `json` | `text` | 出力フォーマット |
| `--max-tokens` | `Int` | なし | 最大レスポンストークン数 |
| `--temperature` | `Double` | なし | 温度パラメータ (0.0-2.0) |
| `--sampling` | `greedy` | なし | サンプリングモード (greedy) |
| `--sampling-threshold` | `Double` | なし | ランダムサンプリング確率閾値 (0.0-1.0) |
| `--sampling-top` | `Int` | なし | ランダムサンプリング top-k |
| `--sampling-seed` | `UInt64` | なし | ランダムサンプリングシード |
| `--guardrails` | `default` / `permissive` | `default` | ガードレールレベル |
| `--adapter` | `String` (パス) | なし | カスタムアダプターファイルパス |
| `--stream` | `Bool` | `false` | ストリーミング出力 |
| `--tool` | `String` (反復可) | なし | 有効にするビルトインツール |

### ビルトインツール

| ツール名 | 説明 |
|---|---|
| `shell` | シェルコマンドを実行して結果を返す |
| `file-read` | ファイルの内容を読み取る |

使用例:
```bash
applefm respond "List Swift files in current dir" --tool shell
applefm respond "Summarize README.md" --tool shell --tool file-read
```

## エラーハンドリング

| GenerationError | 終了コード | ユーザーメッセージ |
|---|---|---|
| `exceededContextWindowSize` | 2 | "Context window exceeded. Start a new session or reduce prompt size." |
| `guardrailViolation` | 3 | "Request was blocked by safety guardrails." |
| `rateLimited` | 4 | "Rate limited. Please wait and try again." |
| `refusal` | 5 | "Model refused the request." |
| `unsupportedLanguageOrLocale` | 6 | "Unsupported language or locale." |
| `assetsUnavailable` | 7 | "Model assets are unavailable." |
| `unsupportedGuide` | 8 | "Unsupported generation guide." |
| `decodingFailure` | 9 | "Failed to decode generated content." |
| モデル未利用可能 | 10 | "Foundation Models is not available." + UnavailableReason |
| `concurrentRequests` | 11 | "Concurrent requests are not supported." |
| その他 | 1 | エラーメッセージそのまま |

## データ永続化

### ディレクトリ構造

```
~/.applefm/
└── sessions/
    ├── <name>.json          # SessionMetadata (名前、作成日時、instructions)
    └── <name>.transcript    # Transcript の JSON エンコード
```

### SessionMetadata

```json
{
  "name": "my-session",
  "createdAt": "2025-06-01T12:00:00Z",
  "instructions": "You are a helpful assistant."
}
```

### セッション復元フロー

1. `~/.applefm/sessions/<name>.transcript` を読み込み
2. `Transcript` を JSON デコード
3. `LanguageModelSession(model:tools:transcript:)` で復元
4. 新しいレスポンス後、transcript を再保存

## プロンプト入力

優先順位:
1. コマンドライン引数 (`applefm session respond test "Hello"`)
2. ファイル (`--file prompt.txt`)
3. 標準入力 (`echo "Hello" | applefm session respond test`)

## Foundation Models API カバレッジ

### CLI でカバー済み

- `SystemLanguageModel` — availability, languages, supportsLocale
- `SystemLanguageModel(useCase:guardrails:)` — `--guardrails` オプション
- `SystemLanguageModel(adapter:guardrails:)` — `--adapter` オプション
- `LanguageModelSession` — 作成、復元 (transcript)、instructions
- `session.respond(to:options:)` — テキスト生成
- `session.respond(to:schema:options:)` — Dynamic Schema 構造化出力
- `session.streamResponse(to:options:)` — ストリーミング
- `session.prewarm(promptPrefix:)` — プリウォーム
- `GenerationOptions` — maximumResponseTokens, temperature, sampling (greedy / random)
- `Tool` protocol — ShellTool, FileReadTool ビルトインツール
- `Transcript` — 表示、永続化、復元
- `GenerationError` — 全ケースのエラーハンドリング

### CLI の性質上対象外

- `@Generable` macro — コンパイル時型定義。CLI では Dynamic Schema で代替
- `@Guide` macro — @Generable と同様
- `@PromptBuilder` / `@InstructionsBuilder` — String で十分
- `isResponding` — CLI は単発実行のため不要
- `Generable` 型の静的 Guided Generation — コンパイル時型が必要。Dynamic Schema で代替
- `includeSchemaInPrompt` — 静的 Generable 専用パラメータ
