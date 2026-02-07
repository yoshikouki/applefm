# 03: 構造化出力 (Guided Generation) の精度調査

## 調査環境

- デバイス: macOS 26 (Darwin 25.2.0)
- CLI: `.build/release/applefm generate`
- 調査日: 2026-02-08

---

## テスト 1: 単純なスキーマ (string, integer, boolean)

### スキーマ

```json
{
  "type": "object",
  "properties": {
    "name": { "type": "string" },
    "age": { "type": "integer" },
    "active": { "type": "boolean" }
  },
  "required": ["name", "age", "active"]
}
```

### テスト 1a: 具体的な指示

```bash
applefm generate "Create a profile for a software engineer named Alice who is 30 years old" \
  --schema schemas/simple.json
```

**出力:**
```json
{"name":"Alice","age":30,"active":true}
```

**評価:**
- スキーマ準拠: 完全準拠
- 型の正確性: name=string, age=integer, active=boolean -- 全て正確
- プロンプト追従: name と age はプロンプト通り。active はプロンプトに指定なく、モデルが推論して true を選択（妥当）
- エラー: なし

### テスト 1b: 曖昧な指示

```bash
applefm generate "Create a profile for a retired person" \
  --schema schemas/simple.json
```

**出力:**
```json
{"name":"Root","age":78,"active":false}
```

**評価:**
- スキーマ準拠: 完全準拠
- 型の正確性: 全て正確
- 意味的妥当性: 「退職者」→ age=78, active=false は妥当な推論。name="Root" はやや不自然だが許容範囲
- エラー: なし

---

## テスト 2: ネストしたオブジェクト + 配列

### スキーマ

```json
{
  "type": "object",
  "properties": {
    "title": { "type": "string" },
    "author": {
      "type": "object",
      "properties": {
        "name": { "type": "string" },
        "email": { "type": "string" }
      },
      "required": ["name", "email"]
    },
    "tags": {
      "type": "array",
      "items": { "type": "string" }
    },
    "rating": { "type": "number" }
  },
  "required": ["title", "author", "tags", "rating"]
}
```

### テスト 2a: 英語プロンプト

```bash
applefm generate "Create a book review for 'The Swift Programming Language'" \
  --schema schemas/nested.json
```

**出力:**
```json
{
  "title": "The Swift Programming Language",
  "tags": ["Beginner", "Intermediate", "Programming"],
  "author": {"email": "author@example.com", "name": "John Doe"},
  "rating": 5
}
```

**評価:**
- スキーマ準拠: 完全準拠
- 型の正確性: ネストオブジェクト (author)、配列 (tags)、number (rating) -- 全て正確
- ネスト構造: author.name, author.email が正しく生成
- 配列: tags が string 配列として正しく生成（3要素）
- rating: 整数 5 （number 型なので小数も許容されるが、整数も valid）
- エラー: なし

### テスト 2b: 日本語プロンプト

```bash
applefm generate "日本語の技術ブログ記事のメタデータを生成してください" \
  --schema schemas/nested.json
```

**出力:**
```json
{
  "title": "最新のプログラミング言語のトレンドについて",
  "rating": 4.5,
  "tags": ["技術", "ブログ", "日本語"],
  "author": {"email": "author@example.com", "name": "田中 太郎"}
}
```

**評価:**
- スキーマ準拠: 完全準拠
- 日本語対応: title, tags, author.name が全て日本語で生成 -- 優秀
- 型の正確性: rating=4.5 (小数点を含む number 型を正しく使用)
- 意味的品質: 日本語の技術ブログとして自然な内容
- エラー: なし

---

## テスト 3: Enum 制約

### スキーマ

```json
{
  "type": "object",
  "properties": {
    "sentiment": {
      "type": "string",
      "enum": ["positive", "negative", "neutral"]
    },
    "confidence": { "type": "number" },
    "reasoning": { "type": "string" }
  },
  "required": ["sentiment", "confidence", "reasoning"]
}
```

### テスト 3a: ポジティブなテキスト

```bash
applefm generate "Analyze the sentiment of: I love this product, it's amazing!" \
  --schema schemas/enum-constrained.json
```

**出力:**
```json
{
  "reasoning": "The use of the word 'love' and the exclamation mark indicate a strong positive sentiment towards the product.",
  "sentiment": "positive",
  "confidence": 1
}
```

**評価:**
- Enum 準拠: "positive" -- enum 値に完全一致
- confidence: 1 (最大値、強い確信を示す)
- reasoning: 適切な根拠を提示
- エラー: なし

### テスト 3b: ネガティブなテキスト

```bash
applefm generate "Analyze the sentiment of: This is the worst experience I've ever had." \
  --schema schemas/enum-constrained.json
```

**出力:**
```json
{
  "confidence": 1,
  "sentiment": "negative",
  "reasoning": "The sentence uses strong negative language such as 'worst experience' to indicate a very negative sentiment."
}
```

