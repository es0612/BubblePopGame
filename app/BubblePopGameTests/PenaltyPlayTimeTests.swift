//
//  PenaltyPlayTimeTests.swift
//  BubblePopGameTests
//
//  #101: 数字モードのまちがいのペナルティ（残り時間が減る）が「遊んだ時間」にも数えられ、
//  難しくなるのが早まり、リザルトのプレイ時間と記録も長くなっていた。
//  ペナルティは残り時間を減らすだけにし、難しさ・プレイ時間・記録は実際に遊んだ秒数で数える。
//

import Testing
import SwiftData
import SwiftUI
@testable import BubblePopGame

@MainActor
@Suite("まちがいのペナルティは遊んだ時間に入れない (#101)")
struct PenaltyPlayTimeTests {

    struct Fixture {
        let vm: GameViewModel
        let scores: ScoreRepositoryImpl
    }

    static func make(mode: String) throws -> Fixture {
        let schema = Schema([GameScore.self, GameStatistics.self, GameSettings.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let settings = GameSettings()
        settings.gameMode = mode
        settings.gameTime = 30
        settings.numberedModeProgressive = true
        settings.numberedModeLevelInterval = 12
        settings.soundEnabled = false
        settings.vibrationEnabled = false
        settings.bgmEnabled = false
        let scores = ScoreRepositoryImpl(modelContainer: container)
        let vm = GameViewModel(
            bubbleService: BubbleServiceImpl(screenBounds: .zero),
            audioService: SpyAudioService(),
            effectService: EffectServiceImpl(),
            deviceService: DeviceServiceImpl(),
            performanceService: PerformanceServiceImpl(),
            scoreRepository: scores,
            settingsRepository: SettingsRepositoryImpl(modelContainer: container),
            statisticsRepository: StatisticsRepositoryImpl(modelContainer: container),
            gameSettings: settings
        )
        vm.updateScreenBounds(CGSize(width: 400, height: 900))
        return Fixture(vm: vm, scores: scores)
    }

    /// 制限 30 秒の数字モードで、5 秒遊ぶ間に 2 回まちがえて 7 秒（3.5 × 2）減った状態
    static func playFiveSecondsWithTwoMistakes(_ vm: GameViewModel) {
        vm.gameState = .playing
        vm.timePenalty = 7
        vm.timeRemaining = 30 - 5 - 7
    }

    @Test("5 秒遊んでまちがい 2 回なら、レベルは 1 のまま（今まではペナルティ込みの 12 秒でレベル 2）")
    func levelIgnoresPenalty() throws {
        let vm = try Self.make(mode: "numbered").vm
        Self.playFiveSecondsWithTwoMistakes(vm)

        #expect(vm.calculateCurrentLevel() == 1)
    }

    @Test("リザルトのプレイ時間は、実際に遊んだ 5 秒")
    func resultPlaySecondsIgnorePenalty() throws {
        let vm = try Self.make(mode: "numbered").vm
        Self.playFiveSecondsWithTwoMistakes(vm)

        #expect(vm.elapsedPlaySeconds == 5)
    }

    @Test("記録に残るゲームの長さも、実際に遊んだ 5 秒")
    func savedDurationIgnoresPenalty() throws {
        let fixture = try Self.make(mode: "numbered")
        Self.playFiveSecondsWithTwoMistakes(fixture.vm)

        fixture.vm.endGame()

        let saved = try fixture.scores.fetchScoresByMode("numbered")
        #expect(saved.count == 1)
        #expect(saved.first?.gameDuration == 5)
    }

    @Test("数字モードのペナルティは、次にノーマルモードで始めたゲームに持ち越さない")
    func penaltyResetsOnNextNormalGame() throws {
        let vm = try Self.make(mode: "numbered").vm
        vm.timePenalty = 7

        vm.gameSettings.gameMode = "normal"
        vm.startGame()
        let penaltyAfterStart = vm.timePenalty
        // 開始でゲームループとタイマーが動き出すので、すぐ止める
        vm.pauseGame()

        #expect(penaltyAfterStart == 0)
    }
}
