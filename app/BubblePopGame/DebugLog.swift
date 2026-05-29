//
//  DebugLog.swift
//  BubblePopGame
//
//  デバッグ用ログ出力。`print` の代替として使用する。
//  リリースビルドでは呼び出しが no-op となり、メッセージの評価も行われない（@autoclosure）。
//  これにより本番ビルドにデバッグ出力が残らない（Issue #19）。
//

import Foundation

/// DEBUG ビルドでのみコンソールへ出力するログ関数。
/// - Note: リリースビルドでは `#if DEBUG` により本体が消え、`message` クロージャも評価されない。
func debugLog(
    _ message: @autoclosure () -> String,
    file: String = #fileID,
    line: Int = #line
) {
    #if DEBUG
    Swift.print("[\(file):\(line)] \(message())")
    #endif
}
