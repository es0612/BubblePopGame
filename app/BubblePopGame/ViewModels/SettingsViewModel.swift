//
//  SettingsViewModel.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation

@Observable
@MainActor
class SettingsViewModel {
    var gameSettings: GameSettings
    var bgmVolume: Double = 0.7
    var sfxVolume: Double = 0.8
    
    private let settingsRepository: SettingsRepository?
    
    init(settingsRepository: SettingsRepository? = nil) {
        self.settingsRepository = settingsRepository
        
        // 保存された設定を読み込み、なければデフォルト設定を使用
        if let repository = settingsRepository {
            do {
                self.gameSettings = try repository.fetchSettings() ?? GameSettings()
            } catch {
                print("Failed to load settings: \(error)")
                self.gameSettings = GameSettings()
            }
        } else {
            self.gameSettings = GameSettings()
        }
    }
    
    func saveSettings() {
        guard let repository = settingsRepository else {
            print("SettingsRepository not available")
            return
        }
        
        do {
            try repository.saveSettings(gameSettings)
            print("Settings saved successfully")
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    func resetToDefaults() {
        gameSettings = GameSettings()
        saveSettings()
    }
    
    func toggleSound() {
        gameSettings.soundEnabled.toggle()
        saveSettings()
    }
    
    func toggleVibration() {
        gameSettings.vibrationEnabled.toggle()
        saveSettings()
    }
}