//
//  BubblePopGameApp.swift
//  BubblePopGame
//  
//  Created on 2025/07/17
//

import SwiftUI
import SwiftData

@main
struct BubblePopGameApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GameScore.self,
            GameSettings.self,
            GameStatistics.self
        ])
        
        // データマイグレーション設定
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // データマイグレーション後の初期化チェック
            performInitialDataMigration(container: container)
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // データマイグレーション処理
    static func performInitialDataMigration(container: ModelContainer) {
        let context = container.mainContext
        
        // 既存のデータがあるかチェック
        do {
            let settingsDescriptor = FetchDescriptor<GameSettings>()
            let existingSettings = try context.fetch(settingsDescriptor)
            
            // 設定データがない場合はデフォルト設定を作成
            if existingSettings.isEmpty {
                let defaultSettings = GameSettings()
                context.insert(defaultSettings)
                try context.save()
                print("Default settings created during migration")
            }
            
            // 統計データがない場合は初期化
            let statsDescriptor = FetchDescriptor<GameStatistics>()
            let existingStats = try context.fetch(statsDescriptor)
            
            if existingStats.isEmpty {
                let defaultStats = GameStatistics()
                context.insert(defaultStats)
                try context.save()
                print("Default statistics created during migration")
            }
            
        } catch {
            print("Migration failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
