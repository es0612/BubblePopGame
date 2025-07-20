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
    func playSFX(name: String)
    func setVolume(_ volume: Float)
    func setBGMVolume(_ volume: Float)
    func setSFXVolume(_ volume: Float)
    func toggleMute()
    func stopAllSounds()
    func stopBGM()
    var isPlaying: Bool { get }
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
    
    var isPlaying: Bool {
        return bgmPlayer.isPlaying
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
            print("Audio engine start failed: \(error)")
        }
    }
    
    func playBGM(name: String, loop: Bool) {
        // BGMを停止
        bgmPlayer.stop()
        
        // 実際の音声ファイルがないので、システム音で代用
        generateSynthesizedBGM()
        print("Playing BGM: \(name), loop: \(loop)")
    }
    
    func playSFX(name: String) {
        // 効果音の種類に応じてシステム音で代用
        switch name {
        case "bubble_pop":
            generatePopSound()
        case "button_tap":
            generateButtonSound()
        case "game_over":
            generateGameOverSound()
        default:
            print("Playing SFX: \(name)")
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
        bgmPlayer.stop()
    }
    
    func stopAllSounds() {
        bgmPlayer.stop()
        for player in sfxPlayers.values {
            player.stop()
        }
    }
    
    private func updateVolumes() {
        let effectiveVolume = isMuted ? 0.0 : masterVolume
        bgmMixerNode.outputVolume = effectiveVolume * bgmVolume
        sfxMixerNode.outputVolume = effectiveVolume * sfxVolume
    }
    
    private func generateSynthesizedBGM() {
        // 実際のプロジェクトでは音声ファイルを使用
        print("🎵 BGM playing (synthesized)")
    }
    
    private func generatePopSound() {
        // シャボン玉破裂音をシミュレート
        AudioServicesPlaySystemSound(1306) // Pop sound
        print("🎵 Pop sound")
    }
    
    private func generateButtonSound() {
        // ボタンタップ音をシミュレート
        AudioServicesPlaySystemSound(1104) // Click sound
        print("🎵 Button sound")
    }
    
    private func generateGameOverSound() {
        // ゲームオーバー音をシミュレート
        AudioServicesPlaySystemSound(1322) // Anticipate sound
        print("🎵 Game over sound")
    }
}