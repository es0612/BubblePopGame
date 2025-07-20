//
//  GameViewModel.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftUI
import QuartzCore

@Observable
@MainActor
class GameViewModel {
    var gameState: GameState = .menu
    var score: Int = 0
    var timeRemaining: Double = 60.0
    var bubbles: [Bubble] = []
    var screenBounds: CGRect = CGRect(x: 0, y: 0, width: 393, height: 852) // iPhone標準サイズ
    var bubblesPopped: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    
    // 数字順ゲームモード専用
    var nextExpectedNumber: Int = 1
    var numberedBubblesCount: Int = 5
    var timePenalty: Double = 0.0
    
    // Services
    private let bubbleService: BubbleService
    let audioService: AudioService
    private let effectService: EffectService
    private let deviceService: DeviceService
    private let performanceService: PerformanceService
    
    // Repositories
    let scoreRepository: ScoreRepository
    private let settingsRepository: SettingsRepository
    private let statisticsRepository: StatisticsRepository
    
    // ゲームループ
    private nonisolated(unsafe) var displayLink: CADisplayLink?
    private nonisolated(unsafe) var gameTimer: Timer?
    var gameSettings: GameSettings
    
    // タッチ応答性監視
    private var lastTouchTime: CFTimeInterval = 0
    private var touchResponseTimes: [CFTimeInterval] = []
    private let maxResponseTimeHistory = 10
    
    init(bubbleService: BubbleService,
         audioService: AudioService,
         effectService: EffectService,
         deviceService: DeviceService,
         performanceService: PerformanceService,
         scoreRepository: ScoreRepository,
         settingsRepository: SettingsRepository,
         statisticsRepository: StatisticsRepository,
         gameSettings: GameSettings? = nil) {
        self.bubbleService = bubbleService
        self.audioService = audioService
        self.effectService = effectService
        self.deviceService = deviceService
        self.performanceService = performanceService
        self.scoreRepository = scoreRepository
        self.settingsRepository = settingsRepository
        self.statisticsRepository = statisticsRepository
        self.gameSettings = gameSettings ?? GameSettings()
    }
    
    func updateScreenBounds(_ size: CGSize) {
        screenBounds = CGRect(origin: .zero, size: size)
        bubbleService.updateScreenBounds(screenBounds)
    }
    
    func updateScreenBounds(_ bounds: CGRect) {
        screenBounds = bounds
        bubbleService.updateScreenBounds(bounds)
    }
    
    // パフォーマンス最適化メソッド
    func optimizePerformance() {
        let adjustment = performanceService.getPerformanceAdjustment()
        let optimalBubbleCount = Int(Double(gameSettings.bubbleCount) * adjustment)
        let deviceOptimalCount = deviceService.adaptBubbleCount(for: gameSettings)
        
        // より制限の厳しい方を採用
        let finalBubbleCount = min(optimalBubbleCount, deviceOptimalCount)
        
        // バブル数が現在より少ない場合は調整
        if bubbles.count > finalBubbleCount {
            let excess = bubbles.count - finalBubbleCount
            bubbles.removeLast(excess)
        }
    }
    
    func setupParticleEffectView(_ particleEffectView: ParticleEffectView) {
        if let effectServiceImpl = effectService as? EffectServiceImpl {
            effectServiceImpl.particleEffectView = particleEffectView
        }
    }
    
