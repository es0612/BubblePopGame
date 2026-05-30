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
    
    // SwiftData ModelContainer setup
    var modelContainer: ModelContainer = {
        do {
            let schema = Schema([
                GameSettings.self,
                GameScore.self,
                GameStatistics.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // フォールバック: インメモリでの実行
            debugLog("Failed to create ModelContainer with persistent storage: \(error)")
            do {
                let schema = Schema([
                    GameSettings.self,
                    GameScore.self,
                    GameStatistics.self
                ])
                
                let fallbackConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                // 最終フォールバック
                fatalError("Failed to create fallback ModelContainer: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                .modelContainer(modelContainer)
                .task {
                    GameTimeDefaultMigration.runIfNeeded(
                        repository: SettingsRepositoryImpl(modelContainer: modelContainer)
                    )
                }
        }
    }
}
