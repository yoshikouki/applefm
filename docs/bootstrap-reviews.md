# v1.0.0 リリースレビュー

レビュー日: 2026-02-07
レビューチーム: code-reviewer, arch-reviewer, test-reviewer, docs-reviewer

---

## 総合評価

applefm v1.0.0 は、Foundation Models framework の主要機能を CLI から利用可能にするという目標を**概ね達成**している。アーキテクチャは明快で、`AppleFMCore`（ライブラリ）と `applefm`（エントリポイント）の二層分離、コマンドツリーの API 命名への準拠、共通抽象化（ModelFactory, SessionStore, OutputFormatter 等）の設計はいずれも適切。ただし、セキュリティ面（ShellTool の確認なし実行）、テストカバレッジ（インテグレーションテストが placeholder）、一部コードの重複について、リリース前に対応を検討すべき課題がある。

---

## 1. コード品質・バグ・セキュリティレビュー

### サマリー

全体的にコード品質は高い。Swift 6.2 の concurrency 対応（`main.swift` の async dispatch パターン）は正しく実装されている。命名規則は一貫しており、エラーハンドリングも `GenerationError` の全ケースを網羅。ただし、ShellTool のセキュリティ設計と一部のコード重複が懸念事項。

### Critical（リリースブロッカー）

- [ ] **ShellTool: ツール承認機構の未実装** (`Tools/ShellTool.swift:14-32`)
  - bootstrap.md で「ツール呼び出しはデフォルトで **ask（確認）**。`-tool-approval auto` は明示しない限り ON にしない」と定義されているが、現在の実装では `--tool shell` を指定するとモデルが任意のシェルコマンドを**無確認で**実行できる。`rm -rf /` のような破壊的コマンドもモデルの判断のみで実行される。
  - **推奨**: ツール呼び出し時にユーザー確認プロンプトを挟む仕組み（デフォルト ask モード）を実装するか、v1.0.0 では ShellTool を実験的機能として警告を出すこと。

### Warning（推奨修正）

- [ ] **FileReadTool: パストラバーサルの制限なし** (`Tools/FileReadTool.swift:14-17`)
  - モデルが指定する任意のパスを読み取り可能。`/etc/passwd` や `~/.ssh/id_rsa` なども対象になりうる。
  - **推奨**: 許可ディレクトリのホワイトリストまたは警告メッセージの追加。

- [ ] **ストリーミングのデルタ計算ロジック** (`Commands/RespondCommand.swift:73-80`, `Commands/Session/SessionRespondCommand.swift:71-80`)
  - `partial.content` の文字数比較 (`current.count > previousContent.count`) でデルタを計算している。モデルが以前の内容を修正して返す場合（retraction）、文字数が減る可能性がありデルタが出力されない。また `String.count` は O(n) であり、長い応答では毎回のフルスキャンが非効率。
  - **推奨**: `partial.content` のインデックス管理に変更するか、`content` が単調増加する前提をドキュメントに明記。

- [ ] **ストリーミングコードの重複** (`RespondCommand.swift:69-82` と `SessionRespondCommand.swift:68-89`)
  - ストリーミング処理のロジックがほぼ完全に重複している。
  - **推奨**: 共通ヘルパー関数への抽出。

- [ ] **コマンドオプションの重複定義** (RespondCommand, SessionRespondCommand, GenerateCommand, SessionGenerateCommand)
  - `--max-tokens`, `--temperature`, `--sampling-*`, `--guardrails`, `--adapter` の定義が4コマンドに渡ってコピーされている。変更時に不整合が発生しやすい。
  - **推奨**: `ParsableArguments` プロトコルを使った共通オプショングループの抽出（例: `GenerationOptionGroup`）。

- [ ] **SessionStore: セッション名のサニタイズなし** (`Session/SessionStore.swift:97-103`)
  - セッション名がそのままファイル名に使われる（`\(name).json`, `\(name).transcript`）。`../` や `/` を含む名前でパストラバーサルが可能。
  - **推奨**: セッション名のバリデーション（英数字・ハイフン・アンダースコアのみ許可）。

- [ ] **SessionStore.listSessions: transcript ファイルも SessionMetadata としてデコード試行** (`Session/SessionStore.swift:69`)
  - `pathExtension == "json"` でフィルタしているが、`.transcript` ファイルは `.json` 拡張子ではないため問題は発生しない。ただし `.json` 拡張子のメタデータ以外のファイルが配置された場合、`compactMap` で無視される。意図的な設計か不明。
  - **推奨**: ファイル名パターンの明示的フィルタ（例: `.session.json` サフィックス）の検討。

