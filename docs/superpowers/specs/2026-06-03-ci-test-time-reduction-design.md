# CI テスト時間の短縮（Issue #44）設計

- 日付: 2026-06-03
- 対象 Issue: #44「テスト時間が長すぎる。」（Xcode Cloud の CI/CD が時間かかりすぎる）
- ブランチ: `feature/issue-44-ci-test-time`（base=main）

## 1. 背景と問題

Xcode Cloud の CI/CD 所要時間が長い。コード読みの推測ではなく、ローカル iPhone 17 Pro シミュレータで工程別に**実測**した内訳:

| 工程 | 時間 | 割合 |
| --- | --- | --- |
| クリーンビルド（app + Unit + UI 全ターゲット, `build-for-testing`） | 16s | ~2% |
| UnitTest 実行（84 `@Test` funcs, `BubblePopGameTests`） | 85s | ~12% |
| **UITest 実行（11 funcs / per-config 反復で 39 ケース実行, `BubblePopGameUITests`）** | **617s（約10分）** | **~86%** |

計測方法: `xcodebuild build-for-testing`（クリーン）→ `test-without-building -only-testing:<target>` で工程を分離して `SECONDS` 計測。

### 根本原因

1. **UITest が圧倒的なボトルネック（全体の 86%）。** 各 funcs が `app.launch()`（コールド起動）を行い、CI では 1 回あたり数〜十数秒かかる。
2. **`runsForEachTargetApplicationUIConfiguration = true` による反復実行。** `BubblePopGameUITestsLaunchTests` の `testMemoryUsageAfterLaunch` / `testOrientationHandling` がログ上で**各 6 回以上**実行されており、UI 構成ごとの反復が時間を乗算している（各 ~12s × 6 回 = ~70〜90s/テスト）。
3. **ハードな固定待機 `sleep(1/2/3)` が多数。** 固定 sleep が積み上がり、かつ flaky の温床になっている。
4. **共有スキーム・テストプランが両方とも不在。** `app/BubblePopGame.xcodeproj/xcshareddata/xcschemes/` が存在せず、`.xctestplan` も無い。そのため「CI で何を走らせるか」を制御する土台がなく、全テスト（Unit + UI）が無条件に走っている。

> 補足: CLAUDE.md は既に「UITest は起動失敗しやすい」「UnitTest のみに絞ると UITest 起動失敗の影響を避けられる」と複数箇所で警告しており、UITest の CI 上の信頼性は元々低い。本設計はこの既存スタンスと整合する。

## 2. ゴール

毎回の CI（push / PR ごと）を「ビルド + Unit ≈ 100s 前後」に収め、現状（~718s）から**約 86% 削減**する。UITest は CI の毎回実行から外し、回すときも明白な無駄を削って速く・安定させる。

## 3. 確定した方針（ブレスト合意）

- **毎回 CI = UnitTest のみ。** UITest は別枠。
- **UITest の別枠 = 手動 / ローカル + リリース前のみ。** Nightly や専用 Xcode Cloud ワークフローは作らない（リポ完結・最小）。
- **UITest 自体の無駄削減も今回のスコープに含める**（per-config 反復の無効化、ハード sleep の置換）。トレードオフとして per-config 反復で得ていた複数 UI 構成のカバレッジは低下することを許容する。

## 4. コンポーネント設計（すべてリポ側で完結）

### ① 共有スキーム新設

`app/BubblePopGame.xcodeproj/xcshareddata/xcschemes/BubblePopGame.xcscheme`

- スキームを共有化し、TestAction に下記 2 つのテストプランを参照させる。
- **デフォルトテストプランを `CI`** に設定する（`default = "YES"`）。
- これが全レバーの土台。現状スキームが未共有 = CI 設定が暗黙であるため、まずここを明示化する。

### ② テストプラン 2 枚

配置: `app/`（`.xcodeproj` と同階層。`container:` の `../` 解決を避けるため。当初案の `app/TestPlans/` から変更）

参考: ターゲット GUID（`project.pbxproj` より）
- app `BubblePopGame`: `D5DF7FBE2E28B0A4002424F1`
- `BubblePopGameTests`: `D5DF7FCD2E28B0A6002424F1`
- `BubblePopGameUITests`: `D5DF7FD72E28B0A6002424F1`
- container: `container:BubblePopGame.xcodeproj`

- **`CI.xctestplan`（デフォルト）**
  - テストターゲット: `BubblePopGameTests` のみ
  - `parallelizable = true`（並列実行で 85s のさらなる短縮を狙う）
