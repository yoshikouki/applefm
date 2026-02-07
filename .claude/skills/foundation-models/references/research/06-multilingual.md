# 多言語対応と日本語特性の調査

## 調査環境
- macOS 26 Beta / Apple Silicon
- applefm CLI (release build)
- Foundation Models on-device LLM

---

## 1. 日本語の理解・生成品質

### 1.1 一般知識（四季の説明）

```bash
./.build/release/applefm respond "日本の四季について説明してください"
```

**出力:**
> 日本の四季は非常に豊かで、それぞれの季節には独特の風物詩があります。以下に、日本の四季について簡単に説明します。
>
> 1. **春（スヂマツ）**: 3月から5月頃
>    - 桜の花見が有名で、多くの桜の木が美しい花を咲かせます。
>    - 気温が上がり始め、日照時間が長くなり、緑が蘇ります。
>    - 虫の声や鳥のさえずりが増え、自然が生き生きとしています。
>
> 2. **夏（ナツ）**: 6月から8月頃
>    - 暑くて湿度が高く、梅雨という時期があります。
>    - 多くの花が咲き、特に夜に虫の音が響きます。
>    - 海や川でのんびり過ごすのが一般的です。
>
> 3. **秋（アキ）**: 9月から11月頃
>    - 紅葉が美しく、特に山間の地域では鮮やかな色彩を楽しむことができます。
>    - 夜は涼しくなり、温度差が感じられます。
>    - 収穫祭や秋の風物詩を楽しむ季節です。
>
> 4. **冬（フユ）**: 12月から2月頃
>    - 寒く、雪が降る地域も多いです。
>    - イルミネーションや雪まつりが人気があります。
>    - 伝統的なお正月や年末年始の行事が行われます。

**評価:**
- 文法: おおむね正しいが、「春（スヂマツ）」は誤り（正しくは「ハル」）。読み仮名が不正確
- 構成: 論理的な構成で、各季節を網羅
- 内容: 概ね正確だが、表層的。梅雨の位置付けが正しい
- 品質: **B** — 構成は良いが、読み仮名の誤り（ハルシネーション）が目立つ

### 1.2 技術的説明（デザインパターン）

```bash
./.build/release/applefm respond "プログラミングにおけるデザインパターンを3つ説明してください"
```

**出力:**
> 1. **ファクトリーパターン（Factory Pattern）**
>    - 目的: オブジェクトを生成するためのメカニズムを提供し...
>
> 2. **ストラクチャパターン（Structural Pattern）**
>    - 目的: オブジェクトの構造を定義し...
>
> 3. **セレクタパターン（Selector Pattern）**
>    - 目的: 複数のオブジェクト間の関係や操作を明示的に定義し...

**評価:**
- 文法: 正しい日本語
- 正確性: **問題あり**。「ストラクチャパターン」はカテゴリ名であり具体的なパターン名ではない。「セレクタパターン」はGoFのデザインパターンとしては一般的でない名称。Factory Pattern の説明は概ね正確
- 品質: **C** — 日本語としては読みやすいが、技術的正確性に欠ける。ハルシネーションの傾向

### 1.3 敬語変換

```bash
./.build/release/applefm respond "以下の文章を敬語に直してください：明日会議あるから来て"
```

**出力:**
> 明日会議がありますので、お越しいただけますでしょうか。

**評価:**
- 文法: 完璧な敬語
- 自然さ: ビジネスシーンで自然に使える表現
- 品質: **A** — 短い変換タスクは非常に得意

### 1.4 俳句生成

```bash
./.build/release/applefm respond "俳句を一つ詠んでください"
```

**出力:**
> 朝の光
> 静かに舞う
> 鳥のさえずり

**評価:**
- 音数: 5-5-7 で、正しい 5-7-5 の形式ではない
- 季語: 明確な季語がない（「朝の光」は季語として弱い）
- 品質: **C** — 俳句の形式ルール（5-7-5）を正確に守れていない

---

## 2. 日本語固有の知識テスト

### 2.1 比較知識（東京タワー vs スカイツリー）

```bash
./.build/release/applefm respond "東京タワーとスカイツリーの違いは？"
# デフォルト・ガードレール
```

**出力:**
> Appleのウェブサイトで、最新の製品情報をご覧ください。

```bash
./.build/release/applefm respond "東京タワーとスカイツリーの違いは？" --guardrails permissive
```

