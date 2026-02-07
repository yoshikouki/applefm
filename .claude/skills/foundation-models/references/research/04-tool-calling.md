# 04. ツール呼び出し (Tool Calling) の精度調査

## 調査概要

Apple Foundation Models のオンデバイス LLM がツール呼び出し機能をどの程度正確に利用できるかを調査。`file-read` および `shell` ツールを対象に、呼び出し判断・引数精度・結果統合・エラーハンドリングを検証した。

**テスト環境**: macOS 26, Apple Silicon, applefm CLI (release build)
**テスト日**: 2026-02-08

---

## 1. file-read ツール基本テスト

### テスト 1a: README.md の読み取りと要約
```bash
./.build/release/applefm respond "Read the file README.md and summarize its contents" --tool file-read --tool-approval auto
```
**結果**: 成功。ツールを正しく呼び出し、README.md の内容を詳細に要約。セクション構成・主要機能・インストール方法など網羅的にカバー。
- ツール呼び出し判断: 適切
- 引数精度: 正確 (パス "README.md")
- 結果活用: 良好 — 読み取り内容を構造的に要約

### テスト 1b: Package.swift の内容確認
```bash
./.build/release/applefm respond "What does the Package.swift file contain?" --tool file-read --tool-approval auto
```
**結果**: 失敗。ツールを呼び出さず「ファイル I/O 機能がない」と回答。
- ツール呼び出し判断: **不適切** — ツールが利用可能にもかかわらず呼び出さなかった
- 原因推測: "Read the file" という明示的な指示がないと呼び出しトリガーが弱い

### テスト 1c: CLAUDE.md の読み取りとセクション一覧
```bash
./.build/release/applefm respond "Read the CLAUDE.md file and list the main sections" --tool file-read --tool-approval auto
```
**結果**: 成功。ツールを呼び出し、11 セクションを正確に列挙。
- ツール呼び出し判断: 適切
- 引数精度: 正確
- 結果活用: 良好

### file-read 基本テスト所見
- "Read the file X" パターンでは安定してツールを呼び出す
- "What does X contain?" のような間接的表現ではツールを呼び出さない場合がある
- **明示的な指示がツール呼び出しの信頼性を大幅に向上させる**

---

## 2. shell ツール基本テスト

### テスト 2a: カレントディレクトリのファイル一覧
```bash
./.build/release/applefm respond "What files are in the current directory?" --tool shell --tool-approval auto
```
**結果**: 成功。`ls` 相当のコマンドを実行し、ファイル一覧を正確に列挙。
- ツール呼び出し判断: 適切
- 引数精度: 正確
- 結果活用: 良好

### テスト 2b: Swift ファイル数のカウント
```bash
./.build/release/applefm respond "How many Swift files are in this project?" --tool shell --tool-approval auto
```
**結果**: 失敗。「Swift パッケージの初期化に問題がある」というエラーメッセージを返した。
- ツール呼び出し判断: 試みたが不適切なコマンドを実行した可能性
- 引数精度: **不正確** — `swift` コマンド関連を実行した模様（`find` や `wc` ではなく）

### テスト 2c: 現在の日時
```bash
./.build/release/applefm respond "What is the current date and time?" --tool shell --tool-approval auto
```
**結果**: 失敗。「不正な時刻フォーマット」エラー。ツールは呼び出したが不正確な引数を渡した。
- ツール呼び出し判断: 適切
- 引数精度: **不正確** — date コマンドのフォーマット指定に問題

### shell 基本テスト所見
- 簡単なファイル一覧は成功するが、やや複雑なコマンド（パイプ、特定フォーマット）では失敗しやすい
- モデルがシェルコマンドの正確な構文を十分に把握していない可能性

---

## 3. ツール呼び出し判断テスト（呼ぶべきでないケース）

### テスト 3a: 単純な計算
```bash
./.build/release/applefm respond "What is 2 + 2?" --tool file-read --tool shell --tool-approval auto
```
**結果**: 部分的失敗。shell ツールで `2 + 2` を実行しようとして失敗した後、自力で「4」と回答。
- ツール呼び出し判断: **不適切** — ツールが不要な場面で呼び出した
- 最終結果: 正しい答えは出力されたが、不要なツール呼び出しが先行

### テスト 3b: 俳句の作成
```bash
./.build/release/applefm respond "Write a haiku about spring" --tool file-read --tool shell --tool-approval auto
```
**結果**: エラー (exit code 1)。`FoundationModels.LanguageModelSession.GenerationError error -1` で失敗。
- ツール呼び出し判断: 不明（エラーにより判断不能）
- 備考: ツールが利用可能な場合に創作タスクで安全フィルタに抵触した可能性

