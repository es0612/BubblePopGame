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
                    SettingsSection(title: "ゲーム設定") {
                        VStack(spacing: 15) {
                            SettingsRow(
                                icon: "gamecontroller.fill",
                                title: "ゲームモード",
                                iconColor: .purple
                            ) {
                                Picker("ゲームモード", selection: $viewModel.gameSettings.gameMode) {
                                    Text("通常モード").tag("normal")
                                    Text("数字順モード").tag("numbered")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            SettingsRow(
                                icon: "timer",
                                title: "制限時間",
                                iconColor: .red
                            ) {
                                HStack {
                                    Stepper("\(Int(viewModel.gameSettings.gameTime))秒", 
                                           value: $viewModel.gameSettings.gameTime, 
                                           in: 30...180, 
                                           step: 15)
                                }
                            }
                            
                            SettingsRow(
                                icon: "bubble.middle.bottom.fill",
                                title: "シャボン玉の数",
                                iconColor: .blue
                            ) {
                                HStack {
                                    Stepper("\(viewModel.gameSettings.bubbleCount)個", 
                                           value: $viewModel.gameSettings.bubbleCount, 
                                           in: 10...50, 
                                           step: 5)
                                }
                            }
                        }
                    }
                    
                    // 音響設定セクション
                    SettingsSection(title: "音響設定") {
                        VStack(spacing: 15) {
                            SettingsRow(
                                icon: "speaker.wave.3.fill",
                                title: "効果音",
                                iconColor: .orange
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { viewModel.gameSettings.soundEnabled },
                                    set: { _ in viewModel.toggleSound() }
                                ))
                            }
                            
                            SettingsRow(
                                icon: "music.note",
                                title: "BGM",
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
                                    title: "BGM選択",
                                    iconColor: .green
                                ) {
                                    Picker("BGMトラック", selection: Binding(
                                        get: { viewModel.gameSettings.bgmTrack },
                                        set: { viewModel.setBGMTrack($0) }
                                    )) {
                                        Text("トラック1").tag("track1")
                                        Text("トラック2").tag("track2")  
                                        Text("トラック3").tag("track3")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                            }
                            
                            SettingsRow(
                                icon: "music.quarternote.3",
                                title: "BGM音量",
                                iconColor: .green
                            ) {
                                VStack(spacing: 5) {
                                    HStack {
                                        Text("0")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Slider(value: $viewModel.gameSettings.bgmVolume, in: 0...1, step: 0.1)
                                            .onChange(of: viewModel.gameSettings.bgmVolume) { _, _ in
                                                viewModel.saveSettings()
                                            }
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
                                title: "効果音音量",
                                iconColor: .orange
                            ) {
                                VStack(spacing: 5) {
                                    HStack {
                                        Text("0")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Slider(value: $viewModel.gameSettings.sfxVolume, in: 0...1, step: 0.1)
                                            .onChange(of: viewModel.gameSettings.sfxVolume) { _, _ in
                                                viewModel.saveSettings()
                                            }
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
                        SettingsSection(title: "数字モード設定") {
                            VStack(spacing: 15) {
                                SettingsRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "プログレッシブ難易度",
                                    iconColor: .orange
                                ) {
                                    Toggle("", isOn: $viewModel.gameSettings.numberedModeProgressive)
                                }
                                
                                if viewModel.gameSettings.numberedModeProgressive {
                                    SettingsRow(
                                        icon: "timer.square",
                                        title: "レベル進行間隔",
                                        iconColor: .orange
                                    ) {
                                        VStack(spacing: 5) {
                                            HStack {
                                                Text("\(Int(viewModel.gameSettings.numberedModeLevelInterval))秒")
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
                                        title: "最大レベル",
                                        iconColor: .orange
                                    ) {
                                        HStack {
                                            Stepper(
                                                "Lv.\(viewModel.gameSettings.numberedModeMaxLevel)",
                                                value: $viewModel.gameSettings.numberedModeMaxLevel,
                                                in: 3...10
                                            )
                                        }
                                    }
                                }
                                
                                SettingsRow(
                                    icon: "123.rectangle.fill",
                                    title: "数字範囲",
                                    iconColor: .blue
                                ) {
                                    VStack(spacing: 5) {
                                        HStack {
                                            Text("1〜\(viewModel.gameSettings.numberedModeMaxRange)")
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
                                    title: "スピードボーナス",
                                    iconColor: .cyan
                                ) {
                                    Toggle("", isOn: $viewModel.gameSettings.speedBonusEnabled)
                                }
                                
                                if viewModel.gameSettings.speedBonusEnabled {
                                    SettingsRow(
                                        icon: "multiply.circle",
                                        title: "スピードボーナス倍率",
                                        iconColor: .cyan
                                    ) {
                                        VStack(spacing: 5) {
                                            HStack {
                                                Text("×\(String(format: "%.1f", viewModel.gameSettings.speedBonusMultiplier))")
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
                                    title: "パーフェクトチェイン",
                                    iconColor: .green
                                ) {
                                    Toggle("", isOn: $viewModel.gameSettings.perfectChainEnabled)
                                }
                                
                                SettingsRow(
                                    icon: "sparkles",
                                    title: "特殊ルール",
                                    iconColor: .purple
                                ) {
                                    Picker("特殊ルール", selection: $viewModel.gameSettings.numberedModeSpecialRule) {
                                        Text("通常").tag("normal")
                                        Text("逆順").tag("reverse")
                                        Text("2倍数").tag("double")
                                        Text("ランダム").tag("random")
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                            }
                        }
                    }
                    
                    // システム設定セクション
                    SettingsSection(title: "システム設定") {
                        VStack(spacing: 15) {
                            SettingsRow(
                                icon: "iphone.radiowaves.left.and.right",
                                title: "バイブレーション",
                                iconColor: .purple
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { viewModel.gameSettings.vibrationEnabled },
                                    set: { _ in viewModel.toggleVibration() }
                                ))
                            }
                            
                            SettingsRow(
                                icon: "questionmark.circle",
                                title: "チュートリアルを再表示",
                                iconColor: .blue
                            ) {
                                Button("表示") {
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
                            Text("設定をリセット")
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
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        viewModel.saveSettings()
                        onDismiss()
                    }
                }
            }
        }
        .alert("設定リセット確認", isPresented: $showingResetConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("リセット", role: .destructive) {
                viewModel.resetToDefaults()
            }
        } message: {
            Text("すべての設定をデフォルト値に戻します。この操作は取り消せません。")
        }
    }
    
    private func showTutorial() {
        guard let gameViewModel = gameViewModel else {
            print("⚠️ GameViewModel is not available for tutorial display")
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