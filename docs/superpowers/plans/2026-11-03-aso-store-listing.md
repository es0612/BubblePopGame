# #78 ASO（アプリ名・ストア画像）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 1.1.2 で、検索結果の 1 行（名前・サブタイトル・最初の 3 枚）から「タップで割る楽しさ／親子で安心／30 秒で気分転換」が伝わり、en ストアに en の画面と en のキャプションが出るようにする。

**Architecture:** アプリ側は DEBUG の撮影用起動引数だけを変える（プレイ途中の状態を `startGame()` の最後で注入する）。画像は `compose_screenshots.py` をロケール別にして ja/en を合成する。テキストのメタデータは `docs/app-store-metadata.md` で案を出して PO が選び、ASC へは `asc-submission-prep` で入力する。効果は、検索順位の測定スクリプトと ASC アナリティクスで前後を比べる。

**Tech Stack:** SwiftUI / SwiftTesting（`xcodebuild test`）/ Python 3 + Pillow / `xcrun simctl` / iTunes Search API

**Spec:** `docs/superpowers/specs/2026-11-03-aso-store-listing-design.md`

## Global Constraints

- 1.1.2 は ASO だけで出す。アプリ側の変更は DEBUG の撮影用起動引数だけ（`#if DEBUG` の外に撮影用コードを置かない）
- スクショのためにゲームの UI を変えない
- 注入する値は実プレイで到達できる値にする（`result` の既存サンプル: スコア 1280 / 破裂 96 / 最大連鎖 18 / 104 タップ中 96 成功 ≒ 1 個 13 点）
- キャプション・メタデータに、アプリにない機能を書かない（ガイドライン 2.3.1）。絵文字を入れない（ja/en とも）
- アプリ名・サブタイトルは 30 文字以内、キーワードは 100 文字以内（カンマ区切り、カンマの後に空白を入れない）
- ja のアプリ名は「シャボン玉消しゲーム」を残し、後ろに価値を足す
- 画像の並び: 1 ゲーム（ノーマル）→ 2 ゲーム（数字モード）→ 3 リザルト → 4 メニュー → 5 設定
- ja キャプション（試作の文言・PO の最終選択で変わりうる）: 「タップでぱちん！シャボン玉」「広告なし。親子で安心して遊べる」「30秒で気分転換」「BGMで癒しのひととき」「時間も数も好みに調整」
- 出力サイズ: iPhone 6.9"（1290×2796）/ 6.5"（1242×2688）/ iPad 13"（2064×2752）× ja / en
- `app/` を変える PR は、PR #79（1.1.2 への bump）が main に入るまでマージしない
- 撮影後は必ず `xcrun simctl terminate`（BGM がデフォルト ON）

## Review Focus

1. 起動直後は `screenBounds == .zero` で `startGame()` が保留され、画面サイズが届いたときに走る `startGame()` がスコアを 0 に戻す → 保留を経由しても注入した値が残ること（Task 1 のテスト `snapshotSurvivesDeferredStart`）
2. Release ビルドに撮影用コードが入らないこと（Task 1 の Step 6 で Release ビルドが通ることと、`ScreenshotGameSnapshot` が `#if DEBUG` の中にあることを確認）
3. 注入後もタイマーは進む。撮影まで（起動から約 5 秒）に残り時間が 0 になってリザルトに切り替わらないこと → 注入する残り時間は 15 秒以上（Task 1 のテスト `snapshotsKeepEnoughTime`）
4. en キャプションが長く、自動縮小で読めないほど小さくなること → 6.5" のキャンバスで文字サイズが幅の 5% 以上（Task 3 のテスト `test_en_captions_fit_without_shrinking_too_far`）
5. 検索 API の失敗（通信エラー・HTTP エラー）を「圏外」として記録すること → 失敗は `ERROR` と書き、圏外と区別する（Task 2 のテスト `test_fetch_error_is_not_out_of_rank`）

---

### Task 1: プレイ途中の状態を撮影用に注入する（DEBUG）

**Files:**
- Create: `app/BubblePopGame/Utils/ScreenshotGameSnapshot.swift`
- Modify: `app/BubblePopGame/ViewModels/GameViewModel.swift`（プロパティ追加と `startGame()` の末尾）
- Modify: `app/BubblePopGame/ContentView.swift:170-191`（`configureForScreenshot` の `game` / `game-numbered`）
- Test: `app/BubblePopGameTests/ScreenshotGameSnapshotTests.swift`

