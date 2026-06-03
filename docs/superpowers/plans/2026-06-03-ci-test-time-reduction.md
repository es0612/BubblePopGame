# CI テスト時間短縮 実装計画（Issue #44）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (推奨, このタスクは xcodebuild の実測フィードバックで反復するため inline 実行が適切) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 毎回の CI を UnitTest のみ（ビルド+Unit ≈ 100s）に絞り、UITest を別枠化＋無駄削減して、CI テスト時間を約 86% 削減する。

**Architecture:** 共有スキーム + 2 つのテストプラン（`CI`=Unit のみ・デフォルト / `Full`=Unit+UI）をリポに新設し、テストプラン未指定の実行が Unit-only になるようにする。加えて UITest の per-config 反復を無効化し、ハード sleep を要素待機へ置換する。

**Tech Stack:** Xcode 16 / xcodebuild / `.xctestplan`(JSON) / `.xcscheme`(XML) / XCTest(XCUITest)

参考: ターゲット GUID（`app/BubblePopGame.xcodeproj/project.pbxproj` より）
- app `BubblePopGame`: `D5DF7FBE2E28B0A4002424F1`
- `BubblePopGameTests`: `D5DF7FCD2E28B0A6002424F1`
- `BubblePopGameUITests`: `D5DF7FD72E28B0A6002424F1`

ベースライン実測（修正前, iPhone 17 Pro, ローカル）: ビルド 16s / Unit 85s / UITest 617s。

---

## Task 1: テストプラン 2 枚を作成

**Files:**
- Create: `app/CI.xctestplan`
- Create: `app/Full.xctestplan`

> 配置場所はパス解決を単純にするため `.xcodeproj` と同じ `app/` 直下（`container:` の `../` を避ける）。spec の `app/TestPlans/` から変更。

- [ ] **Step 1: `app/CI.xctestplan` を作成（Unit のみ・並列）**

```json
{
  "configurations" : [
    {
      "id" : "C1000000-0000-4000-8000-000000000001",
      "name" : "Configuration 1",
      "options" : {

      }
    }
  ],
  "defaultOptions" : {

  },
  "testTargets" : [
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:BubblePopGame.xcodeproj",
        "identifier" : "D5DF7FCD2E28B0A6002424F1",
        "name" : "BubblePopGameTests"
      }
    }
  ],
  "version" : 1
}
```

- [ ] **Step 2: `app/Full.xctestplan` を作成（Unit + UI）**

```json
{
  "configurations" : [
    {
      "id" : "F2000000-0000-4000-8000-000000000002",
      "name" : "Configuration 1",
      "options" : {

      }
    }
  ],
  "defaultOptions" : {

  },
  "testTargets" : [
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:BubblePopGame.xcodeproj",
        "identifier" : "D5DF7FCD2E28B0A6002424F1",
        "name" : "BubblePopGameTests"
      }
    },
    {
      "parallelizable" : false,
      "target" : {
        "containerPath" : "container:BubblePopGame.xcodeproj",
        "identifier" : "D5DF7FD72E28B0A6002424F1",
        "name" : "BubblePopGameUITests"
      }
    }
  ],
  "version" : 1
}
```

- [ ] **Step 3: JSON が妥当か検証**

Run: `python3 -m json.tool app/CI.xctestplan >/dev/null && python3 -m json.tool app/Full.xctestplan >/dev/null && echo OK`
Expected: `OK`（パースエラーなし）

- [ ] **Step 4: コミット**

```bash
git add app/CI.xctestplan app/Full.xctestplan
git commit -m "feat: CI / Full テストプランを追加 (#44)"
```

---

## Task 2: 共有スキームを新設しテストプランを参照

**Files:**
- Create: `app/BubblePopGame.xcodeproj/xcshareddata/xcschemes/BubblePopGame.xcscheme`

現状 `.xcscheme` は存在せず "BubblePopGame" スキームは自動生成。手書きで共有スキームを作り、TestAction に `CI`(default) と `Full` を登録する。

- [ ] **Step 1: 修正前の状態を確認（RED）**

Run: `xcodebuild -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -showTestPlans 2>&1 | tail -5`
Expected: テストプランが無い旨のメッセージ（例: `does not use test plans` など）。`CI` / `Full` は**列挙されない**。

