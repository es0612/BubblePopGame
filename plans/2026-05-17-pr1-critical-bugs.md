# PR1: 致命的バグ修正 (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App Store審査前のクリティカルパスを進めるため、ゲームプレイを破壊する致命的バグ4件（画面サイズ初期化／時間表示不整合／ParticleEffectView状態更新／アクセシビリティ高コントラスト無効化）をTDDで修正する。

**Architecture:** 既存のMVVM + Service層に最小限の変更で対応。最大の変更は `ParticleEffectView`（struct）から `ParticleEffectViewModel`（@Observable class）への分離。これは値型がView外から渡されたとき状態が同期されない問題の根本対処。他3件はプロパティ初期値・パラメータ参照・実装関数差し替えのみ。

**Tech Stack:** Swift 5.9+ / SwiftUI / SwiftTesting / iOS 17.0+ / Xcode 16+

**親プラン参照:** `plans/github-issue-federated-music.md`（Issue #5 全体計画）

---

## File Structure

### 修正対象
- `app/BubblePopGame/ViewModels/GameViewModel.swift` — `screenBounds` 初期値、`startGame()` ガード、`setupParticleEffectView` シグネチャ
- `app/BubblePopGame/Views/Game/GameView.swift` — `@State` を ViewModel に置換、`ProgressView` の total 参照
- `app/BubblePopGame/Views/GameOver/GameOverView.swift` — `60.0` ハードコード3箇所を `gameSettings.gameTime` 参照に置換
- `app/BubblePopGame/Views/Effects/ParticleEffectView.swift` — `ParticleEffectViewModel` (@Observable class) を新規追加、`ParticleEffectView` (struct) は ViewModel を `@Bindable` で参照する形に
- `app/BubblePopGame/Services/EffectService.swift` — `particleEffectView: ParticleEffectView?` を `particleEffectViewModel: ParticleEffectViewModel?` に変更
- `app/BubblePopGame/Utils/AccessibilityUtils.swift` — `isHighContrastEnabled` を `UIAccessibility.isDarkerSystemColorsEnabled` 返却に修正

### 新規作成
- `app/BubblePopGameTests/CriticalBugFixTests.swift` — Task 1.1/1.2/1.4 のテスト集約（class化されるTask 1.3も含む）

### 触らないファイル（PR3以降で対応）
- `BubbleService.swift`（PR3で設定値反映）
- `EffectServiceImpl.particleEffectView as? EffectServiceImpl` ダウンキャスト箇所 → PR3で完全除去。本PRでは型を `ParticleEffectViewModel?` に置き換えるのみで、ダウンキャスト自体は残す（最小変更原則）

---

## Task 0: フィーチャーブランチ作成と既存テスト状態確認

**Files:** （変更なし、Git操作のみ）

- [ ] **Step 1: main の最新を取得**

```bash
git fetch origin
git status
```
Expected: `On branch main` / `nothing to commit, working tree clean`

- [ ] **Step 2: フィーチャーブランチを作成**

```bash
git checkout -b feature/issue-5-pr1-critical-bugs
```
Expected: `Switched to a new branch 'feature/issue-5-pr1-critical-bugs'`

- [ ] **Step 3: ベースラインのビルド確認**

```bash
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: ベースラインの全テストPASS確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tail -10
```
Expected: `** TEST SUCCEEDED **`

これがベースラインで、PR1 完了後も同じ結果＋新規テスト分が PASS する状態を目指す。

---

## Task 1: 画面サイズ初期化問題の修正 (1.1)

**Background:** `GameViewModel.swift:19` は `screenBounds` のデフォルト値を `CGRect(x: 0, y: 0, width: 393, height: 852)` というiPhone標準サイズでハードコードしている。これによりView表示前にバブル生成すると、実機のサイズと不一致になり、バブルが画面外に配置されるリスクがある。`.zero` をデフォルトにし、View側の `onAppear` で確実に更新される設計に変更する。

**Files:**
- Modify: `app/BubblePopGame/ViewModels/GameViewModel.swift:19, 116-119`
- Test: `app/BubblePopGameTests/CriticalBugFixTests.swift` （新規作成）

