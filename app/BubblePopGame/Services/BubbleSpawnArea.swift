//
//  BubbleSpawnArea.swift
//  BubblePopGame
//
//  Issue #85: 泡の生成範囲の計算を 1 か所にまとめる。
//  ゲーム領域が狭いとき（高さ 270pt 未満・幅 120pt 未満）に
//  `CGFloat.random(in:)` の範囲が逆転して trap しないようにする。
//

import CoreGraphics

enum BubbleSpawnArea {
    /// 上部の HUD 領域の高さ
    static let hudHeight: CGFloat = 150
    /// 画面端からのマージン
    static let margin: CGFloat = 60

    /// 泡を生成してよい範囲。
    /// 十分な広さがあるときは従来どおり x: margin...(width - margin)、
    /// y: (hudHeight + margin)...(height - margin)。
    /// 足りない軸は、その軸の中央付近の 1 点に潰す（落ちないことを優先した暫定の振る舞い）。
    static func ranges(in screenBounds: CGRect) -> (x: ClosedRange<CGFloat>, y: ClosedRange<CGFloat>) {
        let x = axisRange(lower: margin, upper: screenBounds.width - margin, size: screenBounds.width)
        let y = axisRange(lower: hudHeight + margin, upper: screenBounds.height - margin, size: screenBounds.height)
        return (x, y)
    }

    /// 生成範囲の中からランダムな位置を返す。
    static func randomPosition(in screenBounds: CGRect) -> CGPoint {
        let (xRange, yRange) = ranges(in: screenBounds)
        return CGPoint(x: CGFloat.random(in: xRange), y: CGFloat.random(in: yRange))
    }

    private static func axisRange(lower: CGFloat, upper: CGFloat, size: CGFloat) -> ClosedRange<CGFloat> {
        if lower.isFinite, upper.isFinite, lower <= upper {
            return lower...upper
        }
        // 範囲が取れないときは 1 点に潰す。下限と上限の中間が画面内ならそこ、外なら画面の中央。
        let safeSize = size.isFinite ? max(size, 0) : 0
        let mid = (lower + upper) / 2
        let point = (mid.isFinite && mid >= 0 && mid <= safeSize) ? mid : safeSize / 2
        return point...point
    }
}
