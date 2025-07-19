//
//  MenuViewModel.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation

@Observable
class MenuViewModel {
    var showSettings: Bool = false
    var highScores: [GameScore] = []
    
    init() {
        
    }
    
    func loadHighScores() {
        // TODO: Repository経由でハイスコア読み込み
    }
    
    func navigateToGame() {
        // TODO: ゲーム画面への遷移
    }
    
    func showSettingsView() {
        showSettings = true
    }
}