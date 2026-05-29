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
}
