# applefm 活用事例

applefm の3大差別化ポイント **完全オフライン**・**プライバシー保護**・**Unix 哲学準拠** を軸に、活用事例をカテゴリ別に整理する。

## 差別化ポイント

| 強み | 意味 | 他ツールとの差 |
|---|---|---|
| 完全オフライン | インターネット不要。飛行機内でも使える | Claude Code / Copilot / ChatGPT はすべてクラウド必須 |
| プライバシー保護 | データがデバイスの外に出ない | 機密コード・個人情報・健康データも安心 |
| Unix 哲学準拠 | パイプ・リダイレクト・構造化出力で自然に統合 | CLI ネイティブの AI ツールとして唯一無二 |

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
- 機密データを扱うタスク（コードレビュー, 個人データ, 健康情報）
- オフライン環境（飛行機, 地下鉄, 山間部）
- 他の AI ツールの前処理/後処理（MCP 連携, パイプラインチェーン）

---

## 1. 開発者ワークフロー

### 1-1. コードレビュー

プロプライエタリコードがクラウドに送信されないため、社内コードでも安心して利用できる。

```bash
# ステージ済み差分をオフラインでレビュー
git diff --staged | applefm respond "バグ・パフォーマンス・セキュリティの観点でレビューして" --stream

# file-read ツールでコンテキスト付きレビュー
applefm respond "SessionStore.swift を読んでエラーハンドリングの観点でレビューして" \
  --tool file-read --tool-approval auto --stream

# セッションで複数ファイルを文脈付きレビュー
applefm session new review --instructions "セキュリティに詳しいシニア開発者として振る舞って"
cat Auth.swift | applefm session respond review "このファイルをレビュー"
cat Token.swift | applefm session respond review "前のファイルとの整合性も含めてレビュー"
```

### 1-2. コード生成・テスト生成

```bash
# ボイラープレート生成（構造化出力）
applefm generate "User モデルの CRUD を生成。フィールド: id, name, email" \
  --schema crud-schema.json --format json

# 実装ファイルからテスト自動生成
cat Calculator.swift | applefm respond \
  "Swift Testing フレームワーク（@Suite, @Test, #expect）でユニットテストを生成して" --stream
```

### 1-3. Git ワークフロー統合

```bash
# コミットメッセージ自動生成
git commit -m "$(git diff --staged | applefm respond \
  'Conventional Commits 形式のメッセージを1行で。メッセージのみ出力')"

# PR 説明文生成
git log main..HEAD --oneline | applefm respond \
  "## Summary, ## Changes, ## Test Plan のセクションを含むPR説明文を生成して" --stream

# リリースノート生成
git log v1.0.0..v1.1.0 --pretty=format:"%s" | applefm respond \
  "ユーザー向けリリースノートを生成。カテゴリ別に分類して"

# コンフリクト解決支援
git diff --diff-filter=U | applefm respond "マージコンフリクトの解決方法を提案して" --stream
```

### 1-4. ビルドエラー・テスト失敗の解析

```bash
# ビルドエラー解析
swift build 2>&1 | applefm respond "エラーの原因と修正方法を説明して" --stream

# テスト失敗の解析
swift test 2>&1 | applefm respond "失敗したテストの原因と修正方法を提案して" --stream

# 構造化ビルドレポート
swift build 2>&1 | applefm generate --schema build-report.json "ビルド結果をレポートにまとめて" --format json
```

### 1-5. ドキュメント生成・メンテナンス

```bash
# パブリック API のドキュメントコメント生成
cat NetworkManager.swift | applefm respond \
  "各パブリックメソッドに /// 形式の Swift ドキュメントコメントを生成して" --stream

# アーキテクチャ図生成（Mermaid 記法）
applefm respond "Sources/ 以下を読んでコンポーネント間の依存関係を Mermaid 記法で" \
  --tool file-read --tool shell --tool-approval auto

# API 変更ログ
git diff v1.0.0..HEAD -- "Sources/**/*.swift" | applefm respond \
  "パブリック API の変更を検出して CHANGELOG エントリを生成して"
```

### 1-6. デバッグ・トラブルシューティング

```bash
# クラッシュログ解析
cat crash.log | applefm respond "クラッシュの原因と修正方法を説明して" --stream

# インタラクティブなデバッグ（モデルが自律的に調査）
applefm chat --tool shell --tool file-read \
  --instructions "Swift デバッグの専門家として、シェルコマンドやファイル読み取りを活用して調査して"

# 構造化バグレポート
cat error.log | applefm generate --schema bug-report.json "バグレポートを作成して" --format json
```

---

## 2. シェルスクリプト・自動化パイプライン

### 2-1. テキスト処理パイプライン

awk/sed では正規表現の設計が必要だった処理を自然言語で記述できる。

