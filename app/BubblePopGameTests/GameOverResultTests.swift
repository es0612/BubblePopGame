//
//  GameOverResultTests.swift
//  BubblePopGameTests
//
//  #37: リザルトのプレイ時間表示（%d に Double を渡す 0 sec バグの回帰防止）
//

import Testing
import SwiftData
import Foundation
@testable import BubblePopGame

@MainActor
@Suite("リザルト プレイ時間表示 (#37)")
struct GameOverResultTests {

    static func makeViewModel(gameTime: Double = 30.0) throws -> GameViewModel {
        let schema = Schema([GameScore.self, GameStatistics.self, GameSettings.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let settings = GameSettings()
        settings.gameTime = gameTime
        return GameViewModel(
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
    }

    @Test("経過プレイ秒数は effectiveGameTime - timeRemaining を整数で返す")
    func elapsedPlaySecondsComputesInteger() throws {
        let vm = try Self.makeViewModel(gameTime: 30.0)
        vm.timeRemaining = 10.0
        #expect(vm.elapsedPlaySeconds == 20)
    }

    @Test("タイムアップ（timeRemaining=0）でプレイ秒数は満了時間")
    func elapsedPlaySecondsAtTimeout() throws {
        let vm = try Self.makeViewModel(gameTime: 30.0)
        vm.timeRemaining = 0.0
        #expect(vm.elapsedPlaySeconds == 30)
    }

    @Test("ゲーム未開始（timeRemaining=満了）でプレイ秒数は0")
    func elapsedPlaySecondsBeforePlay() throws {
        let vm = try Self.makeViewModel(gameTime: 30.0)
        vm.timeRemaining = 30.0
        #expect(vm.elapsedPlaySeconds == 0)
    }
}
