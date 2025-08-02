//
//  SettingsRepository.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftData

@MainActor
protocol SettingsRepository {
    func saveSettings(_ settings: GameSettings) throws
    func fetchSettings() throws -> GameSettings?
    func resetToDefaults() throws
}

class SettingsRepositoryImpl: SettingsRepository {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    @MainActor
    func saveSettings(_ settings: GameSettings) throws {
        let context = modelContainer.mainContext
        
        // 設定がまだコンテキストに追加されていない場合のみ追加
        if settings.modelContext == nil {
            // 既存の設定があれば削除してから新しい設定を追加
            let descriptor = FetchDescriptor<GameSettings>()
            let existingSettings = try context.fetch(descriptor)
            for existing in existingSettings {
                context.delete(existing)
            }
            context.insert(settings)
        }
        
        // SwiftDataは自動的に変更を追跡するため、明示的な保存で永続化
        try context.save()
    }
    
    @MainActor
    func fetchSettings() throws -> GameSettings? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<GameSettings>()
        
        let settings = try context.fetch(descriptor)
        return settings.first
    }
    
    @MainActor
    func resetToDefaults() throws {
        let defaultSettings = GameSettings()
        try saveSettings(defaultSettings)
    }
}