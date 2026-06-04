# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 開発ルール
- 全て日本語で回答すること
- tasks.mdファイルに則り、小さなタスクサイズでイテレーティブに開発を進めること
- 要件や設計は、requirements.mdとdesign.mdを参照すること
- 各タスク終了時にビルドやテストが問題なくパスすることを確認し、コミットすること

## プロジェクト概要
シャボン玉消しゲームのiOSアプリケーション。SwiftUI、SwiftData、MVVMアーキテクチャを使用。

## ビルドとテスト
```bash
# Xcodeプロジェクトを開く
open app/BubblePopGame.xcodeproj

# コマンドラインビルド（destinationは利用可能なシミュレータに合わせる）
xcodebuild -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# テスト実行（UnitTestのみに絞ると UITest 起動失敗の影響を避けられる）
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:BubblePopGameTests

# Release ビルド（シミュレータ向け、警告検出に有用）
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Release -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# クリーンビルド
xcodebuild clean -project app/BubblePopGame.xcodeproj -scheme BubblePopGame
```

### テストプランの使い分け（#44）
本プロジェクトは共有スキーム + 2 つのテストプランを持つ:
- **`CI`（デフォルト, UnitTest のみ・並列）**: 毎回の CI / ローカル開発用。`-testPlan` を省略すると `CI` が使われる（bare `xcodebuild test` で UITest 0 件をローカル実証済み）。明示するなら `-testPlan CI`。⚠️ Xcode Cloud は既存ワークフローがテストターゲットを明示列挙している場合、ASC 側で「CI テストプランを使う」設定変更が 1 回必要（リポからは変更不可）。
- **`Full`（UnitTest + UITest）**: リリース前 / 手動のみ。`xcodebuild test ... -testPlan Full` で明示指定。

UITest は起動コストが高く flaky なため毎回 CI からは除外している（別枠）。テストプラン実体は `app/CI.xctestplan` / `app/Full.xctestplan`、スキームは `app/BubblePopGame.xcodeproj/xcshareddata/xcschemes/BubblePopGame.xcscheme`。

### 利用可能シミュレータの確認
```bash
xcrun simctl list devices available | grep -E "iPhone|iPad"
```
iPhone 16 系は存在しない環境がある（iPhone 17 系 / iPad Pro が主）。Release ビルドを実機向け (`-destination 'generic/platform=iOS'`) で実行すると Provisioning Profile が必要で失敗するため、検証は基本シミュレータ向けで行うこと。

### SwiftTesting のテスト結果確認
xcodebuild の出力は冗長なので、SwiftTesting の結果は以下の grep で抽出する:
```bash
xcodebuild test ... 2>&1 | grep -iE "Suite.*(started|passed|failed)|Test case .* (passed|failed)"
```
`** TEST SUCCEEDED **` だけ見るとどのテストが走ったか分からないので、テストの実体確認には上記パターン推奨。

⚠️ **単一テスト指定の「0件 SUCCEEDED」罠**: `-only-testing:BubblePopGameTests/SuiteName/testMethod()` のように**メソッド単位**まで絞ると、ビルドキャッシュ等の都合で**1件も実行されないまま `** TEST SUCCEEDED **`**（vacuous）になることがある。これを RED 確認に使うと「落ちるはずのテストが通った」と誤認する。テストを確実に走らせて RED/GREEN を判定したいときは **suite 単位**（`-only-testing:BubblePopGameTests/SuiteName`）で実行し、上の grep で `Test case '...' (passed|failed)` 行が実際に出力されることを確認すること。

## アーキテクチャ

### ディレクトリ構造
```
app/BubblePopGame/
├── BubblePopGameApp.swift          # アプリエントリーポイント
├── ContentView.swift               # メインビュー
├── Item.swift                      # SwiftDataモデル（仮）
├── Views/                          # SwiftUIビュー
├── ViewModels/                     # @Observable ViewModels
├── Services/                       # ビジネスロジック（Audio, Effect, Bubble）
├── Models/                         # SwiftDataモデルとCore Data Types
├── Repositories/                   # データアクセス層
└── Assets.xcassets/                # アセット
```

### MVVMアーキテクチャ
- **View層**: SwiftUI Views + Gesture Recognition
- **ViewModel層**: @Observable ViewModels + Business Logic
- **Service層**: Audio, Effect, Game Logic Services  
- **Model層**: SwiftData Models + Core Data Types
- **Repository層**: Data Access & Persistence

