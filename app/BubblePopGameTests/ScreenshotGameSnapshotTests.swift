//
//  ScreenshotGameSnapshotTests.swift
//  BubblePopGameTests
//
//  Issue #78: App Store スクショ撮影用に、プレイ途中の状態を注入する（DEBUG）。
//  起動直後は screenBounds == .zero で startGame() が保留され、画面サイズが届いたときの
//  startGame() がスコアを 0 に戻す。注入はその後でも残らなければならない。
//

import Testing
import Foundation
@testable import BubblePopGame

@MainActor
@Suite("Screenshot game snapshot (#78)")
struct ScreenshotGameSnapshotTests {

    @Test("保留された開始を経由しても、注入した値が残る")
    func snapshotSurvivesDeferredStart() throws {
        let vm = try DebugOverrideTests.makeViewModel(gameTime: 30)
        vm.debugScreenshotSnapshot = .normal
        vm.startGame()                                         // screenBounds == .zero → 保留
        vm.updateScreenBounds(CGSize(width: 402, height: 874)) // ここで実際に開始
        #expect(vm.gameState == .playing)
        #expect(vm.score == ScreenshotGameSnapshot.normal.score)
        #expect(vm.bubblesPopped == ScreenshotGameSnapshot.normal.bubblesPopped)
        #expect(vm.timeRemaining == ScreenshotGameSnapshot.normal.timeRemaining)
    }

    @Test("注入しなければ、これまでどおり 0 から始まる")
    func noSnapshotKeepsNormalReset() throws {
        let vm = try DebugOverrideTests.makeViewModel(gameTime: 30)
        vm.updateScreenBounds(CGSize(width: 402, height: 874))
        vm.startGame()
        #expect(vm.score == 0)
        #expect(vm.timeRemaining == 30)
    }

    @Test("撮影までに残り時間が 0 にならない")
    func snapshotsKeepEnoughTime() {
        #expect(ScreenshotGameSnapshot.normal.timeRemaining >= 15)
        #expect(ScreenshotGameSnapshot.numbered.timeRemaining >= 15)
        #expect(ScreenshotGameSnapshot.normal.timeRemaining < 30)
    }

    @Test("実プレイで到達できる値になっている")
    func snapshotsAreReachable() {
        for s in [ScreenshotGameSnapshot.normal, .numbered] {
            #expect(s.successfulTaps == s.bubblesPopped)
            #expect(s.totalTaps >= s.successfulTaps)
            #expect(s.bestStreak >= s.currentStreak)
            #expect(s.score <= s.bubblesPopped * 14)
        }
    }
}
