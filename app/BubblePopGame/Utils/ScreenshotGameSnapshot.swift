//
//  ScreenshotGameSnapshot.swift
//  BubblePopGame
//
//  Issue #78: App Store スクショ撮影用の「プレイ途中の状態」（DEBUG 専用）。
//  `--screenshot=game` / `--screenshot=game-numbered` で起動したとき、
//  GameViewModel.startGame() の最後に適用し、スコア 0 の開始直後ではなく遊んでいる途中に見せる。
//  値は実プレイで到達できる範囲にする（result の既存サンプルと同じく 1 個あたり約 13 点）。
//

#if DEBUG
struct ScreenshotGameSnapshot: Equatable {
    let score: Int
    let bubblesPopped: Int
    let currentStreak: Int
    let bestStreak: Int
    let totalTaps: Int
    let successfulTaps: Int
    let timeRemaining: Double

    /// ノーマルモード（1 枚目「タップでぱちん！」）
    static let normal = ScreenshotGameSnapshot(
        score: 520, bubblesPopped: 40, currentStreak: 9, bestStreak: 12,
        totalTaps: 43, successfulTaps: 40, timeRemaining: 19
    )

    /// 数字モード（2 枚目）
    static let numbered = ScreenshotGameSnapshot(
        score: 380, bubblesPopped: 29, currentStreak: 7, bestStreak: 7,
        totalTaps: 31, successfulTaps: 29, timeRemaining: 21
    )
}
#endif