- [ ] **Step 1: 失敗するテストを書く**

`app/BubblePopGameTests/CriticalBugFixTests.swift` を新規作成:

```swift
//
//  CriticalBugFixTests.swift
//  BubblePopGameTests
//
//  PR1: Phase 1 致命的バグ修正の回帰テスト
//

import Testing
import SwiftData
import Foundation
import SwiftUI
@testable import BubblePopGame

@MainActor
struct CriticalBugFixTests {

    // MARK: - 1.1 画面サイズ初期化

    @Test("GameViewModel initialized with .zero screenBounds, not iPhone 14 default")
    func initialScreenBoundsIsZero() throws {
        let container = try ModelContainer(
            for: GameScore.self, GameStatistics.self, SettingsItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let scoreRepo = ScoreRepository(context: context)
        let settingsRepo = SettingsRepository(context: context)
        let statsRepo = StatisticsRepository(context: context)

        let vm = GameViewModel(
            bubbleService: BubbleServiceImpl(),
            audioService: AudioService(),
            effectService: EffectServiceImpl(),
            deviceService: DeviceService(),
            performanceService: PerformanceService(),
            scoreRepository: scoreRepo,
            settingsRepository: settingsRepo,
            statisticsRepository: statsRepo
        )

        #expect(vm.screenBounds == .zero,
                "初期化直後の screenBounds は .zero であるべき。View 側 onAppear で実サイズに更新される設計")
    }

    @Test("startGame with .zero screenBounds does not generate bubbles")
    func startGameGuardsAgainstZeroBounds() throws {
        let container = try ModelContainer(
            for: GameScore.self, GameStatistics.self, SettingsItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let vm = GameViewModel(
            bubbleService: BubbleServiceImpl(),
            audioService: AudioService(),
            effectService: EffectServiceImpl(),
            deviceService: DeviceService(),
            performanceService: PerformanceService(),
            scoreRepository: ScoreRepository(context: context),
            settingsRepository: SettingsRepository(context: context),
            statisticsRepository: StatisticsRepository(context: context)
        )
        // screenBounds が .zero のまま startGame を呼ぶ
        vm.startGame()

        #expect(vm.bubbles.isEmpty,
                "screenBounds が .zero のときは bubble を生成しない（画面外配置を防止）")
    }

    @Test("startGame after updateScreenBounds generates bubbles")
    func startGameGeneratesBubblesAfterScreenBoundsSet() throws {
        let container = try ModelContainer(
            for: GameScore.self, GameStatistics.self, SettingsItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let vm = GameViewModel(
            bubbleService: BubbleServiceImpl(),
            audioService: AudioService(),
            effectService: EffectServiceImpl(),
            deviceService: DeviceService(),
            performanceService: PerformanceService(),
            scoreRepository: ScoreRepository(context: context),
            settingsRepository: SettingsRepository(context: context),
            statisticsRepository: StatisticsRepository(context: context)
        )
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        vm.startGame()

        #expect(!vm.bubbles.isEmpty,
                "screenBounds 設定後 startGame でバブルが生成される")
    }
}
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:BubblePopGameTests/CriticalBugFixTests 2>&1 | tail -30
```
Expected: `initialScreenBoundsIsZero` が **FAIL**（現状 393x852 でデフォルト初期化されているため）

- [ ] **Step 3: GameViewModel.swift の修正**

`app/BubblePopGame/ViewModels/GameViewModel.swift:19` を変更:

```swift
// before
var screenBounds: CGRect = CGRect(x: 0, y: 0, width: 393, height: 852) // iPhone標準サイズ

// after
var screenBounds: CGRect = .zero
```

`app/BubblePopGame/ViewModels/GameViewModel.swift:116-119` の `startGame()` 冒頭にガードを追加:

`startGame()` メソッドの先頭（`gameState = .playing` の直前）に挿入:

```swift
func startGame() {
    // screenBounds 未設定（View マウント前）の場合はバブル生成を遅延
    // GameView.onAppear で updateScreenBounds → startGame の順に呼ばれる
    guard screenBounds != .zero else {
        return
    }

    gameState = .playing
    score = 0
    // ...以下既存のまま
```

