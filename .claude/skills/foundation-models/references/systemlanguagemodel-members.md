# SystemLanguageModel Members

出典:
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/default
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/supportslocale(_:)
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/supportedlanguages
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.property
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/isavailable
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/available
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailable(_:)
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason/modelnotready
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason/devicenoteligible
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason/appleintelligencenotenabled
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/init(adapter:guardrails:)
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/init(usecase:guardrails:)
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/usecase/general
- https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/usecase/contenttagging

## Availability
- `availability` は `SystemLanguageModel.Availability` を返す。
- `Availability` は `available` / `unavailable(reason:)` を持つ。
- `UnavailableReason` は `modelNotReady` / `deviceNotEligible` / `appleIntelligenceNotEnabled` など。

## Locale
- `supportsLocale(_:)` でロケール対応を判定。
- `supportedLanguages` で対応言語を取得。

## UseCase
- `UseCase.general` は汎用。
- `UseCase.contentTagging` はタグ付け用途。

## Adapter / Guardrails
- `Adapter` でカスタムアダプタを利用。
- `Guardrails` で安全性の挙動を制御。
