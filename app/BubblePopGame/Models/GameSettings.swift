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
    }
}