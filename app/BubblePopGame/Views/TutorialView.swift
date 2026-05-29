//
//  TutorialView.swift
//  BubblePopGame
//
//  Created on 2025/07/22
//

import SwiftUI

struct TutorialView: View {
    let gameViewModel: GameViewModel
    @State private var currentStep: Int = 0
    @State private var tutorialBubbles: [Bubble] = []
    @State private var showTapHint = false
    @State private var hasCompletedTap = false
    @State private var tutorialScore = 0
    
    private let totalSteps = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.1)], 
                              startPoint: .top, endPoint: .bottom)
                
                // Tutorial Bubbles (only for step 2)
                if currentStep == 2 {
                    ForEach(tutorialBubbles) { bubble in
                        TutorialBubbleView(bubble: bubble)
                    }
                }
                
                // スキップボタン（右上に配置）
                VStack {
                    HStack {
                        Spacer()
                        Button(NSLocalizedString("skip", comment: "Skip button")) {
                            skipTutorial()
                        }
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .accessibilityLabel(NSLocalizedString("skip", comment: "Skip accessibility"))
                        .accessibilityHint(NSLocalizedString("accessibility_tutorial_skip_hint", comment: "Skip tutorial hint"))
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                    Spacer()
                }
                
                // Tutorial Content
                VStack(spacing: 40) {
                    // Progress indicator
                    HStack {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            Circle()
                                .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Step Content
                    VStack(spacing: 30) {
                        stepContent
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Navigation Buttons
                    HStack(spacing: 20) {
                        if currentStep > 0 {
                            Button(NSLocalizedString("back", comment: "Back button")) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    previousStep()
                                }
                            }
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Button(currentStep == totalSteps - 1 ? NSLocalizedString("tutorial_complete_button", comment: "Complete tutorial button") : NSLocalizedString("next", comment: "Next button")) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if currentStep == totalSteps - 1 {
                                    completeTutorial()
                                } else {
                                    nextStep()
                                }
                            }
                        }
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(canProceed ? Color.blue : Color.gray)
                        .accessibilityIdentifier(currentStep == totalSteps - 1 ? "tutorialComplete" : "tutorialNext")
                        .cornerRadius(10)
                        .disabled(!canProceed)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        if currentStep == 2 {
                            handleTutorialTap(at: value.location)
                        }
                    }
            )
            .onAppear {
                gameViewModel.updateScreenBounds(geometry.frame(in: .local))
                if currentStep == 2 {
                    setupTutorialBubbles()
                }
                
                // チュートリアル開始時にBGMを再生
                if gameViewModel.gameSettings.bgmEnabled && gameViewModel.gameSettings.bgmTrack != "off" {
                    gameViewModel.audioService.playBGMTrack(gameViewModel.gameSettings.bgmTrack, loop: true)
                }
            }
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            gameBasicsStep
        case 2:
            practiceStep
        case 3:
            gameModesStep
        default:
            EmptyView()
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(NSLocalizedString("tutorial_welcome", comment: "Welcome title"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(NSLocalizedString("tutorial_welcome_subtitle", comment: "Welcome subtitle"))
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text(NSLocalizedString("tutorial_welcome_description", comment: "Welcome description"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
        }
    }
    
    private var gameBasicsStep: some View {
        VStack(spacing: 25) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text(NSLocalizedString("tutorial_objective_title", comment: "Objective title"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.red)
                    Text(NSLocalizedString("tutorial_time_limit", comment: "Time limit info"))
                        .font(.title3)
                }
                
                HStack {
                    Image(systemName: "hand.point.up.fill")
                        .foregroundColor(.blue)
                    Text(NSLocalizedString("tutorial_tap_bubbles", comment: "Tap bubbles info"))
                        .font(.title3)
                }
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(NSLocalizedString("tutorial_get_score", comment: "Get score info"))
                        .font(.title3)
                }
                
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.purple)
                    Text(NSLocalizedString("tutorial_chain_bonus", comment: "Chain bonus info"))
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var practiceStep: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("tutorial_practice_title", comment: "Practice title"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if !hasCompletedTap {
                VStack(spacing: 15) {
                    Text(NSLocalizedString("tutorial_practice_instruction", comment: "Practice instruction"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if showTapHint {
                        HStack {
                            Image(systemName: "hand.point.down.fill")
                                .foregroundColor(.blue)
                                .scaleEffect(showTapHint ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showTapHint)
                            Text(NSLocalizedString("tutorial_tap_here", comment: "Tap here text"))
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text(NSLocalizedString("tutorial_excellent", comment: "Excellent text"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text(String(format: NSLocalizedString("game_score", comment: "Score label") + ": %d", tutorialScore))
                        .font(.title3)
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("tutorial_practice_description", comment: "Practice description"))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var gameModesStep: some View {
        VStack(spacing: 25) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text(NSLocalizedString("tutorial_modes_title", comment: "Game modes title"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(.blue)
                        Text(NSLocalizedString("tutorial_normal_mode_title", comment: "Normal mode title"))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Text(NSLocalizedString("tutorial_normal_mode_description", comment: "Normal mode description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.leading, 25)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "123.rectangle")
                            .foregroundColor(.orange)
                        Text(NSLocalizedString("tutorial_numbered_mode_title", comment: "Numbered mode title"))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Text(NSLocalizedString("tutorial_numbered_mode_description", comment: "Numbered mode description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.leading, 25)
                }
            }
            .padding(.horizontal, 20)
            
            Text(NSLocalizedString("tutorial_ready_message", comment: "Ready message"))
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top, 10)
        }
    }
    
    private var canProceed: Bool {
        if currentStep == 2 {
            return hasCompletedTap
        }
        return true
    }
    
    private func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
            
            if currentStep == 2 {
                setupTutorialBubbles()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showTapHint = true
                }
            }
        }
    }
    
    private func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
            
            if currentStep != 2 {
                tutorialBubbles.removeAll()
                hasCompletedTap = false
                showTapHint = false
                tutorialScore = 0
            }
        }
    }
    
    private func setupTutorialBubbles() {
        tutorialBubbles.removeAll()
        hasCompletedTap = false
        showTapHint = false
        tutorialScore = 0
        
        // 画面の下部4分の1の領域に配置（文字と重複しないよう）
        let screenHeight = gameViewModel.screenBounds.height
        let screenWidth = gameViewModel.screenBounds.width
        let bubbleY = screenHeight * 0.75 // 画面の下部4分の1
        let bubbleX = screenWidth * 0.5   // 画面の中央
        
        let centerBubble = Bubble(
            position: CGPoint(x: bubbleX, y: bubbleY),
            velocity: CGVector.zero,
            radius: 50,
            type: .normal,
            number: nil,
            color: .blue,
            alpha: 1.0,
            animationPhase: 0.0
        )
        tutorialBubbles.append(centerBubble)
    }
    
    private func handleTutorialTap(at location: CGPoint) {
        guard !hasCompletedTap else { return }
        
        if let hitBubbleIndex = findHitBubble(at: location) {
            var hitBubble = tutorialBubbles[hitBubbleIndex]
            hitBubble.isPopping = true
            tutorialBubbles[hitBubbleIndex] = hitBubble
            
            tutorialScore += 1
            hasCompletedTap = true
            showTapHint = false
            
            // 破裂エフェクト
            gameViewModel.audioService.playSFX(name: "bubble_pop")
            
            // 0.3秒後にシャボン玉を削除
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                tutorialBubbles.removeAll { $0.id == hitBubble.id }
            }
        }
    }
    
    private func findHitBubble(at location: CGPoint) -> Int? {
        for (index, bubble) in tutorialBubbles.enumerated() {
            let distance = sqrt(pow(location.x - bubble.position.x, 2) + pow(location.y - bubble.position.y, 2))
            if distance <= bubble.radius {
                return index
            }
        }
        return nil
    }
    
    private func skipTutorial() {
        // 初回起動フラグを無効にする
        gameViewModel.gameSettings.isFirstLaunch = false
        
        // 設定を保存
        do {
            try gameViewModel.saveGameSettings()
        } catch {
            print("Failed to save tutorial skip: \(error)")
        }
        
        // メニュー画面に遷移
        gameViewModel.gameState = .menu
    }
    
    private func completeTutorial() {
        // 初回起動フラグを無効にする
        gameViewModel.gameSettings.isFirstLaunch = false
        
        // 設定を保存
        do {
            try gameViewModel.saveGameSettings()
        } catch {
            print("Failed to save tutorial completion: \(error)")
        }
        
        // メニュー画面に遷移
        gameViewModel.gameState = .menu
    }
}

struct TutorialBubbleView: View {
    let bubble: Bubble
    
    var body: some View {
        ZStack {
            // シンプルなシャボン玉表示（BubbleViewの簡略版）
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.8),
                            Color.cyan.opacity(0.6),
                            Color.blue.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .background(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.clear,
                                    bubble.color.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 0,
                                endRadius: bubble.radius
                            )
                        )
                )
                .frame(width: bubble.radius * 2, height: bubble.radius * 2)
            
            // ハイライト効果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: bubble.radius * 0.5
                    )
                )
                .frame(width: bubble.radius * 0.8, height: bubble.radius * 0.8)
        }
        .position(bubble.position)
        .scaleEffect(bubble.isPopping ? 0 : 1)
        .opacity(bubble.isPopping ? 0 : bubble.alpha)
        .animation(.easeOut(duration: 0.3), value: bubble.isPopping)
    }
}

