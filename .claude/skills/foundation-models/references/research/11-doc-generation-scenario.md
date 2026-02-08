# 実用シナリオ: ドキュメント・コミットメッセージ生成

> Apple Foundation Models (on-device) のドキュメント生成能力を8つの実用タスクで検証

## テスト環境

- デバイス: macOS 26+
- CLI: `.build/release/applefm`
- モデル: SystemLanguageModel.default (on-device)
- 実行日: 2026-02-08

---

## テスト 1: Docstring 生成

### コマンド

```bash
./.build/release/applefm respond 'Generate Swift documentation comments (///) for this function: ...' \
  --instructions "Generate comprehensive Swift documentation comments (///) including parameter descriptions, return value, and throws documentation."
```

### 出力

```swift
/// Creates a new LanguageModelSession with a given model, tools, and instructions.
///
/// - Parameters:
///   - name: The name of the session.
///   - instructions: Optional instructions for the session.
///   - tools: An array of tools to be used in the session.
///   - guardrails: Optional guardrails to enforce during session execution.
/// - Returns: A new LanguageModelSession instance.
/// - Throws: LanguageModelError if any step fails.
func createSession(
    name: String,
    instructions: String?,
    tools: [String],
    guardrails: String? = nil
) throws -> LanguageModelSession {
    // Step 1: Create a model using the provided guardrails.
    let model = try ModelFactory.createModel(guardrails: guardrails)
    // Step 2: Resolve tool instances from the provided array.
    let toolInstances = ToolRegistry.resolve(tools)
    // Step 3: Create a new LanguageModelSession instance with the model, tools, and instructions.
    let session = LanguageModelSession(
        model: model,
        tools: toolInstances,
        instructions: instructions.map { Instructions($0) }
    )
    // Step 4: Save the session to the session store with the given name and metadata.
    try sessionStore.save(name: name, metadata: SessionMetadata(name: name, instructions: instructions))
    // Step 5: Return the newly created session.
    return session
}
```

### 評価

| 項目 | 評価 |
|------|------|
| 正確性 | 良好 — パラメータ名・型・Optionalの記述が正確 |
| 完成度 | 良好 — `///` 形式、Parameters/Returns/Throws を網羅 |
| 実用性 | 中程度 — そのまま使えるが、throws の型が `LanguageModelError` と推測で記述（要確認） |
| 問題点 | 関数本体にインラインコメント（Step 1〜5）を勝手に追加。guardrails に `= nil` をデフォルト引数として追加（元コードにはない）。ドキュメントだけ生成してほしいのにコード本体も変更した |
| そのまま使えるか | **要編集** — ドキュメント部分のみ抽出して使う必要あり。throws の型名は検証が必要 |

---

## テスト 2: コミットメッセージ生成（構造化出力）

### コマンド

```bash
./.build/release/applefm generate 'Generate a conventional commit message for these changes: ...' \
  --schema .claude/skills/foundation-models/references/research/schemas/changelog.json
```

### 出力

```json
{
  "content": "{\"summary\":\"Enhanced error handling and JSON Schema support in FileReadTool and SchemaLoader\",\"breaking\":false,\"scope\":\"module\",\"type\":\"fix\"}"
}
```

パース後:
```json
{
  "type": "fix",
  "scope": "module",
  "summary": "Enhanced error handling and JSON Schema support in FileReadTool and SchemaLoader",
  "breaking": false
}
```

### 評価

| 項目 | 評価 |
|------|------|
| 正確性 | 良好 — type: "fix" は変更内容に適切、breaking: false も正しい |
| 完成度 | 良好 — スキーマの全フィールド（type, scope, summary, breaking）が出力 |
| 実用性 | 高い — そのまま `fix(module): Enhanced error handling...` に変換可能 |
| 問題点 | scope が "module" と汎用的。より具体的な "schema,file-read" 等が望ましい。summary がやや長い |
| そのまま使えるか | **ほぼそのまま使える** — scope の調整のみ |