**評価:**
- Enum 準拠: "negative" -- enum 値に完全一致
- confidence: 1
- reasoning: 適切
- エラー: なし

### テスト 3c: 中立的なテキスト

```bash
applefm generate "Analyze the sentiment of: The weather is cloudy today." \
  --schema schemas/enum-constrained.json
```

**出力:**
```json
{
  "sentiment": "neutral",
  "confidence": 0.5,
  "reasoning": "The sentence describes a weather condition without expressing any positive or negative emotional tone. It simply states the fact that the weather is cloudy."
}
```

**評価:**
- Enum 準拠: "neutral" -- enum 値に完全一致
- confidence: 0.5 (中程度の確信、事実の記述に対して適切)
- reasoning: 適切
- エラー: なし

---

## テスト 4: 複雑なスキーマ (配列の中にオブジェクト)

### スキーマ

```json
{
  "type": "object",
  "properties": {
    "tasks": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "integer" },
          "title": { "type": "string" },
          "priority": {
            "type": "string",
            "enum": ["low", "medium", "high", "critical"]
          },
          "subtasks": {
            "type": "array",
            "items": { "type": "string" }
          },
          "completed": { "type": "boolean" }
        },
        "required": ["id", "title", "priority", "subtasks", "completed"]
      }
    },
    "summary": { "type": "string" },
    "totalCount": { "type": "integer" }
  },
  "required": ["tasks", "summary", "totalCount"]
}
```

### テスト 4a: 3タスクのプロジェクト計画

```bash
applefm generate "Create a project plan for building a mobile app with 3 tasks" \
  --schema schemas/complex.json
```

**出力 (整形済み):**
```json
{
  "totalCount": 5,
  "summary": "Project Plan for Building a Mobile App",
  "tasks": [
    {
      "totalCount": 1,
      "summary": "Define Project Scope and Requirements",
      "tasks": [
        {"tasks": [], "totalCount": 0, "summary": "Conduct Market Research"},
        {"totalCount": 0, "tasks": [], "summary": "Gather User Requirements"}
      ]
    },
    {
      "totalCount": 1,
      "summary": "Design User Interface",
      "tasks": [
        {"totalCount": 0, "tasks": [], "summary": "Create Wireframes"},
        {"tasks": [], "totalCount": 0, "summary": "Design Visual Elements"}
      ]
    },
    ...
  ]
}
```

**評価:**
- **スキーマ準拠: 不合格** -- 重大な構造エラー
- **問題点**: モデルは tasks 配列内の各要素を、期待されるタスクオブジェクト (`id`, `title`, `priority`, `subtasks`, `completed`) ではなく、トップレベルと同じ再帰的構造 (`tasks`, `summary`, `totalCount`) で生成した
- **欠落フィールド**: `id`, `title`, `priority`, `subtasks`, `completed` が全て欠落
- **余剰フィールド**: tasks 配列内に `summary`, `totalCount`, `tasks` (再帰) が出現
- **原因推定**: DynamicGenerationSchema が深くネストされた配列内オブジェクトのプロパティ制約を正しくモデルに伝達できていない可能性。あるいはモデルが再帰的パターンを誤って推論した

### テスト 4b: 明示的なタスク数指定

```bash
applefm generate "Create exactly 2 tasks for a weekend project" \
  --schema schemas/complex.json
```

**出力 (整形済み):**
```json
{
  "summary": "Weekend Project Tasks",
  "tasks": [
    {
      "totalCount": 2,
      "tasks": [
        {"summary": "Create a detailed blueprint of the project space", "totalCount": 0, "tasks": []},
        {"summary": "Identify necessary materials and tools", "totalCount": 0, "tasks": []}
      ],
      "summary": "Design and Plan the Project Layout"
    },
    {
      "totalCount": 2,
      "tasks": [
        {"summary": "Construct a working model of the project", "totalCount": 0, "tasks": []},
        {"summary": "Test the prototype and make adjustments", "totalCount": 0, "tasks": []}
      ],
      "summary": "Develop the Project Prototype"
    }
  ],
  "totalCount": 4
}
```

**評価:**
- **スキーマ準拠: 不合格** -- テスト 4a と同じ再帰的構造の問題
- 同じパターンで `id`, `title`, `priority`, `subtasks`, `completed` が全て欠落
- モデルがトップレベルスキーマを再帰的に適用するパターンは再現性がある

---

## テスト 5: --format json オプション

### テスト 5a: --format json (曖昧なプロンプト)

```bash
applefm generate "Create a simple profile" \
  --schema schemas/simple.json --format json
```

**出力:**
```json
{"content":"{\"name\":\"Root\",\"age\":30,\"active\":true}"}
```

**評価:**
- --format json 時も出力構造は同じ（content ラッパー内にJSON文字列）
- 内容のスキーマ準拠は完全