- [ ] **Step 4: テスト3件がPASSすることを確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:BubblePopGameTests/CriticalBugFixTests 2>&1 | tail -10
```
Expected: 3件 PASS

- [ ] **Step 5: 全テストが影響を受けていないことを確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tail -10
```
Expected: `** TEST SUCCEEDED **`（既存テストもPASS）

⚠️ もし `SimpleGameViewModelTests` などが「screenBounds がデフォルトで非ゼロ」を前提にしていた場合は、テスト側を修正する（先に `vm.updateScreenBounds(...)` を呼ぶ）。テスト側修正もこのStepに含む。

- [ ] **Step 6: コミット**

```bash
git add app/BubblePopGame/ViewModels/GameViewModel.swift \
        app/BubblePopGameTests/CriticalBugFixTests.swift
git commit -m "$(cat <<'EOF'
fix(GameViewModel): screenBounds初期値を.zeroにし、startGameでガード

iPhone標準サイズのハードコード値（393x852）でデフォルト初期化されていたため、
実機サイズと不一致になりバブルが画面外配置されるリスクがあった。
.zeroをデフォルトにし、View側onAppearで実サイズ更新される設計を明確化。

- screenBounds初期値: CGRect(393x852) → .zero
- startGame()先頭で .zero ガード追加
- CriticalBugFixTests に回帰テスト3件追加

refs #5 Phase 1 (1.1)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: 時間表示不整合の修正 (1.2)

**Background:** `GameView.swift:134` の `ProgressView(value: viewModel.timeRemaining, total: 60.0)` は60秒固定。設定で gameTime=120s にしてもプログレスバーは60s基準で動くため、即座に満タンに見える。`GameOverView.swift:102-104` も同じく `60.0 - viewModel.timeRemaining` で経過時間を計算しているが、これは120sプレイ後 `-60.0` のような不正値になる。全てを `viewModel.gameSettings.gameTime` 参照に置き換える。

**Files:**
- Modify: `app/BubblePopGame/Views/Game/GameView.swift:134`
- Modify: `app/BubblePopGame/Views/GameOver/GameOverView.swift:102-104`
- Test: `app/BubblePopGameTests/CriticalBugFixTests.swift`（追記）

- [ ] **Step 1: テストを追記**

`CriticalBugFixTests.swift` の struct 内に追加:

```swift
    // MARK: - 1.2 時間表示

    @Test("gameTime=120 では timeRemaining 初期値も 120")
    func startGameInitializesTimeRemainingFromSettings() throws {
        let container = try ModelContainer(
            for: GameScore.self, GameStatistics.self, SettingsItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let settings = GameSettings()
        settings.gameTime = 120.0

        let vm = GameViewModel(
            bubbleService: BubbleServiceImpl(),
            audioService: AudioService(),
            effectService: EffectServiceImpl(),
            deviceService: DeviceService(),
            performanceService: PerformanceService(),
            scoreRepository: ScoreRepository(context: context),
            settingsRepository: SettingsRepository(context: context),
            statisticsRepository: StatisticsRepository(context: context),
            gameSettings: settings
        )
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        vm.startGame()

        #expect(vm.timeRemaining == 120.0,
                "startGame後の timeRemaining は gameSettings.gameTime を反映する")
        #expect(vm.gameSettings.gameTime == 120.0)
    }

    @Test("gameTime=30 でも正しく初期化される")
    func startGameWithShortTime() throws {
        let container = try ModelContainer(
            for: GameScore.self, GameStatistics.self, SettingsItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let settings = GameSettings()
        settings.gameTime = 30.0

        let vm = GameViewModel(
            bubbleService: BubbleServiceImpl(),
            audioService: AudioService(),
            effectService: EffectServiceImpl(),
            deviceService: DeviceService(),
            performanceService: PerformanceService(),
            scoreRepository: ScoreRepository(context: context),
            settingsRepository: SettingsRepository(context: context),
            statisticsRepository: StatisticsRepository(context: context),
            gameSettings: settings
        )
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        vm.startGame()

        #expect(vm.timeRemaining == 30.0)
    }
```

- [ ] **Step 2: テストを実行して既存ロジック確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:BubblePopGameTests/CriticalBugFixTests/startGameInitializesTimeRemainingFromSettings 2>&1 | tail -10
```
Expected: PASS（このテストは GameView/GameOverView ではなく ViewModel 内のロジック検証なので、Task 1 修正後にすでにPASSする見込み。ViewModelは `timeRemaining = gameSettings.gameTime` の実装が既にある）

Viewは目視検証になるため、Step 3 以降はView修正を主体とする。

- [ ] **Step 3: GameView.swift:134 の修正**

`app/BubblePopGame/Views/Game/GameView.swift:134`:

```swift
// before
ProgressView(value: viewModel.timeRemaining, total: 60.0)

// after
ProgressView(value: viewModel.timeRemaining, total: viewModel.gameSettings.gameTime)
```

- [ ] **Step 4: GameOverView.swift:102-104 の修正**

3箇所すべての `60.0 - viewModel.timeRemaining` を `viewModel.gameSettings.gameTime - viewModel.timeRemaining` に変更。`max(1, 60.0 - ...)` も同様に置換。

`app/BubblePopGame/Views/GameOver/GameOverView.swift:102-104` を以下に書き換える:

```swift
StatRow(label: NSLocalizedString("gameover_play_time", comment: "Play time label"),
        value: String(format: NSLocalizedString("seconds_format", comment: "Seconds format with decimal"),
                      viewModel.gameSettings.gameTime - viewModel.timeRemaining))
StatRow(label: NSLocalizedString("gameover_avg_reaction", comment: "Average reaction time label"),
        value: viewModel.bubblesPopped > 0
            ? String(format: "%.2f" + NSLocalizedString("game_seconds_unit", comment: "Seconds unit") + "/" + NSLocalizedString("game_pieces_unit", comment: "Pieces unit"),
                     (viewModel.gameSettings.gameTime - viewModel.timeRemaining) / Double(viewModel.bubblesPopped))
            : "N/A")
StatRow(label: NSLocalizedString("gameover_bubble_density", comment: "Bubble density label"),
        value: String(format: "%.1f" + NSLocalizedString("game_pieces_unit", comment: "Pieces unit") + "/" + NSLocalizedString("game_seconds_unit", comment: "Seconds unit"),
                      Double(viewModel.bubblesPopped) / max(1, viewModel.gameSettings.gameTime - viewModel.timeRemaining)))
```

- [ ] **Step 5: ビルドと全テストPASSを確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tail -10
```
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: シミュレータで目視確認**

`Skill: ios-simulator-app-verification` を使用。手順:
1. 設定で gameTime=120s に変更
2. ゲーム開始
3. プログレスバーが 120s 起点で減ることを確認（スクショ記録）
4. ゲーム終了後 GameOver 画面で「プレイ時間」が正しい経過秒数を示すことを確認

- [ ] **Step 7: コミット**

```bash
git add app/BubblePopGame/Views/Game/GameView.swift \
        app/BubblePopGame/Views/GameOver/GameOverView.swift \
        app/BubblePopGameTests/CriticalBugFixTests.swift
git commit -m "$(cat <<'EOF'
fix(GameView/GameOverView): 60秒ハードコードを gameSettings.gameTime に置換

ProgressView の total と GameOver の経過時間計算が 60.0 リテラル固定で、
gameTime=120s 設定時にバーが満タン固定、経過時間が負値になっていた。

- GameView.swift:134 ProgressView total を gameSettings.gameTime 参照に
- GameOverView.swift:102-104 経過時間/平均反応時間/バブル密度の3箇所を
  gameSettings.gameTime - timeRemaining に置換

refs #5 Phase 1 (1.2)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: ParticleEffectView 状態更新問題の修正 (1.3)

**Background:** 現在の `ParticleEffectView` は `struct` で `@State private var effects: [ParticleEffectData]` を持つ。`GameView` で `@State private var particleEffectView = ParticleEffectView()` してインスタンスを生成し、`onAppear` で `viewModel.setupParticleEffectView(particleEffectView)` で渡している。しかしSwiftUI の struct は値型で、`EffectServiceImpl` が保持する `particleEffectView` プロパティは値コピーとなる。`EffectServiceImpl.createPopEffect` が `particleEffectView?.addEffect(...)` を呼んでも、その変更は GameView 側で表示している `particleEffectView` には反映されない。これがパーティクル演出が見えない真の原因。

**解決策:** `@Observable class ParticleEffectViewModel` を分離。状態（effects配列）は ViewModel に持たせ、`ParticleEffectView` (struct) は `let viewModel: ParticleEffectViewModel` を参照する。Service側も `ParticleEffectViewModel?` を保持。GameView は `@State private var particleEffectViewModel = ParticleEffectViewModel()` で参照を共有。

**Files:**
- Modify: `app/BubblePopGame/Views/Effects/ParticleEffectView.swift`
- Modify: `app/BubblePopGame/Services/EffectService.swift:27, 46`
- Modify: `app/BubblePopGame/ViewModels/GameViewModel.swift:110-114`
- Modify: `app/BubblePopGame/Views/Game/GameView.swift:12, 156`

- [ ] **Step 1: テストを追記**

`CriticalBugFixTests.swift` に追加:

```swift
    // MARK: - 1.3 ParticleEffectView

    @Test("ParticleEffectViewModel が参照型で、addEffect が状態を共有する")
    func particleEffectViewModelIsReferenceType() {
        let vm = ParticleEffectViewModel()
        let shared = vm

        #expect(vm.effects.isEmpty)
        shared.addEffect(at: CGPoint(x: 100, y: 100), color: .red)

        #expect(vm.effects.count == 1, "参照型のためsharedとvmは同じインスタンス")
    }

    @Test("EffectServiceImpl.createPopEffect は ViewModel に effect を追加する")
    func effectServiceTriggersViewModelEffect() {
        let service = EffectServiceImpl()
        let viewModel = ParticleEffectViewModel()
        service.particleEffectViewModel = viewModel

        #expect(viewModel.effects.isEmpty)
        service.createPopEffect(at: CGPoint(x: 50, y: 50), color: .blue)

        #expect(viewModel.effects.count == 1)
    }
```

- [ ] **Step 2: テストを実行して失敗を確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:BubblePopGameTests/CriticalBugFixTests/particleEffectViewModelIsReferenceType \
  -only-testing:BubblePopGameTests/CriticalBugFixTests/effectServiceTriggersViewModelEffect 2>&1 | tail -30
```
Expected: コンパイルエラー `Cannot find 'ParticleEffectViewModel' in scope` または `Value of type 'EffectServiceImpl' has no member 'particleEffectViewModel'`

- [ ] **Step 3: ParticleEffectView.swift を全面書き換え**

`app/BubblePopGame/Views/Effects/ParticleEffectView.swift` を以下で完全に置き換え:

```swift
//
//  ParticleEffectView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

@Observable
@MainActor
class ParticleEffectViewModel {
    var effects: [ParticleEffectData] = []

    func addEffect(at position: CGPoint, color: Color) {
        let effect = ParticleEffectData(position: position, color: color)
        effects.append(effect)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.effects.removeAll { $0.id == effect.id }
        }
    }
}

