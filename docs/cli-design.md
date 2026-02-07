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
│   └── delete <name>       → セッション削除 (--force で確認スキップ)
├── respond                 → ワンショット (一時 session) [デフォルトサブコマンド]
└── generate                → ワンショット guided generation
```

> **設計メモ**: `model prewarm` は `model` サブグループに配置している。`prewarm` は内部的に `LanguageModelSession` を使用するが、ユーザーの視点ではモデルの準備操作であるため、`model` グループに属する方が直感的。

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
| `--instructions` | `String` | なし | システムインストラクション (ワンショットコマンド) |
| `--stream` | `Bool` | `false` | ストリーミング出力 |
| `--schema` | `String` (パス) | なし | JSON スキーマファイル (generate コマンド) |
| `--tool` | `String` (反復可) | なし | 有効にするビルトインツール |
| `--tool-approval` | `ask` / `auto` | `ask` | ツール承認モード |
| `--force` | `Bool` | `false` | 確認プロンプトをスキップ (session delete) |

**制約**: `--stream` と `--format json` の同時使用は不可。`validate()` でバリデーションエラーを返す。

### オプショングループ（実装上の共通化）

共通オプションは `ParsableArguments` 準拠の3グループに分離されている:
- `GenerationOptionGroup`: maxTokens, temperature, sampling 系6オプション
- `ModelOptionGroup`: guardrails, adapter
- `ToolOptionGroup`: tool, toolApproval

> **注**: `OutputOptionGroup` は v1.0.0 で削除。`format` オプションのデフォルト値がコマンドによって異なるため（respond 系は `.text`、generate 系は `.json`）、共通グループ化せず各コマンドで直接定義。

### ツール承認

`--tool-approval` はツール呼び出し時のユーザー確認モードを制御する:
- `ask`（デフォルト）: 各ツール呼び出し前に stderr で確認プロンプトを表示し、y/N の入力を待つ
- `auto`: 確認なしで即時実行。非インタラクティブ環境や信頼できるパイプライン用

パイプ入力（stdin が tty でない）の場合、`ask` モードではツール実行を拒否し、`--tool-approval auto` の使用を促すメッセージを表示する。

### ビルトインツール

| ツール名 | 説明 | 安全機能 |
|---|---|---|
| `shell` | シェルコマンドを実行して結果を返す | 60秒タイムアウト |
| `file-read` | ファイルの内容を読み取る | センシティブパス警告 |

使用例:
```bash
applefm respond "List Swift files in current dir" --tool shell
applefm respond "Summarize README.md" --tool shell --tool file-read
```

## エラーハンドリング

| GenerationError | 終了コード | ユーザーメッセージ |
|---|---|---|
| `exceededContextWindowSize` | 2 | "Context window exceeded. Start a new session or reduce prompt size." |
| `guardrailViolation` | 3 | "Request was blocked by safety guardrails. Try rephrasing or use --guardrails permissive." |
| `rateLimited` | 4 | "Rate limited. Please wait and try again." |
| `refusal` | 5 | "Model refused the request." |
| `unsupportedLanguageOrLocale` | 6 | "Unsupported language or locale. Use 'applefm model languages' to see supported languages." |
| `assetsUnavailable` | 7 | "Model assets are unavailable. Check that Apple Intelligence is enabled in System Settings." |
| `unsupportedGuide` | 8 | "Unsupported generation guide." |
| `decodingFailure` | 9 | "Failed to decode generated content. Check your schema file for correctness." |
| モデル未利用可能 | 10 | "Foundation Models is not available." + UnavailableReason |
| `concurrentRequests` | 11 | "Concurrent requests are not supported." |
| その他 | 1 | エラーメッセージそのまま |

## データ永続化

### ディレクトリ構造

```
~/.applefm/
└── sessions/
    ├── <name>.json          # SessionMetadata (名前、作成日時、instructions、guardrails、adapter、tools)
    └── <name>.transcript    # Transcript の JSON エンコード
```

### セッション名バリデーション

セッション名は英数字・ハイフン・アンダースコアのみ許可（1-100文字）。パストラバーサル防止のため、`../` や `/` を含む名前は拒否される。

### SessionMetadata

```json
{
  "name": "my-session",
  "createdAt": "2025-06-01T12:00:00Z",
  "instructions": "You are a helpful assistant.",
  "guardrails": "default",
  "adapterPath": null,
  "tools": ["shell", "file-read"]
}
```

### セッション復元フロー

1. `~/.applefm/sessions/<name>.json` からメタデータを読み込み（guardrails, adapter, tools のフォールバック値を取得）
2. `~/.applefm/sessions/<name>.transcript` を読み込み
3. `Transcript` を JSON デコード
4. transcript が空の場合: `LanguageModelSession(model:tools:instructions:)` で instructions 付きセッションを作成
5. transcript が空でない場合: `LanguageModelSession(model:tools:transcript:)` で復元
6. コマンドラインで明示されたオプションはメタデータの値より優先
7. 新しいレスポンス後、transcript を再保存（`defer` で生成エラー時も部分保存）

## プロンプト入力

優先順位:
1. コマンドライン引数 (`applefm session respond test "Hello"`)
2. ファイル (`--file prompt.txt`)
3. 標準入力 (`echo "Hello" | applefm session respond test`)

入力サイズ上限: 10MB（ファイル・stdin ともに）

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

## 設計判断

### コマンド間の共通ロジック

`RespondCommand` と `SessionRespondCommand`（および `GenerateCommand` と `SessionGenerateCommand`）は類似のロジックを持つ。これは意図的な設計判断である:

- **薄いラッパー原則**: 各コマンドは Foundation Models API の薄いラッパーであり、コマンド自体のロジックは最小限に留める。共通化のためにコマンド間の抽象レイヤーを追加すると、この原則に反する
- **共通化はユーティリティレベルに留める**: `ResponseStreamer`、`OutputFormatter`、`PromptInput`、`OptionGroups` などの共通ユーティリティで重複を最小化。コマンドの `run()` メソッド内のオーケストレーションは各コマンドが責任を持つ
- **独立した進化**: ワンショットコマンドとセッションコマンドは今後異なる方向に進化する可能性がある（例: セッション側のみにツール永続化、ワンショット側のみにバッチ実行など）。過度な共通化は将来の柔軟性を損なう
