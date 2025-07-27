//
//  GameSettings.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftData

@Model
class GameSettings {
    var id: UUID
    var bubbleCount: Int
    var gameTime: Double
    var bubbleMinRadius: Double
    var bubbleMaxRadius: Double
    var animationSpeed: Double
    var soundEnabled: Bool
    var vibrationEnabled: Bool
    var gameMode: String
    var isFirstLaunch: Bool
    var bgmEnabled: Bool
    var bgmTrack: String
    var bgmVolume: Double
    var sfxVolume: Double
    
    // 数字モード設定
    var numberedModeMaxLevel: Int
    var numberedModeProgressive: Bool
    var numberedModeLevelInterval: Double
    var numberedModeMaxRange: Int
    var numberedModeStartRange: Int
    
    // ボーナス設定
    var speedBonusEnabled: Bool
    var speedBonusMultiplier: Double
    var perfectChainEnabled: Bool
    var perfectChainMultiplier: Double
    
    // 特殊ルール
    var numberedModeSpecialRule: String
    
    init() {
        self.id = UUID()
        self.bubbleCount = 20
        self.gameTime = 60.0
        self.bubbleMinRadius = 30.0
        self.bubbleMaxRadius = 60.0
        self.animationSpeed = 1.0
        self.soundEnabled = true
        self.vibrationEnabled = true
        self.gameMode = "normal" // "normal" or "numbered"
        self.isFirstLaunch = true
        self.bgmEnabled = true
        self.bgmTrack = "track1" // "off", "track1", "track2", "track3"
        self.bgmVolume = 0.7
        self.sfxVolume = 0.8
        
        // 数字モード設定のデフォルト値（バランス調整済み）
        self.numberedModeMaxLevel = 7 // 最大レベルを7に調整（より長く楽しめる）
        self.numberedModeProgressive = true
        self.numberedModeLevelInterval = 12.0 // 12秒間隔（よりテンポ良く）
        self.numberedModeMaxRange = 20 // 範囲を20に拡大（後半の難易度向上）
        self.numberedModeStartRange = 4 // 開始範囲を4に調整（初心者に優しく）
        
        // ボーナス設定のデフォルト値（バランス調整済み）
        self.speedBonusEnabled = true
        self.speedBonusMultiplier = 2.5 // 倍率を2.5に調整（適度な報酬）
        self.perfectChainEnabled = true
        self.perfectChainMultiplier = 0.15 // 0.15に調整（チェインボーナス強化）
        
        // 特殊ルールのデフォルト値
        self.numberedModeSpecialRule = "normal" // "normal", "reverse", "double", "random"
    }
}