#Preview {
    // プレビュー用のダミーGameViewModel
    let dummyGameViewModel = GameViewModel(
        bubbleService: BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 393, height: 852)),
        audioService: AudioServiceImpl(),
        effectService: EffectServiceImpl(),
        deviceService: DeviceServiceImpl(),
        performanceService: PerformanceServiceImpl(),
        scoreRepository: ScoreRepositoryMock(),
        settingsRepository: SettingsRepositoryMock(),
        statisticsRepository: StatisticsRepositoryMock()
    )
    
    TutorialView(gameViewModel: dummyGameViewModel)
}

// プレビュー用のMockクラス
class ScoreRepositoryMock: ScoreRepository {
    func saveScore(_ score: GameScore) throws {}
    func fetchHighScores(limit: Int) throws -> [GameScore] { return [] }
    func fetchScoresByMode(_ mode: String) throws -> [GameScore] { return [] }
    func fetchScoresByModeAndTime(_ mode: String, gameTime: Double) throws -> [GameScore] { return [] }
    func fetchAvailableGameTimes() throws -> [Double] { return [60.0] }
    func deleteScore(_ score: GameScore) throws {}
}

class SettingsRepositoryMock: SettingsRepository {
    func saveSettings(_ settings: GameSettings) throws {}
    func fetchSettings() throws -> GameSettings? { return GameSettings() }
    func resetSettings() throws {}
    func resetToDefaults() throws {}
}

class StatisticsRepositoryMock: StatisticsRepository {
    func saveStatistics(_ statistics: GameStatistics) throws {}
    func fetchStatistics() throws -> GameStatistics? { return GameStatistics() }
    func updateStatistics(with score: GameScore) throws {}
    func resetStatistics() throws {}
}