# RELEASE v1.1 — ITMS リジェクト回避の再提出

- 対象: BubblePopGame v1.1（build 40）の App Store 再提出
- 作成: 2026-06-05
- 関連: #46（ASC リジェクト）/ PR #47（バージョン bump）/ #44・PR #48（CI テスト時間短縮）

## 背景（なぜ v1.1 か）

v1.0 が 2026-06-02 に App Store 公開（approved）された後、build 39 を **`1.0` のまま**再提出したため ASC に弾かれた（Issue #46 のスクショが一次証拠）:

- `ITMS-90186` — Invalid Pre-Release Train: 公開済み `1.0` train は新規ビルド提出に対して closed
- `ITMS-90062` — `CFBundleShortVersionString` は既に承認された `1.0` より高い必要がある

→ MARKETING_VERSION を `1.0` → `1.1` に上げて train を開き直す（PR #47 で対応済み）。

## バージョン

| キー | 値 | 根拠 |
| --- | --- | --- |
| `MARKETING_VERSION` (CFBundleShortVersionString) | **1.1** | ASC 承認済み最新 = `1.0`（`git tag v1.0` で確認）。`1.0` train は公開済みで閉じているため `1.1` へ |
| `CURRENT_PROJECT_VERSION` (CFBundleVersion / build) | **40** | リジェクトメールの最終アップロード build = `39` より上。pbxproj が `36` に lag していたため `40` まで上げて余裕を持たせた |

⚠️ **次回 bump も `release-version-bump-check` skill を Archive 直前に再実行**し、ASC/TestFlight の最高 build + 1 を確認すること（App / Tests / UITests × Debug / Release で計 12 箇所、`replace_all` 推奨）。

## このバージョンの内容（ユーザー向け新機能: なし）

`v1.0`（tag = #43 マージ点）→ HEAD の差分は **すべて内部/CI/docs** で、ユーザー向けの挙動変更はゼロ:

| 変更 | 種別 | PR |
| --- | --- | --- |
| CI を UnitTest のみに分離（テストプラン2枚 + 共有スキーム新設） | 内部 / CI | #48（#44） |
| UITest の per-config 反復無効化 + ハード sleep を要素待機へ置換 | 内部 / テスト品質 | #48（#44） |
| バージョン番号 v1.1 / build 40 へ bump | リリース機構 | #47（#46） |
| v1.0 リリース振り返り + ASC ノウハウ docs | docs | #45 |
| `.DS_Store` を `.gitignore` に追加 | chore | — |

→ よって **本リリースは「ITMS リジェクト回避の再提出」**であり、What's New はメンテナンス系の最小表記とする。

## What's New 下書き

> ja（絵文字あり版を第一候補）:
> 軽微な内部改善とビルドの安定性向上を行いました。引き続きごゆっくりお楽しみください🫧

> ⚠️ **ja 絵文字フォールバック**: BubblePopGame は v1.0 提出時に ja の説明文・プロモ文の絵文字を ASC 拒否で全除去した実績がある（memory: `asc-bubblepop-state`）。What's New でも 🫧 が弾かれる場合は、絵文字なしの下記を使う:
> 軽微な内部改善とビルドの安定性向上を行いました。引き続きごゆっくりお楽しみください。

> en（**絵文字禁止** — ASC が en の絵文字を「無効な文字」として弾く。plain text）:
> This update includes minor internal improvements and build stability fixes. Thank you for playing!

## 提出前チェックリスト

### コード側（✅ マージ済み・検証済み）
- [x] `MARKETING_VERSION = 1.1` / `CURRENT_PROJECT_VERSION = 40`（> リジェクト時 build 39）— `-showBuildSettings` で伝播確認済み（PR #47）
- [x] Debug ビルド成功（pbxproj 非破損）/ UnitTest 緑（CI テストプラン）
- [x] 広告/解析/クラッシュ/ネットワーク SDK なし（= App Privacy「データを収集していません」据え置き）

### App Store Connect 側（手動・要対応）
- [ ] ASC で **v1.1 のバージョンを新規作成**し、What's New を入力（ja は絵文字可 / **en は絵文字 NG**）
- [ ] スクリーンショット: 既存 v1.0 提出分を流用可（UI 変更なし）。iPhone 6.9" + iPad 13"（`TARGETED_DEVICE_FAMILY = "1,2"` のため両方必須）
- [ ] App Privacy / 年齢制限 / 説明文・キーワード等は v1.0 から変更なし（`docs/app-store-metadata.md` が単一ソース）
  - 年齢制限の「広告」(Advertising) は **No 据え置きで正**（広告 SDK なしを確認済み。Package.resolved 不在・コード grep でも 0 ヒット）
- [ ] **marketing URL を修正**: v1.0 提出時に別アプリ用 `weightscale-7cdf1.web.app` のまま出た可能性（memory: `asc-bubblepop-state`）→ サポートURL `https://note.com/es0612swift` に**付け替える**。ASC → 該当バージョン → 「マーケティングURL」フィールド（任意フィールドだが他アプリへの誤リンクは是正する）
- [ ] **Xcode Cloud 経由で配信ビルドを実行**。配信前に build が **≥ 40** であることを `release-version-bump-check` で再確認（pbxproj は `-showBuildSettings` で `1.1 / 40` 伝播確認済み）
- [ ] 🔗 **配信ビルドの Test アクションのログで #44 を同時検証**（本プロジェクトは Xcode Cloud 配信のため、提出ビルドが #44 のクローズ条件も満たせる）:
  - [ ] UITest が走っていない（Unit のみ・`CI` テストプラン）ことを確認
  - [ ] もし UITest がまだ走るなら、ASC のワークフロー Test アクションを「`CI` テストプラン使用」に**1回だけ**設定変更（リポからは変更不可）
  - [ ] wall-clock が before（約 718s）より実際に短縮されたことを確認

### マージ後
- [ ] `git tag -a v1.1 -m "v1.1 (build 40) ITMS リジェクト回避の再提出" && git push origin v1.1`
  - ⚠️ **タグは実提出する commit に打つ**。提出前に追加 commit が入るとタグ位置がずれるため、ASC へ Archive/Distribute する commit が確定してから打つこと（v1.0 のときと同じ運用）
- [ ] 提出が承認されたら本ファイルに「Retrospective」節を追記（`RELEASE_v1.0.md` の慣習に倣う）

---

## クローズ条件（#46）

- [ ] ASC で v1.1 / build 40 が **正常に受理**される（ITMS-90186 / ITMS-90062 が再発しない）
- [ ] 審査通過後に `git tag v1.1` を push

> #46 は ASC 提出という**外部依存**のため、コード側 bump（PR #47）マージだけではクローズできない。実提出の受理を確認して初めてクローズする。
