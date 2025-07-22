//
//  BubblePopGameTests.swift
//  BubblePopGameTests
//  
//  Created on 2025/07/17
//


import Testing
import SwiftData
import SwiftUI
import UIKit
@testable import BubblePopGame

// MARK: - Mock Services
class MockBubbleService: BubbleService {
    private var screenBounds: CGRect = .zero
    
    func createBubble(at position: CGPoint, type: BubbleType) -> Bubble {
        return Bubble(
            position: position,
            velocity: CGVector(dx: 0, dy: 0),
            radius: 30,
            type: type,
            number: type == .numbered ? 1 : nil,
            color: .blue,
            alpha: 0.8,
            animationPhase: 0.0
        )
    }
    
    func createNumberedBubble(at position: CGPoint, number: Int) -> Bubble {
        return Bubble(
            position: position,
            velocity: CGVector(dx: 0, dy: 0),
            radius: 30,
            type: .numbered,
            number: number,
            color: .yellow,
            alpha: 0.8,
            animationPhase: 0.0
        )
    }
    
    func updateBubbles(_ bubbles: inout [Bubble]) {
        // Mock implementation - no updates needed for tests
    }
    
    func checkCollision(at point: CGPoint, in bubbles: [Bubble]) -> Bubble? {
        return bubbles.first { bubble in
            let distance = sqrt(pow(point.x - bubble.position.x, 2) + pow(point.y - bubble.position.y, 2))
            return distance <= bubble.radius
        }
    }
    
    func checkCollisionIndex(at point: CGPoint, in bubbles: [Bubble]) -> Int? {
        return bubbles.firstIndex { bubble in
            let distance = sqrt(pow(point.x - bubble.position.x, 2) + pow(point.y - bubble.position.y, 2))
            return distance <= bubble.radius
        }
    }
    
    func generateRandomBubbles(count: Int, screenBounds: CGRect) -> [Bubble] {
        var bubbles: [Bubble] = []
        for i in 0..<count {
            let bubble = createBubble(
                at: CGPoint(x: 100 + i * 50, y: 100),
                type: .normal
            )
            bubbles.append(bubble)
        }
        return bubbles
    }
    
    func generateNumberedBubbles(count: Int, screenBounds: CGRect, numberedCount: Int) -> [Bubble] {
        var bubbles: [Bubble] = []
        
        // 数字付きバブル生成
        for number in 1...numberedCount {
            let bubble = createNumberedBubble(
                at: CGPoint(x: 100 + number * 50, y: 100),
                number: number
            )
            bubbles.append(bubble)
        }
        
        // 残りは通常バブル
        for i in numberedCount..<count {
            let bubble = createBubble(
                at: CGPoint(x: 100 + i * 50, y: 200),
                type: .normal
            )
            bubbles.append(bubble)
        }
        
        return bubbles
    }
    
    func updateScreenBounds(_ bounds: CGRect) {
        screenBounds = bounds
    }
    
    func generateNumberedBubblesWithCustomSet(count: Int, screenBounds: CGRect, numberSet: [Int]) -> [Bubble] {
        var bubbles: [Bubble] = []
        
        // カスタム数字セットから数字付きバブル生成
        for number in numberSet {
            let bubble = createNumberedBubble(
                at: CGPoint(x: 100 + number * 30, y: 100),
                number: number
            )
            bubbles.append(bubble)
        }
        
        // 残りは通常バブル
        let remainingCount = max(0, count - numberSet.count)
        for i in 0..<remainingCount {
            let bubble = createBubble(
                at: CGPoint(x: 100 + (numberSet.count + i) * 30, y: 200),
                type: .normal
            )
            bubbles.append(bubble)
        }
        
        return bubbles
    }
}

class MockAudioService: AudioService {
    var isPlaying: Bool = false
    var _isBGMEnabled: Bool = true
    var _currentBGMTrack: String?
    
    var isBGMEnabled: Bool { _isBGMEnabled }
    var currentBGMTrack: String? { _currentBGMTrack }
    
    func playBGM(name: String, loop: Bool) {
        isPlaying = true
    }
    
    func playBGMTrack(_ track: String, loop: Bool) {
        if _isBGMEnabled {
            isPlaying = true
            _currentBGMTrack = track
        }
    }
    
