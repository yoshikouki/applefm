# applefm 活用事例

applefm の3大差別化ポイント **完全オフライン**・**プライバシー保護**・**Unix 哲学準拠** を軸に、活用事例をカテゴリ別に整理する。

> **検証済み**: 本ドキュメントの各ユースケースは実際の `applefm` CLI で動作検証済み。評価は A（優秀）〜D（非実用的）の4段階。

## 差別化ポイント

| 強み | 意味 | 他ツールとの差 |
|---|---|---|
| 完全オフライン | インターネット不要。飛行機内でも使える | Claude Code / Copilot / ChatGPT はすべてクラウド必須 |
| プライバシー保護 | データがデバイスの外に出ない | 機密コード・個人情報も安心 |
| Unix 哲学準拠 | パイプ・リダイレクト・構造化出力で自然に統合 | CLI ネイティブの AI ツールとして唯一無二 |

## オンデバイスモデルの特性

applefm はオンデバイスの Foundation Models を使用する。クラウドの大規模モデル（Claude, GPT-4 等）と比べて推論能力に差がある。この前提を踏まえた活用が重要。

**得意なこと**: テキスト要約・翻訳、トーン変換、簡単な構造化出力、会話の文脈維持、定型的なテキスト生成、フォーマット変換（JSON↔YAML）、クリエイティブライティング

**苦手なこと**: 複雑なコード分析、正確な数値判定、多段階の論理的推論、厳密なフォーマット遵守、日英以外の言語

**原則**: applefm の出力は **ドラフト（下書き）** として扱い、人が確認・編集することを前提とする。自動化パイプラインで判断を委ねる用途には向かない。

## 戦略的ポジショニング

```
                  高い推論能力
                      ↑
           Claude Code / ChatGPT
                      |
                      |
  オフライン ←--------+--------→ クラウド必須
                      |
                 ★ applefm ★
                      |
                      ↓
                  軽量・高速
```

**applefm のスイートスポット**:

- 毎日繰り返す高頻度タスク（Git hooks, シェル関数, ランチャー連携）
- 機密データを含むテキストの要約・変換
- オフライン環境（飛行機, 地下鉄, 山間部）
- 他の AI ツールの前処理/後処理（MCP 連携, パイプラインチェーン）

## 効果的な使い方のコツ

### パイプ入力パターン

applefm のプロンプト入力は **CLI 引数 > `--file` > stdin** の優先順位で解決される。パイプ入力と CLI 引数を同時に使うと **stdin は無視される**。

```bash
# ✅ 正しい: パイプ + --instructions（stdin がプロンプト、--instructions がシステム指示）
cat file.txt | applefm respond --instructions "要約して"

# ✅ 正しい: CLI 引数のみ（パイプなし）
applefm respond "Swiftのエラーハンドリングを教えて"

# ✅ 正しい: パイプのみ（指示をパイプ内容に含める）
echo "Swiftのエラーハンドリングを教えて" | applefm respond

# ❌ 間違い: パイプ + CLI 引数（stdin が無視され、ファイル内容がモデルに渡らない）
cat file.txt | applefm respond "要約して"
```

### instructions のベストプラクティス

検証の結果、以下のパターンが安定して高品質な出力を生む。

**具体的な制約を含める**（品質に最も影響する要素）:

```bash
# ❌ 曖昧: モデルが情報を膨張させ、ハルシネーションのリスクが高い
applefm respond --instructions "要約して"

# ✅ 具体的: 長さ・言語・フォーマットを明示
applefm respond --instructions "日本語で3文以内に要約してください"
```

**フォーマット遵守が必要な場合は英語 instructions を推奨**:

```bash
# 日本語 instructions ではセクション構造が崩れやすい
--instructions "## Summary, ## Changes のセクションを含むPR説明文を生成して"

# 英語 instructions の方がフォーマット遵守率が高い
--instructions "Generate a PR description with exactly two sections: ## Summary and ## Changes. Write in Japanese."
```

**instruction の言語とトーンは品質に影響しない**。重要なのは制約の明示。

### 推奨 temperature 設定