struct ParticleEffectView: View {
    let viewModel: ParticleEffectViewModel

    var body: some View {
        ZStack {
            ForEach(viewModel.effects) { effect in
                ParticleEffect(position: effect.position, color: effect.color)
            }
        }
    }
}
```

⚠️ **互換性メモ:** `ParticleEffectData` の定義は別ファイルにあると想定。もし `ParticleEffectView.swift` 内に定義があった場合はそのまま残す。実装エージェントは Read で再確認すること。

- [ ] **Step 4: EffectService.swift の修正**

`app/BubblePopGame/Services/EffectService.swift:27` の型を変更:

```swift
// before
var particleEffectView: ParticleEffectView?

// after
var particleEffectViewModel: ParticleEffectViewModel?
```

`app/BubblePopGame/Services/EffectService.swift:46`:

```swift
// before
particleEffectView?.addEffect(at: position, color: color)

// after
particleEffectViewModel?.addEffect(at: position, color: color)
```

- [ ] **Step 5: GameViewModel.swift の修正**

`app/BubblePopGame/ViewModels/GameViewModel.swift:110-114` を変更:

```swift
// before
func setupParticleEffectView(_ particleEffectView: ParticleEffectView) {
    if let effectServiceImpl = effectService as? EffectServiceImpl {
        effectServiceImpl.particleEffectView = particleEffectView
    }
}

