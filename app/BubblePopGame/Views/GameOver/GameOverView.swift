//
//  GameOverView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct GameOverView: View {
    let viewModel: GameViewModel
    @State private var showingStats = false
    
    var body: some View {
        VStack(spacing: 30) {
            // ゲーム終了タイトル
            VStack(spacing: 10) {
                Text(NSLocalizedString("gameover_title", comment: "Game over title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red.accessible())
                
                Text(NSLocalizedString("gameover_congratulations", comment: "Congratulations message"))
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // スコア表示セクション
            VStack(spacing: 20) {
                ScoreCard(title: NSLocalizedString("gameover_final_score", comment: "Final score title"), value: "\(viewModel.score)", color: .orange.accessible())
                
                HStack(spacing: 15) {
                    ScoreCard(title: NSLocalizedString("gameover_bubbles_count", comment: "Bubbles count title"), value: "\(viewModel.bubblesPopped)", color: .blue.accessible())
                    ScoreCard(title: NSLocalizedString("gameover_max_chain", comment: "Max chain title"), value: "\(viewModel.bestStreak)", color: .purple.accessible())
                }
                
                ScoreCard(title: NSLocalizedString("gameover_accuracy", comment: "Accuracy title"), value: String(format: NSLocalizedString("percentage_format", comment: "Percentage format"), viewModel.calculateAccuracy() * 100), color: .green.accessible())
            }
            
            // ボタン群
            VStack(spacing: 15) {
                Button(action: {
                    viewModel.audioService.playSFX(name: "button_tap")
                    viewModel.startGame()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(NSLocalizedString("gameover_play_again", comment: "Play again button"))
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    viewModel.audioService.playSFX(name: "button_tap")
                    viewModel.gameState = .menu
                }) {
                    HStack {
                        Image(systemName: "house")
                        Text(NSLocalizedString("menu_back_to_menu", comment: "Back to menu button"))
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showingStats.toggle()
                    viewModel.audioService.playSFX(name: "button_tap")
                }) {
                    HStack {
                        Image(systemName: "chart.bar")
                        Text(NSLocalizedString("gameover_detailed_stats", comment: "Detailed stats button"))
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 30)
            
            if showingStats {
                VStack(spacing: 10) {
                    Text(NSLocalizedString("gameover_stats_title", comment: "Game statistics title"))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        StatRow(label: NSLocalizedString("gameover_play_time", comment: "Play time label"), value: String(format: NSLocalizedString("seconds_format", comment: "Seconds format with decimal"), 60.0 - viewModel.timeRemaining))
                        StatRow(label: NSLocalizedString("gameover_avg_reaction", comment: "Average reaction time label"), value: viewModel.bubblesPopped > 0 ? String(format: "%.2f" + NSLocalizedString("game_seconds_unit", comment: "Seconds unit") + "/" + NSLocalizedString("game_pieces_unit", comment: "Pieces unit"), (60.0 - viewModel.timeRemaining) / Double(viewModel.bubblesPopped)) : "N/A")
                        StatRow(label: NSLocalizedString("gameover_bubble_density", comment: "Bubble density label"), value: String(format: "%.1f" + NSLocalizedString("game_pieces_unit", comment: "Pieces unit") + "/" + NSLocalizedString("game_seconds_unit", comment: "Seconds unit"), Double(viewModel.bubblesPopped) / max(1, 60.0 - viewModel.timeRemaining)))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 30)
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(colors: [.red.accessible().opacity(0.3), .orange.accessible().opacity(0.1)], 
                          startPoint: .top, endPoint: .bottom)
        )
    }
}