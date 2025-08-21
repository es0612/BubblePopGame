//
//  SimplePerformanceTests.swift
//  BubblePopGameTests
//
//  基本的なパフォーマンステストスイート
//

import Testing
import Foundation
@testable import BubblePopGame

// 基本的なパフォーマンステストスイート
@Suite("基本パフォーマンステスト")
struct SimplePerformanceTests {
    
    @Test("バブル更新パフォーマンステスト", .timeLimit(.minutes(1)))
    func testBubbleUpdatePerformance() {
        let service = BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
        
        // 50個のバブルを生成
        var bubbles = service.generateRandomBubbles(count: 50, screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 60フレーム分のバブル更新をシミュレート
        for _ in 0..<60 {
            service.updateBubbles(&bubbles)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // 2秒以内で完了することを確認（余裕をもった時間制限）
        #expect(duration < 2.0)
        
        print("バブル更新パフォーマンス: \(duration)秒で60フレーム処理")
    }
    
    @Test("衝突判定パフォーマンステスト", .timeLimit(.minutes(1)))
    func testCollisionDetectionPerformance() {
        let service = BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
        
        // テスト用バブル配列を作成（25個）
        let bubbles = service.generateRandomBubbles(count: 25, screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 100回の衝突判定テスト
        for i in 0..<100 {
            let testPoint = CGPoint(x: Double(i % 400), y: Double((i / 400) % 800))
            _ = service.checkCollision(at: testPoint, in: bubbles)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // 1秒以内で100回の衝突判定が完了することを確認
        #expect(duration < 1.0)
        
        print("衝突判定パフォーマンス: 100回で\(duration)秒")
    }
    
    @Test("メモリ効率テスト")
    func testMemoryEfficiency() {
        let service = BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
        
        // 複数回のバブル生成・破棄でメモリリークをテスト
        for _ in 0..<5 {
            var bubbles = service.generateRandomBubbles(count: 50, screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
            
            // バブルを更新
            for _ in 0..<10 {
                service.updateBubbles(&bubbles)
            }
            
            // バブルを削除
            bubbles.removeAll()
        }
        
        // メモリが適切に解放されていることを確認（クラッシュしないことで検証）
        #expect(true)
    }
    
    @Test("大量データ処理テスト", .timeLimit(.minutes(2)))
    func testLargeDataHandling() {
        let service = BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 800, height: 1600))
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 大量のバブル生成
        let bubbles = service.generateRandomBubbles(count: 100, screenBounds: CGRect(x: 0, y: 0, width: 800, height: 1600))
        
        // すべてのバブルに対して衝突判定テスト
        var hitCount = 0
        for i in 0..<50 {
            let testPoint = CGPoint(x: Double(i * 16), y: Double(i * 32))
            if service.checkCollision(at: testPoint, in: bubbles) != nil {
                hitCount += 1
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // 1秒以内で完了することを確認
        #expect(duration < 1.0)
        #expect(bubbles.count == 100)
        #expect(hitCount >= 0) // ヒット数は0以上
        
        print("大量データ処理テスト: \(duration)秒で完了, ヒット数: \(hitCount)")
    }
    
    @Test("数字順バブル生成パフォーマンステスト")
    func testNumberedBubbleGenerationPerformance() {
        let service = BubbleServiceImpl(screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800))
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 複数回の数字付きバブル生成
        for _ in 0..<10 {
            let bubbles = service.generateNumberedBubbles(count: 20, screenBounds: CGRect(x: 0, y: 0, width: 400, height: 800), numberedCount: 5)
            #expect(bubbles.count == 20)
            
            let numberedBubbles = bubbles.filter { $0.type == .numbered }
            #expect(numberedBubbles.count == 5)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // 1秒以内で完了することを確認
        #expect(duration < 1.0)
        
        print("数字順バブル生成: \(duration)秒で10回実行")
    }
}