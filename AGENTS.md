# Repository Guidelines

## Project Structure & Module Organization

- `Sources/AppleFMCore/`: Core library (prompt/session/settings/formatters/tools). Most logic lives here.
- `Sources/applefm/`: CLI entry point built with `swift-argument-parser`.
- `Tests/AppleFMTests/`: Unit tests.
- `Tests/IntegrationTests/`: Integration tests (gated; see below).
- `docs/`: Design notes and usage examples.

## Build, Test, and Development Commands

- `swift build`: Build all targets.
- `swift test`: Run unit + integration tests (integration tests may be skipped unless enabled).
- `swift test --filter AppleFMTests.OutputFormatterTests`: Run a focused suite while iterating.
- `APPLEFM_INTEGRATION_TESTS=1 swift test --filter IntegrationTests`: Run integration tests.
- `swift run applefm`: Run the CLI locally.

Prereqs: **macOS 26+** and **Swift 6.2** (Foundation Models availability depends on hardware).

## Coding Style & Naming Conventions

- Language: Swift 6.x.
- Indentation: 2 spaces (match existing Swift style).
- Prefer expressive type/func names (`SessionStore`, `ToolRegistry`) and keep CLI commands thin (delegate to `AppleFMCore`).

## Testing Guidelines

- Framework: **Swift Testing** (`import Testing`, `@Suite`, `@Test`, `#expect`). Do not add XCTest.
- Add/adjust tests in `Tests/` alongside the module they cover.
- For bug fixes, prefer a small failing test first, then implement the fix, then run `swift test`.

## Commit & Pull Request Guidelines

- Commits: small and frequent. Use conventional prefixes seen in history: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `ci:`.
- PRs: describe user-visible behavior changes, link issues if any, and include command output snippets when changing CLI UX.

## Security & Configuration Tips

- User data is stored under `~/.applefm/` (e.g., logs are append-only). Be conservative with any new delete/reset behaviors.
