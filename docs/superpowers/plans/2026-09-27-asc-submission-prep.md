# asc-submission-prep Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 全アプリ共通のグローバル skill `asc-submission-prep` を作り、BubblePopGame v1.1 で初回実走して「提出ボタン直前」まで進める。

**Architecture:** skill は手順書（SKILL.md）で、実行は claude-in-chrome によるログイン済み ASC の読み取り・書き込み。既定は dry-run（読み取りと差分計算のみ）で、書き込みは差分表への一括 OK 後だけ。検証は単体テストではなく、既知の事実（2026-09-27 の Chrome 読み取り）と dry-run の出力を突き合わせて行う。

**Tech Stack:** Claude Code skill（Markdown）/ claude-in-chrome MCP / App Store Connect Web UI / gh CLI

**Spec:** `docs/superpowers/specs/2026-09-27-asc-submission-prep-design.md`

## Global Constraints

- 審査提出ボタン（「審査用に追加」「審査へ提出」）は Claude が押さない。常に人が押す。
- 書き込みは判断①（差分表への一括 OK）の後だけ。OK は実行 1 回にだけ有効。表に無い書き込みはしない。
- Xcode Cloud のビルド起動は判断②で確認してから。
- 認証情報（API Key / .p8 / パスワード）は読まない・入力しない。ログイン/2FA 画面が出たら停止して人に渡す。
- ビルド紐付け条件: VALID かつ バージョン文字列 == pbxproj の `MARKETING_VERSION`。build 番号では判定しない。
- skip（リポ値が空・プレースホルダー）の項目は書き込まない。
- skill 本体にアプリ固有値（bundle id・Apple ID・URL）を書かない。
- ステータス語は `done / in-progress / validating / idea` の 4 値。スクショアップロードとビルド起動は初回実走後も `validating`。

## Review Focus

1. **ビルド紐付け時の輸出コンプライアンス（暗号化）確認ダイアログ** — ビルド追加時に ASC が暗号化の質問を出す場合がある。想定: 回答は人の判断事項として停止し、選択肢を提示する（Claude が勝手に回答しない）。→ Task 1 の手順に記載、Task 3 で遭遇したら記録。
2. **ロケール切替で値を読み違える** — ja 表示のまま en の値を読んだつもりになる。想定: 各ロケールで画面上のロケール名を確認してから値を読む。→ Task 1 手順、Task 2 の dry-run で ja/en 両方の値を表に出して確認。
3. **フォーム値がページテキストに出ない** — `get_page_text` は input/textarea の値を返さない（2026-09-27 実測）。想定: `find`/`read_page` またはスクショで値を読む。→ Task 1 手順、Task 2 で確認。
4. **保存し忘れ／未保存ダイアログ** — ASC は右上「保存」を押すまで反映されない。想定: 書き込み後に「保存」→ページ再読み込み→読み戻しで一致確認。→ Task 3。
5. **絵文字入りの入力値** — ASC が `INVALID_CHARACTERS` で拒否する。想定: 差分表で警告し、絵文字なし版を人に選ばせる。→ Task 1 手順、Task 2 で RELEASE_v1.1.md の 🫧 案が警告されることを確認。

---

### Task 1: SKILL.md を作成する

**Files:**
- Create: `~/.claude/skills/asc-submission-prep/SKILL.md`
- Modify: `~/.claude/skills/asc-metadata-delivery/SKILL.md`（「When to Use」直後に 1 行リンク）

**Interfaces:**
- Produces: skill 名 `asc-submission-prep`、起動フレーズ「v<ver> の申請準備して」「ASC 申請準備」、出力 = 差分表（列: 項目 / ロケール / ASC 現在値 / リポ値 / 分類 / 入力元）と停止レポート。Task 2・3 はこの表形式を使う。

- [ ] **Step 1: frontmatter と Overview を書く**

```markdown
---
name: asc-submission-prep
description: Use when preparing an App Store Connect submission for any iOS app up to (but not including) the "submit for review" click, via the logged-in Chrome session (claude-in-chrome) — covers reading version/build/metadata state, diffing against repo docs (RELEASE_v<ver>.md / app-store-metadata.md), a single batched human OK before any write, attaching the VALID build whose version matches MARKETING_VERSION, optional Xcode Cloud build start behind a second human OK, and a stop report. Default mode is dry-run (read + diff, zero writes). Never touches credentials; never clicks submit.
---
```

