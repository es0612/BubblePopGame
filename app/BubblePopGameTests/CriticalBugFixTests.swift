//
//  CriticalBugFixTests.swift
//  BubblePopGameTests
//
//  PR1: Phase 1 致命的バグ修正の回帰テスト
//

import Testing
import SwiftData
import Foundation
import SwiftUI
import UIKit
@testable import BubblePopGame

@MainActor
@Suite("PR1致命バグ修正")
struct CriticalBugFixTests {

    // MARK: - Helpers

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

    static func makeViewModel(gameTime: Double? = nil) throws -> GameViewModel {
        let container = try makeContainer()
        let settings = GameSettings()
        if let gameTime { settings.gameTime = gameTime }

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

    // MARK: - 1.1 画面サイズ初期化

    @Test("初期化直後の screenBounds は .zero")
    func initialScreenBoundsIsZero() throws {
        let vm = try Self.makeViewModel()
        #expect(vm.screenBounds == .zero,
                "View マウント前は .zero、onAppear で実サイズに更新される設計")
    }

    @Test("screenBounds=.zero のままで startGame してもバブル生成しない")
    func startGameGuardsAgainstZeroBounds() throws {
        let vm = try Self.makeViewModel()
        vm.startGame()
        #expect(vm.bubbles.isEmpty,
                ".zero で startGame した場合は画面外配置防止のため生成しない")
    }

    @Test("updateScreenBounds 後に startGame するとバブル生成される")
    func startGameGeneratesBubblesAfterScreenBoundsSet() throws {
        let vm = try Self.makeViewModel()
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        vm.startGame()
        #expect(!vm.bubbles.isEmpty,
                "screenBounds 設定後 startGame でバブル生成される")
    }

    @Test("MenuView 経路（GameView マウント前）でも startGame で playing に遷移する")
    func startGameTransitionsToPlayingFromMenuPath() throws {
        // 再現シナリオ: ContentView.setupDependencies が screenBounds を
        // セットしてから gameState を割り当てる、という契約。
        // この契約が満たされていれば、ユーザーが MenuView の Start ボタン押下時
        // （GameView.onAppear が走る前）でも startGame() が機能する。
        let vm = try Self.makeViewModel()
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        vm.gameState = .menu

        vm.startGame()

        #expect(vm.gameState == .playing,
                "ContentView 初期化で screenBounds がセット済みなら、Menu からの startGame で .playing に遷移する")
        #expect(!vm.bubbles.isEmpty)
    }

    // MARK: - 1.1b Start デッドロック防止 (#23)

    @Test("screenBounds 未設定で Start しても、サイズ到達時に自動でゲーム開始する（#23 デッドロック防止）")
    func startIsDeferredUntilScreenBoundsAvailable() throws {
        let vm = try Self.makeViewModel()
        vm.gameState = .menu

        // screenBounds が .zero のまま Start → 即 playing にはせず保留（PR #10 ガード維持）
        vm.startGame()
        #expect(vm.gameState == .menu, "サイズ未供給時は保留（まだ playing にしない）")
        #expect(vm.bubbles.isEmpty, "PR #10 ガード: .zero でバブル生成しない")

        // 画面サイズが到達 → 保留分が自動でゲーム開始（永久デッドロックを防ぐ）
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        #expect(vm.gameState == .playing, "サイズ到達で保留分が自動開始する")
        #expect(!vm.bubbles.isEmpty)

        vm.pauseGame() // タイマー/ループ停止
    }

    @Test("有効な screenBounds は .zero で上書きされない（#23 クロバー防止）")
    func validScreenBoundsNotClobberedByZero() throws {
        let vm = try Self.makeViewModel()
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))

        // 遷移中の geometry 取りこぼし（.zero）が有効値を壊さないこと
        vm.updateScreenBounds(CGRect.zero)
        vm.gameState = .menu
        vm.startGame()

        #expect(vm.gameState == .playing, ".zero で上書きされず Start が機能する")
        #expect(!vm.bubbles.isEmpty)

        vm.pauseGame()
    }

    // MARK: - 1.2 時間表示

    @Test("gameTime=120 で startGame すると timeRemaining も 120")
    func startGameInitializesTimeRemainingFromSettings120() throws {
        let vm = try Self.makeViewModel(gameTime: 120.0)
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        vm.startGame()
        #expect(vm.timeRemaining == 120.0)
        #expect(vm.gameSettings.gameTime == 120.0)
    }

    @Test("gameTime=30 で startGame すると timeRemaining も 30")
    func startGameInitializesTimeRemainingFromSettings30() throws {
        let vm = try Self.makeViewModel(gameTime: 30.0)
        vm.updateScreenBounds(CGRect(x: 0, y: 0, width: 400, height: 800))
        vm.startGame()
        #expect(vm.timeRemaining == 30.0)
    }

    // MARK: - 1.3 ParticleEffectView

    @Test("ParticleEffectViewModel は参照型で状態を共有する")
    func particleEffectViewModelIsReferenceType() {
        let vm = ParticleEffectViewModel()
        let shared = vm
        #expect(vm.effects.isEmpty)
        shared.addEffect(at: CGPoint(x: 100, y: 100), color: .red)
        #expect(vm.effects.count == 1, "参照型のため vm と shared は同じインスタンス")
    }

    @Test("EffectServiceImpl.createPopEffect は ViewModel に effect を追加する")
    func effectServiceTriggersViewModelEffect() {
        let service = EffectServiceImpl()
        let viewModel = ParticleEffectViewModel()
        service.particleEffectViewModel = viewModel

        #expect(viewModel.effects.isEmpty)
        service.createPopEffect(at: CGPoint(x: 50, y: 50), color: .blue)
        #expect(viewModel.effects.count == 1)
    }

    // MARK: - 1.4 高コントラスト

    @Test("Color.accessible(highContrast:) は通常と異なる色を返す")
    func accessibleColorReturnsHighContrast() {
        let original = Color.red
        let highContrast = original.accessible(highContrast: true)
        let normal = original.accessible(highContrast: false)
        #expect(highContrast != normal,
                "高コントラストフラグで色が変化する")
    }

    @Test("AccessibilityUtils.accessibleColor 高コントラストRed は Pure red")
    func highContrastRedIsPureRed() {
        let result = AccessibilityUtils.accessibleColor(for: .red, isHighContrast: true)
        let uiColor = UIColor(result)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(r == 1.0 && g == 0.0 && b == 0.0,
                "高コントラスト赤は Pure red (1.0, 0.0, 0.0)")
    }
}
