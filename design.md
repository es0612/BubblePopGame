# 設計書

## 概要

シャボン玉消しゲームは、SwiftUI、Observationマクロ、SwiftData、MVVMアーキテクチャを使用したモダンなiOSアプリです。Core Animationによる滑らかなアニメーション、AVAudioEngineによる高品質音響効果、UIKitの触覚フィードバックを組み合わせて、没入感のあるゲーム体験を提供します。SwiftTestingフレームワークによる包括的なテストカバレッジも含みます。

## アーキテクチャ

### MVVM構成

```
┌─────────────────────────────────────────────────────────────┐
│                        Views (SwiftUI)                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  MenuView   │  │  GameView   │  │ SettingsView│         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    ViewModels (@Observable)                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │MenuViewModel│  │GameViewModel│  │SettingsVM   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Models & Services                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │BubbleSystem │  │AudioService │  │EffectService│         │
│  │             │  │             │  │             │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Data Layer (SwiftData)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ GameScore   │  │GameSettings │  │ Statistics  │         │
│  │   Model     │  │   Model     │  │   Model     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### レイヤー構造

1. **View層**: SwiftUI Views + Gesture Recognition
2. **ViewModel層**: @Observable ViewModels + Business Logic
3. **Service層**: Audio, Effect, Game Logic Services
4. **Model層**: SwiftData Models + Core Data Types
5. **Repository層**: Data Access & Persistence

## コンポーネントとインターフェース

### 1. ViewModels (@Observable)

```swift
@Observable
class GameViewModel {
    var gameState: GameState = .menu
    var score: Int = 0
    var timeRemaining: Double = 60.0
    var bubbles: [Bubble] = []
    
    private let bubbleService: BubbleService
    private let audioService: AudioService
    private let effectService: EffectService
    private let scoreRepository: ScoreRepository
    
    init(bubbleService: BubbleService, audioService: AudioService, 
         effectService: EffectService, scoreRepository: ScoreRepository)
    
    func startGame()
    func pauseGame()
    func resumeGame()
    func endGame()
    func handleBubbleTap(at location: CGPoint)
}

@Observable
class MenuViewModel {
    var showSettings: Bool = false
    var highScores: [GameScore] = []
    
    private let scoreRepository: ScoreRepository
    
    func loadHighScores()
    func navigateToGame()
    func showSettingsView()
}

@Observable
class SettingsViewModel {
    var gameSettings: GameSettings
    
    private let settingsRepository: SettingsRepository
    
    func saveSettings()
    func resetToDefaults()
    func toggleSound()
    func toggleVibration()
}
```

### 2. Services (Business Logic)

```swift
protocol BubbleService {
    func createBubble(at position: CGPoint, type: BubbleType) -> Bubble
    func updateBubbles(_ bubbles: inout [Bubble])
    func checkCollision(at point: CGPoint, in bubbles: [Bubble]) -> Bubble?
    func generateRandomBubbles(count: Int, screenBounds: CGRect) -> [Bubble]
}

class BubbleServiceImpl: BubbleService {
    private let screenBounds: CGRect
    private var bubblePool: [Bubble] = []
    
    func createBubble(at position: CGPoint, type: BubbleType) -> Bubble
    func updateBubbles(_ bubbles: inout [Bubble])
    func checkCollision(at point: CGPoint, in bubbles: [Bubble]) -> Bubble?
    func generateRandomBubbles(count: Int, screenBounds: CGRect) -> [Bubble]
}

protocol AudioService {
    func playBGM(name: String, loop: Bool)
    func playSFX(name: String)
    func setVolume(_ volume: Float)
    func toggleMute()
}

class AudioServiceImpl: AudioService {
    private var audioEngine: AVAudioEngine
    private var bgmPlayer: AVAudioPlayerNode
    private var sfxPlayers: [String: AVAudioPlayerNode]
    
    func playBGM(name: String, loop: Bool)
    func playSFX(name: String)
    func setVolume(_ volume: Float)
    func toggleMute()
}

protocol EffectService {
    func createPopEffect(at position: CGPoint, color: Color)
    func triggerHapticFeedback(intensity: UIImpactFeedbackGenerator.FeedbackStyle)
}

class EffectServiceImpl: EffectService {
    private let hapticFeedback: UIImpactFeedbackGenerator
    
    func createPopEffect(at position: CGPoint, color: Color)
    func triggerHapticFeedback(intensity: UIImpactFeedbackGenerator.FeedbackStyle)
}
```

### 3. SwiftUI Views

```swift
struct ContentView: View {
    @State private var gameViewModel: GameViewModel
    @State private var menuViewModel: MenuViewModel
    
