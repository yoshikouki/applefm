# 基本テキスト生成の品質・特性調査

調査日: 2026-02-08
環境: macOS 26, Apple Foundation Models (on-device LLM), applefm CLI

## 1. 基本的な質問応答

### 1a. 英語 - 事実質問

```bash
./.build/release/applefm respond "What is the capital of France?"
```

> The capital of France is Paris.

**評価**: 正確、簡潔。事実質問に対して過不足のない回答。

### 1b. 日本語 - 事実質問

```bash
./.build/release/applefm respond "日本の首都はどこですか？"
```

> Appleのウェブサイトで、最新の製品情報をご覧ください。

**評価**: **不正確** - 質問と全く無関係な回答。Apple製品の宣伝のような出力が返された。日本語での事実質問に対して著しく品質が低下する事例。再現性を確認する必要がある。

### 1c. 英語 - 概念説明

```bash
./.build/release/applefm respond "Explain quantum computing in simple terms"
```

> Quantum computing is a type of computing that uses the principles of quantum mechanics to process information. Unlike traditional computers, which use bits as the smallest unit of information (either 0 or 1), quantum computers use quantum bits, or qubits.
>
> Here are some key concepts to understand quantum computing:
>
> 1. **Superposition**: A qubit can exist in a state of both 0 and 1 simultaneously, thanks to superposition. This means a quantum computer can explore multiple possibilities at once, unlike classical computers that process one possibility at a time.
>
> 2. **Entanglement**: This is when qubits become interconnected in such a way that the state of one qubit instantly influences the state of another, no matter how far apart they are. This property allows quantum computers to perform complex calculations more efficiently.
>
> 3. **Quantum Interference**: Quantum algorithms can use interference to amplify the correct solutions and cancel out incorrect ones, which can lead to faster computation for certain problems.
>
> Quantum computing is particularly promising for solving problems that are hard for classical computers, such as factoring large numbers (important for cryptography) or simulating quantum systems (which are crucial for materials science and chemistry). However, it's still in the early stages of development and faces significant challenges, such as maintaining qubit stability and error correction.

**評価**: 高品質。構造化された説明で、重要な概念（重ね合わせ、量子もつれ、量子干渉）を網羅。平易な言葉で説明しつつも技術的に正確。

### 1d. 日本語 - 概念説明

```bash
./.build/release/applefm respond "量子コンピュータを簡単に説明してください"
```

> 量子コンピュータは、量子力学に基づいた計算を行うコンピュータの一種です。従来のコンピュータが0と1のビットを使って情報を処理するのに対し、量子コンピュータは量子ビット、つまり「キュービット」を使って情報を処理します。キュービットは、0、1、または両方の状態を同時に持つことができる「スーパーポジション」という性質を持っています。これにより、量子コンピュータは非常に多くの計算パターンを同時に試すことができ、特に複雑な問題を高速に解くことができます。
>
> 量子コンピュータは、例えば暗号解読、シミュレーション、最適化問題など、従来のコンピュータでは計算が困難な分野で大きな可能性を秘めています。ただし、量子コンピュータはまだ実用化段階にあり、開発には多くの技術的課題が伴っています。

**評価**: 良好。内容は正確で流暢な日本語。英語版ほど詳細ではないが、簡潔な説明としては適切。1b の失敗とは対照的に、こちらの日本語質問では正常に動作している。

---

## 2. 要約タスク

### 2a. 英語 - 箇条書き要約

```bash
./.build/release/applefm respond "Summarize the key features of the Swift programming language in 3 bullet points"
```

> - **Dynamic Typing and Strong Typing**: Swift supports dynamic typing with optional type inference, allowing developers to write flexible and expressive code. However, it also provides strong typing for safety and performance, ensuring explicit type declarations for more controlled scenarios.
>
> - **Modern Features and Safety**: Swift incorporates several modern programming features such as generics, optionals, and pattern matching, enhancing code readability and maintainability. It also emphasizes safety through features like memory management control via reference counting and ownership, reducing runtime crashes and errors.
>
> - **Performance Optimization**: Swift is designed with performance in mind, utilizing features like Automatic Reference Counting (ARC) for memory management and Just-In-Time (JIT) compilation to optimize performance. This makes Swift a suitable choice for both mobile and desktop applications.