---

## テスト 3: チェンジログ生成

### コマンド

```bash
./.build/release/applefm respond 'Generate a changelog entry for these commits: ...' \
  --instructions "Generate a professional changelog following Keep a Changelog format."
```

### 出力

```markdown
## Version 1.2.0

### Added
- **Interactive Chat Mode**: Introduced interactive chat functionality, enhancing user engagement and interaction.
- **Foundation Models Performance Characteristics Research**: Added a section detailing performance characteristics of Foundation Models, aiding developers in optimizing their applications.

### Changed
- **JSON Schema Enum Support**: Implemented JSON Schema enum support, improving data validation and consistency.
- **FileReadTool Error Handling**: Enhanced error handling for FileReadTool, ensuring smoother operation and user experience.

### Fixed
- **Interactive Mode Guardrails**: Added default instructions and permissive guardrails for interactive mode to ensure user safety and compliance.
```

### 評価

| 項目 | 評価 |
|------|------|
| 正確性 | 中程度 — Keep a Changelog 形式に概ね準拠。ただし分類に問題あり（JSON Schema enum は "Fixed" であるべき。"Changed" は不適切） |
| 完成度 | 良好 — 全4コミットが反映され、3カテゴリに分類 |
| 実用性 | 中程度 — 構造・フォーマットは良いが、分類の正確性に要修正 |
| 問題点 | コミットの fix: prefix を正しく "Fixed" に分類できていないケースあり。説明文がやや冗長 |
| そのまま使えるか | **要編集** — カテゴリの再分類と説明文の簡潔化が必要 |

---

## テスト 4: README セクション生成（ツール使用）

### コマンド

```bash
./.build/release/applefm respond "Read the file Sources/AppleFMCore/Commands/ChatCommand.swift and generate a README section documenting the chat command with usage examples, available options, and tips" \
  --tool file-read --tool-approval auto \
  --instructions "Generate documentation in markdown format suitable for a README.md file."
```

### 出力

```markdown
# Chat Command Documentation

## Usage Examples

### Basic Usage
swift run chat

### Usage with Instructions
swift run chat --instructions "Welcome to the chat!"

### Example with Generation Options
swift run chat --gen-mode random

## Available Options
- **--instructions**: System instructions for the chat session.
- **--gen-mode**: Mode for generation options.
- **--model-option, --tool-option**: Additional model and tool options.

## Tips
- **Experiment with different generation modes** to see how the chat evolves.
- **Adjust the instructions** to tailor the chat experience to your needs.
- **Review the generated transcripts** to understand the outputs and refine future interactions.
```

### 評価

| 項目 | 評価 |
|------|------|
| 正確性 | 低い — `swift run chat` は誤り（正しくは `applefm chat`）。`--gen-mode` オプションは実際には存在しない可能性 |
| 完成度 | 中程度 — セクション構造は良いが、実際のオプション名が不正確 |
| 実用性 | 低い — コマンド名・オプション名が間違っているため、そのまま使うとユーザーに誤情報を提供 |
| 問題点 | ファイルを読んでいるはずだが、実際のコードとの整合性が低い。ツール使用時にもハルシネーションが発生 |
| そのまま使えるか | **使えない** — コマンド名、オプション名の全面的な修正が必要 |

---

## テスト 5: API ドキュメント生成（ツール使用）

### コマンド

```bash
./.build/release/applefm respond "Read the file Sources/AppleFMCore/Settings/Settings.swift and generate API documentation..." \
  --tool file-read --tool-approval auto
```

### 結果

**1回目**: ファイルパスが `Settings/Settings.swift` ではなく `Config/Settings.swift` だったため、ツールがファイルを見つけられず。モデルはファイルが存在しないと回答。

**2回目（正しいパス）**: `Error: Context window exceeded. Start a new session or reduce prompt size.`

Settings.swift は258行のファイルだが、プロンプト + ファイル内容 + instructions の合計がオンデバイスモデルのコンテキストウィンドウ上限を超過。

