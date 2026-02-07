# LanguageModelSession Members

出典:
- https://developer.apple.com/documentation/foundationmodels/languagemodelsession/init(model:tools:instructions:)
- https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond(to:schema:includeschemainprompt:options:)

## Initializer
- `init(model:tools:instructions:)` はモデル・ツール・指示をまとめて指定する。

## Dynamic Schema
- `respond(to:schema:includeSchemaInPrompt:options:)` で動的スキーマによる生成が可能。
- `includeSchemaInPrompt` はスキーマをプロンプトに含めるかどうかを制御する。