// after
func setupParticleEffectViewModel(_ viewModel: ParticleEffectViewModel) {
    if let effectServiceImpl = effectService as? EffectServiceImpl {
        effectServiceImpl.particleEffectViewModel = viewModel
    }
}
```

⚠️ ダウンキャスト `effectService as? EffectServiceImpl` は PR3 で除去予定。本PRでは残す。

- [ ] **Step 6: GameView.swift の修正**

`app/BubblePopGame/Views/Game/GameView.swift:12` を変更:

```swift
// before
@State private var particleEffectView = ParticleEffectView()

// after
@State private var particleEffectViewModel = ParticleEffectViewModel()
```

`app/BubblePopGame/Views/Game/GameView.swift:28` の表示を変更:

```swift
// before
particleEffectView

// after
ParticleEffectView(viewModel: particleEffectViewModel)
```

`app/BubblePopGame/Views/Game/GameView.swift:156` の onAppear を変更:

```swift
// before
viewModel.setupParticleEffectView(particleEffectView)

// after
viewModel.setupParticleEffectViewModel(particleEffectViewModel)
```

- [ ] **Step 7: ビルドを通す**

```bash
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`

エラーが出る場合は、他に `ParticleEffectView()` をinstance化している箇所がないか grep で確認:

```bash
grep -rn "ParticleEffectView()" app/BubblePopGame --include="*.swift"
grep -rn "setupParticleEffectView\b" app/BubblePopGame --include="*.swift"
```

- [ ] **Step 8: テスト2件がPASSすることを確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:BubblePopGameTests/CriticalBugFixTests 2>&1 | tail -10
```
Expected: 全テストPASS