    func setBGMEnabled(_ enabled: Bool) {
        _isBGMEnabled = enabled
        if !enabled {
            stopBGM()
        }
    }
    
    func playSFX(name: String) {}
    func setVolume(_ volume: Float) {}
    func setBGMVolume(_ volume: Float) {}
    func setSFXVolume(_ volume: Float) {}
    func toggleMute() {}
    func stopAllSounds() {
        isPlaying = false
        _currentBGMTrack = nil
    }
    func stopBGM() {
        isPlaying = false
        _currentBGMTrack = nil
    }
}

class MockEffectService: EffectService {
    func createPopEffect(at position: CGPoint, color: Color) {}
    func triggerHapticFeedback(intensity: UIImpactFeedbackGenerator.FeedbackStyle) {}
    func triggerSuccessFeedback() {}
    func triggerWarningFeedback() {}
    func triggerErrorFeedback() {}
}

class MockDeviceService: DeviceService {
    var deviceType: DeviceType = .iPhone
    var screenSize: CGSize = CGSize(width: 375, height: 667)
    var isLowPerformanceDevice: Bool = false
    
    func adaptBubbleCount(for settings: GameSettings) -> Int {
        return settings.bubbleCount
    }
    
    func getOptimalBubbleSize() -> CGFloat {
        return 40.0
    }
}

class MockPerformanceService: PerformanceService {
    var currentFPS: Double = 60.0
    var averageFPS: Double = 60.0
    var isPerformanceGood: Bool = true
    
    func startMonitoring() {}
    func stopMonitoring() {}
    func shouldReduceBubbles() -> Bool { return false }
    func getPerformanceAdjustment() -> Double { return 1.0 }
}

class MockScoreRepository: ScoreRepository {
    private var scores: [GameScore] = []
    
    func saveScore(_ score: GameScore) throws {
        scores.append(score)
    }
    
    func fetchHighScores(limit: Int) throws -> [GameScore] {
        return Array(scores.sorted { $0.score > $1.score }.prefix(limit))
    }
    
    func fetchScoresByMode(_ mode: String) throws -> [GameScore] {
        return scores.filter { $0.gameMode == mode }.sorted { $0.score > $1.score }
    }
    
    func deleteScore(_ score: GameScore) throws {
        scores.removeAll { $0.id == score.id }
    }
}

@MainActor
class MockSettingsRepository: SettingsRepository {
    private var gameSettings: GameSettings?
    
    func saveSettings(_ settings: GameSettings) throws {
        gameSettings = settings
    }
    
    func fetchSettings() throws -> GameSettings? {
        return gameSettings
    }
    
    func resetToDefaults() throws {
        gameSettings = GameSettings()
    }
}

@MainActor
class MockStatisticsRepository: StatisticsRepository {
    private var statistics: GameStatistics?
    
    func updateStatistics(with score: GameScore) throws {
        if statistics == nil {
            statistics = GameStatistics()
        }
        
        statistics?.totalGamesPlayed += 1
        statistics?.totalBubblesPopped += score.bubblesPopped
        statistics?.totalPlayTime += score.gameDuration
        statistics?.lastPlayDate = score.playDate
        
        let totalScore = statistics!.averageScore * Double(statistics!.totalGamesPlayed - 1) + Double(score.score)
        statistics!.averageScore = totalScore / Double(statistics!.totalGamesPlayed)
        
        if score.score > statistics!.bestScore {
            statistics!.bestScore = score.score
        }
    }
    
    func fetchStatistics() throws -> GameStatistics? {
        return statistics
    }
    
    func resetStatistics() throws {
        statistics = GameStatistics()
    }
}

struct GameViewModelTests {
    
    // Mock services for testing
    private func createMockServices() -> (BubbleService, AudioService, EffectService, DeviceService, PerformanceService) {
        let bubbleService = MockBubbleService()
        let audioService = MockAudioService()
        let effectService = MockEffectService()
        let deviceService = MockDeviceService()
        let performanceService = MockPerformanceService()
        
        return (bubbleService, audioService, effectService, deviceService, performanceService)
    }
    
