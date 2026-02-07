# Prompting

出典:
- https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model
- https://developer.apple.com/documentation/foundationmodels/analyzing-the-runtime-performance-of-your-foundation-models-app

## Prompting an on-device foundation model
- 目的・制約・出力形式を明確に書くと結果が安定する。
- 指示（Instructions）と入力（Prompt）を分離して整理する。
- `GenerationOptions` を使って生成のふるまいを調整する。
- セッションは同時に1リクエストのみ対応のため並列実行は設計が必要。

## Analyzing runtime performance
- Instruments を使ってトークン消費と応答時間を計測し、ボトルネックを把握する。
- プロンプトやツール定義がコンテキストサイズに影響するため、必要最小限に抑える。
- 反復的なやりとりは Transcript を活用して再利用する。
