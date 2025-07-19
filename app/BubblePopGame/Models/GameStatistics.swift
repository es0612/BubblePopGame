//
//  GameStatistics.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftData

@Model
class GameStatistics {
    var id: UUID
    var totalGamesPlayed: Int
    var totalBubblesPopped: Int
    var totalPlayTime: TimeInterval
    var averageScore: Double
    var bestScore: Int
    var lastPlayDate: Date
    
    init() {
        self.id = UUID()
        self.totalGamesPlayed = 0
        self.totalBubblesPopped = 0
        self.totalPlayTime = 0
        self.averageScore = 0
        self.bestScore = 0
        self.lastPlayDate = Date()
    }
}