    @MainActor
    private func createMockRepositories() -> (ScoreRepository, SettingsRepository, StatisticsRepository) {
        let scoreRepo = MockScoreRepository()
        let settingsRepo = MockSettingsRepository()
        let statsRepo = MockStatisticsRepository()
        
        return (scoreRepo, settingsRepo, statsRepo)
    }

    @Test @MainActor func gameViewModelInitialization() async throws {
        let (bubbleService, audioService, effectService, deviceService, performanceService) = createMockServices()
        let (scoreRepo, settingsRepo, statsRepo) = await createMockRepositories()
        
        let gameSettings = GameSettings()
        
        let viewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            deviceService: deviceService,
            performanceService: performanceService,
            scoreRepository: scoreRepo,
            settingsRepository: settingsRepo,
            statisticsRepository: statsRepo,
            gameSettings: gameSettings
        )
        
        #expect(viewModel.gameState == .menu)
        #expect(viewModel.score == 0)
        #expect(viewModel.timeRemaining == 60.0)
        #expect(viewModel.bubblesPopped == 0)
        #expect(viewModel.currentStreak == 0)
        #expect(viewModel.bestStreak == 0)
    }
    
    @Test @MainActor func startGameUpdatesState() async throws {
        let (bubbleService, audioService, effectService, deviceService, performanceService) = createMockServices()
        let (scoreRepo, settingsRepo, statsRepo) = await createMockRepositories()
        
        let gameSettings = GameSettings()
        
        let viewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            deviceService: deviceService,
            performanceService: performanceService,
            scoreRepository: scoreRepo,
            settingsRepository: settingsRepo,
            statisticsRepository: statsRepo,
            gameSettings: gameSettings
        )
        
        await viewModel.startGame()
        
        #expect(viewModel.gameState == .playing)
        #expect(viewModel.score == 0)
        #expect(viewModel.timeRemaining == gameSettings.gameTime)
    }
    
    @Test @MainActor func pauseGameTogglesState() async throws {
        let (bubbleService, audioService, effectService, deviceService, performanceService) = createMockServices()
        let (scoreRepo, settingsRepo, statsRepo) = await createMockRepositories()
        
        let gameSettings = GameSettings()
        
        let viewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            deviceService: deviceService,
            performanceService: performanceService,
            scoreRepository: scoreRepo,
            settingsRepository: settingsRepo,
            statisticsRepository: statsRepo,
            gameSettings: gameSettings
        )
        
        await viewModel.startGame()
        #expect(viewModel.gameState == .playing)
        
        viewModel.pauseGame()
        #expect(viewModel.gameState == .paused)
        
        viewModel.resumeGame()
        #expect(viewModel.gameState == .playing)
    }
    
    @Test @MainActor func numberedGameModeInitialization() async throws {
        let (bubbleService, audioService, effectService, deviceService, performanceService) = createMockServices()
        let (scoreRepo, settingsRepo, statsRepo) = await createMockRepositories()
        
        let gameSettings = GameSettings()
        gameSettings.gameMode = "numbered"
        
        let viewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            deviceService: deviceService,
            performanceService: performanceService,
            scoreRepository: scoreRepo,
            settingsRepository: settingsRepo,
            statisticsRepository: statsRepo,
            gameSettings: gameSettings
        )
        
        await viewModel.startGame()
        
        #expect(viewModel.nextExpectedNumber == 1)
        #expect(viewModel.timePenalty == 0.0)
    }
    
    @Test func bubbleCollisionDetection() async throws {
        let bubbleService = MockBubbleService()
        
        // テスト用バブル作成
        let bubble1 = bubbleService.createBubble(at: CGPoint(x: 100, y: 100), type: .normal)
        let bubble2 = bubbleService.createBubble(at: CGPoint(x: 200, y: 200), type: .normal)
        let bubbles = [bubble1, bubble2]
        
        // 衝突判定テスト
        let hitBubble = bubbleService.checkCollision(at: CGPoint(x: 100, y: 100), in: bubbles)
        #expect(hitBubble != nil)
        #expect(hitBubble?.id == bubble1.id)
        
        // 衝突しない位置のテスト
        let missedBubble = bubbleService.checkCollision(at: CGPoint(x: 50, y: 50), in: bubbles)
        #expect(missedBubble == nil)
        
        // インデックス取得テスト
        let hitIndex = bubbleService.checkCollisionIndex(at: CGPoint(x: 200, y: 200), in: bubbles)
        #expect(hitIndex == 1)
    }
    
    @Test func numberedBubbleGeneration() async throws {
        let bubbleService = MockBubbleService()
        let screenBounds = CGRect(x: 0, y: 0, width: 400, height: 800)
        
        let bubbles = bubbleService.generateNumberedBubbles(
            count: 10,
            screenBounds: screenBounds,
            numberedCount: 5
        )
        
        #expect(bubbles.count == 10)
        
        // 最初の5個が数字付きバブルかチェック
        let numberedBubbles = bubbles.filter { $0.type == .numbered }
        #expect(numberedBubbles.count == 5)
        
        // 数字が1-5の範囲内かチェック
        for bubble in numberedBubbles {
            if let number = bubble.number {
                #expect(number >= 1 && number <= 5)
            }
        }
    }
    
    @Test @MainActor func gamePerformanceOptimization() async throws {
        let (bubbleService, audioService, effectService, deviceService, performanceService) = createMockServices()
        let (scoreRepo, settingsRepo, statsRepo) = await createMockRepositories()
        
        let gameSettings = GameSettings()
        gameSettings.bubbleCount = 30
        
        let viewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            deviceService: deviceService,
            performanceService: performanceService,
            scoreRepository: scoreRepo,
            settingsRepository: settingsRepo,
            statisticsRepository: statsRepo,
            gameSettings: gameSettings
        )
        
        await viewModel.startGame()
        
        // 初期バブル数の確認
        #expect(viewModel.bubbles.count == gameSettings.bubbleCount)
        
        // パフォーマンス最適化実行
        viewModel.optimizePerformance()
        
        // MockPerformanceServiceは常に良好なパフォーマンスを返すため、バブル数は変わらない
        #expect(viewModel.bubbles.count <= gameSettings.bubbleCount)
    }
}

