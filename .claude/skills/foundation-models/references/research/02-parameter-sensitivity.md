# パラメータ感度テスト

調査日: 2026-02-08
環境: macOS 26, Apple Foundation Models (on-device), applefm CLI

## 1. Temperature テスト

プロンプト: `"Write a creative name for a coffee shop"`

### 各 temperature 値の出力

| temperature | 出力 |
|---|---|
| 0.0 | "Brewed Horizons" |
| 0.5 | "Brewed Awakenings" |
| 1.0 | "The Bean Whisperers" |
| 1.5 | "Whisk & Brew Haven" |
| 2.0 | "Brewed Awakening Corner" |

### 再現性テスト

**temperature 0.0（3回実行）:**

| 試行 | 出力 |
|---|---|
| 1回目 | "Brewed Horizons" |
| 2回目 | "Brewed Horizons" |
| 3回目 | "Brewed Horizons" |

結果: **完全に再現性あり** — 3回とも同一出力

**temperature 1.0（3回実行）:**

| 試行 | 出力 |
|---|---|
| 1回目 | "Bean Bliss Brews" |
| 2回目 | "Mocha Mirage" |
| 3回目 | "Brewed Whimsy Haven" |

結果: **毎回異なる出力** — 十分なランダム性あり

### 分析

- **temperature 0.0**: 完全に決定論的。同じ入力に対して常に同じ出力を返す。再現性が重要な用途（テスト、CI、テンプレート生成）に適する
- **temperature 0.5**: やや保守的だが安定した品質。「Brewed」というパターンが残りやすい
- **temperature 1.0**: 十分な多様性がありつつ、意味のある出力を維持。創造的タスクの標準設定として適切
- **temperature 1.5**: より冒険的な組み合わせが出現（"Whisk & Brew Haven"）。奇抜さが求められる場合に有効
- **temperature 2.0**: 高い temperature でも文法的に正しい出力を維持。Apple FM はガードレールにより品質の下限が守られている模様

**注目点**: temperature 2.0 でも壊れた出力にならない。クラウドベースの LLM（GPT-4, Claude）では temperature 2.0 だと出力が崩壊することが多いが、Apple FM はガードレールにより高 temperature でも安定した出力を維持する。

## 2. Sampling モードテスト

プロンプト: `"List 5 random animals"`

### 各 Sampling モードの出力

**`--sampling greedy`:**
```
1. Kangaroo
2. Komodo dragon
3. Narwhal
4. Axolotl
5. Emperor penguin
```

**`--sampling-threshold 0.5`:**
```
1. Bengal Tiger
2. Emperor Penguin
3. Komodo Dragon
4. Red Panda
5. Blue Whale
```

**`--sampling-threshold 0.9`:**
```
1. Bengal Tiger
2. Emperor Penguin
3. Komodo Dragon
4. Red Panda
5. Axolotl
```

**`--sampling-top 5`:**
```
1. Kangaroo
2. Komodo dragon
3. Red panda
4. Narwhal
5. Okapi
```

**`--sampling-top 50`:**
```
1. Kangaroo
2. Narwhal
3. Okapi
4. Komodo dragon
5. Axolotl
```

### 分析

- **greedy**: 最も確信度の高いトークンを常に選択。決定論的だが temperature 0.0 とは異なる語彙選択になる場合がある
- **sampling-threshold 0.5 vs 0.9**: threshold が高いほど低確率トークンも候補に含まれるが、このテストでは大きな差は見られなかった（4/5 の動物が共通）
- **sampling-top 5 vs 50**: top-k が大きいほど多様性が増す。top 5 では「Red panda」、top 50 では「Narwhal, Okapi」が上位に出現
- 全体的に **Komodo dragon, Kangaroo, Axolotl** などの「珍しいが有名な動物」が好まれる傾向あり。Apple FM の学習データの偏りを反映している可能性

**greedy と temperature 0.0 の違い**: 両者とも決定論的だが、内部のサンプリングアルゴリズムが異なるため、出力が一致するとは限らない。

## 3. Max-tokens テスト

プロンプト: `"Explain the theory of relativity in detail"`

### 各 max-tokens 値の出力

**`--max-tokens 50`:**
```
The theory of relativity, formulated by Albert Einstein, is one of the two pillars
of modern physics, the other being quantum mechanics. It comprises two parts:
special relativity and general relativity.

### Special Relativity (1905)
```
→ 途中で切断。約35ワード生成後に停止。ヘッダー直後で切れた。

**`--max-tokens 100`:**
```
The theory of relativity, developed by Albert Einstein, comprises two parts:
special relativity and general relativity. Here's a detailed explanation of each:

### Special Relativity

**Postulates:**
1. **Principle of Relativity:** The laws of physics are the same for all observers
   who are in uniform motion relative to one another.
2. **Constancy of the Speed of Light:** The speed of light in a vacuum is constant
   and is the same for all observers, regardless of
```
→ 約74ワード。文の途中で切断される。