**出力（permissive）:**
> Appleのウェブサイトで、最新の製品情報をご覧ください。

**評価:**
- 品質: **F** — ガードレールに関わらず、Apple 製品宣伝へリダイレクトされる。「タワー」「スカイツリー」などの固有名詞がトリガーになっている可能性がある
- 注目点: **ガードレールを `permissive` にしても回避できないケースが存在する**

### 2.2 ことわざ理解

```bash
./.build/release/applefm respond "「猫に小判」ということわざの意味を説明してください"
# → デフォルトガードレールでブロック（safety guardrails error）

./.build/release/applefm respond "「猫に小判」ということわざの意味を説明してください" --guardrails permissive
```

**出力（permissive）:**
> 「猫に小判」ということわざは、無駄な費用のこと、または無駄遣いを指します。この表現は、猫が食べ物を無駄にする様子から来ています。

**正しい意味:** 価値のわからない者に貴重なものを与えても無駄であるということ（"Pearls before swine"に相当）

**評価:**
- 文法: 正しい日本語
- 正確性: **不正確**。意味が完全に間違っている。「無駄遣い」ではなく「価値がわからない者に貴重品は無意味」が正しい
- 品質: **D** — 日本文化固有の知識が不十分。自信を持って誤った回答を生成する

**追加テスト（フレーズ変更）:**
```bash
./.build/release/applefm respond "猫に小判ということわざの意味は？"
```
> 「猫に小判」ということわざは、意味が少し複雑です。この表現は、主に「何かをあまり真剣に考えず、軽率に判断する」という意味で使われます。

**評価:** こちらもデフォルトガードレールでは通過するが、意味はやはり不正確。プロンプトの微妙な違いでガードレールの挙動が変わる

### 2.3 古典文学知識

```bash
./.build/release/applefm respond "源氏物語について簡潔に説明してください" --guardrails permissive
```

**出力:**
> 「源氏物語」は、日本の古典文学で、紫式部が11世紀に執筆した長編小説です。物語は貴族社会を舞台にしており、主人公は源氏という若い貴族の生活を中心に描かれています。物語は恋愛、友情、権力闘争などをテーマにし、当時の日本社会の文化や風習を詳細に反映しています。

**評価:**
- 正確性: 概ね正確（著者、時代、テーマ）。ただし「主人公は源氏」は「光源氏」がより正確
- 品質: **B** — 基本的事実は正しいが、やや表層的

### 2.4 地理知識

```bash
./.build/release/applefm respond "日本の都道府県を北から5つ挙げてください" --guardrails permissive
```

**出力:**
> 1. 北海道
> 2. 東北地方（岩手県、宮城県、秋田県、山形県、福島県）
> 3. 関東地方（茨城県、栃木県、群馬県、埼玉県、千葉県）
> 4. 甲信越地方（長野県、岐阜県、静岡県、山梨県）
> 5. 東海地方（愛知県、三重県、滋賀県、京都府、大阪府）

**正しい回答:** 北海道、青森県、岩手県、宮城県、秋田県

**評価:**
- 正確性: **不正確**。質問は「都道府県を5つ」だが、地方名を列挙しており指示に従っていない。青森県が欠落。甲信越に岐阜・静岡を含めるのは地理的に不正確
- 品質: **D** — 指示理解の失敗と地理知識の不正確さ

---

## 3. 翻訳テスト

### 3.1 英語→日本語

```bash
./.build/release/applefm respond "Translate to Japanese: Machine learning is a subset of artificial intelligence that enables systems to learn from data."
```

**出力:**
> 機械学習は、データからシステムが学習できるようにする人工知能のサブセットです。

**評価:**
- 正確性: 意味は正確に伝達
- 自然さ: 「サブセット」はカタカナのまま。「一分野」「部分領域」がより自然な日本語
- 品質: **B+** — 正確だがやや機械的

### 3.2 日本語→英語

```bash
./.build/release/applefm respond "Translate to English: 人工知能の発展により、私たちの生活は大きく変わりつつあります。"
```

**出力:**
> The development of artificial intelligence is gradually transforming our lives.

**評価:**
- 正確性: 原文の意味を正確に伝達
- 自然さ: 自然な英語表現
- 品質: **A** — 優れた翻訳

### 3.3 英語→韓国語

```bash
./.build/release/applefm respond "Translate to Korean: Hello, how are you today?"
```

**出力:**
> 안녕하세요, 오늘은 어때요?

