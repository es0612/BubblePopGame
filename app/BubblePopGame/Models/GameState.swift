//
//  GameState.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation

enum GameState: String, CaseIterable {
    case tutorial = "tutorial"
    case menu = "menu"
    case playing = "playing"
    case paused = "paused"
    case gameOver = "gameOver"
    case settings = "settings"
    case highScore = "highScore"
}