**評価**: 指示遵守度は高い（3つの箇条書き）。ただし内容に不正確な点がある:
- Swift は「Dynamic Typing」ではなく静的型付け言語
- Swift は JIT コンパイルではなく AOT (Ahead-of-Time) コンパイル
- これらは重大な事実誤認

### 2b. 日本語 - 箇条書き要約

```bash
./.build/release/applefm respond "Swiftプログラミング言語の主な特徴を3つの箇条書きで要約してください"
```

> - **静的型システム**: Swiftは強力な静的型システムを採用しており、型が宣言された時点で予めチェックされるため、プログラムの誤りを早期に発見できます。
>
> - **シンプルでモダンなAPI**: Swiftのインターフェースは簡潔で直感的であり、オブジェクト指向や関数指向のプログラミングが容易に行えます。このため、他の多くのプログラミング言語に比べて学習コストが低いです。
>
> - **パフォーマンスと安全性**: SwiftはC言語に近いパフォーマンスを持ちながら、安全なメモリ管理を実現しています。オート・メモリ・マネージメントシステムにより、動的メモリ管理によるエラーやオーバーフローのリスクを低減しています。

**評価**: 英語版より正確。静的型システムを正しく識別。指示遵守度も高い（3つの箇条書き）。日本語での要約は英語版の誤りを含まない点が興味深い。

---

## 3. コード生成

### 3a. Swift - 素数判定関数

```bash
./.build/release/applefm respond "Write a Swift function that checks if a number is prime"
```

出力（抜粋）:

```swift
func isPrime(_ n: Int) -> Bool {
    if n < 2 {
        return false
    }
    if n % 2 == 0 {
        return false
    }
    for i in stride(from: 3, through: Int(sqrt(Double(n))), by: 2) {
        if n % i == 0 {
            return false
        }
    }
    return true
}
```

**評価**: 高品質。アルゴリズムは正確で、エッジケース（n < 2, 偶数）を適切に処理。ただし `n == 2` の場合に `false` を返すバグがある（偶数チェックで `n > 2` の条件がない）。使用例も豊富に提供されているが、`isPrime(2)` の出力コメントに `true` と書かれているのにコードは `false` を返す矛盾がある。

### 3b. Python - 連結リスト反転

```bash
./.build/release/applefm respond "Write a Python function to reverse a linked list"
```

出力（抜粋）:

```python
class ListNode:
    def __init__(self, value=0, next=None):
        self.value = value
        self.next = next

def reverse_linked_list(head):
    prev = None
    current = head
    while current is not None:
        next_node = current.next
        current.next = prev
        prev = current
        current = next_node
    return prev
```

**評価**: 高品質。反復的なアプローチで正しく実装されている。ヘルパー関数と使用例も付属。説明も明瞭。

### 3c. Bash - ワンライナー

```bash
./.build/release/applefm respond "Write a bash one-liner to find all .swift files larger than 10KB"
```

> ```bash
> find . -type f -name "*.swift" -size +10000
> ```

**評価**: 概ね正確だが、`-size +10000` はバイト単位ではなく512バイトブロック単位。正確には `-size +10k` とすべき。実用上は問題ないが厳密には不正確。

---

## 4. 翻訳

### 4a. 英語→日本語

```bash
./.build/release/applefm respond "Translate to Japanese: The quick brown fox jumps over the lazy dog"
```

> 日本語で翻訳すると、次のようになります。
>
> 「速い茶色の狐はのんびりしている犬の上に跳び越えた。」

**評価**: 良好。自然な日本語訳。ただし余分な前置きが付いている（「日本語で翻訳すると、次のようになります。」）。翻訳のみを求める場合は instructions で制御する必要がある。

