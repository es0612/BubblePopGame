# App Store Connect メタデータ

## 📱 アプリ基本情報

### アプリ名
- **日本語**: シャボン玉消しゲーム：親子で癒しタッチ（1.1.2 から。#78）
- **英語**: Bubble Pop: Relax & Focus
- **文字数**: 日本語 19文字、英語 25文字（30文字制限内）
> ※ 1.1.1 までの ja 名は「シャボン玉消しゲーム」。検索の入口になっている「シャボン玉」を残し、届けたい人（親子の両方）と価値（癒し・タッチ）を足した（#78、PO が A 案を選択。設計: `docs/superpowers/specs/2026-11-03-aso-store-listing-design.md`）。名前はストア全体で一意である必要があり、使えるかは ASC で保存するまで未確認
> ※ 当初の「Bubble Pop Game」「BubblePopGame」はどちらも他アプリが使用中で ASC に登録不可だったため、一意な「Bubble Pop: Relax & Focus」を採用（2026-05-31 ASC 登録時に確定）。App Store のアプリ名は全世界で一意。

### サブタイトル
- **日本語**: 広告なし。泡をタップする暇つぶし（1.1.2 から。#78）
- **英語**: Calm tap game for kids, no ads（1.1.2 から。#78）
- **文字数**: 日本語 16文字、英語 30文字（30文字制限内）
> ※ 1.1.1 までは ja「美しいシャボン玉で楽しむリラックスゲーム」/ en「Relaxing soap bubble game」
> ※ 旧英語サブタイトル「Relaxing game with beautiful soap bubbles」は 37 文字で 30 字制限超過だったため短縮（25 文字）。

### カテゴリ
- **プライマリ**: ゲーム
- **セカンダリ**: アクション
- **ジャンル**: カジュアル, ファミリー

### 年齢制限
- **レーティング**: 4+（すべての年齢層に適用）
- **理由**: 暴力表現なし、不適切な内容なし

### 価格設定
- **価格**: 無料
- **アプリ内購入**: なし
- **広告**: なし

---

## 📝 説明文

> ⚠️ **ASC の文字制限（2026-05-31 実機検証）**: 説明文・プロモーションテキスト欄は**絵文字を「無効な文字」として拒否**する（🫧 だけでなく ✨🎵📱🌟💫🔒 等も全滅）。ウェーブダッシュ `〜`(U+301C) も避け、全角チルダ `～`(U+FF5E) を使う。箇条書き `•`(U+2022)・CJK 隅付き括弧 `【】` は OK。本ファイルの説明文・プロモは絵文字除去済み（#42）。

### 日本語版説明文 (4000文字制限)

```
美しいシャボン玉を指先で楽しもう！

画面に舞い踊る虹色のシャボン玉をタップして消す、心癒されるカジュアルゲームです。美しいアニメーションと心地よい音楽で、日常の疲れを忘れてリラックスできます。

主な機能

【ゲームモード】
• 通常モード: 自由にシャボン玉を消してスコアを競う
• 数字順モード: 1から順番に数字のシャボン玉を消すチャレンジ
• 制限時間: 30秒～180秒（初期値30秒）まで自由に設定可能
• シャボン玉数: 10個から調整可能（最大数は端末に合わせて自動調整）

【カスタマイズ設定】
• BGMセレクション: 3つの癒し系楽曲から選択
• 効果音: ON/OFF を切り替え
• バイブレーション: タッチフィードバックのON/OFF
• プログレッシブ難易度: 数字モードで段階的に難しくなる設定

【スコア・記録システム】
• ハイスコア自動保存
• ゲームモード別ランキング
• 制限時間別記録管理
• リザルトで正確率・最大チェーン・プレイ時間を表示

【充実のサポート機能】
• 分かりやすいチュートリアル（4ステップガイド）
• VoiceOver完全対応（視覚障害者サポート）
• Dynamic Type対応（文字サイズ調整）
• 色覚異常者配慮のカラーシステム

音響・体験の特徴
• 3曲のオリジナルBGM搭載
• リアルなシャボン玉破裂音
• 美しいパーティクル効果
• 滑らかな60FPSアニメーション
• 直感的なタッチ操作

対応デバイス
• iPhone（iOS 17.0以降）
• iPad（iPadOS 17.0以降）
• レスポンシブデザインで全画面サイズ対応
• iPhone 12以降、iPad第9世代以降推奨

こんな方におすすめ
• 通勤・通学の隙間時間にリラックスしたい
• 集中力を鍛えたい（数字順モード）
• 美しい視覚効果を楽しみたい
• アクセシビリティ機能を必要とする
• シンプルで分かりやすいゲームをお探しの方

アクセシビリティ
このアプリは誰もが楽しめるよう設計されています。VoiceOverによる音声ガイド、文字サイズ調整など、障害をお持ちの方も安心してご利用いただけます。

プライバシー
ユーザーデータは全てデバイス内にローカル保存され、外部サーバーへの送信は一切行いません。安心してお楽しみください。

シンプルながらも奥深い、心温まるシャボン玉の世界をお楽しみください！
```