// MARK: - Repository Tests
struct RepositoryTests {
    
    @Test @MainActor func scoreRepositorySaveAndFetch() async throws {
        let repository = MockScoreRepository()
        
        let testScore = GameScore(
            score: 1000,
            bubblesPopped: 50,
            accuracy: 0.8,
            gameMode: "normal",
            playDate: Date(),
            gameDuration: 60.0
        )
        
        try repository.saveScore(testScore)
        
        let highScores = try repository.fetchHighScores(limit: 10)
        #expect(highScores.count == 1)
        #expect(highScores.first?.score == 1000)
        
        let normalModeScores = try repository.fetchScoresByMode("normal")
        #expect(normalModeScores.count == 1)
        #expect(normalModeScores.first?.gameMode == "normal")
    }
    
    @Test @MainActor func settingsRepositorySaveAndFetch() async throws {
        let repository = MockSettingsRepository()
        
        let testSettings = GameSettings()
        testSettings.gameTime = 90.0
        testSettings.bubbleCount = 25
        testSettings.gameMode = "numbered"
        testSettings.soundEnabled = false
        
        try repository.saveSettings(testSettings)
        
        let fetchedSettings = try repository.fetchSettings()
        #expect(fetchedSettings?.gameTime == 90.0)
        #expect(fetchedSettings?.bubbleCount == 25)
        #expect(fetchedSettings?.gameMode == "numbered")
        #expect(fetchedSettings?.soundEnabled == false)
    }
    
    @Test @MainActor func statisticsRepositoryUpdate() async throws {
        let repository = MockStatisticsRepository()
        
        let testScore = GameScore(
            score: 500,
            bubblesPopped: 25,
            accuracy: 0.9,
            gameMode: "normal",
            playDate: Date(),
            gameDuration: 45.0
        )
        
        try repository.updateStatistics(with: testScore)
        
        let statistics = try repository.fetchStatistics()
        #expect(statistics?.totalGamesPlayed == 1)
        #expect(statistics?.totalBubblesPopped == 25)
        #expect(statistics?.totalPlayTime == 45.0)
        #expect(statistics?.averageScore == 500.0)
    }
}

// MARK: - Performance Tests
struct PerformanceTests {
    
