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
    
    private let settingsRepository: SettingsRepository?
    private let audioService: AudioService?
    
    init(settingsRepository: SettingsRepository? = nil, audioService: AudioService? = nil) {
        self.settingsRepository = settingsRepository
        self.audioService = audioService
        
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
        
        // 初期化時にオーディオサービスに設定を適用
        applyAudioSettings()
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
        // チュートリアル完了状態は保持する
        let wasFirstLaunch = gameSettings.isFirstLaunch
        gameSettings = GameSettings()
        gameSettings.isFirstLaunch = wasFirstLaunch
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
    
    func toggleBGM() {
        gameSettings.bgmEnabled.toggle()
        applyAudioSettings()
        saveSettings()
    }
    
    func setBGMTrack(_ track: String) {
        gameSettings.bgmTrack = track
        applyAudioSettings()
        saveSettings()
    }
    
    private func applyAudioSettings() {
        guard let audioService = audioService else { return }
        
        // BGM設定を適用
        audioService.setBGMEnabled(gameSettings.bgmEnabled)
        
        // BGMが有効でトラックが"off"でない場合はBGMを再生
        if gameSettings.bgmEnabled && gameSettings.bgmTrack != "off" {
            audioService.playBGMTrack(gameSettings.bgmTrack, loop: true)
        }
        
        // 音量設定を適用
        audioService.setBGMVolume(Float(gameSettings.bgmVolume))
        audioService.setSFXVolume(Float(gameSettings.sfxVolume))
    }
}