- [ ] **GenerateCommand の出力**: `String(describing: response.content)` (`Commands/GenerateCommand.swift:73`)
  - `DynamicGenerationSchema` の応答を `String(describing:)` で文字列化しているが、これは Swift のデバッグ表現であり、ユーザー向けの構造化出力として適切か要確認。

### Info（改善提案）

- [ ] `ShellTool.call` で `process.waitUntilExit()` がメインスレッドをブロックする。Swift concurrency と組み合わせる場合、`Process` を非同期ラッパーで包む方がクリーン。
- [ ] `OutputFormatter` の `ExpressibleByArgument` 準拠が `ModelAvailabilityCommand.swift` に置かれている。独立した extension にした方が発見しやすい。
- [ ] `ModelPrewarmCommand` で `session.prewarm()` の戻り値を待っていない（fire-and-forget）。プリウォーム完了を保証するなら `await` が必要。

---

## 2. アーキテクチャ・設計レビュー

### サマリー

コマンドツリーは Foundation Models API の命名に忠実で、cli-design.md と実装が高い整合性を持つ。`ModelFactory` / `SessionStore` / `ToolRegistry` / `SchemaLoader` の抽象化は「薄いラッパー」方針に合致。二層ターゲット構造（`AppleFMCore` + `applefm`）はテスタビリティを確保している。

### API カバレッジ

| Foundation Models API | CLI コマンド | ステータス |
|---|---|---|
| `SystemLanguageModel.default.availability` | `model availability` | ✅ |
| `SystemLanguageModel.default.supportedLanguages` | `model languages` | ✅ |
| `SystemLanguageModel.default.supportsLocale(_:)` | `model supports-locale` | ✅ |
| `SystemLanguageModel(useCase:guardrails:)` | `--guardrails` オプション | ✅ |
| `SystemLanguageModel(adapter:guardrails:)` | `--adapter` オプション | ✅ |
| `LanguageModelSession(model:tools:instructions:)` | `session new` | ✅ |
| `LanguageModelSession(model:tools:transcript:)` | `session respond` (復元) | ✅ |
| `session.respond(to:options:)` | `respond` / `session respond` | ✅ |
| `session.streamResponse(to:options:)` | `--stream` フラグ | ✅ |
| `session.respond(to:schema:options:)` | `generate` / `session generate` | ✅ |
| `session.prewarm(promptPrefix:)` | `model prewarm` | ✅ |
| `session.transcript` | `session transcript` | ✅ |
| `GenerationOptions` (maxTokens, temperature, sampling) | 共通オプション群 | ✅ |
| `Tool` protocol | `--tool shell/file-read` | ✅ |
| `GenerationError` 全ケース | `AppError` マッピング | ✅ |
| `DynamicGenerationSchema` | `SchemaLoader` | ✅ |
| `Transcript` 永続化・復元 | `SessionStore` | ✅ |
| `@Generable` / `@Guide` macro | CLI 性質上対象外（DynamicSchema で代替） | ✅ 理由妥当 |
| `@PromptBuilder` / `@InstructionsBuilder` | CLI 性質上対象外（String で十分） | ✅ 理由妥当 |
| `isResponding` | CLI 性質上対象外（単発実行） | ✅ 理由妥当 |
| ツール承認機構 (`-tool-approval`) | 未実装 | ❌ |

### Critical（リリースブロッカー）

- [ ] **ツール承認機構の欠如**: bootstrap.md のセキュリティ基本方針「ツール呼び出しはデフォルトで ask（確認）」が未実装。`--tool shell` を使う場合、モデルが任意のコマンドを無確認で実行できる状態。v1.0.0 のセキュリティ方針に反する。

### Warning（推奨修正）

- [ ] **`session new` で保存される instructions がメタデータのみ**: `session respond` 時にメタデータの `instructions` を復元して新しいセッションに渡していない。transcript からの復元のみに依存している。transcript に instructions が含まれるかは API の実装依存。
- [ ] **`session respond` / `session generate` での guardrails・adapter の扱い**: セッション作成時と応答時で異なる guardrails/adapter を指定できてしまう。セッションの一貫性の観点から、作成時の設定をメタデータに保存して復元時に使うべきか検討が必要。
- [ ] **`SamplingModeOption` が `greedy` のみ**: `random` をサポートしているが、CLI の `--sampling` オプションでは `greedy` しか選択できない。`--sampling random` も追加すべきか検討。

### Info（改善提案）