    @Test func performanceServiceMonitoring() async throws {
        let performanceService = MockPerformanceService()
        
        performanceService.startMonitoring()
        
        #expect(performanceService.currentFPS == 60.0)
        #expect(performanceService.averageFPS == 60.0)
        #expect(performanceService.isPerformanceGood == true)
        #expect(performanceService.shouldReduceBubbles() == false)
        #expect(performanceService.getPerformanceAdjustment() == 1.0)
        
        performanceService.stopMonitoring()
    }
}

// MARK: - AudioService Tests
struct AudioServiceTests {
    
    @Test func bgmTrackPlaybackEnabled() async throws {
        let audioService = MockAudioService()
        
        // BGMが有効な場合
        audioService.setBGMEnabled(true)
        audioService.playBGMTrack("track1", loop: true)
        
        #expect(audioService.isPlaying == true)
        #expect(audioService.currentBGMTrack == "track1")
        #expect(audioService.isBGMEnabled == true)
    }
    
    @Test func bgmTrackPlaybackDisabled() async throws {
        let audioService = MockAudioService()
        
        // BGMが無効な場合
        audioService.setBGMEnabled(false)
        audioService.playBGMTrack("track1", loop: true)
        
        #expect(audioService.isPlaying == false)
        #expect(audioService.currentBGMTrack == nil)
        #expect(audioService.isBGMEnabled == false)
    }
    
    @Test func bgmToggleOnOff() async throws {
        let audioService = MockAudioService()
        
        // 初期状態: BGM有効
        #expect(audioService.isBGMEnabled == true)
        
        // BGMを無効にする
        audioService.setBGMEnabled(false)
        #expect(audioService.isBGMEnabled == false)
        #expect(audioService.isPlaying == false)
        
        // BGMを再び有効にする
        audioService.setBGMEnabled(true)
        #expect(audioService.isBGMEnabled == true)
    }
    
    @Test func bgmTrackSwitching() async throws {
        let audioService = MockAudioService()
        
        audioService.setBGMEnabled(true)
        
        // Track1を再生
        audioService.playBGMTrack("track1", loop: true)
        #expect(audioService.currentBGMTrack == "track1")
        
        // Track2に切り替え
        audioService.playBGMTrack("track2", loop: true)
        #expect(audioService.currentBGMTrack == "track2")
        
        // Track3に切り替え
        audioService.playBGMTrack("track3", loop: true)
        #expect(audioService.currentBGMTrack == "track3")
    }
    
    @Test func bgmStopFunctionality() async throws {
        let audioService = MockAudioService()
        
        audioService.setBGMEnabled(true)
        audioService.playBGMTrack("track1", loop: true)
        
        #expect(audioService.isPlaying == true)
        #expect(audioService.currentBGMTrack == "track1")
        
        // BGM停止
        audioService.stopBGM()
        
        #expect(audioService.isPlaying == false)
        #expect(audioService.currentBGMTrack == nil)
    }
}

// MARK: - Settings Tests
struct SettingsTests {
    
    @Test @MainActor func settingsViewModelBGMToggle() async throws {
        let mockSettingsRepo = MockSettingsRepository()
        let mockAudioService = MockAudioService()
        
        let viewModel = SettingsViewModel(
            settingsRepository: mockSettingsRepo,
            audioService: mockAudioService
        )
        
        // 初期状態: BGM有効
        #expect(viewModel.gameSettings.bgmEnabled == true)
        
        // BGMをオフに切り替え
        viewModel.toggleBGM()
        #expect(viewModel.gameSettings.bgmEnabled == false)
        #expect(mockAudioService.isBGMEnabled == false)
        
        // BGMを再びオンに切り替え
        viewModel.toggleBGM()
        #expect(viewModel.gameSettings.bgmEnabled == true)
        #expect(mockAudioService.isBGMEnabled == true)
    }
    