Overview 節に: 目的（人の作業を「差分 OK」「提出ボタン」の 2 つにする）、fastlane/API 経路は `asc-metadata-delivery` の領分であること、ステータス（読取・差分・紐付け = 初回実走で検証予定 / スクショ・ビルド起動 = validating）。

- [ ] **Step 2: フロー 0〜7 を書く**

spec の「フロー」節 0〜7 をそのまま手順化する。各ステップに使う claude-in-chrome ツールを明記:
- 0: `tabs_context_mcp(createIfEmpty:true)` → ASC トップに `navigate` → スクショでログイン状態確認。ログイン/2FA/規約同意画面なら停止。アプリ特定は `grep app_identifier fastlane/Appfile`、無ければ `grep PRODUCT_BUNDLE_IDENTIFIER *.pbxproj`。ASC の「アプリ」一覧でその bundle id のアプリを開く。
- 1: 配信タブの `version/inflight` → `get_page_text` でバージョン状態・ビルド欄。フォーム値は `get_page_text` に出ないので `find`（例: 「このバージョンの最新情報 textarea」）またはスクショで読む（Review Focus 3）。ロケールは画面上部のロケール選択で切り替え、切替後にロケール名を確認してから読む（Review Focus 2）。TestFlight `testflight/ios` でバージョン・ビルド・ステータス一覧。Xcode Cloud のビルド一覧→最新 run → Test アクション → 「テスト」タブで内訳。
- 2: 差分表を作る。分類ルールは spec の表。絵文字を含むリポ値には ⚠️ を付け、絵文字なし版を候補として併記（Review Focus 5）。
- 3: AskUserQuestion で「この差分表の書き込みをまとめて実行 / 修正する / dry-run で終了」。
- 4: 各項目を入力 → 右上「保存」→ 再読み込み → 読み戻し一致確認（Review Focus 4）。不一致なら停止して報告。
- 5: needs-build の時だけ AskUserQuestion で「Xcode Cloud でビルド開始 / しない」。開始はビルド一覧の「ビルドを開始」→ workflow と branch を人が確認した値で選択。（validating）
- 6: 「ビルドを追加」→ 条件に合う最新ビルドを選択 → 完了 → 保存。輸出コンプライアンス等の質問ダイアログが出たら回答せず停止し、質問文と選択肢を人に提示（Review Focus 1）。
- 7: 停止レポート（テンプレートを Step 3 で定義）。

- [ ] **Step 3: 差分表と停止レポートのテンプレートを書く**

```markdown
| 項目 | ロケール | ASC 現在値 | リポ値 | 分類 | 入力元 |
|---|---|---|---|---|---|
| バージョン | - | 1.1 提出準備中 | 1.1 | unchanged | pbxproj MARKETING_VERSION |
| What's New | ja | （先頭40字） | （先頭40字） | unchanged | docs/RELEASE_v1.1.md |
| ビルド | - | 未紐付け | build 46 (1.1, VALID) | update | TestFlight |
```

停止レポート: 「✅ 提出準備完了 / 紐付け build / 書き込んだ項目と読み戻し結果 / Xcode Cloud テスト内訳 / 人がやること: 内容確認 → 『審査用に追加』→ 提出」。

- [ ] **Step 4: Don't / Common Mistakes 節を書く**

Global Constraints の禁止事項、spec の「既知の ASC 入力制約」（en 絵文字 NG・ja も U+1FAE7 拒否実績・規約未同意で全体停止）、`get_page_text` がフォーム値を返さない実測。

- [ ] **Step 5: asc-metadata-delivery にリンクを 1 行追加**

「When to Use」節の直後に:

```markdown
> Chrome（ログイン済み ASC）で認証情報に触れずに申請準備を進めたい場合は [[asc-submission-prep]] を使う。
```

- [ ] **Step 6: 自己チェック**

Run: `grep -nE 'com\.asapapalab|6748926018|BubblePop' ~/.claude/skills/asc-submission-prep/SKILL.md`
Expected: 出力なし（アプリ固有値ゼロ）。例示に BubblePop を使う場合は「例:」と明記された行のみ許容。

（skill は git 管理外のためコミットなし。）

---

### Task 2: BubblePopGame v1.1 で dry-run（書き込み 0 件）

**Files:** なし（Chrome 読み取りのみ）

**Interfaces:**
- Consumes: Task 1 の SKILL.md 手順と差分表テンプレート
- Produces: 差分表（Task 3 の判断①に使う）