## 主要技術スタック
- **UI**: SwiftUI
- **データ永続化**: SwiftData
- **アーキテクチャ**: MVVM with @Observable
- **アニメーション**: Core Animation + SwiftUI
- **音響**: AVAudioEngine
- **テスト**: SwiftTesting
- **触覚フィードバック**: UIKit (UIImpactFeedbackGenerator)

## 開発時の注意点
- SwiftDataモデルは必ず@Modelマクロを使用
- ViewModelには@Observableマクロを適用
- パフォーマンス監視（60FPS維持）を重視
- オブジェクトプールパターンでメモリ効率化
- アクセシビリティ対応を忘れずに実装
- 新規 `.swift` ファイルはフォルダに置くだけでターゲットに自動参加する（本プロジェクトは Xcode 16 の file-system synchronized groups を採用 = `PBXFileSystemSynchronizedRootGroup`）。`project.pbxproj` の手編集は不要。テストファイルも `BubblePopGameTests/` に置けば自動で UnitTest ターゲットに含まれる

### MainActor 隔離

- `@Observable class` で UI から呼ばれるサービスを書く場合は `@MainActor` 付与（特に `effects` などのSwiftUI状態を変更するメソッド）
- 実装側だけ `@MainActor` を付けるとプロトコル適合で Swift 6 警告（`conformance ... crosses into main actor-isolated code`）が出るため、プロトコル側にも合わせて付与するのが本筋
- 既存プロトコルを変えにくい場合は `Task { @MainActor in ... }` でラップする選択肢もあるが、`createPopEffect` のような UI 連動メソッドはレイテンシ的に同期呼び出しが望ましい
- ⚠️ **「見えない警告」の検証**: 本プロジェクトは `SWIFT_VERSION = 5.0` かつ `SWIFT_STRICT_CONCURRENCY` 未設定（= minimal）のため、上記 conformance 警告は**通常ビルドでは surface しない**。`@MainActor` 化のような Swift 6 対応を修正・検証するときは、`xcodebuild build ... SWIFT_STRICT_CONCURRENCY=complete` で before（警告が出る）/ after（消える）を実測すること。通常 config のままだと「修正したつもり」でも検証不能（View レイヤのリテラル revert がテストをすり抜けるのと同じ盲点）

### SwiftData の取り扱い

- ⚠️ **autosave footgun**: SwiftUI の `.modelContainer(_:)` は `mainContext.autosaveEnabled = true` がデフォルト。`fetchSettings()` 等で取得した context 追跡下の `@Model` インスタンス（例: `GameSettings`）を `obj.prop = ...` と書き換えると、明示的に save しなくても autosave で**永続化される**
- そのため、テスト/デバッグ用の一時的な override（例: `--skip-tutorial` で `isFirstLaunch` を無視する）では、**永続モデルを書き換えず**にローカル変数で判定だけ分岐させること。モデルを mutate すると次回の通常起動にも値が残ってバグになる
- どうしても override 値をモデル経由で渡したい場合は、context 非挿入の detached な `GameSettings()` を作る方式を検討（ただし全フィールド複製の保守コストと、後段で保存経路に乗ると重複 row を作るリスクに注意）
- ✅ **read サイトが多数ある `@Model` 値の一時 override は computed-property override が本命**（上記「局所変数 / detached copy」に続く第3の選択肢）。`gameTime` のように参照箇所が多い（タイマー初期化・ProgressView・スコア記録・難易度計算・リザルト表示など 9 箇所超）値を override するとき、各 read サイトを書き換えるのは保守不能。ViewModel に `effectiveX = overrideX ?? gameSettings.X` の computed property を1つ置き、全 read サイトをそれ経由にする。**本プロジェクトは既に `GameViewModel.effectiveGameTime`（DEBUG の `--game-time=` 起動引数を優先）でこのパターンを採用済み**。テスト可能・副作用ゼロ（永続モデルを mutate しない）・Release ビルドで collapse し、detached copy の全フィールド複製コストも保存経路での重複 row リスクも回避できる
- ⚠️ **`@Model` のデフォルト値を変えたら既存ユーザー移行を別途用意する**。デフォルト値の変更（例 `gameTime 60→30`、#35）は `init()` 経由なので**新規インストールにしか効かない**（既存ユーザーは永続 row の旧値を保持）。既存ユーザーも動かすには 1 回限りの migration を、**全ユーザーが起動時に必ず通る単一チョークポイント**で実行する（ルート View の `.task` 等。設定画面に紐付けると設定を開かない人に発火しない）。二重実行は `UserDefaults` センチネルで防ぎ、**値ベース判定**（旧デフォルト値の row だけ移行）で手動変更したユーザーを尊重する。⚠️ センチネル/完了フラグは **no-op・成功時のみ立て、fetch/save が失敗したら立てずに（`debugLog` して）次回起動で再試行**させる。`defer { setFlag }` を fetch ガードより前に置くと失敗も握り潰し「やった印」だけ立って**永久に未移行**になる（#35 の最終レビューで実際に捕捉した）。`GameTimeDefaultMigration` が実装例（in-memory ModelContainer + 一意 UserDefaults suite でユニットテスト可能）