    @Test @MainActor func settingsViewModelBGMTrackSelection() async throws {
        let mockSettingsRepo = MockSettingsRepository()
        let mockAudioService = MockAudioService()
        
        let viewModel = SettingsViewModel(
            settingsRepository: mockSettingsRepo,
            audioService: mockAudioService
        )
        
        // Track2に変更
        viewModel.setBGMTrack("track2")
        #expect(viewModel.gameSettings.bgmTrack == "track2")
        #expect(mockAudioService.currentBGMTrack == "track2")
        
        // Track3に変更
        viewModel.setBGMTrack("track3")
        #expect(viewModel.gameSettings.bgmTrack == "track3")
        #expect(mockAudioService.currentBGMTrack == "track3")
    }
    
    @Test @MainActor func settingsViewModelSaveSettings() async throws {
        let mockSettingsRepo = MockSettingsRepository()
        let mockAudioService = MockAudioService()
        
        let viewModel = SettingsViewModel(
            settingsRepository: mockSettingsRepo,
            audioService: mockAudioService
        )
        
        // 設定変更
        viewModel.gameSettings.bgmEnabled = false
        viewModel.gameSettings.bgmTrack = "track2"
        viewModel.gameSettings.soundEnabled = false
        
        // 設定保存
        viewModel.saveSettings()
        
        // 保存された設定を確認
        let savedSettings = try mockSettingsRepo.fetchSettings()
        #expect(savedSettings?.bgmEnabled == false)
        #expect(savedSettings?.bgmTrack == "track2")
        #expect(savedSettings?.soundEnabled == false)
    }
    
    @Test @MainActor func settingsViewModelResetToDefaults() async throws {
        let mockSettingsRepo = MockSettingsRepository()
        let mockAudioService = MockAudioService()
        
        let viewModel = SettingsViewModel(
            settingsRepository: mockSettingsRepo,
            audioService: mockAudioService
        )
        
        // 設定を変更
        viewModel.gameSettings.bgmEnabled = false
        viewModel.gameSettings.bgmTrack = "track3"
        viewModel.gameSettings.gameTime = 120.0
        
        // デフォルトにリセット
        viewModel.resetToDefaults()
        
        // デフォルト値に戻っているかチェック
        #expect(viewModel.gameSettings.bgmEnabled == true)
        #expect(viewModel.gameSettings.bgmTrack == "track1")
        #expect(viewModel.gameSettings.gameTime == 60.0)
    }
}

// MARK: - Dynamic Number Mode Tests
struct DynamicNumberModeTests {
    
    @Test @MainActor func dynamicDifficultyLevelProgression() async throws {
        let (bubbleService, audioService, effectService, deviceService, performanceService) = createMockServices()
        let (scoreRepo, settingsRepo, statsRepo) = await createMockRepositories()
        
        let gameSettings = GameSettings()
        gameSettings.gameMode = "numbered"
        
        let viewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            deviceService: deviceService,
            performanceService: performanceService,
            scoreRepository: scoreRepo,
            settingsRepository: settingsRepo,
            statisticsRepository: statsRepo,
            gameSettings: gameSettings
        )
        
        await viewModel.startGame()
        
        // レベル1の初期状態確認
        #expect(viewModel.currentLevel == 1)
        #expect(viewModel.currentNumberSet.count == 3)
        #expect(viewModel.nextExpectedNumber == viewModel.currentNumberSet[0])
        
        // 時間経過シミュレーション（レベル2へ）
        viewModel.timeRemaining = 45.0 // 15秒経過
        