| タスク種別 | 推奨 | 備考 |
|---|---|---|
| フォーマット変換（JSON↔YAML 等） | 0.1 | 正確さ最優先 |
| 要約 | 0.2 | ファクチュアリティ重視 |
| 翻訳 | 0.2 | 忠実さ重視 |
| コード説明・エラー解説 | 0.2 | 技術的正確さ重視 |
| 生成（アイデア出し等） | 0.7 | 多様性と正確さのバランス |
| クリエイティブ | 1.0〜1.5 | 多様性重視 |

### 既知の制約

- **コンテキストウィンドウ**: パイプ入力は `head -100` 程度に制限する。`head -500` ではコンテキスト超過エラーが発生する
- **言語検出**: 英語のみ・ハッシュ文字列が多い入力で `Unsupported language or locale` エラーが非決定的に発生する。日本語テキストのプレフィックス追加や `--guardrails permissive` で回避可能
- **対応言語**: 日本語と英語のみ実用的。フランス語等の他言語は非対応
- **出力フォーマット制御**: 「コードブロックなし」「Markdown 装飾なし」の指示に従わない傾向がある

---

## 1. 開発者ワークフロー

### 1-1. diff の要約 [検証済: B]

差分の内容を要約する。人が読む前の概要把握に便利。

```bash
# ステージ済み差分の要約
git diff --staged | head -100 | applefm respond \
  --instructions "Summarize the changes in this diff as bullet points in Japanese." \
  --temperature 0.2 --stream

# 変更統計の要約（--shortstat を使用。--stat のバーグラフは言語検出エラーを誘発する）
git diff HEAD~1 --shortstat | applefm respond \
  --instructions "この変更統計を日本語で要約して"
```

> **注意**: 大きな diff は `head -100` でトランケートする。`git diff --stat` のバーグラフ（`++++----`）は `unsupportedLanguageOrLocale` エラーを誘発するため `--shortstat` を推奨。

### 1-2. コミットメッセージのドラフト生成 [検証済: C]

生成されたメッセージは人が確認・編集する前提。Conventional Commits の厳密なフォーマット遵守は苦手なので、ドラフトとして利用する。

```bash
# prepare-commit-msg hook でドラフトを提示（人がエディタで確認・編集する）
git diff --cached | head -100 | applefm respond \
  --instructions "Generate a one-line commit message in Conventional Commits format: type(scope): description. Output only the message." \
  --temperature 0.3
```

> **注意**: `head -100` でコンテキストウィンドウ内に収める。英語 instructions の方がフォーマット遵守率が高い。

### 1-3. PR 説明文・リリースノートのドラフト [検証済: A]

```bash
# PR 説明文のドラフト生成
git log main..HEAD --oneline | applefm respond \
  --instructions "Generate a PR description with exactly two sections: ## Summary and ## Changes. Write in Japanese." \
  --temperature 0.3 --stream

# リリースノートのドラフト生成
git log v1.0.0..v1.1.0 --pretty=format:"%s" | applefm respond \
  --instructions "Generate user-facing release notes. Categorize changes. Write in Japanese." \
  --temperature 0.3
```

### 1-4. ドキュメントコメントのドラフト生成 [検証済: A]

applefm の最も強いユースケースの一つ。パブリック API のドキュメントコメントを正確に生成する。

```bash
# パブリック API のドキュメントコメントのドラフト
cat MyClass.swift | applefm respond \
  --instructions "各パブリックメソッドに /// 形式の Swift ドキュメントコメントを生成して" \
  --temperature 0.2 --stream
```

### 1-5. ビルドエラーメッセージの読み解き [検証済: B]

エラーメッセージの意味を理解する補助として。修正案は参考程度。

```bash
# ビルドエラーの読み解き（言語コンテキストを明示する）
swift build 2>&1 | tail -30 | applefm respond \
  --instructions "These are Swift compiler errors. Explain each error message in Japanese." \
  --temperature 0.2 --stream
```

> **注意**: `swift build` の全出力はコンテキスト超過するため `tail -30` でエラー部分のみ渡す。instructions で "Swift errors" と明示しないと言語を誤認する場合がある。

### 1-6. file-read ツールでファイル内容の要約 [検証済: A]

```bash
# モデルにファイルを読ませて概要を把握
applefm respond "README.md を読んで内容を要約して" \
  --tool file-read --tool-approval auto --stream
```

### 1-7. テスト結果の要約 [検証済: A]

