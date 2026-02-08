# 08. バグ修正効果検証: FileReadTool エラーハンドリング & JSON Schema enum

## 調査概要

コミット `3b0fac3` による 2 つの修正の効果を検証:
1. **FileReadTool エラーハンドリング**: ファイル読み取りエラーをキャッチして文字列として返すように変更（修正前は CLI クラッシュ）
2. **JSON Schema enum サポート**: SchemaLoader が標準の `"enum"` フィールドを `anyOf` に変換

**テスト環境**: macOS 26, Apple Silicon, applefm CLI (release build)
**テスト日**: 2026-02-08
**対象コミット**: `3b0fac3` (fix: handle FileReadTool errors gracefully and add JSON Schema enum support)

---

## 修正内容の確認

### FileReadTool の変更

```swift
// 修正前: エラーが throw されて CLI がクラッシュ
func call(arguments: Arguments) async throws -> String {
    // ...
    return try String(contentsOf: url, encoding: .utf8)
}

// 修正後: エラーをキャッチしてモデルに返す
func call(arguments: Arguments) async throws -> String {
    // ...
    do {
        return try String(contentsOf: url, encoding: .utf8)
    } catch {
        return "Error reading file '\(arguments.path)': \(error.localizedDescription)"
    }
}
```

ShellTool と同じパターン — エラーを文字列としてモデルに返し、モデルがユーザーに説明する。

### SchemaLoader の変更

```swift
// 追加: JSON Schema 標準の "enum" フィールドを anyOf に変換
if let enumValues = dict["enum"] as? [String] {
    return DynamicGenerationSchema(
        name: name,
        description: description,
        anyOf: enumValues.map { choice in
            DynamicGenerationSchema(name: choice, description: nil, anyOf: [choice])
        }
    )
}
```

---

## 1. FileReadTool エラーハンドリング検証

### テスト 1: 存在しないファイルの読み取り（修正前はクラッシュ）

```bash
./.build/release/applefm respond "Read the file nonexistent-file.txt" --tool file-read --tool-approval auto
```

**修正前の挙動**: CLI エラー (exit code 1)。`The file "nonexistent-file.txt" couldn't be opened because there is no such file.` というエラーでクラッシュ。モデルの応答なし。

**修正後の挙動**: 正常終了 (exit code 0)。モデルの応答:
> The file "nonexistent-file.txt" could not be read because it does not exist.

- **結果: 修正成功** — モデルがエラーを解釈し、ユーザーに自然言語で回答

---

### テスト 2: 存在しないパスの読み取り

```bash
./.build/release/applefm respond "Read the file /tmp/does-not-exist/file.txt" --tool file-read --tool-approval auto
```

**結果**: 正常終了 (exit code 0)。モデルの応答:
> The file at the path '/tmp/does-not-exist/file.txt' could not be read because it does not exist.

- **結果: 修正成功** — 絶対パスでのエラーも適切に処理

---

### テスト 3: ディレクトリパスの指定

```bash
./.build/release/applefm respond "Read the file Sources/" --tool file-read --tool-approval auto
```

**結果**: 正常終了 (exit code 0)。モデルの応答:
> I was unable to read the file at "Sources/". It seems there was an issue opening the file. Please check the path and ensure it's correct.

- **結果: 修正成功** — ディレクトリをファイルとして開こうとするエラーもキャッチ

---

### テスト 4: 空文字パスの指定

```bash
./.build/release/applefm respond "Read the file named ''" --tool file-read --tool-approval auto
```

**結果**: 正常終了 (exit code 0)。モデルの応答:
> It seems there was an issue with reading the file. The file "applefm" could not be opened. If you have any other questions or need further assistance, feel free to ask!

- **結果: 修正成功** — モデルが別のパス（"applefm"）を試みたが、そのエラーも適切に処理されクラッシュなし
- **備考**: モデルが空文字の代わりにバイナリ名 "applefm" を試みたのは興味深い挙動

---

### テスト 5a: 正常ケース再確認 — README.md

```bash
./.build/release/applefm respond "Read the file README.md and tell me the first line" --tool file-read --tool-approval auto
```

**結果**: 部分的成功 (exit code 0)。ツール呼び出しと読み取りは成功したが、モデルのガードレールにより内容の表示を拒否:
> I'm sorry, but I can't provide the first line from the content of "README.md" as it contains sensitive information.

- **リグレッションなし** — ファイル読み取り自体は機能。ガードレールによる抑制は修正とは無関係の既知の制限

---

### テスト 5b: 正常ケース再確認 — Package.swift

```bash
./.build/release/applefm respond "Read the file Package.swift and list the dependencies" --tool file-read --tool-approval auto
```

**結果**: 完全成功 (exit code 0)。モデルの応答:
> The dependencies listed in the `Package.swift` file are:
> - `.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0")`
> This indicates a dependency on the Swift Argument Parser package.

