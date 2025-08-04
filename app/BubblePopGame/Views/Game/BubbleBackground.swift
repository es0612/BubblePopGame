//
//  BubbleBackground.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct BubbleBackground: View {
    let bubble: Bubble
    
    var body: some View {
        ZStack {
            // メインのシャボン玉（虹色の縁）
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color.red.opacity(0.7),
                            Color.orange.opacity(0.7),
                            Color.yellow.opacity(0.7),
                            Color.green.opacity(0.7),
                            Color.blue.opacity(0.7),
                            Color.purple.opacity(0.7),
                            Color.red.opacity(0.7)
                        ],
                        center: .center,
                        angle: .degrees(bubble.animationPhase * 20)
                    ),
                    lineWidth: 2
                )
                .background(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.clear,
                                    bubble.color.accessible().opacity(0.15),
                                    bubble.color.accessible().opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 0,
                                endRadius: bubble.radius * 1.2
                            )
                        )
                )
                .frame(width: bubble.radius * 2, height: bubble.radius * 2)
            
            // ハイライト効果（強化版）
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.25, y: 0.25),
                        startRadius: 0,
                        endRadius: bubble.radius * 0.5
                    )
                )
                .frame(width: bubble.radius * 0.8, height: bubble.radius * 0.8)
            
            // 反射光効果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.cyan.opacity(0.2),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.75, y: 0.75),
                        startRadius: 0,
                        endRadius: bubble.radius * 0.3
                    )
                )
                .frame(width: bubble.radius * 0.6, height: bubble.radius * 0.6)
        }
    }
}