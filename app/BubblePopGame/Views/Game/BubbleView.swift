//
//  BubbleView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct BubbleView: View {
    let bubble: Bubble
    
    var body: some View {
        ZStack {
            // アニメーション付きバブル背景
            BubbleBackground(bubble: bubble)
                .rotation3DEffect(
                    .degrees(bubble.animationPhase * 5),
                    axis: (x: 0, y: 0, z: 1)
                )
                .scaleEffect(1.0 + sin(bubble.animationPhase * .pi * 0.5) * 0.05)
                .offset(
                    x: bubble.type == .numbered ? 0 : sin(bubble.animationPhase * .pi * 0.3) * 3,
                    y: bubble.type == .numbered ? 0 : cos(bubble.animationPhase * .pi * 0.25) * 2
                )
            
            // 安定した数字表示（回転やオフセットの影響を受けない）
            if bubble.type == .numbered, let number = bubble.number {
                Text("\(number)")
                    .font(.system(size: bubble.radius * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1, x: 1, y: 1)
            }
        }
        .position(bubble.position)
        .scaleEffect(bubble.isPopping ? (1.2 - bubble.popAnimationProgress * 1.2) : 1)
        .opacity(bubble.isPopping ? (1.0 - bubble.popAnimationProgress * bubble.popAnimationProgress) : bubble.alpha)
        .blur(radius: bubble.isPopping ? bubble.popAnimationProgress * 3 : 0)
        .animation(.easeOut(duration: 0.3), value: bubble.isPopping)
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: bubble.animationPhase)
        .accessibilityElement()
        .accessibilityLabel(bubble.type == .numbered
            ? String(format: NSLocalizedString("accessibility_bubble_numbered", comment: "Numbered bubble accessibility label"), bubble.number ?? 0)
            : NSLocalizedString("accessibility_bubble_normal", comment: "Bubble accessibility label"))
        .accessibilityHint(NSLocalizedString("accessibility_bubble_hint", comment: "Bubble tap hint"))
        .accessibilityAddTraits(.isButton)
    }
}