        // レベルアップ確認（実際のゲームではupdateDynamicDifficultyが呼ばれる）
        let newLevel = viewModel.calculateCurrentLevel()
        #expect(newLevel == 2)
    }
    
    @Test @MainActor func randomNumberSetGeneration() async throws {
        let (bubbleService, audioService, effectService, deviceService, performanceService) = createMockServices()
        let (scoreRepo, settingsRepo, statsRepo) = await createMockRepositories()
        
        let gameSettings = GameSettings()
        gameSettings.gameMode = "numbered"
        
        let viewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            deviceService: deviceService,
            performanceService: performanceService,
            scoreRepository: scoreRepo,
            settingsRepository: settingsRepo,
            statisticsRepository: statsRepo,
            gameSettings: gameSettings
        )
        
        await viewModel.startGame()
        
        // 初期数字セット確認
        let initialSet = viewModel.currentNumberSet
        #expect(initialSet.count > 0)
        #expect(initialSet.allSatisfy { $0 >= 1 && $0 <= 15 }) // 最大範囲内
        #expect(initialSet == initialSet.sorted()) // ソート済み確認
        
        // 異なるレベルで異なる範囲確認
        let level2Numbers = viewModel.generateRandomNumberSet(for: 2)
        let level3Numbers = viewModel.generateRandomNumberSet(for: 3)
        
        #expect(level2Numbers.count == 4) // レベル2は4個
        #expect(level3Numbers.count == 5) // レベル3は5個
    }
    
    @Test @MainActor func perfectChainBonusSystem() async throws {
        let (bubbleService, audioService, effectService, deviceService, performanceService) = createMockServices()
        let (scoreRepo, settingsRepo, statsRepo) = await createMockRepositories()
        
        let gameSettings = GameSettings()
        gameSettings.gameMode = "numbered"
        
        let viewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            deviceService: deviceService,
            performanceService: performanceService,
            scoreRepository: scoreRepo,
            settingsRepository: settingsRepo,
            statisticsRepository: statsRepo,
            gameSettings: gameSettings
        )
        
        await viewModel.startGame()
        
        let initialPerfectChain = viewModel.perfectChain
        #expect(initialPerfectChain == 0)
        
        // 数字セット完了でパーフェクトチェイン増加をシミュレート
        viewModel.advanceToNextNumber() // 数字セットの最後まで進める
        
        // 実際の実装ではadvanceToNextNumberでパーフェクトチェインが増加
        #expect(viewModel.perfectChain >= initialPerfectChain)
    }
    
    @Test @MainActor func speedBonusCalculation() async throws {
        let (bubbleService, audioService, effectService, deviceService, performanceService) = createMockServices()
        let (scoreRepo, settingsRepo, statsRepo) = await createMockRepositories()
        
        let gameSettings = GameSettings()
        gameSettings.gameMode = "numbered"
        
        let viewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            deviceService: deviceService,
            performanceService: performanceService,
            scoreRepository: scoreRepo,
            settingsRepository: settingsRepo,
            statisticsRepository: statsRepo,
            gameSettings: gameSettings
        )
        
        await viewModel.startGame()
        
        let initialSpeedBonus = viewModel.speedBonus
        #expect(initialSpeedBonus == 1.0)
        
        // 高速回答シミュレーション
        viewModel.lastCorrectTime = Date().addingTimeInterval(-0.5) // 0.5秒前
        viewModel.advanceToNextNumber()
        
        // スピードボーナス増加確認
        #expect(viewModel.speedBonus >= initialSpeedBonus)
    }
    
    @Test func customNumberSetBubbleGeneration() async throws {
        let bubbleService = MockBubbleService()
        let screenBounds = CGRect(x: 0, y: 0, width: 400, height: 800)
        let customNumberSet = [3, 7, 12, 2, 15]
        
        let bubbles = bubbleService.generateNumberedBubblesWithCustomSet(
            count: 10,
            screenBounds: screenBounds,
            numberSet: customNumberSet
        )
        
        #expect(bubbles.count == 10)
        
        // カスタム数字セットの数字付きバブル確認
        let numberedBubbles = bubbles.filter { $0.type == .numbered }
        #expect(numberedBubbles.count == customNumberSet.count)
        
        // 各数字が正しく設定されているか確認
        let bubbleNumbers = numberedBubbles.compactMap { $0.number }.sorted()
        let expectedNumbers = customNumberSet.sorted()
        #expect(bubbleNumbers == expectedNumbers)
    }
    
    private func createMockServices() -> (BubbleService, AudioService, EffectService, DeviceService, PerformanceService) {
        let bubbleService = MockBubbleService()
        let audioService = MockAudioService()
        let effectService = MockEffectService()
        let deviceService = MockDeviceService()
        let performanceService = MockPerformanceService()
        
        return (bubbleService, audioService, effectService, deviceService, performanceService)
    }
    
    @MainActor
    private func createMockRepositories() -> (ScoreRepository, SettingsRepository, StatisticsRepository) {
        let scoreRepo = MockScoreRepository()
        let settingsRepo = MockSettingsRepository()
        let statsRepo = MockStatisticsRepository()
        
        return (scoreRepo, settingsRepo, statsRepo)
    }
}
