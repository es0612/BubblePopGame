//
//  AudioSettingsTests.swift
//  BubblePopGameTests
//
//  #66: 音量スライダーの即時反映・効果音 OFF・リセット・フェードとの競合
//

import Testing
import Foundation
@testable import BubblePopGame

/// AudioService の呼び出しを記録するテスト用モック
final class SpyAudioService: AudioService {
    var playedTracks: [String] = []
    var bgmVolumes: [Float] = []
    var sfxVolumes: [Float] = []
    private(set) var isBGMEnabled: Bool = true
    private(set) var isSFXEnabled: Bool = true
    var currentBGMTrack: String?
    var isPlaying: Bool = false
    var isPaused: Bool = false

    func playBGM(name: String, loop: Bool) { playedTracks.append(name) }
    func playBGMTrack(_ track: String, loop: Bool) { playedTracks.append(track) }
    func setBGMEnabled(_ enabled: Bool) { isBGMEnabled = enabled }
    func setSFXEnabled(_ enabled: Bool) { isSFXEnabled = enabled }
    func playSFX(name: String) {}
    func setVolume(_ volume: Float) {}
    func setBGMVolume(_ volume: Float) { bgmVolumes.append(volume) }
    func setSFXVolume(_ volume: Float) { sfxVolumes.append(volume) }
    func toggleMute() {}
    func stopAllSounds() {}
    func stopBGM() {}
    func fadeOutBGM(duration: TimeInterval) {}
    func pauseBGM() {}
    func resumeBGM() {}
}

@MainActor
@Suite("音の設定の反映 (#66)")
struct AudioSettingsTests {

    // MARK: - 音量スライダー

    @Test("BGM 音量を変えると、トラックを再生し直さずに音量だけが AudioService に届く")
    func bgmVolumeAppliesImmediately() {
        let spy = SpyAudioService()
        let vm = SettingsViewModel(audioService: spy)
        let playedBefore = spy.playedTracks.count

        vm.setBGMVolume(0.0)

        #expect(vm.gameSettings.bgmVolume == 0.0)
        #expect(spy.bgmVolumes.last == 0.0)
        #expect(spy.playedTracks.count == playedBefore)
    }

    @Test("効果音音量を変えると、すぐに AudioService に届く")
    func sfxVolumeAppliesImmediately() {
        let spy = SpyAudioService()
        let vm = SettingsViewModel(audioService: spy)

        vm.setSFXVolume(0.3)

        #expect(vm.gameSettings.sfxVolume == 0.3)
        #expect(spy.sfxVolumes.last == Float(0.3))
    }

    // MARK: - 効果音 OFF

    @Test("効果音を OFF にすると AudioService の効果音も止まる")
    func toggleSoundDisablesSFX() {
        let spy = SpyAudioService()
        let vm = SettingsViewModel(audioService: spy)
        #expect(vm.gameSettings.soundEnabled)

        vm.toggleSound()

        #expect(spy.isSFXEnabled == false)
    }

    @Test("AudioServiceImpl は効果音 OFF のとき鳴らさない判定になる")
    func implRespectsSFXDisabled() {
        let service = AudioServiceImpl()
        #expect(service.canPlaySFX)

        service.setSFXEnabled(false)
        #expect(service.canPlaySFX == false)

        service.setSFXEnabled(true)
        service.setSFXVolume(0.0)
        #expect(service.canPlaySFX == false)
    }

    // MARK: - リセット

    @Test("BGM と効果音を OFF にしてからリセットすると、AudioService も ON に戻る")
    func resetReappliesAudioSettings() {
        let spy = SpyAudioService()
        let vm = SettingsViewModel(audioService: spy)
        vm.toggleBGM()
        vm.toggleSound()
        #expect(spy.isBGMEnabled == false)
        #expect(spy.isSFXEnabled == false)

        vm.resetToDefaults()

        #expect(spy.isBGMEnabled == true)
        #expect(spy.isSFXEnabled == true)
        #expect(spy.bgmVolumes.last == Float(vm.gameSettings.bgmVolume))
    }

    // MARK: - フェードとの競合

    @Test("フェードアウト中に BGM を再生し直すと、古いフェードが止まる")
    func playBGMCancelsPendingFade() {
        let service = AudioServiceImpl()
        service.playBGMTrack("track1", loop: true)
        service.fadeOutBGM(duration: 1.0)
        // 前提: 実際にフェードが始まっていること（始まっていなければこのテストは意味がない）
        #expect(service.isFadingOut)

        service.playBGMTrack("track1", loop: true)

        #expect(service.isFadingOut == false)
        service.stopAllSounds()
    }
}
