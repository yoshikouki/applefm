---
name: release
description: applefm のリリース手順とチェックリスト。リリース準備・バージョン更新・Homebrew 配布時に使う。
---

# Release

## Distribution

- Homebrew tap: `yoshikouki/homebrew-applefm`
- リリースフロー: タグ push → GitHub Actions → GitHub Release 作成 + Homebrew formula 自動更新
- 必要な Secret: `HOMEBREW_TAP_TOKEN` — `yoshikouki/homebrew-applefm` への書き込み権限を持つ Fine-grained PAT

## Checklist

リリース前に必ず以下を確認すること:

1. **バージョン更新**: `AppleFM.swift` の `version:` を更新。`CommandParsingTests` のバージョンアサーションも更新
2. **ドキュメント同期**: 新しいコマンド・オプション追加時、以下を更新:
   - `docs/cli-design.md`: コマンドツリー、API マッピング、共通オプション、データ永続化
   - `README.md`: Commands ツリー、Common Options テーブル、使用例
   - `CLAUDE.md`: Architecture セクション（→ `.claude/skills/architecture/SKILL.md`）
3. **テストカバレッジ**: 新機能には最低限のユニットテストを含める。新コマンドには CommandParsingTests にサブコマンドアサーションを追加
4. **パーミッション一貫性**: ファイル書き込みコードは 0o700 (dir) / 0o600 (file) を設定
5. **設定統合**: 新しい OptionGroup フィールドは Optional 型 + `withSettings()` の nil チェックパターンに従う
6. **ビルド検証**: `swift build && swift test && swift run applefm --version`
