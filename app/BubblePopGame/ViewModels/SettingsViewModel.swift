//
//  SettingsViewModel.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation

@Observable
class SettingsViewModel {
    var gameSettings: GameSettings
    var bgmVolume: Double = 0.7
    var sfxVolume: Double = 0.8
    
    init() {
        // 初期設定として空のGameSettingsを作成
        self.gameSettings = GameSettings()
    }
    
    func saveSettings() {
        // TODO: Repository経由で設定保存
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