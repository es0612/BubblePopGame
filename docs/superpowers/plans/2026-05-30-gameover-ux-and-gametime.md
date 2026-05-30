# GameOver画面UX改善 + 制限時間デフォルト 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** リザルト画面を子供向けのお祝いトーンに整え（#37）、ゲームオーバー直後の誤タップを防ぎ（#36）、制限時間デフォルトを30秒にして既存ユーザーも移行する（#35）。

**Architecture:** 2つの独立した PR に分割（すべて base=main）。PR-A は `GameOverView.swift` と `Localizable.strings`（+ テスト可能な `elapsedPlaySeconds` を `GameViewModel` に追加）。PR-B は `GameSettings`/`GameScore` のデフォルト値変更と、起動時 `.task` で 1 回だけ走る条件付き migration。

**Tech Stack:** SwiftUI, SwiftData, SwiftTesting, MVVM (@Observable)。

**設計書:** `docs/superpowers/specs/2026-05-30-gameover-ux-design.md`

**テスト実行（CLAUDE.md 準拠）:** suite 単位で実行し、grep で実行確認する（メソッド単位指定は「0件 SUCCEEDED」罠があるため避ける）:
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BubblePopGameTests/<SuiteName> 2>&1 \
  | grep -iE "Suite.*(started|passed|failed)|Test case .* (passed|failed)"
```

---

# PR-A: リザルト画面UX (#37 + #36)

**ブランチ:** `feature/issue-37-36-gameover-ux`（作成済み）

## Task A1: プレイ時間バグ修正のための `elapsedPlaySeconds` を追加（TDD）

**背景:** `GameOverView.swift:102` は `seconds_format`（`"%d秒"`= 整数書式）に **Double** (`gameSettings.gameTime - timeRemaining`) を渡しており、`%d` に Double を渡すと 0/不正値になる（=「Play Time 0 sec」バグ）。整数を返すテスト可能な computed property を `GameViewModel` に追加して修正する。

**Files:**
- Test: `app/BubblePopGameTests/GameOverResultTests.swift`（新規）
- Modify: `app/BubblePopGame/ViewModels/GameViewModel.swift`（`effectiveGameTime`(L69-75) の直後に追加）

- [ ] **Step 1: 失敗するテストを書く**

`app/BubblePopGameTests/GameOverResultTests.swift` を新規作成:

```swift
//
//  GameOverResultTests.swift
//  BubblePopGameTests
//
//  #37: リザルトのプレイ時間表示（%d に Double を渡す 0 sec バグの回帰防止）
//

import Testing
import SwiftData
import Foundation
@testable import BubblePopGame

@MainActor
@Suite("リザルト プレイ時間表示 (#37)")
struct GameOverResultTests {

