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

---

## 振り返り (Retrospective) — 2026-06-02 リリース完了

> ✅ **2026-06-02、初版 v1.0 (build 36) が App Store 審査を通過しリリース済み**。本セクションは `release-retrospective` skill に基づくリリースサイクル（PR #6〜#43, 2026-05-26〜05-31）の振り返り。次の v1.x retro はこの節を起点に trend を追える。
>
> 初版のため retro 対象 PR は多いが、個々の技術的学びの大半は既に CLAUDE.md に継続追記済み（#11 / #28 / #34 / #38）。本節では **(a) リリース journey の俯瞰**、**(b) まだ CLAUDE.md に無い学び（特に ASC 実機提出ノウハウ）**、**(c) アクションアイテム表**に絞る。

### リリース journey（テーマ別）

| テーマ | 主な PR | 要点 |
| --- | --- | --- |
| 起動安定性（screenBounds systemic fault） | #6, #10, #32, #33 | 起動不能（#23）・チュートリアル練習バブル不可視（#24）が TestFlight まで漏れた。共有 `screenBounds == .zero` の供給取りこぼしが根本原因。deferred-start＋View 固有 geometry で解消 |
| Swift 6 / コード品質 | #12, #29, #30 | EffectService protocol の `@MainActor` 化、debug print の `#if DEBUG` ログ化、DI 改善＋パフォーマンス回復 |
| DEBUG 検証基盤（no-tap 自動化） | #14, #16, #43 | `--skip-tutorial` / `--game-time` / `--game-mode` / `--screenshot=<画面>` を配線。simctl の tap 不在を「画面遷移の引数化」で回避 |
| ローカライズ | #15, #22 | ローカライズ漏れ修正、LaunchScreen 仕上げ＋英語重複解消。`LocalizationKeysTests` でキー存在＋ ja/en/Base パリティを担保 |
| ゲーム体験 / 設定反映 | #21, #39, #40 | バブルサイズ・速度に GameSettings 反映、リザルト画面お祝いトーン化＋誤タップ防止、制限時間デフォルト 60→30 秒＋既存ユーザー migration |
| App Store 提出準備 | #31, #41, #42, #43 | 輸出コンプラ事前申告、v1.0(build36) 提出準備＋privacy manifest、旧 docs 整理、スクショ全自動生成 |
| プロセス改善（振り返りの複利） | #11, #28, #34, #38 | 罠を都度 CLAUDE.md 化し、次 PR で踏まない運用を確立 |

### 良かった点（What went well）

- **振り返りの複利が機能した**: 詰まった点を都度 CLAUDE.md に追記する運用（#11 / #28 / #34 / #38）で、同じ罠を後続 PR で踏まない流れが定着。session-retrospective skill＋Stop hook の仕組みが回った。
- **no-tap 自動検証基盤を整備**: `simctl` に `tap` が無い制約を、`#if DEBUG` 起動引数（`--skip-tutorial` / `--game-time` / `--screenshot`）で「画面遷移そのものを引数化」して回避。起動確認だけでなく "売り" 画面のスクショまで全自動化できた。
- **テストで盲点を守った**: `LocalizationKeysTests`（キー存在＋ロケールパリティ）、`GameTimeDefaultMigration`（in-memory ModelContainer でユニットテスト）、`elapsedPlaySeconds`（computed property 化）など、目視・no-tap 検証をすり抜ける箇所をテストで大声検出。
- **スクショ全自動生成パイプライン**: DEBUG ナビ＋ Pillow 合成（`scripts/screenshots/compose_screenshots.py`）で必須スクショを自動生成。

### 詰まった点 / 失敗（What went wrong）