- [ ] **Step 1: SKILL.md に従い 0〜2 を実行**

`asc-submission-prep` skill を起動し、dry-run で実行する。

- [ ] **Step 2: 既知事実と突き合わせる**

Expected（2026-09-27 の事前読み取りと一致すること）:
- バージョン 1.1「提出準備中」
- ビルド: 未紐付け → 候補 build 46（1.1, 提出準備完了）→ 分類 update
- What's New ja/en: ASC 値が 2026-08-28 投入文と一致。RELEASE_v1.1.md の ja 案に 🫧 があれば ⚠️ 警告が付き、絵文字なしフォールバック文が ASC 値と一致して unchanged
- marketing URL ja/en: `https://note.com/es0612swift`
- Xcode Cloud build 46: Test 84/84、UITest 0 件

不一致があれば「SKILL.md の手順の不備」か「ASC 側の変化」かを切り分け、手順の不備なら SKILL.md を直して Step 1 からやり直す。

- [ ] **Step 3: 所要時間を記録**

dry-run の開始・終了時刻をメモ（物差し用、Task 4 で使う）。

---

### Task 3: v1.1 に build 46 を紐付け、停止レポートを出す

**Files:** なし（ASC への書き込み）

**Interfaces:**
- Consumes: Task 2 の差分表

- [ ] **Step 1: 判断①**

差分表を提示し、AskUserQuestion で一括 OK を得る。OK が無ければ書き込まずに Task 4 へ。

- [ ] **Step 2: build 46 を紐付けて保存**

SKILL.md のフロー 6 に従う。ダイアログが出たら停止して人に提示（Review Focus 1）。

- [ ] **Step 3: 読み戻し**

ページを再読み込みし、ビルド欄が build 46 (1.1) になっていることを確認。スクショを `save_to_disk:true` で保存。

- [ ] **Step 4: 停止レポート**

テンプレートどおりに出力。人の手直し回数（判断①での修正・ダイアログ対応など）を数えてメモ。

---

### Task 4: RELEASE_v1.1.md 更新・PR 作成

**Files:**
- Modify: `docs/RELEASE_v1.1.md`（ASC 側チェックリスト 58〜67 行付近、クローズ条件、末尾に Retrospective の下書き）

- [ ] **Step 1: チェックリストを実態に更新**

- 「v1.1 新規作成」「What's New 入力」「marketing URL 付け替え」: `[x]`（2026-08-28 API 投入済み、2026-09-27 Chrome で確認）
- 「Xcode Cloud 配信ビルド」: `[x]` build 46（2026-09-27 手動ビルド、`03e7ca3`）。build 40 の記述を「build ≥ 40（実際は 46）」に訂正
- #44 の 3 項目: `[x]`（UITest 0 件・Unit 84/84、所要時間は比較元が無いので 14 分を基準値として記録）
- 「build 46 を v1.1 に紐付け」行を追加して `[x]`（Task 3 が成功した場合のみ）
- 残り: 人が「審査用に追加」→ 提出 → 受理後 `git tag v1.1`

- [ ] **Step 2: 物差しを記録**

末尾に「## asc-submission-prep 初回実走（2026-09-27）」節: 所要時間 / 人の手直し回数 / 遭遇した想定外（ダイアログ等）/ validating のまま残った項目（スクショ・ビルド起動）。

- [ ] **Step 3: コミット**

```bash
git add docs/RELEASE_v1.1.md docs/superpowers/plans/2026-09-27-asc-submission-prep.md
git commit -m "docs: v1.1 提出チェックリストを実態に更新し asc-submission-prep 初回実走を記録 (toward #53, #46)"
```

- [ ] **Step 4: push と PR 作成**

```bash
git push -u origin feature/issue-53-asc-chrome-automation
gh pr create --base main --title "docs: ASC 申請準備 skill の設計と v1.1 初回実走 (toward #53, #46)" --body "<概要 / 変更ファイル / skill は ~/.claude/skills 配下で本 PR 外 / Test plan: dry-run 差分表が既知事実と一致・build 46 紐付けの読み戻し・人が提出 / Toward #53 #46>"
```

- [ ] **Step 5: #53 に進捗コメント**

投稿直前に ASC の v1.1 ビルド欄を再確認してから（鮮度チェック）、「skill 作成・初回実走済み（validating）、2 アプリ目の実走でクローズ判断」をコメントする。
