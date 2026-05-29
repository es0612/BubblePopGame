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
                debugLog("Failed to load settings: \(error)")
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
            debugLog("SettingsRepository not available")
            return
        }
        
        do {
            try repository.saveSettings(gameSettings)
            debugLog("Settings saved successfully")
        } catch {
            debugLog("Failed to save settings: \(error)")
        }
    }
    
    func resetToDefaults() {
        // チュートリアル完了状態は保持する
        let wasFirstLaunch = gameSettings.isFirstLaunch
        
        // 既存オブジェクトのプロパティを個別に更新（SwiftDataの追跡を維持）
        let defaultSettings = GameSettings()
        gameSettings.bubbleCount = defaultSettings.bubbleCount
        gameSettings.gameTime = defaultSettings.gameTime
        gameSettings.bubbleMinRadius = defaultSettings.bubbleMinRadius
        gameSettings.bubbleMaxRadius = defaultSettings.bubbleMaxRadius
        gameSettings.animationSpeed = defaultSettings.animationSpeed
        gameSettings.soundEnabled = defaultSettings.soundEnabled
        gameSettings.vibrationEnabled = defaultSettings.vibrationEnabled
        gameSettings.gameMode = defaultSettings.gameMode
        gameSettings.bgmEnabled = defaultSettings.bgmEnabled
        gameSettings.bgmTrack = defaultSettings.bgmTrack
        gameSettings.bgmVolume = defaultSettings.bgmVolume
        gameSettings.sfxVolume = defaultSettings.sfxVolume
        gameSettings.numberedModeMaxLevel = defaultSettings.numberedModeMaxLevel
        gameSettings.numberedModeProgressive = defaultSettings.numberedModeProgressive
        gameSettings.numberedModeLevelInterval = defaultSettings.numberedModeLevelInterval
        gameSettings.numberedModeMaxRange = defaultSettings.numberedModeMaxRange
        gameSettings.numberedModeStartRange = defaultSettings.numberedModeStartRange
        gameSettings.speedBonusEnabled = defaultSettings.speedBonusEnabled
        gameSettings.speedBonusMultiplier = defaultSettings.speedBonusMultiplier
        gameSettings.perfectChainEnabled = defaultSettings.perfectChainEnabled
        gameSettings.perfectChainMultiplier = defaultSettings.perfectChainMultiplier
        gameSettings.numberedModeSpecialRule = defaultSettings.numberedModeSpecialRule
        
        // チュートリアル完了状態を復元
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