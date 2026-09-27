# asc-submission-prep 設計（Issue #53）

- 日付: 2026-09-27
- ステータス: idea → 本 spec 承認後に実装
- 関連: #53（本件）/ #46（v1.1 提出）/ #44（CI テスト時間）/ 既存 skill `asc-metadata-delivery`

## 目的（誰にとって、どんな価値か）

個人開発の全 iOS アプリ（BubblePopGame / OtetsudaiCoin / LeafTimer …）で、App Store Connect（ASC）の申請準備を「`v1.x の申請準備して`」の一言で **提出ボタンを押す直前まで** 進められるようにする。人が ASC でやる作業を「差分を見て OK」「提出ボタン」の2つに減らす。

## 前提として確認した事実（2026-09-27、Chrome で読み取りのみ）

| 項目 | 事実 |
|---|---|
| ASC セッション | Chrome でログイン済み |
| v1.1 | 「提出準備中」、ビルド未紐付け |
| build 45 | 期限切れ |
| build 46 | 2026-09-27 09:51 手動ビルド（`03e7ca3`）、「提出準備完了」、失効まで 90 日 |
| Xcode Cloud Test（build 46） | 84/84 合格、全 14 スイートが UnitTest、UITest 実行 0 件。ビルド全体 14 分 |
| ビルド起動 | Xcode Cloud 画面に「ビルドを開始」ボタンあり（Chrome から手動起動可） |
| `fastlane/metadata/` | 空（入力元として使えない） |
| ASC API | Claude が API Key を読む操作は auto mode で拒否された |

## 方式の決定

**Chrome 主体（案 A）**。認証はユーザーがログイン済みのブラウザセッションのみを使い、Claude は認証情報に触れない。API 主体（案 B）は各アプリに鍵の配線が必要で auto mode で止まる。既存 `asc-metadata-delivery` の拡張（案 C）は fastlane `deliver` が故障中（2026-08-28）で、Chrome 手順を混ぜると肥大化するため採らない。

## フロー

```
0. 前提確認   Chrome の ASC ログインを確認。ログイン/2FA 画面なら停止して人に渡す。
              アプリ特定は実行リポの fastlane/Appfile の app_identifier（無ければ pbxproj の
              PRODUCT_BUNDLE_IDENTIFIER）。skill 本体にアプリ固有値を持たない。
1. 状態読取   バージョン状態 / 紐付けビルド / What's New・marketing URL（ロケール別）/
   (read-only) スクショ枚数（デバイスファミリ別）/ TestFlight の VALID ビルド一覧 /
              Xcode Cloud 最新 run のテスト内訳
2. 差分計算   リポ入力と ASC を項目別に照合し unchanged / update / skip / needs-build に分類。
              「バージョン新規作成」「build N 紐付け」も差分表の 1 行として出す。
3. 🛑 判断①  差分表を提示し一括 OK を得る。OK はその実行 1 回にだけ有効。表に無い書き込みはしない。
4. 書き込み   Chrome で入力・保存 → 項目ごとに読み戻して一致を確認。
5. 🛑 判断②  needs-build の時だけ「Xcode Cloud でビルドを開始しますか？」を確認してから起動。
6. ビルド紐付け  VALID かつ バージョン文字列 == pbxproj の MARKETING_VERSION の最新ビルド。
              build 番号（CURRENT_PROJECT_VERSION）では判定しない（Xcode Cloud が自動採番する）。
7. 停止       「提出準備完了」レポート（差分結果 / 紐付け build / テスト内訳）を出して終了。
              審査提出ボタンは人が押す。Claude は押さない。
```

### モード

- **既定は dry-run**: 0〜2 のみ実行し、書き込み 0 件。Chrome 操作は単体テストできないため、dry-run を「何度回しても安全な検証手段」とする。
- 書き込みモードは判断①の OK 後にのみ入る。

### 差分の分類ルール

| 分類 | 条件 | 動作 |
|---|---|---|
| unchanged | リポ値 == ASC 値 | 何もしない |
| update | リポ値あり かつ ASC 値と異なる | 判断①の対象 |
| skip | リポ値が空・プレースホルダー・未記載 | **書き込まない**（live を空で上書きしない） |
| needs-build | 条件を満たす VALID ビルドが無い | 判断②へ |

### エラー時

セッション切れ・画面構造が想定と違う・読み戻し不一致のいずれでも **その場で停止** し、「どの項目まで書いたか」を報告する。自動リトライはしない。

### 既知の ASC 入力制約（既存知見の再掲）

- en ロケールは絵文字 NG、ja も What's New の 🫧 (U+1FAE7) は拒否された → 絵文字を含む値は差分表で警告。
- 規約未同意時は ASC 全体が塞がる → Business ページでの同意を案内して停止。

## 入力元

| 項目 | 入力元 |
|---|---|
| What's New（ja/en） | `docs/RELEASE_v<ver>.md` の What's New 節 |
| 説明文・キーワード・サブタイトル・プロモ | `docs/app-store-metadata.md` |
| marketing / support URL | `docs/app-store-metadata.md`（無ければ skip） |
| スクショ | リポの生成物パス（BubblePop は `scripts/screenshots/` の出力） |

アプリによって docs 構成が違う場合、skill は閉じた選択肢で所在を確認する。`fastlane/metadata/` は現状空のため使わない（fastlane 経路が必要になった時に上記 docs から生成する位置づけ。今は作らない）。

## 初回実走の範囲（1 歩目）

対象: BubblePopGame v1.1。

- 実行する: 0 → 1 → 2（What's New / URL は 2026-08-28 投入済みのため unchanged 見込み）→ 判断① → build 46 紐付け → 7。
- 実行しない: スクショアップロード、判断②（ビルド起動）。skill には手順を書くが状態は `validating` と明記し、次にスクショ更新のあるリリースで検証する。

## 成果物と配置

- `~/.claude/skills/asc-submission-prep/SKILL.md`（新規・グローバル。既存 skill と同じく git 管理外）
- `~/.claude/skills/asc-metadata-delivery/SKILL.md` に「Chrome 経路は asc-submission-prep」へのリンク 1 行
- 本リポ PR: 本 spec / CLAUDE.md 追記 / `docs/RELEASE_v1.1.md` のチェックリスト更新（build 46・#44 実測）

## 物差し

- 初回実走で「申請準備の所要時間」と「人の手直し回数」を記録し、`docs/RELEASE_v1.1.md` の Retrospective に残す。
- 2 アプリ目（OtetsudaiCoin 等）の実走で同じ 2 指標を比較する。下がらなければ skill を薄くする。

## スコープ外

- 審査提出ボタンのクリック（常に人）
- コピーライティング（入力は執筆済み docs）
- スクショ画像の生成（既存の生成スクリプトの領分）
- ASC API / fastlane 経由の投入（既存 `asc-metadata-delivery` の領分）

## Issue の扱い

- #44: build 46 の実測（UITest 0 件・Unit 84/84）をコメントし、ビルド全体 14 分を今後の基準値として記録してクローズ（前後比較は過去 run が UI/API とも無く不能と明記）。
- #46: v1.1 提出が受理され `git tag v1.1` を push した時点でクローズ。
- #53: skill 作成と v1.1 初回実走で `validating`。2 アプリ目の実走で物差しを確認してクローズ判断。
