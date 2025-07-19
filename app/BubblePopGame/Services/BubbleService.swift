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
    private let screenBounds: CGRect
    private var bubblePool: [Bubble] = []
    
    init(screenBounds: CGRect) {
        self.screenBounds = screenBounds
    }
    
    func createBubble(at position: CGPoint, type: BubbleType) -> Bubble {
        let radius = CGFloat.random(in: 30...60)
        let color = Color.random()
        
        return Bubble(
            position: position,
            velocity: CGVector(dx: Double.random(in: -50...50), dy: Double.random(in: -50...50)),
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
            // 位置更新
            bubbles[i].position.x += bubbles[i].velocity.dx / 60.0
            bubbles[i].position.y += bubbles[i].velocity.dy / 60.0
            
            // アニメーションフェーズ更新
            bubbles[i].animationPhase += 0.05
            
            // 画面境界での跳ね返り
            handleBoundaryCollision(&bubbles[i])
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
            
            let bubble = createBubble(at: position, type: .normal)
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