### View レイヤ修正の検証戦略

- View 内のハードコード値（`60.0` リテラル等）や `EnvironmentValues` の挙動は、ViewModel/Color変換の単体テストではカバーできない（リテラルをrevertしてもテストPASSしてしまう盲点）
- そのため View 層修正は**手動 walk-through が必須**。PR description に「マージ前手動確認チェックリスト」を明記する
- `simctl` には `tap` がないため、設定変更や tutorial スキップを伴う自動検証は不可。`xcrun simctl io ... screenshot` で起動確認＋クラッシュなしの確認までが自動化の上限
- 永続化された GameSettings は SwiftData なので `UserDefaults trick`（`xcrun simctl spawn ... defaults write`）が効かない点に注意
- 永続化フラグ（`isFirstLaunch` 等）で初期化フローが分岐する場合、手動 walk-through は「初回起動」「2回目以降」の両経路を必ず検証する。Tutorial を経由するかどうかで `updateScreenBounds` のような重要な副作用がスキップされ、本番バグの温床になる
- `guard` で前提条件を弾く修正を入れるときは、その前提条件を供給するコード（例: `screenBounds` をセットする `onAppear`）が、ガードを通過する全ての到達経路で確実に走るかを必ず洗い出す。コメントに「X で供給される」と書くだけでは、X が一部経路でしか実行されないと永続デッドロックになる
- ⚠️ **`screenBounds == .zero` は本番化済みの systemic fault**（#23 起動不能 / #24 チュートリアルバブル不可視で実際に TestFlight に出た）。共有 `gameViewModel.screenBounds` は LaunchScreen→ContentView のアニメ遷移中に供給を取りこぼし `.zero` になりうる。対処は「供給を待つ」だけでなく次の3点:
  1. `updateScreenBounds` は `.zero`/不正サイズを無視し、有効値を上書きしない
  2. `startGame` は `.zero` で early-return（永久デッドロック）せず保留し、サイズ到達時に自動開始する（deferred-start）
  3. **View 固有の座標計算は共有 screenBounds でなく、その View 自身の `geometry.size` を使う**（例: TutorialView の練習バブル配置）
- ⚠️ **検証後の cleanup を忘れない**: `xcrun simctl launch` でアプリを起動して screenshot を撮ったら、検証完了後に必ず `xcrun simctl terminate <SIM> <BUNDLE>`（必要なら `xcrun simctl shutdown <SIM>`）で停止する。本アプリは BGM がデフォルト ON（`bgmEnabled = true`）でメニュー画面で自動再生されるため、起動しっぱなしにすると裏で音楽が鳴り続ける。**音声を持つアプリの検証では terminate を特に徹底する**
- バグ報告 issue の screenshot は一次証拠。**public repo なら `curl -L <github user-attachments の画像URL> -o /tmp/x.png` でダウンロード → Read で直接解析**できる（`gh issue view --json body` では `![image](...)` の URL は取れても画像本文は得られない）。タイトルだけで原因を推測せず、必ず画像を見ること（#23/#24 は画像で「メニュー停止」「練習バブル不可視」と即断定できた）

### UI テスト設計

- XCUITest の predicate（例: `CONTAINS '0' OR CONTAINS '1'`）は、意図しない他の UI 要素（時間表示の「60 秒」等）にも偽陽性マッチして検証が空転する。スコア／タイマー等の同種数値要素が画面に共存するときは accessibilityIdentifier で厳密に特定する

### ローカライズの検証戦略