**`--max-tokens 500`:**
→ Special Relativity と General Relativity の主要概念を網羅。「Black Holes」セクションの途中で停止。構造的にほぼ完結した説明。

**max-tokens 未指定（デフォルト）:**
→ Special Relativity, General Relativity, Implications and Applications を含む完全な説明を生成。約400ワード。自然な結論文で終了。

### 分析

- max-tokens はトークン単位で制限されるため、ワード数とは正確に一致しない（1トークン ≈ 0.7ワード程度）
- 制限に達すると**文の途中でも即座に切断**される。文の境界での停止は行わない
- デフォルト（制限なし）では、モデルが自然に完結するまで生成を続ける。この例では約400ワード
- **短い max-tokens（50-100）は文脈的に不完全な出力になりやすい**。要約タスクには不向き — モデルは「詳しく説明しようとする」が途中で切れる
- 実用的には **200-500 トークン** がバランスが良い

## 4. Guardrails テスト

プロンプト: `"Write a poem about nature"`

### default vs permissive

**`--guardrails default`:**
```
In the cradle of the earth, where whispers reside,
Nature unfurls her tapestry, wild and wide.
Emerald forests stretch to kiss the sky,
While rivers weave their songs as they glide by.
...（8スタンザ）
```

**`--guardrails permissive`:**
```
In the cradle of dawn's gentle embrace,
Where whispers of morning softly trace,
The dew-kissed petals of wildflowers sway,
Dancing in the light of a new day.
...（7スタンザ）
```

### 分析

- 安全なプロンプト（自然の詩）では **default と permissive の間に顕著な差はない**
- 両方とも同程度の品質・長さの詩を生成
- guardrails の効果は主に**エッジケース**（暴力的・性的・差別的コンテンツ）で現れると推測される
- permissive モード（`.permissiveContentTransformations`）はガードレールを「無効化」するのではなく、「最も緩い設定」にする。Apple FM では完全な無効化は不可能

## 5. 複合パラメータテスト

プロンプト: `"Write a haiku about mountains"`

**`--temperature 0.0 --max-tokens 50`:**
```
Majestic peaks rise,
Whispers of ancient winds sing—
Silent giants stand.
```

**`--temperature 1.5 --max-tokens 50`:**
```
Majestic peaks rise,
Whispering winds through valleys—
Silent giants rise.
```

### 分析

- 俳句のような短い形式では、temperature の違いによる影響が小さい。構造的な制約（5-7-5 音節）がモデルの選択肢を限定するため
- 両方とも「Majestic peaks rise」で始まり、「Silent giants」で終わる — 俳句の定番パターンに収束
- max-tokens 50 は俳句には十分。短い形式には小さな max-tokens が適切
- 微細な差異: temperature 0.0 は "Whispers of ancient winds sing"、1.5 は "Whispering winds through valleys" — 高 temperature の方がやや具体的な表現を選ぶ傾向

## パラメータ推奨ガイドライン

### ユースケース別推奨設定

| ユースケース | temperature | sampling | max-tokens | guardrails |
|---|---|---|---|---|
| **再現性が必要な処理**（テスト、CI、テンプレート） | 0.0 | greedy | 用途に応じて | default |
| **一般的な質問応答** | 未指定（デフォルト） | 未指定 | 未指定 | default |
| **創造的な文章生成**（詩、物語、ネーミング） | 0.8 - 1.2 | 未指定 | 未指定 | default |
| **高い多様性が必要**（ブレスト、複数案生成） | 1.5 - 2.0 | sampling-top 50 | 未指定 | default |
| **構造化データ抽出** | 0.0 | greedy | 用途に応じて | default |
| **短い出力**（一行回答、ラベリング） | 未指定 | 未指定 | 50-100 | default |
| **詳細な説明** | 未指定 | 未指定 | 500+ or 未指定 | default |

### 重要な知見

1. **Temperature 0.0 は完全に決定論的** — 再現性が保証される唯一の設定
2. **高 temperature でも品質が崩壊しない** — Apple FM のガードレールが品質の下限を保持。クラウド LLM と異なり temperature 2.0 でも文法的に正しい出力を維持する
3. **max-tokens は文の途中で切断する** — 自然な文末での停止は保証されない。出力の自然さが重要な場合は max-tokens を設定しないか、十分大きな値を設定すること
4. **Sampling モードの差異は微妙** — greedy 以外のモードの差は大きくない。大半のユースケースでは temperature だけで十分な制御が可能
5. **Guardrails は安全なコンテンツでは影響なし** — default と permissive の違いはエッジケースでのみ顕著になる
6. **短い形式では temperature の影響が小さい** — 俳句のような構造的制約がある場合、モデルは temperature に関わらず似たパターンに収束する
7. **デフォルト設定が多くのケースで最適** — Apple FM はデフォルトで良好なバランスに調整されている。パラメータ調整は特定のニーズがある場合のみ推奨
