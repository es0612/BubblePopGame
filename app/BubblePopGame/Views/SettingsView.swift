//
//  SettingsView.swift
//  BubblePopGame
//
//  Created on 2025/07/22
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    let onDismiss: () -> Void
    
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
                                        Slider(value: $viewModel.bgmVolume, in: 0...1, step: 0.1)
                                        Text("100")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text("\(Int(viewModel.bgmVolume * 100))%")
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
                                        Slider(value: $viewModel.sfxVolume, in: 0...1, step: 0.1)
                                        Text("100")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text("\(Int(viewModel.sfxVolume * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
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
                        }
                    }
                    
                    // リセットボタン
                    Button(action: {
                        viewModel.resetToDefaults()
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
    SettingsView(viewModel: SettingsViewModel()) {
        // Dismiss action for preview
    }
}