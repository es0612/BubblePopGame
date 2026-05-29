//
//  MenuView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct MenuView: View {
    let gameViewModel: GameViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width > 600
            let spacing: CGFloat = isIPad ? 60 : 40
            
            VStack(spacing: spacing) {
            Text(NSLocalizedString("game_title", comment: "Game title"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.blue.accessible())
                .accessibilityLabel(NSLocalizedString("accessibility_game_title", comment: "Game title accessibility"))
                .accessibilityHint(NSLocalizedString("accessibility_game_title_hint", comment: "Game title hint"))
            
            VStack(spacing: 20) {
                Button(action: {
                    gameViewModel.startGame()
                    gameViewModel.audioService.playSFX(name: "button_tap")
                }) {
                    Text(NSLocalizedString("menu_start_game", comment: "Start game button"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.accessible())
                        .cornerRadius(10)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("mainMenuGameStart")
                .accessibilityLabel(NSLocalizedString("accessibility_start_game", comment: "Start game accessibility"))
                .accessibilityHint(NSLocalizedString("accessibility_start_game_hint", comment: "Start game hint"))
                .accessibilityAddTraits(.isButton)
                
                Button(action: {
                    gameViewModel.gameState = .settings
                    gameViewModel.audioService.playSFX(name: "button_tap")
                }) {
                    Text(NSLocalizedString("menu_settings", comment: "Settings button"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.blue.accessible())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.accessible().opacity(0.1))
                        .cornerRadius(10)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("mainMenuSettings")
                .accessibilityLabel(NSLocalizedString("accessibility_settings", comment: "Settings accessibility"))
                .accessibilityHint(NSLocalizedString("accessibility_settings_hint", comment: "Settings hint"))
                .accessibilityAddTraits(.isButton)
                
                // ハイスコア表示ボタン
                Button(action: {
                    gameViewModel.gameState = .highScore
                    gameViewModel.audioService.playSFX(name: "button_tap")
                }) {
                    Text(NSLocalizedString("menu_high_score", comment: "High score button"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.purple.accessible())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.accessible().opacity(0.1))
                        .cornerRadius(10)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("mainMenuHighScore")
                .accessibilityLabel(NSLocalizedString("accessibility_high_score", comment: "High score accessibility"))
                .accessibilityHint(NSLocalizedString("accessibility_high_score_hint", comment: "High score hint"))
                .accessibilityAddTraits(.isButton)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            }
            .padding(isIPad ? 60 : 20)
            .background(
                LinearGradient(colors: [.cyan.opacity(0.3), .blue.opacity(0.1)], 
                              startPoint: .top, endPoint: .bottom)
            )
        }
    }
}