# applefm

A thin CLI wrapper for Apple's Foundation Models framework (macOS 26+). Exposes on-device LLM capabilities via command-line interface.

## Prerequisites

- **macOS 26+** (Tahoe)
- **Swift 6.2+**
- Apple Intelligence-capable device (Apple Silicon Mac)

## Installation

```bash
git clone https://github.com/yoshikouki/applefm.git
cd applefm
swift build -c release
# Binary at .build/release/applefm

# Optional: add to PATH
cp .build/release/applefm /usr/local/bin/
# or
export PATH="$PWD/.build/release:$PATH"
```

## Quick Start

```bash
# Check model availability
applefm model availability

# One-shot generation
applefm respond "What is Swift concurrency?"

# Streaming output
applefm respond "Explain async/await" --stream

# Pipe input
echo "Summarize this" | applefm respond

# Read prompt from file
applefm respond --file prompt.txt

# Structured output with JSON schema
applefm generate "List 3 colors" --schema colors.json --format json
```

## Commands

```
applefm
├── model
│   ├── availability        Check model availability
│   ├── languages           List supported languages
│   ├── supports-locale     Check locale support
│   └── prewarm             Prewarm the model
├── session
│   ├── new <name>          Create a persistent session
│   ├── respond <name>      Send a prompt to a session
│   ├── generate <name>     Structured output in a session
│   ├── transcript <name>   View session history
│   ├── list                List all sessions
│   └── delete <name>       Delete a session (--force to skip confirmation)
├── respond                 One-shot generation (default command)
└── generate                One-shot structured output
```

## Common Options

| Option | Type | Default | Description |
|---|---|---|---|
| `--format` | `text`/`json` | `text` | Output format |
| `--max-tokens` | `Int` | - | Maximum response tokens |
| `--temperature` | `Double` | - | Sampling temperature (0.0-2.0) |
| `--sampling` | `greedy` | - | Sampling mode |
| `--sampling-threshold` | `Double` | - | Random sampling probability threshold (0.0-1.0) |
| `--sampling-top` | `Int` | - | Random sampling top-k count |
| `--sampling-seed` | `UInt64` | - | Random sampling seed |
| `--guardrails` | `default`/`permissive` | `default` | Guardrails level |
| `--adapter` | path | - | Custom adapter file |
| `--stream` | flag | `false` | Stream response incrementally |
| `--instructions` | `String` | - | System instructions (one-shot commands) |
| `--schema` | path | - | JSON schema file (generate commands) |
| `--tool` | `shell`/`file-read` | - | Enable built-in tool (repeatable) |
| `--tool-approval` | `ask`/`auto` | `ask` | Tool approval mode |
| `--force` | flag | `false` | Skip confirmation (session delete) |

**Note**: `--stream` and `--format json` cannot be used together.

## Built-in Tools

Tools allow the model to interact with the system during generation.

```bash
# Shell command execution (requires approval by default)
applefm respond "List Swift files in current dir" --tool shell

# File reading
applefm respond "Summarize README.md" --tool file-read

# Multiple tools
applefm respond "Read and analyze main.swift" --tool shell --tool file-read

# Skip approval prompts (non-interactive use)
applefm respond "Count lines in *.swift" --tool shell --tool-approval auto
```

**Security**: By default (`--tool-approval ask`), the CLI prompts for user confirmation before each tool execution. Use `--tool-approval auto` only in trusted, non-interactive environments.

Shell commands have a 60-second timeout. File reads warn on sensitive paths (`.ssh/`, `.env`, etc.).

## Session Management

Sessions persist conversation history across multiple interactions.

```bash
# Create a session with instructions
applefm session new coding --instructions "You are a Swift expert"

# Chat within the session
applefm session respond coding "How do I use async/await?"
applefm session respond coding "Show me an example with URLSession"

# View conversation history
applefm session transcript coding

# List and manage sessions
applefm session list
applefm session delete coding          # prompts for confirmation
applefm session delete coding --force  # skip confirmation
```

Sessions are stored in `~/.applefm/sessions/` as JSON files.

## Structured Output

Generate structured data using JSON schemas.

```bash
# Create a schema file
cat > person.json << 'EOF'
{
  "name": "Person",
  "properties": {
    "name": {"type": "string", "description": "Full name"},
    "age": {"type": "integer", "description": "Age in years"}
  },
  "required": ["name", "age"]
}
EOF

# Generate structured output
applefm generate "Create a fictional character" --schema person.json
```

## Error Codes

| Code | Meaning |
|---|---|
| 1 | General error (invalid input, session not found, file error) |
| 2 | Context window exceeded |
| 3 | Guardrail violation |
| 4 | Rate limited |
| 5 | Model refusal |
| 6 | Unsupported language/locale |
| 7 | Assets unavailable |
| 8 | Unsupported guide |
| 9 | Decoding failure |
| 10 | Model not available |
| 11 | Concurrent requests |

## Known Limitations

- Requires macOS 26+ with Apple Intelligence enabled
- Foundation Models availability depends on device hardware (Apple Silicon)
- Guardrails cannot be fully disabled; `--guardrails permissive` is the most relaxed option
- Dynamic tool creation at runtime is not possible; all tools must be compiled into the binary
- `--stream` and `--format json` cannot be combined (streaming outputs raw text)

## Development

```bash
swift build              # Build
swift test               # Run unit tests
swift test --filter AppleFMTests  # Run specific test suite
swift run applefm        # Run CLI

# Integration tests (requires Foundation Models device)
APPLEFM_INTEGRATION_TESTS=1 swift test --filter IntegrationTests
```

## License

MIT