### 判断テスト所見
- ツールが不要な場面でも呼び出しを試みる傾向がある（false positive）
- ツール使用の「抑制」判断が弱い

---

## 4. 複数ツールの使い分けテスト

### テスト 4a: README.md の読み取りと行数カウント
```bash
./.build/release/applefm respond "Read README.md and count how many lines it has" --tool file-read --tool shell --tool-approval auto
```
**結果**: 成功。file-read で内容を読み取り、268 行と正確に回答。
- ツール使い分け: 良好
- 精度: **正確** — 実際の行数 268 と一致

### テスト 4b: Swift ファイル一覧と Package.swift の読み取り
```bash
./.build/release/applefm respond "List all Swift files and then read the contents of Package.swift" --tool file-read --tool shell --tool-approval auto
```
**結果**: 部分的成功。Swift ファイル一覧は失敗（shell コマンド不適切）だが Package.swift の読み取りは成功。
- ツール使い分け: file-read は正確、shell は不安定
- 結果活用: Package.swift の内容は正確に表示

### 複数ツール所見
- file-read は一貫して安定
- shell との組み合わせでは shell 側の失敗が目立つ
- 2 つのツールを連続して使う能力はある

---

## 5. ツール結果の統合テスト

### テスト 5: Package.swift の依存関係説明
```bash
./.build/release/applefm respond "Read Package.swift and explain what dependencies this project uses" --tool file-read --tool-approval auto
```
**結果**: 成功。file-read で Package.swift を読み取り、`swift-argument-parser` 依存関係を正確に特定・説明。
- ツール呼び出し: 適切
- 結果統合: 優秀 — 技術的な文脈を正確に解釈し、依存関係の目的まで説明

---

## 6. エラーハンドリングテスト

### テスト 6a: 存在しないファイルの読み取り
```bash
./.build/release/applefm respond "Read the file nonexistent-file.txt" --tool file-read --tool-approval auto
```
**結果**: CLI エラー (exit code 1)。エラーメッセージ: `The file "nonexistent-file.txt" couldn't be opened because there is no such file.`
- ツール呼び出し: 適切（ファイル名も正確）
- エラー処理: **CLI レベルでクラッシュ** — ツールエラーがモデルに返されず CLI が終了してしまう
- 問題点: モデルがエラーを受け取って「ファイルが見つかりません」と回答する方が望ましい

### テスト 6b: 存在しないコマンドの実行
```bash
./.build/release/applefm respond "Run the command that-doesnt-exist" --tool shell --tool-approval auto
```
**結果**: 成功。shell ツールがエラーを返し、モデルが「コマンドが見つからなかった」と適切に回答。
- ツール呼び出し: 適切
- エラー処理: **適切** — エラーをモデルが解釈して自然言語で説明

### エラーハンドリング所見
- shell ツールのエラーは適切に処理される（モデルに返される）
- **file-read ツールのエラーは CLI レベルでクラッシュする（重大な問題）** — ツールエラーがモデルに伝搬されず、ユーザーにスタックトレースが表示される

---

## 7. 日本語でのツール呼び出しテスト

### テスト 7a: README.md の要約（日本語プロンプト）
```bash
./.build/release/applefm respond "README.mdの内容を読んで要約してください" --tool file-read --tool-approval auto
```
**結果**: 成功。ツールを正しく呼び出し、英語で要約を返した。
- ツール呼び出し判断: 適切
- 引数精度: 正確
- 注意: 日本語でプロンプトしても回答は英語

### テスト 7b: Swift ファイル数カウント（日本語プロンプト）
```bash
./.build/release/applefm respond "このプロジェクトのSwiftファイルの数を教えてください" --tool shell --tool-approval auto
```
**結果**: 失敗。日本語で「確認できませんでした。エラーが発生しました。」と回答。
- ツール呼び出し判断: 試みたが shell コマンドが失敗
- 英語テスト 2b と同じ問題パターン

### 日本語テスト所見
- 日本語プロンプトでもツール呼び出し自体は発動する
- file-read は日本語プロンプトでも安定
- shell は言語に関係なく不安定

---

## 8. 追加テスト

### テスト 8a: 明示的なコマンド指定
```bash
./.build/release/applefm respond "Use the shell to run: find . -name '*.swift' | wc -l" --tool shell --tool-approval auto
```
**結果**: 成功。380（`.build` 含む）と回答。明示的にコマンドを指定すれば正確に実行できる。

### テスト 8b: 明示的なツール名指定
```bash
./.build/release/applefm respond "Use the file_read tool to read Package.swift" --tool file-read --tool-approval auto
```
**結果**: 成功。テスト 1b（失敗）と異なり、ツール名を明示すると確実に呼び出す。