### 英語版説明文 (4000文字制限) — ⚠️ 絵文字禁止（ASC の en は絵文字を弾く。見出し `【】`・箇条書き `•` は v1.1 で受理済み）

```
Pop beautiful soap bubbles with your fingertips!

A soothing casual game where you tap to pop rainbow-colored soap bubbles dancing on your screen. Beautiful animations and relaxing music help you forget daily stress and unwind.

Key Features

【Game Modes】
• Normal Mode: Freely pop bubbles and compete for high scores
• Numbered Mode: Challenge yourself by popping numbered bubbles in order
• Time Limit: Customizable from 30 to 180 seconds (default 30)
• Bubble Count: Adjustable from 10 (the maximum adapts to your device)

【Customization Settings】
• BGM Selection: Choose from 3 soothing music tracks
• Sound Effects: Turn on or off
• Vibration: Toggle touch feedback ON/OFF
• Progressive Difficulty: Gradually increasing challenge in numbered mode

【Score & Record System】
• Automatic high score saving
• Rankings by game mode
• Records management by time limit
• Results show accuracy, max chain, and play time

【Comprehensive Support Features】
• Easy-to-understand tutorial (4-step guide)
• Full VoiceOver support (visual impairment accessibility)
• Dynamic Type support (text size adjustment)
• Color vision deficiency considerate color system

Audio & Experience Features
• 3 original BGM tracks included
• Realistic bubble popping sounds
• Beautiful particle effects
• Smooth 60FPS animations
• Intuitive touch controls

Device Compatibility
• iPhone (iOS 17.0 or later)
• iPad (iPadOS 17.0 or later)
• Responsive design for all screen sizes
• Recommended: iPhone 12 or later, iPad 9th generation or later

Perfect For
• Relaxing during commute or study breaks
• Training concentration skills (numbered mode)
• Enjoying beautiful visual effects
• Users requiring accessibility features
• Anyone seeking simple, intuitive games

Accessibility
This app is designed for everyone to enjoy. With VoiceOver audio guidance, text size adjustment, and more, users with disabilities can use it with confidence.

Privacy
All user data is stored locally on your device, with no transmission to external servers. Enjoy with peace of mind.

Experience the simple yet profound, heartwarming world of soap bubbles!
```

---

## 🔍 キーワード戦略

1.1.2 から（#78）。狙う検索語は 3 系統（子ども・親子系 / 癒し・暇つぶし系 / 泡・バブル系）。名前・サブタイトルに入っている語はキーワード欄に入れない（名前・サブタイトル・キーワードはまとめて検索の対象になるため、重ねると枠が無駄になる）。文字数と重複は機械で確認済み（2026-11-03）。

2026-11-03 の検索順位（`scripts/aso/search_rank.py scripts/aso/terms-ja.txt`、変更前のベースライン）: 「シャボン玉ゲーム」2 位・「シャボン玉」4 位。ほかの 14 語はすべて圏外。

### 日本語キーワード (100文字制限)
```
子供,子ども,幼児,知育,数字,順番,バブル,プチプチ,リラックス,ストレス解消,ストレス発散,集中力,家族,反射神経,カジュアル,ひまつぶし,BGM
```
> ※ 75 文字。名前・サブタイトルにある `シャボン玉` `ゲーム` `親子` `癒し` `タッチ` `広告なし` `泡` `タップ` `暇つぶし` は除外。1.1.1 までの `無料` `シンプル` `アクセシビリティ` `VoiceOver` などは外した

### 英語キーワード (100文字制限)
```
family,toddler,baby,numbers,count,stress relief,fidget,time killer,casual,soap,chill,quick,popping
```
> ※ 98 文字。名前・サブタイトルにある `bubble` `pop` `relax` `focus` `calm` `tap` `game` `kids` `ads` は除外

---

## 🏷️ カテゴリ詳細

### プライマリカテゴリ: ゲーム
- **理由**: ユーザーがゲームとして認識し検索しやすい
- **競合**: 他のカジュアルゲームとの比較優位性

### セカンダリカテゴリ: アクション
- **理由**: タップ操作による即座の反応が求められる
- **ターゲット**: アクションゲーム好きのユーザー獲得

### 追加適合カテゴリ
- **ファミリー**: 全年齢対象の安全なコンテンツ
- **パズル**: 数字順モードの戦略性
- **エンターテインメント**: リラクゼーション要素

---

## 📱 年齢制限詳細

### レーティング: 4+
- **暴力表現**: なし
- **性的内容**: なし
- **薬物・アルコール**: なし
- **ギャンブル**: なし
- **不適切な言語**: なし
- **恐怖要素**: なし

### レーティング根拠
- 純粋な娯楽コンテンツ
- 教育的価値（集中力、反射神経向上）
- 家族全員で楽しめる内容

---

## 💰 価格戦略

### 無料配布の理由
1. **ユーザー獲得**: 初期ダウンロード数最大化
2. **口コミ効果**: 低い参入障壁による拡散期待
3. **アクセシビリティ**: 誰でも気軽に試せる
4. **レビュー獲得**: 評価とフィードバック収集