- accessibility ラベル等、**スクショ/目視に映らないローカライズ文字列**を追加したら、「全新規キーが ja/en/Base の全ファイルに存在する」＋「3 ファイルのキー集合が一致する」ことを assert するユニットテストで守る。キー欠落・ロケール漏れは `simctl` の no-tap 検証や目視をすり抜けるため、テストで大声で検出させる（関連スキル: `xcstrings-bulk-update` / `xcstrings-plural-variations`）。**本プロジェクトには既に `LocalizationKeysTests`（必須キー存在＋ ja/en/Base パリティ）がある**ので、キー追加/削除時はこれが守る（1 ロケールだけ消し忘れるとパリティテストが落ちる）
- ⚠️ **`String(format:)` の書式指定子と引数型の不一致は実行時に黙って壊れる**。`seconds_format = "%d秒"`（整数書式）に **Double** を渡すと 0／不正値になる（#37「Play Time 0 sec」の実際の原因。`SettingsView` は `Int(...)` キャスト済みだが `GameOverView` は Double を渡していた）。同じ format キーを複数箇所で使うと、片方が `Int(...)`・片方が Double で挙動が割れて目視をすり抜ける。format 系は型を揃え、計算は **testable な computed property（`Int` 返し等）に切り出してユニットテストで守る**（例: `GameViewModel.elapsedPlaySeconds`）

### App Store 提出・スクショ検証

- ✅ **simctl 自動スクショの上限は「起動画面のみ」ではない**。`#if DEBUG` 限定の起動引数で目的の `gameState` へ直行＋サンプルデータ注入すれば、ゲーム中／リザルト／設定など **tap 遷移が要る "売り" の画面も tap なしで全自動キャプチャ**できる。本プロジェクトは `--screenshot=<画面>` を実装済み（#43）。App Store スクショはこの DEBUG ナビ＋ Pillow 合成（`scripts/screenshots/compose_screenshots.py`、Hiragino フォント）で全自動生成できる。`simctl` に `tap` が無い制約は、DEBUG 起動引数で「画面遷移そのものを引数化」すれば回避できる（[[ios-simulator-app-verification]] の no-tap 検証の発展形）
- ⚠️ **App Store スクショは `TARGETED_DEVICE_FAMILY` の全デバイスファミリ分が提出必須**。本プロジェクトは `"1,2"`（iPhone+iPad）なので、iPhone 6.9" だけでなく **iPad 13" のスクショも必須**（iPhone 分だけ用意すると審査で不足扱い）。撮影機シミュレータの実寸は必須解像度と一致不要で、合成時にデバイス枠内へスケール配置すればよい
- ✅ **ASC 提出フィールド（説明文・キーワード・サブタイトル等）の単一ソースは `docs/app-store-metadata.md`**。コードと乖離した旧マーケ／分析 docs（旧リリース計画等）は削除済みなので、提出情報はこのファイルだけを最新化・参照する

### Git運用

- `main` には直接コミットしない。`feature/issue-N-pr-X-<topic>` のような名前で feature branch を切る
- ⚠️ **スタックPR のマージ順の罠**: base が別 feature ブランチのスタックPR（`#B` の base=`feature/A`）は、`#A` を先に main へマージした後で `#B` をマージすると、**main でなく中間ブランチ（feature/A）に入り、コードが main に到達しない**（GitHub 上は "merged" 表示でも）。実際に #26/#27 がこれで #19/#20 を main 未着地にし、re-land 2 PR（#29/#30）の手戻りが発生した。→ **独立に並行する変更は base=main で切る**（同一ファイルを触っても 3-way merge で大抵解決）。どうしてもスタックする場合は下から順にマージし、各PRの base（マージ先）を必ず確認する
- `build/` と `DerivedData/` は `.gitignore` 済み（`xcodebuild -derivedDataPath build/DerivedData` 利用時の生成物）
- PR タイトルは `fix:` / `feat:` / `chore:` プレフィックス、本文に Test plan の手動確認チェックリストを含める

## セッション終了時の振り返り運用

開発を進めるほどフローが洗練されていく「複利」を生む仕組み:

- **`session-retrospective` skill**（グローバル）が用意されている。ユーザーが「終わり」「お疲れ」「振り返って」等を発話すると自動発動
- **Stop hook**（`.claude/hooks/stop-retrospective-reminder.sh`、`.claude/settings.local.json` で登録）が、直近2時間でコミット3件以上 かつ 最終リマインドから1時間以上経過時に「振り返りませんか?」とリマインド
- 振り返り skill は、セッション中の学びを以下に振り分けて反映:
  - **プロジェクト知識** → CLAUDE.md（このファイル）に追記
  - **未完了/別途対応事項** → GitHub Issue 化（`gh issue create`）
  - **ユーザー嗜好** → memory に保存
- これを継続することで、次セッションは前回の学びを最初から踏まえて動ける（同じ罠を踏まない／同じ手順を3回繰り返さない）

⚠️ **stateファイル** `.claude/.last-retrospective-reminder` は `.gitignore` 対象（hookが書き込むタイムスタンプ）