- **`Full.xctestplan`**
  - テストターゲット: `BubblePopGameTests` + `BubblePopGameUITests`
  - pre-release / 手動でこちらを `-testPlan Full` で明示指定して実行

### ③ UITest の無駄削減

- `BubblePopGameUITestsLaunchTests` の `runsForEachTargetApplicationUIConfiguration` を **`false`** に（同一テストの多重反復を解消。数百秒級の削減）。
- ハード `sleep(1/2/3)` を、既に併用している `waitForExistence(timeout:)` ベースの待機へ置換（固定待機の積み上げ解消 + flaky 緩和）。安定化に寄与する範囲で段階的に置換する。

## 5. CI が拾う仕組みと検証

- スキームのデフォルトテストプランを `CI` にすれば、テストプラン未指定の `xcodebuild test`（および Xcode Cloud の標準 Test アクション）は **Unit-only** を実行する。
- **検証コマンド:**
  - `xcodebuild -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -showTestPlans` → `CI` / `Full` が列挙され、`CI` がデフォルト
  - `xcodebuild test ... -testPlan CI` → `BubblePopGameTests` のみ実行（UITest が走らない）
  - `xcodebuild test ... -testPlan Full` → Unit + UITest 実行
- **before / after の実測時間を記録**し、PR 本文に残す（CLAUDE.md の grep でテスト実体を確認）。

### 実測結果（最終 HEAD での before/after）

計測環境: iPhone 17 Pro シミュレータ、ローカル、`SECONDS` 計測。本表は per-config 反復無効化（#44 Task 4）+ ハード sleep 置換（Task 5）まで反映した**最終 HEAD**での値。

**毎回 CI（push/PR ごと）の総時間**（クリーン後の bare `xcodebuild test`、`-testPlan` 未指定 = デフォルト CI プラン）:

| | 総時間（build + test） | 実行内容 |
| --- | --- | --- |
| before（テストプラン導入前・全テスト） | 約 718s | Unit + UITest（UITest は per-config 反復で 39 ケース） |
| **after（デフォルト CI プラン）** | **105s** | Unit のみ・**UITest 0 件**（bare 実行で `Test case 'BubblePopGameUITests` = 0 を確認） |

→ 毎回 CI を **約 85% 削減**。`-testPlan` 省略の bare `xcodebuild test` で UITest 0 件 = デフォルトの CI プランが拾われることを実証。

**テスト実行のみ**の時間（`test-without-building`、ビルドキャッシュ使用、参考値）:

| テストプラン | 実行ターゲット | 経過時間 | UITest 実行ケース |
| --- | --- | --- | --- |
| CI（デフォルト） | BubblePopGameTests のみ | 62s | 0 |
| Full（per-config 無効化 + sleep 置換後） | Unit + UITest | 197s | 11（全 passed） |

- Full の UITest は per-config 反復無効化で **39 → 11 ケース**に減少、ハード sleep 置換と合わせ test-only 時間は 617s → **197s**。flaky 失敗なし。
- `xcodebuild -showTestPlans` で CI (default) / Full の 2 プランが列挙されることを確認。
- 注: §1 ベースライン表の旧「116 funcs」は `func test*` と `@Test` の重複カウント。全テストが Swift Testing (`import Testing`) で `@Test` = **84** が正（CI プランで 84 件全件 passed、skipped=0）。

## 6. スコープ外 / マージ後フォローアップ

- ⚠️ **Xcode Cloud ワークフロー設定は ASC 側にあり、リポからは変更できない。** 現在のワークフローが明示的にテストターゲットを列挙している場合、ASC 側で「CI テストプランを使う / UITest ターゲットを外す」設定の確認・更新が**1 回だけ**必要。マージ後タスクとして PR に明記する（#46 の ASC 作業と同じ構図）。
- UITest の更なる削減（冗長テストの統廃合、Page Object 化など）は本 PR の対象外。

## 7. リスクと対処

- **共有スキーム / xctestplan を手書きする際のフォーマット誤り** → `xcodebuild -showTestPlans` と `-testPlan` 実行で都度検証し、壊れていないことを確認する。
- **per-config 反復の無効化によるカバレッジ低下** → 合意済みのトレードオフ。orientation テストは単一構成で残るため、最低限の回転検証は維持される。
- **既存 Xcode Cloud ワークフローがテストプランを自動で拾わない可能性** → §6 のフォローアップで ASC 側確認を必須化することで担保。