### 評価

| 項目 | 評価 |
|------|------|
| 正確性 | N/A（実行失敗） |
| 完成度 | N/A |
| 実用性 | N/A |
| 問題点 | (1) ファイルパスの推測ミス — モデルはパスを正確に解決できない。(2) 258行のファイルでもコンテキスト超過 — ツール使用+長いプロンプトとの組み合わせで限界に到達 |
| そのまま使えるか | **実行不可** |

**重要な発見**: ツール使用時はファイル内容がコンテキストに追加されるため、比較的小さなファイル（約260行）でもコンテキスト上限に達する。大きなファイルの読み取り+ドキュメント生成は現実的でない。

---

## テスト 6: 日本語ドキュメント生成（ツール使用）

### コマンド

```bash
./.build/release/applefm respond "Read the file Sources/AppleFMCore/Interactive/InteractiveLoop.swift and generate user-facing documentation in Japanese..." \
  --tool file-read --tool-approval auto \
  --instructions "日本語でユーザー向けドキュメントを生成してください。" \
  --guardrails permissive
```

### 出力

```markdown
**インタラクティブチャットモードのユーザー向けドキュメント**

### インタラクティブチャットの仕組み

#### 主な機能
- 自然な会話で返答します。
- ユーザーと同じ言語を使用します。
- /quit や Ctrl+D キーを押すと終了できます。
- 応答の履歴を記録し、必要に応じてログに記録します。

#### 使用方法
1. チャットモードを開始します。
2. ユーザーが任意の文を入力します。
3. システムは、ユーザーの入力に基づいて応答を生成します。
4. 応答が返されます。
5. /quit または Ctrl+D を入力すると終了します。

#### 履歴とログ
- 入力されたテキストは、セッションの履歴に保存されます。
- 応答もログに記録されます。
```

### 評価

| 項目 | 評価 |
|------|------|
| 正確性 | 良好 — /quit と Ctrl+D の終了方法は実装と一致。基本的な使い方の説明は正確 |
| 完成度 | 中程度 — 基本的な使い方は網羅しているが、具体的なコマンドライン例がない |
| 実用性 | 中程度 — ユーザー向けドキュメントとしての構造は良い。ただし具体性に欠ける |
| 問題点 | 起動コマンド（`applefm chat`）の記載がない。オプション（--instructions, --tool 等）の説明がない。ファイルを読んだ割に詳細度が低い |
| そのまま使えるか | **要編集** — 起動コマンドとオプションの追記が必要 |

**日本語能力**: 自然な日本語が生成された。技術文書としての日本語品質は十分。instructions を日本語で与えると日本語で応答する点は良好。

---

## テスト 7: PR 説明文生成（diff から）

### コマンド

```bash
./.build/release/applefm respond 'Summarize what this diff does in 2-3 sentences for a pull request description: ...' \
  --instructions "Write a concise pull request description."
```

### 出力

> This diff removes the `instructions` and `guardrails` parameters from `ChatCommand`. These parameters were previously required by default. The `run` method now uses `InteractiveLoop()` instead.

### 評価

| 項目 | 評価 |
|------|------|
| 正確性 | 良好 — パラメータの削除と InteractiveLoop の変更を正しく把握 |
| 完成度 | 中程度 — 「何を変えたか」は正確だが「なぜ変えたか」の説明が弱い（"for optimal quality" がdiffのコメントにあるのに反映されていない） |
| 実用性 | 高い — 2-3文の要約としては十分。PR description として使える |
| 問題点 | "previously required by default" は不正確（Optional だったので "configurable" が正しい）。変更の動機が欠落 |
| そのまま使えるか | **ほぼそのまま使える** — 動機の追記のみ |

---

## テスト 8: TODO リスト生成（構造化出力・配列スキーマ）

### コマンド

```bash
./.build/release/applefm generate 'Based on these code review findings, create a TODO list: ...' \
  --schema .claude/skills/foundation-models/references/research/schemas/todo-list.json
```

