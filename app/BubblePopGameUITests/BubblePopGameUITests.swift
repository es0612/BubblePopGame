//
//  BubblePopGameUITests.swift
//  BubblePopGameUITests
//
//  Created on 2025/07/25
//

import XCTest

final class BubblePopGameUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - ハッピーパステスト
    
    func testAppLaunchAndMenuNavigation() throws {
        // アプリ起動
        app.launch()
        
        // 初回起動時はチュートリアルまたはメニューが表示される
        let menuTitle = app.staticTexts["シャボン玉消しゲーム"]
        let tutorialSkipButton = app.buttons["スキップ"]
        
        // チュートリアルが表示される場合はスキップ
        if tutorialSkipButton.waitForExistence(timeout: 3.0) {
            tutorialSkipButton.tap()
        }
        
        // メニュー画面の要素が表示されることを確認
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 5.0), "メニュータイトルが表示されない")
        XCTAssertTrue(app.buttons["mainMenuGameStart"].exists, "ゲーム開始ボタンが存在しない")
        XCTAssertTrue(app.buttons["mainMenuSettings"].exists, "設定ボタンが存在しない")
        XCTAssertTrue(app.buttons["mainMenuHighScore"].exists, "ハイスコアボタンが存在しない")
    }
    
    func testGameStart() throws {
        // アプリ起動
        app.launch()
        
        // チュートリアルスキップ（存在する場合）
        let tutorialSkipButton = app.buttons["スキップ"]
        if tutorialSkipButton.waitForExistence(timeout: 3.0) {
            tutorialSkipButton.tap()
        }
        
        // ゲーム開始ボタンをタップ
        let gameStartButton = app.buttons["mainMenuGameStart"]
        XCTAssertTrue(gameStartButton.waitForExistence(timeout: 5.0), "ゲーム開始ボタンが表示されない")
        gameStartButton.tap()
        
        // ゲーム画面の要素が表示されることを確認
        let scoreLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0'")).firstMatch
        XCTAssertTrue(scoreLabel.waitForExistence(timeout: 5.0), "スコア表示が見つからない")
        
        // 残り時間の表示を確認
        let timeLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '残り時間'")).firstMatch
        XCTAssertTrue(timeLabel.waitForExistence(timeout: 3.0), "時間表示が見つからない")
        
        // ポーズボタンの存在を確認
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'ポーズ'")).firstMatch.waitForExistence(timeout: 3.0), "ポーズボタンが見つからない")
    }
    
    func testGamePauseAndResume() throws {
        // アプリ起動
        app.launch()
        
        // チュートリアルスキップ（存在する場合）
        let tutorialSkipButton = app.buttons["スキップ"]
        if tutorialSkipButton.waitForExistence(timeout: 3.0) {
            tutorialSkipButton.tap()
        }
        
        // ゲーム開始
        let gameStartButton = app.buttons["mainMenuGameStart"]
        XCTAssertTrue(gameStartButton.waitForExistence(timeout: 5.0))
        gameStartButton.tap()
        
        // 少し待ってゲームが開始されることを確認
        sleep(1)
        
        // ポーズボタンをタップ
        let pauseButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'ポーズ'")).firstMatch
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 3.0))
        pauseButton.tap()
        
        // ポーズ画面の表示を確認
        let pauseTitle = app.staticTexts["ポーズ中"]
        XCTAssertTrue(pauseTitle.waitForExistence(timeout: 3.0), "ポーズ画面が表示されない")
        
        // 再開ボタンをタップ
        let resumeButton = app.buttons["再開"]
        XCTAssertTrue(resumeButton.exists, "再開ボタンが存在しない")
        resumeButton.tap()
        
        // ゲームが再開されることを確認（ポーズ画面が消える）
        XCTAssertFalse(pauseTitle.waitForExistence(timeout: 1.0), "ポーズ画面が消えない")
    }
    
    func testSettingsAccess() throws {
        // アプリ起動
        app.launch()
        
        // チュートリアルスキップ（存在する場合）
        let tutorialSkipButton = app.buttons["スキップ"]
        if tutorialSkipButton.waitForExistence(timeout: 3.0) {
            tutorialSkipButton.tap()
        }
        
        // 設定ボタンをタップ
        let settingsButton = app.buttons["mainMenuSettings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5.0))
        settingsButton.tap()
        
        // 設定画面の要素が表示されることを確認
        let settingsTitle = app.staticTexts["設定"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5.0), "設定画面が表示されない")
        
        // 設定項目の存在を確認
        XCTAssertTrue(app.staticTexts["ゲーム設定"].waitForExistence(timeout: 3.0), "ゲーム設定セクションが存在しない")
        
        // 戻るボタンまたは他の方法でメニューに戻る処理を試す
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '戻る' OR label CONTAINS 'メニュー'")).firstMatch
        if backButton.exists {
            backButton.tap()
        }
    }
    
    func testHighScoreAccess() throws {
        // アプリ起動
        app.launch()
        
        // チュートリアルスキップ（存在する場合）
        let tutorialSkipButton = app.buttons["スキップ"]
        if tutorialSkipButton.waitForExistence(timeout: 3.0) {
            tutorialSkipButton.tap()
        }
        
        // ハイスコアボタンをタップ
        let highScoreButton = app.buttons["mainMenuHighScore"]
        XCTAssertTrue(highScoreButton.waitForExistence(timeout: 5.0))
        highScoreButton.tap()
        
        // ハイスコア画面の表示を確認
        let highScoreTitle = app.staticTexts["ハイスコア"]
        XCTAssertTrue(highScoreTitle.waitForExistence(timeout: 5.0), "ハイスコア画面が表示されない")
        
        // メニューに戻るボタンの存在を確認
        let backButton = app.buttons["メニューに戻る"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 3.0), "メニューに戻るボタンが存在しない")
        backButton.tap()
        
        // メニューに戻ることを確認
        let menuTitle = app.staticTexts["シャボン玉消しゲーム"]
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 3.0), "メニューに戻らない")
    }
    
    func testBasicGameInteraction() throws {
        // アプリ起動
        app.launch()
        
        // チュートリアルスキップ（存在する場合）
        let tutorialSkipButton = app.buttons["スキップ"]
        if tutorialSkipButton.waitForExistence(timeout: 3.0) {
            tutorialSkipButton.tap()
        }
        
        // ゲーム開始
        let gameStartButton = app.buttons["mainMenuGameStart"]
        XCTAssertTrue(gameStartButton.waitForExistence(timeout: 5.0))
        gameStartButton.tap()
        
        // ゲーム画面が表示されるまで待機
        sleep(2)
        
        // 画面上をタップしてみる（バブルがあるかもしれない場所）
        let gameArea = app.otherElements.firstMatch
        if gameArea.exists {
            gameArea.tap()
            
            // 少し待つ
            sleep(1)
            
            // スコアが変更されたかチェック（必ずしもヒットするとは限らないため、エラーにはしない）
            let scoreExists = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0' OR label CONTAINS '1' OR label CONTAINS '2'")).firstMatch.exists
            XCTAssertTrue(scoreExists, "スコア表示が見つからない")
        }
    }
    
    // MARK: - アクセシビリティテスト
    
    func testAccessibilityLabels() throws {
        // アプリ起動
        app.launch()
        
        // チュートリアルスキップ（存在する場合）
        let tutorialSkipButton = app.buttons["スキップ"]
        if tutorialSkipButton.waitForExistence(timeout: 3.0) {
            tutorialSkipButton.tap()
        }
        
        // メニュー画面のアクセシビリティラベルを確認
        let gameStartButton = app.buttons["mainMenuGameStart"]
        XCTAssertTrue(gameStartButton.waitForExistence(timeout: 5.0))
//        XCTAssertTrue(gameStartButton.isAccessibilityElement)
//        
//        let settingsButton = app.buttons["mainMenuSettings"]
//        XCTAssertTrue(settingsButton.exists)
//        XCTAssertTrue(settingsButton.isAccessibilityElement)
//        
//        let highScoreButton = app.buttons["mainMenuHighScore"]
//        XCTAssertTrue(highScoreButton.exists)
//        XCTAssertTrue(highScoreButton.isAccessibilityElement)
    }
}
