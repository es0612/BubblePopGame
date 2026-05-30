//
//  DebugLaunchOptions.swift
//  BubblePopGame
//
//  Issue #8: デバッグビルド/UIテスト時に起動引数からテスト用 override を解釈する。
//
//  GameSettings は SwiftData で永続化されるため `xcrun simctl spawn ... defaults write`
//  トリックが効かない。代わりに起動引数で初回起動フローやゲーム設定を bypass し、
//  メニュー以降の画面検証や UI 自動テストを行えるようにする。
//
//  パース処理自体は純粋関数で副作用がないためビルド構成に依存しないが、
//  実際に override を「適用する」配線は呼び出し側で #if DEBUG ガードすること
//  （リリースビルドの挙動を変えないため）。
//
//  使用例:
//    xcrun simctl launch <SIM_ID> com.asapapalab.BubblePopGame \
//      --skip-tutorial --game-time=120 --game-mode=numbered
//

import Foundation

struct DebugLaunchOptions {
    /// `--skip-tutorial`: 初回起動でもチュートリアルをスキップしてメニューへ
    let skipTutorial: Bool
    /// `--game-time=<秒>`: ゲーム制限時間の override（パース不能なら nil）
    let gameTime: Double?
    /// `--game-mode=<モード>`: ゲームモードの override（GameMode の rawValue 文字列）
    let gameMode: String?
    /// `--screenshot=<画面>`: App Store スクショ撮影用に起動直後の表示画面へ直行
    /// （`menu`/`game`/`game-numbered`/`result`/`settings`/`highscore`）。DEBUG 専用。
    let screenshot: String?

    /// いずれかの override が指定されているか
    var hasOverrides: Bool {
        skipTutorial || gameTime != nil || gameMode != nil || screenshot != nil
    }

    init(arguments: [String]) {
        self.skipTutorial = arguments.contains("--skip-tutorial")
        self.gameTime = Self.value(for: "--game-time=", in: arguments).flatMap(Double.init)
        self.gameMode = Self.value(for: "--game-mode=", in: arguments)
        self.screenshot = Self.value(for: "--screenshot=", in: arguments)
    }

    /// `--key=value` 形式の引数から value 部分を取り出す（空文字列は nil 扱い）
    private static func value(for prefix: String, in arguments: [String]) -> String? {
        guard let arg = arguments.first(where: { $0.hasPrefix(prefix) }) else { return nil }
        let value = String(arg.dropFirst(prefix.count))
        return value.isEmpty ? nil : value
    }
}
