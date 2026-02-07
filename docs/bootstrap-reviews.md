# applefm v1.0.0 リリースレビュー (Round 2)

レビュー実施日: 2026-02-07
レビュー体制: 4 Agent Teams による並行レビュー

前回レビュー (Round 1) で指摘された Critical 3 件・Warning 10 件は全て対応済み。
本レビューは対応後のコードベースに対する再レビューである。

---

## 総合評価

**リリース可（条件付き）** — Foundation Models API カバレッジ ~90%、アーキテクチャは明確で「薄いラッパー」原則に忠実。コード品質は高く、前回指摘事項は概ね解決済み。新たに発見されたリリースブロッカー 4 件の対応が必要。

---

## リリースブロッカー（対応必須）

### RB-1: ShellTool のデッドロック可能性
- **分類**: コード品質 / Critical
- **ファイル**: `Sources/AppleFMCore/Tools/ShellTool.swift:31-34`
- **問題**: `process.waitUntilExit()` の前に Pipe からデータを読んでいない。stdout/stderr の出力がパイプバッファ（通常 64KB）を超えるとデッドロックが発生する
- **修正案**: `readDataToEndOfFile()` を `waitUntilExit()` の前に呼ぶか、別スレッドで読み込む

### RB-2: ストリーミング時エラーでトランスクリプトが保存されない
- **分類**: コード品質 / Critical
- **ファイル**: `Sources/AppleFMCore/Commands/Session/SessionRespondCommand.swift:58-72`
- **問題**: ストリーミング応答中にエラーが発生すると `store.saveTranscript()` が実行されず、部分的に受信したレスポンスを含むトランスクリプトが失われる
- **関連**: `SessionGenerateCommand.swift:49-63` でも `saveTranscript` が `do` ブロック内にあり一貫性がない

### RB-3: ToolApproval にユニットテストがない
- **分類**: テストカバレッジ
- **問題**: セキュリティ機構である ToolApproval に一切のテストがない。`.auto` モードの動作と非 TTY 環境での `.ask` モード拒否は容易にテスト可能
- **修正案**: 最低限 `.auto` モードと非 TTY 環境テストを追加

### RB-4: `--stream --format json` の挙動が未定義
- **分類**: アーキテクチャ / High
- **問題**: `ResponseStreamer.stream()` は常にプレーンテキストで出力。JSON フォーマット指定時の挙動が未定義
- **修正案**: 組み合わせをエラーにするか NDJSON 対応するか決定

---

## リリース前推奨（対応推奨）

### P1: FileReadTool にパス検証がない
- **分類**: コード品質 / High
- **ファイル**: `Sources/AppleFMCore/Tools/FileReadTool.swift:19-26`
- **問題**: `--tool-approval auto` の場合、LLM が `/etc/shadow` や `~/.ssh/id_rsa` など機微なファイルを読み取り可能
- **推奨**: センシティブパスへのアクセス制限か許可ディレクトリのホワイトリスト

### P2: ShellTool にタイムアウトがない
- **分類**: コード品質 / High
- **ファイル**: `Sources/AppleFMCore/Tools/ShellTool.swift:24-41`
- **問題**: LLM が `sleep 999999` 等を生成した場合、CLI が永久にハング
- **推奨**: タイムアウト付き実行メカニズムの実装

### P3: コマンドパーステストの追加
- **分類**: テストカバレッジ
- **問題**: ArgumentParser の設定（commandName, abstract, デフォルト値）の検証テストが全 13 コマンドで皆無
- **推奨**: ルートコマンド設定、`--schema` 必須オプション、デフォルトサブコマンド等のパーステストを追加

### P4: SchemaLoaderTests のアサーション強化
- **分類**: テストカバレッジ
- **問題**: `_ = schema` で終わるテストが多く、スキーマ構造の検証をしていない
- **推奨**: 生成されたスキーマのプロパティ数・型・isOptional フラグ等を検証

### P5: README.md のインストール手順不足
- **分類**: ドキュメント・UX / High
- **問題**: ビルド後にバイナリをパスに追加する手順がない。初めてのユーザーが「command not found」になる
- **推奨**: `cp .build/release/applefm /usr/local/bin/` や `swift run applefm` の説明を追加

### P6: エラーメッセージにアクショナブルなガイダンス追加
- **分類**: ドキュメント・UX / High
- **問題**: `guardrailViolation`, `unsupportedLanguageOrLocale`, `assetsUnavailable`, `decodingFailure` 等のエラーで次のアクションが不明確
- **推奨**: 例 — `"Unsupported language or locale. Use 'applefm model languages' to see supported languages."`

### P7: bootstrap.md の完了状態が未反映
- **分類**: ドキュメント・UX / High
- **問題**: タスク 3 のみ「実装済み」マーク。他のタスクの完了状態が未更新。仮のコマンド候補セクションも残存

### P8: `OutputOptionGroup` の整理
- **分類**: アーキテクチャ / High
- **問題**: 定義されているが全コマンドで未使用。各コマンドが個別に `@Option var format` を宣言
- **修正案**: 全コマンドで統一するか、未使用の `OutputOptionGroup` を削除

---

## 品質改善（リリース後でも可）

### Q1: SessionStore のファイル書き込みがアトミックでない
- **ファイル**: `Sources/AppleFMCore/Session/SessionStore.swift:41, 65`
- **推奨**: `data.write(to: url, options: .atomic)` を使用

### Q2: PromptInput.readStdin() にサイズ制限がない
- **ファイル**: `Sources/AppleFMCore/Common/PromptInput.swift:39-48`
- **問題**: 巨大ファイルがパイプされると OOM リスク

