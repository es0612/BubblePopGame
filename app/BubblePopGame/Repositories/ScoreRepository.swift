//
//  ScoreRepository.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftData

@MainActor
protocol ScoreRepository {
    func saveScore(_ score: GameScore) throws
    func fetchHighScores(limit: Int) throws -> [GameScore]
    func fetchScoresByMode(_ mode: String) throws -> [GameScore]
    func fetchScoresByModeAndTime(_ mode: String, gameTime: Double) throws -> [GameScore]
    func fetchAvailableGameTimes() throws -> [Double]
    func deleteScore(_ score: GameScore) throws
}

class ScoreRepositoryImpl: ScoreRepository {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    @MainActor
    func saveScore(_ score: GameScore) throws {
        let context = modelContainer.mainContext
        context.insert(score)
        try context.save()
    }
    
    @MainActor
    func fetchHighScores(limit: Int) throws -> [GameScore] {
        let context = modelContainer.mainContext
        var descriptor = FetchDescriptor<GameScore>(
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func fetchScoresByMode(_ mode: String) throws -> [GameScore] {
        let context = modelContainer.mainContext
        let predicate = #Predicate<GameScore> { score in
            score.gameMode == mode
        }
        
        let descriptor = FetchDescriptor<GameScore>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func fetchScoresByModeAndTime(_ mode: String, gameTime: Double) throws -> [GameScore] {
        let context = modelContainer.mainContext
        let predicate = #Predicate<GameScore> { score in
            score.gameMode == mode && score.gameTimeLimit == gameTime
        }
        
        let descriptor = FetchDescriptor<GameScore>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    @MainActor
    func fetchAvailableGameTimes() throws -> [Double] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<GameScore>()
        let allScores = try context.fetch(descriptor)
        
        // ユニークな制限時間を取得
        let uniqueTimes = Set(allScores.map { $0.gameTimeLimit })
        
        return Array(uniqueTimes).sorted()
    }
    
    @MainActor
    func deleteScore(_ score: GameScore) throws {
        let context = modelContainer.mainContext
        context.delete(score)
        try context.save()
    }
}