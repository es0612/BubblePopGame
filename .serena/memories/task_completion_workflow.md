# タスク完了時のワークフロー

## 必須実行手順
各タスク終了時に以下を順番に実行すること：

### 1. ビルド確認
```bash
# デバッグビルドの実行
xcodebuild -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -configuration Debug build
```
- エラーなくビルドが完了することを確認
- 警告があれば可能な限り修正

### 2. テスト実行と確認
```bash
# 全テストの実行
xcodebuild test -project app/BubblePopGame.xcodeproj -scheme BubblePopGame -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```
- 全テストがパスすることを確認
- 失敗したテストがあれば修正

### 3. 品質チェック（該当する場合）
- Lintツールがある場合は実行
- コードレビューの実施
- パフォーマンステストの確認

### 4. gitコミット
```bash
# 変更状況の確認
git status
git diff

# ファイルをステージング
git add .

# コミット実行
git commit -m "適切なコミットメッセージ"
```

## コミットメッセージ規約
- 日本語で記述
- 何を実装/修正したかを簡潔に記述
- 例: 
  - "GameViewModel実装: 基本的なゲーム状態管理機能追加"
  - "シャボン玉衝突判定修正: 精度向上とパフォーマンス最適化"
  - "SwiftDataモデル実装: GameScore永続化機能追加"

## 開発サイクル
1. **tasks.mdから次のタスクを選択**
2. **小さなイテレーションで実装** （1〜2時間程度）
3. **上記ワークフローを実行**
4. **requirements.mdとdesign.mdとの整合性確認**
5. **次のタスクへ進む**

## 注意事項
- ビルドやテストが失敗した状態でコミットしない
- 大きなタスクは小さく分割して進める
- パフォーマンス要件（60FPS）を常に意識
- アクセシビリティ対応を忘れない