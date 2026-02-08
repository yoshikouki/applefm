# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

applefm is a thin CLI wrapper for Apple's Foundation Models framework (macOS 26+). It exposes on-device LLM capabilities via `swift-argument-parser` commands that map directly to the FoundationModels API surface.

## Build & Test

```bash
swift build              # Build all targets
swift test               # Run all unit tests (AppleFMTests + IntegrationTests)
swift test --filter AppleFMTests.OutputFormatterTests  # Run a single test suite
swift run applefm        # Run the CLI (default: RespondCommand)
```

Requires **macOS 26+** and **Swift 6.2**. Foundation Models availability depends on the device hardware.

**テスト効率**: 変更が特定モジュールに限定される場合は `swift test --filter` で関連テストのみ実行する。フル `swift test` は複数モジュールにまたがる変更時またはコミット直前のみ。

## Architecture

Two-target split: `AppleFMCore` (library with all logic) + `applefm` (thin entry point with async dispatch). Tests import `AppleFMCore` directly.

詳細（コマンドツリー、主要抽象、ツールプロトコル）→ `.claude/skills/architecture/SKILL.md`

## Testing

Uses **Swift Testing** framework (`import Testing`, `@Suite`, `@Test`, `#expect`). Do NOT use XCTest.

Unit tests cover: OutputFormatter, PromptInput, SessionStore, SettingsStore, Settings, SchemaLoader, TranscriptFormatter, ToolRegistry, ModelFactory, AppError, HistoryStore, SessionLogger, InteractiveLoop. Integration tests are gated by `APPLEFM_INTEGRATION_TESTS` environment variable and require a device with Foundation Models available.

## Documentation Rule

重要な変更（アーキテクチャ変更、新コマンド追加、API マッピング変更）や重要な躓き（API の実際の挙動がドキュメントと異なる、ビルドエラーの回避策など）があった場合は、関連する docs（`docs/cli-design.md`, `.claude/skills/foundation-models/references/api-reference.md`, この `CLAUDE.md`）を必ず更新すること。コードだけ変えてドキュメントを放置しない。

## Design Principles

- **ログは永続**: `~/.applefm/logs/` のファイルは append-only。セッション削除やリセットでログを消さない
- **セッションは CRUD**: `~/.applefm/sessions/` のデータはユーザーが明示的に作成・削除する
- **ユーザーデータの削除はデフォルト保守的**: 新しい「削除」動作を追加する場合、関連データ（ログ等）は保持がデフォルト

## Workflow

変更のたびにコミットする。小さな単位でこまめにコミットし、変更を積み上げていく。

実装完了後は必ず `swift run applefm` で実際の CLI 挙動を確認する。テストだけでなく、ユーザーが使うのと同じ方法で動作検証を行うこと。インタラクティブコマンド (`chat` 等) の検証には tmux を使う（→ `.claude/skills/cli-verification/SKILL.md`）。

**セッションサイズの管理**: 1セッション内の実装計画は **最大5コミット** を目安にする。6コミット以上の計画は複数セッションに分割し、各セッションに明確なゴールを設定する。これはコンテキスト溢れによる進捗情報の喪失を防ぐため。

## Skills Reference

| Skill | 用途 |
|---|---|
| `architecture` | コマンドツリー、主要抽象、ツールプロトコル |
| `release` | リリースチェックリスト、Homebrew 配布 |
| `foundation-models` | FoundationModels API リファレンス、実装上の制約 |
| `cli-verification` | tmux を使った CLI 動作検証手順 |