**Interfaces:**
- Produces（すべて `#if DEBUG` の中）:
  - `struct ScreenshotGameSnapshot: Equatable { let score: Int; let bubblesPopped: Int; let currentStreak: Int; let bestStreak: Int; let totalTaps: Int; let successfulTaps: Int; let timeRemaining: Double }`
  - `static let normal: ScreenshotGameSnapshot` / `static let numbered: ScreenshotGameSnapshot`
  - `GameViewModel.debugScreenshotSnapshot: ScreenshotGameSnapshot?`（`startGame()` が最後に適用する）

- [ ] **Step 1: 失敗するテストを書く**（`DebugOverrideTests.makeViewModel` と同じ組み立てで ViewModel を作る）

```swift
@MainActor @Suite("Screenshot game snapshot (#78)")
struct ScreenshotGameSnapshotTests {
    @Test func snapshotSurvivesDeferredStart() throws {
        let vm = try DebugOverrideTests.makeViewModel(gameTime: 30)
        vm.debugScreenshotSnapshot = .normal
        vm.startGame()                                   // screenBounds == .zero → 保留
        vm.updateScreenBounds(CGSize(width: 402, height: 874))  // ここで実際に開始
        #expect(vm.gameState == .playing)
        #expect(vm.score == ScreenshotGameSnapshot.normal.score)
        #expect(vm.bubblesPopped == ScreenshotGameSnapshot.normal.bubblesPopped)
        #expect(vm.timeRemaining == ScreenshotGameSnapshot.normal.timeRemaining)
    }
    @Test func noSnapshotKeepsNormalReset() throws {
        let vm = try DebugOverrideTests.makeViewModel(gameTime: 30)
        vm.updateScreenBounds(CGSize(width: 402, height: 874))
        vm.startGame()
        #expect(vm.score == 0)
        #expect(vm.timeRemaining == 30)
    }
    @Test func snapshotsKeepEnoughTime() {
        #expect(ScreenshotGameSnapshot.normal.timeRemaining >= 15)
        #expect(ScreenshotGameSnapshot.numbered.timeRemaining >= 15)
        #expect(ScreenshotGameSnapshot.normal.timeRemaining < 30)   // 初期値 30 秒より減っている＝途中に見える
    }
    @Test func snapshotsAreReachable() {
        for s in [ScreenshotGameSnapshot.normal, .numbered] {
            #expect(s.successfulTaps == s.bubblesPopped)
            #expect(s.totalTaps >= s.successfulTaps)
            #expect(s.bestStreak >= s.currentStreak)
            #expect(s.score <= s.bubblesPopped * 14)        // result サンプルの 1 個 ≒ 13 点に揃える
        }
    }
}
```

- [ ] **Step 2: suite 単位で実行し、コンパイルエラー（`ScreenshotGameSnapshot` 未定義）で失敗することを確認**

Run: `xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:BubblePopGameTests/ScreenshotGameSnapshotTests 2>&1 | grep -iE "error:|Test case .* (passed|failed)"`
Expected: `cannot find 'ScreenshotGameSnapshot'`

- [ ] **Step 3: `ScreenshotGameSnapshot` と `.normal` / `.numbered` を実装する**（ファイル全体を `#if DEBUG` で囲む）。値は Step 1 のテストを満たし、`normal` は残り 15〜25 秒・スコア 3 桁、`numbered` は `normal` より少し小さい値にする

- [ ] **Step 4: `GameViewModel` に `debugScreenshotSnapshot` を足し、`startGame()` の末尾（`performanceService.startMonitoring()` の後）で `#if DEBUG` の中から適用する**。`perfectChain` は注入しない（倍率表示の不具合 #69 を写さないため）

- [ ] **Step 5: `configureForScreenshot` の `game` に `.normal`、`game-numbered` に `.numbered` を設定してから `startGame()` を呼ぶ**

- [ ] **Step 6: テストと Release ビルドを確認する**

Run: Step 2 のコマンド → Expected: 4 件が `passed`
Run: `xcodebuild test ... -only-testing:BubblePopGameTests 2>&1 | grep -E "\*\* TEST (SUCCEEDED|FAILED)"` → Expected: `** TEST SUCCEEDED **`
Run: `xcodebuild build ... -configuration Release -sdk iphonesimulator ... -quiet` → Expected: エラーなし（`ScreenshotGameSnapshot` が Release で参照されていない）

- [ ] **Step 7: 数字モードの数字の見え方を確かめる（コードは変えない）**。`--screenshot=game-numbered` で起動して撮り、`BubbleView.swift:28-` の数字の描画（色・不透明度）を読む。実際のゲームでも薄いなら、見やすさの不具合として Issue を起票し、その番号を PR 本文に書く