    var body: some View {
        NavigationStack {
            switch gameViewModel.gameState {
            case .menu:
                MenuView(viewModel: menuViewModel, gameViewModel: gameViewModel)
            case .playing, .paused:
                GameView(viewModel: gameViewModel)
            case .gameOver:
                GameOverView(viewModel: gameViewModel)
            case .settings:
                SettingsView()
            }
        }
    }
}

struct GameView: View {
    let viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.1)], 
                          startPoint: .top, endPoint: .bottom)
            
            // Bubbles
            ForEach(viewModel.bubbles) { bubble in
                BubbleView(bubble: bubble)
                    .onTapGesture {
                        viewModel.handleBubbleTap(at: bubble.position)
                    }
            }
            
            // HUD
            VStack {
                HStack {
                    Text("Score: \(viewModel.score)")
                    Spacer()
                    Text("Time: \(Int(viewModel.timeRemaining))")
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            viewModel.startGame()
        }
    }
}

struct BubbleView: View {
    let bubble: Bubble
    
    var body: some View {
        Circle()
            .fill(bubble.color.opacity(bubble.alpha))
            .frame(width: bubble.radius * 2, height: bubble.radius * 2)
            .position(bubble.position)
            .scaleEffect(bubble.isPopping ? 0 : 1)
            .animation(.easeOut(duration: 0.3), value: bubble.isPopping)
    }
}
```

## データモデル

### SwiftData Models

```swift
import SwiftData

@Model
class GameScore {
    var id: UUID
    var score: Int
    var bubblesPopped: Int
    var accuracy: Double
    var gameMode: GameMode
    var playDate: Date
    var gameDuration: TimeInterval
    
    init(score: Int, bubblesPopped: Int, accuracy: Double, 
         gameMode: GameMode, playDate: Date, gameDuration: TimeInterval) {
        self.id = UUID()
        self.score = score
        self.bubblesPopped = bubblesPopped
        self.accuracy = accuracy
        self.gameMode = gameMode
        self.playDate = playDate
        self.gameDuration = gameDuration
    }
}

@Model
class GameSettings {
    var id: UUID
    var bubbleCount: Int
    var gameTime: Double
    var bubbleMinRadius: Double
    var bubbleMaxRadius: Double
    var animationSpeed: Double
    var soundEnabled: Bool
    var vibrationEnabled: Bool
    var gameMode: GameMode
    
    init() {
        self.id = UUID()
        self.bubbleCount = 20
        self.gameTime = 60.0
        self.bubbleMinRadius = 30.0
        self.bubbleMaxRadius = 60.0
        self.animationSpeed = 1.0
        self.soundEnabled = true
        self.vibrationEnabled = true
        self.gameMode = .normal
    }
}

@Model
class GameStatistics {
    var id: UUID
    var totalGamesPlayed: Int
    var totalBubblesPopped: Int
    var totalPlayTime: TimeInterval
    var averageScore: Double
    var bestScore: Int
    var lastPlayDate: Date
    
    init() {
        self.id = UUID()
        self.totalGamesPlayed = 0
        self.totalBubblesPopped = 0
        self.totalPlayTime = 0
        self.averageScore = 0
        self.bestScore = 0
        self.lastPlayDate = Date()
    }
}
```

### Core Data Types

```swift
enum GameState: String, CaseIterable {
    case menu = "menu"
    case playing = "playing"
    case paused = "paused"
    case gameOver = "gameOver"
    case settings = "settings"
}

enum GameMode: String, CaseIterable, Codable {
    case normal = "normal"
    case numbered = "numbered"
}

enum BubbleType: String, CaseIterable {
    case normal = "normal"
    case numbered = "numbered"
}

struct Bubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var radius: CGFloat
    var type: BubbleType
    var number: Int?
    var color: Color
    var alpha: Double
    var animationPhase: Double
    var isPopping: Bool = false
}
```

### Repository Protocols

```swift
protocol ScoreRepository {
    func saveScore(_ score: GameScore) async throws
    func fetchHighScores(limit: Int) async throws -> [GameScore]
    func fetchScoresByMode(_ mode: GameMode) async throws -> [GameScore]
    func deleteScore(_ score: GameScore) async throws
}

protocol SettingsRepository {
    func saveSettings(_ settings: GameSettings) async throws
    func fetchSettings() async throws -> GameSettings?
    func resetToDefaults() async throws
}

protocol StatisticsRepository {
    func updateStatistics(with score: GameScore) async throws
    func fetchStatistics() async throws -> GameStatistics?
    func resetStatistics() async throws
}
```

## エラーハンドリング

### 1. 音響エラー

```swift
enum AudioError: Error {
    case loadFailed(String)
    case playbackFailed(String)
    case engineNotStarted
    case fileNotFound(String)
}