```bash
# swift test の結果を要約
swift test 2>&1 | tail -40 | applefm respond \
  --instructions "Summarize this test output in Japanese: total tests, passed/failed, slowest suite." \
  --temperature 0.2
```

> **注意**: `tail -40` で結果サマリー部分のみ渡す。テスト数は正確だが、個別テストの合否の詳細にはハルシネーションの可能性がある。

### 1-8. シェルスクリプトの説明生成 [検証済: A]

```bash
# スクリプトの動作を説明
cat deploy.sh | applefm respond \
  --instructions "このシェルスクリプトの動作を日本語でステップごとに説明して" \
  --temperature 0.2
```

> **注意**: 全体構造の把握は優秀だが、個別コマンドオプション（`set -u` 等）の説明に不正確さが出る場合がある。

### 1-9. JSON↔YAML 変換 [検証済: A]

```bash
# JSON → YAML
cat config.json | applefm respond \
  --instructions "Convert this JSON to YAML format. Output only the YAML." \
  --temperature 0.1

# YAML → JSON
cat config.yaml | applefm respond \
  --instructions "Convert this YAML to JSON format. Output only the JSON." \
  --temperature 0.1
```

### 1-10. API レスポンスの解説 [検証済: A]

```bash
# API レスポンスの構造を解説
curl -s https://api.example.com/data | applefm respond \
  --instructions "このAPIレスポンスの構造と各フィールドの意味を日本語で説明して" \
  --temperature 0.2
```

---

## 2. シェルスクリプト・自動化パイプライン

### 2-1. テキスト変換パイプライン [検証済: A]

フォーマット変換や翻訳など、「正解の形が明確な」変換に適している。

```bash
# Markdown テーブル → CSV 変換
cat table.md | applefm respond \
  --instructions "Convert this Markdown table to CSV format. Output only the CSV." \
  --temperature 0.1

# コメント翻訳（コード保持）
cat main.swift | applefm respond \
  --instructions "日本語コメントを英語に翻訳して。コードはそのまま出力して" \
  --temperature 0.2
```

### 2-2. 構造化出力によるテキスト分析 [検証済: A]

JSON Schema で出力形式を強制できるため、後続処理と組み合わせやすい。

```bash
# 感情分析（構造化出力）
cat review.txt | applefm generate \
  --instructions "Analyze the sentiment of this text." \
  --schema sentiment.json --format json

# 非構造化テキストからの情報抽出
cat meeting_email.txt | applefm generate \
  --instructions "Extract meeting information from this text." \
  --schema meeting.json --format json
```

> **注意**: 相対的な日時表現（「来週の水曜日」等）は具体的な日付にハルシネーションする場合がある。

### 2-3. ログの要約 [検証済: A/C]

大量のログを人間が読みやすい要約に変換する。git ログの要約は得意だが、システムログのフォーマット解析は苦手。

```bash
# git ログの要約（A: 得意）
git log --oneline -20 | applefm respond \
  --instructions "このコミットログの概要を日本語で要約して。主な変更をカテゴリ別に整理して" \
  --temperature 0.2

# ビルドログの要約
xcodebuild build 2>&1 | tail -50 | applefm respond \
  --instructions "Summarize the build result in Japanese." --temperature 0.2
```

> **注意**: 正確なカウントや統計には向かない。ログの概要把握用として使う。

### 2-4. cron / launchd 統合 [検証済: B]

```bash
#!/bin/bash
# daily_summary.sh — launchd で毎朝実行。システム状態の概要を生成
{
  echo "=== Disk Usage ==="
  df -h /
  echo "=== Top CPU Processes ==="
  ps aux | sort -nrk 3 | head -5
} | applefm respond \
  --instructions "Summarize this system information concisely in Japanese." \
  --temperature 0.2 \
  > ~/reports/summary-$(date +%F).md
```

> **注意**: 入力にラベル（`=== Disk Usage ===` 等）を付けるとパース精度が向上する。数値の正確さは完璧ではないため、概要把握用として使う。

```xml
<!-- ~/Library/LaunchAgents/com.applefm.daily-summary.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.applefm.daily-summary</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>/Users/you/scripts/daily_summary.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>8</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
</dict>
</plist>
```

