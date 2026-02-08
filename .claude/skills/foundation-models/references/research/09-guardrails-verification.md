# Guardrails + Default Instructions 修正効果の検証

調査日: 2026-02-08
対象コミット: 1c6ceda (fix(chat): add default instructions and permissive guardrails for interactive mode)
環境: macOS 26, Apple Foundation Models (on-device LLM), applefm CLI (release build)

## 修正内容の概要

コミット 1c6ceda で以下の変更が行われた:

1. **ChatCommand**: `fallbackGuardrails: .permissive` でモデル作成、`InteractiveLoop.defaultInstructions` をフォールバック Instructions に設定
2. **RespondCommand**: TTY でインタラクティブモードに入る場合のみ permissive guardrails + defaultInstructions を適用。**通常の one-shot モードは変更なし**
3. **InteractiveLoop.defaultInstructions**: `"You are a helpful assistant. Respond naturally and conversationally. Answer in the same language the user writes in."`

---

## 1. 以前ブロックされた日本語プロンプトの再テスト (respond コマンド)

### 1a. 「日本の首都はどこですか？」

```bash
./.build/release/applefm respond "日本の首都はどこですか？"
```

> Appleのウェブサイトで最新の製品情報をご覧ください。

```bash
./.build/release/applefm respond "日本の首都はどこですか？" --guardrails permissive
```

> Appleのウェブサイトで、最新の製品情報をご覧ください。

**前回調査との比較**: 変化なし。respond one-shot モードは修正の影響を受けない設計のため、デフォルトでも permissive でも Apple 宣伝にリダイレクトされる。

```bash
./.build/release/applefm respond "日本の首都はどこですか？" --guardrails permissive --instructions "You are a helpful assistant. Answer in the same language the user writes in."
```

> 日本の首都は東京です。

**重要な発見**: `--guardrails permissive` **単体では不十分**だが、**Instructions を追加すると正しく回答できる**。Instructions がモデルの挙動を正常化する決定的な要因であることが判明。

### 1b. ことわざ「猫に小判」

```bash
./.build/release/applefm respond "「猫に小判」ということわざの意味を説明してください"
```

> Error: Request was blocked by safety guardrails. Try rephrasing or use --guardrails permissive. (Exit code 1)

```bash
./.build/release/applefm respond "「猫に小判」ということわざの意味を説明してください" --guardrails permissive
```

> 「猫に小判」ということわざは、無駄遣いや無駄な支出を指します。この表現は、「猫が小判（お金のこと）を貯めることはない」というニュアンスから来ています。つまり、無駄に使い果たして良い結果が出ないことを意味します。この表現は、浪費や無駄なお金を使うことを戒め、節約を促すためのものです。

**前回調査との比較**: 挙動は同じ。デフォルトでブロック、permissive で生成可能だが意味は依然として不正確（正しくは「価値のわからない者に貴重なものを与えても無駄」）。

### 1c. 東京タワー vs スカイツリー

```bash
./.build/release/applefm respond "東京タワーとスカイツリーの違いは？"
```

> Appleのウェブサイトで、最新の製品情報をご覧ください。

```bash
./.build/release/applefm respond "東京タワーとスカイツリーの違いは？" --guardrails permissive
```

> Appleのウェブサイトで、最新の製品情報をご覧ください。

```bash
./.build/release/applefm respond "東京タワーとスカイツリーの違いは？" --guardrails permissive --instructions "You are a helpful assistant. Answer in the same language the user writes in."
```

> 東京タワーとスカイツリーはどちらも東京にある象徴的なタワーですが、いくつかの違いがあります。
> 1. **高さ**: スカイツリーは約634メートル、東京タワーは約333メートル
> 2. **建設年**: 東京タワー1958年、スカイツリー2012年
> 3. **目的**: 東京タワーはテレビ送信塔、スカイツリーも通信設備+観光
> 4. **デザイン**: 東京タワーはシンプルで丸みを帯びた、スカイツリーは鉄骨構造の尖塔型
> 5. **場所**: 東京タワーは赤坂に、スカイツリーは豊島区に

**前回調査との比較**: **大幅改善**。前回は `--guardrails permissive` でも Apple 宣伝にリダイレクトされていた。**Instructions を組み合わせることで完全に解決**。ただし場所の情報は不正確（東京タワーは港区芝公園、スカイツリーは墨田区押上）。

---

## 2. respond コマンドの Instructions 効果テスト

### 2a. Instructions なし

```bash
./.build/release/applefm respond "Tell me about dogs"
```

> (8項目の詳細な箇条書きリスト: Domestication, Breeds, Variety, Temperament, Communication, Health and Care, Role in Society, Training)

### 2b. Instructions あり

```bash
./.build/release/applefm respond "Tell me about dogs" --instructions "Answer in exactly 2 sentences."
```

> Dogs are domesticated mammals belonging to the Canidae family, known for their loyalty, intelligence, and companionship. They have been bred for various purposes, including working, herding, hunting, and companionship, and are one of the most popular pets worldwide.