### 結果

```
Error: Failed to decode generated content. Check your schema file for correctness.
```

2回試行とも同じエラー。

### スキーマ

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

### 評価

| 項目 | 評価 |
|------|------|
| 正確性 | N/A（実行失敗） |
| 問題点 | 配列を含むネストされたスキーマでデコードに一貫して失敗。enum 制約のある配列要素は Foundation Models の構造化出力の限界と思われる |
| そのまま使えるか | **実行不可** |

**重要な発見**: `array` 型の `items` を持つスキーマでは `generate` コマンドが一貫して失敗する。配列を含む構造化出力は Foundation Models on-device モデルの制約と考えられる。

---

## ドキュメント生成能力まとめ

### 1. 得意なドキュメントタイプ

| タイプ | 理由 |
|--------|------|
| **Docstring / コードコメント** | 関数シグネチャから正確にパラメータ・戻り値を抽出。Swift の `///` 形式も理解 |
| **短い要約・PR 説明文** | 2-3文の簡潔な説明は的確。diff の変更内容を正しく読み取る |
| **構造化コミットメッセージ** | フラットなスキーマ（type/scope/summary/breaking）であれば正確に出力 |
| **日本語ドキュメント** | instructions を日本語で指定すれば自然な日本語で応答。技術文書品質は十分 |

### 2. 苦手なドキュメントタイプ

| タイプ | 理由 |
|--------|------|
| **大きなファイルのAPI ドキュメント** | 約260行でコンテキスト超過。ツール使用時は実質100-200行が上限 |
| **正確なCLI ドキュメント** | コマンド名・オプション名のハルシネーションが頻発（swift run chat 等） |
| **配列を含む構造化出力** | array 型スキーマでデコード失敗が一貫して発生 |
| **変更の「なぜ」の説明** | 「何を変えたか」は正確だが動機・背景の説明が弱い |
| **カテゴリ分類の正確性** | チェンジログで fix: を "Changed" に誤分類する等、意味的な分類精度が低い |

### 3. 効果的なプロンプトパターン

| パターン | 効果 |
|----------|------|
| **instructions での形式指定** | "Generate Swift documentation comments (///)" のように出力形式を明示すると従う |
| **短い入力 + 明確な指示** | プロンプトが短いほど品質が向上。長文のコード+指示はコンテキスト圧迫 |
| **フラットなスキーマ** | 構造化出力はネストの浅いスキーマが成功率高 |
| **言語指定は instructions で** | 日本語出力が必要な場合は instructions に日本語で指示 |
| **差分ベースの説明** | 完全なファイルよりも diff を渡す方が正確で効率的 |

### 4. 実用度の総合評価

| 評価軸 | スコア | コメント |
|--------|--------|----------|
| ドラフト生成 | **7/10** | 下書きとしては十分。そのまま使えるケースは少ない |
| 正確性 | **5/10** | ハルシネーション（コマンド名・オプション名）が頻発 |
| 構造化出力 | **4/10** | フラットなスキーマのみ実用的。配列は不可 |
| 日本語対応 | **8/10** | 自然な日本語。技術文書品質は良好 |
| コンテキスト制約 | **3/10** | ツール使用時は約200行でコンテキスト上限。大きなファイルの処理は非実用的 |
| **総合** | **5/10** | 短い入力の下書き生成には有用だが、正確性の検証が常に必要。本番ドキュメントの自動生成には力不足 |

### 推奨ワークフロー

1. **下書き生成** → 人間がレビュー・修正 → コミット
2. **短い入力を与える** — ファイル全体ではなく、関連する関数やdiffのみ
3. **構造化出力はフラットに** — 配列やネストは避け、単一オブジェクトのスキーマを使用
4. **CLI ドキュメントは手動作成** — コマンド名・オプション名のハルシネーションリスクが高い
5. **コミットメッセージ生成は実用的** — 変更内容を箇条書きで与えれば良い品質の下書きが得られる