### 2-5. シェル関数としての組み込み [検証済: B]

```bash
# ~/.zshrc に追加
explain() {
  echo "$*" | applefm respond \
    --instructions "Explain this command in Japanese." \
    --temperature 0.2 --guardrails permissive
}
tldr-ai() {
  applefm respond "コマンド '$1' の実用例を5つ、日本語で簡潔に教えて" \
    --temperature 0.5 --guardrails permissive
}
summarize() {
  cat "$1" | applefm respond \
    --instructions "日本語で3文以内に要約してください" --temperature 0.3
}
```

> **注意**: コマンド説明系はデフォルトガードレールでブロックされる場合がある。`--guardrails permissive` を推奨。応答言語を制御したい場合は instructions 内で明示する。

---

## 3. クリエイティブ・個人利用

### 3-1. 文章作成・編集支援 [検証済: A〜C]

```bash
# ブログ下書き（具体的なプロンプトが重要）
applefm respond "macOS 26 の新機能について、500文字程度の技術ブログの下書きを書いて。見出しと箇条書きを含めて" \
  --stream --temperature 1.0

# メール推敲（社外秘情報も安全。詳細な指示で品質向上）
echo "明日の会議の資料が間に合わないかもしれません" | \
  applefm respond --instructions "ビジネスメールとして書き直して。件名、クッション言葉、代替案の提示を含めて"

# SNS 投稿の最適化
applefm respond --file blog-draft.txt \
  --instructions "280文字以内のツイートに要約して" --temperature 0.5

# トーン変換（カジュアル化が得意）
applefm session new tone-test --instructions "文章のトーン変換の専門家として"
applefm session respond tone-test "以下をカジュアルに: 弊社のサービスをご利用いただき誠にありがとうございます。今後ともよろしくお願い申し上げます。"
```

> **注意**: 曖昧なプロンプト（「ブログを書いて」）は非常に短い出力になる。文字数・構造・含めるべき要素を具体的に指定する。プレスリリース風などの特定スタイルへの変換は苦手。

### 3-2. 学習支援 [検証済: B]

オフライン動作のため、飛行機内や通信環境のない場所でも学習を継続できる。

```bash
# 英会話練習（日本語と英語のみ対応）
applefm chat --instructions "English conversation partner. Respond in English with Japanese translation for each sentence. Beginner level."

# 要約による学習ノート作成
pbpaste | applefm respond \
  --instructions "この学術テキストを3つの要点にまとめて" --temperature 0.2
```

> **注意**: 日本語と英語の言語学習のみ対応。フランス語等の他言語では応答がすべて日本語になり、会話パートナーとして機能しない。

### 3-3. クリエイティブライティング [検証済: A]

applefm の最強ユースケースの一つ。アイデアのブレインストーミングや下書き生成に。未発表作品がクラウドに送信されない安心感。

```bash
# 小説のアイデア出し（temperature 1.5 で創造性を最大化）
applefm session new novel --instructions "SF小説の共同執筆者として"
applefm session respond novel \
  "2040年の東京、記憶を売買できる闇市場が存在する設定で主人公を提案して" --temperature 1.5
applefm session respond novel "第一章のあらすじを3パターン考えて" --temperature 1.5

# ブレインストーミング REPL（構造化された指示で高品質な出力）
applefm chat \
  --instructions "アイデア出しのファシリテーターとして。各トピックに対して5つの発展案と2つの反論を提示して" \
  --temperature 1.5
```

### 3-4. 日記・ジャーナリング [検証済: A/B]

日記は最もプライベートな情報。オンデバイス処理で安全にAI支援を受けられる。

```bash
# 日記の振り返り
applefm session new journal-$(date +%Y%m) \
  --instructions "ジャーナリングコーチとして。日記の内容を受けて、ポジティブな側面の発見や気づきの質問を温かいトーンで提供して"

# 週次振り返りの要約
cat ~/journal/2026-02-{02..08}.md | \
  applefm respond --instructions "この一週間の日記を3つのハイライトと1つの振り返りにまとめて" \
  --temperature 0.3

# 構造化ジャーナルエントリー（JSON Schema で安定した出力）
echo "新プロジェクトのキックオフがあった。チームと良い議論ができた" | \
  applefm generate --instructions "Structure this as a journal entry." \
  --schema journal.json --format json >> ~/journal/reflections.jsonl
```