- **screenBounds == .zero が systemic fault として本番化**: #23（起動不能）/ #24（練習バブル不可視）が実際に TestFlight に出た。共有 `gameViewModel.screenBounds` が LaunchScreen→ContentView のアニメ遷移中に供給を取りこぼす設計上の脆さ。対処（無効値を上書きしない／deferred-start／View 固有 geometry）は CLAUDE.md 化済みだが、**共有可変状態に座標を載せる設計そのもの**は将来の改善余地。
- **スタックPR のマージ順罠**: base が中間 feature ブランチの #26/#27 を先に main へ入れた結果、#19/#20 が main 未着地に。re-land 2 PR（#29/#30）の手戻りが発生。→ CLAUDE.md に「独立変更は base=main で切る」と明記済み。
- **SwiftData migration の defer footgun**: `defer { setFlag }` を fetch ガードより前に置くと失敗も握り潰し「やった印」だけ立って永久未移行になる罠を #35 最終レビューで捕捉。
- **`String(format:)` の型不一致で Play Time 0 sec**（#37）: 整数書式 `%d秒` に Double を渡して 0 表示。`SettingsView` は Int キャスト済み・`GameOverView` は Double で挙動が割れていた。
- **単一テスト `-only-testing` の vacuous SUCCEEDED 罠**: メソッド単位指定で 0 件実行のまま `** TEST SUCCEEDED **` になり、RED 確認に使うと誤認。

### 想定外の発見（Surprises）

- ⚠️ **App Store のアプリ名は全世界で一意**（コード内の Bundle 名とは無関係）。計画していた `Bubble Pop Game` / `BubblePopGame` はどちらも他アプリが使用中で ASC に登録不可。土壇場で一意な **`Bubble Pop: Relax & Focus`** にリネーム（2026-05-31 ASC 登録時に確定）。
- ⚠️ **ASC の説明文・プロモーションテキスト欄は絵文字を「無効な文字」として拒否**（🫧 だけでなく ✨🎵📱🌟💫🔒 等も全滅）。docs は絵文字込みで用意していたため入力時に手で除去する羽目に。ウェーブダッシュ `〜`(U+301C) も避け全角チルダ `～`(U+FF5E) を使う。箇条書き `•`・CJK 隅付き括弧 `【】` は OK。
- ✅ **simctl 自動スクショの上限は「起動画面のみ」ではなかった**（ポジティブな発見）: DEBUG 起動引数で目的の `gameState` へ直行＋サンプルデータ注入すれば、tap が要る売り画面まで全自動キャプチャできた。
- ⚠️ **App Store スクショは `TARGETED_DEVICE_FAMILY` の全ファミリ分が提出必須**: `"1,2"` のため iPhone 6.9" だけでなく iPad 13" も必要（本ドキュメント上部チェックリストの「6.5"/5.5"」は旧スペックで、実提出では現行の 6.9"＋iPad 13" を使用）。

### 次サイクルへの遺産（Action items）

| 学び | 行き先 | 状態 |
| --- | --- | --- |
| App Store スクショ自動化（DEBUG ナビ / 全デバイスファミリ必須 / metadata 単一ソース） | CLAUDE.md「App Store 提出・スクショ検証」セクション | ✅ 本 retro PR で追記 |
| ASC 入力ノウハウ（アプリ名の全世界一意性 / 絵文字拒否 / U+301C vs U+FF5E / キーワード除外最適化） | memory（`asc-browser-input-quirks.md`）＋ skill 化（新規 vs 既存統合は要判断） | 🔲 ユーザー確認 |
| `app-store-metadata.md` が却下された旧アプリ名のまま（origin/main 版） | docs 再適用（最終アプリ名 / ASC 警告 / キーワード最適化を絵文字復活なしで反映） | 🔲 本 retro PR で対応 |
| 初版リリースのバージョン境界（タグ）が無い → 次回 retro の window 起点が取れない | `git tag v1.0`（提出前チェックリスト「マージ後」にも記載あり） | 🔲 ユーザー確認（push せず提案） |
| release epic #5 完了 | Issue #5 クローズ | 🔲 ユーザー確認 |
| テスト時間が長すぎる | 既存 Issue #44 | ✅ 登録済み |
| screenBounds の共有可変状態設計そのものの脆さ | 将来の設計改善 Issue 化（候補） | 🔲 検討 |

> アクションアイテム表がこの retro の心臓部。状態列で実行可否を追跡する。次の v1.x リリースはこの表の未消化項目を起点に triage する。
