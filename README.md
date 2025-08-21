# 🫧 シャボン玉消しゲーム / Bubble Pop Game

[![iOS](https://img.shields.io/badge/iOS-17.0+-007AFF.svg?style=flat&logo=iOS&logoColor=white)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-FA7343.svg?style=flat&logo=swift&logoColor=white)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-027DFF.svg?style=flat&logo=swift&logoColor=white)](https://developer.apple.com/swiftui/)
[![SwiftData](https://img.shields.io/badge/SwiftData-5.0-027DFF.svg?style=flat&logo=swift&logoColor=white)](https://developer.apple.com/swiftdata/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![VoiceOver](https://img.shields.io/badge/VoiceOver-✓-green.svg)](docs/accessibility-guide.md)

美しいシャボン玉を指先で消す心癒されるカジュアルゲーム。完全なアクセシビリティ対応で、誰もが楽しめるインクルーシブデザインを実現。

A soothing casual game where you pop beautiful soap bubbles with your fingertips. Fully accessible design that everyone can enjoy.

## 📱 主な特徴 / Key Features

### 🎮 ゲームプレイ / Gameplay
- **通常モード**: 制限時間内でシャボン玉を自由に消してスコアを競う
- **数字順モード**: 1から順番に数字のシャボン玉を消すチャレンジ
- **カスタマイズ設定**: 制限時間・シャボン玉数を自由に調整

### 🌟 アクセシビリティ / Accessibility
- **VoiceOver完全対応**: 音声ガイドでゲームを楽しめる
- **高コントラスト表示**: 視認性を向上
- **Dynamic Type対応**: 文字サイズを自由に調整
- **色覚配慮**: 色覚多様性に対応したカラーシステム

### 🎵 音響・エフェクト / Audio & Effects
- **3曲のオリジナルBGM**: 癒し系楽曲を搭載
- **リアルなシャボン玉破裂音**: 没入感のある効果音
- **美しいパーティクル効果**: 破裂時の視覚エフェクト
- **触覚フィードバック**: タッチに応じた振動

### 🔒 プライバシー重視 / Privacy First
- **個人情報収集なし**: ユーザーデータを一切収集しない
- **ローカル保存のみ**: 全データはデバイス内で完結
- **外部通信なし**: インターネット接続不要

## 🚀 クイックスタート / Quick Start

### 必要条件 / Requirements
- iOS 17.0以降 / iOS 17.0 or later
- Xcode 15.0以降 / Xcode 15.0 or later
- Swift 6.0

### ビルド手順 / Build Instructions

```bash
# リポジトリをクローン / Clone repository
git clone https://github.com/your-username/BubblePopGame.git
cd BubblePopGame

# Xcodeでプロジェクトを開く / Open project in Xcode
open app/BubblePopGame.xcodeproj

# コマンドラインビルド / Command line build
xcodebuild -project app/BubblePopGame.xcodeproj -scheme BubblePopGame build

# テスト実行 / Run tests
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

## 🏗️ アーキテクチャ / Architecture

### MVVMアーキテクチャ構成 / MVVM Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SwiftUI       │    │   @Observable   │    │   SwiftData     │
│   Views         │◄──►│   ViewModels    │◄──►│   Models        │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Gesture       │    │   Business      │    │   Repository    │
│   Recognition   │    │   Logic         │    │   Layer         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### ディレクトリ構造 / Directory Structure

```
app/BubblePopGame/
├── 📱 アプリエントリーポイント / App Entry Points
│   ├── BubblePopGameApp.swift      # メインアプリ / Main app
│   └── ContentView.swift           # ルートビュー / Root view
│
├── 🎨 ビューレイヤー / View Layer
│   ├── Views/
│   │   ├── Menu/                   # メニュー画面 / Menu screens
│   │   ├── Game/                   # ゲーム画面 / Game screens
│   │   ├── GameOver/               # ゲームオーバー / Game over
│   │   ├── HighScore/              # ハイスコア / High scores
│   │   ├── Effects/                # エフェクト / Visual effects
│   │   ├── SettingsView.swift      # 設定画面 / Settings
│   │   ├── TutorialView.swift      # チュートリアル / Tutorial
│   │   └── LaunchScreenView.swift  # 起動画面 / Launch screen
│   └── ViewModels/                 # ビューモデル / ViewModels
│       ├── GameViewModel.swift     # ゲーム状態管理 / Game state
│       ├── MenuViewModel.swift     # メニュー管理 / Menu state
│       └── SettingsViewModel.swift # 設定管理 / Settings state
│
├── 🧠 ビジネスロジック / Business Logic
│   └── Services/
│       ├── BubbleService.swift     # シャボン玉ロジック / Bubble logic
│       ├── AudioService.swift      # 音響システム / Audio system
│       ├── EffectService.swift     # エフェクト処理 / Effect handling
│       ├── PerformanceService.swift # パフォーマンス監視 / Performance
│       └── DeviceService.swift     # デバイス情報 / Device info
│
├── 📊 データレイヤー / Data Layer
│   ├── Models/                     # SwiftDataモデル / SwiftData models
│   │   ├── GameScore.swift         # スコアデータ / Score data
│   │   ├── GameSettings.swift      # 設定データ / Settings data
│   │   ├── GameStatistics.swift    # 統計データ / Statistics data
│   │   └── Bubble.swift           # シャボン玉モデル / Bubble model
│   └── Repositories/               # データアクセス / Data access
│       ├── ScoreRepository.swift   # スコア管理 / Score management
│       ├── SettingsRepository.swift # 設定管理 / Settings management
│       └── StatisticsRepository.swift # 統計管理 / Statistics
│
├── 🌍 国際化対応 / Internationalization
│   ├── ja.lproj/                   # 日本語リソース / Japanese resources
│   ├── en.lproj/                   # 英語リソース / English resources
│   └── Base.lproj/                 # 基本リソース / Base resources
│
├── 🎵 アセット / Assets
│   ├── Assets.xcassets/            # 画像アセット / Image assets
│   └── Bgm/                       # BGMファイル / BGM files
│
└── 🧪 テスト / Tests
    ├── BubblePopGameTests/         # ユニットテスト / Unit tests
    └── BubblePopGameUITests/       # UIテスト / UI tests
```

## 🧪 テスト / Testing

### テストスイート構成 / Test Suite

- **BasicPropertyTests**: SwiftDataモデルの基本テスト
- **SimpleGameViewModelTests**: GameViewModelの動作テスト
- **BubbleServiceTests**: シャボン玉ロジック・衝突判定テスト
- **SimpleSwiftDataTests**: データ永続化テスト
- **SimplePerformanceTests**: 60FPS維持確認テスト

### テスト実行 / Running Tests

```bash
# 全テスト実行 / Run all tests
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'

# 特定のテスト実行 / Run specific test
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:BubblePopGameTests/BubbleServiceTests
```

## 🚀 App Store リリース / App Store Release

### リリース準備文書 / Release Documentation

プロジェクトには App Store リリースに必要な全文書が含まれています：

| 文書 / Document | 説明 / Description |
|---|---|
| [📱 App Store メタデータ](docs/app-store-metadata.md) | Store Connect対応の完全メタデータ |
| [📄 プライバシーポリシー](docs/privacy-policy.md) | 日英対応プライバシーポリシー |
| [📄 利用規約](docs/terms-of-service.md) | 日英対応利用規約 |
| [🌟 アクセシビリティガイド](docs/accessibility-guide.md) | VoiceOver等詳細ガイド |
| [📚 ユーザーサポート](docs/support-documentation.md) | 包括的サポートドキュメント |
| [📢 マーケティング資料](docs/marketing-materials.md) | 総合マーケティング戦略 |
| [🎯 ASO戦略](docs/app-store-optimization.md) | App Store最適化戦略 |
| [📝 リリースノート](docs/release-notes-templates.md) | リリースノートテンプレート |

### リリースプロセス / Release Process

1. **コード品質確認** / Code Quality Check
   ```bash
   xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame
   xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame
   ```

2. **アーカイブ作成** / Create Archive
   ```bash
   xcodebuild archive -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -archivePath BubblePopGame.xcarchive
   ```

3. **App Store Connect アップロード** / Upload to App Store Connect
   ```bash
   xcodebuild -exportArchive -archivePath BubblePopGame.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath ./
   ```

## 🌟 主要技術スタック / Technology Stack

| 技術 / Technology | 用途 / Purpose | バージョン / Version |
|---|---|---|
| **SwiftUI** | UI フレームワーク / UI Framework | 6.0 |
| **SwiftData** | データ永続化 / Data Persistence | 2.0 |
| **AVAudioEngine** | 音響システム / Audio System | - |
| **Core Animation** | アニメーション / Animations | - |
| **SwiftTesting** | テストフレームワーク / Testing | 6.0 |
| **UIKit** | 触覚フィードバック / Haptic Feedback | - |

## 🎮 ゲーム仕様 / Game Specifications

### ゲームモード / Game Modes

#### 通常モード / Normal Mode
- 制限時間: 15〜180秒（設定可能）
- シャボン玉数: 10〜50個（設定可能）
- スコアルール: 1個破裂 = 1ポイント

#### 数字順モード / Numbered Mode
- 数字付きシャボン玉（1-10）を順番に破裂
- 正解時: 2倍ポイント
- 誤答時: 時間ペナルティ（-3秒）
- プログレッシブ難易度対応

### パフォーマンス要件 / Performance Requirements

- **フレームレート**: 60 FPS維持
- **タッチ応答**: 100ms以内
- **メモリ効率**: オブジェクトプール使用
- **デバイス対応**: 性能に応じた動的調整

### アクセシビリティ対応 / Accessibility Features

- **VoiceOver**: 完全音声ガイド対応
- **Dynamic Type**: 文字サイズ調整
- **高コントラスト**: 視認性向上
- **色覚配慮**: 色覚多様性対応
- **操作支援**: AssistiveTouch対応

## 🔧 開発ガイドライン / Development Guidelines

### コーディング規約 / Coding Standards

- **SwiftUI**: 宣言的UI設計
- **@Observable**: ViewModelには必須
- **SwiftData**: @Modelマクロ使用
- **アクセシビリティ**: 全UI要素に対応
- **国際化**: NSLocalizedString使用

### パフォーマンス最適化 / Performance Optimization

```swift
// オブジェクトプール使用例 / Object Pool Example
class BubbleService: ObservableObject {
    private var bubblePool: [Bubble] = []
    
    func getBubble() -> Bubble {
        return bubblePool.popLast() ?? Bubble()
    }
    
    func recycleBubble(_ bubble: Bubble) {
        bubble.reset()
        bubblePool.append(bubble)
    }
}
```

### アクセシビリティ実装 / Accessibility Implementation

```swift
// VoiceOver対応例 / VoiceOver Example
Button(action: popBubble) {
    Text("🫧")
}
.accessibilityLabel(NSLocalizedString("bubble_button", comment: "Bubble to pop"))
.accessibilityHint(NSLocalizedString("bubble_hint", comment: "Tap to pop bubble"))
.accessibilityValue("\(bubbleNumber)")
```

## 📊 プロジェクト統計 / Project Statistics

- **総ファイル数**: 50+ ファイル
- **総コード行数**: 3,000+ 行
- **テストカバレッジ**: 主要ロジック網羅
- **国際化対応**: 日本語・英語完全対応
- **文書化**: 9つの包括的文書

## 🤝 コントリビューション / Contributing

### 開発環境セットアップ / Development Setup

1. **前提条件確認** / Prerequisites
   - macOS 14.0以降 / macOS 14.0 or later
   - Xcode 15.0以降 / Xcode 15.0 or later
   - Git

2. **リポジトリセットアップ** / Repository Setup
   ```bash
   git clone https://github.com/your-username/BubblePopGame.git
   cd BubblePopGame
   open app/BubblePopGame.xcodeproj
   ```

3. **ビルド確認** / Build Verification
   ```bash
   xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame
   ```

### 貢献方法 / How to Contribute

1. **Issue作成**: 新機能要求やバグレポート
2. **Fork**: リポジトリをフォーク
3. **ブランチ作成**: `feature/your-feature-name`
4. **実装**: 機能実装・テスト追加
5. **プルリクエスト**: 詳細な説明とともに提出

## 📜 ライセンス / License

このプロジェクトは [MIT License](LICENSE) の下でライセンスされています。

This project is licensed under the [MIT License](LICENSE).

## 📞 サポート / Support

### 問い合わせ方法 / Contact Methods

- **GitHub Issues**: バグレポート・機能要求
- **App Store**: アプリページからのお問い合わせ
- **アクセシビリティ**: [accessibility-guide.md](docs/accessibility-guide.md)
- **ユーザーサポート**: [support-documentation.md](docs/support-documentation.md)

### よくある質問 / FAQ

**Q: VoiceOverでゲームをプレイできますか？**  
A: はい、完全にVoiceOverに対応しています。詳細は[アクセシビリティガイド](docs/accessibility-guide.md)をご覧ください。

**Q: 個人情報は収集されますか？**  
A: いいえ、一切収集しません。詳細は[プライバシーポリシー](docs/privacy-policy.md)をご確認ください。

**Q: オフラインでプレイできますか？**  
A: はい、インターネット接続は不要です。すべてのデータはローカルに保存されます。

---

**🫧 美しいシャボン玉の世界をお楽しみください！**  
**🫧 Enjoy the beautiful world of soap bubbles!**

---

*Made with ❤️ using SwiftUI and SwiftData*