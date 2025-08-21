# 開発ガイドライン

## 基本原則
1. **日本語でのコミュニケーション**: 全ての回答、コメント、ドキュメントは日本語
2. **小さなタスクサイズ**: tasks.mdに則り、イテレーティブに開発進行
3. **品質第一**: 各タスク終了時にビルド・テストの確認とコミット実行

## 設計パターン
### MVVM + Clean Architecture
- **View**: SwiftUI + Gesture Recognition
- **ViewModel**: @Observable + Business Logic
- **Service**: Domain Logic (Bubble, Audio, Effect)
- **Repository**: Data Access Layer
- **Model**: SwiftData Models

### 依存性注入
```swift
// プロトコル定義
protocol BubbleService {
    func createBubble(at position: CGPoint) -> Bubble
}

// ViewModelでの使用
@Observable
class GameViewModel {
    private let bubbleService: BubbleService
    
    init(bubbleService: BubbleService) {
        self.bubbleService = bubbleService
    }
}
```

## パフォーマンス最適化戦略
### メモリ管理
- **オブジェクトプール**: 大量のBubbleオブジェクト管理
- **ContiguousArray**: 連続メモリ配置でキャッシュ効率向上
- **Weak Reference**: メモリリーク防止

### レンダリング最適化
- **CADisplayLink**: 60FPSゲームループ
- **座標変換最小化**: ビュー更新の効率化
- **アニメーション最適化**: Core Animationの活用

## テスト戦略
### テストレベル
1. **Unit Tests**: ViewModel・Service層のロジックテスト
2. **Integration Tests**: SwiftDataとRepository層のテスト
3. **Performance Tests**: 60FPS維持・メモリ使用量テスト
4. **UI Tests**: タップ応答性・画面遷移テスト

### SwiftTesting使用例
```swift
@Suite("Bubble Service Tests")
struct BubbleServiceTests {
    @Test("衝突判定の正確性")
    func testCollisionDetection() {
        let service = BubbleServiceImpl()
        let bubble = Bubble(position: CGPoint(x: 100, y: 100), radius: 30)
        
        let hit = service.checkCollision(at: CGPoint(x: 105, y: 105), bubbles: [bubble])
        #expect(hit != nil)
    }
}
```

## エラーハンドリング指針
### 音響システム
- ファイル読み込み失敗 → サイレントモード
- 再生エラー → 代替音源使用

### パフォーマンス
- FPS低下 → シャボン玉数自動調整
- メモリ不足 → エフェクト品質低下

### データ永続化
- 保存失敗 → ローカルキャッシュ使用
- 読み込み失敗 → デフォルト値適用

## アクセシビリティ要件
- **VoiceOver**: 全UIコンポーネントのラベル付与
- **色覚対応**: 高コントラストモード・色覚異常者配慮
- **音声案内**: スコア・時間の音声フィードバック

## リリース準備
- App Store審査ガイドライン準拠
- iOS Deployment Target: 17.0以上
- アプリアイコン・スプラッシュ画面実装
- プライバシー情報・メタデータ整備