class AudioErrorHandler {
    func handleLoadError(_ audioName: String, error: Error) {
        print("Audio load failed for \(audioName): \(error)")
        // フォールバック: サイレントモードに切り替え
    }
    
    func handlePlaybackError(_ audioName: String, error: Error) {
        print("Audio playback failed for \(audioName): \(error)")
        // 代替音源の再生を試行
    }
    
    func fallbackToSilentMode() {
        // 音響なしでゲーム続行
    }
}
```

### 2. パフォーマンスエラー

```swift
class PerformanceMonitor: ObservableObject {
    @Published var currentFPS: Double = 60.0
    @Published var isLowPerformance: Bool = false
    
    private var frameCount: Int = 0
    private var lastTimestamp: CFTimeInterval = 0
    
    func monitorFPS() {
        // CADisplayLinkでFPS監視
    }
    
    func adjustBubbleCount() {
        if currentFPS < 30 {
            // シャボン玉数を減らす
            isLowPerformance = true
        }
    }
    
    func reduceEffectQuality() {
        // エフェクト品質を下げる
    }
}
```

### 3. SwiftData エラー

```swift
enum DataError: Error {
    case saveFailed
    case fetchFailed
    case deleteFailed
    case modelContextNotFound
}

class DataErrorHandler {
    func handleSaveError(_ error: Error) {
        print("Data save failed: \(error)")
        // ローカルキャッシュに保存
    }
    
    func handleFetchError(_ error: Error) {
        print("Data fetch failed: \(error)")
        // デフォルト値を返す
    }
}
```

## テスト戦略

### 1. SwiftTesting ユニットテスト

```swift
import Testing
@testable import BubblePopGame

@Suite("Bubble Service Tests")
struct BubbleServiceTests {
    
    @Test("Bubble creation with valid parameters")
    func testBubbleCreation() {
        let service = BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
        let bubble = service.createBubble(at: CGPoint(x: 100, y: 100), type: .normal)
        
        #expect(bubble.position.x == 100)
        #expect(bubble.position.y == 100)
        #expect(bubble.type == .normal)
    }
    
    @Test("Collision detection accuracy")
    func testCollisionDetection() {
        let service = BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
        let bubbles = [
            Bubble(id: UUID(), position: CGPoint(x: 100, y: 100), 
                   velocity: CGVector.zero, radius: 30, type: .normal, 
                   number: nil, color: .blue, alpha: 1.0, animationPhase: 0)
        ]
        
        let hitBubble = service.checkCollision(at: CGPoint(x: 105, y: 105), in: bubbles)
        #expect(hitBubble != nil)
        
        let missBubble = service.checkCollision(at: CGPoint(x: 200, y: 200), in: bubbles)
        #expect(missBubble == nil)
    }
}

@Suite("Game ViewModel Tests")
struct GameViewModelTests {
    
    @Test("Game state transitions")
    func testGameStateTransitions() {
        let viewModel = GameViewModel(
            bubbleService: MockBubbleService(),
            audioService: MockAudioService(),
            effectService: MockEffectService(),
            scoreRepository: MockScoreRepository()
        )
        
        #expect(viewModel.gameState == .menu)
        
        viewModel.startGame()
        #expect(viewModel.gameState == .playing)
        
        viewModel.pauseGame()
        #expect(viewModel.gameState == .paused)
        
        viewModel.endGame()
        #expect(viewModel.gameState == .gameOver)
    }
}
```

### 2. SwiftData 統合テスト

```swift
@Suite("SwiftData Integration Tests")
struct SwiftDataTests {
    
