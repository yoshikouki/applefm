---
name: cli-verification
description: applefm CLI の動作検証を tmux で実行する。実装完了後の手動検証フェーズで使う。
---

# CLI 動作検証 (tmux)

`applefm` はインタラクティブ REPL (`chat` コマンド) を持つため、パイプ入力では正しく検証できない。tmux を使ってセッションを操作する。

## 手順

### 1. tmux セッション作成

```bash
tmux new-session -d -s applefm-test -x 120 -y 30
```

### 2. CLI 起動

```bash
tmux send-keys -t applefm-test "swift run applefm <command>" Enter
```

ビルド完了を待つ:

```bash
sleep 5 && tmux capture-pane -t applefm-test -p
```

### 3. 入力送信と応答確認

```bash
tmux send-keys -t applefm-test "<input>" Enter
sleep 8 && tmux capture-pane -t applefm-test -p
```

- Foundation Models の応答には数秒かかるため `sleep` で待機
- `capture-pane -p` で現在の画面内容を標準出力に取得

### 4. 終了

```bash
tmux send-keys -t applefm-test "/quit" Enter
sleep 2 && tmux kill-session -t applefm-test
```

## コマンド別の検証ポイント

| コマンド | 検証内容 |
|---|---|
| `chat` | REPL 起動、応答生成、ログ出力 (`~/.applefm/logs/session-*.jsonl`)、セッション保存 (`~/.applefm/sessions/`) |
| `respond` | 一発応答、TTY なし時の動作 |
| `session respond <name>` | 既存セッションの継続 |
| `model availability` | モデル状態の表示 |
| `config list` | 設定一覧の表示 |

## 注意事項

- Foundation Models は macOS 26+ かつ対応ハードウェアが必要
- 応答時間はデバイス性能に依存する。`sleep` の値は適宜調整
- tmux セッション名 `applefm-test` は固定。既存セッションがある場合は先に `tmux kill-session -t applefm-test` で削除