```bash
# 自然言語フィルタリング
cat sales.csv | applefm respond "売上100万円以上の行だけCSV形式で抽出して"

# テキスト変換
cat table.md | applefm respond "この Markdown テーブルを CSV 形式に変換して"

# diff の自然言語要約
git diff HEAD~1 | applefm respond "変更内容を箇条書きで要約して"

# 感情分析（構造化出力）
cat review.txt | applefm generate "感情を分析して" --schema sentiment.json --format json
```

### 2-2. ログ分析・モニタリング

```bash
# バッチログ分析（構造化出力）
tail -1000 /var/log/system.log | applefm generate \
  "ログを分析して" --schema log-analysis.json --format json

# リアルタイムログ監視 + macOS 通知
tail -f /var/log/app/error.log | while IFS= read -r line; do
  ANALYSIS=$(echo "$line" | applefm respond "重大な問題があれば CRITICAL: で始めて報告。問題なければ OK")
  if echo "$ANALYSIS" | grep -q "^CRITICAL:"; then
    osascript -e "display notification \"$ANALYSIS\" with title \"applefm Alert\""
  fi
done

# ビルドログ分析
xcodebuild build 2>&1 | applefm respond "エラーの原因と修正方法を簡潔に" --temperature 0.2
```

### 2-3. データ変換・ETL

構造化出力（`--schema` + `--format json`）で非構造化テキストを機械可読データに変換。

```bash
# 非構造化テキスト → JSON
cat meeting_email.txt | applefm generate "会議情報を抽出して" --schema meeting.json --format json

# マルチステップ ETL パイプライン
for file in reports/*.txt; do
  applefm generate --file "$file" --schema report.json --format json \
    > "structured/$(basename "$file" .txt).json"
done

# API レスポンスの再構造化
gh pr list --json title,author,state,body | \
  applefm generate "各PRを要約して" --schema pr-summary.json --format json
```

### 2-4. cron / launchd 統合

```bash
#!/bin/bash
# daily_health_report.sh — launchd で毎朝8時に実行
{ df -h /; vm_stat; ps aux | sort -nrk 3 | head -10; } | \
  applefm respond "日次ヘルスレポートを生成して" --temperature 0.2 \
  > ~/reports/health-$(date +%F).md
```

```xml
<!-- ~/Library/LaunchAgents/com.applefm.daily-health.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.applefm.daily-health</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>/Users/you/scripts/daily_health_report.sh</string>
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
explain() { echo "$*" | applefm respond "このコマンドを説明して" --temperature 0.2; }
tldr-ai() { applefm respond "コマンド '$1' の実用例を5つ" --temperature 0.5; }
fixcmd() {
  local last_cmd=$(fc -ln -1)
  local last_err=$(eval "$last_cmd" 2>&1)
  echo "Command: $last_cmd\nError: $last_err" | applefm respond "修正後のコマンドのみ出力して" --temperature 0.2
}
summarize() { cat "$1" | applefm respond "3行で要約して" --temperature 0.3; }
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

# 構造化クイズ生成
applefm generate "日本史の鎌倉時代に関する4択クイズ" --schema quiz.json --format json

# 要約による学習ノート作成
pbpaste | applefm respond --instructions "この学術テキストを3つの要点にまとめて"
```

### 3-3. クリエイティブライティング

未発表作品がクラウドの学習データに使われるリスクがゼロ。著作権を完全に保護。

```bash
# 小説のプロット共同開発
applefm config preset creative  # temperature=1.5
applefm session new novel --instructions "SF小説の共同執筆者として"
applefm session respond novel "2040年の東京、記憶を売買できる闇市場が存在する設定で主人公を提案して"
applefm session respond novel "第一章のあらすじを3パターン考えて"

# シナリオの構造化生成
applefm generate "カフェで偶然再会した旧友の会話シーン" --schema scene.json --format json

# ブレインストーミング REPL
applefm chat --instructions "アイデア出しのファシリテーターとして。5つの発展案と2つの反論を提示して" --temperature 1.5
```

### 3-4. 日記・ジャーナリング

日記は最もプライベートな情報。オンデバイス処理で安全にAI支援を受けられる。

```bash
# 日記の振り返りコーチング
applefm session new journal-$(date +%Y%m) \
  --instructions "ジャーナリングコーチとして。感情の傾向分析とポジティブな側面の発見を提供して"

# 週次振り返り自動サマリー
cat ~/journal/2026-02-{02..08}.md | \
  applefm respond "この一週間の感情変化パターン、達成したこと、来週への提案をまとめて"

# 構造化ジャーナルエントリー
echo "新プロジェクトのキックオフがあった。チームと良い議論ができた" | \
  applefm generate --schema journal.json --format json >> ~/journal/reflections.jsonl
```

### 3-5. プライバシー重視の個人アシスタント

健康情報・財務データ・個人的な悩みなど、クラウド AI では躊躇する相談もオンデバイスなら安心。

