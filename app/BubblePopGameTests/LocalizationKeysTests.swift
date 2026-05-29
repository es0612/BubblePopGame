//
//  LocalizationKeysTests.swift
//  BubblePopGameTests
//
//  Issue #5: ローカライズキーの存在とロケール間パリティを保証する回帰テスト。
//
//  accessibility 系の文字列（VoiceOver 専用）は ja/en スクリーンショットに映らないため、
//  キー欠落（= 英語ユーザーに生キー文字列が表示される古典的バグ）が目視検証をすり抜ける。
//  このテストで「全ロケールに必要キーが存在し、ja/en/Base のキー集合が一致する」ことを
//  ビルド時に大声で検出する。
//

import Testing
import Foundation
@testable import BubblePopGame

@Suite("ローカライズキーの存在とパリティ")
struct LocalizationKeysTests {

    /// アプリバンドルを含む型から bundle を解決（テストランナーの Bundle.main ではなくアプリ本体）
    private var appBundle: Bundle { Bundle(for: GameSettings.self) }

    private func strings(for localization: String) -> [String: String]? {
        guard let path = appBundle.path(
            forResource: "Localizable",
            ofType: "strings",
            inDirectory: nil,
            forLocalization: localization
        ) else { return nil }
        return NSDictionary(contentsOfFile: path) as? [String: String]
    }

    /// Issue #5 で新規追加したキー
    private let newKeys = [
        "seconds_decimal_format",
        "accessibility_bubble_numbered",
        "accessibility_bubble_normal",
        "accessibility_bubble_hint",
        "accessibility_pause_resume_hint",
        "accessibility_pause_quit_hint",
        "pause_confirm_exit_title",
        "pause_confirm_exit_message",
        "accessibility_tutorial_skip_hint",
        "loading_settings",
        "loading_initializing",
    ]

    /// Issue #5 のコード側で再利用している既存キー（将来の削除でビューが壊れるのを防ぐ）
    private let reusedKeys = [
        "highscore_numbered_mode",
        "highscore_normal_mode",
        "game_bubbles_popped",
        "gameover_accuracy",
        "percentage_format",
        "highscore_time_limit",
        "seconds_format",
        "gameover_play_time",
        "settings_time_limit",
    ]

    private let localizations = ["ja", "en", "Base"]

    @Test("全ロケールに新規キーと再利用キーが存在する")
    func requiredKeysExistInAllLocalizations() throws {
        for loc in localizations {
            let dict = try #require(strings(for: loc), "\(loc).lproj/Localizable.strings が読み込めない")
            for key in newKeys + reusedKeys {
                #expect(dict[key] != nil, "キー '\(key)' が \(loc) に存在しない")
                // 値が空でないこと（空文字は実質欠落）
                #expect(dict[key]?.isEmpty == false, "キー '\(key)' の \(loc) 値が空")
            }
        }
    }

    @Test("ja / en / Base のキー集合が一致する（パリティ）")
    func localizationsHaveIdenticalKeySets() throws {
        let ja = Set(try #require(strings(for: "ja")).keys)
        let en = Set(try #require(strings(for: "en")).keys)
        let base = Set(try #require(strings(for: "Base")).keys)

        #expect(ja == en, "ja と en でキー集合が不一致: ja-only=\(ja.subtracting(en)), en-only=\(en.subtracting(ja))")
        #expect(en == base, "en と Base でキー集合が不一致: en-only=\(en.subtracting(base)), Base-only=\(base.subtracting(en))")
    }
}