### 3-5. プライバシー重視の個人利用 [検証済: A]

applefm のキラーフィーチャー。クラウド AI では躊躇する内容も、オンデバイスなら安心して扱える。

```bash
# 個人的な悩みの整理（共感的で非指示的な応答を生成）
applefm chat \
  --instructions "傾聴力のあるカウンセラーとして。アドバイスを押し付けず、考えを整理する手助けをして"

# 機密性のある文書の要約（データがデバイスの外に出ない）
cat confidential-report.txt | applefm respond \
  --instructions "日本語で3行の箇条書きに要約してください" --temperature 0.2
```

---

## 4. エディタ・ツール統合

### 4-1. Vim/Neovim

```lua
-- ~/.config/nvim/lua/applefm.lua

-- 選択範囲をapplefmに送って説明を表示
function M.explain_selection()
  local lines = vim.fn.getline("'<", "'>")
  local text = table.concat(lines, "\n")
  local result = vim.fn.system(
    { "applefm", "respond", "--instructions", "Explain this code concisely in Japanese.", "--temperature", "0.2" }, text)
  -- フローティングウィンドウで表示
end

-- コミットメッセージのドラフト生成 (fugitive 連携)
function M.generate_commit_msg()
  local diff = vim.fn.system("git diff --cached | head -100")
  local result = vim.fn.system({
    "applefm", "respond",
    "--instructions", "Generate a conventional commit message. Output only the message.",
    "--temperature", "0.3",
  }, diff)
  vim.fn.setreg('"', vim.trim(result))
end

vim.keymap.set("v", "<leader>ae", M.explain_selection, { desc = "applefm: Explain" })
vim.keymap.set("n", "<leader>ac", M.generate_commit_msg, { desc = "applefm: Commit msg" })
```

### 4-2. VS Code

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "applefm: Explain Selection",
      "type": "shell",
      "command": "echo '${selectedText}' | applefm respond --instructions 'Explain this code concisely in Japanese.' --temperature 0.2 --stream",
      "presentation": { "reveal": "always", "panel": "dedicated" }
    }
  ]
}
```

### 4-3. Git Hooks

毎日何十回も実行されるため、低レイテンシ・オフラインの強みが活きる。

```bash
#!/bin/bash
# .git/hooks/prepare-commit-msg — コミットメッセージのドラフトを提示
# エディタで人が確認・編集する前提
COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2
[ -n "$COMMIT_SOURCE" ] && exit 0

git diff --cached | head -100 | applefm respond \
  --instructions "Generate a one-line commit message in Conventional Commits format: type(scope): description. Output only the message." \
  --temperature 0.3 > "$COMMIT_MSG_FILE"
```

### 4-4. Raycast / Alfred

キーボードショートカット一発で、どのアプリからでもオンデバイス AI 処理。API キー不要。

```bash
#!/bin/bash
# Raycast スクリプト: クリップボード加工
# @raycast.schemaVersion 1
# @raycast.title applefm Process
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "Instruction" }

pbpaste | applefm respond --instructions "$1" | pbcopy
```

### 4-5. Apple エコシステム（Shortcuts / AppleScript / Automator）

ターミナルを使わないユーザーにもリーチできる、applefm 固有の強み。

```
# Apple Shortcuts: 「テキストを要約」
1. [入力を受け取る] → テキスト
2. [シェルスクリプトを実行]: echo "$input" | applefm respond --instructions "日本語で3行に要約してください"
3. [クリップボードにコピー]
```

```bash
# Automator フォルダアクション: テキストファイル追加時に自動要約
for f in "$@"; do
  cat "$f" | applefm respond \
    --instructions "日本語で3文以内に要約してください" --temperature 0.3 \
    > ~/summaries/"$(basename "$f" .txt)-summary.txt"
  osascript -e "display notification \"$(basename "$f") の要約完了\" with title \"applefm\""
done
```

### 4-6. tmux 統合

```bash
# ~/.tmux.conf — Prefix + a で applefm チャットペインをトグル
bind a if-shell "tmux list-panes -F '#{pane_title}' | grep -q applefm" \
  "select-pane -t applefm" \
  "split-window -h -l 40% 'applefm chat'"
