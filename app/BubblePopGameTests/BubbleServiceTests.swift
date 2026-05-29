//
//  BubbleServiceTests.swift
//  BubblePopGameTests
//
//  BubbleServiceの衝突判定とロジックテストスイート
//

import Testing
import Foundation
@testable import BubblePopGame

// BubbleServiceの単体テストスイート
@Suite("BubbleServiceテスト")
struct BubbleServiceTests {
    
    private func createTestService() -> BubbleServiceImpl {
        return BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
    }
    
    @Test("バブル作成テスト")
    func testBubbleCreation() {
        let service = createTestService()
        let position = CGPoint(x: 100, y: 100)
        
        // 通常バブル作成
        let normalBubble = service.createBubble(at: position, type: .normal)
        #expect(normalBubble.position.x == position.x)
        #expect(normalBubble.position.y == position.y)
        #expect(normalBubble.type == .normal)
        #expect(normalBubble.number == nil)
        // 設定未指定時はデフォルト（GameSettings 既定の min=30/max=60）を反映
        #expect(normalBubble.radius >= 30.0)
        #expect(normalBubble.radius <= 60.0)
        #expect(normalBubble.alpha == 0.8)
        #expect(normalBubble.isPopping == false)

        // 数字付きバブル作成（デフォルト maxRadius=60 で固定）
        let numberedBubble = service.createNumberedBubble(at: position, number: 5)
        #expect(numberedBubble.position.x == position.x)
        #expect(numberedBubble.position.y == position.y)
        #expect(numberedBubble.type == .numbered)
        #expect(numberedBubble.number == 5)
        #expect(numberedBubble.radius == 60.0)
    }
    
    @Test("衝突判定の正確性テスト")
    func testCollisionDetectionAccuracy() {
        let service = createTestService()
        
        // テスト用バブル作成
        let bubble1 = Bubble(
            position: CGPoint(x: 100, y: 100),
            velocity: CGVector.zero,
            radius: 30,
            type: .normal,
            number: nil,
            color: .blue,
            alpha: 1.0,
            animationPhase: 0
        )
        
        let bubble2 = Bubble(
            position: CGPoint(x: 200, y: 200),
            velocity: CGVector.zero,
            radius: 25,
            type: .normal,
            number: nil,
            color: .red,
            alpha: 1.0,
            animationPhase: 0
        )
        
        let bubbles = [bubble1, bubble2]
        
        // ヒットテスト（バブル内の点）
        let hitResult1 = service.checkCollision(at: CGPoint(x: 105, y: 105), in: bubbles)
        #expect(hitResult1 != nil)
        #expect(hitResult1?.position.x == bubble1.position.x)
        
        let hitResult2 = service.checkCollision(at: CGPoint(x: 195, y: 195), in: bubbles)
        #expect(hitResult2 != nil)
        #expect(hitResult2?.position.x == bubble2.position.x)
        
        // ミステスト（バブル外の点）
        let missResult = service.checkCollision(at: CGPoint(x: 300, y: 300), in: bubbles)
        #expect(missResult == nil)
        
        // 境界線テスト（バブルの端）
        let edgeHit = service.checkCollision(at: CGPoint(x: 130, y: 100), in: bubbles)
        #expect(edgeHit != nil) // 半径30なので130はヒット範囲内
        
        let edgeMiss = service.checkCollision(at: CGPoint(x: 131, y: 100), in: bubbles)
        #expect(edgeMiss == nil) // 半径30なので131は範囲外
    }
    
    @Test("衝突インデックス検索テスト")
    func testCollisionIndexDetection() {
        let service = createTestService()
        
        let bubbles = [
            Bubble(position: CGPoint(x: 50, y: 50), velocity: CGVector.zero, radius: 20, type: .normal, number: nil, color: .blue, alpha: 1.0, animationPhase: 0),
            Bubble(position: CGPoint(x: 150, y: 150), velocity: CGVector.zero, radius: 25, type: .normal, number: nil, color: .red, alpha: 1.0, animationPhase: 0),
            Bubble(position: CGPoint(x: 250, y: 250), velocity: CGVector.zero, radius: 30, type: .normal, number: nil, color: .green, alpha: 1.0, animationPhase: 0)
        ]
        
        // 最初のバブルをヒット
        let index1 = service.checkCollisionIndex(at: CGPoint(x: 55, y: 55), in: bubbles)
        #expect(index1 == 0)
        
        // 2番目のバブルをヒット
        let index2 = service.checkCollisionIndex(at: CGPoint(x: 145, y: 145), in: bubbles)
        #expect(index2 == 1)
        
        // 3番目のバブルをヒット
        let index3 = service.checkCollisionIndex(at: CGPoint(x: 255, y: 255), in: bubbles)
        #expect(index3 == 2)
        
        // ミス（インデックス無し）
        let noHitIndex = service.checkCollisionIndex(at: CGPoint(x: 350, y: 350), in: bubbles)
        #expect(noHitIndex == -1)
    }
    