    static func makeViewModel(gameTime: Double = 30.0) throws -> GameViewModel {
        let schema = Schema([GameScore.self, GameStatistics.self, GameSettings.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let settings = GameSettings()
        settings.gameTime = gameTime
        return GameViewModel(
            bubbleService: BubbleServiceImpl(screenBounds: .zero),
            audioService: AudioServiceImpl(),
            effectService: EffectServiceImpl(),
            deviceService: DeviceServiceImpl(),
            performanceService: PerformanceServiceImpl(),
            scoreRepository: ScoreRepositoryImpl(modelContainer: container),
            settingsRepository: SettingsRepositoryImpl(modelContainer: container),
            statisticsRepository: StatisticsRepositoryImpl(modelContainer: container),
            gameSettings: settings
        )
    }

    @Test("経過プレイ秒数は effectiveGameTime - timeRemaining を整数で返す")
    func elapsedPlaySecondsComputesInteger() throws {
        let vm = try Self.makeViewModel(gameTime: 30.0)
        vm.timeRemaining = 10.0
        #expect(vm.elapsedPlaySeconds == 20)
    }

    @Test("タイムアップ（timeRemaining=0）でプレイ秒数は満了時間")
    func elapsedPlaySecondsAtTimeout() throws {
        let vm = try Self.makeViewModel(gameTime: 30.0)
        vm.timeRemaining = 0.0
        #expect(vm.elapsedPlaySeconds == 30)
    }

    @Test("ゲーム未開始（timeRemaining=満了）でプレイ秒数は0")
    func elapsedPlaySecondsBeforePlay() throws {
        let vm = try Self.makeViewModel(gameTime: 30.0)
        vm.timeRemaining = 30.0
        #expect(vm.elapsedPlaySeconds == 0)
    }
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run:
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BubblePopGameTests/GameOverResultTests 2>&1 \
  | grep -iE "error:|Suite.*(started|passed|failed)|Test case .* (passed|failed)"
```
Expected: ビルド失敗（`value of type 'GameViewModel' has no member 'elapsedPlaySeconds'`）= RED。

- [ ] **Step 3: 最小実装を書く**

`app/BubblePopGame/ViewModels/GameViewModel.swift` の `effectiveGameTime` computed property（L69-75 付近）の直後に追加:

```swift
    /// リザルト表示用の経過プレイ秒数（整数秒）。
    /// timeRemaining は effectiveGameTime から減算されるので、その差が実プレイ秒数。
    /// seconds_format = "%d秒" に Double を渡すと 0 になるバグ(#37)を、Int で返して防ぐ。
    var elapsedPlaySeconds: Int {
        max(0, Int((effectiveGameTime - timeRemaining).rounded()))
    }
```

- [ ] **Step 4: テストが通ることを確認**

Run:
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BubblePopGameTests/GameOverResultTests 2>&1 \
  | grep -iE "Suite.*(started|passed|failed)|Test case .* (passed|failed)"
```
Expected: `Test case 'elapsedPlaySecondsComputesInteger()' passed` など 3 件 passed = GREEN。

- [ ] **Step 5: コミット**

```bash
git add app/BubblePopGameTests/GameOverResultTests.swift app/BubblePopGame/ViewModels/GameViewModel.swift
git commit -m "feat: リザルトの経過プレイ秒数 elapsedPlaySeconds を追加 (#37)

%d 書式に Double を渡して 0 sec になるバグの修正基盤。整数秒を返す。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task A2: GameOverView の配色・タイトル・スタッツ整理 + ローカライズ（#37）

**Files:**
- Modify: `app/BubblePopGame/Views/GameOver/GameOverView.swift`
- Modify: `app/BubblePopGame/ja.lproj/Localizable.strings`
- Modify: `app/BubblePopGame/en.lproj/Localizable.strings`
- Modify: `app/BubblePopGame/Base.lproj/Localizable.strings`
- Regression test: `app/BubblePopGameTests/LocalizationKeysTests.swift`（既存・変更なしで実行）

- [ ] **Step 1: 削除キーが他で使われていないことを確認**

Run:
```bash
grep -rn "gameover_avg_reaction\|gameover_bubble_density" app/BubblePopGame --include="*.swift"
```
Expected: `GameOverView.swift` の 2 箇所（削除予定の StatRow）のみ。他に出たら削除前に確認。

- [ ] **Step 2: タイトル色を変更（赤→オレンジ）**

`GameOverView.swift:21` を変更:

```swift
// 変更前
                    .foregroundColor(.red.accessible())
// 変更後
                    .foregroundColor(.orange.accessible())
```

- [ ] **Step 3: 背景グラデーションをお祝いトーンへ（赤→青緑）**

`GameOverView.swift:116-119` を変更:

```swift
// 変更前
        .background(
            LinearGradient(colors: [.red.accessible().opacity(0.3), .orange.accessible().opacity(0.1)],
                          startPoint: .top, endPoint: .bottom)
        )
// 変更後
        .background(
            LinearGradient(colors: [.blue.accessible().opacity(0.22), .green.accessible().opacity(0.10)],
                          startPoint: .top, endPoint: .bottom)
        )
```

- [ ] **Step 4: 詳細統計から「平均反応速度」「シャボン玉密度」を削除し、「プレイ時間」を `elapsedPlaySeconds` に修正**

`GameOverView.swift:101-105`（`VStack(spacing: 8) { ... }` の中身）を以下に置き換え:

```swift
                    VStack(spacing: 8) {
                        StatRow(label: NSLocalizedString("gameover_play_time", comment: "Play time label"), value: String(format: NSLocalizedString("seconds_format", comment: "Seconds format"), viewModel.elapsedPlaySeconds))
                    }
```

（= `gameover_avg_reaction` と `gameover_bubble_density` の 2 行を削除し、`gameover_play_time` 行の値を `viewModel.elapsedPlaySeconds`（Int）に変更。`%d` 書式と型が一致する。）

- [ ] **Step 5: ローカライズ — タイトル文言の変更（ja / en / Base）**

`app/BubblePopGame/ja.lproj/Localizable.strings` の `gameover_title` 行:
```
"gameover_title" = "おしまい！";
```

`app/BubblePopGame/en.lproj/Localizable.strings` の `gameover_title` 行:
```
"gameover_title" = "All Done!";
```

`app/BubblePopGame/Base.lproj/Localizable.strings` の `gameover_title` 行:
```
"gameover_title" = "All Done!";
```

- [ ] **Step 6: ローカライズ — 削除2キーを ja / en / Base 全てから除去**

3 ファイルすべてから次の 2 行を削除:
```
"gameover_avg_reaction" = ...;
"gameover_bubble_density" = ...;
```
（ja: 「平均反応速度」「シャボン玉密度」、en/Base: "Avg Reaction Time" / "Bubble Density"）

- [ ] **Step 7: ローカライズの回帰テストを実行（パリティ＝3ファイルでキー集合一致を保証）**

Run:
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BubblePopGameTests/LocalizationKeysTests 2>&1 \
  | grep -iE "Suite.*(started|passed|failed)|Test case .* (passed|failed)"
```
Expected: 2 件 passed。**もし「1ロケールだけ消し忘れ」があれば `localizationsHaveIdenticalKeySets()` が failed になる** → 消し忘れたファイルを修正。

- [ ] **Step 8: ビルドが通ることを確認**

Run:
```bash
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`。

- [ ] **Step 9: コミット**

```bash
git add app/BubblePopGame/Views/GameOver/GameOverView.swift app/BubblePopGame/ja.lproj/Localizable.strings app/BubblePopGame/en.lproj/Localizable.strings app/BubblePopGame/Base.lproj/Localizable.strings
git commit -m "feat: リザルトを子供向けお祝いトーンに+スタッツ整理 (#37)

- タイトル赤→オレンジ、背景 赤系→青緑のお祝いトーン
- タイトル文言 Game Over→All Done!/おしまい!（勝ち負けのないゲームに合わせ失敗感を払拭）
- 平均反応速度・シャボン玉密度を削除（子供向けでない開発者指標）
- プレイ時間を elapsedPlaySeconds(Int) で表示し 0 sec バグを修正

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

> **Deferred optional（このPRのタスクに含めない）:** 設計書 #37-A の「`endGame()` 内 `triggerErrorFeedback()`（エラー触覚）→ 中立フィードバックへ差し替え」は任意項目。`EffectService` の中立/成功フィードバック API を未確認のため、推測のメソッド名を計画に書かず本計画では見送る。着手する場合は別途 `EffectService` の API を確認してから 1 ステップ追加すること。

---

## Task A3: ゲームオーバー直後の誤タップ防止ガード（#36）

**Files:**
- Modify: `app/BubblePopGame/Views/GameOver/GameOverView.swift`

- [ ] **Step 1: ガード用の state と定数を追加**

`GameOverView.swift:11-12` を変更:

```swift
// 変更前
struct GameOverView: View {
    let viewModel: GameViewModel
    @State private var showingStats = false
// 変更後
struct GameOverView: View {
    let viewModel: GameViewModel
    @State private var showingStats = false
    @State private var buttonsEnabled = false   // #36: GO直後の流れ弾タップ防止

    /// ゲームオーバー表示直後、この秒数だけボタンを無効化する
    private let buttonActivationDelay: TimeInterval = 0.7
```

- [ ] **Step 2: ボタン群に無効化＋フェードインを適用**

`GameOverView.swift:93`（ボタン群 `VStack` の `.padding(.horizontal, 30)` の直後）に修飾子を追加:

```swift
            .padding(.horizontal, 30)
            .disabled(!buttonsEnabled)
            .opacity(buttonsEnabled ? 1.0 : 0.35)
            .animation(.easeIn(duration: 0.3), value: buttonsEnabled)
```

- [ ] **Step 3: onAppear で遅延後にボタンを有効化**

`GameOverView.swift` の最外 `VStack` 末尾の `.background(...)`（L116-119）の直後に `.onAppear` を追加:

```swift
        .onAppear {
            buttonsEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + buttonActivationDelay) {
                buttonsEnabled = true
            }
        }
```

- [ ] **Step 4: ビルドが通ることを確認**

Run:
```bash
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`。

- [ ] **Step 5: 手動 walk-through（SwiftUI の onAppear タイミングは単体テスト不可）**

シミュレータでゲームをプレイ→終了し、ゲームオーバー画面出現直後の約0.7秒はボタンが薄く＆押せず、その後フェードインして押せることを確認（`ios-simulator-app-verification` skill 参照。タップ自体は simctl 不可なので目視＋クラッシュ無し確認まで）。

- [ ] **Step 6: コミット**

```bash
git add app/BubblePopGame/Views/GameOver/GameOverView.swift
git commit -m "fix: ゲームオーバー直後の誤タップ防止ガード (#36)

GO画面出現直後0.7秒はボタンを無効化＋フェードイン。プレイ中の連打が
Play Again に着弾して即リスタートするのを防ぐハードニング。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task A4: PR-A 全体テスト & PR 作成

- [ ] **Step 1: UnitTest 全体を実行**

Run:
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:BubblePopGameTests 2>&1 \
  | grep -iE "Suite.*(passed|failed)|Test case .* failed|TEST (SUCCEEDED|FAILED)"
```
Expected: failed が 0、`** TEST SUCCEEDED **`。

- [ ] **Step 2: push & PR 作成（base=main）**

```bash
git push -u origin feature/issue-37-36-gameover-ux
gh pr create --base main --head feature/issue-37-36-gameover-ux \
  --title "feat: リザルト画面UX改善（お祝いトーン+スタッツ整理+誤タップ防止） (#37, #36)" \
  --body "$(cat <<'EOF'
## 概要
- #37: リザルトを子供向けお祝いトーンへ。タイトル赤→オレンジ、背景 赤系→青緑、文言 Game Over→All Done!/おしまい!（勝ち負けのないゲームに失敗感は不要）。平均反応速度・シャボン玉密度を削除し、プレイ時間の 0 sec バグ（%d に Double）を `elapsedPlaySeconds`(Int) で修正。
- #36: ゲームオーバー直後 約0.7秒はボタンを無効化+フェードイン。プレイ中の連打が Play Again に着弾して即リスタートするのを防ぐハードニング。

## Test plan（マージ前手動確認）
- [ ] 背景が明るいお祝いトーン（赤くない）
- [ ] タイトル「おしまい！/All Done!」がポジティブな色
- [ ] 平均反応速度・シャボン玉密度が消えている
- [ ] プレイ時間が正しい秒数（0 sec にならない）
- [ ] ja / en 両方で確認（en に文言反映）
- [ ] GO直後 約0.7秒ボタン無効→フェードイン
- [ ] ⚠️ #36 は実機/タップ無しで再現不可。TestFlight 実機で誤タップ解消を確認してからクローズ（推測で fixed 断定しない）

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

# PR-B: 制限時間デフォルト30秒 + 移行 (#35)

**ブランチ:** `feature/issue-35-default-gametime`（main から新規作成）

## Task B0: ブランチ作成

- [ ] **Step 1: main から新ブランチを切る**

```bash
git checkout main
git pull --ff-only origin main
git checkout -b feature/issue-35-default-gametime
```

---

## Task B1: デフォルト値 60→30 へ変更 + 既存テスト更新（TDD）

**背景:** デフォルトを変えると、デフォルト60を前提にした既存テスト4箇所が壊れる。テストを先に30へ更新（RED）→ デフォルト値変更（GREEN）の順で進める。

**Files:**
- Modify: `app/BubblePopGame/Models/GameSettings.swift:47`
- Modify: `app/BubblePopGame/Models/GameScore.swift:22`
- Modify: `app/BubblePopGame/ViewModels/GameViewModel.swift:18`
- Modify (test 期待値 60→30): `app/BubblePopGameTests/BasicPropertyTests.swift:20`, `SimpleGameViewModelTests.swift:21`, `SimpleSwiftDataTests.swift:45`, `DebugOverrideTests.swift:58`

- [ ] **Step 1: 既存テストの期待値を 30 に更新（先に RED 化）**

各ファイルの該当行を変更:

`BasicPropertyTests.swift:20`:
```swift
        #expect(settings.gameTime == 30.0)
```
`SimpleGameViewModelTests.swift:21`:
```swift
        #expect(settings.gameTime == 30.0)
```
`SimpleSwiftDataTests.swift:45`:
```swift
        #expect(settings.gameTime == 30.0)
```
`DebugOverrideTests.swift:58`（前後を読み、`gameSettings.gameTime == 60` を 30 に。DEBUG override が永続値を変えないことの確認なので、期待は新デフォルト30）:
```swift
        #expect(vm.gameSettings.gameTime == 30)
```

> 注意: `SimpleSwiftDataTests.swift:35` の `gameScore.gameTimeLimit == 60.0` は明示的に `gameTimeLimit: 60.0` で作った GameScore の検証なので**変更しない**。

- [ ] **Step 2: テストが失敗することを確認（デフォルトはまだ60）**

Run:
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BubblePopGameTests/BasicPropertyTests 2>&1 \
  | grep -iE "Test case .* (passed|failed)"
```
Expected: `gameTime == 30.0` 系が failed = RED（実値は60）。

- [ ] **Step 3: デフォルト値を 30 に変更**

`GameSettings.swift:47`:
```swift
        self.gameTime = 30.0
```
`GameScore.swift:22`（引数デフォルト）:
```swift
    init(score: Int, bubblesPopped: Int, accuracy: Double, gameMode: String, playDate: Date, gameDuration: TimeInterval, gameTimeLimit: TimeInterval = 30.0) {
```
`GameViewModel.swift:18`（startGame で上書きされるが整合のため）:
```swift
    var timeRemaining: Double = 30.0
```

- [ ] **Step 4: テストが通ることを確認**

Run:
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BubblePopGameTests/BasicPropertyTests \
  -only-testing:BubblePopGameTests/SimpleGameViewModelTests \
  -only-testing:BubblePopGameTests/SimpleSwiftDataTests \
  -only-testing:BubblePopGameTests/DebugOverrideTests 2>&1 \
  | grep -iE "Test case .* (passed|failed)"
```
Expected: 全 passed = GREEN。

- [ ] **Step 5: コミット**

```bash
git add app/BubblePopGame/Models/GameSettings.swift app/BubblePopGame/Models/GameScore.swift app/BubblePopGame/ViewModels/GameViewModel.swift app/BubblePopGameTests/BasicPropertyTests.swift app/BubblePopGameTests/SimpleGameViewModelTests.swift app/BubblePopGameTests/SimpleSwiftDataTests.swift app/BubblePopGameTests/DebugOverrideTests.swift
git commit -m "feat: 制限時間デフォルトを60→30秒に変更 (#35)

新規インストールの初期値を30秒に。既存テストの期待値も更新。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task B2: 条件付き1回限り migration ロジック（TDD）

**Files:**
- Test: `app/BubblePopGameTests/GameTimeMigrationTests.swift`（新規）
- Create: `app/BubblePopGame/Services/GameTimeDefaultMigration.swift`（新規）

- [ ] **Step 1: 失敗するテストを書く**

`app/BubblePopGameTests/GameTimeMigrationTests.swift` を新規作成:

```swift
//
//  GameTimeMigrationTests.swift
//  BubblePopGameTests
//
//  #35: 制限時間デフォルト 60→30 の既存ユーザー向け 1 回限り migration
//

import Testing
import SwiftData
import Foundation
@testable import BubblePopGame

@MainActor
@Suite("制限時間デフォルト migration (#35)")
struct GameTimeMigrationTests {

    static func makeRepo() throws -> SettingsRepositoryImpl {
        let schema = Schema([GameScore.self, GameStatistics.self, GameSettings.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SettingsRepositoryImpl(modelContainer: container)
    }

    /// テスト隔離用 UserDefaults。一意 suite を作り、開始時に空にする。
    static func makeDefaults(_ name: String) -> UserDefaults {
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test("旧デフォルト60のユーザーは30へ移行する")
    func migratesSixtyToThirty() throws {
        let repo = try Self.makeRepo()
        let settings = GameSettings()
        settings.gameTime = 60.0
        try repo.saveSettings(settings)
        let defaults = Self.makeDefaults("test.migrate.sixty")

        GameTimeDefaultMigration.runIfNeeded(repository: repo, defaults: defaults)

        #expect(try repo.fetchSettings()?.gameTime == 30.0)
        #expect(defaults.bool(forKey: GameTimeDefaultMigration.sentinelKey) == true)
    }

    @Test("手動で90にしたユーザーは不変")
    func leavesNinetyUnchanged() throws {
        let repo = try Self.makeRepo()
        let settings = GameSettings()
        settings.gameTime = 90.0
        try repo.saveSettings(settings)
        let defaults = Self.makeDefaults("test.migrate.ninety")

        GameTimeDefaultMigration.runIfNeeded(repository: repo, defaults: defaults)

        #expect(try repo.fetchSettings()?.gameTime == 90.0)
    }

    @Test("センチネル済みなら何もしない")
    func skipsWhenAlreadyMigrated() throws {
        let repo = try Self.makeRepo()
        let settings = GameSettings()
        settings.gameTime = 60.0
        try repo.saveSettings(settings)
        let defaults = Self.makeDefaults("test.migrate.done")
        defaults.set(true, forKey: GameTimeDefaultMigration.sentinelKey)

        GameTimeDefaultMigration.runIfNeeded(repository: repo, defaults: defaults)

        #expect(try repo.fetchSettings()?.gameTime == 60.0)
    }

    @Test("永続row無しでもクラッシュせずセンチネルを立てる")
    func handlesNoPersistedRow() throws {
        let repo = try Self.makeRepo()
        let defaults = Self.makeDefaults("test.migrate.norow")

        GameTimeDefaultMigration.runIfNeeded(repository: repo, defaults: defaults)

        #expect(try repo.fetchSettings() == nil)
        #expect(defaults.bool(forKey: GameTimeDefaultMigration.sentinelKey) == true)
    }
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run:
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BubblePopGameTests/GameTimeMigrationTests 2>&1 \
  | grep -iE "error:|Test case .* (passed|failed)"
```
Expected: ビルド失敗（`cannot find 'GameTimeDefaultMigration' in scope`）= RED。

- [ ] **Step 3: migration ロジックを実装**

`app/BubblePopGame/Services/GameTimeDefaultMigration.swift` を新規作成:

```swift
//
//  GameTimeDefaultMigration.swift
//  BubblePopGame
//
//  #35: 制限時間デフォルトを 60→30 に変更した際の、既存ユーザー向け 1 回限り migration。
//  旧デフォルト(60.0)のまま保存しているユーザーのみ 30.0 へ寄せる。手動で他の値にした人は尊重。
//

import Foundation

@MainActor
enum GameTimeDefaultMigration {
    static let sentinelKey = "didMigrateDefaultGameTimeTo30"
    static let oldDefault: Double = 60.0
    static let newDefault: Double = 30.0

    /// 起動時に 1 回だけ呼ぶ。センチネル済み・row 無し・旧デフォルト以外なら値を変えない。
    /// row が無くてもセンチネルは立てる（毎起動の再 fetch を避ける）。
    static func runIfNeeded(repository: SettingsRepository, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: sentinelKey) else { return }
        defer { defaults.set(true, forKey: sentinelKey) }

        guard let settings = try? repository.fetchSettings() else { return }
        if settings.gameTime == oldDefault {
            settings.gameTime = newDefault
            try? repository.saveSettings(settings)
        }
    }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run:
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BubblePopGameTests/GameTimeMigrationTests 2>&1 \
  | grep -iE "Test case .* (passed|failed)"
```
Expected: 4 件 passed = GREEN。

- [ ] **Step 5: コミット**

```bash
git add app/BubblePopGame/Services/GameTimeDefaultMigration.swift app/BubblePopGameTests/GameTimeMigrationTests.swift
git commit -m "feat: 制限時間デフォルト migration ロジック (#35)

旧デフォルト60のユーザーのみ30へ寄せる1回限りmigration。UserDefaultsセンチネルで二重実行防止。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task B3: migration を起動時 `.task` に配線（手動確認）

**背景:** 全ユーザーが起動時に必ず通る単一チョークポイントで 1 回実行する。設定画面に紐付けると設定を開かないユーザーに発火しない。`BubblePopGameApp` の root view（`modelContainer` を持つ）の `.task` が最早かつ全経路を通る。

**Files:**
- Modify: `app/BubblePopGame/BubblePopGameApp.swift`

- [ ] **Step 1: `.task` で migration を呼ぶ**

`BubblePopGameApp.swift` の `body` を変更:

```swift
    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                .modelContainer(modelContainer)
                .task {
                    GameTimeDefaultMigration.runIfNeeded(
                        repository: SettingsRepositoryImpl(modelContainer: modelContainer)
                    )
                }
        }
    }
```

- [ ] **Step 2: ビルドが通ることを確認**

Run:
```bash
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`。

- [ ] **Step 3: 手動 walk-through（タイミング制約の確認）**

- 新規インストール相当（シミュレータのアプリ削除→再インストール）で起動し、設定画面の Time Limit が **30 sec** 初期表示であることを確認。
- migration がメニュー操作前（起動時 `.task`）に走ること、`GameViewModel` が古い 60 を保持して 1 セッション目だけ 60 で遊んでしまう経路がないか確認（必要なら startGame 時の再読込を検討）。
- 検証後は `xcrun simctl terminate` でアプリ停止（BGM が鳴り続けるため）。

- [ ] **Step 4: コミット**

```bash
git add app/BubblePopGame/BubblePopGameApp.swift
git commit -m "feat: 起動時に制限時間 migration を実行 (#35)

全ユーザーが通る root .task で1回だけ runIfNeeded を呼ぶ。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task B4: PR-B 全体テスト & PR 作成

- [ ] **Step 1: UnitTest 全体を実行**

Run:
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:BubblePopGameTests 2>&1 \
  | grep -iE "Suite.*(passed|failed)|Test case .* failed|TEST (SUCCEEDED|FAILED)"
```
Expected: failed 0、`** TEST SUCCEEDED **`。

- [ ] **Step 2: push & PR 作成（base=main）**

```bash
git push -u origin feature/issue-35-default-gametime
gh pr create --base main --head feature/issue-35-default-gametime \
  --title "feat: 制限時間デフォルトを30秒に+既存ユーザー移行 (#35)" \
  --body "$(cat <<'EOF'
## 概要
- 制限時間デフォルトを 60→30 秒に変更（`GameSettings`/`GameScore`/`timeRemaining`）。
- 旧デフォルト60のまま保存している既存ユーザーのみ30へ寄せる、UserDefaultsセンチネル付き1回限り migration を追加。手動で他の値にした人は尊重。
- 全ユーザーが通る起動時 root `.task` で `GameTimeDefaultMigration.runIfNeeded` を実行。

## Test plan
- [x] migration ユニットテスト（60→30 / 90→不変 / センチネル済→不変 / row無し→不変）
- [ ] 新規インストールで初期値30秒
- [ ] 旧60秒（未変更）ユーザーがアップデート起動後30秒へ
- [ ] 手動で90秒等にしたユーザーは保持
- [ ] 設定画面を開かずに起動しても migration 発火

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## マージ前手動確認チェックリスト（再掲）

### PR-A
- [ ] 背景が明るいお祝いトーン（赤くない）
- [ ] タイトル「おしまい！/All Done!」がポジティブな色
- [ ] 平均反応速度・シャボン玉密度が消えている
- [ ] プレイ時間が正しい秒数（0 sec にならない）
- [ ] ja / en 両方で確認（en に文言反映）
- [ ] GO直後 約0.7秒ボタン無効→フェードイン
- [ ] TestFlight 実機で #36 誤タップ解消を確認（クローズ条件）

### PR-B
- [ ] 新規インストールで初期値30秒
- [ ] 旧60秒（未変更）ユーザーがアップデート起動後30秒へ
- [ ] 手動で90秒等にしたユーザーは保持
- [ ] 設定画面を開かずに起動しても migration 発火
