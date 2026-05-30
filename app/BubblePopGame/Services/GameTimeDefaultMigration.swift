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
    /// row が無い／移行不要／移行成功時のみセンチネルを立てる（毎起動の再 fetch を避ける）。
    /// fetch/save が失敗した場合はセンチネルを立てずログのみ行い、次回起動で再試行する。
    static func runIfNeeded(repository: SettingsRepository, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: sentinelKey) else { return }

        let settings: GameSettings?
        do {
            settings = try repository.fetchSettings()
        } catch {
            // fetch 失敗時は sentinel を立てず、次回起動で再試行する
            debugLog("GameTimeDefaultMigration: 設定の取得に失敗 — \(error)")
            return
        }

        guard let settings else {
            // 永続 row 無し（新規インストール等）。既定値が30なので移行不要。
            defaults.set(true, forKey: sentinelKey)
            return
        }

        guard settings.gameTime == oldDefault else {
            // 旧デフォルト以外（手動設定値など）は尊重。移行不要。
            defaults.set(true, forKey: sentinelKey)
            return
        }

        settings.gameTime = newDefault
        do {
            try repository.saveSettings(settings)
            defaults.set(true, forKey: sentinelKey)
        } catch {
            // 永続化失敗時は sentinel を立てず、次回起動で再試行する
            debugLog("GameTimeDefaultMigration: 移行の永続化に失敗 — \(error)")
        }
    }
}
