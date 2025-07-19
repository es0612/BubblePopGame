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
    
    // Services
    private let bubbleService: BubbleService
    private let audioService: AudioService
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
    
    func startGame() {
        gameState = .playing
        score = 0
        timeRemaining = gameSettings.gameTime
        
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
        
        // スコア保存
        saveScore()
    }
    
    func handleBubbleTap(at location: CGPoint) {
        guard gameState == .playing else { return }
        
        if let hitBubble = bubbleService.checkCollision(at: location, in: bubbles) {
            // シャボン玉を配列から削除
            bubbles.removeAll { $0.id == hitBubble.id }
            
            // スコア加算
            score += calculateScore(for: hitBubble)
            
            // エフェクト再生
            effectService.createPopEffect(at: hitBubble.position, color: hitBubble.color)
            audioService.playSFX(name: "bubble_pop")
            effectService.triggerHapticFeedback(intensity: .light)
            
            // 新しいシャボン玉を追加
            addRandomBubble()
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