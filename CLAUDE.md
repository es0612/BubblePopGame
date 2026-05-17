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

### MainActor 隔離

- `@Observable class` で UI から呼ばれるサービスを書く場合は `@MainActor` 付与（特に `effects` などのSwiftUI状態を変更するメソッド）
- 実装側だけ `@MainActor` を付けるとプロトコル適合で Swift 6 警告（`conformance ... crosses into main actor-isolated code`）が出るため、プロトコル側にも合わせて付与するのが本筋
- 既存プロトコルを変えにくい場合は `Task { @MainActor in ... }` でラップする選択肢もあるが、`createPopEffect` のような UI 連動メソッドはレイテンシ的に同期呼び出しが望ましい

### View レイヤ修正の検証戦略

- View 内のハードコード値（`60.0` リテラル等）や `EnvironmentValues` の挙動は、ViewModel/Color変換の単体テストではカバーできない（リテラルをrevertしてもテストPASSしてしまう盲点）
- そのため View 層修正は**手動 walk-through が必須**。PR description に「マージ前手動確認チェックリスト」を明記する
- `simctl` には `tap` がないため、設定変更や tutorial スキップを伴う自動検証は不可。`xcrun simctl io ... screenshot` で起動確認＋クラッシュなしの確認までが自動化の上限
- 永続化された GameSettings は SwiftData なので `UserDefaults trick`（`xcrun simctl spawn ... defaults write`）が効かない点に注意

### Git運用

- `main` には直接コミットしない。`feature/issue-N-pr-X-<topic>` のような名前で feature branch を切る
- `build/` と `DerivedData/` は `.gitignore` 済み（`xcodebuild -derivedDataPath build/DerivedData` 利用時の生成物）
- PR タイトルは `fix:` / `feat:` / `chore:` プレフィックス、本文に Test plan の手動確認チェックリストを含める
