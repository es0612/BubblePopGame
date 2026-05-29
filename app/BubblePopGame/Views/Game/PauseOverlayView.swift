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
            Text(NSLocalizedString("pause_title", comment: "Pause title"))
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
                        Text(NSLocalizedString("pause_resume", comment: "Resume button"))
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
                .accessibilityLabel(NSLocalizedString("pause_resume", comment: "Resume accessibility"))
                .accessibilityHint(NSLocalizedString("accessibility_pause_resume_hint", comment: "Resume hint"))
                .accessibilityAddTraits(.isButton)
                
                // 終了ボタン（2.5秒遅延で表示）
                if showExitButton {
                    Button(action: {
                        showExitConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text(NSLocalizedString("pause_quit", comment: "Quit button"))
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
                    .accessibilityLabel(NSLocalizedString("pause_quit", comment: "Quit accessibility"))
                    .accessibilityHint(NSLocalizedString("accessibility_pause_quit_hint", comment: "Quit hint"))
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
        .alert(NSLocalizedString("pause_confirm_exit_title", comment: "Exit confirmation title"), isPresented: $showExitConfirmation) {
            Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) {
                showExitConfirmation = false
            }
            Button(NSLocalizedString("pause_quit", comment: "Quit button"), role: .destructive) {
                gameViewModel.endGame()
            }
        } message: {
            Text(NSLocalizedString("pause_confirm_exit_message", comment: "Exit confirmation message"))
        }
    }
}