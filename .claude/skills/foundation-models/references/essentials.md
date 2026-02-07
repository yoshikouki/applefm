# Essentials

出典:
- https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models
- https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output
- https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models
- https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

## Generating content and performing tasks
- オンデバイスモデルはテキスト生成、要約、抽出、理解、リライト、会話、創作などに対応する。
- 生成は `SystemLanguageModel` と `LanguageModelSession` を使って実行する。
- 構造化出力には `@Generable` を利用する。
- ツール呼び出しで外部データやアプリ固有の処理を組み合わせられる。

## Improving the safety of generative model output
- 生成体験は安全性の設計が必要（不適切入力・センシティブ領域・誤情報の扱いなど）。
- 出力の検証や利用者への説明（出力の性質、制約）を設計に含める。
- ガードレールを考慮し、要件に応じて調整する。

## Supporting languages and locales
- `supportsLocale(_:)` で言語・ロケール対応可否を確認する。
- `Instructions` にロケール指定を含めると出力品質が安定する。
- `supportedLanguages` を利用して UI の選択肢やフォールバック設計に反映する。

## Adding intelligent app features
- 期待する出力を明確化し、ユースケース別に `UseCase` やガイド付き生成を使い分ける。
- ツール呼び出しは必要最小限にし、ツール定義を小さく保つ。
- 生成の失敗時（拒否・ガードレール・コンテキスト超過）を前提にリカバリ設計を行う。
