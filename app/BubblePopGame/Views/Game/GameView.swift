//
//  GameView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct GameView: View {
    let viewModel: GameViewModel
    @State private var particleEffectViewModel = ParticleEffectViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.1)], 
                              startPoint: .top, endPoint: .bottom)
                
                // Bubbles
                ForEach(viewModel.bubbles) { bubble in
                    BubbleView(bubble: bubble)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.bubbles.count)
                
                // Particle Effects
                ParticleEffectView(viewModel: particleEffectViewModel)
                
                // HUD
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("game_score", comment: "Score label"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(viewModel.score)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            if viewModel.currentStreak >= 3 {
                                Text(String(format: NSLocalizedString("game_chain", comment: "Chain label"), viewModel.currentStreak))
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(NSLocalizedString("accessibility_current_score", comment: "Current score accessibility").replacingOccurrences(of: "%d", with: "\(viewModel.score)") + (viewModel.currentStreak >= 3 ? String(format: NSLocalizedString("accessibility_chain_info", comment: "Chain info accessibility"), viewModel.currentStreak) : ""))
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 2) {
                            if viewModel.gameSettings.gameMode == "numbered" {
                                // レベル表示
                                HStack(spacing: 4) {
                                    Text(String(format: NSLocalizedString("game_level", comment: "Level label"), viewModel.currentLevel))
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    if viewModel.perfectChain > 0 {
                                        Text(String(format: NSLocalizedString("multiplier_format", comment: "Multiplier format"), Double(viewModel.perfectChain + 1)))
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                Text(NSLocalizedString("game_next_number", comment: "Next number label"))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(viewModel.nextExpectedNumber)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                                
                                // スピードボーナス表示
                                if viewModel.speedBonus > 1.0 {
                                    Text(String(format: NSLocalizedString("multiplier_format", comment: "Speed bonus multiplier"), viewModel.speedBonus))
                                        .font(.caption2)
                                        .foregroundColor(.cyan)
                                }
                            } else {
                                Text(NSLocalizedString("game_bubbles_popped", comment: "Bubbles popped label"))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(viewModel.bubblesPopped)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(viewModel.gameSettings.gameMode == "numbered" ? String(format: NSLocalizedString("accessibility_next_number", comment: "Next number accessibility"), viewModel.nextExpectedNumber) : String(format: NSLocalizedString("accessibility_bubbles_popped", comment: "Bubbles popped accessibility"), viewModel.bubblesPopped))
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(NSLocalizedString("game_time_remaining", comment: "Time remaining label"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text(String(format: NSLocalizedString("seconds_format", comment: "Seconds format"), Int(viewModel.timeRemaining)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.timeRemaining <= 10 ? .red : .white)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(String(format: NSLocalizedString("accessibility_time_remaining", comment: "Time remaining accessibility"), Int(viewModel.timeRemaining)) + (viewModel.timeRemaining <= 10 ? NSLocalizedString("accessibility_time_warning", comment: "Time warning accessibility") : ""))
                        
                        // ポーズボタンをHUD領域に移動
                        if viewModel.gameState == .playing {
                            Button(action: {
                                viewModel.pauseGame()
                            }) {
                                Image(systemName: "pause.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel(NSLocalizedString("accessibility_pause", comment: "Pause accessibility"))
                            .accessibilityHint(NSLocalizedString("accessibility_pause_hint", comment: "Pause hint accessibility"))
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.black.opacity(0.4))
                            .shadow(radius: 5)
                    )
                    .padding(.horizontal)
                    
                    // プログレスバー（時間）
                    ProgressView(value: viewModel.timeRemaining, total: viewModel.gameSettings.gameTime)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .accentColor(viewModel.timeRemaining <= 10 ? .red : .cyan)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // ポーズ状態のオーバーレイ
                    if viewModel.gameState == .paused {
                        PauseOverlayView(gameViewModel: viewModel)
                    }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        viewModel.handleBubbleTap(at: value.location)
                    }
            )
            .onAppear {
                viewModel.updateScreenBounds(geometry.frame(in: .local))
                viewModel.setupParticleEffectViewModel(particleEffectViewModel)
                if viewModel.gameState != .playing {
                    viewModel.startGame()
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                viewModel.updateScreenBounds(CGRect(origin: .zero, size: newSize))
            }
        }
    }
}