//
//  ContentView.swift
//  BubblePopGame
//  
//  Created on 2025/07/17
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var gameViewModel: GameViewModel
    @State private var menuViewModel: MenuViewModel
    
    init() {
        // TODO: Dependency Injectionで実装予定
        self._gameViewModel = State(initialValue: GameViewModel())
        self._menuViewModel = State(initialValue: MenuViewModel())
    }
    
    var body: some View {
        NavigationStack {
            switch gameViewModel.gameState {
            case .menu:
                MenuView(viewModel: menuViewModel, gameViewModel: gameViewModel)
            case .playing, .paused:
                GameView(viewModel: gameViewModel)
            case .gameOver:
                GameOverView(viewModel: gameViewModel)
            case .settings:
                SettingsView()
            }
        }
    }
}

struct MenuView: View {
    let viewModel: MenuViewModel
    let gameViewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Text("シャボン玉消しゲーム")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            VStack(spacing: 20) {
                Button(action: {
                    gameViewModel.startGame()
                }) {
                    Text("ゲーム開始")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    gameViewModel.gameState = .settings
                }) {
                    Text("設定")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(colors: [.cyan.opacity(0.3), .blue.opacity(0.1)], 
                          startPoint: .top, endPoint: .bottom)
        )
    }
}

struct GameView: View {
    let viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.1)], 
                          startPoint: .top, endPoint: .bottom)
            
            // Bubbles
            ForEach(viewModel.bubbles) { bubble in
                BubbleView(bubble: bubble)
                    .onTapGesture {
                        viewModel.handleBubbleTap(at: bubble.position)
                    }
            }
            
            // HUD
            VStack {
                HStack {
                    Text("スコア: \(viewModel.score)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text("残り時間: \(Int(viewModel.timeRemaining))秒")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
            if viewModel.gameState != .playing {
                viewModel.startGame()
            }
        }
    }
}

struct BubbleView: View {
    let bubble: Bubble
    
    var body: some View {
        Circle()
            .fill(bubble.color.opacity(bubble.alpha))
            .frame(width: bubble.radius * 2, height: bubble.radius * 2)
            .position(bubble.position)
            .scaleEffect(bubble.isPopping ? 0 : 1)
            .animation(.easeOut(duration: 0.3), value: bubble.isPopping)
    }
}

struct GameOverView: View {
    let viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Text("ゲーム終了")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text("最終スコア: \(viewModel.score)")
                .font(.title)
                .fontWeight(.semibold)
            
            Button(action: {
                viewModel.gameState = .menu
            }) {
                Text("メニューに戻る")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(colors: [.red.opacity(0.3), .orange.opacity(0.1)], 
                          startPoint: .top, endPoint: .bottom)
        )
    }
}

struct SettingsView: View {
    @State private var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("設定")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            VStack(spacing: 15) {
                HStack {
                    Text("音声")
                        .font(.title3)
                    Spacer()
                    Toggle("", isOn: $settingsViewModel.gameSettings.soundEnabled)
                }
                
                HStack {
                    Text("振動")
                        .font(.title3)
                    Spacer()
                    Toggle("", isOn: $settingsViewModel.gameSettings.vibrationEnabled)
                }
                
                HStack {
                    Text("シャボン玉数")
                        .font(.title3)
                    Spacer()
                    Text("\(settingsViewModel.gameSettings.bubbleCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(colors: [.green.opacity(0.3), .mint.opacity(0.1)], 
                          startPoint: .top, endPoint: .bottom)
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: GameScore.self, inMemory: true)
}
