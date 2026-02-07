## **背景**

Apple の Foundation Models（FoundationModels framework）を macOS で気軽に使える CLI ツール **`applefm`** を作りたい。

現時点では Foundation Models のAPI理解（できる/できない・概念・型・呼び出し構造）をまず上げたい。

その上で、**CLIのサブコマンドは可能な限り公式APIの概念/命名に寄せたい**。

## **ゴール（重要）**

- `applefm` の **v1.0.0** ゴールは「Foundation Models framework が提供する全機能を、薄いラッパーとして CLI から利用可能にする」こと。
- `serve`（HTTPサーバ化）は **後回し**。1.0.0には入れない。
- “respond は session に紐づくか？”のような疑問を含め、まずは **公式ドキュメント/サンプルコードの事実**を収集して確度を上げる。

## 進め方（タスク）

※ 必要やタスクの性質に応じて、Agent Teams や複数 Sub-agent の活用も判断せよ

1. **公式APIの表面積（surface area）を整理**せよ
    - 結果は Agent Skills として `./.claude/skills/foundation-models/` に集約する
    - xcode MCP の DocumentationSearch や公式ドキュメント https://developer.apple.com/documentation/foundationmodels を出典とする
    - FoundationModels framework の主要型と責務を列挙
        
        例：`SystemLanguageModel`, `LanguageModelSession`, `Tool`, `Instructions`, `Transcript`, `GenerationOptions`, `GenerationSchema` / `Generable`, availability周り、streaming周り etc.
        
    - 「何が必ず Session に紐づくか（respond/stream/generate/tools/instructions/transcript）」を明確化
    - “ガードレールは無効化できるか”や、availabilityの理由なども確認
2. 上記を踏まえ、**CLIサブコマンド設計案を作る**（公式APIに寄せる）
    - 1.0.0のコマンドツリー案を提案し、根拠として「公式APIの型/メソッド名との対応」を説明すること
    - respondはsessionが必須なら、CLIでも `session respond` を基本にする（単発aliasは後回しでも良い）
3. セキュリティ/安全性の基本方針を決める ✅ **実装済み**
    - ツール呼び出しはデフォルトで **ask（確認）**。`--tool-approval auto` は明示しない限りONにしない → **ToolApproval 実装済み**
    - セッション名バリデーション（パストラバーサル防止）→ **SessionStore.validateSessionName 実装済み**
    - ログは `~/.applefm/` に保存する → **SessionStore でセッション永続化済み**
    - transcript保存やログの扱いも検討 → **Transcript 永続化済み**
4. 実装の最小骨組み（Swift Package + ArgumentParser）を提示
    - いきなり全部実装ではなく、1.0.0に向けて “積み上げ可能” な構造を作る
    - コマンド定義、共通オプション（GenerationOptions相当）、Sessionの永続化（名前→ファイル）などの設計を出す
5. Coding Agent 自身がテスト・分析できる基盤を作る
    - macOS Tahoe 26.2 以上が必須でも構わないので、Foundation Models を使ってテスト、検証ができるようにする
    - Coding Agent 自身が観測・実行・改善のループを行えるようにする

## 期待するアウトプット（形式）

- `.claude/skills/foundation-models/`：
    - 公式APIのドキュメンテーションと理解
    - “respondはsession必須か”などの結論（根拠付き）
    - availability / guardrails / tools / guided generation / stream のメモ
- `docs/cli-design.md`：
    - 1.0.0コマンドツリー（例：`system-language-model ...`, `session ...`, `tools ...` など）
    - 各コマンドがどの公式APIに対応するかのマッピング表
- 可能なら `Package.swift` + `Sources/applefm/...` の最低限の雛形（ビルドが通るところまで）
    - `applefm system-language-model availability`
    - `applefm session new/respond`
    - `applefm tools list/describe`（まずはbuiltinの定義だけでも）

## 制約

- macOS向け。Foundation Modelsが使えるOS/環境前提。
- 細部が変わる可能性が高い（beta含む）ので、実装は「変更に強い」構造にする
- 1.0.0は Foundation Models の機能を CLI 経由で利用できるようにする
- 1.0.0では `serve` は実装しない

## 補足：仮のコマンド候補（たたき台）

（確定ではない。公式API確認後に修正してOK）

- `applefm system-language-model availability [--use-case ...]`
- `applefm session new <name> [--use-case ...] [--instructions ...]`
- `applefm session respond <name> <text|--stdin|-f>`
- `applefm session stream <name> ...`
- `applefm session generate <name> --schema schema.json ...`
- `applefm session transcript <name> [--format jsonl|md]`
- `applefm tools list|describe`
- `applefm session tools add|remove|policy`