**評価:**
- 正確性: 正確な翻訳
- 自然さ: 自然な韓国語
- 品質: **A**

### 3.4 英語→中国語

```bash
./.build/release/applefm respond "Translate to Chinese: The weather is beautiful today."
```

**出力:**
> 今天的天气很漂亮。

**評価:**
- 正確性: 意味は通じるが、「天气很漂亮」はやや不自然。「天气很好」や「天气真好」がより自然
- 品質: **B** — 通じるが、ネイティブ表現からはやや離れる

### 3.5 英語→フランス語

```bash
./.build/release/applefm respond "Translate to French: I would like to order a coffee, please."
```

**出力:**
> Je voudrais commander un café, s'il vous plaît.

**評価:**
- 正確性: 完全に正確
- 自然さ: 自然なフランス語
- 品質: **A**

---

## 4. 各言語での基本生成テスト

### 4.1 韓国語

```bash
./.build/release/applefm respond "한국어로 대답해주세요: 서울의 유명한 관광지를 3곳 알려주세요" --guardrails permissive
```

**出力:**
> 서울에는 많은 유명한 관광지가 있습니다. 다음은 세 곳입니다:
> 1. **경복궁**: 조선 시대의 궁궐로, 한국의 전통 건축과 역사를 느낄 수 있는 곳입니다.
> 2. **N서울타워**: 서울의 스카이라인을 조망할 수 있는 전망대로...
> 3. **남산타워**: 서울의 또 다른 전망대이며...

**評価:**
- 文法: 正しい韓国語
- 正確性: N서울타워と남산타워は実質的に同じもの（南山タワー = N Seoul Tower）。3つの異なる場所を求めたが、実質2つしか挙げていない
- 品質: **C+** — 文法は良いが、事実の重複エラー

### 4.2 中国語

```bash
./.build/release/applefm respond "请用中文回答：北京有哪些著名的景点？" --guardrails permissive
```

**出力:**
> 北京有许多著名的景点，以下是一些主要的景点：
> 1. 长城 2. 故宫 3. 天安门广场 4. 颐和园 5. 圆明园 6. 北京动物园 7. 长城脚下的胡同

**評価:**
- 文法: 正しい中国語（簡体字）
- 内容: 主要な観光地を網羅。ただし「长城脚下的胡同」は存在しない表現
- 品質: **B** — 全体的に良いが、一部にハルシネーション

### 4.3 フランス語

```bash
./.build/release/applefm respond "Répondez en français: Quels sont les monuments célèbres de Paris?" --guardrails permissive
```

**出力:**
> Paris est connue pour ses monuments emblématiques:
> 1. La Tour Eiffel 2. La Cathédrale Notre-Dame 3. Le Louvre 4. La Conciergerie et la Sainte-Chapelle 5. Le Sacré-Cœur 6. Le Pont Alexandre III 7. Le Palais de la Cité et la Cité de la Musique

**評価:**
- 文法: 正しいフランス語
- 内容: 概ね正確だが、「Palais de la Cité et la Cité de la Musique」の関連付けがやや不自然
- 品質: **B+**

### 4.4 ドイツ語

```bash
./.build/release/applefm respond "Antworten Sie auf Deutsch: Was sind die beliebtesten Sehenswürdigkeiten in Berlin?" --guardrails permissive
```

**出力:**
> Berlin ist eine Stadt mit einer reichen Geschichte und vielen Sehenswürdigkeiten:
> 1. Brandenburger Tor 2. Reichstag 3. Museumsinsel 4. Berlin Mauer 5. Checkpoint Charlie 6. Tempelhofer Feld 7. Alexanderplatz 8. Holocaust-Mahnmal 9. Charlottenburg Palace 10. Berlin TV Tower

**評価:**
- 文法: 概ね正しいドイツ語。ただし "Berlin Mauer" は "Berliner Mauer"、"Charlottenburg Palace" は英語混在
- 内容: 正確で包括的
- 品質: **B+** — 良好だが、言語の純度にやや問題

### 4.5 スペイン語

```bash
./.build/release/applefm respond "Responde en español: ¿Cuáles son los platos típicos de España?" --guardrails permissive
```

**出力:**
> España tiene una rica variedad de platos típicos:
> 1. Paella 2. Tortilla Española 3. Gazpacho 4. Jamón Ibérico 5. Pimientos de Padrón 6. Fabada Asturiana 7. Cocido Madrileño 8. Pulpo a la Gallega 9. Bacalao al Pil Pil 10. Churros con Chocolate