    @Test("Score persistence")
    func testScorePersistence() async throws {
        let container = try ModelContainer(for: GameScore.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repository = ScoreRepositoryImpl(modelContainer: container)
        
        let score = GameScore(score: 100, bubblesPopped: 50, accuracy: 0.8, 
                             gameMode: .normal, playDate: Date(), gameDuration: 60.0)
        
        try await repository.saveScore(score)
        let fetchedScores = try await repository.fetchHighScores(limit: 10)
        
        #expect(fetchedScores.count == 1)
        #expect(fetchedScores.first?.score == 100)
    }
    
    @Test("Settings persistence")
    func testSettingsPersistence() async throws {
        let container = try ModelContainer(for: GameSettings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repository = SettingsRepositoryImpl(modelContainer: container)
        
        let settings = GameSettings()
        settings.bubbleCount = 25
        settings.soundEnabled = false
        
        try await repository.saveSettings(settings)
        let fetchedSettings = try await repository.fetchSettings()
        
        #expect(fetchedSettings?.bubbleCount == 25)
        #expect(fetchedSettings?.soundEnabled == false)
    }
}
```

### 3. パフォーマンステスト

```swift
@Suite("Performance Tests")
struct PerformanceTests {
    
    @Test("Bubble update performance", .timeLimit(.seconds(1)))
    func testBubbleUpdatePerformance() {
        let service = BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
        var bubbles = service.generateRandomBubbles(count: 100, screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<60 { // 60フレーム分のシミュレーション
            service.updateBubbles(&bubbles)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        #expect(duration < 1.0) // 1秒以内で完了すること
    }
}
```

### 4. UI テスト

```swift
@Suite("UI Tests")
struct UITests {
    
    @Test("Menu navigation")
    func testMenuNavigation() {
        // SwiftUI Preview テストまたは実機テスト
        // タップ操作の応答性テスト
        // 画面遷移の確認
    }
    
    @Test("Game interaction")
    func testGameInteraction() {
        // シャボン玉タップの応答性テスト
        // スコア更新の確認
        // タイマー動作の検証
    }
}
```

## 実装上の考慮事項

### パフォーマンス最適化

```swift
// オブジェクトプールパターンの実装
class BubblePool {
    private var availableBubbles: [Bubble] = []
    private let maxPoolSize: Int = 100
    
    func getBubble() -> Bubble {
        if availableBubbles.isEmpty {
            return createNewBubble()
        }
        return availableBubbles.removeLast()
    }
    
    func returnBubble(_ bubble: Bubble) {
        if availableBubbles.count < maxPoolSize {
            bubble.reset()
            availableBubbles.append(bubble)
        }
    }
}

// CADisplayLinkによる効率的なゲームループ
class GameLoop {
    private var displayLink: CADisplayLink?
    
    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func update() {
        // 60FPS でのゲーム状態更新
    }
}
```

### デバイス対応

```swift
// 画面サイズ適応
struct AdaptiveGameView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            GameView(screenSize: geometry.size)
                .scaleEffect(scaleFactor(for: geometry.size))
        }
    }
    
    private func scaleFactor(for size: CGSize) -> CGFloat {
        let baseWidth: CGFloat = 375 // iPhone標準幅
        return min(size.width / baseWidth, 1.5) // 最大1.5倍まで
    }
}

// デバイス性能に応じた調整
class DeviceCapabilityManager {
    static let shared = DeviceCapabilityManager()
    
    var maxBubbleCount: Int {
        if ProcessInfo.processInfo.processorCount >= 6 {
            return 30 // 高性能デバイス
        } else {
            return 20 // 標準デバイス
        }
    }
    
    var enableParticleEffects: Bool {
        return ProcessInfo.processInfo.physicalMemory > 2_000_000_000 // 2GB以上
    }
}
```

### アクセシビリティ

```swift
struct AccessibleBubbleView: View {
    let bubble: Bubble
    let onTap: () -> Void
    
    var body: some View {
        Circle()
            .fill(bubble.color.opacity(bubble.alpha))
            .frame(width: bubble.radius * 2, height: bubble.radius * 2)
            .position(bubble.position)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("タップしてシャボン玉を割る")
            .accessibilityAddTraits(.isButton)
            .onTapGesture {
                onTap()
            }
    }
    
    private var accessibilityLabel: String {
        if let number = bubble.number {
            return "数字\(number)のシャボン玉"
        } else {
            return "シャボン玉"
        }
    }
}

// VoiceOver対応
class AccessibilityManager {
    static func announceScore(_ score: Int) {
        let announcement = "スコア\(score)点"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    static func announceTimeRemaining(_ time: Int) {
        let announcement = "残り時間\(time)秒"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

// 色覚異常者への配慮
extension Color {
    static let bubbleColors: [Color] = [
        .blue,      // 青
        .orange,    // オレンジ（赤の代替）
        .green,     // 緑
        .purple,    // 紫
        .yellow     // 黄色
    ]
    
    // 高コントラスト対応
    static func bubbleColor(for type: BubbleType, highContrast: Bool = false) -> Color {
        if highContrast {
            return type == .normal ? .white : .black
        } else {
            return bubbleColors.randomElement() ?? .blue
        }
    }
}
```

### メモリ管理

```swift
// WeakReferenceを使用したメモリリーク防止
class GameCoordinator {
    weak var gameViewModel: GameViewModel?
    weak var audioService: AudioService?
    
    deinit {
        // リソースのクリーンアップ
        audioService?.stopAllSounds()
    }
}

// 大量オブジェクトの効率的な管理
struct BubbleCollection {
    private var bubbles: ContiguousArray<Bubble> = []
    
    mutating func addBubble(_ bubble: Bubble) {
        bubbles.append(bubble)
    }
    
    mutating func removeBubbles(where predicate: (Bubble) -> Bool) {
        bubbles.removeAll(where: predicate)
    }
}
```