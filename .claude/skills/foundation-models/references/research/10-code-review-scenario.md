# 10. 実用シナリオ: コードレビュー・説明能力

## 概要

Apple Foundation Models のコードレビュー・コード説明能力を、実際のプロジェクトソースコードと合成コード片の両方を使って評価した。file-read ツール連携、バグ発見、diff 解釈、複数ファイル横断レビュー、日本語レビューなど7つのシナリオをテスト。

---

## テスト1: ソースコード説明（RespondCommand.swift）

### コマンド
```bash
./.build/release/applefm respond "Read the file Sources/AppleFMCore/Commands/RespondCommand.swift and explain what this command does, its main options, and how it works" \
  --tool file-read --tool-approval auto \
  --instructions "You are a code reviewer. Be concise and focus on architecture."
```

### 出力
```
The `RespondCommand` in AppleFMCore is a Swift command designed to create a temporary session for language model interactions. Here's a summary of its functionality, options, and architecture:

### Functionality
- **Purpose**: The command is intended to handle one-shot responses using a language model, creating a temporary session.
- **Interaction Model**: It operates in interactive mode if no prompt or file is provided and the terminal is tty-like. Otherwise, it creates a session based on model and tool configurations.

### Main Options
- **Prompt**: An optional string for the initial prompt text.
- **File**: A string path to read a prompt from a file.
- **Instructions**: A string for system instructions to be used in the session.
- **Generation Options**: Includes various options for adjusting the generation process.
- **Model Options**: Defines the language model to be used.
- **Tool Options**: Provides additional tools for interaction.
- **Stream**: A boolean flag to stream responses incrementally (not compatible with JSON format).
- **Format**: An option to specify the output format (default is text, but can be JSON).

### Architecture
- **Command Structure**: The command uses `ArgumentParser` for parsing command-line arguments, and it is defined as an `AsyncParsableCommand` for asynchronous handling.
- **Validation**: The `validate` method checks constraints, such as the incompatibility of `--stream` and `--format json`.
- **Execution Flow**:
  - **Interactive Mode**: If no prompt or file is provided and the terminal is tty-like, it enters interactive mode with default instructions and a model.
  - **Session Creation**: If interactive mode is not suitable, it creates a session using the specified model and tools.
  - **Response Handling**:
    - **Stream Mode**: Uses a stream response mechanism.
    - **Non-Stream Mode**: Produces and prints the response to the console.
- **Environment Setup**: Utilizes `SettingsStore` for loading environment settings and `SessionStore` for managing session metadata and transcripts.

This command encapsulates a flexible and configurable language model interaction session, with clear separation of concerns across different options and execution paths.
```

### 評価

| 観点 | 評価 | コメント |
|------|------|---------|
| 正確性 | A | ファイルを正しく読み取り、コマンドの目的・オプション・実行フローを正確に説明 |
| 網羅性 | A | 主要オプション、バリデーション、インタラクティブモード分岐などを網羅 |
| 実用性 | A | 新しい開発者がコードを理解するのに十分な説明 |
| 構造化 | A | Markdown見出しでセクション分け。読みやすい |

**総合: A** — file-read ツールとの連携でソースコードを正確に読み取り、構造的な説明を生成。

---

## テスト2: 複雑なコードの設計パターン説明（InteractiveLoop.swift）

### コマンド
```bash
./.build/release/applefm respond "Read the file Sources/AppleFMCore/Interactive/InteractiveLoop.swift and explain the main design patterns used, dependency injection points, and error handling strategy" \
  --tool file-read --tool-approval auto \
  --instructions "You are a senior Swift developer reviewing code. Focus on design patterns and architectural decisions."
```

### 出力
```
The Swift code defines a `InteractiveLoop` struct, which implements an interactive command-line interface using dependency injection (DI) to enhance testability. Here's a breakdown of its main design patterns, dependency injection points, and error handling strategy:

### Design Patterns
1. **Command-Line Interface (CLI):**
   - The `InteractiveLoop` struct provides a CLI that listens for user input and processes it in real-time.
2. **Asynchronous Programming:**
   - Utilizes `async` and `await` to handle asynchronous operations.
3. **Modular Design:**
   - Decouples the interaction logic from the session management and logging.

### Dependency Injection Points
1. **Input Handling:** `readInput` is injected via a dependency parameter.
2. **Stderr Output:** `writeStderr` is also injected.
3. **Session Management:** The `run` method depends on `session`, `sessionName`, `store`, `options`, and `settings`.

### Error Handling Strategy
1. **Graceful Exit:** The loop exits gracefully upon receiving a '/quit' command or encountering an EOF.
2. **Logging Errors:** Errors are logged using `SessionLogger`.
3. **Centralized Error Handling:** Errors are caught within the `run` method and wrapped in an `AppError.generationError`.
```