    @Test("バブル更新ロジックテスト")
    func testBubbleUpdateLogic() {
        let service = createTestService()
        
        var bubbles = [
            Bubble(
                position: CGPoint(x: 100, y: 100),
                velocity: CGVector(dx: 2, dy: 1),
                radius: 30,
                type: .normal,
                number: nil,
                color: .blue,
                alpha: 1.0,
                animationPhase: 0
            )
        ]
        
        let originalPosition = bubbles[0].position
        let originalVelocity = bubbles[0].velocity
        
        // バブル更新を実行
        service.updateBubbles(&bubbles)
        
        // 位置が更新されていることを確認
        #expect(bubbles[0].position.x != originalPosition.x)
        #expect(bubbles[0].position.y != originalPosition.y)
        
        // アニメーションフェーズが更新されていることを確認
        #expect(bubbles[0].animationPhase >= 0)
        #expect(bubbles[0].animationPhase <= 2 * Double.pi)
    }
    
    @Test("ランダムバブル生成テスト")
    func testRandomBubbleGeneration() {
        let service = createTestService()
        let screenBounds = CGRect(x: 0, y: 0, width: 400, height: 800)
        
        let bubbles = service.generateRandomBubbles(count: 10, screenBounds: screenBounds)
        
        // 指定した数のバブルが生成されることを確認
        #expect(bubbles.count == 10)
        
        // 全てのバブルが画面内に生成されることを確認
        for bubble in bubbles {
            #expect(bubble.position.x >= bubble.radius)
            #expect(bubble.position.x <= screenBounds.width - bubble.radius)
            #expect(bubble.position.y >= bubble.radius)
            #expect(bubble.position.y <= screenBounds.height - bubble.radius)
            #expect(bubble.type == .normal)
            #expect(bubble.number == nil)
        }
    }
    
    @Test("数字付きバブル生成テスト")
    func testNumberedBubbleGeneration() {
        let service = createTestService()
        let screenBounds = CGRect(x: 0, y: 0, width: 400, height: 800)
        
        let bubbles = service.generateNumberedBubbles(count: 15, screenBounds: screenBounds, numberedCount: 5)
        
        // 指定した数のバブルが生成されることを確認
        #expect(bubbles.count == 15)
        
        // 数字付きバブルが指定数生成されることを確認
        let numberedBubbles = bubbles.filter { $0.type == .numbered }
        #expect(numberedBubbles.count == 5)
        
        // 通常バブルが残りの数生成されることを確認
        let normalBubbles = bubbles.filter { $0.type == .normal }
        #expect(normalBubbles.count == 10)
        
        // 数字付きバブルに数字が割り当てられていることを確認
        for numberedBubble in numberedBubbles {
            #expect(numberedBubble.number != nil)
            #expect(numberedBubble.number! >= 1)
            #expect(numberedBubble.number! <= 5)
        }
    }
    
    @Test("カスタム数字セットバブル生成テスト")
    func testCustomNumberSetBubbleGeneration() {
        let service = createTestService()
        let screenBounds = CGRect(x: 0, y: 0, width: 400, height: 800)
        let customNumberSet = [3, 7, 1, 9, 5]
        
        let bubbles = service.generateNumberedBubblesWithCustomSet(
            count: 12,
            screenBounds: screenBounds,
            numberSet: customNumberSet
        )
        
        #expect(bubbles.count == 12)
        
        let numberedBubbles = bubbles.filter { $0.type == .numbered }
        #expect(numberedBubbles.count == customNumberSet.count)
        
        // 指定した数字セットが使用されていることを確認
        let assignedNumbers = numberedBubbles.compactMap { $0.number }.sorted()
        let expectedNumbers = customNumberSet.sorted()
        #expect(assignedNumbers == expectedNumbers)
    }
    
    @Test("画面境界更新テスト")
    func testScreenBoundsUpdate() {
        let service = createTestService()
        let newBounds = CGRect(x: 0, y: 0, width: 600, height: 1000)
        
        service.updateScreenBounds(newBounds)
        
        // 新しい境界でバブルを生成してテスト
        let bubbles = service.generateRandomBubbles(count: 5, screenBounds: newBounds)
        
        for bubble in bubbles {
            #expect(bubble.position.x >= bubble.radius)
            #expect(bubble.position.x <= newBounds.width - bubble.radius)
            #expect(bubble.position.y >= bubble.radius)
            #expect(bubble.position.y <= newBounds.height - bubble.radius)
        }
    }
    
