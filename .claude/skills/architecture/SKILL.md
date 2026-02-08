---
name: architecture
description: applefm のアーキテクチャ詳細（コマンドツリー、主要抽象、ツールプロトコル）。コマンド追加・リファクタリング・設計判断時に使う。
---

# Architecture

Two-target split: `AppleFMCore` (library with all logic) + `applefm` (thin entry point with async dispatch). Tests import `AppleFMCore` directly.

## Command Tree → API Mapping

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
├── config
│   ├── set <key> <val> → SettingsStore.save (individual key, with validation)
│   ├── get <key>       → SettingsStore.load + value(forKey:)
│   ├── list [--all]    → SettingsStore.load + allValues() (--all shows unset keys)
│   ├── reset [<key>]   → SettingsStore.reset / removeValue(forKey:)
│   ├── describe [<key>]→ KeyMetadata display (type, valid values, range, description)
│   ├── init            → Interactive setup wizard (stderr prompts, stdin input)
│   └── preset [<name>] → Apply built-in preset (creative, precise, balanced)
├── chat                → interactive REPL (auto-persisted session)
├── respond             → one-shot (ephemeral session; no args + TTY → chat mode)
└── generate            → one-shot structured output
```

## Key Abstractions

- **ModelFactory** — Centralized `SystemLanguageModel` creation with guardrails/adapter selection and `GenerationOptions` building
- **ToolRegistry** — Maps `--tool` string names ("shell", "file-read") to compiled `Tool` protocol implementations
- **ToolApproval** — Controls user confirmation before tool execution (`ask` mode prompts via stderr, `auto` mode skips)
- **SessionStore** — Persists `SessionMetadata` + `Transcript` as JSON files under `~/.applefm/sessions/`. Validates session names (alphanumeric + hyphens/underscores, 1-100 chars)
- **PromptInput** — Resolves prompt from: CLI argument > `--file` > stdin
- **OutputFormatter** — Switches between text/json output via `--format`
- **InteractiveLoop** — REPL engine with DI seams (`readInput`, `writeStderr`). Streams responses, persists transcript each turn, logs via HistoryStore/SessionLogger. Session name auto-generated as `chat-YYYYMMDD-HHmmss`
- **ResponseStreamer** — Common streaming output helper used by RespondCommand, SessionRespondCommand, and InteractiveLoop
- **AppError** — Maps `LanguageModelSession.GenerationError` cases to user messages and exit codes (2–11)
- **SchemaLoader** — Parses JSON files into `DynamicGenerationSchema` for structured output
- **OptionGroups** — `ParsableArguments` groups (GenerationOptionGroup, ModelOptionGroup, ToolOptionGroup) that eliminate option duplication across commands. Each group has a `withSettings(_:)` method that returns a copy with settings-based fallback values applied
- **SettingsStore** — Persists `Settings` as `~/.applefm/settings.json`. Priority: CLI option > settings.json > built-in default. DI via `baseDirectory` init parameter
- **Settings** — All-optional `Codable` struct with key-value access (`value(forKey:)`, `setValue(_:forKey:)`, `removeValue(forKey:)`). Includes `KeyMetadata` for discoverability, value validation (enum/range checks), `suggestKey(for:)` for typo correction, and built-in `Preset` definitions
- **HistoryStore** — Appends `HistoryEntry` (sessionId, ts, text, cwd) to `~/.applefm/history.jsonl`. File permissions `0o600`
- **SessionLogger** — Writes `SessionLogEntry` to `~/.applefm/logs/session-<date>-<sessionId>.jsonl`. Tracks user/assistant/error events per session. Tool output is not logged

## Tool Protocol Pattern

Built-in tools (`ShellTool`, `FileReadTool`) use `@Generable` and `@Guide` macros for compile-time argument schema generation. Dynamic runtime tool creation is not possible with the Tool protocol — all tools must be compiled into the binary.