- [ ] **Step 9: 全テストが影響を受けていないことを確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tail -10
```
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 10: シミュレータで目視確認**

`Skill: ios-simulator-app-verification` を使用。手順:
1. ゲーム開始
2. バブルを何回かタップ
3. パーティクル演出（小さな円が広がる）が表示されることを確認
4. 1.5秒後に消えることを確認
5. スクショを撮影

- [ ] **Step 11: コミット**

```bash
git add app/BubblePopGame/Views/Effects/ParticleEffectView.swift \
        app/BubblePopGame/Services/EffectService.swift \
        app/BubblePopGame/ViewModels/GameViewModel.swift \
        app/BubblePopGame/Views/Game/GameView.swift \
        app/BubblePopGameTests/CriticalBugFixTests.swift
git commit -m "$(cat <<'EOF'
fix(ParticleEffect): struct→@Observable class分離で状態更新を反映

ParticleEffectView が struct のため、Service 側に渡した値コピーへの
addEffect は GameView 表示インスタンスに反映されなかった。
@Observable class ParticleEffectViewModel に状態を分離し、参照型で共有。

- ParticleEffectViewModel (@Observable class) 新設
- ParticleEffectView は viewModel を参照する struct に変更
- EffectServiceImpl.particleEffectView → particleEffectViewModel
- GameViewModel.setupParticleEffectView → setupParticleEffectViewModel
- GameView の @State も ViewModel に変更
- as? EffectServiceImpl ダウンキャストは PR3 で除去予定

refs #5 Phase 1 (1.3)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: アクセシビリティ高コントラスト有効化 (1.4)

**Background:** `AccessibilityUtils.swift:131` の `isHighContrastEnabled` が常に `false` を返す簡略化実装になっている。視覚支援を必要とするユーザに高コントラスト色が適用されない。`UIAccessibility.isDarkerSystemColorsEnabled` を返すように修正。

**Files:**
- Modify: `app/BubblePopGame/Utils/AccessibilityUtils.swift:130-132`
- Test: `app/BubblePopGameTests/CriticalBugFixTests.swift`（追記）

