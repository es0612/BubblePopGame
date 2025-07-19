//
//  GameViewModel.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftUI

@Observable
class GameViewModel {
    var gameState: GameState = .menu
    var score: Int = 0
    var timeRemaining: Double = 60.0
    var bubbles: [Bubble] = []
    
    // 初期化用の空の実装 - 後でDependency Injectionで実装予定
    init() {
        
    }
    
    func startGame() {
        gameState = .playing
        score = 0
        timeRemaining = 60.0
        // TODO: シャボン玉生成とゲームループ開始
    }
    
    func pauseGame() {
        gameState = .paused
        // TODO: ゲームループ停止
    }
    
    func resumeGame() {
        gameState = .playing
        // TODO: ゲームループ再開
    }
    
    func endGame() {
        gameState = .gameOver
        // TODO: スコア保存とゲームループ停止
    }
    
    func handleBubbleTap(at location: CGPoint) {
        // TODO: 衝突判定とシャボン玉破裂処理
    }
}