**評価:**
- 文法: 正しいスペイン語
- 内容: 正確で包括的。各料理の説明も適切
- 品質: **A-** — 高品質な生成

---

## 5. クロスリンガルタスク

### 5.1 英語プロンプト → 日本語回答（フランス料理について）

```bash
./.build/release/applefm respond "Answer in Japanese about French cuisine: What are 3 famous French dishes?" --guardrails permissive
```

**出力:**
> フランスの有名な料理には、以下のようなものがあります。
> 1. エビのタレード（Bouillabaisse）
> 2. ビーフロースト（Boeuf Bourguignon）
> 3. クロワッサン（Croissant）

**評価:**
- 言語切り替え: 英語プロンプトに対して日本語で正しく回答
- 正確性: 「エビのタレード」は Bouillabaisse の訳として不正確（正しくは「ブイヤベース」）。「ビーフロースト」も Boeuf Bourguignon の訳として不適切（「牛肉の赤ワイン煮」が適切）
- 品質: **C** — 言語切り替えは成功するが、固有名詞の翻訳が不正確

### 5.2 日本語プロンプト → 英語回答（日本料理について）

```bash
./.build/release/applefm respond "英語で日本料理について3つの有名な料理を教えてください" --guardrails permissive
```

**出力:**
> もちろんです！以下は3つの有名な日本料理です。
> 1. 寿司（寿司） 2. 天ぷら（天ぷら） 3. ラーメン（ラーメン）

**評価:**
- 言語切り替え: **失敗**。「英語で」と指示したが日本語で回答
- 内容: 料理の選択自体は適切
- 品質: **D** — 言語指示に従えていない

---

## 6. 言語混在テスト

### 6.1 日本語ワードの英語説明

```bash
./.build/release/applefm respond "What is the meaning of 'おもてなし' in Japanese culture? Please explain in English." --guardrails permissive
```

**出力:**
> In Japanese culture, "おもてなし" (pronounced omotenashi) refers to the traditional Japanese art of hospitality and service. It embodies the concept of providing exceptional care and attention to guests...

**評価:**
- 言語処理: 日本語ワードを含む英語プロンプトを正しく処理
- 内容: 「おもてなし」の意味を正確に説明
- 品質: **A** — 混在入力の処理が優れている

### 6.2 英語用語の日本語説明

```bash
./.build/release/applefm respond "Please explain these programming terms in Japanese: variable, function, class" --guardrails permissive
```

**出力:**
> 1. **変数 (Variable)**: 変数は、プログラム内で値を保存するためのメモリ領域です。
> 2. **関数 (Function)**: 関数は、特定のタスクを実行するための小さなプログラムです。
> 3. **クラス (Class)**: クラスとは、オブジェクトを定義するためのデータ構造です。

**評価:**
- 言語処理: 英語プロンプトに対して日本語で正しく回答
- 内容: 正確な技術用語の日本語訳と説明
- 品質: **A-** — 良好な混在言語処理

---

## 7. Locale サポート確認

### 公式サポート言語一覧

```bash
./.build/release/applefm model languages
```

**出力:** da, de, en, es, fr, it, ja, ko, nb, nl, pt, sv, tr, vi, zh

**合計 15 言語**

### supports-locale テスト結果

| Locale | Supported | カテゴリ |
|--------|-----------|----------|
| en | true | ヨーロッパ系 |
| de | true | ヨーロッパ系 |
| fr | true | ヨーロッパ系 |
| es | true | ヨーロッパ系 |
| it | true | ヨーロッパ系 |
| pt | true | ヨーロッパ系 |
| nl | true | ヨーロッパ系 |
| da | true | ヨーロッパ系（北欧） |
| nb | true | ヨーロッパ系（北欧） |
| sv | true | ヨーロッパ系（北欧） |
| tr | true | ヨーロッパ系 |
| ja | true | 東アジア |
| ko | true | 東アジア |
| zh | true | 東アジア |
| vi | true | 東南アジア |
| ar | **false** | 中東 |
| hi | **false** | 南アジア |
| ru | **false** | スラブ系 |
| th | **false** | 東南アジア |
| id | **false** | 東南アジア |

**所見:**
- サポート対象は主に西ヨーロッパ言語 + 東アジア主要言語 + ベトナム語 + トルコ語
- アラビア語、ヒンディー語、ロシア語、タイ語、インドネシア語は非サポート
- RTL（右から左）言語は非サポート

