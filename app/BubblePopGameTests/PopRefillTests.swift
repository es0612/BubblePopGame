//
//  PopRefillTests.swift
//  BubblePopGameTests
//
//  #69: 割れた泡の 0.3 秒後の後片付け（削除と補充）が、ゲームの状態を見ていなかった。
//  - ポーズ中に新しい泡が現れる
//  - ゲーム終了後にも泡を足す
//  - 数字モードでセットを作り直した直後にも足すので、セットを完了するたびに 1 個ずつ増える
//

import Testing
import SwiftData
import SwiftUI
@testable import BubblePopGame

@MainActor
@Suite("割れた泡の後片付けと補充 (#69)")
struct PopRefillTests {

    static func makeViewModel(mode: String) throws -> GameViewModel {
        let schema = Schema([GameScore.self, GameStatistics.self, GameSettings.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let settings = GameSettings()
        settings.gameMode = mode
        settings.soundEnabled = false
        settings.vibrationEnabled = false
        settings.bgmEnabled = false
        let vm = GameViewModel(
            bubbleService: BubbleServiceImpl(screenBounds: .zero),
            audioService: SpyAudioService(),
            effectService: EffectServiceImpl(),
            deviceService: DeviceServiceImpl(),
            performanceService: PerformanceServiceImpl(),
            scoreRepository: ScoreRepositoryImpl(modelContainer: container),
            settingsRepository: SettingsRepositoryImpl(modelContainer: container),
            statisticsRepository: StatisticsRepositoryImpl(modelContainer: container),
            gameSettings: settings
        )
        // 補充の泡は screenBounds の中に置かれるので、有効なサイズを先に入れる
        vm.updateScreenBounds(CGSize(width: 400, height: 900))
        vm.gameState = .playing
        return vm
    }

    static func bubble(at point: CGPoint, type: BubbleType = .normal, number: Int? = nil) -> Bubble {
        Bubble(
            position: point,
            velocity: .zero,
            radius: 30,
            type: type,
            number: number,
            color: .blue,
            alpha: 1.0,
            animationPhase: 0
        )
    }

    static let first = CGPoint(x: 100, y: 300)
    static let second = CGPoint(x: 250, y: 300)

    /// 破裂アニメーション（0.3 秒）の後片付けが終わるまで待つ
    static func waitForPopCleanup() async throws {
        try await Task.sleep(for: .milliseconds(600))
    }

    @Test("プレイ中に割った泡は消え、代わりの泡が 1 個足される")
    func playingRefills() async throws {
        let vm = try Self.makeViewModel(mode: "normal")
        let popped = Self.bubble(at: Self.first)
        vm.bubbles = [popped, Self.bubble(at: Self.second)]

        vm.handleBubbleTap(at: Self.first)
        try await Self.waitForPopCleanup()

        #expect(!vm.bubbles.contains { $0.id == popped.id })
        #expect(vm.bubbles.count == 2)
    }

    @Test("ポーズ中は代わりの泡を足さない")
    func pausedDoesNotRefill() async throws {
        let vm = try Self.makeViewModel(mode: "normal")
        let popped = Self.bubble(at: Self.first)
        vm.bubbles = [popped, Self.bubble(at: Self.second)]

        vm.handleBubbleTap(at: Self.first)
        vm.pauseGame()
        try await Self.waitForPopCleanup()

        #expect(!vm.bubbles.contains { $0.id == popped.id })
        #expect(vm.bubbles.count == 1)
    }

    @Test("ポーズ中に足さなかった分は、再開したときに足す")
    func resumeRefillsPending() async throws {
        let vm = try Self.makeViewModel(mode: "normal")
        vm.bubbles = [Self.bubble(at: Self.first), Self.bubble(at: Self.second)]

        vm.handleBubbleTap(at: Self.first)
        vm.pauseGame()
        try await Self.waitForPopCleanup()
        #expect(vm.bubbles.count == 1)

        vm.resumeGame()
        let countAfterResume = vm.bubbles.count
        // 再開でゲームループとタイマーが動き出すので、すぐ止める
        vm.pauseGame()

        #expect(countAfterResume == 2)
    }

    @Test("ゲーム終了後は代わりの泡を足さない")
    func gameOverDoesNotRefill() async throws {
        let vm = try Self.makeViewModel(mode: "normal")
        let popped = Self.bubble(at: Self.first)
        vm.bubbles = [popped, Self.bubble(at: Self.second)]

        vm.handleBubbleTap(at: Self.first)
        vm.gameState = .gameOver
        try await Self.waitForPopCleanup()

        #expect(!vm.bubbles.contains { $0.id == popped.id })
        #expect(vm.bubbles.count == 1)
    }

    @Test("数字モードでセットを作り直したときは、作り直す前に割った泡の補充をしない")
    func numberedSetRegenerationDoesNotAddExtra() async throws {
        let vm = try Self.makeViewModel(mode: "numbered")
        vm.currentNumberSet = [1]
        vm.currentNumberIndex = 0
        vm.nextExpectedNumber = 1
        vm.bubbles = [Self.bubble(at: Self.first, type: .numbered, number: 1)]

        // セットの最後の数字を割る → 新しいセットで泡が作り直される
        vm.handleBubbleTap(at: Self.first)
        let countAfterRegeneration = vm.bubbles.count
        #expect(countAfterRegeneration > 0)

        try await Self.waitForPopCleanup()

        #expect(vm.bubbles.count == countAfterRegeneration)
    }
}
