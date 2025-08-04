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
                Text("ゲーム終了")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red.accessible())
                
                Text("お疲れ様でした！")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // スコア表示セクション
            VStack(spacing: 20) {
                ScoreCard(title: "最終スコア", value: "\(viewModel.score)", color: .orange.accessible())
                
                HStack(spacing: 15) {
                    ScoreCard(title: "破裂数", value: "\(viewModel.bubblesPopped)", color: .blue.accessible())
                    ScoreCard(title: "最大連鎖", value: "\(viewModel.bestStreak)", color: .purple.accessible())
                }
                
                ScoreCard(title: "正確率", value: String(format: "%.1f%%", viewModel.calculateAccuracy() * 100), color: .green.accessible())
            }
            
            // ボタン群
            VStack(spacing: 15) {
                Button(action: {
                    viewModel.audioService.playSFX(name: "button_tap")
                    viewModel.startGame()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("もう一度プレイ")
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
                        Text("メニューに戻る")
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
                        Text("詳細統計")
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
                    Text("ゲーム統計")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        StatRow(label: "プレイ時間", value: String(format: "%.1f秒", 60.0 - viewModel.timeRemaining))
                        StatRow(label: "平均反応速度", value: viewModel.bubblesPopped > 0 ? String(format: "%.2f秒/個", (60.0 - viewModel.timeRemaining) / Double(viewModel.bubblesPopped)) : "N/A")
                        StatRow(label: "シャボン玉密度", value: String(format: "%.1f個/秒", Double(viewModel.bubblesPopped) / max(1, 60.0 - viewModel.timeRemaining)))
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