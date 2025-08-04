//
//  PauseOverlayView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct PauseOverlayView: View {
    let gameViewModel: GameViewModel
    @State private var showExitButton = false
    @State private var showExitConfirmation = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("ポーズ中")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(radius: 5)
            
            VStack(spacing: 20) {
                // 再開ボタン（常に表示）
                Button(action: {
                    gameViewModel.resumeGame()
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("再開")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(15)
                    .shadow(radius: 3)
                }
                .accessibilityLabel("再開")
                .accessibilityHint("ゲームを再開します")
                .accessibilityAddTraits(.isButton)
                
                // 終了ボタン（2.5秒遅延で表示）
                if showExitButton {
                    Button(action: {
                        showExitConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("終了")
                        }
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(15)
                        .shadow(radius: 3)
                    }
                    .accessibilityIdentifier("pauseEndButton")
                    .accessibilityLabel("終了")
                    .accessibilityHint("ゲームを終了してメニューに戻ります")
                    .accessibilityAddTraits(.isButton)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
        .onAppear {
            // 2.5秒後に終了ボタンを表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showExitButton = true
                }
            }
        }
        .onDisappear {
            showExitButton = false
            showExitConfirmation = false
        }
        .alert("ゲーム終了確認", isPresented: $showExitConfirmation) {
            Button("キャンセル", role: .cancel) {
                showExitConfirmation = false
            }
            Button("終了", role: .destructive) {
                gameViewModel.endGame()
            }
        } message: {
            Text("本当にゲームを終了しますか？\n現在のゲームが終了します。")
        }
    }
}