- [ ] **Step 2: 共有スキームを作成**

`app/BubblePopGame.xcodeproj/xcshareddata/xcschemes/BubblePopGame.xcscheme`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1640"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "D5DF7FBE2E28B0A4002424F1"
               BuildableName = "BubblePopGame.app"
               BlueprintName = "BubblePopGame"
               ReferencedContainer = "container:BubblePopGame.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <TestPlans>
         <TestPlanReference
            reference = "container:CI.xctestplan"
            default = "YES">
         </TestPlanReference>
         <TestPlanReference
            reference = "container:Full.xctestplan">
         </TestPlanReference>
      </TestPlans>
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "D5DF7FBE2E28B0A4002424F1"
            BuildableName = "BubblePopGame.app"
            BlueprintName = "BubblePopGame"
            ReferencedContainer = "container:BubblePopGame.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "D5DF7FBE2E28B0A4002424F1"
            BuildableName = "BubblePopGame.app"
            BlueprintName = "BubblePopGame"
            ReferencedContainer = "container:BubblePopGame.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
```

- [ ] **Step 3: テストプランが認識されるか検証（GREEN）**

Run: `xcodebuild -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -showTestPlans 2>&1 | tail -8`
Expected: `CI`（デフォルト）と `Full` の 2 つが列挙される。
（フォーマット不正で失敗した場合は、container パス・GUID・XML 構造を見直し、`-showTestPlans` が両プランを返すまで修正する。）

- [ ] **Step 4: コミット**

```bash
git add app/BubblePopGame.xcodeproj/xcshareddata/xcschemes/BubblePopGame.xcscheme
git commit -m "feat: 共有スキームを追加しテストプランを登録 (#44)"
```

---

## Task 3: CI=Unit のみ / Full=Unit+UI を検証し、新タイムを記録

**Files:** （変更なし。検証のみ）

- [ ] **Step 1: クリーンビルド（計測の前提を揃える）**

Run:
```bash
rm -rf build/DerivedData
xcodebuild build-for-testing -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/DerivedData >/tmp/t3-build.log 2>&1
echo "exit=$?"; tail -1 /tmp/t3-build.log
```
Expected: `** TEST BUILD SUCCEEDED **`

- [ ] **Step 2: CI プランは Unit のみ実行されることを検証 + 計測**

Run:
```bash
SECONDS=0
xcodebuild test-without-building -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/DerivedData \
  -testPlan CI >/tmp/t3-ci.log 2>&1
echo "exit=$? CI elapsed=${SECONDS}s"
grep -ciE "BubblePopGameUITests" /tmp/t3-ci.log
```
Expected: `exit=0`、UITest のヒット数 `0`（UITest が一切走らない）。elapsed は概ね 85s 前後。

- [ ] **Step 3: Full プランは Unit+UI 実行されることを検証**

Run:
```bash
xcodebuild test-without-building -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/DerivedData \
  -testPlan Full >/tmp/t3-full.log 2>&1
echo "exit=$?"
grep -cE "Test case 'BubblePopGameUITests" /tmp/t3-full.log
```
Expected: `exit=0`、UITest のテストケースが 1 件以上実行される。

- [ ] **Step 4: 結果を spec の §5 に追記（before/after の実測）してコミット**

```bash
git add docs/superpowers/specs/2026-06-03-ci-test-time-reduction-design.md
git commit -m "docs: CI/Full テストプランの実測結果を記録 (#44)"
```

---

## Task 4: UITest の per-config 反復を無効化

**Files:**
- Modify: `app/BubblePopGameUITests/BubblePopGameUITestsLaunchTests.swift:12-14`

`runsForEachTargetApplicationUIConfiguration` が `true` のため `testMemoryUsageAfterLaunch` / `testOrientationHandling` が UI 構成ごとに 6 回以上反復実行されている。`false` にして反復を解消する。

- [ ] **Step 1: override を false に変更**

`BubblePopGameUITestsLaunchTests.swift` の以下を変更:

```swift
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }
```

- [ ] **Step 2: Full プランで反復解消＋時間短縮を検証**

Run:
```bash
SECONDS=0
xcodebuild test-without-building -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/DerivedData \
  -testPlan Full >/tmp/t4-full.log 2>&1