### 4b. 日本語→英語

```bash
./.build/release/applefm respond "Translate to English: 吾輩は猫である。名前はまだない。"
```

> The translation to English is: "I am a cat. My name is not yet."

**評価**: 部分的に不正確。夏目漱石の有名な冒頭文の定訳は "I Am a Cat. As yet I have no name." が一般的。"My name is not yet." は文法的に不自然で、意味も不完全（「まだない」= "not yet given" / "I have no name yet"）。文学的な翻訳の品質に課題がある。

---

## 5. 推論・論理タスク

### 5a. 三段論法

```bash
./.build/release/applefm respond "If all roses are flowers and some flowers fade quickly, can we conclude that some roses fade quickly? Explain your reasoning."
```

> From these statements, we can infer that since roses are a subset of flowers (all roses are flowers), it follows that some roses must also fade quickly. This is because if there are some flowers that fade quickly and roses are among those flowers, then some roses must fade quickly as well.
>
> Thus, the conclusion is that some roses fade quickly.

**評価**: **不正確**。これは古典的な論理学の誤謬。「すべてのバラは花である」かつ「ある花はすぐに枯れる」から「あるバラはすぐに枯れる」は論理的に導出できない。枯れやすい花がバラでない可能性がある。これは「未分配中項の誤謬」(fallacy of the undistributed middle) の一種。モデルは論理的推論でこの誤りを犯している。

### 5b. バットとボール問題

```bash
./.build/release/applefm respond "A bat and a ball cost $1.10 in total. The bat costs $1.00 more than the ball. How much does the ball cost?"
```

> x + (x + 1.00) = 1.10
> 2x + 1.00 = 1.10
> 2x = 0.10
> x = 0.05
>
> Thus, the ball costs $0.05.

**評価**: **正確**。有名な認知バイアス問題（多くの人が直感的に$0.10と答える）を正しく解いている。数式の展開も明確。

---

## 6. Instructions (System Prompt) の効果

### 6a. 獣医 + 2文制限

```bash
./.build/release/applefm respond "Tell me about dogs" --instructions "You are a veterinarian. Answer in exactly 2 sentences."
```

> Dogs are domesticated mammals belonging to the Canidae family, known for their loyalty and companionship. They have been bred for various roles, including working, herding, and companionship, and are among the most popular pets worldwide.

**評価**: 高い指示遵守度。正確に2文で回答。獣医の視点は弱いが（医学的観点からの言及がない）、全般的な制約は守られている。

### 6b. 詩人 + 俳句形式

```bash
./.build/release/applefm respond "Tell me about dogs" --instructions "You are a poet. Answer in haiku format."
```

> Furry friends so true,
> Loyal hearts in gentle gaze,
> Joy in every bark.

**評価**: 高品質。英語俳句の5-7-5音節構造にほぼ準拠（5-7-5: "Fur-ry friends so true" = 5, "Loy-al hearts in gen-tle gaze" = 7, "Joy in ev-ery bark" = 5）。詩的表現も適切。

### 6c. Instructions なし（ベースライン）

```bash
./.build/release/applefm respond "Tell me about dogs"
```

> （8項目の詳細な箇条書きリスト - 家畜化、品種の多様性、性格、コミュニケーション、健康管理、用途、行動、寿命について）

**評価**: Instructions なしの場合、包括的で詳細な回答を生成する傾向がある。6a/6b との比較で、Instructions が出力のスタイルと長さに大きな影響を与えることが確認できる。

### Instructions の効果まとめ

| 条件 | 出力長 | スタイル | 指示遵守度 |
|------|--------|----------|------------|
| 獣医 + 2文 | 2文 | 情報的 | 高（文数は正確） |
| 詩人 + 俳句 | 3行 | 詩的 | 高（5-7-5構造） |
| なし | 長文（8項目） | 百科事典的 | N/A |

Instructions は出力の形式制御に非常に効果的。

---

