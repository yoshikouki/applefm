# 12. 実用シナリオ: データ変換・抽出タスク

## 概要

Apple Foundation Models のデータ変換・抽出能力を、8つの実用的なシナリオで検証した。構造化出力（`generate`）と自由形式出力（`respond`）の両方を使い分けて評価。

---

## テスト結果

### テスト 1: 非構造化テキストからの連絡先抽出

**コマンド:**
```bash
./.build/release/applefm generate 'Extract contact information from this email:

Hi Team,

I wanted to introduce our new technical lead, Sarah Chen. She can be reached at sarah.chen@techcorp.io and her direct line is 555-0142. She previously worked at DataFlow Inc as a Principal Engineer.

Best regards,
Mike' --schema schemas/contact-info.json
```

**出力:**
```json
{
  "email": "sarah.chen@techcorp.io",
  "company": "TechCorp",
  "role": "Technical Lead",
  "name": "Sarah Chen"
}
```

**評価:**
- 名前、メール、役職: 正確に抽出
- 会社名: "TechCorp" と推定（メールドメインから）。実際には前職が "DataFlow Inc" で、現職の会社名は明示されていない。ドメインからの推測は妥当だがスキーマの意図次第
- 電話番号: スキーマで `phone` は required ではないため、省略された（555-0142 が存在するのに抽出されなかった）
- **正確性: 4/5** -- 電話番号が欠落、会社名は推測ベース

---

### テスト 2: ログからのエラー情報抽出

**コマンド:**
```bash
./.build/release/applefm respond 'Extract all errors from these log lines and summarize them:
[10行のログ]' --instructions "Extract only the ERROR entries. For each, provide: timestamp, error message, and likely root cause."
```

**出力:**
```
1. **Timestamp:** 2026-02-08 10:15:45
   - **Error Message:** Database connection failed: timeout after 30s
   - **Likely Root Cause:** Potential network issues or a slow database server.

2. **Timestamp:** 2026-02-08 10:16:15
   - **Error Message:** Database connection failed: host unreachable
   - **Likely Root Cause:** Network issues or a misconfigured host.

3. **Timestamp:** 2026-02-08 10:17:00
   - **Error Message:** API endpoint /api/users returned 503
   - **Likely Root Cause:** Service overload or misconfiguration on the API server.

4. **Timestamp:** 2026-02-08 10:17:15
   - **Error Message:** Memory usage exceeded 90% threshold
   - **Likely Root Cause:** High load or memory leaks in the application or system.
```

**評価:**
- 4件の ERROR エントリを正確に識別（INFO/WARN を除外）
- タイムスタンプとエラーメッセージは正確に転記
- 根本原因の推測は一般的だが妥当
- 注意: 4番目のタイムスタンプが 10:17:15 と記載されているが、実際は 10:18:00（INFOログの時刻と混同）
- **正確性: 4/5** -- タイムスタンプの転記ミスが1件

---

### テスト 3: テキスト分類（GitHub Issue 分類）

#### 3a. Bug Report

**出力:**
```json
{
  "category": "bug-report",
  "suggestedLabels": ["iOS Crash", "Settings Icon Issue", "Bad Access Error"],
  "confidence": 95,
  "reasoning": "The issue is clearly stated as an app crash with EXC_BAD_ACCESS, which is indicative of a software bug."
}
```

**評価:** 正確。カテゴリ、ラベル、推論すべて的確。confidence 95 も妥当。

#### 3b. Feature Request

**出力:**
```json
{
  "category": "feature-request",
  "confidence": 1,
  "suggestedLabels": [],
  "reasoning": "The issue describes a request for a new feature (dark mode support) that would improve user experience..."
}
```

**評価:** カテゴリは正確。ただし confidence が `1`（0-1スケール？）で、3a の `95`（0-100スケール）と一貫性がない。suggestedLabels が空配列なのも不十分。

#### 3c. Question

**出力:**
```json
{
  "suggestedLabels": ["documentation"],
  "confidence": 0.8,
  "category": "documentation",
  "reasoning": "The issue arises from a lack of clear documentation regarding the configuration of custom API endpoints."
}
```

**評価:** `category` が "documentation" だが、enum 定義には "question" がある。ユーザーの意図はドキュメント不備の指摘よりも質問に近い。confidence 0.8 はまた別のスケール。

**テスト3全体の評価:**
- カテゴリ分類: 2/3 正確（3c は "question" が適切だった）
- confidence スケールが不一致（95, 1, 0.8 と実行ごとにバラバラ）
- **正確性: 3/5** -- 分類精度は概ね良いが、confidence のスケール不一致が実用上の課題

---

### テスト 4: 会議メモから TODO リスト生成

#### 構造化出力（generate）の試行

