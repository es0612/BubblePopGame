# アーキテクチャとディレクトリ構造

## MVVMアーキテクチャ構成
- **View層**: SwiftUI Views + Gesture Recognition
- **ViewModel層**: @Observable ViewModels + Business Logic  
- **Service層**: Audio, Effect, Game Logic Services
- **Model層**: SwiftData Models + Core Data Types
- **Repository層**: Data Access & Persistence

## ディレクトリ構造
```
app/BubblePopGame/
├── BubblePopGameApp.swift          # アプリエントリーポイント
├── ContentView.swift               # メインビュー
├── Views/                          # SwiftUIビュー
│   ├── Menu/                       # メニュー関連
│   ├── Game/                       # ゲーム画面関連
│   ├── GameOver/                   # ゲームオーバー画面
│   ├── HighScore/                  # ハイスコア画面
│   ├── Effects/                    # エフェクト関連
│   ├── SettingsView.swift          # 設定画面
│   ├── TutorialView.swift          # チュートリアル
│   └── LaunchScreenView.swift      # 起動画面
├── ViewModels/                     # @Observable ViewModels
│   ├── GameViewModel.swift
│   ├── MenuViewModel.swift
│   └── SettingsViewModel.swift
├── Services/                       # ビジネスロジック
│   ├── BubbleService.swift         # シャボン玉ロジック
│   ├── AudioService.swift          # 音響システム
│   ├── EffectService.swift         # エフェクト処理
│   ├── PerformanceService.swift    # パフォーマンス監視
│   └── DeviceService.swift         # デバイス情報
├── Models/                         # SwiftDataモデル
│   ├── GameScore.swift
│   ├── GameSettings.swift
│   ├── GameStatistics.swift
│   ├── Bubble.swift
│   ├── GameState.swift
│   ├── GameMode.swift
│   └── BubbleType.swift
├── Repositories/                   # データアクセス層
│   ├── ScoreRepository.swift
│   ├── SettingsRepository.swift
│   └── StatisticsRepository.swift
├── Utils/                          # ユーティリティ
├── Assets.xcassets/                # アセット
└── Bgm/                           # BGMファイル
```

## 主要コンポーネントの役割
- **GameViewModel**: ゲーム状態管理、スコア処理、タイマー管理
- **BubbleService**: シャボン玉生成・更新・衝突判定ロジック
- **AudioService**: BGM・効果音再生（AVAudioEngine使用）
- **EffectService**: 破裂エフェクト・触覚フィードバック
- **SwiftDataモデル**: ゲームスコア・設定・統計の永続化