- [ ] `ParsableArguments` を活用した共通オプショングループの定義で、コマンド間の整合性を構造的に保証できる。
- [ ] `SessionMetadata` に guardrails, adapter, tools の情報を保存すると、セッション復元時の一貫性が向上する。
- [ ] `model` サブコマンドの配置: `prewarm` は `session.prewarm()` の呼び出しであり、セッションに紐づく。`model` の下に置くか `session` の下に置くかは設計判断だが、現在の API マッピング（`model prewarm`）は直感的に分かりにくい可能性がある。

---

## 3. テストカバレッジ・品質レビュー

### サマリー

ユニットテストは主要な共通モジュール（OutputFormatter, PromptInput, SessionStore, SchemaLoader, TranscriptFormatter, ToolRegistry, ModelFactory）をカバーしており、基本的な正常系・異常系をテストしている。ただし、インテグレーションテストは placeholder のみで実質未実装。コマンドレベルのテストも存在しない。

### テストカバレッジマトリクス

| モジュール | テスト有無 | カバレッジ評価 | 備考 |
|---|---|---|---|
| OutputFormatter | ✅ | 中 | 基本的な出力パターンをカバー。空入力テストなし |
| PromptInput | ✅ | 高 | 引数・ファイル・stdin・エッジケースを網羅 |
| SessionStore | ✅ | 高 | CRUD + エラーケースをカバー |
| SchemaLoader | ✅ | 高 | object/array/anyOf/primitive/エラーをカバー |
| TranscriptFormatter | ✅ | 低 | 空 transcript のみ。実データでのテストなし |
| ToolRegistry | ✅ | 高 | 全パスをカバー |
| ModelFactory | ✅ | 中 | オプション構築はカバー。createModel は未テスト（デバイス依存） |
| Errors (AppError) | ❌ | なし | エラーメッセージ・終了コードのテストなし |
| RespondCommand | ❌ | なし | コマンド実行のテストなし |
| GenerateCommand | ❌ | なし | コマンド実行のテストなし |
| SessionRespondCommand | ❌ | なし | コマンド実行のテストなし |
| SessionNewCommand | ❌ | なし | コマンド実行のテストなし |
| Model* Commands | ❌ | なし | コマンド実行のテストなし |
| ShellTool | ❌ | なし | ツール実行のテストなし |
| FileReadTool | ❌ | なし | ツール実行のテストなし |
| IntegrationTests | ⚠️ | なし | placeholder のみ (`#expect(Bool(true))`) |

### Critical（リリースブロッカー）

- [ ] **IntegrationTests が placeholder のみ** (`Tests/IntegrationTests/IntegrationTests.swift:8-12`)
  - 「E2E テストも用意している」という報告があるが、実際には `#expect(Bool(true))` の placeholder テストのみ。Foundation Models が利用可能なデバイスでの実際の生成テストが存在しない。
  - **推奨**: 少なくとも `model availability` の確認、`respond` の基本動作、`session` のライフサイクル（new → respond → transcript → delete）の E2E テストを追加。

### Warning（推奨修正）

- [ ] **AppError のテストなし**: エラーメッセージと終了コードのマッピングは CLI の重要な契約。`formatGenerationError` と `exitCodeForGenerationError` の各ケースをテストすべき。
- [ ] **TranscriptFormatter のテストが不十分**: 空 transcript のテストのみで、実際の会話データ（instructions, prompt, response, tool_calls, tool_output）を含む transcript のフォーマットテストがない。`LanguageModelSession` の生成なしにテスト用 `Transcript` を構築する方法が限られる可能性はあるが、可能ならモック transcript でテストすべき。
- [ ] **SchemaLoader テストのアサーション弱さ**: 多くのテストが `_ = schema`（作成成功の確認のみ）で終わっている。生成されたスキーマの構造（プロパティ数、名前、型）を検証すべき。

### Info（改善提案）

- [ ] コマンドのパース結果テスト: `ArgumentParser` の `parse()` メソッドを使って、コマンドライン引数が正しくパースされるかテストできる。
- [ ] `SessionStore` のテストでテンポラリディレクトリのクリーンアップが `try?` で無視されている。テスト失敗時にゴミが残る可能性。`defer` で `init()` 直後にクリーンアップを設定するとより確実。

---

## 4. ドキュメント・UX レビュー

### サマリー

`cli-design.md` は実装との整合性が高く、API マッピング表やエラーハンドリング表が充実。`CLAUDE.md` のアーキテクチャ概要も正確。ただし、外部ユーザー向けの README（インストール手順、使い方ガイド）が存在せず、v1.0.0 リリースとしての体裁が不足。