**前回調査との比較**: 同等の品質。Instructions による形式制御は引き続き効果的。正確に2文で回答。

---

## 3. Chat モードの日本語テスト

### 3a. 「日本の首都はどこですか？」

```bash
echo "日本の首都はどこですか？" | ./.build/release/applefm chat 2>/dev/null
```

> The capital of Japan is Tokyo.

**評価**: 正しく回答できた。ただし日本語で質問したのに英語で回答している。defaultInstructions の "Answer in the same language the user writes in" が完全には遵守されていない。前回の respond コマンドでは Apple 宣伝にリダイレクトされていたため、**ガードレール問題は解決**。言語遵守は部分的。

### 3b. 東京タワー vs スカイツリー

```bash
echo "東京タワーとスカイツリーの違いは？" | ./.build/release/applefm chat 2>/dev/null
```

> Tokyo Tower と Skytree はどちらも東京のランドマークですが、いくつかの点で違いがあります。
> 1. **高さ**: Skytree は東京タワーの約3倍の高さです。正式には 634 メートル
> 2. **目的とデザイン**: Tokyo Tower はテレビ送信塔、Skytree は観光施設としても機能
> 3. **建設時期**: Tokyo Tower は 1958 年、Skytree は 2012 年
> 4. **構造**: Skytree は 2 つの主塔が連結された設計

**評価**: **大幅改善**。前回は permissive でも Apple 宣伝にリダイレクトされていた。Chat モードでは正しく比較情報を生成できた。日本語と英語が混在するが、内容は概ね正確。

### 3c. ことわざ「猫に小判」

```bash
echo "「猫に小判」ということわざの意味を説明してください" | ./.build/release/applefm chat 2>/dev/null
```

> "猫に小判"は、猫が小判（小判は昔の日本の貨幣で、100円分）を貰うような、とても大きな恩恵を与えることを意味します。このことわざは、非常に大きな助けや恩恵を相手に与えることを表しています。

**評価**: ガードレールでブロックされなくなった点は改善。ただし意味は**依然として不正確**（正しくは「価値のわからない者に貴重なものを与えても無駄」）。小判の価値説明（100円分）も事実誤認。モデルの日本文化知識の限界。

---

## 4. 日本語地理知識の再テスト

### 4a. respond + permissive（Instructions なし）

```bash
./.build/release/applefm respond "日本の都道府県を北から5つ挙げてください" --guardrails permissive
```

> 1. 北海道
> 2. 青森県
> 3. 岩手県
> 4. 宮城県
> 5. 秋田県

**前回調査との比較**: **大幅改善**。前回は地方名を列挙し、青森県が欠落していた。今回は正確に個別の都道府県名を北から列挙。

### 4b. respond + permissive + Instructions

```bash
./.build/release/applefm respond "日本の都道府県を北から5つ挙げてください" --guardrails permissive --instructions "正確に都道府県名だけを列挙してください。地方名ではなく個別の都道府県名を回答してください。"
```

> 北海道、青森県、岩手県、宮城県、秋田県

**評価**: 完璧。Instructions で形式も制御でき、簡潔かつ正確な回答。

### 4c. Chat モード

```bash
echo "日本の都道府県を北から5つ挙げてください" | ./.build/release/applefm chat 2>/dev/null
```

> Okay! Here are the top 5 Japanese prefectures from north to south:
> 1. Hokkaido
> 2. Tohoku
> 3. Kanto
> 4. Chubu
> 5. Kansai

**評価**: Chat モードでは品質が低下。英語で回答し、地方名を列挙（前回の respond + permissive と同じ誤り）。Chat モードの defaultInstructions は一般的すぎて、具体的な知識タスクの精度を向上させない。

---

## 5. 以前の事実誤認テストの再実行

### Swift の特徴（Instructions 付き）

```bash
./.build/release/applefm respond "Summarize the key features of the Swift programming language in 3 bullet points" --instructions "Be factually accurate. Swift is a statically typed, compiled language."
```

> - **Statically Typed**: Swift is a statically typed language, meaning that all variables and constants must be declared with a specific type at compile time.
> - **Compiled Language**: Swift is a compiled language, translated from a high-level programming language into machine code before execution.
> - **Modern Features**: Swift incorporates modern programming features such as strong typing, automatic reference counting (ARC), and a focus on safety and performance.

**前回調査との比較**: **大幅改善**。前回は "Dynamic Typing" と "JIT compilation" という重大な事実誤認があった。Instructions で正しい特性を示すことで、モデルが正確な情報を生成。Instructions が事実の正確性制御にも有効であることを確認。

---

## 6. 俳句テスト

### 6a. respond + permissive（Instructions なし）

```bash
./.build/release/applefm respond "俳句を一つ詠んでください" --guardrails permissive
```

> 風の　ささやき　夜空に　星が舞う

**評価**: 5-7-5 の形式ではない。一行で出力されており、俳句の構造を正しく理解できていない。

### 6b. respond + permissive + Instructions

