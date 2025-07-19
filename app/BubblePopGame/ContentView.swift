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
    @State private var gameViewModel: GameViewModel?
    @State private var menuViewModel: MenuViewModel
    
    init() {
        self._menuViewModel = State(initialValue: MenuViewModel())
    }
    
    var body: some View {
        NavigationStack {
            if let gameViewModel = gameViewModel {
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
            } else {
                // 初期化中
                ProgressView("初期化中...")
                    .onAppear {
                        setupDependencies()
                    }
            }
        }
    }
    
    private func setupDependencies() {
        // ModelContainer取得
        let modelContainer = modelContext.container
        
        // Repositories作成
        let scoreRepository = ScoreRepositoryImpl(modelContainer: modelContainer)
        let settingsRepository = SettingsRepositoryImpl(modelContainer: modelContainer)
        let statisticsRepository = StatisticsRepositoryImpl(modelContainer: modelContainer)
        
        // Services作成
        let screenBounds = CGRect(x: 0, y: 0, width: 393, height: 852)
        let bubbleService = BubbleServiceImpl(screenBounds: screenBounds)
        let audioService = AudioServiceImpl()
        let effectService = EffectServiceImpl()
        
        // ゲーム設定読み込み
        let gameSettings: GameSettings
        do {
            gameSettings = try settingsRepository.fetchSettings() ?? GameSettings()
        } catch {
            print("Failed to load settings: \(error)")
            gameSettings = GameSettings()
        }
        
        // GameViewModel作成
        self.gameViewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            scoreRepository: scoreRepository,
            settingsRepository: settingsRepository,
            statisticsRepository: statisticsRepository,
            gameSettings: gameSettings
        )
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
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.1)], 
                              startPoint: .top, endPoint: .bottom)
                
                // Bubbles
                ForEach(viewModel.bubbles) { bubble in
                    BubbleView(bubble: bubble)
                }
                
                // HUD
                VStack {
                    HStack {
                        Text("スコア: \(viewModel.score)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Text("残り時間: \(Int(viewModel.timeRemaining))秒")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                    .padding()
                    
                    Spacer()
                    
                    // ポーズボタン
                    if viewModel.gameState == .playing {
                        Button(action: {
                            viewModel.pauseGame()
                        }) {
                            Image(systemName: "pause.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.bottom, 50)
                    } else if viewModel.gameState == .paused {
                        VStack {
                            Text("ポーズ中")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    viewModel.resumeGame()
                                }) {
                                    Text("再開")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    viewModel.endGame()
                                }) {
                                    Text("終了")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .onTapGesture { location in
                viewModel.handleBubbleTap(at: location)
            }
            .onAppear {
                viewModel.updateScreenBounds(geometry.frame(in: .local))
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

struct BubbleView: View {
    let bubble: Bubble
    
    var body: some View {
        ZStack {
            // メインのシャボン玉
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            bubble.color.opacity(0.6),
                            bubble.color.opacity(bubble.alpha),
                            bubble.color.opacity(0.8)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: bubble.radius
                    )
                )
                .frame(width: bubble.radius * 2, height: bubble.radius * 2)
            
            // ハイライト効果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.2, y: 0.2),
                        startRadius: 0,
                        endRadius: bubble.radius * 0.6
                    )
                )
                .frame(width: bubble.radius * 1.2, height: bubble.radius * 1.2)
            
            // 数字表示（番号付きシャボン玉の場合）
            if bubble.type == .numbered, let number = bubble.number {
                Text("\(number)")
                    .font(.system(size: bubble.radius * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1, x: 1, y: 1)
            }
        }
        .position(bubble.position)
        .scaleEffect(bubble.isPopping ? 0 : 1)
        .rotation3DEffect(
            .degrees(bubble.animationPhase * 10),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.easeOut(duration: 0.3), value: bubble.isPopping)
        .animation(.easeInOut(duration: 2), value: bubble.animationPhase)
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
