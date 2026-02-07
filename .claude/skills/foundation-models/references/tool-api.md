# Tool API

出典:
- https://developer.apple.com/documentation/foundationmodels/tool

## Tool の概要
- モデルが実行時にアプリのコードを呼び出すためのプロトコル。
- ツールの `name` / `description` / `parameters` がプロンプトに注入され、モデルが呼び出し判断を行う。
- `call(arguments:)` の入力は `ConvertibleFromGeneratedContent`、出力は `PromptRepresentable` に準拠する。
- `Output` は `String` / `Generable` / それらの配列などを想定。

## Tool 定義の要点
- `Sendable` に準拠する必要がある。
- ツール定義はコンテキストサイズに影響するため、説明は短く、ツール数は最小限にする。
