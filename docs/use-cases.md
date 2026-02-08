# applefm 活用事例

applefm の3大差別化ポイント **完全オフライン**・**プライバシー保護**・**Unix 哲学準拠** を軸に、活用事例をカテゴリ別に整理する。

## 差別化ポイント

| 強み | 意味 | 他ツールとの差 |
|---|---|---|
| 完全オフライン | インターネット不要。飛行機内でも使える | Claude Code / Copilot / ChatGPT はすべてクラウド必須 |
| プライバシー保護 | データがデバイスの外に出ない | 機密コード・個人情報も安心 |
| Unix 哲学準拠 | パイプ・リダイレクト・構造化出力で自然に統合 | CLI ネイティブの AI ツールとして唯一無二 |

## オンデバイスモデルの特性

applefm はオンデバイスの Foundation Models を使用する。クラウドの大規模モデル（Claude, GPT-4 等）と比べて推論能力に差がある。この前提を踏まえた活用が重要。

**得意なこと**: テキスト要約・翻訳、トーン変換、簡単な構造化出力、会話の文脈維持、定型的なテキスト生成

**苦手なこと**: 複雑なコード分析、正確な数値判定、多段階の論理的推論、厳密なフォーマット遵守

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

## パイプ入力パターン

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

---

## 1. 開発者ワークフロー

### 1-1. diff の要約

差分の内容を日本語で要約する。人が読む前の概要把握に便利。

```bash
# ステージ済み差分の要約
git diff --staged | applefm respond --instructions "この差分の変更内容を箇条書きで要約して" --stream

# 変更統計の要約
git diff HEAD~1 --stat | applefm respond --instructions "変更されたファイルと変更内容を日本語で要約して"
```

### 1-2. コミットメッセージのドラフト生成

生成されたメッセージは人が確認・編集する前提。エディタが開くので修正が容易。

```bash
# prepare-commit-msg hook でドラフトを提示（人がエディタで確認・編集する）
git diff --cached | head -500 | applefm respond \
  --instructions "Conventional Commits 形式のメッセージを1行で。メッセージのみ出力" \
  --temperature 0.3
```

### 1-3. PR 説明文・リリースノートのドラフト

```bash
# PR 説明文のドラフト生成
git log main..HEAD --oneline | applefm respond \
  --instructions "## Summary, ## Changes のセクションを含むPR説明文のドラフトを生成して" --stream

# リリースノートのドラフト生成
git log v1.0.0..v1.1.0 --pretty=format:"%s" | applefm respond \
  --instructions "ユーザー向けリリースノートを生成。カテゴリ別に分類して"
```

### 1-4. ドキュメントコメントのドラフト生成

```bash
# パブリック API のドキュメントコメントのドラフト
cat NetworkManager.swift | applefm respond \
  --instructions "各パブリックメソッドに /// 形式の Swift ドキュメントコメントを生成して" --stream
```

### 1-5. ビルドエラーメッセージの読み解き

エラーメッセージの意味を理解する補助として。修正案は参考程度に。

```bash
# ビルドエラーの読み解き
swift build 2>&1 | applefm respond --instructions "各エラーメッセージの意味を日本語で説明して" --stream
```

### 1-6. file-read ツールでファイル内容の要約

```bash
# モデルにファイルを読ませて概要を把握
applefm respond "README.md を読んで内容を要約して" \
  --tool file-read --tool-approval auto --stream
```

---

## 2. シェルスクリプト・自動化パイプライン

### 2-1. テキスト変換パイプライン

フォーマット変換や翻訳など、「正解の形が明確な」変換に適している。

```bash
# テキスト変換
cat table.md | applefm respond --instructions "この Markdown テーブルを CSV 形式に変換して"

# diff の自然言語要約
git diff HEAD~1 | applefm respond --instructions "変更内容を箇条書きで要約して"

# コメント翻訳
cat main.swift | applefm respond --instructions "日本語コメントを英語に翻訳して。コードはそのまま"
```

### 2-2. 構造化出力によるテキスト分析

JSON Schema で出力形式を強制できるため、後続処理と組み合わせやすい。

```bash
# 感情分析（構造化出力）
cat review.txt | applefm generate --instructions "感情を分析して" \
  --schema sentiment.json --format json

# 非構造化テキストからの情報抽出
cat meeting_email.txt | applefm generate --instructions "会議情報を抽出して" \
  --schema meeting.json --format json
```

### 2-3. ログの要約

大量のログを人間が読みやすい要約に変換する。正確なカウントや統計には向かない。

```bash
# バッチログの要約
tail -500 /var/log/system.log | applefm respond \
  --instructions "このログの概要を日本語で要約して。目立つエラーがあれば記載して"

# ビルドログの要約
xcodebuild build 2>&1 | applefm respond \
  --instructions "ビルド結果を要約して" --temperature 0.2
```

### 2-4. cron / launchd 統合

```bash
#!/bin/bash
# daily_summary.sh — launchd で毎朝実行。システム状態の概要を生成
{ df -h /; ps aux | sort -nrk 3 | head -5; } | \
  applefm respond --instructions "このシステム情報を簡潔に要約して" --temperature 0.2 \
  > ~/reports/summary-$(date +%F).md
```

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

### 2-5. シェル関数としての組み込み

