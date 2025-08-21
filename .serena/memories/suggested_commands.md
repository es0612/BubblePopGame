# 開発時の推奨コマンド

## Xcodeプロジェクト操作
```bash
# Xcodeプロジェクトを開く
open app/BubblePopGame.xcodeproj
```

## ビルドコマンド
```bash
# コマンドラインビルド（デバッグ）
xcodebuild -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Debug build

# リリースビルド
xcodebuild -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Release build

# クリーンビルド
xcodebuild clean -project app/BubblePopGame.xcodeproj -scheme BubblePopGame
```

## テスト実行
```bash
# テスト実行（iPhone 16シミュレーター）
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'

# 特定のテストクラスのみ実行
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:BubblePopGameTests/BubbleServiceTests

# カバレッジ付きテスト
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -enableCodeCoverage YES
```

## タスク完了時のワークフロー
1. ビルドの確認
2. テストの実行と確認
3. gitでのコミット

## システムコマンド（Darwin用）
- `ls`: ディレクトリリスト表示
- `find`: ファイル検索
- `grep`: テキスト検索  
- `git`: バージョン管理
- `cd`: ディレクトリ移動

## パフォーマンス監視
```bash
# Instrumentsでのプロファイリング
instruments -t "Time Profiler" -D ./profile_results.trace -l 30000 ./app/DerivedData/BubblePopGame/Build/Products/Debug-iphonesimulator/BubblePopGame.app
```