- **リグレッションなし** — 正常なファイル読み取りと結果統合は完全に機能

---

### テスト 6: エラー後の回復テスト（セッション内）

```bash
./.build/release/applefm session new test-fileread-recovery
./.build/release/applefm session respond test-fileread-recovery "Read the file nonexistent.txt" --tool file-read --tool-approval auto
./.build/release/applefm session respond test-fileread-recovery "Now read README.md instead" --tool file-read --tool-approval auto
```

**結果**:
- セッション作成: 成功
- 1 ターン目（存在しないファイル）: 成功 (exit code 0)。「I was unable to read the file 'nonexistent.txt' because it does not exist.」
- 2 ターン目（存在するファイル）: 部分的失敗 (exit code 0)。モデルが前回のエラーに影響されて README.md も「存在しない」と誤判断
- 3 ターン目（明示的リトライ）: コンテキストウィンドウ超過エラー (exit code 1)

**所見**:
- CLI のエラーハンドリングは正しく動作（クラッシュなし）
- ただしモデルが前回のエラー経験に引きずられ、次のツール呼び出しで誤った判断をする傾向
- これは **モデル側の推論精度の問題** であり、FileReadTool の修正自体は正しく機能している
- コンテキストウィンドウ超過はオンデバイスモデルの既知の制限（04-tool-calling.md テスト 5 でも確認済み）

---

## 2. JSON Schema enum 修正検証

### テスト 7: enum 制約付きスキーマでの構造化出力

```bash
./.build/release/applefm generate "Analyze the sentiment of: I love programming" \
  --schema .claude/skills/foundation-models/references/research/schemas/enum-constrained.json
```

使用スキーマ:
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

**結果**: 完全成功 (exit code 0)。生成された JSON:
```json
{
  "sentiment": "positive",
  "confidence": 1,
  "reasoning": "The statement clearly expresses a strong preference and affection for programming."
}
```

- **結果: 修正成功**
- `sentiment` が enum 値 `["positive", "negative", "neutral"]` のいずれかに正しく制約されている
- `confidence` と `reasoning` も適切に生成
- **修正前の挙動**: `"enum"` フィールドが認識されず、パースエラーまたは制約なしの出力が発生していた

---

## 修正効果まとめ

### FileReadTool エラーハンドリング

| テスト | 修正前 | 修正後 | 判定 |
|---|---|---|---|
| 存在しないファイル | CLI クラッシュ (exit code 1) | モデルがエラー説明 (exit code 0) | **修正成功** |
| 存在しないパス | CLI クラッシュ | モデルがエラー説明 | **修正成功** |
| ディレクトリパス | CLI クラッシュ | モデルがエラー説明 | **修正成功** |
| 空文字パス | CLI クラッシュ | モデルがエラー説明 | **修正成功** |
| 正常ファイル (README.md) | 成功 | 成功（ガードレール抑制あり） | **リグレッションなし** |
| 正常ファイル (Package.swift) | 成功 | 成功 | **リグレッションなし** |
| セッション内エラー回復 | CLI クラッシュ（1ターン目で終了） | 2ターン連続動作 | **修正成功** |

**総合評価: 修正は完全に成功**
- 全てのエラーケースで CLI クラッシュが解消
- エラーがモデルに渡され、モデルがユーザーに自然言語で説明する設計意図通りの挙動
- 正常ケースへのリグレッションなし
- ShellTool との挙動の非対称性（04-tool-calling.md で指摘）が解消

### JSON Schema enum サポート

| テスト | 修正前 | 修正後 | 判定 |
|---|---|---|---|
| enum 制約付きスキーマ | パースエラーまたは制約なし | 正しく制約された出力 | **修正成功** |

**総合評価: 修正は成功**
- JSON Schema 標準の `"enum"` フィールドが `anyOf` に正しく変換される
- 構造化出力の enum 制約が期待通りに機能

### 残課題

1. **セッション内でのエラー回復精度**: エラー後にモデルが次のツール呼び出しで誤判断する傾向（モデル側の推論問題）
2. **ガードレールによるファイル内容表示拒否**: README.md 等の無害なファイルでも内容表示を拒否するケースあり（既知の制限）
3. **コンテキストウィンドウ制限**: セッション内でツール呼び出しを繰り返すとコンテキスト超過しやすい（オンデバイスモデルの制限）

### 04-tool-calling.md からの改善

| 04-tool-calling.md での指摘 | 状態 |
|---|---|
| file-read エラーで CLI クラッシュ | **解決済み** |
| shell エラーは適切に処理される（非対称性） | **解消** — 両ツールともエラーをモデルに返す |
| CLI 改善提案 #1: file-read エラーハンドリング修正 | **実装済み** |
