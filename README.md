# applefm

A thin CLI wrapper for Apple's Foundation Models framework (macOS 26+). Exposes on-device LLM capabilities via command-line interface.

## Prerequisites

- **macOS 26+** (Tahoe)
- **Swift 6.2+**
- Apple Intelligence-capable device (Apple Silicon Mac)

## Installation

### Homebrew (recommended)

```bash
brew tap yoshikouki/applefm
brew install applefm
```

### Build from source

```bash
git clone https://github.com/yoshikouki/applefm.git
cd applefm
swift build -c release
cp .build/release/applefm /usr/local/bin/
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
├── config
│   ├── set <key> <value>   Set a default value (with validation)
│   ├── get <key>           Get a setting value
│   ├── list [--all]        List settings (--all shows unset keys too)
│   ├── reset [<key>]       Reset settings (key or all)
│   ├── describe [<key>]    Describe a key (type, valid values, range)
│   ├── init                Interactive setup wizard
│   └── preset [<name>]     Apply a built-in preset
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
| `--language` | `ja`/`en` | - | Response language hint (respond, generate, chat) |
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
applefm respond "Summarize README.md in current project" --tool file-read

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

## Configuration

Set default values for CLI options in `~/.applefm/settings.json`. CLI options always take priority over settings.

```bash
# Set defaults
applefm config set temperature 0.7
applefm config set stream true
applefm config set tools shell,file-read

# View settings
applefm config list
applefm config get temperature

# Reset
applefm config reset temperature   # Reset single key
applefm config reset               # Reset all

# Discover available settings
applefm config describe            # List all keys with descriptions
applefm config describe temperature  # Detailed info for a key

# Interactive setup
applefm config init                # Guided wizard for common settings

# Apply presets
applefm config preset              # List available presets
applefm config preset creative     # Apply creative preset (temperature=1.5)
applefm config preset precise      # Apply precise preset (temperature=0.2, sampling=greedy)
applefm config preset balanced     # Apply balanced preset (temperature=0.7)

# CLI options override settings
applefm respond "Hello" --temperature 1.0  # Uses 1.0, not 0.7
```

Setting values are validated: invalid enum values, out-of-range numbers, and key typos are caught with helpful error messages.

All setting keys correspond to CLI option names (camelCase): `maxTokens`, `temperature`, `sampling`, `samplingThreshold`, `samplingTop`, `samplingSeed`, `guardrails`, `adapter`, `tools`, `toolApproval`, `format`, `stream`, `instructions`, `logEnabled`, `language`.

## Logging

applefm automatically records command history and session logs (enabled by default).

### Command History

All prompts are recorded in `~/.applefm/history.jsonl` with session ID, timestamp, prompt text, and working directory.

### Session Logs

Session commands (`session respond`, `session generate`) write detailed logs to `~/.applefm/sessions/log-<date>-<sessionId>.jsonl`, recording user prompts, assistant responses, and errors.

### Disabling Logging

```bash
# Via config
applefm config set logEnabled false

# Via environment variable
APPLEFM_NO_LOG=1 applefm respond "Hello"
```

Log files are stored with restricted permissions (file: 0600, directory: 0700) to protect conversation content.

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
- `--language` is best-effort; the on-device model tends to follow the prompt language rather than the system instruction language hint

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
