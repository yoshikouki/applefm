# applefm CLI Design

## コマンドツリー

```
applefm
├── model
│   ├── availability        → SystemLanguageModel.default.availability
│   ├── languages           → .supportedLanguages
│   └── supports-locale     → .supportsLocale(_:)
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
| `--stream` | `Bool` | `false` | ストリーミング出力 |

## エラーハンドリング

| GenerationError | 終了コード | ユーザーメッセージ |
|---|---|---|
| `exceededContextWindowSize` | 2 | "Context window exceeded. Start a new session or reduce prompt size." |
| `guardrailViolation` | 3 | "Request was blocked by safety guardrails." |
| `rateLimited` | 4 | "Rate limited. Please wait and try again." |
| `refusal` | 5 | "Model refused the request: {reason}" |
| `unsupportedLanguageOrLocale` | 6 | "Unsupported language or locale." |
| モデル未利用可能 | 10 | "Foundation Models is not available." + UnavailableReason |
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
  "instructions": "You are a helpful assistant.",
  "model": "default"
}
```

### セッション復元フロー

1. `~/.applefm/sessions/<name>.transcript` を読み込み
2. `Transcript` を JSON デコード
3. `LanguageModelSession(transcript: transcript)` で復元
4. 新しいレスポンス後、transcript を再保存

## プロンプト入力

優先順位:
1. コマンドライン引数 (`applefm session respond test "Hello"`)
2. ファイル (`--file prompt.txt`)
3. 標準入力 (`echo "Hello" | applefm session respond test`)
