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

## Architecture

Two-target split: `AppleFMCore` (library with all logic) + `applefm` (thin entry point with async dispatch). Tests import `AppleFMCore` directly.

### Command Tree → API Mapping

Commands mirror FoundationModels API naming. The root command's `defaultSubcommand` is `RespondCommand`.

```
applefm
├── model
│   ├── availability    → SystemLanguageModel.default.availability
│   ├── languages       → .supportedLanguages
│   ├── supports-locale → .supportsLocale(_:)
│   └── prewarm         → session.prewarm(promptPrefix:)
├── session
│   ├── new <name>      → LanguageModelSession(model:tools:instructions:)
│   ├── respond <name>  → session.respond(to:options:) / streamResponse
│   ├── generate <name> → session.respond(to:schema:options:)
│   ├── transcript      → session.transcript
│   ├── list / delete   → filesystem ops on ~/.applefm/sessions/
├── respond             → one-shot (ephemeral session)
└── generate            → one-shot structured output
```

### Key Abstractions

- **ModelFactory** — Centralized `SystemLanguageModel` creation with guardrails/adapter selection and `GenerationOptions` building
- **ToolRegistry** — Maps `--tool` string names ("shell", "file-read") to compiled `Tool` protocol implementations
- **SessionStore** — Persists `SessionMetadata` + `Transcript` as JSON files under `~/.applefm/sessions/`
- **PromptInput** — Resolves prompt from: CLI argument > `--file` > stdin
- **OutputFormatter** — Switches between text/json output via `--format`
- **AppError** — Maps `LanguageModelSession.GenerationError` cases to user messages and exit codes (2–11)
- **SchemaLoader** — Parses JSON files into `DynamicGenerationSchema` for structured output

### Tool Protocol Pattern

Built-in tools (`ShellTool`, `FileReadTool`) use `@Generable` and `@Guide` macros for compile-time argument schema generation. Dynamic runtime tool creation is not possible with the Tool protocol — all tools must be compiled into the binary.

## Testing

Uses **Swift Testing** framework (`import Testing`, `@Suite`, `@Test`, `#expect`). Do NOT use XCTest.

Unit tests cover: OutputFormatter, PromptInput, SessionStore, SchemaLoader, TranscriptFormatter, ToolRegistry, ModelFactory. Integration tests require a device with Foundation Models available.

## Documentation Rule

重要な変更（アーキテクチャ変更、新コマンド追加、API マッピング変更）や重要な躓き（API の実際の挙動がドキュメントと異なる、ビルドエラーの回避策など）があった場合は、関連する docs（`docs/cli-design.md`, `.claude/skills/foundation-models/references/api-reference.md`, この `CLAUDE.md`）を必ず更新すること。コードだけ変えてドキュメントを放置しない。

## Workflow

変更のたびにコミットする。小さな単位でこまめにコミットし、変更を積み上げていく。

## Key Constraints

- `LanguageModelSession` is the center of all generation — respond, stream, generate, and tools all require a session
- `Transcript` conforms to `RandomAccessCollection` directly (no `.entries` property)
- `GenerationOptions.temperature` is a direct property (not nested under `Sampling`)
- `GenerationOptions.sampling` supports `.greedy`, `.random(probabilityThreshold:seed:)`, `.random(top:seed:)` — CLI exposes via `--sampling`, `--sampling-threshold`, `--sampling-top`, `--sampling-seed`
- Guardrails cannot be fully disabled; `.permissiveContentTransformations` is the most relaxed option
- `@Generable`/`@Guide` macros are compile-time only — CLI uses `DynamicGenerationSchema` for user-provided schemas
- `AsyncParsableCommand` の sync `main()` は DEBUG ビルドで即座に終了する — `main.swift` では `parseAsRoot()` + async `run()` で直接ディスパッチすること（`AppleFM.main()` を呼ばない）
