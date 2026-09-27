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

### App Store Connect 側（2026-09-27 時点）
- [x] ASC で v1.1 のバージョンを作成（2026-06-08）・What's New を入力（2026-08-28 API 投入。ja は 🫧 が `INVALID_CHARACTERS` で拒否されたため絵文字なし文）
- [x] スクリーンショット: v1.0 分を流用（iPhone 6.5" 5 枚 / iPad 13" 5 枚を 2026-09-27 に確認）
- [x] 年齢制限の「広告」(Advertising) は No のまま（広告 SDK なし）
- [x] marketing URL を `https://note.com/es0612swift` に付け替え（2026-08-28 API 投入、2026-09-27 に ja/en を確認）
- [x] プロモーション用テキスト（ja/en）を入力（2026-09-27。v1.1 では空になっていた → `docs/app-store-metadata.md` の値を入力）
- [x] 説明文（ja/en）の制限時間を「15〜180 秒」→「30〜180 秒（初期値 30 秒）」に修正（2026-09-27。コード `SettingsView` の `30...180` に合わせた 1 行修正。リポ doc と live の体裁の違いは別 Issue）
- [x] Xcode Cloud 配信ビルド: **build 46**（2026-09-27 09:51 手動ビルド、commit `03e7ca3`）。build 41〜45 は TestFlight の 90 日期限で失効
- [x] build 46 を v1.1 に紐付け（2026-09-27、再読み込みして確認済み）
- [x] #44 を同時に検証: Test アクション 84/84 合格、実行は UnitTest 14 スイートのみで UITest は 0 件（ASC 側の設定変更は不要）。変更前の Xcode Cloud 実行記録がないため時間の前後比較はできず、ビルド全体 14 分を今後の基準値として記録 → #44 クローズ
- [ ] 👤 App Review の連絡先（氏名・電話・メール）が空欄 → 提出前に人が入力または確認する
- [ ] 👤 内容を確認 →「審査用に追加」→ 提出（人が実行）

### 提出後
- [ ] `git tag -a v1.1 03e7ca3 -m "v1.1 (build 46) ITMS リジェクト回避の再提出" && git push origin v1.1`
  - ⚠️ **タグは build 46 のビルド元 `03e7ca3` に打つ**（main の先頭ではない。この PR がマージされると先頭はずれる）
- [ ] 承認されたら本ファイルに「Retrospective」節を追加（`RELEASE_v1.0.md` の書き方に合わせる）

---

## クローズ条件（#46）

- [ ] ASC で v1.1 / build 46 が **正常に受理**される（ITMS-90186 / ITMS-90062 が再発しない）
- [ ] 審査通過後に `git tag v1.1` を push

> #46 は ASC 提出という**外部依存**のため、コード側 bump（PR #47）マージだけではクローズできない。実提出の受理を確認して初めてクローズする。

---

## asc-submission-prep 初回実走（2026-09-27, #53）

Chrome 経路の申請準備 skill（`~/.claude/skills/asc-submission-prep`）を v1.1 で初めて実走した記録。

| 物差し | 結果 |
|---|---|
| 人が判断した回数 | 1 回（判断①：差分表のうち説明文の扱いを選んだ）。判断②（ビルド起動）は build 46 があったので不要 |
| 人が手で直した回数 | 0 回（書き込み 5 件はすべて再読み込み後の読み戻しで一致） |
| dry-run で見つかった想定外 | プロモ ja/en が空欄／説明文 ja/en の制限時間が古い（15 秒）／App Review 連絡先が空欄 |
| 実走で得た手順の修正 | フォーム値は `javascript_tool` で name 属性を読む／ビルド選択ダイアログは期限切れのビルドも選べる／ロケールのメニューは座標クリックで開く（SKILL.md に反映済み） |
| まだ検証していない手順 | スクショ差し替え、Xcode Cloud のビルド起動 |

所要時間は、会話の往復と skill 自体の修正が混ざっているため、今回は正確に測れていない。2 アプリ目で dry-run の開始から停止レポートまでを計測して、比較の基準にする。
