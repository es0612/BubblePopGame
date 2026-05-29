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
    func createNumberedBubble(at position: CGPoint, number: Int) -> Bubble
    func updateBubbles(_ bubbles: inout [Bubble])
    func checkCollision(at point: CGPoint, in bubbles: [Bubble]) -> Bubble?
    func checkCollisionIndex(at point: CGPoint, in bubbles: [Bubble]) -> Int
    func generateRandomBubbles(count: Int, screenBounds: CGRect) -> [Bubble]
    func generateNumberedBubbles(count: Int, screenBounds: CGRect, numberedCount: Int) -> [Bubble]
    func generateNumberedBubblesWithCustomSet(count: Int, screenBounds: CGRect, numberSet: [Int]) -> [Bubble]
    func updateScreenBounds(_ bounds: CGRect)
    func updateBubbleConfig(minRadius: Double, maxRadius: Double, animationSpeed: Double)
}

class BubbleServiceImpl: BubbleService {
    private var screenBounds: CGRect
    private var bubblePool: [Bubble] = []

    // GameSettings から反映されるバブル生成パラメータ（Issue #17）。
    // デフォルトは GameSettings のデフォルト値（30/60/1.0）に揃える。
    private var minRadius: CGFloat = 30.0
    private var maxRadius: CGFloat = 60.0
    private var animationSpeed: CGFloat = 1.0

    init(screenBounds: CGRect) {
        self.screenBounds = screenBounds
    }

    func updateScreenBounds(_ bounds: CGRect) {
        screenBounds = bounds
    }

    func updateBubbleConfig(minRadius: Double, maxRadius: Double, animationSpeed: Double) {
        self.minRadius = CGFloat(minRadius)
        self.maxRadius = CGFloat(maxRadius)
        self.animationSpeed = CGFloat(animationSpeed)
    }
    
    func createBubble(at position: CGPoint, type: BubbleType) -> Bubble {
        // 半径は設定値（minRadius/maxRadius）を反映。数字タイプは目立たせるため maxRadius 固定。
        let radius: CGFloat = type == .numbered ?
            maxRadius :
            CGFloat.random(in: minRadius...maxRadius)

        // 数字タイプは赤や黄色で目立つように
        let color: Color = type == .numbered ?
            [.red, .yellow, .orange].randomElement() ?? .red :
            Color.random()

        // 初期速度もタイプによって少し変える（animationSpeed でスケール）
        let velocityRange: Range<Double> = type == .numbered ?
            -30.0..<30.0 :
            -50.0..<50.0

        return Bubble(
            position: position,
            velocity: CGVector(
                dx: Double.random(in: velocityRange) * Double(animationSpeed),
                dy: Double.random(in: velocityRange) * Double(animationSpeed)
            ),
            radius: radius,
            type: type,
            number: type == .numbered ? Int.random(in: 1...10) : nil,
            color: color,
            alpha: 0.8,
            animationPhase: 0.0
        )
    }
    
    func createNumberedBubble(at position: CGPoint, number: Int) -> Bubble {
        let radius: CGFloat = maxRadius // 数字バブルは目立たせるため maxRadius で固定
        let color: Color = .yellow // 数字バブルは黄色で統一

        return Bubble(
            position: position,
            velocity: CGVector(
                dx: Double.random(in: -20.0..<20.0) * Double(animationSpeed),
                dy: Double.random(in: -20.0..<20.0) * Double(animationSpeed)
            ),
            radius: radius,
            type: .numbered,
            number: number,
            color: color,
            alpha: 0.9,
            animationPhase: 0.0
        )
    }
    
    func updateBubbles(_ bubbles: inout [Bubble]) {
        for i in bubbles.indices {
            // 破裂アニメーション処理
            if bubbles[i].isPopping {
                if let lastTouchTime = bubbles[i].lastTouchTime {
                    let elapsed = Date().timeIntervalSince(lastTouchTime)
                    bubbles[i].popAnimationProgress = min(elapsed / 0.3, 1.0)
                }
                continue
            }
            
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
            guard !bubble.isPopping else { return false }
            let distance = sqrt(pow(point.x - bubble.position.x, 2) + pow(point.y - bubble.position.y, 2))
            return distance <= bubble.radius
        }
    }
    
    func checkCollisionIndex(at point: CGPoint, in bubbles: [Bubble]) -> Int {
        return bubbles.firstIndex { bubble in
            guard !bubble.isPopping else { return false }
            let distance = sqrt(pow(point.x - bubble.position.x, 2) + pow(point.y - bubble.position.y, 2))
            return distance <= bubble.radius
        } ?? -1
    }
    
    func generateRandomBubbles(count: Int, screenBounds: CGRect) -> [Bubble] {
        var bubbles: [Bubble] = []
        
        // HUD領域（上部150px）とマージン（60px）を除外した生成領域
        let hudHeight: CGFloat = 150
        let margin: CGFloat = 60
        
        for _ in 0..<count {
            let x = CGFloat.random(in: margin...(screenBounds.width - margin))
            let y = CGFloat.random(in: (hudHeight + margin)...(screenBounds.height - margin))
            let position = CGPoint(x: x, y: y)
            
            // 通常モードでは通常タイプのみ生成
            let bubble = createBubble(at: position, type: .normal)
            bubbles.append(bubble)
        }
        
        return bubbles
    }
    
    func generateNumberedBubbles(count: Int, screenBounds: CGRect, numberedCount: Int) -> [Bubble] {
        var bubbles: [Bubble] = []
        
        // HUD領域（上部150px）とマージン（60px）を除外した生成領域
        let hudHeight: CGFloat = 150
        let margin: CGFloat = 60
        
        // 指定された数の数字付きバブルを生成（1からnumberedCountまで）
        for number in 1...numberedCount {
            let x = CGFloat.random(in: margin...(screenBounds.width - margin))
            let y = CGFloat.random(in: (hudHeight + margin)...(screenBounds.height - margin))
            let position = CGPoint(x: x, y: y)
            
            let bubble = createNumberedBubble(at: position, number: number)
            bubbles.append(bubble)
        }
        
        // 残りは通常のバブル
        for _ in numberedCount..<count {
            let x = CGFloat.random(in: margin...(screenBounds.width - margin))
            let y = CGFloat.random(in: (hudHeight + margin)...(screenBounds.height - margin))
            let position = CGPoint(x: x, y: y)
            
            let bubble = createBubble(at: position, type: .normal)
            bubbles.append(bubble)
        }
        
        return bubbles
    }
    
    func generateNumberedBubblesWithCustomSet(count: Int, screenBounds: CGRect, numberSet: [Int]) -> [Bubble] {
        var bubbles: [Bubble] = []
        
        // HUD領域（上部150px）とマージン（60px）を除外した生成領域
        let hudHeight: CGFloat = 150
        let margin: CGFloat = 60
        
        // カスタム数字セットから数字付きバブルを生成
        for number in numberSet {
            let x = CGFloat.random(in: margin...(screenBounds.width - margin))
            let y = CGFloat.random(in: (hudHeight + margin)...(screenBounds.height - margin))
            let position = CGPoint(x: x, y: y)
            
            let bubble = createNumberedBubble(at: position, number: number)
            bubbles.append(bubble)
        }
        
        // 残りは通常のバブル
        let remainingCount = max(0, count - numberSet.count)
        for _ in 0..<remainingCount {
            let x = CGFloat.random(in: margin...(screenBounds.width - margin))
            let y = CGFloat.random(in: (hudHeight + margin)...(screenBounds.height - margin))
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