### 評価

| 観点 | 評価 | コメント |
|------|------|---------|
| 正確性 | B+ | DI ポイント（readInput, writeStderr）を正しく特定。ただし「CLI」をデザインパターンとして挙げるのは不適切 |
| 網羅性 | B | REPL ループパターン、ResponseStreamer との連携、HistoryStore/SessionLogger の二重ロギングなどへの言及が薄い |
| 深さ | B- | 「シニア開発者」としての洞察がやや浅い。パターン名の列挙に留まり、なぜそのパターンが選ばれたかの考察がない |
| 実用性 | B | 概要把握には十分だが、コードレビューとしての改善提案がない |

**総合: B** — DI ポイントの特定は正確だが、シニアレベルの深い分析には至っていない。

---

## テスト3: コード改善提案（FileReadTool.swift）

### コマンド
```bash
./.build/release/applefm respond "Read the file Sources/AppleFMCore/Tools/FileReadTool.swift and suggest improvements for error handling, security, and code quality" \
  --tool file-read --tool-approval auto \
  --instructions "You are a security-focused code reviewer. Identify potential issues and suggest improvements."
```

### 出力（要約）
改善提案として以下を提示:
1. **エラーハンドリング**: `URLError` などの特定エラーの処理
2. **セキュリティ**: センシティブパス（`.ssh/`, `.gnupg/`, `.env` 等）へのアクセス制御
3. **コード品質**: 変数名の改善

具体的なコード例も提示:
```swift
private static let sensitivePaths = [".ssh/", ".gnupg/", ".env", ".netrc", ".aws/", ".kube/config"]

if Self.sensitivePaths.contains(where: { arguments.path.contains($0) }) {
    return "Access denied for sensitive path."
}
```

### 評価

| 観点 | 評価 | コメント |
|------|------|---------|
| 正確性 | B+ | セキュリティ観点のセンシティブパスチェックは妥当。ただし提案コードに `ToolApproval()` のデフォルトイニシャライザなど元コードにない構造を含む |
| 具体性 | A | 改善コード全体を提示。即座に適用可能なレベル |
| セキュリティ深度 | B | パストラバーサル攻撃（`../` を使ったディレクトリ脱出）への言及がない。ファイルサイズ制限への言及もない |
| 実用性 | B+ | 提案自体は実用的だが、一部の提案（URLError ハンドリング）はローカルファイル読み取りには不要 |

**総合: B+** — セキュリティ改善提案は具体的で実用的。ただし高度な攻撃ベクタへの考慮が不足。

---

## テスト4: バグ発見能力テスト（インラインコード）

### コマンド
```bash
./.build/release/applefm respond 'Review this Swift code for bugs: [3つのバグ入り関数]' \
  --instructions "You are a code reviewer. Find all bugs in the code and explain each one."
```

### 出力
```
Here are the bugs found in the code:

1. **Function `fibonacci`:**
   - **Bug:** The function `fibonacci` returns `a` instead of `b`.
   - **Explanation:** In the Fibonacci sequence, `b` represents the next Fibonacci number, and it should be returned.

2. **Function `safeDivide`:**
   - **Bug:** There is no check for division by zero.
   - **Explanation:** The function `safeDivide` does not handle the case where `b` is zero, which will lead to undefined behavior.

3. **Function `findMax`:**
   - **Bug:** The initial value of `max` is set to `0`, which might not be the maximum possible value.
   - **Explanation:** It's better to initialize `max` with `Int.min`.
```

### 評価

| 観点 | 評価 | コメント |
|------|------|---------|
| 検出率 | A | 3/3 のバグをすべて検出 |
| 説明精度 | A- | 各バグの原因と修正方法を正しく説明。ただし `safeDivide` で Swift の Double 除算は実際には `inf` を返す（クラッシュではない）という点の言及なし |
| 誤検出 | A | 偽陽性なし |
| 修正提案 | B | 修正コードの提示がない（説明のみ） |

**総合: A-** — 全バグを正確に検出。バグ検出タスクに非常に強い。

---

## テスト5: diff の解釈テスト

### コマンド
```bash
./.build/release/applefm respond 'Review this git diff and explain what changed and why: [FileReadTool の diff]' \
  --instructions "You are a code reviewer. Explain what this diff does, why it was made, and if the approach is correct."
```