### 将来のマネタイズ検討
- **プレミアム版**: 追加BGM、スキン、モード
- **広告表示**: 非侵入的なバナー広告
- **アプリ内購入**: 装飾要素、追加機能

---

## 📸 スクリーンショット戦略

1.1.2 から（#78）。並びは「遊び → 安心 → 癒し → 補足」。検索結果には最初の 3 枚が出るので、1〜3 枚目で届けたい人（親子の両方）に向けた価値を見せる。文言と並びの単一ソースは `scripts/screenshots/compose_screenshots.py` の `JOBS`。生成手順は `scripts/screenshots/README.md`。

| 順 | 画面 | ja | en |
| --- | --- | --- | --- |
| 1 | ゲーム中（ノーマル、プレイ途中の状態を注入） | タップでぱちん！シャボン玉 | Tap to pop the bubbles! |
| 2 | ゲーム中（数字モード、プレイ途中の状態を注入） | 広告なし。親子で安心して遊べる | No ads. Fun for families |
| 3 | リザルト | 30秒で気分転換 | A 30-second break to refresh |
| 4 | メニュー | BGMで癒しのひととき | Relax with calming music |
| 5 | 設定 | 時間も数も好みに調整 | Adjust time and bubbles |

- サイズ: iPhone 6.9"（1290×2796）/ 6.5"（1242×2688）/ iPad 13"（2064×2752）。`TARGETED_DEVICE_FAMILY = "1,2"` なので iPad も必須
- en ロケールには en の画面・en の見出しの画像を入れる（1.1.1 までは ja の画像を共有していた）
- 見出しに絵文字を入れない。アプリにない機能を書かない（「広告なし」は広告 SDK 0 件を 2026-11-03 に grep で確認）

---

## 🎯 プロモーションテキスト

### 日本語 (170文字制限)
```
心癒されるシャボン玉ゲーム！美しいアニメーションと癒しの音楽で日常のストレスを忘れましょう。通常モードでリラックス、数字順モードでチャレンジ。VoiceOver対応で誰でも楽しめます。今すぐ無料でダウンロード！
```

### 英語 (170文字制限) — ⚠️ 絵文字禁止（ASC の en フィールドは絵文字を弾く）
```
Soothing bubble popping game! Beautiful animations and music melt away daily stress. Relax in normal mode or challenge numbered mode. VoiceOver supported. Free now!
```
> ※ 旧版は約200字で170字制限超過のため短縮（約160字・絵文字なし）

---

## 🌍 地域別配布戦略

### Phase 1: 日本市場
- **理由**: 開発言語・文化的親和性
- **期間**: リリース〜3ヶ月
- **目標**: 1,000ダウンロード、4.0星評価

### Phase 2: 英語圏展開
- **対象**: 米国、英国、カナダ、オーストラリア
- **期間**: 4〜6ヶ月目
- **準備**: 英語版完全ローカライズ確認

### Phase 3: アジア太平洋
- **対象**: 韓国、台湾、香港、シンガポール
- **期間**: 7〜12ヶ月目
- **検討**: 追加言語対応

---

## 📊 競合分析

### 直接競合
1. **バブルシューター系**: より複雑、戦略性重視
2. **カジュアルタップゲーム**: シンプルさで類似
3. **リラクゼーションアプリ**: 癒し要素で競合

### 差別化ポイント
- **アクセシビリティ**: VoiceOver完全対応
- **カスタマイズ性**: 豊富な設定オプション
- **教育的価値**: 集中力・反射神経向上
- **プライバシー**: ローカル保存のみ

---

## 🎭 ブランドトーン

### 日本語版
- **親しみやすさ**: 「〜しましょう」「お楽しみください」
- **癒し系**: 「心癒される」「リラックス」
- **包容力**: 「誰でも」「安心して」

### 英語版
- **フレンドリー**: "Enjoy", "Experience", "Perfect for"
- **ポジティブ**: "Beautiful", "Soothing", "Wonderful"
- **インクルーシブ**: "Everyone", "All ages", "Accessible"

---

## 📈 Success Metrics

### ダウンロード数
- **週1**: 50件以上
- **月1**: 200件以上
- **月3**: 1,000件以上

### ユーザー評価
- **平均評価**: 4.0星以上維持
- **レビュー数**: 月10件以上
- **評価分布**: 4-5星が80%以上

### エンゲージメント
- **アプリ継続率**: 1日後50%以上
- **平均セッション**: 3分以上
- **月間アクティブ**: ダウンロード数の30%以上

---

*最終更新: 2026-05-30（v1.0 提出に向けて最新化）。反映済みの実装: 制限時間 30〜180秒（初期値30）/ iPhone・iPad 両対応 / リザルト画面はお祝いトーン（タイトル「おしまい！/All Done!」）/ 詳細統計はプレイ時間中心（平均反応速度・密度は廃止）/ 広告・解析・ネットワークなし＝データ収集なし。*
*⚠️ en（英語ロケール）の Description / Promotional / What's New は **絵文字禁止**（ASC が弾く）。ja は絵文字OK。提出直前に App Store Connect の最新ガイドラインと再確認すること。*