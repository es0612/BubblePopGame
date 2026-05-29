//
//  SettingsReflectionTests.swift
//  BubblePopGameTests
//
//  Issue #17: 設定値（バブルサイズ・速度）が BubbleService に反映されることの回帰テスト
//

import Testing
import SwiftData
import Foundation
import SwiftUI
@testable import BubblePopGame

/// updateBubbleConfig の呼び出しを記録し、生成系メソッドは実装へ委譲する spy。
/// 「設定をサービスへ push する supply line」が将来 silent revert されても
/// 検知できるようにするためのテスト用ダブル。
final class SpyBubbleService: BubbleService {
    private let wrapped: BubbleServiceImpl
    private(set) var updateBubbleConfigCallCount = 0
    private(set) var lastConfig: (minRadius: Double, maxRadius: Double, animationSpeed: Double)?

    init(screenBounds: CGRect) {
        wrapped = BubbleServiceImpl(screenBounds: screenBounds)
    }

    func createBubble(at position: CGPoint, type: BubbleType) -> Bubble {
        wrapped.createBubble(at: position, type: type)
    }
    func createNumberedBubble(at position: CGPoint, number: Int) -> Bubble {
        wrapped.createNumberedBubble(at: position, number: number)
    }
    func updateBubbles(_ bubbles: inout [Bubble]) {
        wrapped.updateBubbles(&bubbles)
    }
    func checkCollision(at point: CGPoint, in bubbles: [Bubble]) -> Bubble? {
        wrapped.checkCollision(at: point, in: bubbles)
    }
    func checkCollisionIndex(at point: CGPoint, in bubbles: [Bubble]) -> Int {
        wrapped.checkCollisionIndex(at: point, in: bubbles)
    }
    func generateRandomBubbles(count: Int, screenBounds: CGRect) -> [Bubble] {
        wrapped.generateRandomBubbles(count: count, screenBounds: screenBounds)
    }
    func generateNumberedBubbles(count: Int, screenBounds: CGRect, numberedCount: Int) -> [Bubble] {
        wrapped.generateNumberedBubbles(count: count, screenBounds: screenBounds, numberedCount: numberedCount)
    }
    func generateNumberedBubblesWithCustomSet(count: Int, screenBounds: CGRect, numberSet: [Int]) -> [Bubble] {
        wrapped.generateNumberedBubblesWithCustomSet(count: count, screenBounds: screenBounds, numberSet: numberSet)
    }
    func updateScreenBounds(_ bounds: CGRect) {
        wrapped.updateScreenBounds(bounds)
    }
    func updateBubbleConfig(minRadius: Double, maxRadius: Double, animationSpeed: Double) {
        updateBubbleConfigCallCount += 1
        lastConfig = (minRadius, maxRadius, animationSpeed)
        wrapped.updateBubbleConfig(minRadius: minRadius, maxRadius: maxRadius, animationSpeed: animationSpeed)
    }
}

@MainActor
@Suite("設定値反映 (Issue #17)")
struct SettingsReflectionTests {

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            GameScore.self,
            GameStatistics.self,
            GameSettings.self,
        ])
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test("startGame で BubbleService に GameSettings のバブル設定が push される")
    func startGamePushesSettingsToBubbleService() throws {
        let container = try Self.makeContainer()
        let settings = GameSettings()
        settings.bubbleMinRadius = 22.0
        settings.bubbleMaxRadius = 44.0
        settings.animationSpeed = 1.5
        settings.bgmEnabled = false // テスト中の BGM 再生を避ける

        let spy = SpyBubbleService(screenBounds: .zero)
        let vm = GameViewModel(
            bubbleService: spy,
            audioService: AudioServiceImpl(),
            effectService: EffectServiceImpl(),
            deviceService: DeviceServiceImpl(),
            performanceService: PerformanceServiceImpl(),
            scoreRepository: ScoreRepositoryImpl(modelContainer: container),
            settingsRepository: SettingsRepositoryImpl(modelContainer: container),
            statisticsRepository: StatisticsRepositoryImpl(modelContainer: container),
            gameSettings: settings
        )

        // startGame は screenBounds=.zero だとバブル生成を遅延するため、先に実サイズを設定
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        vm.startGame()

        #expect(spy.updateBubbleConfigCallCount >= 1)
        #expect(spy.lastConfig?.minRadius == 22.0)
        #expect(spy.lastConfig?.maxRadius == 44.0)
        #expect(spy.lastConfig?.animationSpeed == 1.5)

        // タイマー/ゲームループを止めてテスト後に残さない
        vm.pauseGame()
    }
}