### 出力
```
#### Changes Made:
1. Added a `do-catch` block around the `Data(contentsOf: url)` call.
2. Returned an error message if the file reading fails.

#### Why Was This Made:
1. **Error Handling**: By wrapping the file reading in a `do-catch` block, we can handle potential errors more gracefully.
2. **Improved Robustness**: This approach makes the code more robust and user-friendly.

#### Correctness of the Approach:
- **Correct**: The use of a `do-catch` block is a good practice for handling errors in Swift.
- **Potential Improvements**: Consider adding more specific error handling for different types of errors.
```

### 評価

| 観点 | 評価 | コメント |
|------|------|---------|
| 変更内容の理解 | A | do-catch ブロックの追加を正確に識別 |
| 変更理由の推論 | A- | エラーハンドリング改善という意図を正しく推論 |
| 批判的評価 | B | 「throws を使わずに文字列でエラーを返すことの是非」への言及がない。Tool プロトコルの制約を考慮した評価がない |
| 改善提案 | B- | 「特定エラーの分別処理」は妥当だが具体性に欠ける |

**総合: B+** — diff の内容と意図は正確に把握。批判的レビュー能力はやや弱い。

---

## テスト6: 複数ファイルの関係理解（セッション）

### コマンド
```bash
./.build/release/applefm session new code-review-session --instructions "You are a senior Swift developer doing a code review."
./.build/release/applefm session respond code-review-session "Read the file Sources/AppleFMCore/Schema/SchemaLoader.swift" --tool file-read --tool-approval auto
./.build/release/applefm session respond code-review-session "Now read Tests/AppleFMTests/SchemaLoaderTests.swift and tell me if the tests adequately cover the SchemaLoader functionality" --tool file-read --tool-approval auto
```

### 結果

**1回目の応答（SchemaLoader.swift 読み取り）**: 成功。ファイル内容を正しく読み取り表示。

**2回目の応答（テストファイル読み取り）**: **失敗**
```
Error: Context window exceeded. Start a new session or reduce prompt size.
```

**重要な発見**: セッション内でファイル読み取りツールを使うと、ファイル内容がセッションのトランスクリプトに蓄積され、2ファイル目の読み取り時点でコンテキストウィンドウを超過する。Foundation Models のオンデバイスモデルのコンテキスト長制限が直接影響。

### 代替アプローチ（ワンショット）
```bash
./.build/release/applefm respond "Read the file Tests/AppleFMTests/SchemaLoaderTests.swift and evaluate whether the tests adequately cover JSON schema loading, error cases, and edge cases for a SchemaLoader component" \
  --tool file-read --tool-approval auto \
  --instructions "You are a senior Swift developer. Evaluate test coverage completeness."
```

**ワンショットでの結果**: 成功。テストカバレッジを評価し、ハッピーパス（10テスト）、エラーパス（4テスト）、エッジケース（7テスト）にカテゴリ分けして説明。

### 評価

| 観点 | 評価 | コメント |
|------|------|---------|
| セッション方式 | F | 2ファイル目でコンテキスト超過。複数ファイル横断レビューはセッション方式では不可能 |
| ワンショット方式 | B+ | 単一ファイルのテストカバレッジ評価は的確。ただし実装コードとの対比ができない |
| テスト評価の深さ | B | テストケースの列挙は正確だが「不足しているテスト」の指摘がない。結論が楽観的すぎる |

**総合: C+** — オンデバイスモデルのコンテキスト制限が致命的。複数ファイル横断レビューは現実的に困難。

---

## テスト7: 日本語でのコードレビュー

### コマンド
```bash
./.build/release/applefm respond "Read the file Sources/AppleFMCore/Config/SettingsStore.swift and provide a code review in Japanese" \
  --tool file-read --tool-approval auto \
  --instructions "日本語でコードレビューを行ってください。エラーハンドリング、データ永続化、セキュリティの観点からレビューしてください。" \
  --guardrails permissive
```

**注意**: 最初の実行では誤ったファイルパス（`Settings/SettingsStore.swift`）でファイルが見つからず失敗。正しいパス（`Config/SettingsStore.swift`）に修正して再実行で成功。

### 出力（要約）

日本語で構造化されたレビューを提供:

**エラーハンドリング**:
- ファイル読み込み時の `Settings()` フォールバック評価
- `save()` の JSON エンコーディングエラー処理の不足を指摘
- `ensureDirectoryExists()` のエラー処理欠如を指摘

**データ永続化**:
- `~/.applefm/settings.json` パス設計の評価
- `.atomic` オプション使用の評価（正しい指摘）
- JSON 形式の利点と欠点

**セキュリティ**:
- `0o700` パーミッション設定の評価
- ファイルパスに関する考察

### 評価

