//
//  DebugLaunchOptionsTests.swift
//  BubblePopGameTests
//
//  Issue #8: デバッグ起動引数パーサの単体テスト
//

import Testing
import Foundation
@testable import BubblePopGame

@Suite("DebugLaunchOptions パーサ")
struct DebugLaunchOptionsTests {

    @Test("引数なしでは override なし")
    func noArguments() {
        let options = DebugLaunchOptions(arguments: ["/path/to/app"])
        #expect(options.skipTutorial == false)
        #expect(options.gameTime == nil)
        #expect(options.gameMode == nil)
        #expect(options.screenshot == nil)
        #expect(options.hasOverrides == false)
    }

    @Test("--skip-tutorial を検出する")
    func skipTutorialFlag() {
        let options = DebugLaunchOptions(arguments: ["app", "--skip-tutorial"])
        #expect(options.skipTutorial == true)
        #expect(options.hasOverrides == true)
    }

    @Test("--game-time=120 を Double として解釈する")
    func gameTimeParsing() {
        let options = DebugLaunchOptions(arguments: ["app", "--game-time=120"])
        #expect(options.gameTime == 120.0)
        #expect(options.hasOverrides == true)
    }

    @Test("--game-time に数値以外を渡すと nil")
    func gameTimeInvalid() {
        let options = DebugLaunchOptions(arguments: ["app", "--game-time=abc"])
        #expect(options.gameTime == nil)
    }

    @Test("--game-time= が空なら nil")
    func gameTimeEmpty() {
        let options = DebugLaunchOptions(arguments: ["app", "--game-time="])
        #expect(options.gameTime == nil)
    }

    @Test("--game-mode=numbered を文字列として解釈する")
    func gameModeParsing() {
        let options = DebugLaunchOptions(arguments: ["app", "--game-mode=numbered"])
        #expect(options.gameMode == "numbered")
        #expect(options.hasOverrides == true)
    }

    @Test("--screenshot=result を文字列として解釈する")
    func screenshotParsing() {
        let options = DebugLaunchOptions(arguments: ["app", "--screenshot=result"])
        #expect(options.screenshot == "result")
        #expect(options.hasOverrides == true)
    }

    @Test("複数引数を同時に解釈する")
    func combinedArguments() {
        let options = DebugLaunchOptions(
            arguments: ["app", "--skip-tutorial", "--game-time=30", "--game-mode=normal"]
        )
        #expect(options.skipTutorial == true)
        #expect(options.gameTime == 30.0)
        #expect(options.gameMode == "normal")
        #expect(options.hasOverrides == true)
    }
}