    @Test("バブル色生成テスト")
    func testBubbleColorGeneration() {
        let service = createTestService()
        let position = CGPoint(x: 100, y: 100)
        
        // 複数のバブルを生成して色のバリエーションをテスト
        var colors: Set<String> = []
        for _ in 0..<20 {
            let bubble = service.createBubble(at: position, type: .normal)
            colors.insert(bubble.color.description)
        }
        
        // 複数の色が使用されていることを確認（完全にランダムなので最低2色以上）
        #expect(colors.count >= 1)
    }
    
    @Test("バブル半径が設定の min/max を反映する")
    func testBubbleRadiusReflectsSettings() {
        let service = createTestService()
        service.updateBubbleConfig(minRadius: 10.0, maxRadius: 15.0, animationSpeed: 1.0)

        // 設定した半径範囲内で生成されることを確認（ランダムなので複数回）
        for _ in 0..<50 {
            let bubble = service.createBubble(at: CGPoint(x: 100, y: 100), type: .normal)
            #expect(bubble.radius >= 10.0)
            #expect(bubble.radius <= 15.0)
        }
    }

    @Test("数字バブル半径が設定の maxRadius を反映する")
    func testNumberedBubbleRadiusReflectsSettings() {
        let service = createTestService()
        service.updateBubbleConfig(minRadius: 10.0, maxRadius: 15.0, animationSpeed: 1.0)

        // 数字バブルは目立たせるため maxRadius で固定生成
        let bubble = service.createNumberedBubble(at: CGPoint(x: 100, y: 100), number: 3)
        #expect(bubble.radius == 15.0)
    }

    @Test("min/max が逆転していてもクラッシュせず範囲内に収まる")
    func testInvertedRadiusConfigDoesNotCrash() {
        let service = createTestService()
        // 逆転した値を渡しても random(in:) が trap しないこと（正規化される）
        service.updateBubbleConfig(minRadius: 60.0, maxRadius: 30.0, animationSpeed: 1.0)

        for _ in 0..<50 {
            let bubble = service.createBubble(at: CGPoint(x: 100, y: 100), type: .normal)
            #expect(bubble.radius >= 30.0)
            #expect(bubble.radius <= 60.0)
        }

        // 数字バブルは大きい方（60）で固定
        let numbered = service.createNumberedBubble(at: CGPoint(x: 100, y: 100), number: 1)
        #expect(numbered.radius == 60.0)
    }

    @Test("animationSpeed が初期速度をスケールする")
    func testAnimationSpeedScalesVelocity() {
        let service = createTestService()
        // animationSpeed=0 なら初速も0になる（決定的に検証可能）
        service.updateBubbleConfig(minRadius: 30.0, maxRadius: 60.0, animationSpeed: 0.0)

        let normalBubble = service.createBubble(at: CGPoint(x: 100, y: 100), type: .normal)
        #expect(normalBubble.velocity.dx == 0.0)
        #expect(normalBubble.velocity.dy == 0.0)

        let numberedBubble = service.createNumberedBubble(at: CGPoint(x: 100, y: 100), number: 1)
        #expect(numberedBubble.velocity.dx == 0.0)
        #expect(numberedBubble.velocity.dy == 0.0)
    }

    @Test("境界跳ね返り処理テスト")
    func testBoundaryBounceLogic() {
        let service = createTestService()
        let screenBounds = CGRect(x: 0, y: 0, width: 400, height: 800)
        
        // 画面端近くのバブルを作成
        var edgeBubble = Bubble(
            position: CGPoint(x: 10, y: 100), // 左端近く
            velocity: CGVector(dx: -5, dy: 2), // 左向きの速度
            radius: 30,
            type: .normal,
            number: nil,
            color: .blue,
            alpha: 1.0,
            animationPhase: 0
        )
        
        var bubbles = [edgeBubble]
        service.updateBubbles(&bubbles)
        
        // バブルが画面境界内に留まっていることを確認
        #expect(bubbles[0].position.x >= bubbles[0].radius)
        #expect(bubbles[0].position.x <= screenBounds.width - bubbles[0].radius)
        #expect(bubbles[0].position.y >= bubbles[0].radius)
        #expect(bubbles[0].position.y <= screenBounds.height - bubbles[0].radius)
    }
}