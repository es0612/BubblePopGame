//
//  GameTimeDefaultMigration.swift
//  BubblePopGame
//
//  #35: 制限時間デフォルトを 60→30 に変更した際の、既存ユーザー向け 1 回限り migration。
//  旧デフォルト(60.0)のまま保存しているユーザーのみ 30.0 へ寄せる。手動で他の値にした人は尊重。
//

import Foundation

@MainActor
enum GameTimeDefaultMigration {
    static let sentinelKey = "didMigrateDefaultGameTimeTo30"
    static let oldDefault: Double = 60.0
    static let newDefault: Double = 30.0

    /// 起動時に 1 回だけ呼ぶ。センチネル済み・row 無し・旧デフォルト以外なら値を変えない。
    /// row が無くてもセンチネルは立てる（毎起動の再 fetch を避ける）。
    static func runIfNeeded(repository: SettingsRepository, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: sentinelKey) else { return }
        defer { defaults.set(true, forKey: sentinelKey) }

        guard let settings = try? repository.fetchSettings() else { return }
        if settings.gameTime == oldDefault {
            settings.gameTime = newDefault
            do {
                try repository.saveSettings(settings)
            } catch {
                // sentinel は defer で立つため retry されない点に留意（クラッシュは避ける）
                debugLog("GameTimeDefaultMigration: 移行の永続化に失敗 — \(error)")
            }
        }
    }
}