```

---

## 5. 他の AI ツールとの使い分け・補完

### 比較マトリクス

| 特性 | applefm | Claude Code | GitHub Copilot | ChatGPT |
|------|---------|-------------|----------------|---------|
| 実行環境 | 完全オンデバイス | クラウド | クラウド | クラウド |
| プライバシー | データ外部送信なし | API 送信 | API 送信 | API 送信 |
| オフライン動作 | 可能 | 不可 | 不可 | 不可 |
| レイテンシ | 極低 | 中 | 低〜中 | 中〜高 |
| 推論能力 | 中 | 最高クラス | 中〜高 | 高 |
| コスト | 無料 | API 課金 | サブスク | サブスク/API |
| スクリプタビリティ | 最高 | 高 | 低 | 中 |

### 補完パターン

**パターン A: プライバシーゲート** — 機密テキストはオンデバイスで要約、それ以外はクラウド

```bash
if grep -qiE "(confidential|internal)" "$FILE"; then
  cat "$FILE" | applefm respond --instructions "日本語で3行に要約してください"  # オンデバイス
else
  claude -p "Summarize: $(cat "$FILE")"  # クラウド
fi
```

**パターン B: レイテンシ最適化** — 簡単なタスクは即座にオンデバイス

```bash
case "$TASK" in
  "translate"|"summarize"|"rewrite")
    echo "$CONTENT" | applefm respond --instructions "Perform: $TASK. Output in Japanese." ;;
  "architecture"|"deep-analysis")
    claude -p "$TASK: $CONTENT" ;;
esac
```

**パターン C: パイプラインチェーン** — オンデバイスで前処理し、クラウドへの送信データを最小化

```bash
# Step 1: applefm でファイルを要約（機密コードはローカルに留まる）
find src -name "*.swift" | while read f; do
  cat "$f" | applefm respond \
    --instructions "Summarize this file's responsibility in one sentence in Japanese." \
    --temperature 0.2
done > /tmp/codebase-summary.txt

# Step 2: 要約のみをクラウドに送信（元コードは送信しない）
cat /tmp/codebase-summary.txt | claude -p "アーキテクチャを分析して改善提案をして"
```

---

## 6. MCP サーバーとしての可能性

applefm を Model Context Protocol (MCP) サーバーとして公開することで、Claude Desktop や VS Code などの MCP クライアントからオンデバイスモデルを利用可能にできる。

```json
{
  "mcpServers": {
    "applefm": {
      "command": "applefm",
      "args": ["mcp-server"]
    }
  }
}
```

### 公開すべき MCP インターフェース

```
Tools:
  - applefm_respond         テキスト生成
  - applefm_generate        構造化出力（スキーマ付き）
  - applefm_session_respond セッション付き生成
  - applefm_model_availability モデル可用性チェック

Resources:
  - applefm://sessions                    セッション一覧
  - applefm://sessions/{name}/transcript  会話履歴
  - applefm://config                      現在の設定
```

### マルチモデルオーケストレーション

```
ユーザー → Claude Desktop
              ├── Claude (メイン推論・複雑なタスク)
              ├── applefm MCP (プライベートデータの要約・変換)
              │   ├── 機密ドキュメントの要約
              │   ├── ローカルファイルのテキスト変換
              │   └── プライベートデータの構造化
              └── 他の MCP サーバー (GitHub, Slack, DB ...)
```

機密データだけオンデバイスで処理するワークフローが実現。Claude の推論力 + applefm のプライバシーを両立。

---

## 次のアクション候補

| 優先度 | アクション | 理由 |
|---|---|---|
| P0 | Git hooks サンプル集の公開 | 最もインパクトが高く、導入ハードルが低い |
| P0 | MCP サーバーサブコマンドの実装 | エコシステム統合の鍵。戦略的ポジションを確立 |
| P1 | Raycast/Alfred ワークフロー配布 | 非エンジニアへのリーチ拡大 |
| P1 | シェル関数集の README への追加 | 「インストール後すぐ便利」体験の提供 |
| P2 | Neovim プラグインの作成 | 開発者コミュニティでの認知度向上 |
| P2 | Apple Shortcuts ギャラリーへの登録 | macOS エコシステムとの深い統合 |