### テスト 8c: 明示的な date コマンド指定
```bash
./.build/release/applefm respond "What is the current date and time? Use the shell tool to run the date command." --tool shell --tool-approval auto
```
**結果**: 成功。「February 8, 2026, at 00:50:45 JST」と正確に回答。テスト 2c（失敗）と異なり、具体的指示で成功。

### テスト 8d: パイプ付きコマンド
```bash
./.build/release/applefm respond "Run the command 'echo hello && ls -la | head -3'" --tool shell --tool-approval auto
```
**結果**: 成功。パイプ・チェインコマンドも正確に実行。

### テスト 8e: ネストパスのファイル読み取り
```bash
./.build/release/applefm respond "Read the file Sources/AppleFMCore/Commands/RespondCommand.swift and explain what it does" --tool file-read --tool-approval auto
```
**結果**: 成功。深いパスのファイルも正確に読み取り、コードの機能を詳細に説明。

### テスト 8f: ツール結果の分析精度
```bash
./.build/release/applefm respond "Read the file README.md and count the number of headings that start with ##" --tool file-read --tool-approval auto
```
**結果**: 部分的成功。ツール呼び出しは成功したが `##` ヘッディング数を「16」と回答（実際は 14）。
- **ツール結果の分析精度に課題** — 読み取ったテキストの正確なカウントが苦手

---

## 精度サマリー

| テストカテゴリ | テスト数 | 成功 | 部分的成功 | 失敗 | 成功率 |
|---|---|---|---|---|---|
| file-read 基本 | 3 | 2 | 0 | 1 | 67% |
| shell 基本 | 3 | 1 | 0 | 2 | 33% |
| 不要な呼び出し抑制 | 2 | 0 | 1 | 1 | 0% |
| 複数ツール連携 | 2 | 1 | 1 | 0 | 50% |
| 結果統合 | 1 | 1 | 0 | 0 | 100% |
| エラーハンドリング | 2 | 1 | 0 | 1 | 50% |
| 日本語プロンプト | 2 | 1 | 0 | 1 | 50% |
| 追加（明示的指示） | 6 | 5 | 1 | 0 | 83% |
| **合計** | **21** | **12** | **3** | **6** | **57%** |

---

## ツール呼び出しガイドライン

### 所見

1. **file-read は shell より格段に安定**
   - file-read: 成功率約 80%（明示的指示含む）
   - shell: 暗黙的なコマンド生成は不安定、明示的指示で大幅改善

2. **明示的な指示が精度を劇的に向上させる**
   - "What does X contain?" → ツール呼び出しなし（失敗）
   - "Read the file X" → ツール呼び出し成功
   - "Use the shell to run: [command]" → 正確に実行
   - 暗黙的ツール選択は信頼性が低い

3. **shell コマンドの自動生成は不安定**
   - モデルが独自にシェルコマンドを構成すると、不適切なコマンドや構文エラーが発生
   - 特に `find`, `wc`, `date` のフォーマット指定で失敗しやすい

4. **不要なツール呼び出しの抑制が弱い**
   - ツールが利用可能な場合、不要な場面でも呼び出しを試みる傾向

5. **エラー伝搬の非対称性**
   - shell ツールのエラーはモデルに適切に返される
   - file-read ツールのエラーは CLI クラッシュを引き起こす（バグ）

6. **ツール結果の分析精度に限界**
   - 読み取った内容の要約は得意
   - 正確なカウント（行数やパターン数）はやや不正確

### 推奨プロンプトパターン

#### file-read ツール
```
# 良いパターン（高信頼性）
"Read the file {path} and ..."
"Use the file_read tool to read {path}"

# 避けるべきパターン（低信頼性）
"What does {path} contain?"
"Show me {path}"
```

#### shell ツール
```
# 良いパターン（高信頼性）
"Use the shell to run: {exact_command}"
"Run the command '{exact_command}'"

# 避けるべきパターン（低信頼性）
"How many X files are there?" (コマンド構成をモデルに任せる)
"What is the current date?" (暗黙的なコマンド生成)
```

### CLI 改善提案

1. **file-read エラーハンドリング修正**: ツールエラーをモデルに返す処理を追加し、CLI クラッシュを防ぐ
2. **ツール使用の system instructions 追加**: ツール使用の判断基準をモデルに instructions で明示する
3. **ツール呼び出し結果のログ出力**: `--format json` でツール呼び出しの詳細（引数、結果）を出力可能にする

### セッション利用時の注意事項

- ツール呼び出しの精度はプロンプトの明示性に大きく依存する
- shell ツールを使う場合は、実行したいコマンドをプロンプトに直接含める
- ファイル読み取りには "Read the file" で始めるパターンが最も安定
- ツールが不要な質問では `--tool` フラグを省略することを推奨
