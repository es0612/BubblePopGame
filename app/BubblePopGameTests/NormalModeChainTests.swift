//
//  NormalModeChainTests.swift
//  BubblePopGameTests
//
//  #67: ノーマルモードの空振りでチェーンが切れること（スコアは 1 個 1 点のまま）
//

import Testing
import SwiftData
import SwiftUI
@testable import BubblePopGame

@MainActor
@Suite("ノーマルモードのチェーン (#67)")
struct NormalModeChainTests {

    static func makeViewModel() throws -> GameViewModel {
        let schema = Schema([GameScore.self, GameStatistics.self, GameSettings.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let settings = GameSettings()
        settings.gameMode = "normal"
        settings.soundEnabled = false
        settings.vibrationEnabled = false
        let vm = GameViewModel(
            bubbleService: BubbleServiceImpl(screenBounds: .zero),
            audioService: AudioServiceImpl(),
            effectService: EffectServiceImpl(),
            deviceService: DeviceServiceImpl(),
            performanceService: PerformanceServiceImpl(),
            scoreRepository: ScoreRepositoryImpl(modelContainer: container),
            settingsRepository: SettingsRepositoryImpl(modelContainer: container),
            statisticsRepository: StatisticsRepositoryImpl(modelContainer: container),
            gameSettings: settings
        )
        vm.gameState = .playing
        return vm
    }

    static func bubble(at point: CGPoint) -> Bubble {
        Bubble(
            position: point,
            velocity: .zero,
            radius: 30,
            type: .normal,
            number: nil,
            color: .blue,
            alpha: 1.0,
            animationPhase: 0
        )
    }

    static let first = CGPoint(x: 100, y: 300)
    static let second = CGPoint(x: 250, y: 300)
    static let empty = CGPoint(x: 600, y: 900)

    @Test("ヒットが続くとチェーンが伸びる")
    func hitsExtendChain() throws {
        let vm = try Self.makeViewModel()
        vm.bubbles = [Self.bubble(at: Self.first), Self.bubble(at: Self.second)]

        vm.handleBubbleTap(at: Self.first)
        vm.handleBubbleTap(at: Self.second)

        #expect(vm.currentStreak == 2)
        #expect(vm.bestStreak == 2)
    }

    @Test("空振りでチェーンが 0 に戻り、最大チェーンは割った数より小さくなる")
    func missResetsChain() throws {
        let vm = try Self.makeViewModel()
        vm.bubbles = [Self.bubble(at: Self.first), Self.bubble(at: Self.second)]

        vm.handleBubbleTap(at: Self.first)
        vm.handleBubbleTap(at: Self.empty)
        #expect(vm.currentStreak == 0)

        vm.handleBubbleTap(at: Self.second)
        #expect(vm.currentStreak == 1)
        #expect(vm.bestStreak == 1)
        #expect(vm.bubblesPopped == 2)
    }

    @Test("空振りを挟んでもスコアは 1 個 1 点のまま")
    func missDoesNotChangeScoring() throws {
        let vm = try Self.makeViewModel()
        vm.bubbles = [Self.bubble(at: Self.first), Self.bubble(at: Self.second)]

        vm.handleBubbleTap(at: Self.first)
        vm.handleBubbleTap(at: Self.empty)
        vm.handleBubbleTap(at: Self.second)

        #expect(vm.score == 2)
    }
}