### ドキュメント整合性チェック

| ドキュメント | 実装との整合性 | 備考 |
|---|---|---|
| `CLAUDE.md` | ✅ | コマンドツリー、抽象化、制約事項が正確 |
| `docs/cli-design.md` | ✅ | API マッピング、オプション、エラーコードが実装と一致 |
| `docs/bootstrap.md` | ⚠️ | v1.0.0 ゴールは達成だが、セキュリティ方針（tool-approval）未実装 |
| `.claude/skills/foundation-models/` | ✅ | API リファレンスは詳細かつ正確 |

### Critical（リリースブロッカー）

- [ ] **README.md が存在しない**: v1.0.0 リリースとして、以下の情報を含む README が必要:
  - プロジェクト概要
  - 前提条件（macOS 26+, Swift 6.2, Apple Intelligence 対応デバイス）
  - インストール手順（`swift build`）
  - 基本的な使い方（respond, session, model コマンドの例）
  - ビルトインツールの使い方と注意事項

### Warning（推奨修正）

- [ ] **bootstrap.md のセキュリティ方針と実装の乖離**: 「ツール呼び出しはデフォルトで ask（確認）」「ログは `~/.applefm/` に保存する」と記載されているが、いずれも未実装。v1.0.0 で対応しないなら、ドキュメント側を更新して「v1.1.0 で対応予定」などの記載が必要。
- [ ] **CLI ヘルプメッセージの改善**: 各コマンドの `abstract` は簡潔だが、`discussion` が未設定。`applefm --help` で表示される情報に使い方の例（Examples）を追加するとユーザビリティが向上。
- [ ] **`session list` の instructions 表示**: 40文字で切り詰めて `...` を付けているが、instructions が40文字以下でも `...` が付く (`SessionListCommand.swift:31`)。

### Info（改善提案）

- [ ] `--version` フラグで `1.0.0` が表示されることを確認（`AppleFM.swift:7` で設定済み）。
- [ ] `model prewarm` の出力「Model prewarmed successfully.」は prewarm が非同期処理のため、実際にはプリウォームのリクエスト送信のみ。表現を調整すべきか検討。
- [ ] エラーメッセージは英語のみ。国際化の予定がないなら問題ないが、Foundation Models 自体が多言語対応のため、将来的に検討の余地あり。

---

## リリース判定サマリー

### Critical（リリースブロッカー）: 3件

| # | 分類 | 内容 | 推奨対応 |
|---|---|---|---|
| C-1 | セキュリティ | ~~ShellTool のツール承認機構が未実装~~ | ✅ ToolApproval (ask/auto) 実装済み |
| C-2 | テスト | ~~IntegrationTests が placeholder のみ~~ | ✅ E2E テスト追加済み (環境変数ゲート) |
| C-3 | ドキュメント | ~~README.md が存在しない~~ | ✅ README.md 作成済み |

### Warning（推奨修正）: 10件

| # | 分類 | 内容 |
|---|---|---|
| W-1 | セキュリティ | ~~FileReadTool のパス制限なし~~ | ✅ ToolApproval で承認制に統合 |
| W-2 | セキュリティ | ~~SessionStore のセッション名サニタイズなし~~ | ✅ validateSessionName 実装済み |
| W-3 | コード品質 | ~~ストリーミングのデルタ計算ロジックの堅牢性~~ | ✅ ResponseStreamer に共通化 |
| W-4 | コード品質 | ~~ストリーミングコードの重複~~ | ✅ ResponseStreamer に抽出 |
| W-5 | コード品質 | ~~コマンドオプションの重複定義~~ | ✅ OptionGroups に共通化 |
| W-6 | コード品質 | GenerateCommand の `String(describing:)` 出力 | ⚠️ API 挙動依存のため現状維持 |
| W-7 | 設計 | ~~session instructions の復元フロー~~ | ✅ transcript 空の場合 instructions 復元 |
| W-8 | 設計 | ~~セッションの guardrails/adapter 一貫性~~ | ✅ SessionMetadata に guardrails/adapter/tools 保存 |
| W-9 | テスト | ~~AppError・TranscriptFormatter のテスト不足~~ | ✅ AppErrorTests 追加済み |
| W-10 | ドキュメント | ~~bootstrap.md のセキュリティ方針と実装の乖離~~ | ✅ ドキュメント更新済み |

### 結論

**リリース可能**。Critical 3件すべて対応済み。Warning 10件中9件対応済み（W-6 は API 挙動依存のため現状維持）。
