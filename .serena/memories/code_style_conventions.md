# コードスタイルと開発規約

## 言語とコミュニケーション
- **全て日本語で回答・コミュニケーション**
- コメントも日本語で記述
- 変数名・関数名は英語、コメント・ドキュメントは日本語

## コードスタイル
### ネーミング規則
- クラス名: PascalCase (例: `GameViewModel`, `BubbleService`)
- プロパティ・メソッド名: camelCase (例: `gameState`, `startGame()`)
- 定数: camelCase (例: `maxBubbleCount`)
- 列挙型: PascalCase + case is camelCase (例: `GameState.playing`)

### SwiftUI/SwiftData固有
- **@Observable マクロ**: ViewModelクラスに必須適用
- **@Model マクロ**: SwiftDataモデルに必須適用
- **@State**: SwiftUIビューの状態管理
- **@Environment**: SwiftDataのModelContextなど

### ファイル・クラス構成
- 1ファイル1クラス原則
- ビュー・ビューモデル・サービス・モデルの分離
- プロトコル指向プログラミングの活用

## アーキテクチャ規約
### MVVM実装パターン
```swift
// ViewModel例
@Observable
class GameViewModel {
    var gameState: GameState = .menu
    var score: Int = 0
    
    private let bubbleService: BubbleService
    
    init(bubbleService: BubbleService) {
        self.bubbleService = bubbleService
    }
}

// SwiftDataモデル例
@Model
class GameScore {
    var id: UUID
    var score: Int
    var playDate: Date
    
    init(score: Int, playDate: Date) {
        self.id = UUID()
        self.score = score
        self.playDate = playDate
    }
}
```

### エラーハンドリング
- `Result`型やtry-catchの適切な使用
- フォールバック処理の実装（音響エラー時のサイレントモードなど）

## パフォーマンス規約
- **60FPS維持を最優先**
- オブジェクトプールパターンでメモリ効率化
- CADisplayLinkによる効率的なゲームループ
- 大量データはContiguousArrayを使用

## テスト規約
- SwiftTestingフレームワーク使用
- `@Test`アノテーションでテスト関数定義
- `#expect`マクロでアサーション
- モックオブジェクトの活用

## アクセシビリティ
- 全てのUIコンポーネントにaccessibilityLabelを付与
- VoiceOver対応の実装
- 高コントラストモード対応