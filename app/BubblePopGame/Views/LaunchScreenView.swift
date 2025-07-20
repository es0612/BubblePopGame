//
//  LaunchScreenView.swift
//  BubblePopGame
//
//  Created on 2025/07/20
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showMainView = false
    
    var body: some View {
        if showMainView {
            ContentView()
        } else {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: [.blue.opacity(0.8), .cyan.opacity(0.6), .blue.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // アプリアイコン（シャボン玉風）
                    ZStack {
                        // 外側のシャボン玉
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.blue.opacity(0.8),
                                        Color.blue
                                    ],
                                    center: UnitPoint(x: 0.3, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                        
                        // ハイライト効果
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    center: UnitPoint(x: 0.2, y: 0.2),
                                    startRadius: 0,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 50, height: 50)
                            .offset(x: -15, y: -15)
                    }
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // アプリ名
                    VStack(spacing: 8) {
                        Text("シャボン玉消しゲーム")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Bubble Pop Game")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 1.5).delay(0.5), value: isAnimating)
                    
                    // 読み込みインジケーター
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 1.0).delay(1.0), value: isAnimating)
                }
            }
            .onAppear {
                isAnimating = true
                
                // 3秒後にメインビューに遷移
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showMainView = true
                    }
                }
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}