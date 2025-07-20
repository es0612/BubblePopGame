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
                    gameViewModel.audioService.playSFX(name: "button_tap")
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
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text("破裂数")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(viewModel.bubblesPopped)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
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
                        .progressViewStyle(LinearProgressViewStyle(tint: viewModel.timeRemaining <= 10 ? .red : .cyan))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal)
                    
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
        .scaleEffect(bubble.isPopping ? (1.0 - bubble.popAnimationProgress) : 1)
        .opacity(bubble.isPopping ? (1.0 - bubble.popAnimationProgress) : bubble.alpha)
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

struct ParticleEffect: View {
    let position: CGPoint
    let color: Color
    @State private var particles: [Particle] = []
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        particles = []
        let particleCount = Int.random(in: 8...12)
        
        for _ in 0..<particleCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let velocity = Double.random(in: 30...80)
            let size = Double.random(in: 4...12)
            
            let particle = Particle(
                position: position,
                velocity: CGVector(
                    dx: cos(angle) * velocity,
                    dy: sin(angle) * velocity
                ),
                color: color.opacity(Double.random(in: 0.6...1.0)),
                size: size,
                opacity: 1.0,
                scale: 1.0,
                lifespan: Double.random(in: 0.8...1.5)
            )
            particles.append(particle)
        }
    }
    
    private func animateParticles() {
        isAnimating = true
        
        let animationDuration = 1.5
        let steps = 60
        let stepDuration = animationDuration / Double(steps)
        
        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                updateParticles(progress: Double(step) / Double(steps))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            particles.removeAll()
            isAnimating = false
        }
    }
    
    private func updateParticles(progress: Double) {
        for i in particles.indices {
            let timeStep = 1.0 / 60.0
            
            particles[i].position.x += particles[i].velocity.dx * timeStep
            particles[i].position.y += particles[i].velocity.dy * timeStep
            
            particles[i].velocity.dy += 120 * timeStep
            
            particles[i].velocity.dx *= 0.98
            particles[i].velocity.dy *= 0.98
            
            let life = progress / particles[i].lifespan
            particles[i].opacity = max(0, 1.0 - life)
            particles[i].scale = 1.0 - (life * 0.5)
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    let color: Color
    let size: Double
    var opacity: Double
    var scale: Double
    let lifespan: Double
}

struct ParticleEffectView: View {
    @State private var effects: [ParticleEffectData] = []
    
    var body: some View {
        ZStack {
            ForEach(effects) { effect in
                ParticleEffect(position: effect.position, color: effect.color)
            }
        }
    }
    
    func addEffect(at position: CGPoint, color: Color) {
        let effect = ParticleEffectData(position: position, color: color)
        effects.append(effect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            effects.removeAll { $0.id == effect.id }
        }
    }
}

struct ParticleEffectData: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
}

#Preview {
    ContentView()
        .modelContainer(for: GameScore.self, inMemory: true)
}
