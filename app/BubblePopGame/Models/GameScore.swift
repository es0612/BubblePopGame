//
//  GameScore.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftData

@Model
class GameScore {
    var id: UUID
    var score: Int
    var bubblesPopped: Int
    var accuracy: Double
    var gameMode: String
    var playDate: Date
    var gameDuration: TimeInterval
    
    init(score: Int, bubblesPopped: Int, accuracy: Double, gameMode: String, playDate: Date, gameDuration: TimeInterval) {
        self.id = UUID()
        self.score = score
        self.bubblesPopped = bubblesPopped
        self.accuracy = accuracy
        self.gameMode = gameMode
        self.playDate = playDate
        self.gameDuration = gameDuration
    }
}