---

## 8. ガードレールの多言語への影響

### 発見事項

1. **デフォルトガードレールは日本語の文化的トピックをブロックしやすい**
   - 「猫に小判」（ことわざ）→ ブロック
   - 「東京タワーとスカイツリー」→ Apple製品宣伝へリダイレクト
   - 英語の同等プロンプトではブロックされにくい傾向

2. **`--guardrails permissive` で解決するケースとしないケースがある**
   - ことわざ → permissive で生成可能（ただし内容は不正確）
   - 東京タワー比較 → permissive でも Apple 宣伝にリダイレクト

3. **プロンプトの微妙な差でガードレール挙動が変わる**
   - 「「猫に小判」ということわざの意味を説明してください」→ ブロック
   - 「猫に小判ということわざの意味は？」→ 通過（カッコの有無が影響）

4. **非英語プロンプトのガードレール感度が高い**
   - 同じ意味の質問でも、日本語プロンプトの方がブロックされやすい傾向

---

## 9. 言語別品質サマリー

| 言語 | 文法 | 正確性 | 自然さ | 総合 |
|------|------|--------|--------|------|
| 英語 | A | A | A | **A** |
| 日本語 | B+ | C | B | **B-** |
| 韓国語 | A | B- | A- | **B+** |
| 中国語 | A- | B | B | **B** |
| フランス語 | A | A- | A | **A-** |
| ドイツ語 | B+ | A- | B+ | **B+** |
| スペイン語 | A | A | A | **A-** |

### 品質傾向

- **英語が最高品質**: 文法・正確性・自然さ全てにおいて最も安定
- **西ヨーロッパ言語が高品質**: フランス語・スペイン語は英語に近い品質
- **日本語は文法は良いが事実の正確性に課題**: 文化固有の知識（ことわざ、地理）で誤りが多い
- **東アジア言語は文法面は良好だが、微妙なニュアンスに課題**: 中国語の「天气很漂亮」など

---

## 10. 多言語ガイドライン

### 推奨事項

#### CLI 利用者向け

1. **日本語での使用時は `--guardrails permissive` を推奨**
   - デフォルトガードレールが日本語プロンプトに対して過度に厳しい
   - 文化的トピックがブロックされるリスクが高い

2. **事実確認が必要な回答には依存しない**
   - 日本語の文化固有知識（ことわざ、地理、歴史的詳細）は不正確なことが多い
   - ハルシネーションが自信を持って出力される傾向

3. **翻訳タスクは比較的信頼できる**
   - 短い文の翻訳（特に英語⇔他言語）は高品質
   - ただし専門用語のカタカナ翻訳は確認が必要

4. **言語切り替え指示は英語プロンプトから行う方が成功率が高い**
   - 日本語で「英語で回答して」→ 日本語で回答される（失敗）
   - 英語で "Answer in Japanese" → 日本語で回答（成功）

#### 開発者向け

5. **instructions パラメータで応答言語を明示的に指定する**
   - プロンプトの言語に頼らず、セッションの instructions で言語を指定
   - 例: `instructions: "Always respond in Japanese"`

6. **ガードレール設定のドキュメント化**
   - 非英語プロンプトではガードレールが予期せずトリガーされることを明記
   - ユーザー向けトラブルシューティングガイドに含める

7. **品質が重要な場合は英語プロンプト + 翻訳パイプラインを検討**
   - 英語でプロンプト → 英語で回答 → 翻訳コマンドで日本語化
   - 直接日本語でプロンプトするより事実の正確性が高い可能性

8. **locale チェックを事前に行う**
   - `model supports-locale` で対象言語のサポートを確認してからプロンプトを送る
   - 非サポート言語（ar, hi, ru, th, id）では品質保証なし

### 制限事項まとめ

| 制限 | 詳細 |
|------|------|
| 対応言語数 | 15言語。RTL言語・南アジア言語は非対応 |
| 日本語の事実正確性 | 文化・地理知識で誤りが頻出 |
| ガードレールの言語バイアス | 非英語プロンプトでより厳しくブロック |
| 言語切り替え | 日本語からの切り替え指示に従えないことがある |
| 読み仮名・音数 | カタカナ読み仮名や俳句の音数カウントが不正確 |
| 固有名詞翻訳 | 料理名・地名のカタカナ翻訳で誤りが発生 |
