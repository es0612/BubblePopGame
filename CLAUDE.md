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

# コマンドラインビルド
xcodebuild -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Debug build

# テスト実行
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'

# クリーンビルド
xcodebuild clean -project app/BubblePopGame.xcodeproj -scheme BubblePopGame
```

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
