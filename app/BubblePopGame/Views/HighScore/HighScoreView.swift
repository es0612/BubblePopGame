//
//  HighScoreView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct HighScoreView: View {
    let gameViewModel: GameViewModel
    @State private var highScores: [GameScore] = []
    @State private var selectedMode: String = "normal"
    @State private var selectedTimeLimit: Double = 60.0
    @State private var availableTimeLimits: [Double] = [60.0]
    
    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("highscore_title", comment: "High score title"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple.accessible())
                .padding()
            
            VStack(spacing: 15) {
                // ゲームモード選択
                Picker(NSLocalizedString("settings_game_mode", comment: "Game mode picker"), selection: $selectedMode) {
                    Text(NSLocalizedString("highscore_normal_mode", comment: "Normal mode tab")).tag("normal")
                    Text(NSLocalizedString("highscore_numbered_mode", comment: "Numbered mode tab")).tag("numbered")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedMode) { _, newMode in
                    loadHighScores(for: newMode, timeLimit: selectedTimeLimit)
                }
                
                // 制限時間選択
                if availableTimeLimits.count > 1 {
                    HStack {
                        Text(NSLocalizedString("highscore_time_limit", comment: "Time limit label"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker(NSLocalizedString("settings_time_limit", comment: "Time limit picker label"), selection: $selectedTimeLimit) {
                            ForEach(availableTimeLimits, id: \.self) { timeLimit in
                                Text(String(format: NSLocalizedString("seconds_format", comment: "Seconds format"), Int(timeLimit))).tag(timeLimit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedTimeLimit) { _, newTimeLimit in
                            loadHighScores(for: selectedMode, timeLimit: newTimeLimit)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            
            // スコアリスト
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(highScores.enumerated()), id: \.element.id) { index, score in
                        HighScoreRow(rank: index + 1, score: score)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // 戻るボタン
            Button(action: {
                gameViewModel.audioService.playSFX(name: "button_tap")
                gameViewModel.gameState = .menu
            }) {
                HStack {
                    Image(systemName: "house")
                    Text(NSLocalizedString("menu_back_to_menu", comment: "Back to menu button"))
                }
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple.accessible())
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .background(
            LinearGradient(colors: [.purple.accessible().opacity(0.3), .pink.accessible().opacity(0.1)], 
                          startPoint: .top, endPoint: .bottom)
        )
        .onAppear {
            loadAvailableTimeLimits()
            loadHighScores(for: selectedMode, timeLimit: selectedTimeLimit)
        }
    }
    
    private func loadAvailableTimeLimits() {
        do {
            let times = try gameViewModel.scoreRepository.fetchAvailableGameTimes()
            availableTimeLimits = times.isEmpty ? [60.0] : times
            if !availableTimeLimits.contains(selectedTimeLimit) {
                selectedTimeLimit = availableTimeLimits.first ?? 60.0
            }
        } catch {
            print("Failed to load available time limits: \(error)")
            availableTimeLimits = [60.0]
        }
    }
    
    private func loadHighScores(for mode: String, timeLimit: Double) {
        do {
            highScores = try gameViewModel.scoreRepository.fetchScoresByModeAndTime(mode, gameTime: timeLimit)
        } catch {
            print("Failed to load high scores: \(error)")
            highScores = []
        }
    }
}