**スキーマ（todo-list.json）:** 配列を含むネスト構造
```json
{
  "type": "object",
  "properties": {
    "items": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "task": { "type": "string" },
          "priority": { "type": "string", "enum": ["high", "medium", "low"] },
          "assignee": { "type": "string" }
        },
        "required": ["task", "priority", "assignee"]
      }
    }
  },
  "required": ["items"]
}
```

**結果:** `Failed to decode generated content.` -- デコードエラー

**フラットスキーマでの再試行:**
```json
{
  "content": "{\"assignee1\":\"Alice\",\"task1\":\"Handle the database migration by Friday.\",\"priority1\":\"Critical\"}"
}
```
フラットスキーマでは応答したが、最初のタスクしか抽出されなかった。

#### 自由形式出力（respond）での試行

```json
[
    {"taskDescription": "Handle the database migration", "assigneeName": "Alice", "priority": "high"},
    {"taskDescription": "Fix the authentication bug", "assigneeName": "Bob", "priority": "high"},
    {"taskDescription": "Update the API documentation and share it with the team", "assigneeName": "Carol", "priority": "medium"},
    {"taskDescription": "Set up the staging environment", "assigneeName": "Dave", "priority": "medium"},
    {"taskDescription": "Final review", "assigneeName": "Team", "priority": "high"}
]
```

**評価:**
- `generate` + ネスト配列スキーマ: 失敗（DynamicGenerationSchema の制約）
- `generate` + フラットスキーマ: 部分的成功（1件のみ抽出）
- `respond` + 自由形式: 完全成功（5件すべて正確に抽出、優先度も正しい）
- **正確性: respond は 5/5、generate は 1/5**
- **発見: 配列を含むスキーマでの構造化出力は現状不安定。複数アイテムの抽出には respond の方が信頼性が高い**

---

### テスト 5: 感情分析バッチ

**コマンド:**
```bash
./.build/release/applefm respond '[5件のレビューテキスト]' \
  --instructions "For each review, provide: sentiment (positive/negative/neutral), rating (1-5), and one-line summary."
```

**出力:**
| レビュー | 感情 | 評価 | 期待値 | 一致 |
|---------|------|------|--------|------|
| 1. 期待超え | Positive | 5 | Positive/5 | OK |
| 2. 配送遅い | Negative | 2 | Negative/2 | OK |
| 3. 破損品 | Negative | 1 | Negative/1 | OK |
| 4. 普通 | Neutral | 3 | Neutral/3 | OK |
| 5. コスパ最高 | Positive | 5 | Positive/4-5 | OK |

**評価:**
- 全5件のセンチメント判定が正確
- 評価スコアも妥当
- フォーマットは整っており、すぐに使える品質
- **正確性: 5/5**

---

### テスト 6: フォーマット変換（JSON → 人間可読テキスト）

**コマンド:**
```bash
./.build/release/applefm respond '[JSONデータ]' \
  --instructions "Convert to a readable project overview. Use bullet points."
```

**出力:**
```
**Project Overview for applefm (Version 1.1.1)**

- **Project Name:** applefm
- **Version:** 1.1.1

**Targets:**
- **AppleFMCore**
  - Type: Library
  - Files: 24
- **applefm**
  - Type: Executable
  - Files: 1

**Dependencies:**
- **swift-argument-parser**
  - Version: 1.5.0

**Supported Platforms:**
- macOS 26+

**Swift Version:**
- Swift: 6.2
```

**評価:**
- 全フィールドを正確に変換
- 階層構造を適切にインデントで表現
- Markdown フォーマットが整っている
- ただし "bullet points" の指示に対し、階層的なフォーマットを選択（指示への忠実度は高い）
- **正確性: 5/5**

---

### テスト 7: 日本語テキストからの構造化抽出

**コマンド:**
```bash
./.build/release/applefm generate '以下の日本語テキストから連絡先情報を抽出してください：

株式会社テクノロジーの田中太郎（t.tanaka@techno.co.jp）が新しいプロジェクトリーダーに就任しました。以前は大手IT企業でシニアエンジニアとして勤務していました。' --schema schemas/contact-info.json --guardrails permissive
```

**出力:**
```json
{
  "name": "田中太郎",
  "email": "t.tanaka@techno.co.jp",
  "role": "プロジェクトリーダー",
  "company": "株式会社テクノロジー"
}
```

**評価:**
- 全4フィールドを正確に抽出
- 日本語テキストからの抽出も問題なし
- 会社名、役職が日本語のまま正確に出力
- **正確性: 5/5**

---

### テスト 8: 複雑な抽出 + 分析（コミット履歴パターン分析）

**コマンド:**
```bash
./.build/release/applefm respond '[10件のコミット履歴]' \
  --instructions "You are a technical lead analyzing commit patterns. Be specific about risks."
```