- [ ] **Step 1: テストを追記**

`CriticalBugFixTests.swift` に追加:

```swift
    // MARK: - 1.4 高コントラスト

    @Test("Color.accessible(highContrast: true) は高コントラスト色を返す")
    func accessibleColorReturnsHighContrast() {
        let original = Color.red
        let highContrast = original.accessible(highContrast: true)
        let normal = original.accessible(highContrast: false)

        #expect(highContrast != normal,
                "高コントラストフラグで色が変化する")
    }

    @Test("AccessibilityUtils.accessibleColor 高コントラストRed は Pure red")
    func highContrastRedIsPureRed() {
        let result = AccessibilityUtils.accessibleColor(for: .red, isHighContrast: true)
        // Pure red の RGB を確認するため UIColor 経由で比較
        let uiColor = UIColor(result)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(r == 1.0 && g == 0.0 && b == 0.0,
                "高コントラスト赤は Pure red (1.0, 0.0, 0.0)")
    }
```

⚠️ `isHighContrastEnabled` 自体は SwiftUI Environment 経由なのでテストが難しい。代わりに「色変換ロジック」と「Environment が `UIAccessibility.isDarkerSystemColorsEnabled` を返すという宣言」を担保する単体テストとする。

- [ ] **Step 2: AccessibilityUtils.swift:130-132 の修正**

`app/BubblePopGame/Utils/AccessibilityUtils.swift:127-137` の `EnvironmentValues` extension を変更:

```swift
// before
extension EnvironmentValues {
    var isHighContrastEnabled: Bool {
        false // 簡略化：常にfalseとする（実際のアプリでは適切に実装）
    }

    var isReduceMotionEnabled: Bool {
        self.accessibilityReduceMotion
    }
}

// after
extension EnvironmentValues {
    var isHighContrastEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    var isReduceMotionEnabled: Bool {
        self.accessibilityReduceMotion
    }
}
```

⚠️ Swift で `UIAccessibility` を使うには `import UIKit` が必要。ファイル先頭に `import UIKit` がなければ追加（既存 `import SwiftUI` の下）。

- [ ] **Step 3: テスト2件がPASSすることを確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:BubblePopGameTests/CriticalBugFixTests/accessibleColorReturnsHighContrast \
  -only-testing:BubblePopGameTests/CriticalBugFixTests/highContrastRedIsPureRed 2>&1 | tail -10
```
Expected: 2件 PASS

- [ ] **Step 4: 全テストPASS確認**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tail -10
```
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: シミュレータで目視確認（手動・任意）**

シミュレータ → 設定 → アクセシビリティ → 表示とテキストサイズ → コントラストを上げる → ON
→ アプリ再起動 → メニュー画面の色が高コントラストになることを確認（赤・青・緑が純色に近くなる）

- [ ] **Step 6: コミット**

```bash
git add app/BubblePopGame/Utils/AccessibilityUtils.swift \
        app/BubblePopGameTests/CriticalBugFixTests.swift
git commit -m "$(cat <<'EOF'
fix(AccessibilityUtils): 高コントラスト判定を有効化

isHighContrastEnabled が常に false 返却の簡略実装だったため、
視覚支援を必要とするユーザに高コントラスト色が適用されなかった。
UIAccessibility.isDarkerSystemColorsEnabled を返すよう修正。

- import UIKit 追加
- 色変換ロジックの回帰テスト追加

refs #5 Phase 1 (1.4)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: 統合検証

**Files:** （変更なし、検証のみ）

- [ ] **Step 1: クリーンビルド**

```bash
xcodebuild clean -project app/BubblePopGame.xcodeproj -scheme BubblePopGame
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tail -10
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Release configuration ビルド**

```bash
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -configuration Release \
  -destination 'generic/platform=iOS' 2>&1 | tail -10
```
Expected: `** BUILD SUCCEEDED **`、警告は無視可（PR4でprint削除予定）

- [ ] **Step 3: 全テストPASS**

```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tail -30
```
Expected: `** TEST SUCCEEDED **`、CriticalBugFixTests 全件PASS

