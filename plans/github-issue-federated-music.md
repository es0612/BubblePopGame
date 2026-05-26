# Issue #5: 審査出す準備＋ローカライゼーション 対応計画

> **注記**: プランファイル名は `github-issue-federated-music.md` ですが、システムの制約で変更不可のため
> 内容を Issue #5 用に書いています。実装フェーズで `plans/issue-5-app-store-release.md` 等にリネーム推奨。

---

## Context

GitHub Issue [#5「審査出す準備＋ローカライゼーション」](https://github.com/es0612/BubblePopGame/issues/5) は本文空のサマリーIssueで、内容は既存の `docs/release-action-plan.md`（2025-09-23作成、Phase 1〜5）に紐づく。BubblePopGameは機能実装は完了済（テスト全PASS、日英Localizable.strings実装済み）だが、**App Store審査に出すためには以下のブロッカー解消が必要**:

- 致命的バグ4件（画面サイズ初期化／時間表示不整合／ParticleEffectView状態更新／高コントラスト無効化）
- `PrivacyInfo.xcprivacy` 未実装（iOS 17+で必須、ITMS-91053リスク）
- ローカライズ漏れ（ハードコード文字列11箇所、`knownRegions` に `ja` 未登録）
- 設定値が固定値で反映されないバグ
- デバッグ用print文 約37箇所
- App Storeスクリーンショット未作成
- TestFlight検証未実施

**期待される成果**: v1.0.0 を App Store Connect に提出可能な状態にする。

**ユーザー方針**（確認済み）:
- スコープ: release-action-plan の **全Phase（1〜5）** に取り組む
- PR戦略: **テーマ別に分割**（致命バグ／L10n／機能バグ／プロダクション準備／App Store申請）

---

## 推奨アプローチ

release-action-plan.md の Phase 1〜5 をテーマ別の独立PRに分割し、`superpowers:writing-plans` → `superpowers:executing-plans` の流れでPRごとにイテレーション。Phase 4（コード品質改善）は v1.0 提出後に延期。

### PR一覧と依存関係

| # | タイトル | 対応 Phase | 依存 | 並行可 | 工数目安 | 必須/任意 |
|---|---------|----------|------|--------|---------|---------|
| **PR1** | 致命的バグ修正（画面サイズ／時間表示／パーティクル／HCM） | Phase 1 | なし | PR2と並行可 | 0.5〜1日 | **必須** |
| **PR2** | ローカライゼーション完成（ハードコード除去＋knownRegions＋未翻訳追加） | Phase 2 #6 | なし | PR1と並行可 | 0.5〜1日 | **必須** |
| **PR3** | 機能バグ修正（設定値反映＋DI＋パフォーマンス回復） | Phase 2 #5,7,8 | PR1マージ後推奨 | PR2と並行可 | 0.5〜1日 | **必須** |
| **PR4** | プロダクション準備（PrivacyInfo＋print削除＋TODO解決＋テスト追加） | Phase 3 | PR1〜3 | 単独 | 1日 | **必須** |
| **PR5** | コード品質改善（GameViewModel／TutorialView分割等） | Phase 4 | PR4 | 単独 | 1〜2日 | 任意（v1.0後に延期） |
| **PR6** | App Store申請（スクショ／TestFlight／メタデータ確認） | Phase 5 | PR1〜4 | 単独 | 1日 | **必須** |

**クリティカルパス**: PR1+PR2+PR3 → PR4 → PR6

---

## PR1 — 致命的バグ修正 (Phase 1)

### 目的
ゲームプレイを破壊する4件の致命的バグを修正し、審査時のクラッシュ／不正動作リスクをゼロにする。

### 対象ファイル
- `app/BubblePopGame/ViewModels/GameViewModel.swift`（行 19, 95-108, 116-119）
- `app/BubblePopGame/Views/Game/GameView.swift`（行 134, 154-156）
- `app/BubblePopGame/Views/GameOver/GameOverView.swift`（行 102-104）
- `app/BubblePopGame/Views/Effects/ParticleEffectView.swift`（行 10-28）
- `app/BubblePopGame/Utils/AccessibilityUtils.swift`（行 131）

### TODO

#### 1.1 画面サイズ初期化問題
- [ ] `GameViewModel.swift:19` の `screenBounds` デフォルトを `CGRect.zero` に変更
- [ ] `startGame()` 内で `screenBounds == .zero` のときバブル生成を遅延
- [ ] `GameView.onAppear` の `updateScreenBounds(geometry.frame)` 呼び出し維持を確認
- [ ] 画面回転時の境界更新を確認
- [ ] テスト追加: `GameViewModelTests.initialScreenBounds`

#### 1.2 時間表示不整合
- [ ] `GameView.swift:134`: `total: 60.0` → `total: viewModel.gameSettings.gameTime`
- [ ] `GameOverView.swift:102-104`: `60.0 - viewModel.timeRemaining` 3箇所を `viewModel.gameSettings.gameTime - viewModel.timeRemaining` に置換
- [ ] テスト追加: gameTime=30s/60s/120s/180s 各設定で経過時間正常

#### 1.3 ParticleEffectView 状態更新問題
- [ ] `ParticleEffectView` を `@Observable class ParticleEffectViewModel` 形式に分離
- [ ] `EffectServiceImpl.particleEffectView` を ViewModel 参照に変更
- [ ] `GameView.swift:12` の `@State private var particleEffectView` をViewModelパターンに置換
- [ ] バブルタップ→パーティクル発生→1.5秒で消える挙動を目視確認

#### 1.4 アクセシビリティ高コントラスト
- [ ] `AccessibilityUtils.swift:131` を `UIAccessibility.isDarkerSystemColorsEnabled` 返却に修正
- [ ] iOS設定→アクセシビリティ→コントラストを上げる ON時に色変化を確認

### テスト方法
```bash
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```
- `Skill: ios-simulator-app-verification` でビルド・起動・基本フロー確認
- 設定変更後ゲーム開始でタイマー反映確認

### 完了基準
- [ ] 4件のバグ修正完了 / 全テストPASS / 30s〜180s各設定で完走 / iPhone・iPad両方で動作確認

---

## PR2 — ローカライゼーション完成 (Phase 2 #6)

### 目的
- 全ハードコード文字列を `NSLocalizedString` 経由に置換
- `knownRegions` に `ja` を登録（**重要：現在 `(en, Base)` のみで `ja` 未登録**）
- App Store提出時の多言語対応を完全化

### 対象ファイル
- `app/BubblePopGame.xcodeproj/project.pbxproj`（行 192-195、`knownRegions`）
- `app/BubblePopGame/{ja,en,Base}.lproj/Localizable.strings`
- `app/BubblePopGame/Views/LaunchScreenView.swift`（行 68-74）
- `app/BubblePopGame/Views/HighScore/HighScoreRow.swift`（行 32, 42, 48, 54, 60）
- `app/BubblePopGame/Views/HighScore/HighScoreView.swift`（行 44）
- `app/BubblePopGame/Views/Game/PauseOverlayView.swift`（行 42, 65, 86, 94）
- `app/BubblePopGame/Views/Game/BubbleView.swift`（行 42-43）
- `app/BubblePopGame/Views/TutorialView.swift`（行 49）
- `app/BubblePopGame/ContentView.swift`（行 43, 50）

### TODO

#### 2.0 プロジェクト設定（最優先）
- [ ] `project.pbxproj:192-195` `knownRegions = (en, Base);` → `knownRegions = (en, ja, Base);`
- [ ] Xcode → Project → Info → Localizations に `Japanese` が表示されることを確認
- [ ] ビルド成果物の `.app/ja.lproj/` 存在確認

#### 2.1 新規ローカライゼーションキー追加（ja/en/Base 全てに19キー）

| キー | ja | en |
|------|----|----|
| `loading_settings` | 設定読み込み中... | Loading settings... |
| `loading_initialization` | 初期化中... | Initializing... |
| `accessibility_skip_tutorial_hint` | チュートリアルをスキップしてメニューに進みます | Skip tutorial and go to menu |
| `accessibility_resume_game_hint` | ゲームを再開します | Resume the game |
| `accessibility_quit_game_hint` | ゲームを終了してメニューに戻ります | End the game and return to menu |
| `pause_quit_confirm_title` | ゲーム終了の確認 | Confirm Game Exit |
| `pause_quit_confirm_message` | 本当にゲームを終了しますか？\n現在のゲームは終わります。 | Are you sure you want to quit the game?\nThe current game will be ended. |
| `bubble_accessibility_numbered` | 数字%dのシャボン玉 | Bubble with number %d |
| `bubble_accessibility_normal` | シャボン玉 | Bubble |
| `bubble_accessibility_hint` | タップすると破裂します | Tap to pop |
| `highscore_game_mode_normal` | 通常 | Normal |
| `highscore_game_mode_numbered` | 数字順 | Numbered |
| `highscore_bubbles_popped_label` | 破裂数: %d | Bubbles popped: %d |
| `highscore_accuracy_label` | 正確率: %@ | Accuracy: %@ |
| `highscore_time_limit_label` | 制限時間: %d秒 | Time limit: %d sec |
| `highscore_play_duration_label` | プレイ時間: %.1f秒 | Play time: %.1fs |
| `highscore_time_limit_picker_label` | 制限時間 | Time limit |
| `launch_screen_title_main` | シャボン玉消しゲーム | Bubble Pop Game |
| `launch_screen_title_sub` | Bubble Pop Game | Pop the bubbles! |

#### 2.2〜2.8 各ファイルのハードコード置換
- [ ] `ContentView.swift:43,50`: `ProgressView("設定読み込み中...")` / `"初期化中..."` → `NSLocalizedString` 経由
- [ ] `LaunchScreenView.swift:68,74`: タイトル2行を `launch_screen_title_main/sub` に置換
- [ ] `HighScoreRow.swift:32,42,48,54,60`: 5箇所のText文字列を `NSLocalizedString(format:)` 化
- [ ] `HighScoreView.swift:44`: `Picker("制限時間", ...)` → `NSLocalizedString("highscore_time_limit_picker_label", ...)`
- [ ] `PauseOverlayView.swift:42,65,86,94`: accessibilityHint と alert を全てローカライズ
- [ ] `BubbleView.swift:42-43`: accessibilityLabel と accessibilityHint をローカライズ
- [ ] `TutorialView.swift:49`: accessibilityHint をローカライズ

#### 2.9 String Catalog 移行（任意・推奨度低）
- [ ] **デフォルトでは実施しない**。v1.0提出後に判断
- [ ] 実施する場合は `Skill: xcstrings-bulk-update` を使用

### テスト方法
- `Skill: ios-simulator-locale-testing` で ja/en 切り替えての全7画面（Launch/Menu/Tutorial/Game/Pause/GameOver/HighScore/Settings）スクショ取得
- 並べて目視review（ハードコード残存ゼロ確認）

### 完了基準
- [ ] `knownRegions` に `ja` 追加済み
- [ ] 19キー全て3言語に追加
- [ ] 全ハードコードText/Picker/alert/accessibility が `NSLocalizedString` 経由
- [ ] ja・en両方で全画面スクショ取得し残存ハードコードなし

---

## PR3 — 機能バグ修正 (Phase 2 #5, #7, #8)

### 目的
設定値の未反映・DIダウンキャスト・パフォーマンス回復ロジック不在の3件を修正。

### 対象ファイル
- `app/BubblePopGame/Services/BubbleService.swift`（行 31-71）
- `app/BubblePopGame/ViewModels/GameViewModel.swift`（行 95-108, 110-113）

### TODO

#### 3.1 設定値反映（BubbleService）
- [ ] `BubbleService` に `updateSettings(_ settings: GameSettings)` を追加（**案B採用**）
- [ ] `BubbleServiceImpl` に `private var gameSettings: GameSettings?` を保持
- [ ] `createBubble(at:type:)` の radius 計算で `settings.bubbleMinRadius...bubbleMaxRadius` を使用
- [ ] `updateBubbles(_:)` の `animationPhase` 進行量に `gameSettings?.animationSpeed` を掛ける
- [ ] `GameViewModel.init` / `reloadGameSettings()` / `ContentView.setupDependencies` で `updateSettings` 呼び出し
- [ ] Settings画面でbubbleCount=10/50, animationSpeed=2.0 → ゲーム開始 → 即座反映確認

#### 3.2 依存性注入問題
- [ ] `GameViewModel.swift:110-113` の `effectService as? EffectServiceImpl` ダウンキャストを除去
- [ ] `EffectService` プロトコルに `attachParticleEffectViewModel(_:)` 追加
- [ ] `EffectServiceImpl.particleEffectView` を private 化
- [ ] grep で `as? EffectServiceImpl` 残存ゼロ確認

#### 3.3 パフォーマンス回復ロジック
- [ ] `GameViewModel.optimizePerformance()` に「削減後の回復ロジック」を追加
- [ ] `PerformanceService.shouldRestoreBubbles() -> Bool` を追加
- [ ] `updateGame()` の1秒チェックブロックで `shouldRestoreBubbles()` も判定
- [ ] テスト追加: "削減→負荷回復→再増加" シナリオ

### 完了基準
- [ ] 設定変更がバブルサイズ／速度／個数に即座反映
- [ ] `effectService as? EffectServiceImpl` 残存ゼロ（grep確認）
- [ ] パフォーマンス回復シナリオの単体テストPASS

---

## PR4 — プロダクション準備 (Phase 3 + PrivacyInfo)

### 目的
- **`PrivacyInfo.xcprivacy` 追加（App Store審査ブロッカー解消、最優先）**
- print文約37箇所をOSLog化 or #if DEBUG化
- `MenuViewModel` のTODO 2件解決
- 主要フローの回帰テスト拡充

### 対象ファイル
**新規**:
- `app/BubblePopGame/PrivacyInfo.xcprivacy`
- `app/BubblePopGame/Utils/AppLogger.swift`
- `app/BubblePopGameTests/MenuViewModelTests.swift`
- `app/BubblePopGameTests/SettingsFlowTests.swift`
- `app/BubblePopGameTests/ScoreSaveTests.swift`

**修正**:
- `app/BubblePopGame/ViewModels/MenuViewModel.swift`（行 19-25）
- `app/BubblePopGame/Services/AudioService.swift`（最大20箇所）
- `app/BubblePopGame/Services/EffectService.swift`、その他 print文ある全ファイル

### TODO

#### 4.1 PrivacyInfo.xcprivacy 作成（最優先）
- [ ] grepでUserDefaults/AppStorage使用ゼロ再確認（**確認済**）
- [ ] `app/BubblePopGame/PrivacyInfo.xcprivacy` 作成:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array/>
</dict>
</plist>
```

**根拠**: ネットワーク通信なし・追跡なし・データ収集なし（SwiftDataローカル保存のみ）・UserDefaults使用ゼロ

- [ ] `PBXFileSystemSynchronizedRootGroup` 機構で自動認識されるが、Build Phases → Copy Bundle Resources に含まれていることを確認
- [ ] DerivedData配下に `PrivacyInfo.xcprivacy` 出力確認

#### 4.2 OSLog ベースの統一ロガー
- [ ] `app/BubblePopGame/Utils/AppLogger.swift` 作成:
```swift
import Foundation
import os.log
enum AppLogger {
    private static let subsystem = "com.asapapalab.BubblePopGame"
    static let lifecycle  = Logger(subsystem: subsystem, category: "lifecycle")
    static let settings   = Logger(subsystem: subsystem, category: "settings")
    static let audio      = Logger(subsystem: subsystem, category: "audio")
    static let effect     = Logger(subsystem: subsystem, category: "effect")
    static let performance = Logger(subsystem: subsystem, category: "performance")
    static let highscore  = Logger(subsystem: subsystem, category: "highscore")
    static let tutorial   = Logger(subsystem: subsystem, category: "tutorial")
    static let storage    = Logger(subsystem: subsystem, category: "storage")
}
```

#### 4.3 print文置換（約37箇所）
- [ ] Error系（保持・OSLog化）: ContentView/SettingsViewModel/GameViewModel/BubblePopGameApp/TutorialView/HighScoreView/AudioService の各error出力
- [ ] Info系（DEBUG限定）: `EffectService:47` の高頻度ログは削除、AudioService の探索/再生ログは `#if DEBUG` で囲み debug レベル化
- [ ] 検証: `grep -rn "print(" app/BubblePopGame --include="*.swift" | grep -v "// "` で残存ゼロ

#### 4.4 MenuViewModel TODO解決
- [ ] `MenuViewModel.init(scoreRepository:)` に変更、`loadHighScores()` を Repository経由実装
- [ ] `ContentView.setupDependencies` で `MenuViewModel(scoreRepository: scoreRepository)` 渡す
- [ ] `navigateToGame()` は YAGNI のため削除（現状 MenuView が gameViewModel.startGame() 直接呼び）

#### 4.5 テスト追加
- [ ] `MenuViewModelTests`: `loadHighScores_withRepository_populatesArray` 等3ケース
- [ ] `SettingsFlowTests`: `settingsChange_reflectedInGameStart`
- [ ] `ScoreSaveTests`: `endGame_savesScore` / `endGame_updatesStatistics`

#### 4.6 リリースビルド設定
- [ ] Release configurationの最適化レベル `-O` 確認
- [ ] Strip Linked Product = YES、Symbols Hidden = YES

### 完了基準
- [ ] `PrivacyInfo.xcprivacy` が `.app` バンドルに含まれる
- [ ] print文残存ゼロ（grep確認）
- [ ] MenuViewModel TODO 2件解決
- [ ] 新規テスト3ファイルPASS / 全テストPASS / Release ビルド警告ゼロ

---

## PR5 — コード品質改善 (Phase 4)【任意・v1.0後に延期推奨】

v1.0 提出のクリティカルパス外。**別Issueとして切り出し推奨**。

スケッチのみ:
- GameViewModel.swift (701行) → `GameLogicService` / `GameTimerService` に分割、目標<400行
- TutorialView.swift (540行) → step別ファイル化、目標<300行
- Timer管理を `TimerManager` で統一
- `DispatchQueue.main.asyncAfter` × 8箇所を async/await に移行
- ContentView.swift の `setupDependencies` を `DependencyContainer` に切り出し

---

## PR6 — App Store 申請 (Phase 5)

### 目的
スクリーンショット生成、App Store Connect設定、TestFlight配信、メタデータ最終確認。

### TODO

#### 6.1 バージョン番号確認
- [ ] **`Skill: release-version-bump-check`** でバージョン妥当性検証
- [ ] 初回提出のため `MARKETING_VERSION=1.0`、`CURRENT_PROJECT_VERSION=1` のまま（ITMS-90186/90062リスクなし）

#### 6.2 スクリーンショット生成
- [ ] **`Skill: ios-simulator-locale-testing`** で撮影
- [ ] 必須サイズ: iPhone 6.7"/6.9"（必須）、iPad 13"（iPad対応のため必須）
- [ ] 各サイズ × ja/en × 5画面 = 20枚:
  1. メインメニュー
  2. ゲーム中（通常モード）
  3. ゲーム中（数字順モード）
  4. ハイスコア画面
  5. 設定画面
- [ ] 出力先: `/screenshot/{device}/{locale}/{screen}.png`
- [ ] ステータスバー固定:
  ```bash
  xcrun simctl status_bar booted override --time "9:41" --batteryState charged \
    --batteryLevel 100 --wifiBars 3 --cellularBars 4
  ```

#### 6.3 アプリアイコン最終確認
- [ ] 1024×1024 Light/Dark/Tinted 揃い（探索済）
- [ ] 透過なし・角丸処理なしの生PNG確認

#### 6.4 App Store Connect セットアップ
- [ ] 新規アプリ作成（Bundle ID: `com.asapapalab.BubblePopGame`）
- [ ] `docs/app-store-metadata.md` の内容を転記（アプリ名/サブタイトル/キーワード/説明文）
- [ ] サポートURL・プライバシーポリシーURL（`docs/privacy-policy.md` をGitHub Pages等で公開）登録
- [ ] カテゴリ: ゲーム > カジュアル / 年齢制限: 4+ / 価格: 無料 / IAP: なし
- [ ] App Privacy: "Data Not Collected"（`PrivacyInfo.xcprivacy` と整合）

#### 6.5 TestFlight 配信
- [ ] Xcode → Product → Archive で Release ビルド
- [ ] Validate App で警告ゼロ確認
- [ ] Distribute App → App Store Connect → Upload
- [ ] Processing完了後 Internal Testing に自分を追加 → 実機 walk-through:
  - 初回起動→チュートリアル→メニュー
  - 各ゲームモード × 各時間設定 × 各BGM
  - ハイスコア / 設定リセット / バックグラウンド復帰 / 機内モード動作

#### 6.6 申請前最終チェック
- [ ] PrivacyInfo含む / サポートURL・プライバシーポリシーURL公開済 / スクショ20枚アップロード
- [ ] Export Compliance: 「暗号化未使用」/ Release Notes記載 / 「審査待ち」状態で提出

### 完了基準
- [ ] ASCに v1.0 (Build 1) を「審査待ち」でアップロード
- [ ] TestFlight Internal Testingで実機動作確認完了
- [ ] スクショ20枚アップロード済 / App Privacy "Data Not Collected" 確定

---

## 統合検証（全PR完了後・PR6前）

```bash
# クリーンビルド
xcodebuild clean -project app/BubblePopGame.xcodeproj -scheme BubblePopGame

# Debug / Release / Test 全実行
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Release \
  -destination 'generic/platform=iOS'
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'

# Code Quality grep
grep -rn "print(" app/BubblePopGame --include="*.swift" | grep -v "// "      # → 0行期待
grep -rn "TODO\|FIXME" app/BubblePopGame --include="*.swift"                  # → MenuViewModel解決済確認
grep -rn "as? EffectServiceImpl" app/BubblePopGame --include="*.swift"        # → 0行期待

# PrivacyInfo 検証
find ~/Library/Developer/Xcode/DerivedData -path "*BubblePopGame*" -name "PrivacyInfo.xcprivacy"
```

- `Skill: ios-simulator-locale-testing` で ja/en 全7画面スクショ取得→残存ハードコードゼロ確認
- `Skill: ios-simulator-app-verification` で全フロー walk-through
- iPhone実機（iOS 17.x）で TestFlight 配信前検証

---

## 利用スキル一覧

| スキル | 利用PR | 用途 |
|--------|--------|------|
| `superpowers:writing-plans` | PR1〜PR6 | 各PR詳細計画 |
| `superpowers:executing-plans` | PR1〜PR6 | 各PR実装 |
| `superpowers:test-driven-development` | PR1, PR3, PR4 | バグ修正前のテスト追加 |
| `superpowers:verification-before-completion` | 全PR | マージ前検証 |
| `superpowers:finishing-a-development-branch` | 全PR | PR作成・マージ |
| `ios-simulator-app-verification` | PR1, PR3, PR4 | シミュレータ動作確認 |
| `ios-simulator-locale-testing` | PR2, PR6 | ja/en切り替え検証＋スクショ |
| `xcstrings-bulk-update` | PR2（任意） | String Catalog 移行 |
| `release-version-bump-check` | PR6 | バージョン妥当性 |

---

## リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| `knownRegions` 修正で既存 ja.lproj が壊れる | ja表示不可 | PR2で `ja` 追加後、必ず ja シミュレータで動作確認 |
| `ParticleEffectView` 構造変更でUI崩壊 | パーティクル非表示 | PR1でTDD（先にテスト追加） |
| `PrivacyInfo.xcprivacy` 申告漏れ | 審査リジェクト | UserDefaults等の使用箇所をgrep再確認（**現時点ゼロ確認済**） |
| プライバシーポリシーURL未公開 | 申請不可 | PR6開始前にGitHub Pages公開、ASC登録 |
| TestFlight実機検証でiOS 17未対応バグ | 提出延期 | iPhone 12 (iOS 17.x) 等で確認 |

---

## Critical Files for Implementation

最重要5ファイル:
- `/Users/shinya/workspace/claude/BubblePopGame/app/BubblePopGame.xcodeproj/project.pbxproj`（PR2 `knownRegions`、PR4 PrivacyInfo登録確認）
- `/Users/shinya/workspace/claude/BubblePopGame/app/BubblePopGame/PrivacyInfo.xcprivacy`（**PR4新規・審査ブロッカー解消**）
- `/Users/shinya/workspace/claude/BubblePopGame/app/BubblePopGame/ViewModels/GameViewModel.swift`（PR1致命バグ／PR3 DI・パフォーマンス／PR4 print削除）
- `/Users/shinya/workspace/claude/BubblePopGame/app/BubblePopGame/{ja,en,Base}.lproj/Localizable.strings`（PR2で19キー追加）
- `/Users/shinya/workspace/claude/BubblePopGame/app/BubblePopGame/Services/BubbleService.swift`（PR3設定値反映の中核）

副次的に重要:
- `app/BubblePopGame/Views/Effects/ParticleEffectView.swift`（PR1状態更新バグ）
- `app/BubblePopGame/Utils/AppLogger.swift`（PR4新規）
- `app/BubblePopGame/Views/Game/PauseOverlayView.swift`（PR2 L10n漏れ集中）

---

## 作業順序（推奨タイムライン）

```
Day 1: PR1（致命バグ）と PR2（L10n）を並行で実装→マージ
Day 2: PR3（機能バグ）実装→マージ → PR4（プロダクション準備）開始
Day 3: PR4 続き → マージ → 統合検証チェックリスト実行
Day 4: PR6（App Store申請）→ TestFlight → ASC提出
Day 5+: PR5（コード品質）は別Issue化、v1.0提出後の保守タスク
```

---

## 次のアクション

1. このプラン承認後、**PR1から `superpowers:writing-plans` でPR単位の詳細計画を作成**
2. 各PRごとに `superpowers:executing-plans` で実装
3. PR間で `superpowers:verification-before-completion` を通す
4. 最終的に `superpowers:finishing-a-development-branch` でmainにマージ

---

*作成日: 2026-05-17*
*対象Issue: [#5 審査出す準備＋ローカライゼーション](https://github.com/es0612/BubblePopGame/issues/5)*
*ベース資料: `docs/release-action-plan.md`*