| 観点 | 評価 | コメント |
|------|------|---------|
| 日本語品質 | B+ | 自然な日本語で読みやすい。技術用語の使い方も適切 |
| 正確性 | B- | `.atomic` 書き込みの指摘は正確。ただし「`.applefm` という拡張子」という誤解あり（これはディレクトリ名であって拡張子ではない） |
| セキュリティ深度 | C+ | `0o700` を「一般的なユーザーは読み書きが可能」と表現するのは不正確（オーナーのみ）。`0o400` への変更提案は保存ファイルには不適切（書き込みが必要） |
| 改善提案の妥当性 | B- | 一部の提案（パスの拡張子非使用）が的外れ。`save()` のエラーハンドリング強化は妥当 |

**総合: B-** — 日本語での構造化レビューは実用的だが、技術的な誤りがいくつか含まれる。`--guardrails permissive` の効果でフィルタリングされずに出力された点は良好。

---

## テスト結果サマリー

| テスト | 内容 | 総合評価 | ツール使用 |
|--------|------|----------|-----------|
| 1 | ソースコード説明 | A | file-read |
| 2 | 設計パターン説明 | B | file-read |
| 3 | コード改善提案 | B+ | file-read |
| 4 | バグ発見 | A- | なし |
| 5 | diff 解釈 | B+ | なし |
| 6 | 複数ファイル横断 | C+ | file-read (セッション超過) |
| 7 | 日本語レビュー | B- | file-read + permissive |

---

## コードレビュー能力まとめ

### 1. 強み（得意なレビュー観点）

- **バグ検出**: 明示的なバグ（off-by-one、ゼロチェック欠如、初期値ミス）をほぼ100%検出。偽陽性も少ない
- **コード構造の説明**: ファイル単位でのアーキテクチャ説明が非常に正確。新しい開発者のオンボーディングに有用
- **diff の意図推論**: 変更の「何」と「なぜ」を正しく識別できる
- **構造化出力**: Markdown ヘッダーで自動的にセクション分けし、読みやすいレビューを生成
- **セキュリティ観点の提案**: センシティブパスチェックなど、具体的なコード例を含む改善提案を生成

### 2. 弱み（見落としがちな点）

- **コンテキスト制限**: 複数ファイル横断レビューはセッション方式で2ファイル目の読み取り時にコンテキスト超過。これが最大の制約
- **深い批判的分析**: 「なぜこの設計が選ばれたか」「より良い代替案は何か」といった高度な考察が弱い
- **技術的精度のムラ**: Unix パーミッションの説明（0o700 の意味）など、OS レベルの技術的正確性にブレがある
- **不足テストの指摘能力**: テストカバレッジ評価時に「何がテストされていないか」の指摘が弱く、楽観的な結論になりがち
- **ファイルパス推論の限界**: LLM がプロンプト内のパスを解釈してツールに渡す際、プロジェクト構造を把握していないため誤パスでの失敗が起こりうる

### 3. 効果的なプロンプトパターン

| パターン | 効果 | 推奨度 |
|----------|------|--------|
| `--instructions "You are a code reviewer."` + 具体的な観点指定 | レビュー観点のフォーカスに効果的 | 高 |
| `--instructions` で日本語指定 + `--guardrails permissive` | 日本語レビュー生成の安定性向上 | 高 |
| file-read ツール + ワンショット | 単一ファイルのレビューに最適 | 高 |
| セッション + 複数 file-read | コンテキスト超過リスク大 | 低（非推奨） |
| インラインコードのバグ発見 | ツール不要で高精度 | 非常に高 |
| diff のレビュー | 変更の「何」と「なぜ」を推論 | 高 |

### 4. 実用度の総合評価

**総合評価: B**

| カテゴリ | 評価 | 実用性 |
|----------|------|--------|
| 単一ファイルの説明・レビュー | A | 即座に実用可能。新メンバーオンボーディングに最適 |
| バグ検出（インラインコード） | A- | 明示的バグの検出に優秀。ペアプログラミングの補助に |
| セキュリティレビュー | B+ | 基本的な脆弱性指摘は可能。高度な攻撃ベクタは見落とす |
| diff レビュー | B+ | 変更内容の説明は正確。PR レビューの下書きに有用 |
| 複数ファイル横断レビュー | D | コンテキスト制限により現実的に不可能。最大の弱点 |
| 日本語レビュー | B- | 自然な日本語だが技術的精度にムラ。確認が必要 |

**主な制約と推奨事項**:
- コンテキストウィンドウの制限により、大きなファイルや複数ファイルの横断レビューは困難。1ファイル単位でのワンショットレビューを推奨
- レビュー結果は「たたき台」として使い、人間の確認を前提とすべき（技術的精度にムラがあるため）
- `--instructions` でレビュー観点を明示的に指定すると、焦点の合ったレビューが得られる
- バグ検出タスク（インラインコードを直接渡す形式）は最も信頼性が高いユースケース