- [ ] **Step 4: シミュレータでフル walk-through**

`Skill: ios-simulator-app-verification` で以下を実行・スクショ:
1. 初回起動 → LaunchScreen → メニュー
2. 設定 → gameTime=30s → 戻る
3. 普通モード開始 → バブルタップ × 数回 → パーティクル演出確認 → ゲームオーバー
4. GameOver 画面で「プレイ時間」が 30s 程度の経過時間を表示することを確認
5. 設定 → gameTime=120s → 戻る → 開始 → ProgressView が 120 起点で減ることを確認
6. iPad シミュレータでも起動 → バブルが画面外に出ないことを確認

- [ ] **Step 5: ベースライン比較**

```bash
git diff main --stat
```
変更行数が想定範囲内（150-250行程度）であることを確認。

---

## Task 6: PR 作成

**Files:** （変更なし、Git操作のみ）

- [ ] **Step 1: ブランチを origin に push**

```bash
git push -u origin feature/issue-5-pr1-critical-bugs
```

- [ ] **Step 2: gh pr create で PR 作成**

```bash
gh pr create --title "fix: Phase 1 致命的バグ4件修正 (Issue #5 PR1)" --body "$(cat <<'EOF'
## Summary
Issue #5「審査出す準備＋ローカライゼーション」のクリティカルパス先頭。
release-action-plan.md Phase 1 の致命的バグ4件をTDDで修正。

- 1.1 GameViewModel.screenBounds 初期値ハードコード → .zero に変更＋startGameでガード
- 1.2 GameView ProgressView と GameOverView の 60秒固定 → gameSettings.gameTime 参照に
- 1.3 ParticleEffectView struct→@Observable class分離（パーティクル演出が見えない真の原因を解決）
- 1.4 AccessibilityUtils.isHighContrastEnabled の簡略 false 返却を UIAccessibility 実値に

## Test plan
- [ ] xcodebuild test 全PASS（CriticalBugFixTests を含む）
- [ ] gameTime=30/60/120s でタイマーバーとGameOver経過時間が正しく動作（目視）
- [ ] バブルタップでパーティクル演出が表示・1.5秒で消える（目視）
- [ ] 高コントラスト設定ONで色が純色に近づく（任意）
- [ ] iPhone・iPad両方のシミュレータで動作（バブル画面外配置なし）

refs #5

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 3: PR URLをユーザーに報告**

`gh pr view --json url -q .url` の出力を伝える

---

## 自己レビュー（実装エージェント向けチェックリスト）

実装完了後、以下を確認:

1. **Spec coverage**: 親プラン PR1 の4つのバグが全て対応されているか
2. **Placeholder scan**: "TODO", "後で" などのPlaceholderが残っていないか
3. **Type consistency**: `setupParticleEffectView` → `setupParticleEffectViewModel` のリネームが全箇所適用されているか:
   ```bash
   grep -rn "setupParticleEffectView\b" app/BubblePopGame --include="*.swift"
   grep -rn "particleEffectView\b" app/BubblePopGame --include="*.swift" | grep -v "Tests.swift"
   ```
   後者の出力は `particleEffectViewModel` だけになるべき（テスト除く）

4. **ダウンキャスト残存**: `as? EffectServiceImpl` は **意図的に残す**（PR3で除去予定）。grep で残存が1箇所のみ（GameViewModel.setupParticleEffectViewModel内）を確認

---

## 参考: 関連スキル

| スキル | 用途 |
|--------|------|
| `superpowers:test-driven-development` | Task 1〜4 のテスト → 実装の流れ |
| `superpowers:verification-before-completion` | Task 5 統合検証 |
| `superpowers:finishing-a-development-branch` | Task 6 PR作成 |
| `ios-simulator-app-verification` | Task 2.6, 3.10, 5.4 シミュレータ動作確認 |

---

*作成日: 2026-05-17*
*対象Issue: [#5 審査出す準備＋ローカライゼーション](https://github.com/es0612/BubblePopGame/issues/5) — PR1 致命バグ修正*
*親プラン: `plans/github-issue-federated-music.md`*
