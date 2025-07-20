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
    
    // Services
    private let bubbleService: BubbleService
    let audioService: AudioService
    private let effectService: EffectService
    
    // Repositories
    private let scoreRepository: ScoreRepository
    private let settingsRepository: SettingsRepository
    private let statisticsRepository: StatisticsRepository
    
    // ゲームループ
    private nonisolated(unsafe) var displayLink: CADisplayLink?
    private nonisolated(unsafe) var gameTimer: Timer?
    private var gameSettings: GameSettings
    
    init(bubbleService: BubbleService,
         audioService: AudioService,
         effectService: EffectService,
         scoreRepository: ScoreRepository,
         settingsRepository: SettingsRepository,
         statisticsRepository: StatisticsRepository,
         gameSettings: GameSettings? = nil) {
        self.bubbleService = bubbleService
        self.audioService = audioService
        self.effectService = effectService
        self.scoreRepository = scoreRepository
        self.settingsRepository = settingsRepository
        self.statisticsRepository = statisticsRepository
        self.gameSettings = gameSettings ?? GameSettings()
    }
    
    func updateScreenBounds(_ bounds: CGRect) {
        screenBounds = bounds
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
        
        // シャボン玉生成
        generateBubbles()
        
        // ゲームループ開始
        startGameLoop()
        
        // タイマー開始
        startGameTimer()
        
        // BGM再生
        audioService.playBGM(name: "game_bgm", loop: true)
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
    }
    
    func handleBubbleTap(at location: CGPoint) {
        guard gameState == .playing else { return }
        
        if let hitBubbleIndex = bubbleService.checkCollisionIndex(at: location, in: bubbles) {
            var hitBubble = bubbles[hitBubbleIndex]
            
            // 破裂アニメーション開始
            hitBubble.isPopping = true
            hitBubble.lastTouchTime = Date()
            bubbles[hitBubbleIndex] = hitBubble
            
            // 統計更新
            bubblesPopped += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            
            // スコア加算（ストリークボーナス付き）
            let baseScore = calculateScore(for: hitBubble)
            let streakBonus = currentStreak >= 5 ? baseScore / 2 : 0
            let earnedScore = baseScore + streakBonus
            score += earnedScore
            
            // エフェクトとサウンド
            effectService.createPopEffect(at: hitBubble.position, color: hitBubble.color)
            audioService.playSFX(name: "bubble_pop")
            
            // タイプ別の触覚フィードバック
            let feedbackIntensity: UIImpactFeedbackGenerator.FeedbackStyle = 
                hitBubble.type == .numbered ? .heavy : .light
            effectService.triggerHapticFeedback(intensity: feedbackIntensity)
            
            // 破裂アニメーション後に削除（0.3秒後）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.bubbles.removeAll { $0.id == hitBubble.id }
                self?.addRandomBubble()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func generateBubbles() {
        bubbles = bubbleService.generateRandomBubbles(
            count: gameSettings.bubbleCount,
            screenBounds: screenBounds
        )
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
    
    private func calculateAccuracy() -> Double {
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
    
    deinit {
        displayLink?.invalidate()
        gameTimer?.invalidate()
    }
}