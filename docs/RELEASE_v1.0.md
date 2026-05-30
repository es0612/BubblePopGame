# RELEASE v1.0 — App Store 初回提出

- 対象: BubblePopGame 初回 App Store リリース
- 作成: 2026-05-30
- 関連: #5（審査準備トラッカー）

## バージョン

| キー | 値 | 根拠 |
| --- | --- | --- |
| `MARKETING_VERSION` (CFBundleShortVersionString) | **1.0** | 初回 App Store リリース。TestFlight `1.0` の train はまだ App Store で公開（approved）されていないため据え置きで可 |
| `CURRENT_PROJECT_VERSION` (CFBundleVersion / build) | **36** | TestFlight 最新が `1.0 (35)`。同一 MARKETING_VERSION では build を厳密に上げる必要があるため `35 + 1 = 36`。repo は `1` で stale だった（Xcode Archive で 35 まで上げたが未コミット＝ドリフト）ので是正 |

⚠️ **次回以降の bump**: ASC/TestFlight にアップ済みの最高 build を必ず確認し、それ + 1 にする。App Store で 1.0 が **公開（approved）された後**は 1.0 train が閉じるので、次は `1.0.1` / `1.1.0` 等へ MARKETING_VERSION を上げること（ITMS-90186/90062 回避）。`release-version-bump-check` skill 参照。

## このバージョンの内容（What's New 下書き）

> ja（絵文字OK）:
> はじめまして！シャボン玉をタップして消すかんたんゲームです🫧 集中力と反射神経で高スコアを目指そう！

> en（**絵文字禁止** — ASC が en の絵文字を弾く。plain text + ハイフン箇条書き）:
> Welcome to BubblePopGame! Tap the bubbles to pop them and aim for a high score.
> - Simple, kid-friendly one-tap gameplay
> - Normal and Numbered modes
> - Adjustable time limit (default 30s)

## 提出前チェックリスト

### コード側（✅ この PR で対応・検証済み）
- [x] `MARKETING_VERSION = 1.0` / `CURRENT_PROJECT_VERSION = 36`（> TestFlight 35）
- [x] `PrivacyInfo.xcprivacy` 追加（UserDefaults `CA92.1` / トラッキングなし / データ収集なし）→ .app にバンドル済みを実測確認
- [x] 輸出コンプライアンス `ITSAppUsesNonExemptEncryption = NO`（#25）
- [x] Release ビルド成功 / 全 UnitTest 緑 / ローカライズ ja-en-Base 同期
- [x] 広告/解析/クラッシュ/ネットワーク SDK なし（= App Privacy「データを収集していません」）

### App Store Connect 側（手動・要対応）
- [ ] スクリーンショット: 6.5"（必須）/ 5.5"（必須）。iPad 対応なら iPad 用も
- [ ] アプリアイコン 1024×1024 の最終確認（assets には設定済み。ASC 側にも反映）
- [x] プライバシーポリシーを GitHub Pages で公開: **https://es0612.github.io/BubblePopGame/**（`gh-pages` ブランチに `index.html` のみ・日英・「データ収集なし」明記）→ 残作業は ASC の「プライバシーポリシーURL」欄にこの URL を入力するだけ
- [ ] App Privacy（Nutrition Label）= 「データを収集していません」を申告
- [ ] 年齢制限指定（広告 SDK なしのため「広告」は「いいえ」のままで可）
- [ ] 説明文 / キーワード / カテゴリ / サポートURL を入力
- [ ] **Xcode で Archive → Distribute**（配布署名）。Archive 前に build が **≥ 36** であることを再確認（`release-version-bump-check` skill を Archive 直前にもう一度）

### マージ後
- [ ] `git tag -a v1.0 -m "v1.0 (build 36) App Store 初回提出" && git push origin v1.0`（版の source-of-truth を残す。これが無いと次回また stale 判定が曖昧になる）
