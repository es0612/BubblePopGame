//
//  SimpleGameViewModelTests.swift
//  BubblePopGameTests
//
//  GameViewModelの基本的なテストスイート
//

import Testing
import Foundation
@testable import BubblePopGame

// GameViewModelの基本的なテストスイート
@Suite("GameViewModel基本テスト")
struct SimpleGameViewModelTests {
    
    @Test("GameSettings初期化テスト")
    func testGameSettingsInitialization() {
        let settings = GameSettings()
        
        #expect(settings.bubbleCount == 20)
        #expect(settings.gameTime == 60.0)
        #expect(settings.soundEnabled == true)
        #expect(settings.vibrationEnabled == true)
        #expect(settings.gameMode == "normal")
    }
    
    @Test("ゲームモード値テスト")
    func testGameModeValues() {
        let normalMode = GameMode.normal
        let numberedMode = GameMode.numbered
        
        #expect(normalMode.rawValue == "normal")
        #expect(numberedMode.rawValue == "numbered")
    }
    
    @Test("ゲーム状態値テスト")
    func testGameStateValues() {
        let menuState = GameState.menu
        let playingState = GameState.playing
        let pausedState = GameState.paused
        let gameOverState = GameState.gameOver
        
        #expect(menuState.rawValue == "menu")
        #expect(playingState.rawValue == "playing")
        #expect(pausedState.rawValue == "paused")
        #expect(gameOverState.rawValue == "gameOver")
    }
    
    @Test("バブルタイプ値テスト")
    func testBubbleTypeValues() {
        let normalType = BubbleType.normal
        let numberedType = BubbleType.numbered
        
        #expect(normalType.rawValue == "normal")
        #expect(numberedType.rawValue == "numbered")
    }
    
    @Test("バブル構造体テスト")
    func testBubbleCreation() {
        let bubble = Bubble(
            position: CGPoint(x: 100, y: 100),
            velocity: CGVector(dx: 1, dy: 1),
            radius: 30,
            type: .normal,
            number: nil,
            color: .blue,
            alpha: 1.0,
            animationPhase: 0
        )
        
        #expect(bubble.position.x == 100)
        #expect(bubble.position.y == 100)
        #expect(bubble.velocity.dx == 1)
        #expect(bubble.velocity.dy == 1)
        #expect(bubble.radius == 30)
        #expect(bubble.type == .normal)
        #expect(bubble.number == nil)
        #expect(bubble.alpha == 1.0)
        #expect(bubble.animationPhase == 0)
        #expect(bubble.isPopping == false)
    }
    
    @Test("数字付きバブルテスト")
    func testNumberedBubbleCreation() {
        let numberedBubble = Bubble(
            position: CGPoint(x: 50, y: 50),
            velocity: CGVector.zero,
            radius: 25,
            type: .numbered,
            number: 5,
            color: .red,
            alpha: 0.8,
            animationPhase: 1.0
        )
        
        #expect(numberedBubble.type == .numbered)
        #expect(numberedBubble.number == 5)
        #expect(numberedBubble.radius == 25)
        #expect(numberedBubble.alpha == 0.8)
    }
}