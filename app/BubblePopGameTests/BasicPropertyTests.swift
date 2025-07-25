//
//  BasicPropertyTests.swift
//  BubblePopGameTests
//
//  Created on 2025/07/24
//

import Testing
import Foundation
@testable import BubblePopGame

// GameSettingsの統合テストスイート
struct GameSettingsTests {
    
    @Test func defaultValuesTest() async throws {
        let settings = GameSettings()
        
        // 基本プロパティのデフォルト値テスト
        #expect(settings.bubbleCount == 20)
        #expect(settings.gameTime == 60.0)
        #expect(settings.bubbleMinRadius == 30.0)
        #expect(settings.bubbleMaxRadius == 60.0)
        #expect(settings.animationSpeed == 1.0)
        #expect(settings.soundEnabled == true)
        #expect(settings.vibrationEnabled == true)
        #expect(settings.gameMode == "normal")
        #expect(settings.isFirstLaunch == true)
        #expect(settings.bgmEnabled == true)
        #expect(settings.bgmTrack == "track1")
    }
    
    @Test func numberedModeDefaultValuesTest() async throws {
        let settings = GameSettings()
        
        // 数字モード設定のデフォルト値テスト
        #expect(settings.numberedModeMaxLevel == 7)
        #expect(settings.numberedModeProgressive == true)
        #expect(settings.numberedModeLevelInterval == 12.0)
        #expect(settings.numberedModeMaxRange == 20)
        #expect(settings.numberedModeStartRange == 4)
    }
    
    @Test func bonusSettingsDefaultValuesTest() async throws {
        let settings = GameSettings()
        
        // ボーナス設定のデフォルト値テスト
        #expect(settings.speedBonusEnabled == true)
        #expect(settings.speedBonusMultiplier == 2.5)
        #expect(settings.perfectChainEnabled == true)
        #expect(settings.perfectChainMultiplier == 0.15)
    }
    
    @Test func specialRuleDefaultValueTest() async throws {
        let settings = GameSettings()
        
        // 特殊ルールのデフォルト値テスト
        #expect(settings.numberedModeSpecialRule == "normal")
    }
    
    @Test func validationRangesTest() async throws {
        let settings = GameSettings()
        
        // 数値範囲の妥当性テスト
        #expect(settings.numberedModeMaxLevel >= 1)
        #expect(settings.numberedModeMaxLevel <= 10)
        #expect(settings.numberedModeLevelInterval >= 5.0)
        #expect(settings.numberedModeLevelInterval <= 60.0)
        #expect(settings.numberedModeMaxRange >= settings.numberedModeStartRange)
        #expect(settings.numberedModeStartRange >= 2)
        #expect(settings.numberedModeMaxRange <= 50)
        #expect(settings.speedBonusMultiplier >= 1.0)
        #expect(settings.speedBonusMultiplier <= 10.0)
        #expect(settings.perfectChainMultiplier >= 0.01)
        #expect(settings.perfectChainMultiplier <= 1.0)
    }
    
    @Test func bubbleSettingsValidationTest() async throws {
        let settings = GameSettings()
        
        // バブル設定の妥当性テスト
        #expect(settings.bubbleCount >= 5)
        #expect(settings.bubbleCount <= 100)
        #expect(settings.gameTime >= 10.0)
        #expect(settings.gameTime <= 300.0)
        #expect(settings.bubbleMinRadius >= 10.0)
        #expect(settings.bubbleMaxRadius <= 100.0)
        #expect(settings.bubbleMinRadius < settings.bubbleMaxRadius)
        #expect(settings.animationSpeed >= 0.1)
        #expect(settings.animationSpeed <= 5.0)
    }
    
    @Test func validGameModeTest() async throws {
        let settings = GameSettings()
        
        // ゲームモードの妥当性テスト
        let validGameModes = ["normal", "numbered"]
        #expect(validGameModes.contains(settings.gameMode))
    }
    
    @Test func validSpecialRuleTest() async throws {
        let settings = GameSettings()
        
        // 特殊ルールの妥当性テスト
        let validSpecialRules = ["normal", "reverse", "double", "random"]
        #expect(validSpecialRules.contains(settings.numberedModeSpecialRule))
    }
    
    @Test func validBgmTrackTest() async throws {
        let settings = GameSettings()
        
        // BGMトラックの妥当性テスト
        let validBgmTracks = ["off", "track1", "track2", "track3"]
        #expect(validBgmTracks.contains(settings.bgmTrack))
    }
}