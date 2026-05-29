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
    @State private var settingsViewModel: SettingsViewModel?
    
    init() {
        self._menuViewModel = State(initialValue: MenuViewModel())
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                if let gameViewModel = gameViewModel {
                    switch gameViewModel.gameState {
                    case .tutorial:
                        TutorialView(gameViewModel: gameViewModel)
                    case .menu:
                        MenuView(viewModel: menuViewModel, gameViewModel: gameViewModel)
                    case .playing, .paused:
                        GameView(viewModel: gameViewModel)
                    case .gameOver:
                        GameOverView(viewModel: gameViewModel)
                    case .settings:
                        if let settingsViewModel = settingsViewModel {
                            SettingsView(viewModel: settingsViewModel, gameViewModel: gameViewModel) {
                                // チュートリアル状態の場合はメニューに戻さない
                                if gameViewModel.gameState != .tutorial {
                                    gameViewModel.gameState = .menu
                                }
                            }
                        } else {
                            ProgressView("設定読み込み中...")
                        }
                    case .highScore:
                        HighScoreView(gameViewModel: gameViewModel)
                    }
                } else {
                    // 初期化中
                    ProgressView("初期化中...")
                        .onAppear {
                            setupDependencies(screenSize: geometry.size)
                        }
                }
            }
            .onAppear {
                // 画面サイズが変更された時の処理
                if let gameViewModel = gameViewModel {
                    gameViewModel.updateScreenBounds(geometry.size)
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                // 画面サイズ変更時（回転等）
                if let gameViewModel = gameViewModel {
                    gameViewModel.updateScreenBounds(newSize)
                }
            }
            .onChange(of: gameViewModel?.gameState) { _, newState in
                // ゲーム状態変更時の処理
                if let gameViewModel = gameViewModel, newState == .menu {
                    // メニューに戻ったときのBGM自動再開
                    resumeBGMOnMenuReturn(gameViewModel: gameViewModel)
                    
                    // 設定の同期確認（チュートリアル完了後の同期）
                    do {
                        try gameViewModel.reloadGameSettings()
                    } catch {
                        print("Failed to reload settings: \(error)")
                    }
                }
            }
        }
    }
    
    private func setupDependencies(screenSize: CGSize) {
        // ModelContainer取得
        let modelContainer = modelContext.container
        
        // Repositories作成
        let scoreRepository = ScoreRepositoryImpl(modelContainer: modelContainer)
        let settingsRepository = SettingsRepositoryImpl(modelContainer: modelContainer)
        let statisticsRepository = StatisticsRepositoryImpl(modelContainer: modelContainer)
        
        // 新しいサービス作成
        let deviceService = DeviceServiceImpl()
        let performanceService = PerformanceServiceImpl()
        
        // Services作成（画面サイズを使用）
        let screenBounds = CGRect(origin: .zero, size: screenSize)
        let bubbleService = BubbleServiceImpl(screenBounds: screenBounds)
        let audioService = AudioServiceImpl()
        let effectService = EffectServiceImpl()
        
        // ゲーム設定読み込み
        let gameSettings: GameSettings
        do {
            if let existingSettings = try settingsRepository.fetchSettings() {
                gameSettings = existingSettings
            } else {
                // 初回起動時のみ新しい設定を作成して保存
                let newSettings = GameSettings()
                try settingsRepository.saveSettings(newSettings)
                gameSettings = newSettings
            }
        } catch {
            print("Failed to load settings: \(error)")
            // エラー時も初回起動として扱う
            let newSettings = GameSettings()
            gameSettings = newSettings
        }
        
        // SettingsViewModel作成
        self.settingsViewModel = SettingsViewModel(settingsRepository: settingsRepository, audioService: audioService)
        
        // GameViewModel作成
        let viewModel = GameViewModel(
            bubbleService: bubbleService,
            audioService: audioService,
            effectService: effectService,
            deviceService: deviceService,
            performanceService: performanceService,
            scoreRepository: scoreRepository,
            settingsRepository: settingsRepository,
            statisticsRepository: statisticsRepository,
            gameSettings: gameSettings
        )
        
        // GameView マウント前でも MenuView の Start ボタン経由で startGame() が
        // 呼ばれる経路があるため、ここで screenBounds を初期化しておく。
        // （GameViewModel.startGame() の guard が .zero で early-return する）
        viewModel.updateScreenBounds(CGRect(origin: .zero, size: screenSize))

        // 初回起動時はチュートリアル、そうでなければメニュー。
        // gameSettings は SwiftData で autosave されるため、デバッグ override で
        // モデルを書き換えると通常起動にも永続化されてしまう。永続モデルは変更せず、
        // 初期遷移先の判定と GameViewModel の実効値 override のみをローカルに決定する。
        #if DEBUG
        let debugOptions = DebugLaunchOptions(arguments: CommandLine.arguments)
        // --skip-tutorial: チュートリアルを bypass する（Issue #8）
        let shouldShowTutorial = gameSettings.isFirstLaunch && !debugOptions.skipTutorial
        // --game-time / --game-mode: GameViewModel の実効値を override（Issue #13）。
        // gameSettings は書き換えないので永続化されない。
        viewModel.debugGameTimeOverride = debugOptions.gameTime
        if let mode = debugOptions.gameMode, GameMode(rawValue: mode) != nil {
            viewModel.debugGameModeOverride = mode
        }
        #else
        let shouldShowTutorial = gameSettings.isFirstLaunch
        #endif

        viewModel.gameState = shouldShowTutorial ? .tutorial : .menu

        self.gameViewModel = viewModel
    }
    
    private func resumeBGMOnMenuReturn(gameViewModel: GameViewModel) {
        // BGMが有効でトラックが設定されているが現在再生されていない場合に再開
        let settings = gameViewModel.gameSettings
        let audioService = gameViewModel.audioService
        
        if settings.bgmEnabled && 
           settings.bgmTrack != "off" && 
           !audioService.isPlaying && 
           !audioService.isPaused {
            
            print("🎵 メニュー復帰時にBGMを自動再開: \(settings.bgmTrack)")
            audioService.playBGMTrack(settings.bgmTrack, loop: true)
        } else if settings.bgmEnabled && 
                  settings.bgmTrack != "off" && 
                  audioService.isPaused {
            
            print("🎵 メニュー復帰時にBGMを再開（ポーズ解除）")
            audioService.resumeBGM()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: GameScore.self, inMemory: true)
}