# SystemLanguageModel

出典:
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

## 概要
- オンデバイス LLM へのエントリポイント。
- `isAvailable` / `availability` で可用性を確認できる。
- `supportsLocale(_:)` と `supportedLanguages` で言語対応を確認する。
- `UseCase` と `Guardrails` で用途・安全性の挙動を制御する。
- `Adapter` でカスタムアダプタをロードできる。