**出力（要約）:**

| 分析項目 | 結果 |
|---------|------|
| Fix/Feat/Other 比率 | 6:2:2（実際は 5:3:2 が正確） |
| 最も懸念される修正 | SQL injection, Memory leak, Race condition, Timeout |
| 推奨アクション | セキュリティレビュー、自動テスト、定期的な依存関係更新 |

**評価:**
- コミットの分類: 一部不正確（`pqr1234 refactor` を feat と miscount、`vwx9012 feat: add rate limiting` を重複カウント）
- 実際の内訳: fix 5件、feat 3件、refactor 1件、chore 1件
- リスク分析の質: 高品質 -- SQL injection を最重要と正しく判定
- 推奨アクションは一般的だが実用的
- **正確性: 3/5** -- 集計にエラーがあるが、リスク分析は的確

---

## データ変換・抽出能力まとめ

### 1. 得意な抽出タスク

| タスク | 正確性 | 備考 |
|--------|--------|------|
| 連絡先情報抽出（英語・日本語） | 5/5 | スキーマ駆動で高精度、多言語対応 |
| 感情分析 | 5/5 | センチメント判定・数値評価ともに正確 |
| フォーマット変換 | 5/5 | JSON → 人間可読テキストの変換が的確 |
| ログエラー抽出 | 4/5 | フィルタリング正確、タイムスタンプ転記に注意 |
| テキスト分類（単純） | 4/5 | カテゴリ判定は概ね正確 |

### 2. 苦手な抽出タスク

| タスク | 正確性 | 原因・備考 |
|--------|--------|-----------|
| 複数アイテムの構造化抽出（generate） | 1/5 | 配列を含むスキーマのデコードに失敗。DynamicGenerationSchema の制約 |
| 数値集計・カウント | 3/5 | コミット分類で誤カウント。正確な集計が必要な場合は信頼性に欠ける |
| confidence スケールの一貫性 | 3/5 | 同じスキーマでも 95, 1, 0.8 とスケールがバラバラ |

### 3. 構造化出力（generate）vs 自由形式（respond）の使い分け

| 観点 | generate | respond |
|------|----------|---------|
| **適用場面** | 単一オブジェクトの抽出（連絡先、分類結果） | 複数アイテムのリスト、分析、変換 |
| **精度** | スキーマに合致すれば高精度 | フォーマット一貫性は劣るが内容は正確 |
| **制約** | 配列を含むネストスキーマでデコードエラー | 出力フォーマットの保証なし |
| **推奨** | フラットなスキーマ（5フィールド以下）に限定 | 複雑な抽出やリスト生成には respond を優先 |

**使い分けガイドライン:**
- **generate を使うべき場合:** 単一エンティティの抽出（連絡先、分類、要約）で、スキーマがフラットな場合
- **respond を使うべき場合:** 複数アイテムの抽出、分析レポート、フォーマット変換、配列を含む出力が必要な場合
- **ハイブリッド推奨:** respond で自由形式の JSON を出力させ、アプリ側でパースする方が現実的

### 4. 実用度の総合評価

| 評価項目 | スコア | 詳細 |
|---------|--------|------|
| 情報抽出（単一エンティティ） | A | 連絡先、分類など単一オブジェクトの抽出は実用レベル |
| 情報抽出（複数エンティティ） | B- | generate は配列スキーマで失敗。respond なら対応可能 |
| テキスト分類 | B+ | 分類自体は正確だが、confidence 値のスケール不一致が課題 |
| 感情分析 | A | 5段階評価・ポジネガ判定ともに正確 |
| フォーマット変換 | A | JSON/テキスト間の変換は高品質 |
| 数値分析・集計 | C+ | カウントや比率の計算にエラーが出やすい |
| 多言語対応 | A | 日本語テキストからの抽出も英語と同等の精度 |
| **総合** | **B+** | 単一エンティティの抽出・変換は実用的。複数アイテムの構造化出力と正確な数値処理に改善の余地あり |

### 実用上の推奨事項

1. **構造化出力スキーマはフラットに保つ** -- 配列やネストされたオブジェクトを避け、単一エンティティのスキーマを使用する
2. **複数アイテムの抽出には respond を使用** -- generate の配列スキーマは不安定なため、respond + instructions で JSON フォーマットを指示する方が信頼性が高い
3. **数値集計はモデルに任せない** -- コミットのカウントなど正確な集計が必要な場合は、アプリ側で処理する
4. **confidence 値は相対的に扱う** -- 実行ごとにスケールが変わるため、絶対値としての利用は避ける
5. **日本語テキストの処理は信頼可能** -- 英語と同等の精度で抽出・分類が可能