echo "exit=$? Full elapsed=${SECONDS}s"
grep -cE "Test case 'BubblePopGameUITestsLaunchTests.testOrientationHandling" /tmp/t4-full.log
```
Expected: `exit=0`、`testOrientationHandling` の実行回数が 1（修正前は 6+）。elapsed が Task 3 の Full より大幅に短い。

- [ ] **Step 3: コミット**

```bash
git add app/BubblePopGameUITests/BubblePopGameUITestsLaunchTests.swift
git commit -m "perf: UITest の per-config 反復を無効化 (#44)"
```

---

## Task 5: ハード sleep を要素待機へ置換／削除

**Files:**
- Modify: `app/BubblePopGameUITests/BubblePopGameUITests.swift`
- Modify: `app/BubblePopGameUITests/BubblePopGameUITestsLaunchTests.swift`

方針: **直後に `waitForExistence` が続く sleep は冗長なので削除**。**末尾でメニュー→ゲーム遷移を待つだけの sleep は `gameStartButton.waitForNonExistence(timeout: 5.0)`（=メニューを抜けたこと）へ置換**。**`.exists` を sleep で待っている箇所は `.waitForExistence(timeout:)` に変えて sleep を削除**。`waitForNonExistence(timeout:)` は Xcode 16 で利用可。

### `BubblePopGameUITests.swift`

- [ ] **Step 1: testGameStart の sleep を整理**

L50 の `sleep(2)`（`// 起動を待機`）を削除。直後の `tutorialSkipButton.waitForExistence(timeout: 5.0)` が起動を待つ。
L56 の `sleep(1)` を削除。直後に `gameStartButton.waitForExistence(timeout: 10.0)` がある。
L65 の `sleep(3)`（`// ゲーム画面への遷移を待機`）を次へ置換:

```swift
        // ゲーム画面への遷移を待機（メニューのスタートボタンが消えることで判定）
        _ = gameStartButton.waitForNonExistence(timeout: 5.0)
```

- [ ] **Step 2: testGamePauseAndResume の sleep を整理**

L76 `sleep(2)` 削除（直後に skip の waitForExistence）。
L82 `sleep(1)` 削除（直後に gameStartButton.waitForExistence）。
L91 `sleep(3)` 削除（直後に `pauseButton.waitForExistence(timeout: 5.0)` がある）。
L99-100 の `sleep(1)` + `.exists` を待機に変更:

```swift
            // ポーズ画面の表示を確認
            let pauseExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'ポーズ' OR label CONTAINS 'Pause' OR label CONTAINS '一時停止'")).firstMatch.waitForExistence(timeout: 3.0)
```

- [ ] **Step 3: testBasicGameInteraction の sleep を整理**

L189 `sleep(2)` を遷移待ちへ置換:

```swift
        // ゲーム画面が表示されるまで待機（メニューを抜けたことで判定）
        _ = gameStartButton.waitForNonExistence(timeout: 5.0)
```

L197 `sleep(1)` + L200 の `.exists` を待機へ変更:

```swift
            // 少し待つ（スコア表示の出現を待機）
            let scoreExists = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0' OR label CONTAINS '1' OR label CONTAINS '2'")).firstMatch.waitForExistence(timeout: 2.0)
```

（上記変更に伴い L197 の `sleep(1)` 行は削除）

- [ ] **Step 4: testAccessibilityLabels の sleep を整理**

L212 `sleep(2)` 削除（直後に skip の waitForExistence）。
L218 `sleep(1)` 削除（直後に L223 で gameStartButton.waitForExistence）。

### `BubblePopGameUITestsLaunchTests.swift`

- [ ] **Step 5: LaunchTests の sleep を整理**

L60 `sleep(2)`（`// アプリが安定するまで待機`）削除。直前に `menuTitle.waitForExistence(timeout: 10.0)` があり、直後の `mainMenuGameStart` ボタンは存在するはず。
L84 `sleep(1)`（回転アニメ待ち）削除。直後の `menuTitle.exists || menuTitle.waitForExistence(timeout: 3.0)` が待つ。
L98 `sleep(2)` 削除（直後に skip の waitForExistence）。
L104 `sleep(1)` 削除（直後に L109 で gameStartButton.waitForExistence）。
L113 `sleep(3)` を遷移待ちへ置換:

```swift
        // ゲーム画面への遷移を待機（メニューを抜けたことで判定）
        _ = gameStartButton.waitForNonExistence(timeout: 5.0)
```

- [ ] **Step 6: 残存 sleep がないことを確認**

Run: `grep -rnE "(^| )sleep\(" app/BubblePopGameUITests --include='*.swift'`
Expected: 出力なし（全 sleep を削除/置換済み）。

- [ ] **Step 7: Full プランが PASS し、さらに高速化したことを検証**

Run:
```bash
SECONDS=0
xcodebuild test-without-building -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/DerivedData \
  -testPlan Full 2>&1 | grep -iE "Test case .* (passed|failed)|TEST (SUCCEEDED|FAILED)" | tail -20
echo "Full elapsed=${SECONDS}s"
```
Expected: `** TEST SUCCEEDED **`、failed のテストケースがない、elapsed が Task 4 よりさらに短い。
（flaky で落ちる UITest があれば、その箇所の待機タイムアウトを微調整して PASS させる。）

- [ ] **Step 8: コミット**

```bash
git add app/BubblePopGameUITests/BubblePopGameUITests.swift app/BubblePopGameUITests/BubblePopGameUITestsLaunchTests.swift
git commit -m "perf: UITest のハード sleep を要素待機へ置換 (#44)"
```

---

## Task 6: CLAUDE.md にテストプラン運用を追記し、最終確認

**Files:**
- Modify: `CLAUDE.md`（「ビルドとテスト」セクション）

- [ ] **Step 1: CLAUDE.md にテストプランの使い分けを追記**

「ビルドとテスト」セクションに以下の主旨を追記:
- 毎回の CI / ローカル開発は `CI` テストプラン（Unit のみ）がデフォルト。`xcodebuild test ...`（プラン未指定）または `-testPlan CI`。
- UITest を含む全実行は `-testPlan Full` を明示指定（リリース前/手動のみ）。
- UITest は flaky なため毎回 CI からは外している（#44）。

```markdown
### テストプランの使い分け（#44）
- `CI`（デフォルト, Unit のみ）: 毎回の CI・ローカル開発用。`-testPlan CI` か未指定。
- `Full`（Unit + UITest）: リリース前/手動のみ。`xcodebuild test ... -testPlan Full`。
- UITest は起動コストが高く flaky なため毎回 CI からは除外（別枠）。
```

- [ ] **Step 2: 最終確認 — CI プランの実測（ビルド込み総時間）**

Run:
```bash
rm -rf build/DerivedData
SECONDS=0
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/DerivedData \
  -testPlan CI 2>&1 | grep -iE "Suite.*(passed|failed)|TEST (SUCCEEDED|FAILED)" | tail -10
echo "CI total (build+test) elapsed=${SECONDS}s"
```
Expected: `** TEST SUCCEEDED **`、総時間が ~100s 前後（ベースライン ~718s から大幅短縮）。

- [ ] **Step 3: コミット**

```bash
git add CLAUDE.md
git commit -m "docs: テストプランの使い分けを CLAUDE.md に追記 (#44)"
```

---

## 完了後（PR）

- [ ] `git push -u origin feature/issue-44-ci-test-time`
- [ ] `gh pr create`（base=main）。本文に:
  - before/after の実測時間表（CI / Full）
  - 検証チェックリスト（`-showTestPlans` / `-testPlan CI` で UITest 0 件 / `-testPlan Full` PASS / 残存 sleep なし）
  - ⚠️ **マージ後フォローアップ（ASC, 私からは不可）**: Xcode Cloud のワークフローが既存の暗黙設定の場合、Test アクションが `CI` テストプランを使う（= UITest を含まない）ことを ASC 上で 1 回確認・必要なら設定。

## 自己レビュー結果（spec 対応確認）

- spec §4① 共有スキーム → Task 2 ✅
- spec §4② テストプラン 2 枚 → Task 1 ✅
- spec §4③ per-config 無効化 → Task 4 ✅ / sleep 置換 → Task 5 ✅
- spec §5 CI が拾う仕組み・検証 → Task 3, Task 6 ✅
- spec §6 ASC フォローアップ → PR セクションに明記 ✅
- プレースホルダなし・型/メソッド名整合（`waitForNonExistence` / `waitForExistence`）確認済み
