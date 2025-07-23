//
//  BubblePopGameTests.swift
//  BubblePopGameTests
//  
//  Created on 2025/07/17
//

import Testing
import SwiftData
import SwiftUI
@testable import BubblePopGame

// MARK: - Basic Tests Only
struct BasicGameTests {
    
    @Test func gameSettingsInitialization() async throws {
        let gameSettings = GameSettings()
        
        #expect(gameSettings.gameTime == 60.0)
        #expect(gameSettings.bubbleCount == 20)
        #expect(gameSettings.gameMode == "normal")
        #expect(gameSettings.soundEnabled == true)
    }
    
    @Test func gameSettingsNumberedModeProperties() async throws {
        let gameSettings = GameSettings()
        
        // 数字モード設定のデフォルト値確認
        #expect(gameSettings.numberedModeMaxLevel == 5)
        #expect(gameSettings.numberedModeProgressive == true)
        #expect(gameSettings.numberedModeLevelInterval == 15.0)
        #expect(gameSettings.numberedModeMaxRange == 15)
        #expect(gameSettings.numberedModeStartRange == 3)
        #expect(gameSettings.speedBonusEnabled == true)
        #expect(gameSettings.speedBonusMultiplier == 2.5)
        #expect(gameSettings.perfectChainEnabled == true)
        #expect(gameSettings.perfectChainMultiplier == 0.1)
        #expect(gameSettings.numberedModeSpecialRule == "normal")
    }
    
    @Test func gameSettingsCustomValues() async throws {
        let gameSettings = GameSettings()
        
        // カスタム値設定
        gameSettings.numberedModeMaxLevel = 8
        gameSettings.numberedModeProgressive = false
        gameSettings.numberedModeLevelInterval = 25.0
        gameSettings.speedBonusMultiplier = 4.0
        gameSettings.numberedModeSpecialRule = "reverse"
        
        // 設定値確認
        #expect(gameSettings.numberedModeMaxLevel == 8)
        #expect(gameSettings.numberedModeProgressive == false)
        #expect(gameSettings.numberedModeLevelInterval == 25.0)
        #expect(gameSettings.speedBonusMultiplier == 4.0)
        #expect(gameSettings.numberedModeSpecialRule == "reverse")
    }
}