- [ ] **Step 8: Commit**（`git add` はパス指定。コミット前に `git diff | cat -e` で触っていない空行のインデントが消えていないか確認）

```bash
git add app/BubblePopGame/Utils/ScreenshotGameSnapshot.swift app/BubblePopGame/ViewModels/GameViewModel.swift app/BubblePopGame/ContentView.swift app/BubblePopGameTests/ScreenshotGameSnapshotTests.swift
git commit -m "feat: スクショ撮影用にプレイ途中の状態を注入する（DEBUG、#78）"
```

### Task 2: 検索順位を測るスクリプト

**Files:**
- Create: `scripts/aso/search_rank.py`
- Create: `scripts/aso/terms-ja.txt`（1 行 1 語。設計書の 3 系統＋「シャボン玉」「シャボン玉ゲーム」）
- Test: `scripts/aso/test_search_rank.py`（`unittest`）

**Interfaces:**
- Produces: `find_rank(results: list[dict], bundle_id: str) -> int | None` / `format_row(term: str, rank: int | None, total: int | None) -> str`（`total is None` は取得失敗）
- CLI: `python3 -I scripts/aso/search_rank.py scripts/aso/terms-ja.txt --country jp` → 標準出力に TSV（`term\trank\ttotal`。圏外は `圏外`、失敗は `ERROR`）。1 語ごとに 1 秒待つ。bundle id は `com.asapapalab.BubblePopGame`

- [ ] **Step 1: 失敗するテストを書く**: `test_find_rank_returns_1_based_position`（3 件中 2 件目 → 2）、`test_find_rank_none_when_absent`、`test_fetch_error_is_not_out_of_rank`（`format_row("泡", None, None)` が `"泡\tERROR\t-"`、`format_row("泡", None, 154)` が `"泡\t圏外\t154"`）
- [ ] **Step 2: 実行して失敗を確認**: `python3 -I -m unittest discover -s scripts/aso -v` → Expected: `ModuleNotFoundError`
- [ ] **Step 3: 実装する**（`urllib.request` だけで、追加依存なし。HTTP/通信エラーは `total=None`）
- [ ] **Step 4: テストが通ることと実データで動くことを確認**: unittest が 3 件 OK。CLI の出力で「シャボン玉ゲーム」が 2 位前後、「泡」が `圏外`（2026-11-03 の設計書の表と同じ傾向）
- [ ] **Step 5: Commit**: `git add scripts/aso/ && git commit -m "feat: ASO の検索順位を測るスクリプトを追加（#78）"`

### Task 3: スクショ合成をロケール別にする

**Files:**
- Modify: `scripts/screenshots/compose_screenshots.py`
- Modify: `scripts/screenshots/README.md`
- Test: `scripts/screenshots/test_compose_screenshots.py`（`unittest`。Pillow が要るので venv の python で実行）

**Interfaces:**
- Produces: `JOBS: dict[str, list[tuple[str, str]]]`（キーは `"ja"` / `"en"`。並びは Global Constraints の 5 画面）
- 入力: `/tmp/bpg-shots/{device}-{locale}-{screen}.png`、出力: `/tmp/bpg-final/{locale}/{canvas}__{NN}_{screen}.png`
- 既存の `fit_font(text, max_w, start_px, font_path)` はそのまま使う

- [ ] **Step 1: 失敗するテストを書く**: `test_locales_share_screen_order`（ja と en の画面キーの並びが同じで、`["game", "game-numbered", "result", "menu", "settings"]`）、`test_no_emoji_in_captions`（全キャプションが U+1F000 以上の文字を含まない）、`test_en_captions_fit_without_shrinking_too_far`（6.5" の幅 1242、余白 7% の条件で、各 en キャプションの `fit_font` の結果が 1242×0.05 px 以上）
- [ ] **Step 2: 実行して失敗を確認**: `<venv>/bin/python -I -m unittest discover -s scripts/screenshots -v` → Expected: `JOBS` が list のため失敗
- [ ] **Step 3: `JOBS` をロケール別の dict にし、`main()` を ja/en のループにする**。en キャプションは ja と同じ意味・絵文字なし。案を 2 つずつ PR 本文に並べ、PO が選ぶまでは 1 案目を入れておく
- [ ] **Step 4: テストが通ることを確認**: 3 件 OK
- [ ] **Step 5: README の手順を更新する**（撮影は `-AppleLanguages '(en)' -AppleLocale en_US` を付けて en も撮る。ファイル名にロケールを入れる。撮影後に terminate）
- [ ] **Step 6: Commit**: `git add scripts/screenshots/ && git commit -m "feat: スクショ合成を ja/en のロケール別にし、並びを変える（#78）"`

