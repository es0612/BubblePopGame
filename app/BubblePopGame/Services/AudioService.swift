//
//  AudioService.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import AVFoundation

protocol AudioService {
    func playBGM(name: String, loop: Bool)
    func playBGMTrack(_ track: String, loop: Bool)
    func setBGMEnabled(_ enabled: Bool)
    func playSFX(name: String)
    func setVolume(_ volume: Float)
    func setBGMVolume(_ volume: Float)
    func setSFXVolume(_ volume: Float)
    func toggleMute()
    func stopAllSounds()
    func stopBGM()
    func fadeOutBGM(duration: TimeInterval)
    func pauseBGM()
    func resumeBGM()
    var isPlaying: Bool { get }
    var isBGMEnabled: Bool { get }
    var currentBGMTrack: String? { get }
    var isPaused: Bool { get }
}

class AudioServiceImpl: AudioService {
    private var audioEngine: AVAudioEngine
    private var bgmPlayer: AVAudioPlayerNode
    private var sfxPlayers: [String: AVAudioPlayerNode]
    private var isMuted: Bool = false
    private var masterVolume: Float = 1.0
    private var bgmVolume: Float = 0.7
    private var sfxVolume: Float = 0.8
    private var bgmMixerNode: AVAudioMixerNode
    private var sfxMixerNode: AVAudioMixerNode
    
    // 実際のBGM再生用のAVAudioPlayer
    private var bgmAudioPlayer: AVAudioPlayer?
    private var _isBGMEnabled: Bool = true
    private var _currentBGMTrack: String?
    private var _isPaused: Bool = false
    private var fadingTimer: Timer?
    
    var isPlaying: Bool {
        return bgmAudioPlayer?.isPlaying ?? false
    }
    
    var isBGMEnabled: Bool {
        return _isBGMEnabled
    }
    
    var currentBGMTrack: String? {
        return _currentBGMTrack
    }
    
    var isPaused: Bool {
        return _isPaused
    }
    
    init() {
        self.audioEngine = AVAudioEngine()
        self.bgmPlayer = AVAudioPlayerNode()
        self.sfxPlayers = [:]
        self.bgmMixerNode = AVAudioMixerNode()
        self.sfxMixerNode = AVAudioMixerNode()
        
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        // ミキサーノードをアタッチ
        audioEngine.attach(bgmMixerNode)
        audioEngine.attach(sfxMixerNode)
        audioEngine.attach(bgmPlayer)
        
        // BGMプレイヤーをBGMミキサーに接続
        audioEngine.connect(bgmPlayer, to: bgmMixerNode, format: nil)
        
        // ミキサーをメインミキサーに接続
        audioEngine.connect(bgmMixerNode, to: audioEngine.mainMixerNode, format: nil)
        audioEngine.connect(sfxMixerNode, to: audioEngine.mainMixerNode, format: nil)
        
        // 初期音量設定
        updateVolumes()
        
        do {
            try audioEngine.start()
        } catch {
            debugLog("Audio engine start failed: \(error)")
        }
    }
    
    func playBGM(name: String, loop: Bool) {
        // 後方互換性のため、従来の呼び出しをtrack1にマッピング
        playBGMTrack("track1", loop: loop)
    }
    
    func playBGMTrack(_ track: String, loop: Bool) {
        guard _isBGMEnabled && track != "off" else {
            stopBGM()
            return
        }
        
        // 現在再生中のBGMを停止
        bgmAudioPlayer?.stop()
        
        // ファイル名をマッピング
        let fileName: String
        let resourceName: String
        switch track {
        case "track1":
            fileName = "1.mp3"
            resourceName = "1"
        case "track2":
            fileName = "2.mp3"
            resourceName = "2"
        case "track3":
            fileName = "3.mp3"
            resourceName = "3"
        default:
            debugLog("Unknown BGM track: \(track)")
            return
        }
        
        // バンドルからファイルを取得（複数の方法で試行）
        var url: URL?
        
        // 方法1: メインバンドルから直接検索（最も可能性が高い）
        if let bundlePath = Bundle.main.path(forResource: resourceName, ofType: "mp3") {
            url = URL(fileURLWithPath: bundlePath)
            debugLog("🔍 Found BGM file in main bundle: \(bundlePath)")
        }
        // 方法2: Bgmディレクトリ内からファイルを検索
        else if let bundlePath = Bundle.main.path(forResource: resourceName, ofType: "mp3", inDirectory: "Bgm") {
            url = URL(fileURLWithPath: bundlePath)
            debugLog("🔍 Found BGM file in Bgm directory: \(bundlePath)")
        }
        // 方法3: Bgmディレクトリでファイルタイプにextensionを含めて検索
        else if let bundlePath = Bundle.main.path(forResource: fileName, ofType: nil, inDirectory: "Bgm") {
            url = URL(fileURLWithPath: bundlePath)
            debugLog("🔍 Found BGM file with full name: \(bundlePath)")
        }
        
        guard let audioURL = url else {
            debugLog("❌ BGM file not found: \(fileName)")
            debugLog("📁 Bundle contents debug:")
            let bundlePath = Bundle.main.bundlePath
            debugLog("   Bundle path: \(bundlePath)")
            if let resourcePath = Bundle.main.resourcePath {
                debugLog("   Resource path: \(resourcePath)")
                // Bgmディレクトリの存在確認
                let bgmPath = "\(resourcePath)/Bgm"
                debugLog("   Bgm directory exists: \(FileManager.default.fileExists(atPath: bgmPath))")
            }
            // フォールバック: システム音で代用
            generateSynthesizedBGM()
            return
        }
        
        do {
            // AVAudioPlayerを作成して再生
            bgmAudioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            bgmAudioPlayer?.numberOfLoops = loop ? -1 : 0  // -1は無限ループ
            bgmAudioPlayer?.volume = Float(bgmVolume * masterVolume * (isMuted ? 0.0 : 1.0))
            
            let success = bgmAudioPlayer?.play() ?? false
            if success {
                _currentBGMTrack = track
                debugLog("🎵 Playing BGM track: \(track) (\(fileName))")
            } else {
                debugLog("❌ Failed to play BGM track: \(track)")
                generateSynthesizedBGM() // フォールバック
            }
        } catch {
            debugLog("❌ Error loading BGM file \(fileName): \(error)")
            generateSynthesizedBGM() // フォールバック
        }
    }
    
