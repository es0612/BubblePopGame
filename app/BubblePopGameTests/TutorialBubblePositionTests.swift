//
//  TutorialBubblePositionTests.swift
//  BubblePopGameTests
//
//  Issue #24: チュートリアル練習バブルの配置位置
//

import Testing
import Foundation
import CoreGraphics
@testable import BubblePopGame

@MainActor
@Suite("チュートリアル練習バブル配置 (Issue #24)")
struct TutorialBubblePositionTests {

    @Test("練習バブルは渡された画面サイズの下部中央に配置される")
    func positionUsesProvidedSize() {
        let pos = TutorialView.tutorialBubblePosition(in: CGSize(width: 400, height: 800))
        #expect(pos.x == 200) // width * 0.5
        #expect(pos.y == 600) // height * 0.75
    }

    @Test("有効サイズなら原点(0,0)には置かれない（#24 リグレッション）")
    func positionIsNotOriginForValidSize() {
        let pos = TutorialView.tutorialBubblePosition(in: CGSize(width: 393, height: 852))
        #expect(pos.x > 0)
        #expect(pos.y > 0)
    }
}
