# Tool Members

出典:
- https://developer.apple.com/documentation/foundationmodels/tool/call(arguments:)
- https://developer.apple.com/documentation/foundationmodels/tool/arguments
- https://developer.apple.com/documentation/foundationmodels/tool/output
- https://developer.apple.com/documentation/foundationmodels/tool/description
- https://developer.apple.com/documentation/foundationmodels/tool/includesschemaininstructions
- https://developer.apple.com/documentation/foundationmodels/tool/name
- https://developer.apple.com/documentation/foundationmodels/tool/parameters

## Invoking
- `call(arguments:)` はモデルがツールを利用したいときに呼ばれる。
- `Arguments` は `ConvertibleFromGeneratedContent` に準拠。
- `Output` は `PromptRepresentable` に準拠。

## Properties
- `description`: いつ/どのようにツールを使うかの自然言語説明。
- `includesSchemaInInstructions`: true なら name/description/parameters が Instructions に注入される。
- `name`: ユニークなツール名（例: `get_weather` など）。
- `parameters`: 引数のスキーマ (`GenerationSchema`)。
