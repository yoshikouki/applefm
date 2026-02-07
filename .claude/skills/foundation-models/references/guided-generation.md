# Guided Generation

モデルの出力を Swift の型に制約する機能。

## @Generable Macro

構造体・列挙型に適用し、モデルが生成可能な型を定義する。

```swift
@Generable(description: "Optional description for the model")
struct MyType {
    var property: String
}
```

### Supported Base Types

- `Bool`, `Int`, `Float`, `Double`, `Decimal`
- `String`
- `Array` (of Generable types)
- `Optional` (of Generable types)
- `GenerationID` (モデルが生成する一意識別子)

### Basic Example

```swift
@Generable(description: "Basic profile information about a cat")
struct CatProfile {
    var name: String
    @Guide(description: "The age of the cat", .range(0...20))
    var age: Int
    @Guide(description: "A one sentence profile about the cat's personality")
    var profile: String
}

let session = LanguageModelSession()
let response = try await session.respond(
    to: "Tell me about a tabby cat named Whiskers",
    generating: CatProfile.self
)
// response.content is CatProfile
```

### Nested Types

```swift
@Generable
struct Itinerary {
    @Guide(description: "An exciting name for the trip")
    let title: String
    @Guide(.anyOf(ModelData.landmarkNames))
    let destinationName: String
    @Guide(.count(3))
    let days: [DayPlan]
}

@Generable
struct DayPlan {
    @Guide(description: "A unique title for this day plan")
    let title: String
    @Guide(.count(3))
    let activities: [Activity]
}

@Generable
struct Activity {
    let type: Kind
    let title: String
    let description: String
}

@Generable
enum Kind {
    case sightseeing
    case foodAndDining
    case shopping
    case hotelAndLodging
}
```

> Properties are generated in declaration order.

## @Guide Macro

プロパティの値を制約する。

```swift
@Guide(description: "Natural language description")
@Guide(description: "Description", .constraint)
```

### Available Constraints (GenerationGuide)

| Constraint | Description |
|---|---|
| `.range(ClosedRange)` | 数値の範囲 |
| `.count(Int)` | 配列の要素数 (固定) |
| `.maximumCount(Int)` | 配列の最大要素数 |
| `.anyOf([String])` | 文字列の候補リスト |

### Examples

```swift
@Guide(description: "Rating", .range(1...5))
var rating: Int

@Guide(description: "Tags", .count(3))
var tags: [String]

@Guide(description: "Category", .anyOf(["tech", "science", "art"]))
var category: String

@Guide(.maximumCount(10))
var items: [Item]
```

## PartiallyGenerated

`@Generable` マクロは自動的に `PartiallyGenerated` 型を生成する。全プロパティが `Optional` になったミラー型で、ストリーミング時に使用。

```swift
let stream = session.streamResponse(to: prompt, generating: CatProfile.self)
for try await partial in stream {
    // partial: CatProfile.PartiallyGenerated
    if let name = partial.name {
        print("Name so far: \(name)")
    }
}
let final = try await stream.collect()
// final.content: CatProfile (fully populated)
```

## DynamicGenerationSchema

コンパイル時に型が不明な場合、実行時にスキーマを構築する。

```swift
let menuSchema = DynamicGenerationSchema(
    name: "Menu",
    properties: [
        DynamicGenerationSchema.Property(
            name: "dailySoup",
            schema: DynamicGenerationSchema(
                name: "dailySoup",
                anyOf: ["Tomato", "Chicken Noodle", "Clam Chowder"]
            )
        )
    ]
)

let schema = try GenerationSchema(root: menuSchema, dependencies: [])
let response = try await session.respond(to: "Pick today's menu", schema: schema)
// response.content is GeneratedContent
let soup = response.content.value(String.self, forProperty: "dailySoup")
```

### DynamicGenerationSchema Initializers

```swift
// Object with properties
init(name: String, description: String?, properties: [Property])

// String enum (anyOf)
init(name: String, description: String?, anyOf choices: [DynamicGenerationSchema])

// Array
init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)

// Reference to another schema
init(referenceTo: String)

// From generable type with guides
init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])
```

## Schema Size Optimization

スキーマはコンテキストウィンドウを消費する。削減方法:

- 不要なプロパティを削除
- プロパティ名は短く明確に
- `@Guide(description:)` は品質向上に必要な場合のみ
- `@Guide(.maximumCount(_:))` で配列サイズを制限