### Task 4: テキストのメタデータ案を出し、PO が選ぶ

**Files:**
- Modify: `docs/app-store-metadata.md`（アプリ名・サブタイトル・キーワードの節）
- Modify: `docs/RELEASE_v1.1.2.md`（このバージョンの内容・物差しのベースライン）

- [ ] **Step 1: 2〜3 案を作る**。各案は ja 名・ja サブタイトル・ja キーワード・en サブタイトル・en キーワードの組。案ごとに「どの語で何を拾うか」（3 系統のどれか）を書き、名前・サブタイトル・キーワードの間で語を重ねない
- [ ] **Step 2: 文字数を機械で確かめる**: `python3 -I -c` で各欄の `len()` を出し、名前・サブタイトル ≤ 30、キーワード ≤ 100、キーワードにカンマ後の空白・絵文字がないことを確認して、結果を案の表に書く
- [ ] **Step 3: 👤 PO に AskUserQuestion で案を選んでもらう**（人が判断する点 1。キャプションの ja/en の最終文言も同じ質問で選ぶ）
- [ ] **Step 4: 選ばれた案を `docs/app-store-metadata.md` に反映する**。キャプションの文言が試作と変わったら、`compose_screenshots.py` の `JOBS` も直す
- [ ] **Step 5: ベースラインを記録する**: Task 2 のスクリプトの出力（日付つき）と、ASC アナリティクスの直近 4 週（インプレッション・閲覧・初回ダウンロード）を `docs/RELEASE_v1.1.2.md` の物差しの節に書く。ASC はログイン済みの Chrome で読む
- [ ] **Step 6: Commit**: `git add docs/app-store-metadata.md docs/RELEASE_v1.1.2.md scripts/screenshots/compose_screenshots.py && git commit -m "docs: 1.1.2 のアプリ名・サブタイトル・キーワードを決め、物差しのベースラインを記録（#78）"`

### Task 5: 撮影・合成し、PO の OK をもらう

前提: Task 1 が main にマージ済み（PR #79 の後）。撮影は main の Debug ビルドで行う。

- [ ] **Step 1: Debug ビルドし、iPhone 17 Pro と iPad Pro 13" に入れる**（`scripts/screenshots/README.md` の手順）
- [ ] **Step 2: 5 画面 × ja/en × 2 デバイスを撮る**（`--screenshot=<画面>`、en は `-AppleLanguages '(en)' -AppleLocale en_US`。起動から約 5 秒で撮り、毎回 terminate）。`game` の画像でスコアが 0 でないこと、en の画像で UI が英語であることを Read で目視する
- [ ] **Step 3: 合成する**: `<venv>/bin/python scripts/screenshots/compose_screenshots.py` → Expected: `生成 30 枚`
- [ ] **Step 4: 👤 一覧画像（ja/en 別、最初の 3 枚に枠）を作って PO に見せ、OK をもらう**（人が判断する点 2）。NG の点は Task 1/3/4 に戻して直す
- [ ] **Step 5: `app-store-assets/screenshots/` を新しい画像で置き換える**（画像は `.gitignore` 対象なので commit はしない。置き換えたことを `docs/RELEASE_v1.1.2.md` に書いて commit）

### Task 6: 1.1.2 の申請準備（ASC）

- [x] **Step 0: 提出の前に、ASC アナリティクスの直近 4 週（インプレッション・閲覧・初回ダウンロード）を取って `docs/RELEASE_v1.1.2.md` に書く**。2026-11-03 は期間を切り替えられず未取得（設計書の物差しの節）。取れないまま提出すると前後比較ができないので、取れるまで提出しない。あわせて設計書のベースライン（検索順位）を RELEASE doc に転記する
- [x] **Step 1: skill `asc-submission-prep` で 1.1.2 の申請準備をする**: 名前・サブタイトル・キーワード（ja/en）、スクショ（ja/en を別々に。en の「ja を共有」をやめる）、What's New、ビルドの紐付け。What's New は「ストアの表示を改善」程度にし、アプリの機能が変わったと読める書き方をしない
- [x] **Step 2: 読み戻しで、名前・サブタイトル・キーワードが `docs/app-store-metadata.md` と一致することを確認する**
- [ ] **Step 3: 👤 審査への提出は PO が行う**（人が判断する点 3）
- [ ] **Step 4: 配信の 4 週後に、Task 4 Step 5 と同じ方法で後の値を記録し、設計書の「解釈の限界」を添えて #78 にコメントする**（#78 はこのコメントの後に手で閉じる。PR では `Refs #78` を使い、`Closes` は使わない）
