//
//  DebugOverrideTests.swift
//  BubblePopGameTests
//
//  Issue #13: デバッグ起動引数による gameTime / gameMode override の単体テスト。
//  永続 gameSettings を変更せず、effectiveGameTime / effectiveGameMode で実効値を
//  差し替える設計を検証する。
//

import Testing
import SwiftData
import Foundation
@testable import BubblePopGame

@MainActor
@Suite("DEBUG override (game-time / game-mode)")
struct DebugOverrideTests {

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([GameScore.self, GameStatistics.self, GameSettings.self])
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    static func makeViewModel(gameTime: Double = 60, gameMode: String = "normal") throws -> GameViewModel {
        let container = try makeContainer()
        let settings = GameSettings()
        settings.gameTime = gameTime
        settings.gameMode = gameMode
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

    @Test("override 未設定なら gameSettings の値にフォールバックする")
    func fallsBackToSettingsWhenNoOverride() throws {
        let vm = try Self.makeViewModel(gameTime: 60, gameMode: "normal")
        #expect(vm.effectiveGameTime == 60)
        #expect(vm.effectiveGameMode == "normal")
    }

    @Test("debugGameTimeOverride が effectiveGameTime に反映される")
    func gameTimeOverrideApplies() throws {
        let vm = try Self.makeViewModel(gameTime: 60)
        vm.debugGameTimeOverride = 30
        #expect(vm.effectiveGameTime == 30)
        // 永続モデルは変更されないこと
        #expect(vm.gameSettings.gameTime == 60)
    }

    @Test("debugGameModeOverride が effectiveGameMode に反映される")
    func gameModeOverrideApplies() throws {
        let vm = try Self.makeViewModel(gameMode: "normal")
        vm.debugGameModeOverride = "numbered"
        #expect(vm.effectiveGameMode == "numbered")
        // 永続モデルは変更されないこと
        #expect(vm.gameSettings.gameMode == "normal")
    }

    @Test("startGame の timeRemaining が override 値で初期化される（実効値が read される）")
    func startGameUsesOverriddenTime() throws {
        let vm = try Self.makeViewModel(gameTime: 60)
        vm.debugGameTimeOverride = 30
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        vm.startGame()
        #expect(vm.timeRemaining == 30,
                "startGame は effectiveGameTime を read するため override が反映される")
    }
}