```bash
./.build/release/applefm respond "俳句を一つ詠んでください。5-7-5の音数を厳守してください。" --guardrails permissive --instructions "あなたは俳句の師匠です。5-7-5の音数を必ず守ってください。"
```

> 霧降る　静かな夜空に　星が輝く

**音数分析**: 「き-り-ふ-る」(4) 「し-ず-か-な-よ-ぞ-ら-に」(8) 「ほ-し-が-か-が-や-く」(7) → 4-8-7 で 5-7-5 ではない。

### 6c. Chat モード

```bash
echo "俳句を一つ詠んでください" | ./.build/release/applefm chat 2>/dev/null
```

> 雪に覆われた
> 静かな夜に
> 風が吹き抜ける

**音数分析**: 「ゆ-き-に-お-お-わ-れ-た」(8) 「し-ず-か-な-よ-る-に」(7) 「か-ぜ-が-ふ-き-ぬ-け-る」(8) → 8-7-8 で 5-7-5 ではない。

**総合評価**: 俳句の 5-7-5 音数遵守は、Instructions の有無に関わらず依然として困難。これはモデルの日本語音数カウント能力の限界であり、ガードレール/Instructions 修正では解決できない根本的な制約。

---

## 修正効果まとめ

### 1. 修正が解決した問題

| 問題 | 修正前 | 修正後 (Chat モード) | 修正後 (respond + permissive + instructions) |
|------|--------|---------------------|---------------------------------------------|
| 「日本の首都は？」→ Apple 宣伝 | 常時発生 | **解決** (正しく回答) | **解決** (正しく回答) |
| 「東京タワー vs スカイツリー」→ Apple 宣伝 | permissive でも発生 | **解決** (比較情報を生成) | **解決** (詳細な比較を生成) |
| 「猫に小判」→ ガードレールでブロック | デフォルトでブロック | **ブロック解除** (回答生成) | permissive で以前も通過 |
| Swift の特徴 → "Dynamic Typing" 誤記 | Instructions なしで誤記 | N/A | **解決** (Instructions で正確性向上) |
| 都道府県リスト → 地方名を列挙 | 指示無視 | 改善せず (地方名列挙) | **解決** (正確な都道府県名) |

**核心的な発見**: ガードレール問題の真の原因は `permissive` 設定の不足ではなく、**Instructions（システムプロンプト）の欠如**だった。Instructions なしの場合、モデルは「Apple assistant」として振る舞い、無関係なトピックを Apple 製品にリダイレクトする傾向がある。Instructions を設定することで、モデルが汎用アシスタントとして振る舞うようになり、ガードレールの過剰発動が抑制される。

### 2. 依然として残る問題

| 問題 | 状況 | 根本原因 |
|------|------|----------|
| 日本文化知識の不正確さ | 「猫に小判」の意味が間違い | モデルの学習データの限界 |
| 俳句の 5-7-5 音数遵守 | Instructions 強化でも遵守不可 | 日本語の音数カウント能力の欠如 |
| Chat モードの言語遵守 | 日本語入力に英語で回答する場合あり | defaultInstructions の効果が限定的 |
| Chat モードの知識精度 | 都道府県を地方名で回答 | Instructions が一般的すぎて知識タスクの精度不足 |
| respond one-shot の Apple 宣伝 | --guardrails permissive だけでは解決しない | Instructions なしの one-shot で発生 |
| 事実の正確性 | 東京タワーの場所が「赤坂」(誤: 港区芝公園) | モデルの知識精度の限界 |

### 3. 追加の推奨事項

#### 即座に対応可能

1. **respond one-shot にもデフォルト Instructions を適用する検討**
   - 現在は Chat/インタラクティブモードのみに適用。one-shot でも Instructions を設定すれば品質が大幅に向上することが実証された
   - ただし、one-shot は「明示的に指定された設定のみで動作する」という設計思想との整合性を考慮する必要がある

2. **defaultInstructions の改善**
   - 現在: `"You are a helpful assistant. Respond naturally and conversationally. Answer in the same language the user writes in."`
   - 言語遵守が不完全。より強い指示（例: `"You MUST respond in the same language the user writes in."`）を検討
   - または日本語 locale 検出時に日本語指示を追加する仕組み

3. **`--guardrails permissive` のデフォルト化検討**
   - 日本語利用では permissive がほぼ必須。設定ファイルでデフォルトを変更可能にする（既に `config set` で可能かもしれないが、ドキュメント化が必要）

#### 中長期的な課題

4. **Instructions テンプレートの提供**
   - タスク別の推奨 Instructions を `config preset` として提供（例: `japanese-assistant`, `code-review`, `translation`）
   - 特に日本語利用者向けのプリセットは需要が高い

5. **「猫に小判」等の文化知識問題はモデルの限界として文書化**
   - ユーザーが Apple Foundation Models の限界を理解できるよう、ドキュメントに明記

6. **Instructions + guardrails の組み合わせ効果をユーザーガイドに記載**
   - `--guardrails permissive` だけでは不十分なケースがあること
   - Instructions との組み合わせが重要であることを明記
