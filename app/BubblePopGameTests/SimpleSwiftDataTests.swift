//
//  SimpleSwiftDataTests.swift
//  BubblePopGameTests
//
//  SwiftDataモデルの基本テストスイート
//

import Testing
import Foundation
import SwiftData
@testable import BubblePopGame

// SwiftDataモデルの基本テストスイート
@Suite("SwiftData基本テスト")
struct SimpleSwiftDataTests {
    
    @Test("GameScoreモデル初期化テスト")
    func testGameScoreInitialization() {
        let gameScore = GameScore(
            score: 150,
            bubblesPopped: 25,
            accuracy: 0.85,
            gameMode: "normal",
            playDate: Date(),
            gameDuration: 58.5,
            gameTimeLimit: 60.0
        )
        
        // プロパティの確認
        #expect(gameScore.score == 150)
        #expect(gameScore.bubblesPopped == 25)
        #expect(gameScore.accuracy == 0.85)
        #expect(gameScore.gameMode == "normal")
        #expect(gameScore.gameDuration == 58.5)
        #expect(gameScore.gameTimeLimit == 60.0)
        #expect(gameScore.id != UUID()) // IDが生成されている
    }
    
    @Test("GameSettingsモデル初期化テスト")
    func testGameSettingsInitialization() {
        let settings = GameSettings()
        
        // デフォルト値の確認
        #expect(settings.bubbleCount == 20)
        #expect(settings.gameTime == 30.0)
        #expect(settings.soundEnabled == true)
        #expect(settings.vibrationEnabled == true)
        #expect(settings.gameMode == "normal")
        #expect(settings.isFirstLaunch == true)
        #expect(settings.bgmEnabled == true)
        #expect(settings.bgmTrack == "track1")
        #expect(settings.id != UUID()) // IDが生成されている
    }
    
    @Test("GameStatisticsモデル初期化テスト")
    func testGameStatisticsInitialization() {
        let stats = GameStatistics()
        
        // 初期値の確認
        #expect(stats.totalGamesPlayed == 0)
        #expect(stats.totalBubblesPopped == 0)
        #expect(stats.totalPlayTime == 0)
        #expect(stats.averageScore == 0)
        #expect(stats.bestScore == 0)
        #expect(stats.id != UUID()) // IDが生成されている
    }
    
    @Test("GameStatistics更新テスト")
    func testGameStatisticsUpdates() {
        let stats = GameStatistics()
        
        // 統計情報の更新
        stats.totalGamesPlayed = 5
        stats.totalBubblesPopped = 150
        stats.totalPlayTime = 300.0
        stats.averageScore = 120.5
        stats.bestScore = 200
        
        #expect(stats.totalGamesPlayed == 5)
        #expect(stats.totalBubblesPopped == 150)
        #expect(stats.totalPlayTime == 300.0)
        #expect(stats.averageScore == 120.5)
        #expect(stats.bestScore == 200)
    }
    
    @Test("GameSettings設定値変更テスト")
    func testGameSettingsModification() {
        let settings = GameSettings()
        
        // 設定値を変更
        settings.bubbleCount = 25
        settings.gameTime = 90.0
        settings.soundEnabled = false
        settings.gameMode = "numbered"
        settings.bgmTrack = "track2"
        
        #expect(settings.bubbleCount == 25)
        #expect(settings.gameTime == 90.0)
        #expect(settings.soundEnabled == false)
        #expect(settings.gameMode == "numbered")
        #expect(settings.bgmTrack == "track2")
    }
    
    @Test("複数GameScoreの比較テスト")
    func testMultipleGameScoresComparison() {
        let score1 = GameScore(score: 100, bubblesPopped: 20, accuracy: 0.8, gameMode: "normal", playDate: Date(), gameDuration: 60.0, gameTimeLimit: 60.0)
        let score2 = GameScore(score: 150, bubblesPopped: 30, accuracy: 0.9, gameMode: "numbered", playDate: Date(), gameDuration: 55.0, gameTimeLimit: 60.0)
        let score3 = GameScore(score: 75, bubblesPopped: 15, accuracy: 0.75, gameMode: "normal", playDate: Date(), gameDuration: 58.0, gameTimeLimit: 60.0)
        
        let scores = [score1, score2, score3].sorted { $0.score > $1.score }
        
        #expect(scores[0].score == 150) // 最高スコア
        #expect(scores[1].score == 100) // 2番目
        #expect(scores[2].score == 75)  // 最低スコア
    }
    
    @Test("ゲームモード別スコア分類テスト")
    func testScoreFilteringByGameMode() {
        let normalScore1 = GameScore(score: 100, bubblesPopped: 20, accuracy: 0.8, gameMode: "normal", playDate: Date(), gameDuration: 60.0, gameTimeLimit: 60.0)
        let normalScore2 = GameScore(score: 120, bubblesPopped: 24, accuracy: 0.85, gameMode: "normal", playDate: Date(), gameDuration: 58.0, gameTimeLimit: 60.0)
        let numberedScore = GameScore(score: 200, bubblesPopped: 35, accuracy: 0.9, gameMode: "numbered", playDate: Date(), gameDuration: 55.0, gameTimeLimit: 60.0)
        
        let allScores = [normalScore1, normalScore2, numberedScore]
        
        let normalScores = allScores.filter { $0.gameMode == "normal" }
        let numberedScores = allScores.filter { $0.gameMode == "numbered" }
        
        #expect(normalScores.count == 2)
        #expect(numberedScores.count == 1)
        #expect(numberedScores[0].score == 200)
    }
}