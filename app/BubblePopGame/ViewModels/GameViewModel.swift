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
    
    // 動的難易度システム
    var currentLevel: Int = 1
    var levelStartTime: Double = 0.0
    var currentNumberSet: [Int] = []
    var currentNumberIndex: Int = 0
    var perfectChain: Int = 0
    var speedBonus: Double = 1.0
    var lastCorrectTime: Date?
    
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
            // 動的難易度システム初期化
            currentLevel = 1
            levelStartTime = 0.0
            currentNumberSet = generateRandomNumberSet(for: 1)
            currentNumberIndex = 0
            nextExpectedNumber = currentNumberSet[0]
            timePenalty = 0.0
            
            // 設定に基づいてボーナス初期化
            perfectChain = gameSettings.perfectChainEnabled ? 0 : 0
            speedBonus = gameSettings.speedBonusEnabled ? 1.0 : 1.0
            lastCorrectTime = nil
        }
        
        // シャボン玉生成
        generateBubbles()
        
        // ゲームループ開始
        startGameLoop()
        
        // タイマー開始
        startGameTimer()
        
        // BGM再生（設定に基づいて）
        if gameSettings.bgmEnabled && gameSettings.bgmTrack != "off" {
            audioService.playBGMTrack(gameSettings.bgmTrack, loop: true)
        }
        
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
        audioService.fadeOutBGM(duration: 1.0)
        
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
        
        // 新しいスコア計算システム（動的ボーナス適用）
        let earnedScore = calculateScore(for: bubble) * 2 // 数字順ボーナス
        let streakBonus = currentStreak >= 3 ? earnedScore / 2 : 0
        score += earnedScore + streakBonus
        
        // 動的次番号システム
        advanceToNextNumber()
        
        // 動的難易度更新
        updateDynamicDifficulty()
        
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
        // レベルに応じた動的ペナルティ
        let basePenalty = 3.0
        let levelPenalty = Double(currentLevel) * 0.5
        let penalty = basePenalty + levelPenalty
        
        timePenalty += penalty
        timeRemaining = max(0, timeRemaining - penalty)
        
        // ボーナスリセット
        currentStreak = 0
        if gameSettings.perfectChainEnabled {
            perfectChain = 0
        }
        if gameSettings.speedBonusEnabled {
            speedBonus = max(1.0, speedBonus - 0.2)
        }
        
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
            // 動的システム：カスタム数字セットを使用
            bubbles = bubbleService.generateNumberedBubblesWithCustomSet(
                count: gameSettings.bubbleCount,
                screenBounds: screenBounds,
                numberSet: currentNumberSet
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
        // HUD領域（上部150px）とマージン（60px）を除外した生成領域
        let hudHeight: CGFloat = 150
        let margin: CGFloat = 60
        let x = CGFloat.random(in: margin...(screenBounds.width - margin))
        let y = CGFloat.random(in: (hudHeight + margin)...(screenBounds.height - margin))
        return CGPoint(x: x, y: y)
    }
    
    private func calculateScore(for bubble: Bubble) -> Int {
        switch bubble.type {
        case .normal:
            return 1
        case .numbered:
            let baseScore = bubble.number ?? 1
            var bonusMultiplier = 1.0
            
            // スピードボーナス適用（設定で有効な場合のみ）
            if gameSettings.speedBonusEnabled {
                bonusMultiplier *= speedBonus
            }
            
            // パーフェクトチェインボーナス適用（設定で有効な場合のみ）
            if gameSettings.perfectChainEnabled {
                let chainMultiplier = gameSettings.perfectChainMultiplier
                bonusMultiplier *= (1.0 + Double(perfectChain) * chainMultiplier)
            }
            
            return Int(Double(baseScore) * bonusMultiplier)
        }
    }
    
    // MARK: - Dynamic Difficulty System
    
    func calculateCurrentLevel() -> Int {
        // プログレッシブ難易度が無効の場合は常にレベル1
        guard gameSettings.numberedModeProgressive else { return 1 }
        
        let elapsedTime = gameSettings.gameTime - timeRemaining
        let levelInterval = gameSettings.numberedModeLevelInterval
        let maxLevel = gameSettings.numberedModeMaxLevel
        
        let calculatedLevel = Int(elapsedTime / levelInterval) + 1
        return min(maxLevel, calculatedLevel)
    }
    
    private func getNumberRangeForLevel(_ level: Int) -> (min: Int, max: Int, count: Int) {
        let startRange = gameSettings.numberedModeStartRange
        let maxRange = gameSettings.numberedModeMaxRange
        let maxLevel = gameSettings.numberedModeMaxLevel
        
        // レベルに応じた動的範囲計算
        let rangePerLevel = max(1, (maxRange - startRange) / maxLevel)
        let currentMax = min(maxRange, startRange + (level - 1) * rangePerLevel)
        let count = min(10, startRange + level - 1) // 最大10個まで
        
        return (min: 1, max: currentMax, count: count)
    }
    
    func generateRandomNumberSet(for level: Int) -> [Int] {
        let range = getNumberRangeForLevel(level)
        var selectedNumbers: [Int] = []
        
        // 特殊ルールに基づいて数字を生成
        switch gameSettings.numberedModeSpecialRule {
        case "reverse":
            // 逆順：大きい数字から小さい数字へ
            var availableNumbers = Array(Array(range.min...range.max).reversed())
            for _ in 0..<range.count {
                if let randomIndex = availableNumbers.indices.randomElement() {
                    let number = availableNumbers.remove(at: randomIndex)
                    selectedNumbers.append(number)
                }
            }
            return selectedNumbers.sorted(by: >)
            
        case "double":
            // 2倍数モード：2,4,6,8...
            let evenNumbers = Array(stride(from: 2, through: range.max, by: 2))
            let shuffled = evenNumbers.shuffled()
            selectedNumbers = Array(shuffled.prefix(min(range.count, shuffled.count)))
            return selectedNumbers.sorted()
            
        case "random":
            // ランダム順序：表示順序をランダムに
            var availableNumbers = Array(range.min...range.max)
            for _ in 0..<range.count {
                if let randomIndex = availableNumbers.indices.randomElement() {
                    let number = availableNumbers.remove(at: randomIndex)
                    selectedNumbers.append(number)
                }
            }
            return selectedNumbers // ソートしない（ランダム順序を保持）
            
        default:
            // 通常モード：ランダム選択後ソート
            var availableNumbers = Array(range.min...range.max)
            for _ in 0..<range.count {
                if let randomIndex = availableNumbers.indices.randomElement() {
                    let number = availableNumbers.remove(at: randomIndex)
                    selectedNumbers.append(number)
                }
            }
            return selectedNumbers.sorted()
        }
    }
    
    private func updateDynamicDifficulty() {
        let newLevel = calculateCurrentLevel()
        
        if newLevel != currentLevel {
            // レベルアップ処理
            currentLevel = newLevel
            levelStartTime = gameSettings.gameTime - timeRemaining
            currentNumberSet = generateRandomNumberSet(for: currentLevel)
            currentNumberIndex = 0
            nextExpectedNumber = currentNumberSet[0]
            numberedBubblesCount = getNumberRangeForLevel(currentLevel).count
            
            // レベルアップエフェクト
            audioService.playSFX(name: "level_up")
            effectService.triggerSuccessFeedback()
            
            // 新しいレベルでバブル再生成
            regenerateBubblesForNewLevel()
        }
    }
    
    private func regenerateBubblesForNewLevel() {
        // 既存のバブルをクリア（破裂中以外）
        bubbles.removeAll { !$0.isPopping }
        
        // 新しいレベルに適したバブルを生成
        generateBubbles()
    }
    
    func advanceToNextNumber() {
        currentNumberIndex += 1
        
        if currentNumberIndex >= currentNumberSet.count {
            // 現在のセットが完了、新しいセットを生成
            currentNumberSet = generateRandomNumberSet(for: currentLevel)
            currentNumberIndex = 0
            
            // パーフェクトチェインボーナス（設定で有効な場合のみ）
            if gameSettings.perfectChainEnabled {
                perfectChain += 1
            }
            
            // 新しい数字セットのバブルを画面に表示
            regenerateBubblesForNewLevel()
        }
        
        nextExpectedNumber = currentNumberSet[currentNumberIndex]
        
        // スピードボーナス計算（設定で有効な場合のみ）
        if gameSettings.speedBonusEnabled, let lastTime = lastCorrectTime {
            let responseTime = Date().timeIntervalSince(lastTime)
            let maxMultiplier = gameSettings.speedBonusMultiplier
            
            if responseTime < 1.0 { // 1秒以内の場合
                speedBonus = min(maxMultiplier, speedBonus + 0.1)
            } else {
                speedBonus = max(1.0, speedBonus - 0.05)
            }
        }
        
        lastCorrectTime = Date()
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
    
    /// ゲーム設定を保存する
    func saveGameSettings() throws {
        try settingsRepository.saveSettings(gameSettings)
    }
    
    deinit {
        displayLink?.invalidate()
        gameTimer?.invalidate()
    }
}