```bash
# ~/.zshrc に追加
explain() { echo "$*" | applefm respond --instructions "このコマンドを説明して" --temperature 0.2; }
tldr-ai() { applefm respond "コマンド '$1' の実用例を5つ" --temperature 0.5; }
summarize() { cat "$1" | applefm respond --instructions "3行で要約して" --temperature 0.3; }
```

---

## 3. クリエイティブ・個人利用

### 3-1. 文章作成・編集支援

```bash
# ブログ下書き
applefm config preset creative
applefm respond "macOS 26 の新機能について技術ブログの下書きを書いて" --stream

# メール推敲（社外秘情報も安全）
echo "明日の会議の資料が間に合わないかもしれません" | \
  applefm respond --instructions "ビジネスにふさわしい丁寧な表現に書き直して"

# SNS 投稿の最適化
applefm respond --file blog-draft.txt --instructions "280文字以内のツイートに要約して"

# トーン変換セッション
applefm session new tone-test --instructions "文章のトーン変換の専門家として"
applefm session respond tone-test "以下をカジュアルに: 弊社のサービスをご利用いただき..."
applefm session respond tone-test "同じ内容をプレスリリース風に"
```

### 3-2. 学習・語学学習

オフライン動作のため、飛行機内や通信環境のない場所でも学習を継続できる。

```bash
# 外国語会話練習
applefm chat --instructions "フランス語の会話パートナーとして。初級レベルに合わせて各返答に日本語訳を添えて"

# 要約による学習ノート作成
pbpaste | applefm respond --instructions "この学術テキストを3つの要点にまとめて"
```

### 3-3. クリエイティブライティング

アイデアのブレインストーミングや下書き生成に。未発表作品がクラウドに送信されない安心感。

```bash
# 小説のアイデア出し
applefm config preset creative  # temperature=1.5
applefm session new novel --instructions "SF小説の共同執筆者として"
applefm session respond novel "2040年の東京、記憶を売買できる闇市場が存在する設定で主人公を提案して"
applefm session respond novel "第一章のあらすじを3パターン考えて"

# ブレインストーミング REPL
applefm chat --instructions "アイデア出しのファシリテーターとして。5つの発展案と2つの反論を提示して" --temperature 1.5
```

### 3-4. 日記・ジャーナリング

日記は最もプライベートな情報。オンデバイス処理で安全にAI支援を受けられる。

```bash
# 日記の振り返り
applefm session new journal-$(date +%Y%m) \
  --instructions "ジャーナリングコーチとして。日記の内容を受けて、ポジティブな側面の発見や気づきの質問を提供して"

# 週次振り返りの要約
cat ~/journal/2026-02-{02..08}.md | \
  applefm respond --instructions "この一週間の日記を要約して"

# 構造化ジャーナルエントリー
echo "新プロジェクトのキックオフがあった。チームと良い議論ができた" | \
  applefm generate --instructions "ジャーナルエントリーを構造化して" \
  --schema journal.json --format json >> ~/journal/reflections.jsonl
```

### 3-5. プライバシー重視の個人利用

クラウド AI では躊躇する内容も、オンデバイスなら安心して扱える。

```bash
# 個人的な悩みの整理
applefm chat --instructions "傾聴力のあるカウンセラーとして。アドバイスを押し付けず、考えを整理する手助けをして"

# 機密性のある文書の要約
cat confidential-report.txt | applefm respond --instructions "この文書を3行で要約して"
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
    { "applefm", "respond", "--instructions", "このコードを簡潔に説明して" }, text)
  -- フローティングウィンドウで表示
end

-- コミットメッセージのドラフト生成 (fugitive 連携)
function M.generate_commit_msg()
  local diff = vim.fn.system("git diff --cached")
  local result = vim.fn.system({
    "applefm", "respond",
    "--instructions", "Generate a conventional commit message. Output only the message.",
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
      "command": "echo '${selectedText}' | applefm respond --instructions 'このコードを説明して' --stream",
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

git diff --cached | head -500 | applefm respond \
  --instructions "Conventional Commits 形式のメッセージを1行で。メッセージのみ出力" \
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
2. [シェルスクリプトを実行]: echo "$input" | applefm respond --instructions "3行で要約して"
3. [クリップボードにコピー]
```

```bash
# Automator フォルダアクション: テキストファイル追加時に自動要約
for f in "$@"; do
  cat "$f" | applefm respond --instructions "要約して" \
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
  cat "$FILE" | applefm respond --instructions "要約して"  # オンデバイス
else
  claude -p "Summarize: $(cat "$FILE")"                    # クラウド
fi
```

**パターン B: レイテンシ最適化** — 簡単なタスクは即座にオンデバイス

```bash
case "$TASK" in
  "translate"|"summarize"|"rewrite")
    echo "$CONTENT" | applefm respond --instructions "$TASK" ;;  # 即座に応答
  "architecture"|"deep-analysis")
    claude -p "$TASK: $CONTENT" ;;                               # 深い分析
esac
```

**パターン C: パイプラインチェーン** — オンデバイスで前処理し、クラウドへの送信データを最小化

```bash
# Step 1: applefm でファイルを要約（機密コードはローカルに留まる）
find src -name "*.ts" | while read f; do
  cat "$f" | applefm respond --instructions "このファイルの責務を1行で要約:"
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
