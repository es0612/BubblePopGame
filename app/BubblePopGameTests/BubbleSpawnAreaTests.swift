//
//  BubbleSpawnAreaTests.swift
//  BubblePopGameTests
//
//  Issue #85: 狭い画面で泡の生成範囲が逆転して落ちないこと
//

import Testing
import Foundation
import CoreGraphics
@testable import BubblePopGame

@Suite("泡の生成範囲 (Issue #85)")
struct BubbleSpawnAreaTests {

    @Test("通常サイズでは従来どおり HUD とマージンを除いた範囲になる")
    func normalSizeKeepsOriginalRange() {
        let (x, y) = BubbleSpawnArea.ranges(in: CGRect(x: 0, y: 0, width: 400, height: 800))
        #expect(x == 60...340)   // margin...(width - margin)
        #expect(y == 210...740)  // (hud + margin)...(height - margin)
    }

    @Test("通常サイズで生成した位置は従来の範囲内に収まる")
    func normalSizePositionsStayInOriginalRange() {
        let bounds = CGRect(x: 0, y: 0, width: 393, height: 852)
        for _ in 0..<200 {
            let p = BubbleSpawnArea.randomPosition(in: bounds)
            #expect(p.x >= 60 && p.x <= 333)
            #expect(p.y >= 210 && p.y <= 792)
        }
    }

    @Test("高さ 200pt・幅 100pt でも落ちず、画面内に置かれる")
    func narrowBoundsDoNotTrap() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 200)
        for _ in 0..<50 {
            let p = BubbleSpawnArea.randomPosition(in: bounds)
            #expect(p.x >= 0 && p.x <= 100)
            #expect(p.y >= 0 && p.y <= 200)
        }
    }

    @Test("HUD より低い・ゼロ・負のサイズでも画面内（0 以上）の 1 点になる", arguments: [
        CGSize(width: 50, height: 100),
        CGSize(width: 0, height: 0),
        CGSize(width: -10, height: -10),
    ])
    func degenerateBoundsCollapseInside(size: CGSize) {
        let (x, y) = BubbleSpawnArea.ranges(in: CGRect(origin: .zero, size: size))
        #expect(x.lowerBound == x.upperBound)
        #expect(y.lowerBound == y.upperBound)
        #expect(x.lowerBound >= 0 && x.lowerBound <= max(size.width, 0))
        #expect(y.lowerBound >= 0 && y.lowerBound <= max(size.height, 0))
    }

    @Test("BubbleService の生成も狭い画面で落ちない")
    func bubbleServiceGenerationOnNarrowBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 200)
        let service = BubbleServiceImpl(screenBounds: bounds)
        let random = service.generateRandomBubbles(count: 5, screenBounds: bounds)
        let numbered = service.generateNumberedBubbles(count: 5, screenBounds: bounds, numberedCount: 3)
        let custom = service.generateNumberedBubblesWithCustomSet(count: 5, screenBounds: bounds, numberSet: [2, 4])
        #expect(random.count == 5)
        #expect(numbered.count == 5)
        #expect(custom.count == 5)
        for bubble in random + numbered + custom {
            #expect(bubble.position.x >= 0 && bubble.position.x <= 100)
            #expect(bubble.position.y >= 0 && bubble.position.y <= 200)
        }
    }
}
