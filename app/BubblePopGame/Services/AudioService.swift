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
    func toggleMute()
    func stopAllSounds()
}

class AudioServiceImpl: AudioService {
    private var audioEngine: AVAudioEngine
    private var bgmPlayer: AVAudioPlayerNode
    private var sfxPlayers: [String: AVAudioPlayerNode]
    private var isMuted: Bool = false
    private var currentVolume: Float = 1.0
    
    init() {
        self.audioEngine = AVAudioEngine()
        self.bgmPlayer = AVAudioPlayerNode()
        self.sfxPlayers = [:]
        
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(bgmPlayer)
        audioEngine.connect(bgmPlayer, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start failed: \(error)")
        }
    }
    
    func playBGM(name: String, loop: Bool) {
        // TODO: BGM再生実装（音声ファイルが必要）
        print("Playing BGM: \(name), loop: \(loop)")
    }
    
    func playSFX(name: String) {
        // TODO: 効果音再生実装（音声ファイルが必要）
        print("Playing SFX: \(name)")
    }
    
    func setVolume(_ volume: Float) {
        currentVolume = max(0.0, min(1.0, volume))
        audioEngine.mainMixerNode.outputVolume = isMuted ? 0.0 : currentVolume
    }
    
    func toggleMute() {
        isMuted.toggle()
        audioEngine.mainMixerNode.outputVolume = isMuted ? 0.0 : currentVolume
    }
    
    func stopAllSounds() {
        bgmPlayer.stop()
        for player in sfxPlayers.values {
            player.stop()
        }
    }
}