### Q3: ResponseStreamer の差分計算で O(n) コスト
- **ファイル**: `Sources/AppleFMCore/Common/ResponseStreamer.swift:10-13`
- **問題**: `String.count` ベースの計算は毎回 O(n)。大きなレスポンスで性能劣化の可能性

### Q4: ToolApproval.requestApproval が同期ブロッキング
- **ファイル**: `Sources/AppleFMCore/Tools/ToolApproval.swift:26-46`
- **問題**: `Swift.readLine()` が cooperative thread pool のスレッドをブロック

### Q5: `session delete` に確認プロンプトがない
- **問題**: 確認なしで即座にセッション削除。`--force` / `-y` フラグの検討

### Q6: `model prewarm` のコマンド配置
- **問題**: `session.prewarm()` を呼ぶため `session prewarm` の方が API マッピングに忠実。設計意図の文書化を推奨

### Q7: TranscriptFormatterTests の実データテスト欠落
- **問題**: 初期化と空 Transcript のみ。instructions/prompt/response のフォーマットテストがない

### Q8: コマンド間のコード重複
- **問題**: `SessionRespondCommand` と `RespondCommand` でモデル作成→レスポンス取得→出力のフローが重複
- **推奨**: 共通ヘルパー抽出（ただし「薄いラッパー」原則との兼ね合いに注意）

### Q9: README.md にパイプ入力の例がない
- **推奨**: `echo "..." | applefm respond` や `--file` の使用例を追加

### Q10: `--instructions` と `--sampling-*` オプションが Common Options テーブルに未記載
- **問題**: README.md の Common Options テーブルに含まれていない

### Q11: `session generate` / `generate` のストリーミング未対応
- **問題**: API 上 `streamResponse(to:schema:options:)` が存在するが CLI では未対応

### Q12: IntegrationTests に非デバイス依存テストが混在
- **問題**: SessionStore 関連テストが IntegrationTests 内にあるが、ユニットテストに移動すべき

---

## 記録（将来検討）

| 項目 | 内容 |
|---|---|
| `UseCase.contentTagging` | `.general` 以外の UseCase。v1.0.0 では `.general` のみで十分 |
| `LanguageModelFeedback` | レスポンス品質フィードバック API。CLI の性質上 v1.0.0 では対象外 |
| `respond(options:)` (prompt なし) | Instructions のみで生成。稀なユースケース |
| `SessionStore` 同時アクセス制御 | 複数プロセスからの競合状態。CLI 単発実行では稀 |
| ToolRegistry のプラグイン拡張 | Tool protocol のコンパイル時制約により不可避。将来のプラグイン機構検討 |

---

## テストカバレッジ概況

| 項目 | 値 |
|---|---|
| テスト済みコアモジュール | 8/8 (OutputFormatter, PromptInput, SessionStore, SchemaLoader, TranscriptFormatter, ToolRegistry, ModelFactory, AppError) |
| テスト未実装モジュール | ToolApproval, ResponseStreamer, OptionGroups, ShellTool, FileReadTool |
| コマンドパーステスト | 0/13 コマンド |
| テストスイート数 | ユニット 8 + Integration 1 = 合計 9 |
| 推定テストケース数 | 約 55 |

## API カバレッジ

Foundation Models API カバレッジ: **~90%**（CLI として合理的な範囲）

CLI の性質上対象外とした API:
- `@Generable` / `@Guide` macro（コンパイル時型定義 → Dynamic Schema で代替）
- `@PromptBuilder` / `@InstructionsBuilder`（String で十分）
- `isResponding`（CLI は単発実行のため不要）
- 静的 Guided Generation / `includeSchemaInPrompt`（コンパイル時型が必要）

---

## レビュー実施体制

| レビュアー | 担当領域 | 指摘件数 |
|---|---|---|
| code-quality-reviewer | コード品質・セキュリティ | Critical 2, High 4, Medium 6, Low 5 |
| architecture-reviewer | アーキテクチャ・設計 | P1 2, P2 4, P3 4 |
| docs-ux-reviewer | ドキュメント・UX | High 3, Medium 8, Low 5 |
| test-reviewer | テストカバレッジ | ブロッカー 3, 推奨 5 |

---

## 前回レビュー (Round 1) からの改善

Round 1 で指摘された Critical 3 件・Warning 10 件は全て対応済み:

| Round 1 指摘 | 状態 |
|---|---|
| C-1: ShellTool のツール承認機構が未実装 | ToolApproval (ask/auto) 実装済み |
| C-2: IntegrationTests が placeholder のみ | E2E テスト追加済み (環境変数ゲート) |
| C-3: README.md が存在しない | README.md 作成済み |
| W-1: FileReadTool のパス制限なし | ToolApproval で承認制に統合 |
| W-2: SessionStore のセッション名サニタイズなし | validateSessionName 実装済み |
| W-3: ストリーミングのデルタ計算ロジックの堅牢性 | ResponseStreamer に共通化 |
| W-4: ストリーミングコードの重複 | ResponseStreamer に抽出 |
| W-5: コマンドオプションの重複定義 | OptionGroups に共通化 |
| W-6: GenerateCommand の `String(describing:)` 出力 | API 挙動依存のため現状維持 |
| W-7: session instructions の復元フロー | transcript 空の場合 instructions 復元 |
| W-8: セッションの guardrails/adapter 一貫性 | SessionMetadata に保存 |
| W-9: AppError・TranscriptFormatter のテスト不足 | AppErrorTests 追加済み |
| W-10: bootstrap.md のセキュリティ方針と実装の乖離 | ドキュメント更新済み |