    func setBGMEnabled(_ enabled: Bool) {
        _isBGMEnabled = enabled
        
        if !enabled {
            stopBGM()
        } else if let track = _currentBGMTrack {
            // BGMが有効化された場合、前回のトラックを再生
            playBGMTrack(track, loop: true)
        }
    }
    
    func playSFX(name: String) {
        // 効果音の種類に応じてシステム音で代用（音量調整対応）
        switch name {
        case "bubble_pop":
            generatePopSound()
        case "button_tap":
            generateButtonSound()
        case "game_over":
            generateGameOverSound()
        case "error_sound":
            generateErrorSound()
        case "level_up":
            generateLevelUpSound()
        default:
            debugLog("Playing SFX: \(name)")
        }
    }
    
    func setVolume(_ volume: Float) {
        masterVolume = max(0.0, min(1.0, volume))
        updateVolumes()
    }
    
    func setBGMVolume(_ volume: Float) {
        bgmVolume = max(0.0, min(1.0, volume))
        updateVolumes()
    }
    
    func setSFXVolume(_ volume: Float) {
        sfxVolume = max(0.0, min(1.0, volume))
        updateVolumes()
    }
    
    func toggleMute() {
        isMuted.toggle()
        updateVolumes()
    }
    
    func stopBGM() {
        fadingTimer?.invalidate()
        fadingTimer = nil
        bgmAudioPlayer?.stop()
        bgmPlayer.stop()
        _currentBGMTrack = nil
        _isPaused = false
    }
    
    func fadeOutBGM(duration: TimeInterval) {
        guard let player = bgmAudioPlayer, player.isPlaying else { return }
        
        fadingTimer?.invalidate()
        
        let originalVolume = player.volume
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = originalVolume / Float(steps)
        
        var currentStep = 0
        
        fadingTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            let newVolume = originalVolume - (volumeStep * Float(currentStep))
            
            if currentStep >= steps || newVolume <= 0 {
                timer.invalidate()
                self?.fadingTimer = nil
                self?.stopBGM()
            } else {
                player.volume = newVolume
            }
        }
    }
    
    func pauseBGM() {
        bgmAudioPlayer?.pause()
        _isPaused = true
    }
    
    func resumeBGM() {
        if _isPaused && bgmAudioPlayer != nil {
            bgmAudioPlayer?.play()
            _isPaused = false
        }
    }
    
    func stopAllSounds() {
        fadingTimer?.invalidate()
        fadingTimer = nil
        bgmAudioPlayer?.stop()
        bgmPlayer.stop()
        _currentBGMTrack = nil
        _isPaused = false
        for player in sfxPlayers.values {
            player.stop()
        }
    }
    
    private func updateVolumes() {
        let effectiveVolume = isMuted ? 0.0 : masterVolume
        
        // 実際のBGMプレイヤーの音量を更新
        if let player = bgmAudioPlayer {
            player.volume = Float(effectiveVolume * bgmVolume)
        }
        
        // 従来のAudioEngine音量も更新（フォールバック用）
        bgmMixerNode.outputVolume = effectiveVolume * bgmVolume
        sfxMixerNode.outputVolume = effectiveVolume * sfxVolume
    }
    
    private func generateSynthesizedBGM() {
        // 実際のプロジェクトでは音声ファイルを使用
        debugLog("🎵 BGM playing (synthesized)")
    }
    
    private func generatePopSound() {
        // シャボン玉破裂音をシミュレート（音量調整対応）
        if !isMuted && sfxVolume > 0 {
            AudioServicesPlaySystemSound(1306) // Pop sound
        }
        debugLog("🎵 Pop sound (volume: \(sfxVolume))")  
    }
    
    private func generateButtonSound() {
        // ボタンタップ音をシミュレート（音量調整対応）
        if !isMuted && sfxVolume > 0 {
            AudioServicesPlaySystemSound(1104) // Click sound
        }
        debugLog("🎵 Button sound (volume: \(sfxVolume))")
    }
    
    private func generateGameOverSound() {
        // ゲームオーバー音をシミュレート（音量調整対応）
        if !isMuted && sfxVolume > 0 {
            AudioServicesPlaySystemSound(1322) // Anticipate sound
        }
        debugLog("🎵 Game over sound (volume: \(sfxVolume))")
    }
    
    private func generateErrorSound() {
        // エラー音をシミュレート（音量調整対応）
        if !isMuted && sfxVolume > 0 {
            AudioServicesPlaySystemSound(1521) // Error sound
        }
        debugLog("🎵 Error sound (volume: \(sfxVolume))")
    }
    
    private func generateLevelUpSound() {
        // レベルアップ音をシミュレート（音量調整対応）
        if !isMuted && sfxVolume > 0 {
            AudioServicesPlaySystemSound(1315) // Success sound
        }
        debugLog("🎵 Level up sound (volume: \(sfxVolume))")
    }
}