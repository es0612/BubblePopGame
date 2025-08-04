//
//  GameView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct GameView: View {
    let viewModel: GameViewModel
    @State private var particleEffectView = ParticleEffectView()
    
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
                particleEffectView
                
                // HUD
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("スコア")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(viewModel.score)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            if viewModel.currentStreak >= 3 {
                                Text("連鎖: \(viewModel.currentStreak)")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("現在のスコア \(viewModel.score)ポイント\(viewModel.currentStreak >= 3 ? ", \(viewModel.currentStreak)連鎖" : "")")
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 2) {
                            if viewModel.gameSettings.gameMode == "numbered" {
                                // レベル表示
                                HStack(spacing: 4) {
                                    Text("Lv.\(viewModel.currentLevel)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    if viewModel.perfectChain > 0 {
                                        Text("×\(viewModel.perfectChain + 1)")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                Text("次の数字")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(viewModel.nextExpectedNumber)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                                
                                // スピードボーナス表示
                                if viewModel.speedBonus > 1.0 {
                                    Text("×\(String(format: "%.1f", viewModel.speedBonus))")
                                        .font(.caption2)
                                        .foregroundColor(.cyan)
                                }
                            } else {
                                Text("破裂数")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(viewModel.bubblesPopped)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(viewModel.gameSettings.gameMode == "numbered" ? "次にタップする数字 \(viewModel.nextExpectedNumber)" : "破裂させたバブル数 \(viewModel.bubblesPopped)個")
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("残り時間")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(Int(viewModel.timeRemaining))秒")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.timeRemaining <= 10 ? .red : .white)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("残り時間 \(Int(viewModel.timeRemaining))秒\(viewModel.timeRemaining <= 10 ? "、時間が少なくなっています" : "")")
                        
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
                            .accessibilityLabel("ポーズ")
                            .accessibilityHint("ゲームを一時停止します")
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
                    ProgressView(value: viewModel.timeRemaining, total: 60.0)
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
                viewModel.setupParticleEffectView(particleEffectView)
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