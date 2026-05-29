//
//  SettingsView.swift
//  BubblePopGame
//
//  Created on 2025/07/22
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    let gameViewModel: GameViewModel?
    let onDismiss: () -> Void
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // ゲーム設定セクション
                    SettingsSection(title: NSLocalizedString("settings_game_section", comment: "Game settings section")) {
                        VStack(spacing: 15) {
                            SettingsRow(
                                icon: "gamecontroller.fill",
                                title: NSLocalizedString("settings_game_mode", comment: "Game mode setting"),
                                iconColor: .purple
                            ) {
                                Picker(NSLocalizedString("settings_game_mode", comment: "Game mode picker"), selection: $viewModel.gameSettings.gameMode) {
                                    Text(NSLocalizedString("settings_normal_mode", comment: "Normal mode option")).tag("normal")
                                    Text(NSLocalizedString("settings_numbered_mode", comment: "Numbered mode option")).tag("numbered")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            SettingsRow(
                                icon: "timer",
                                title: NSLocalizedString("settings_time_limit", comment: "Time limit setting"),
                                iconColor: .red
                            ) {
                                HStack {
                                    Stepper(String(format: NSLocalizedString("seconds_format", comment: "Seconds format"), Int(viewModel.gameSettings.gameTime)), 
                                           value: $viewModel.gameSettings.gameTime, 
                                           in: 30...180, 
                                           step: 15)
                                }
                            }
                            
                            SettingsRow(
                                icon: "bubble.middle.bottom.fill",
                                title: NSLocalizedString("settings_bubble_count", comment: "Bubble count setting"),
                                iconColor: .blue
                            ) {
                                HStack {
                                    Stepper(String(format: NSLocalizedString("pieces_format", comment: "Pieces format"), viewModel.gameSettings.bubbleCount), 
                                           value: $viewModel.gameSettings.bubbleCount, 
                                           in: 10...50, 
                                           step: 5)
                                }
                            }
                        }
                    }
                    
                    // 音響設定セクション
                    SettingsSection(title: NSLocalizedString("settings_audio_section", comment: "Audio settings section")) {
                        VStack(spacing: 15) {
                            SettingsRow(
                                icon: "speaker.wave.3.fill",
                                title: NSLocalizedString("settings_sound_effects", comment: "Sound effects setting"),
                                iconColor: .orange
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { viewModel.gameSettings.soundEnabled },
                                    set: { _ in viewModel.toggleSound() }
                                ))
                            }
                            
                            SettingsRow(
                                icon: "music.note",
                                title: NSLocalizedString("settings_bgm", comment: "BGM setting"),
                                iconColor: .green
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { viewModel.gameSettings.bgmEnabled },
                                    set: { _ in viewModel.toggleBGM() }
                                ))
                            }
                            
                            if viewModel.gameSettings.bgmEnabled {
                                SettingsRow(
                                    icon: "music.note.list",
                                    title: NSLocalizedString("settings_bgm_selection", comment: "BGM selection setting"),
                                    iconColor: .green
                                ) {
                                    Picker(NSLocalizedString("settings_bgm_selection", comment: "BGM track picker"), selection: Binding(
                                        get: { viewModel.gameSettings.bgmTrack },
                                        set: { viewModel.setBGMTrack($0) }
                                    )) {
                                        Text(NSLocalizedString("settings_bgm_track1", comment: "BGM track 1")).tag("track1")
                                        Text(NSLocalizedString("settings_bgm_track2", comment: "BGM track 2")).tag("track2")  
                                        Text(NSLocalizedString("settings_bgm_track3", comment: "BGM track 3")).tag("track3")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                            }
                            
                            SettingsRow(
                                icon: "music.quarternote.3",
                                title: NSLocalizedString("settings_bgm_volume", comment: "BGM volume setting"),
                                iconColor: .green
                            ) {
                                VStack(spacing: 5) {
                                    HStack {
                                        Text("0")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Slider(value: $viewModel.gameSettings.bgmVolume, in: 0...1, step: 0.1)
                                        Text("100")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text("\(Int(viewModel.gameSettings.bgmVolume * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            SettingsRow(
                                icon: "waveform",
                                title: NSLocalizedString("settings_sfx_volume", comment: "SFX volume setting"),
                                iconColor: .orange
                            ) {
                                VStack(spacing: 5) {
                                    HStack {
                                        Text("0")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Slider(value: $viewModel.gameSettings.sfxVolume, in: 0...1, step: 0.1)
                                        Text("100")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text("\(Int(viewModel.gameSettings.sfxVolume * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // 数字モード設定セクション
                    if viewModel.gameSettings.gameMode == "numbered" {
                        SettingsSection(title: NSLocalizedString("settings_numbered_mode_section", comment: "Numbered mode settings section")) {
                            VStack(spacing: 15) {
                                SettingsRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: NSLocalizedString("settings_progressive_difficulty", comment: "Progressive difficulty setting"),
                                    iconColor: .orange
                                ) {
                                    Toggle("", isOn: $viewModel.gameSettings.numberedModeProgressive)
                                }
                                
                                if viewModel.gameSettings.numberedModeProgressive {
                                    SettingsRow(
                                        icon: "timer.square",
                                        title: NSLocalizedString("settings_level_interval", comment: "Level interval setting"),
                                        iconColor: .orange
                                    ) {
                                        VStack(spacing: 5) {
                                            HStack {
                                                Text(String(format: NSLocalizedString("seconds_format", comment: "Seconds format"), Int(viewModel.gameSettings.numberedModeLevelInterval)))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Slider(
                                                value: $viewModel.gameSettings.numberedModeLevelInterval,
                                                in: 10...30,
                                                step: 5
                                            )
                                        }
                                    }
                                    
                                    SettingsRow(
                                        icon: "number.square",
                                        title: NSLocalizedString("settings_max_level", comment: "Max level setting"),
                                        iconColor: .orange
                                    ) {
                                        HStack {
                                            Stepper(
                                                String(format: NSLocalizedString("level_format", comment: "Level format"), viewModel.gameSettings.numberedModeMaxLevel),
                                                value: $viewModel.gameSettings.numberedModeMaxLevel,
                                                in: 3...10
                                            )
                                        }
                                    }
                                }
                                
                                SettingsRow(
                                    icon: "123.rectangle.fill",
                                    title: NSLocalizedString("settings_number_range", comment: "Number range setting"),
                                    iconColor: .blue
                                ) {
                                    VStack(spacing: 5) {
                                        HStack {
                                            Text(String(format: NSLocalizedString("range_format", comment: "Range format"), viewModel.gameSettings.numberedModeMaxRange))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Slider(
                                            value: Binding(
                                                get: { Double(viewModel.gameSettings.numberedModeMaxRange) },
                                                set: { viewModel.gameSettings.numberedModeMaxRange = Int($0) }
                                            ),
                                            in: 5...50,
                                            step: 5
                                        )
                                    }
                                }
                                
                                SettingsRow(
                                    icon: "speedometer",
                                    title: NSLocalizedString("settings_speed_bonus", comment: "Speed bonus setting"),
                                    iconColor: .cyan
                                ) {
                                    Toggle("", isOn: $viewModel.gameSettings.speedBonusEnabled)
                                }
                                
                                if viewModel.gameSettings.speedBonusEnabled {
                                    SettingsRow(
                                        icon: "multiply.circle",
                                        title: NSLocalizedString("settings_speed_bonus_multiplier", comment: "Speed bonus multiplier setting"),
                                        iconColor: .cyan
                                    ) {
                                        VStack(spacing: 5) {
                                            HStack {
                                                Text(String(format: NSLocalizedString("multiplier_format", comment: "Multiplier format"), viewModel.gameSettings.speedBonusMultiplier))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Slider(
                                                value: $viewModel.gameSettings.speedBonusMultiplier,
                                                in: 1.5...5.0,
                                                step: 0.5
                                            )
                                        }
                                    }
                                }
                                
                                SettingsRow(
                                    icon: "link",
                                    title: NSLocalizedString("settings_perfect_chain", comment: "Perfect chain setting"),
                                    iconColor: .green
                                ) {
                                    Toggle("", isOn: $viewModel.gameSettings.perfectChainEnabled)
                                }
                                
                                SettingsRow(
                                    icon: "sparkles",
                                    title: NSLocalizedString("settings_special_rule", comment: "Special rule setting"),
                                    iconColor: .purple
                                ) {
                                    Picker(NSLocalizedString("settings_special_rule", comment: "Special rule picker"), selection: $viewModel.gameSettings.numberedModeSpecialRule) {
                                        Text(NSLocalizedString("settings_special_normal", comment: "Normal special rule")).tag("normal")
                                        Text(NSLocalizedString("settings_special_reverse", comment: "Reverse special rule")).tag("reverse")
                                        Text(NSLocalizedString("settings_special_double", comment: "Double special rule")).tag("double")
                                        Text(NSLocalizedString("settings_special_random", comment: "Random special rule")).tag("random")
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                            }
                        }
                    }
                    
                    // システム設定セクション
                    SettingsSection(title: NSLocalizedString("settings_system_section", comment: "System settings section")) {
                        VStack(spacing: 15) {
                            SettingsRow(
                                icon: "iphone.radiowaves.left.and.right",
                                title: NSLocalizedString("settings_vibration", comment: "Vibration setting"),
                                iconColor: .purple
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { viewModel.gameSettings.vibrationEnabled },
                                    set: { _ in viewModel.toggleVibration() }
                                ))
                            }
                            
                            SettingsRow(
                                icon: "questionmark.circle",
                                title: NSLocalizedString("settings_show_tutorial", comment: "Show tutorial setting"),
                                iconColor: .blue
                            ) {
                                Button(NSLocalizedString("settings_show_button", comment: "Show button")) {
                                    showTutorial()
                                }
                                .font(.body)
                                .foregroundColor(gameViewModel != nil ? .blue : .gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background((gameViewModel != nil ? Color.blue : Color.gray).opacity(0.1))
                                .cornerRadius(8)
                                .disabled(gameViewModel == nil)
                            }
                        }
                    }
                    
                    // リセットボタン
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text(NSLocalizedString("settings_reset_settings", comment: "Reset settings button"))
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .navigationTitle(NSLocalizedString("settings_title", comment: "Settings title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("complete", comment: "Done button")) {
                        viewModel.saveSettings()
                        onDismiss()
                    }
                }
            }
        }
        .alert(NSLocalizedString("settings_reset_confirmation_title", comment: "Reset confirmation title"), isPresented: $showingResetConfirmation) {
            Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) { }
            Button(NSLocalizedString("reset", comment: "Reset button"), role: .destructive) {
                viewModel.resetToDefaults()
            }
        } message: {
            Text(NSLocalizedString("settings_reset_confirmation_message", comment: "Reset confirmation message"))
        }
    }
    
    private func showTutorial() {
        guard let gameViewModel = gameViewModel else {
            debugLog("⚠️ GameViewModel is not available for tutorial display")
            return
        }
        
        // チュートリアルを表示するためにゲーム状態を変更
        gameViewModel.gameState = .tutorial
        onDismiss()
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let content: Content
    
    init(icon: String, title: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 25)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color(.secondarySystemBackground))
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(), gameViewModel: nil) {
        // Dismiss action for preview
    }
}