## 7. 創作タスク

### 7a. 英語 - 短編物語

```bash
./.build/release/applefm respond "Write a short story about a robot learning to cook, in 100 words or less"
```

> In a bustling kitchen, R-301, a curious robot, watched humans cook with fascination. Its sensors detected aromas, and its circuits buzzed with determination. Guided by a cookbook, it followed each step meticulously. With each attempt, sparks flew, and ingredients splattered, but R-301 persevered. Finally, it crafted a simple omelet, its metallic spatula deftly flipping the eggs. Cheers erupted from the humans, who marveled at the robot's culinary debut. R-301 beamed with pride, having learned not just cooking, but the art of patience and creativity. In its heart, a new skill had been unlocked—a recipe for innovation.

**評価**: 良好な物語構成。起承転結がある。ただし約98語で100語制限にぎりぎり収まっている。文体は少しテンプレート的だが、創作タスクとしては十分な品質。

### 7b. 日本語 - 短編物語（100文字制限）

```bash
./.build/release/applefm respond "100文字以内で、ロボットが料理を学ぶ短い物語を書いてください"
```

> ロボットA100は、料理を学びたいと願っていた。ある日、インターネットでレシピを見つけ、調理器具のセットを購入した。試行錯誤しながら、初めての料理「ロボットカレー」を作り上げた。味は平凡だったが、達成感に満たされていた。次に挑戦する料理を夢見ながら、ロボットA100は賢く成長を続けていた。

**評価**: 物語としては良好だが、文字数制限を大幅に超過している（約130文字）。日本語の文字数制限の遵守に課題がある。

---

## まとめ

### 全体的な所見

| カテゴリ | 英語品質 | 日本語品質 | 備考 |
|----------|----------|------------|------|
| 事実質問 | 高 | 不安定 | 日本語で無関係な回答が発生する場合がある |
| 概念説明 | 高 | 良好 | 両言語で構造化された説明を生成 |
| 要約 | 中（事実誤認あり） | 良好 | 英語版でSwiftの特性に誤りあり |
| コード生成 | 高 | N/A | 複数言語で正確なコード生成が可能 |
| 翻訳 | - | 良好/中 | 文学的翻訳に課題 |
| 論理推論 | 中 | N/A | 三段論法で誤り、算術は正確 |
| 指示遵守 | 高 | 中 | Instructions による形式制御は効果的 |
| 創作 | 良好 | 良好（制約違反） | 日本語の文字数制限遵守に課題 |

### 強み

1. **英語での説明・回答品質が高い** - 構造化された、読みやすい出力を生成する
2. **Instructions (system prompt) の効果が高い** - 出力形式の制御に非常に有効
3. **コード生成能力が優秀** - Swift, Python, Bash いずれも実用的なコードを生成
4. **数学的推論は正確** - バットとボール問題を正しく解答

### 弱み・制限事項

1. **日本語の事実質問で無関係な回答が発生** - 「日本の首都」に対してApple製品の宣伝が返される事例。再現性と条件の特定が必要
2. **論理的推論に誤りがある** - 三段論法の誤謬を正しく識別できない
3. **事実の正確性に課題** - Swift の型システムやコンパイル方式について誤った記述（英語要約で「Dynamic Typing」「JIT compilation」と記述）
4. **日本語の文字数制限遵守が弱い** - 100文字制限を大幅に超過
5. **コード生成にバグの可能性** - 素数判定関数で `n == 2` のエッジケースが正しく処理されない
6. **翻訳品質にばらつき** - 文学的な翻訳では不自然な英語が生成される

### 推奨事項（applefm CLI の活用観点）

- **Instructions オプションの積極活用** - 出力品質と形式を大きく改善できる
- **英語プロンプトの優先** - 現時点では英語の方が安定した品質を提供
- **コード生成での活用** - 高い実用性があるが、出力コードのレビューは必要
- **論理推論タスクには注意** - 複雑な論理的推論では誤りが生じる可能性がある