```bash
# 健康記録の分析
applefm session new health --instructions "健康管理アシスタントとして。医療診断は行わず、パターン分析と一般的なアドバイスを提供して"
applefm session respond health "今週: 月曜-頭痛, 水曜-胃もたれ, 金曜-肩こり"

# 家計データの整理
cat expenses-202602.csv | applefm generate --schema expense-analysis.json --format json \
  --instructions "支出データを分析して節約アドバイスをください"

# 個人的な悩み相談
applefm chat --instructions "傾聴力のあるカウンセラーとして。アドバイスを押し付けず、考えを整理する手助けをして"

# 確定申告の下調べ
applefm session new tax-prep --instructions "日本の個人の確定申告に関する一般的な情報を提供して"
applefm session respond tax-prep "フリーランスの経費として認められるものの一般例を教えて"
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
  local result = vim.fn.system({ "applefm", "respond", "このコードを説明して" }, text)
  -- フローティングウィンドウで表示
end

-- コミットメッセージ生成 (fugitive 連携)
function M.generate_commit_msg()
  local diff = vim.fn.system("git diff --cached")
  local result = vim.fn.system({ "applefm", "respond",
    "--instructions", "Generate a conventional commit message. Output only the message." }, diff)
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
      "command": "echo '${selectedText}' | applefm respond 'このコードを説明して' --stream",
      "presentation": { "reveal": "always", "panel": "dedicated" }
    },
    {
      "label": "applefm: Generate Unit Test",
      "type": "shell",
      "command": "cat '${file}' | applefm respond 'ユニットテストを生成して' --stream",
      "presentation": { "reveal": "always", "panel": "dedicated" }
    }
  ]
}
```

### 4-3. Git Hooks

毎日何十回も実行されるため、低レイテンシ・オフライン・プライバシーの全ての強みが活きる。

```bash
#!/bin/bash
# .git/hooks/prepare-commit-msg — コミットメッセージ自動生成
COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2
[ -n "$COMMIT_SOURCE" ] && exit 0

git diff --cached | head -500 | applefm respond \
  "Conventional Commits 形式のメッセージを1行で。メッセージのみ出力" \
  --temperature 0.3 > "$COMMIT_MSG_FILE"
```

```bash
#!/bin/bash
# .git/hooks/pre-push — セキュリティスキャン（コードがクラウドに送信されない）
REMOTE=$1
DIFF=$(git diff "$REMOTE/$(git branch --show-current)..HEAD" | head -2000)
RESULT=$(echo "$DIFF" | applefm respond \
  "ハードコードされたシークレットやセキュリティ問題があれば指摘して。問題なければ OK とだけ出力して")

if [ "$RESULT" != "OK" ]; then
  echo "Security concerns: $RESULT"
  read -p "Continue? (y/N) " -n 1 -r
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi
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

pbpaste | applefm respond "$1" | pbcopy
```

```bash
#!/bin/bash
# Alfred ユニバーサルアクション
# 選択テキストに対して翻訳・要約・改善を実行
echo "$1" | applefm respond "$2"
```

### 4-5. Apple エコシステム（Shortcuts / AppleScript / Automator）

ターミナルを使わないユーザーにもリーチできる、applefm 固有の強み。

```
# Apple Shortcuts: 「テキストを要約」
1. [入力を受け取る] → テキスト
2. [シェルスクリプトを実行]: echo "$input" | applefm respond "3行で要約して"
3. [クリップボードにコピー]
```

```bash
# Automator フォルダアクション: テキストファイル追加時に自動要約
for f in "$@"; do
  cat "$f" | applefm respond "要約して" > ~/summaries/"$(basename "$f" .txt)-summary.txt"
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

```bash
#!/bin/bash
# 隣接ペインのエラー出力を自動分析
tmux capture-pane -t '{left}' -p -S -50 | applefm respond "エラーを分析して解決方法を提案して" --stream
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

**パターン A: プライバシーゲート** — 機密コードはオンデバイス、それ以外はクラウド

```bash
if grep -qiE "(api_key|secret|password)" "$FILE"; then
  cat "$FILE" | applefm respond "レビューして"       # オンデバイス
else
  claude -p "Review this code: $(cat "$FILE")"       # クラウド
fi
```

**パターン B: レイテンシ最適化** — 簡単なタスクは即座にオンデバイス

```bash
case "$TASK" in
  "typo"|"format"|"translate"|"commit-msg")
    echo "$CONTENT" | applefm respond "$TASK" ;;       # 即座に応答
  "architecture"|"security-audit")
    claude -p "$TASK: $CONTENT" ;;                     # 深い分析
esac
```

**パターン C: パイプラインチェーン** — オンデバイスで前処理し、クラウドへの送信データを最小化

```bash
# Step 1: applefm でコードベースを要約（機密コードはローカルに留まる）
find src -name "*.ts" | while read f; do
  cat "$f" | applefm respond "このファイルの責務を1行で要約:"
done > /tmp/codebase-summary.txt

# Step 2: 要約のみをクラウドに送信
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
              ├── applefm MCP (プライベートデータ処理)
              │   ├── 社内コードの要約
              │   ├── ローカルファイルの分析
              │   └── 機密ドキュメントの処理
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