    func startGame() {
        gameState = .playing
        score = 0
        timeRemaining = gameSettings.gameTime
        bubblesPopped = 0
        currentStreak = 0
        bestStreak = 0
        
        // 数字順ゲームモード初期化
        if gameSettings.gameMode == "numbered" {
            nextExpectedNumber = 1
            timePenalty = 0.0
        }
        
        // シャボン玉生成
        generateBubbles()
        
        // ゲームループ開始
        startGameLoop()
        
        // タイマー開始
        startGameTimer()
        
        // BGM再生
        audioService.playBGM(name: "game_bgm", loop: true)
        
        // パフォーマンス監視開始
        performanceService.startMonitoring()
    }
    
    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
        stopGameLoop()
        stopGameTimer()
    }
    
    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        startGameLoop()
        startGameTimer()
    }
    
    func endGame() {
        gameState = .gameOver
        stopGameLoop()
        stopGameTimer()
        audioService.stopAllSounds()
        
        // ゲームオーバー音とフィードバック
        audioService.playSFX(name: "game_over")
        effectService.triggerErrorFeedback()
        
        // スコア保存
        saveScore()
        
        // パフォーマンス監視停止
        performanceService.stopMonitoring()
    }
    
    func handleBubbleTap(at location: CGPoint) {
        guard gameState == .playing else { return }
        
        // タッチ応答性監視開始
        let touchStartTime = CACurrentMediaTime()
        
        if let hitBubbleIndex = bubbleService.checkCollisionIndex(at: location, in: bubbles) {
            var hitBubble = bubbles[hitBubbleIndex]
            
            // 数字順ゲームモードでの順序チェック
            if gameSettings.gameMode == "numbered" && hitBubble.type == .numbered {
                if let bubbleNumber = hitBubble.number {
                    if bubbleNumber == nextExpectedNumber {
                        // 正しい順序
                        handleCorrectNumberedBubble(hitBubble, at: hitBubbleIndex)
                        return
                    } else {
                        // 間違った順序
                        handleIncorrectNumberedBubble(hitBubble)
                        return
                    }
                }
            }
            
            // 通常のバブル処理
            handleNormalBubble(hitBubble, at: hitBubbleIndex)
            
            // タッチ応答性記録
            recordTouchResponseTime(startTime: touchStartTime)
        } else {
            // ミスタップも記録
            recordTouchResponseTime(startTime: touchStartTime)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleCorrectNumberedBubble(_ bubble: Bubble, at index: Int) {
        // 破裂アニメーション開始
        var hitBubble = bubble
        hitBubble.isPopping = true
        hitBubble.lastTouchTime = Date()
        bubbles[index] = hitBubble
        
        // 統計更新
        bubblesPopped += 1
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)
        
        // ボーナススコア計算（数字順の場合は2倍）
        let baseScore = bubble.number ?? 1
        let sequenceBonus = baseScore * 2
        let streakBonus = currentStreak >= 3 ? baseScore : 0
        let earnedScore = sequenceBonus + streakBonus
        score += earnedScore
        
        // 次の期待番号を更新
        nextExpectedNumber += 1
        if nextExpectedNumber > numberedBubblesCount {
            nextExpectedNumber = 1
        }
        
        // 成功エフェクトとサウンド
        effectService.createPopEffect(at: bubble.position, color: .green)
        audioService.playSFX(name: "bubble_pop")
        effectService.triggerSuccessFeedback()
        
        // 破裂アニメーション後に削除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.bubbles.removeAll { $0.id == bubble.id }
            self?.addRandomBubble()
        }
    }
    
    private func handleIncorrectNumberedBubble(_ bubble: Bubble) {
        // 時間ペナルティ（5秒減少）
        let penalty = 5.0
        timePenalty += penalty
        timeRemaining = max(0, timeRemaining - penalty)
        
        // ストリークリセット
        currentStreak = 0
        
        // エラーエフェクトとサウンド
        effectService.createPopEffect(at: bubble.position, color: .red)
        audioService.playSFX(name: "error_sound")
        effectService.triggerErrorFeedback()
        
        // バブルは削除しない（正しい順序まで残る）
    }
    
    private func handleNormalBubble(_ bubble: Bubble, at index: Int) {
        // 破裂アニメーション開始
        var hitBubble = bubble
        hitBubble.isPopping = true
        hitBubble.lastTouchTime = Date()
        bubbles[index] = hitBubble
        
        // 統計更新
        bubblesPopped += 1
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)
        
        // スコア加算（ストリークボーナス付き）
        let baseScore = calculateScore(for: bubble)
        let streakBonus = currentStreak >= 5 ? baseScore / 2 : 0
        let earnedScore = baseScore + streakBonus
        score += earnedScore
        
        // エフェクトとサウンド
        effectService.createPopEffect(at: bubble.position, color: bubble.color)
        audioService.playSFX(name: "bubble_pop")
        
        // タイプ別の触覚フィードバック
        let feedbackIntensity: UIImpactFeedbackGenerator.FeedbackStyle = 
            bubble.type == .numbered ? .heavy : .light
        effectService.triggerHapticFeedback(intensity: feedbackIntensity)
        
        // 破裂アニメーション後に削除（0.3秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.bubbles.removeAll { $0.id == bubble.id }
            self?.addRandomBubble()
        }
    }
    
    private func generateBubbles() {
        if gameSettings.gameMode == "numbered" {
            bubbles = bubbleService.generateNumberedBubbles(
                count: gameSettings.bubbleCount,
                screenBounds: screenBounds,
                numberedCount: numberedBubblesCount
            )
        } else {
            bubbles = bubbleService.generateRandomBubbles(
                count: gameSettings.bubbleCount,
                screenBounds: screenBounds
            )
        }
    }
    
    private func addRandomBubble() {
        let newBubble = bubbleService.createBubble(
            at: randomPosition(),
            type: .normal
        )
        bubbles.append(newBubble)
    }
    
    private func randomPosition() -> CGPoint {
        let margin: CGFloat = 60
        let x = CGFloat.random(in: margin...(screenBounds.width - margin))
        let y = CGFloat.random(in: margin...(screenBounds.height - margin))
        return CGPoint(x: x, y: y)
    }
    
    private func calculateScore(for bubble: Bubble) -> Int {
        switch bubble.type {
        case .normal:
            return 1
        case .numbered:
            return bubble.number ?? 1
        }
    }
    
    private func startGameLoop() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateGame))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopGameLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateGame() {
        guard gameState == .playing else { return }
        
        // シャボン玉の位置とアニメーション更新
        bubbleService.updateBubbles(&bubbles)
        
        // 画面境界を越えたシャボン玉を削除
        removeBubblesOutOfBounds()
        
        // パフォーマンス監視とバブル数の動的調整（60フレームごと＝約1秒）
        if displayLink?.timestamp.truncatingRemainder(dividingBy: 1.0) ?? 0 < 0.02 {
            if performanceService.shouldReduceBubbles() {
                optimizePerformance()
            }
        }
    }
    
    private func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateGameTimer()
            }
        }
    }
    
    private func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func updateGameTimer() {
        guard gameState == .playing else { return }
        
        timeRemaining -= 0.1
        
        if timeRemaining <= 0 {
            timeRemaining = 0
            endGame()
        }
    }
    
    private func saveScore() {
        let gameScore = GameScore(
            score: score,
            bubblesPopped: gameSettings.bubbleCount - bubbles.count + score,
            accuracy: calculateAccuracy(),
            gameMode: gameSettings.gameMode,
            playDate: Date(),
            gameDuration: gameSettings.gameTime - timeRemaining
        )
        
        do {
            try scoreRepository.saveScore(gameScore)
            // 統計情報を自動更新
            try statisticsRepository.updateStatistics(with: gameScore)
        } catch {
            print("Failed to save score or update statistics: \(error)")
        }
    }
    
    func calculateAccuracy() -> Double {
        let totalBubbles = gameSettings.bubbleCount - bubbles.count + score
        return totalBubbles > 0 ? Double(score) / Double(totalBubbles) : 0.0
    }
    
    private func removeBubblesOutOfBounds() {
        bubbles.removeAll { bubble in
            let margin: CGFloat = 100
            return bubble.position.x < -margin ||
                   bubble.position.x > screenBounds.width + margin ||
                   bubble.position.y < -margin ||
                   bubble.position.y > screenBounds.height + margin
        }
    }
    
    // MARK: - Touch Response Monitoring
    
    private func recordTouchResponseTime(startTime: CFTimeInterval) {
        let responseTime = CACurrentMediaTime() - startTime
        
        // 応答時間を記録
        touchResponseTimes.append(responseTime)
        
        // 履歴サイズを制限
        if touchResponseTimes.count > maxResponseTimeHistory {
            touchResponseTimes.removeFirst()
        }
        
        // 100ms以上の場合は警告ログ
        if responseTime > 0.1 {
            print("⚠️ Touch response time exceeded 100ms: \(responseTime * 1000)ms")
        }
    }
    
    /// 平均タッチ応答時間を取得
    func getAverageTouchResponseTime() -> Double {
        guard !touchResponseTimes.isEmpty else { return 0.0 }
        let sum = touchResponseTimes.reduce(0.0, +)
        return sum / Double(touchResponseTimes.count)
    }
    
    /// タッチ応答性が良好かどうかを判定
    func isTouchResponseGood() -> Bool {
        return getAverageTouchResponseTime() <= 0.1 // 100ms以内
    }
    
    deinit {
        displayLink?.invalidate()
        gameTimer?.invalidate()
    }
}