### テスト 5b: --format json (明示的な値指定)

```bash
applefm generate "Generate a person profile with name John, age 25, active status true" \
  --schema schemas/simple.json --format json
```

**出力:**
```json
{"content":"{\"active\":true,\"age\":25,\"name\":\"John\"}"}
```

**評価:**
- プロンプトで明示した値が正確に反映
- スキーマ完全準拠
- エラー: なし

---

## テスト 6: Instructions との組み合わせ

```bash
applefm generate "Analyze this text: Apple released a new product" \
  --schema schemas/enum-constrained.json \
  --instructions "You are a financial analyst. Consider market implications."
```

**出力:**
```json
{
  "confidence": 75,
  "reasoning": "The text mentions that Apple released a new product, which suggests a positive market reaction. Such announcements often lead to increased investor interest, higher stock prices, and a boost in market sentiment due to the anticipation and excitement surrounding new product launches.",
  "sentiment": "positive"
}
```

**評価:**
- Enum 準拠: "positive" -- 正しい enum 値
- Instructions 効果: reasoning に「market reaction」「investor interest」「stock prices」「market sentiment」など金融アナリスト視点の分析が反映 -- **instructions が構造化出力にも効果的に作用**
- **注意点**: confidence=75 は number 型として valid だが、テスト 3 では 0-1 の範囲を使用していた。スキーマに range 制約がないため、モデルが 0-100 スケールを選択した。instructions のコンテキストが confidence のスケール解釈に影響を与えた可能性がある
- エラー: なし

---

## 総合評価

| テスト | スキーマ | 準拠度 | 型正確性 | 制約遵守 | エラー |
|--------|----------|--------|----------|----------|--------|
| 1a: 具体的プロフィール | simple | 100% | 完全 | N/A | なし |
| 1b: 曖昧なプロフィール | simple | 100% | 完全 | N/A | なし |
| 2a: 英語ネスト | nested | 100% | 完全 | N/A | なし |
| 2b: 日本語ネスト | nested | 100% | 完全 | N/A | なし |
| 3a: ポジティブ感情 | enum | 100% | 完全 | 完全 | なし |
| 3b: ネガティブ感情 | enum | 100% | 完全 | 完全 | なし |
| 3c: 中立感情 | enum | 100% | 完全 | 完全 | なし |
| 4a: 複雑 (3タスク) | complex | **不合格** | **不正** | **不遵守** | 構造エラー |
| 4b: 複雑 (2タスク) | complex | **不合格** | **不正** | **不遵守** | 構造エラー |
| 5a: format json | simple | 100% | 完全 | N/A | なし |
| 5b: format json + 明示値 | simple | 100% | 完全 | N/A | なし |
| 6: instructions 併用 | enum | 100% | 完全 | 完全 | なし |

---

## 構造化出力ガイドライン

### 所見

1. **単純〜中程度のスキーマは高精度**: フラットなオブジェクト、1段ネスト、string配列、enum制約は全て正確に処理される
2. **複雑なネスト構造で精度が崩壊**: 配列内オブジェクトが多数のプロパティを持つ場合、モデルがトップレベル構造を再帰的に適用するバグが発生する。DynamicGenerationSchema の制約伝達に問題がある可能性
3. **Enum 制約は確実**: 3値 enum（positive/negative/neutral）は全ケースで正確に遵守
4. **日本語プロンプトでも構造は維持**: スキーマ構造の準拠度は言語に依存しない
5. **Instructions は構造化出力に効果的**: reasoning の内容に instructions のコンテキストが反映される
6. **confidence のスケールが不安定**: スキーマに数値範囲制約がないと、実行ごとに 0-1 / 0-100 でスケールが揺れる

### 推奨事項

1. **スキーマは浅くフラットに保つ**: 配列内のオブジェクトは最大 3-4 プロパティに抑える。深いネストを避ける
2. **複雑な構造は分割して生成**: 大きなスキーマを一度に渡すより、小さなスキーマで複数回生成してアプリケーション側で組み合わせる
3. **数値フィールドには description で範囲を示唆**: enum がない number 型には、プロンプトまたは instructions で期待する範囲（「0.0 to 1.0」など）を明示する
4. **Enum は積極的に活用**: 選択肢が決まっているフィールドは enum 制約を必ず付ける。モデルの遵守率は非常に高い
5. **構造化出力の検証を入れる**: 出力された JSON がスキーマに実際に適合するかをアプリケーション側でバリデーションする（特に complex スキーマ）
6. **--instructions と組み合わせる**: 構造化出力の「内容の質」を制御するには instructions が有効。ドメイン固有の分析指示を与えることで、フィールド値の品質が向上する
7. **DynamicGenerationSchema の制約**: 現時点では、配列内オブジェクトの items スキーマが深い場合に正しく制約が伝達されない問題がある。CLI/ライブラリ側の改善が必要な可能性がある
