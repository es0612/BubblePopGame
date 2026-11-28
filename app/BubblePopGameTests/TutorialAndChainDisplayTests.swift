//
//  TutorialAndChainDisplayTests.swift
//  BubblePopGameTests
//
//  #69: 表示と実際の値の食い違い
//  - チュートリアルが「制限時間: 60秒」と案内する（実際の初期値は 30 秒で、設定で 30〜180 秒）
//  - 数字モードのパーフェクトチェーンの倍率を `perfectChain + 1` で表示している
//    （実際の倍率は 1 + chain × perfectChainMultiplier。チェーン 1 で「×2.0」と出て、実際は ×1.15）
//

import Testing
import Foundation
@testable import BubblePopGame

@Suite("チュートリアルの秒数とチェーン倍率の表示 (#69)")
struct TutorialAndChainDisplayTests {

    private var appBundle: Bundle { Bundle(for: GameSettings.self) }
    private let localizations = ["ja", "en", "Base"]

    private func strings(for localization: String) -> [String: String] {
        guard let path = appBundle.path(
            forResource: "Localizable",
            ofType: "strings",
            inDirectory: nil,
            forLocalization: localization
        ) else { return [:] }
        return (NSDictionary(contentsOfFile: path) as? [String: String]) ?? [:]
    }

    @Test("チュートリアルの制限時間は秒数を埋め込む書式で、固定の秒数のキーは残っていない")
    func tutorialTimeLimitIsFormat() {
        for loc in localizations {
            let table = strings(for: loc)
            #expect(table["tutorial_time_limit_format"]?.contains("%d") == true, "\(loc)")
            #expect(table["tutorial_time_limit"] == nil, "\(loc)")
        }
    }

    @Test("チェーン倍率の書式は小数 2 桁（×1.15 を丸めずに出す）")
    func chainMultiplierFormatHasTwoDecimals() {
        for loc in localizations {
            #expect(strings(for: loc)["chain_multiplier_format"]?.contains("%.2f") == true, "\(loc)")
        }
    }
}

@MainActor
@Suite("チェーン倍率とチュートリアルの文言 (#69)")
struct ChainMultiplierValueTests {

    static func makeViewModel(chainEnabled: Bool) throws -> GameViewModel {
        let vm = try PopRefillTests.makeViewModel(mode: "numbered")
        vm.gameSettings.perfectChainEnabled = chainEnabled
        vm.gameSettings.perfectChainMultiplier = 0.15
        return vm
    }

    @Test("チェーン 1 の倍率は 1.15（表示とスコア計算で同じ値を使う）")
    func chainOneIsOnePointOneFive() throws {
        let vm = try Self.makeViewModel(chainEnabled: true)
        vm.perfectChain = 1
        #expect(abs(vm.perfectChainBonusMultiplier - 1.15) < 1e-9)
    }

    @Test("チェーンボーナスが無効なら倍率は 1.0")
    func disabledIsOne() throws {
        let vm = try Self.makeViewModel(chainEnabled: false)
        vm.perfectChain = 3
        #expect(vm.perfectChainBonusMultiplier == 1.0)
    }

    @Test("チュートリアルの制限時間は、渡した秒数を表示する")
    func tutorialTextShowsSeconds() {
        let text = TutorialView.timeLimitText(seconds: 30)
        #expect(text.contains("30"))
        #expect(!text.contains("60"))
        #expect(!text.contains("%"))
    }
}
