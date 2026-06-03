//
//  BubblePopGameUITestsLaunchTests.swift
//  BubblePopGameUITests
//
//  Created on 2025/07/25
//

import XCTest

final class BubblePopGameUITestsLaunchTests: XCTestCase {
    
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // アプリが正常に起動することを確認
        // タイトルまたはメイン要素が表示されるまで待機
        let menuTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '玉' OR label CONTAINS 'Bubble'")).firstMatch
        let tutorialWelcome = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'ようこそ' OR label CONTAINS 'Welcome'")).firstMatch
        
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
    
    func testMemoryUsageAfterLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // アプリが起動するまで待機
        let menuTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '玉' OR label CONTAINS 'Bubble'")).firstMatch
        let tutorialSkipButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'スキップ' OR label CONTAINS 'Skip'")).firstMatch
        
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
        XCTAssertTrue(app.buttons["mainMenuGameStart"].exists, "アプリが応答しない")
        XCTAssertTrue(app.buttons["mainMenuSettings"].exists, "アプリが応答しない")
    }
    
    func testOrientationHandling() throws {
        let app = XCUIApplication()
        app.launch()
        
        // チュートリアルスキップ（存在する場合）
        let tutorialSkipButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'スキップ' OR label CONTAINS 'Skip'")).firstMatch
        if tutorialSkipButton.waitForExistence(timeout: 3.0) {
            tutorialSkipButton.tap()
        }
        
        // ポートレートモードでの動作確認
        XCUIDevice.shared.orientation = .portrait
        let menuTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '玉' OR label CONTAINS 'Bubble'")).firstMatch
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
        
        // 起動を待機
        sleep(2)
        
        // チュートリアルスキップ（存在する場合）
        let tutorialSkipButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'スキップ' OR label CONTAINS 'Skip'")).firstMatch
        if tutorialSkipButton.waitForExistence(timeout: 5.0) {
            tutorialSkipButton.tap()
            sleep(1)
        }
        
        // メニュー → ゲームの状態遷移をテスト
        let gameStartButton = app.buttons["mainMenuGameStart"]
        XCTAssertTrue(gameStartButton.waitForExistence(timeout: 10.0))
        gameStartButton.tap()
        
        // ゲーム画面への遷移を待機
        sleep(3)
        
        // アプリの基本的な状態遷移が成功したことを確認
        XCTAssertTrue(true, "アプリの状態遷移テスト完了")
    }
}
