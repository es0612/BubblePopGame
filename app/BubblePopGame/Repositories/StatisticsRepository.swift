//
//  StatisticsRepository.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftData

protocol StatisticsRepository {
    func updateStatistics(with score: GameScore) throws
    func fetchStatistics() throws -> GameStatistics?
    func resetStatistics() throws
}

class StatisticsRepositoryImpl: StatisticsRepository {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    @MainActor
    func updateStatistics(with score: GameScore) throws {
        let context = modelContainer.mainContext
        
        // 既存の統計情報を取得
        let descriptor = FetchDescriptor<GameStatistics>()
        let existingStats = try context.fetch(descriptor)
        
        let statistics: GameStatistics
        if let existing = existingStats.first {
            statistics = existing
        } else {
            statistics = GameStatistics()
            context.insert(statistics)
        }
        
        // 統計情報更新
        statistics.totalGamesPlayed += 1
        statistics.totalBubblesPopped += score.bubblesPopped
        statistics.totalPlayTime += score.gameDuration
        
        // 平均スコア計算
        let totalScore = statistics.averageScore * Double(statistics.totalGamesPlayed - 1) + Double(score.score)
        statistics.averageScore = totalScore / Double(statistics.totalGamesPlayed)
        
        // ベストスコア更新
        if score.score > statistics.bestScore {
            statistics.bestScore = score.score
        }
        
        statistics.lastPlayDate = score.playDate
        
        try context.save()
    }
    
    @MainActor
    func fetchStatistics() throws -> GameStatistics? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<GameStatistics>()
        
        let statistics = try context.fetch(descriptor)
        return statistics.first
    }
    
    @MainActor
    func resetStatistics() throws {
        let context = modelContainer.mainContext
        
        let descriptor = FetchDescriptor<GameStatistics>()
        let existingStats = try context.fetch(descriptor)
        for stats in existingStats {
            context.delete(stats)
        }
        
        let newStats = GameStatistics()
        context.insert(newStats)
        try context.save()
    }
}