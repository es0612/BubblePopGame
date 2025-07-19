//
//  BubbleService.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftUI

protocol BubbleService {
    func createBubble(at position: CGPoint, type: BubbleType) -> Bubble
    func updateBubbles(_ bubbles: inout [Bubble])
    func checkCollision(at point: CGPoint, in bubbles: [Bubble]) -> Bubble?
    func generateRandomBubbles(count: Int, screenBounds: CGRect) -> [Bubble]
}

class BubbleServiceImpl: BubbleService {
    private var screenBounds: CGRect
    private var bubblePool: [Bubble] = []
    
    init(screenBounds: CGRect) {
        self.screenBounds = screenBounds
    }
    
    func updateScreenBounds(_ bounds: CGRect) {
        screenBounds = bounds
    }
    
    func createBubble(at position: CGPoint, type: BubbleType) -> Bubble {
        // 数字タイプは少し大きめに、通常タイプは少し小さめに
        let radius: CGFloat = type == .numbered ? 
            CGFloat.random(in: 40...70) : 
            CGFloat.random(in: 25...50)
        
        // 数字タイプは赤や黄色で目立つように
        let color: Color = type == .numbered ? 
            [.red, .yellow, .orange].randomElement() ?? .red :
            Color.random()
        
        // 初期速度もタイプによって少し変える
        let velocityRange: Range<Double> = type == .numbered ? 
            -30.0..<30.0 : 
            -50.0..<50.0
        
        return Bubble(
            position: position,
            velocity: CGVector(
                dx: Double.random(in: velocityRange), 
                dy: Double.random(in: velocityRange)
            ),
            radius: radius,
            type: type,
            number: type == .numbered ? Int.random(in: 1...10) : nil,
            color: color,
            alpha: 0.8,
            animationPhase: 0.0
        )
    }
    
    func updateBubbles(_ bubbles: inout [Bubble]) {
        for i in bubbles.indices {
            // 位置更新（60FPS想定）
            bubbles[i].position.x += bubbles[i].velocity.dx / 60.0
            bubbles[i].position.y += bubbles[i].velocity.dy / 60.0
            
            // アニメーションフェーズ更新（浮遊アニメーション用）
            bubbles[i].animationPhase += 0.05
            
            // タイプ別のアニメーション効果
            if bubbles[i].type == .numbered {
                // 数字タイプはより目立つ上下動とスケール変動
                let floatOffset = sin(bubbles[i].animationPhase * 1.5) * 3.0
                bubbles[i].position.y += floatOffset / 60.0
                
                // 数字タイプはパルスエフェクト
                bubbles[i].alpha = 0.8 + sin(bubbles[i].animationPhase * 2.0) * 0.2
            } else {
                // 通常タイプは緩やかな浮遊
                let floatOffset = sin(bubbles[i].animationPhase) * 2.0
                bubbles[i].position.y += floatOffset / 60.0
                
                // 通常タイプはゆるやかなアルファ変化
                bubbles[i].alpha = 0.7 + sin(bubbles[i].animationPhase * 0.5) * 0.2
            }
            
            // 画面境界での跳ね返り
            handleBoundaryCollision(&bubbles[i])
            
            // 速度の減衰（空気抵抗をシミュレート）
            bubbles[i].velocity.dx *= 0.998
            bubbles[i].velocity.dy *= 0.998
        }
    }
    
    private func handleBoundaryCollision(_ bubble: inout Bubble) {
        let minX = bubble.radius
        let maxX = screenBounds.width - bubble.radius
        let minY = bubble.radius
        let maxY = screenBounds.height - bubble.radius
        
        if bubble.position.x <= minX || bubble.position.x >= maxX {
            bubble.velocity.dx *= -0.8
            bubble.position.x = max(minX, min(maxX, bubble.position.x))
        }
        
        if bubble.position.y <= minY || bubble.position.y >= maxY {
            bubble.velocity.dy *= -0.8
            bubble.position.y = max(minY, min(maxY, bubble.position.y))
        }
    }
    
    func checkCollision(at point: CGPoint, in bubbles: [Bubble]) -> Bubble? {
        return bubbles.first { bubble in
            let distance = sqrt(pow(point.x - bubble.position.x, 2) + pow(point.y - bubble.position.y, 2))
            return distance <= bubble.radius
        }
    }
    
    func generateRandomBubbles(count: Int, screenBounds: CGRect) -> [Bubble] {
        var bubbles: [Bubble] = []
        
        for _ in 0..<count {
            let x = CGFloat.random(in: 60...(screenBounds.width - 60))
            let y = CGFloat.random(in: 60...(screenBounds.height - 60))
            let position = CGPoint(x: x, y: y)
            
            // 10%の確率で数字タイプ、90%で通常タイプ
            let bubbleType: BubbleType = Double.random(in: 0...1) < 0.1 ? .numbered : .normal
            let bubble = createBubble(at: position, type: bubbleType)
            bubbles.append(bubble)
        }
        
        return bubbles
    }
}

extension Color {
    static func random() -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .yellow, .pink, .cyan]
        return colors.randomElement() ?? .blue
    }
}