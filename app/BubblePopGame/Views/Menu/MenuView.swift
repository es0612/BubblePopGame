//
//  MenuView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct MenuView: View {
    let viewModel: MenuViewModel
    let gameViewModel: GameViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width > 600
            let spacing: CGFloat = isIPad ? 60 : 40
            
            VStack(spacing: spacing) {
            Text("シャボン玉消しゲーム")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.blue.accessible())
                .accessibilityLabel("シャボン玉消しゲーム")
                .accessibilityHint("ゲームのメインタイトルです")
            
            VStack(spacing: 20) {
                Button(action: {
                    gameViewModel.startGame()
                    gameViewModel.audioService.playSFX(name: "button_tap")
                }) {
                    Text("ゲーム開始")
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
                .accessibilityLabel("ゲーム開始")
                .accessibilityHint("タップするとゲームが開始されます")
                .accessibilityAddTraits(.isButton)
                
                Button(action: {
                    gameViewModel.gameState = .settings
                    gameViewModel.audioService.playSFX(name: "button_tap")
                }) {
                    Text("設定")
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
                .accessibilityLabel("設定")
                .accessibilityHint("ゲームの設定を変更できます")
                .accessibilityAddTraits(.isButton)
                
                // ハイスコア表示ボタン
                Button(action: {
                    gameViewModel.gameState = .highScore
                    gameViewModel.audioService.playSFX(name: "button_tap")
                }) {
                    Text("ハイスコア")
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
                .accessibilityLabel("ハイスコア")
                .accessibilityHint("過去のハイスコアを確認できます")
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