//
//  BubblePopGameUITestsLaunchTests.swift
//  BubblePopGameUITests
//
//  Created on 2025/07/25
//

import XCTest

final class BubblePopGameUITestsLaunchTests: XCTestCase {
    
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // アプリが正常に起動することを確認
        // タイトルまたはメイン要素が表示されるまで待機
        let menuTitle = app.staticTexts["シャボン玉消しゲーム"]
        let tutorialWelcome = app.staticTexts["ようこそ！"]
        
        // メニューまたはチュートリアルのいずれかが表示されることを確認
        let titleExists = menuTitle.waitForExistence(timeout: 10.0)
        let tutorialExists = tutorialWelcome.waitForExistence(timeout: 5.0)
        
        XCTAssertTrue(titleExists || tutorialExists, "アプリが正常に起動しない - メニューまたはチュートリアルが表示されない")
        
        // スクリーンショットを取得してアタッチ
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // アプリ起動時間を測定
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testMemoryUsageAfterLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // アプリが起動するまで待機
        let menuTitle = app.staticTexts["シャボン玉消しゲーム"]
        let tutorialSkipButton = app.buttons["スキップ"]
        
        // チュートリアルをスキップ（存在する場合）
        if tutorialSkipButton.waitForExistence(timeout: 5.0) {
            tutorialSkipButton.tap()
        }
        
        // メニューが表示されるまで待機
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 10.0), "メニューが表示されない")
        
        // メモリ使用量の測定（アプリが正常に動作していることの確認）
        // 実際のメモリ測定はXCTMemoryMetricを使用するが、ここでは基本的な動作確認
        sleep(2) // アプリが安定するまで待機
        
        // アプリがまだ応答することを確認
        XCTAssertTrue(app.buttons["ゲーム開始"].exists, "アプリが応答しない")
        XCTAssertTrue(app.buttons["設定"].exists, "アプリが応答しない")
    }
    
    func testOrientationHandling() throws {
        let app = XCUIApplication()
        app.launch()
        
        // チュートリアルスキップ（存在する場合）
        let tutorialSkipButton = app.buttons["スキップ"]
        if tutorialSkipButton.waitForExistence(timeout: 3.0) {
            tutorialSkipButton.tap()
        }
        
        // ポートレートモードでの動作確認
        XCUIDevice.shared.orientation = .portrait
        let menuTitle = app.staticTexts["シャボン玉消しゲーム"]
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 5.0), "ポートレートモードでメニューが表示されない")
        
        // ランドスケープモードへの回転をテスト
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1) // 回転アニメーションを待つ
        
        // 回転後もアプリが正常に動作することを確認
        XCTAssertTrue(menuTitle.exists || menuTitle.waitForExistence(timeout: 3.0), "ランドスケープモードでアプリが正常に表示されない")
        
        // 元の向きに戻す
        XCUIDevice.shared.orientation = .portrait
    }
    
    func testAppStateTransitions() throws {
        let app = XCUIApplication()
        app.launch()
        
        // チュートリアルスキップ（存在する場合）
        let tutorialSkipButton = app.buttons["スキップ"]
        if tutorialSkipButton.waitForExistence(timeout: 3.0) {
            tutorialSkipButton.tap()
        }
        
        // メニュー → ゲーム → メニューの状態遷移をテスト
        let gameStartButton = app.buttons["ゲーム開始"]
        XCTAssertTrue(gameStartButton.waitForExistence(timeout: 5.0))
        gameStartButton.tap()
        
        // ゲーム画面が表示されることを確認
        sleep(2)
        let pauseButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'ポーズ'")).firstMatch
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 5.0), "ゲーム画面に遷移しない")
        
        // ポーズしてゲームを終了
        pauseButton.tap()
        
        // ポーズ画面で終了ボタンを探す（遅延表示される可能性があるため少し待つ）
        sleep(3)
        let endButton = app.buttons["終了"]
        if endButton.exists {
            endButton.tap()
            
            // 確認ダイアログが表示される場合
            let confirmButton = app.buttons["終了"]
            if confirmButton.waitForExistence(timeout: 2.0) {
                confirmButton.tap()
            }
        } else {
            // 終了ボタンがない場合は再開してからホームに戻る方法を試す
            let resumeButton = app.buttons["再開"]
            if resumeButton.exists {
                resumeButton.tap()
                // アプリをバックグラウンドに送る
                XCUIDevice.shared.press(.home)
                app.activate()
            }
        }
        
        // 最終的にメニューに戻ることを確認
        let menuTitle = app.staticTexts["シャボン玉消しゲーム"]
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 10.0), "メニューに戻らない")
    }
}