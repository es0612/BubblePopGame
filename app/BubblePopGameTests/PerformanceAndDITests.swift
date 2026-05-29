//
//  PerformanceAndDITests.swift
//  BubblePopGameTests
//
//  Issue #20: 依存性注入の具象型キャスト除去（#7）＋ パフォーマンス回復ロジック（#8）
//

import Testing
import SwiftData
import Foundation
import SwiftUI
import UIKit
@testable import BubblePopGame

/// EffectServiceImpl ではない EffectService 実装。
/// setupParticleEffectViewModel が具象型キャストに依存していると、この spy には
/// 値がセットされない（= テストが失敗する）ことで DI 違反を検知する。
@MainActor
final class SpyEffectService: EffectService {
    var didCallSetParticleEffectViewModel = false
    var receivedParticleViewModel: ParticleEffectViewModel?

    func createPopEffect(at position: CGPoint, color: Color) {}
    func triggerHapticFeedback(intensity: UIImpactFeedbackGenerator.FeedbackStyle) {}
    func triggerSuccessFeedback() {}
    func triggerWarningFeedback() {}
    func triggerErrorFeedback() {}
    func setParticleEffectViewModel(_ viewModel: ParticleEffectViewModel?) {
        didCallSetParticleEffectViewModel = true
        receivedParticleViewModel = viewModel
    }
}

/// 調整値を任意に固定できる PerformanceService の fake。
final class FakePerformanceService: PerformanceService {
    var adjustment: Double = 1.0
    var reduce: Bool = false
    var currentFPS: Double = 60
    var averageFPS: Double = 60
    var isPerformanceGood: Bool = true
    func startMonitoring() {}
    func stopMonitoring() {}
    func shouldReduceBubbles() -> Bool { reduce }
    func getPerformanceAdjustment() -> Double { adjustment }
}

/// デバイス上限を大きく固定し、finalBubbleCount を adjustment だけで決まるようにする fake。
final class FakeDeviceService: DeviceService {
    var deviceType: DeviceType = .iPhone
    var screenSize: CGSize = CGSize(width: 400, height: 800)
    var isLowPerformanceDevice: Bool = false
    var optimalCount: Int = 1000
    func adaptBubbleCount(for settings: GameSettings) -> Int { optimalCount }
    func getOptimalBubbleSize() -> CGFloat { 50 }
}

@MainActor
@Suite("DI改善・パフォーマンス回復 (Issue #20)")
struct PerformanceAndDITests {

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([GameScore.self, GameStatistics.self, GameSettings.self])
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    static func makeViewModel(
        effect: EffectService,
        gameMode: String = "normal"
    ) throws -> GameViewModel {
        let container = try makeContainer()
        let settings = GameSettings()
        settings.gameMode = gameMode
        settings.bgmEnabled = false
        return GameViewModel(
            bubbleService: BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800)),
            audioService: AudioServiceImpl(),
            effectService: effect,
            deviceService: DeviceServiceImpl(),
            performanceService: PerformanceServiceImpl(),
            scoreRepository: ScoreRepositoryImpl(modelContainer: container),
            settingsRepository: SettingsRepositoryImpl(modelContainer: container),
            statisticsRepository: StatisticsRepositoryImpl(modelContainer: container),
            gameSettings: settings
        )
    }

    @Test("setupParticleEffectViewModel は具象型に依存せず protocol 経由で設定する")
    func setupParticleEffectViewModelUsesProtocol() throws {
        let spy = SpyEffectService()
        let vm = try Self.makeViewModel(effect: spy)
        let particleVM = ParticleEffectViewModel()

        vm.setupParticleEffectViewModel(particleVM)

        #expect(spy.didCallSetParticleEffectViewModel)
        #expect(spy.receivedParticleViewModel === particleVM)
    }

    // MARK: - パフォーマンス回復 (#8)

    static func makePerfViewModel(
        perf: PerformanceService,
        device: DeviceService,
        gameMode: String = "normal"
    ) throws -> GameViewModel {
        let container = try makeContainer()
        let settings = GameSettings()
        settings.gameMode = gameMode
        settings.bgmEnabled = false
        // bubbleCount は既定 20。finalBubbleCount = min(20 * adjustment, deviceOptimal)
        let vm = GameViewModel(
            bubbleService: BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800)),
            audioService: AudioServiceImpl(),
            effectService: SpyEffectService(),
            deviceService: device,
            performanceService: perf,
            scoreRepository: ScoreRepositoryImpl(modelContainer: container),
            settingsRepository: SettingsRepositoryImpl(modelContainer: container),
            statisticsRepository: StatisticsRepositoryImpl(modelContainer: container),
            gameSettings: settings
        )
        // replenish 経路は randomPosition(screenBounds) を使うため実サイズを設定
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        return vm
    }

    private func makeBubbles(_ count: Int) -> [Bubble] {
        (0..<count).map { _ in
            Bubble(position: CGPoint(x: 100, y: 100), velocity: .zero, radius: 40,
                   type: .normal, number: nil, color: .blue, alpha: 1.0, animationPhase: 0)
        }
    }

    @Test("負荷が高いとバブルを目標数まで削減する")
    func reducesBubblesUnderLoad() throws {
        let perf = FakePerformanceService(); perf.adjustment = 0.5 // 20*0.5 = 10
        let vm = try Self.makePerfViewModel(perf: perf, device: FakeDeviceService())
        vm.bubbles = makeBubbles(20)

        vm.optimizePerformance()

        #expect(vm.bubbles.count == 10)
    }

    @Test("負荷回復後にバブルを目標数まで補充する")
    func replenishesBubblesAfterRecovery() throws {
        let perf = FakePerformanceService(); perf.adjustment = 1.0 // 20*1.0 = 20
        let vm = try Self.makePerfViewModel(perf: perf, device: FakeDeviceService())
        vm.bubbles = makeBubbles(8) // 負荷軽減で減った状態

        vm.optimizePerformance()

        #expect(vm.bubbles.count == 20)
    }

    @Test("定常状態では増減しない（1Hzちらつき防止）")
    func noOpAtSteadyState() throws {
        let perf = FakePerformanceService(); perf.adjustment = 1.0 // final = 20
        let vm = try Self.makePerfViewModel(perf: perf, device: FakeDeviceService())
        vm.bubbles = makeBubbles(20)

        vm.optimizePerformance()

        #expect(vm.bubbles.count == 20)
    }

    @Test("数字モードでは perf 調整を行わない（バブル集合はルール依存）")
    func skipsAdjustmentInNumberedMode() throws {
        let perf = FakePerformanceService(); perf.adjustment = 0.5 // normal なら 10 に減るはず
        let vm = try Self.makePerfViewModel(perf: perf, device: FakeDeviceService(), gameMode: "numbered")
        vm.bubbles = makeBubbles(20)

        vm.optimizePerformance()

        #expect(vm.bubbles.count == 20) // 数字モードは変化なし
    }
}
