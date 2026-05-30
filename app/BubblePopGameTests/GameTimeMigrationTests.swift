//
//  GameTimeMigrationTests.swift
//  BubblePopGameTests
//
//  #35: 制限時間デフォルト 60→30 の既存ユーザー向け 1 回限り migration
//

import Testing
import SwiftData
import Foundation
@testable import BubblePopGame

@MainActor
@Suite("制限時間デフォルト migration (#35)")
struct GameTimeMigrationTests {

    static func makeRepo() throws -> SettingsRepositoryImpl {
        let schema = Schema([GameScore.self, GameStatistics.self, GameSettings.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SettingsRepositoryImpl(modelContainer: container)
    }

    /// テスト隔離用 UserDefaults。一意 suite を作り、開始時に空にする。
    static func makeDefaults(_ name: String) -> UserDefaults {
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test("旧デフォルト60のユーザーは30へ移行する")
    func migratesSixtyToThirty() throws {
        let repo = try Self.makeRepo()
        let settings = GameSettings()
        settings.gameTime = 60.0
        try repo.saveSettings(settings)
        let defaults = Self.makeDefaults("test.migrate.sixty")

        GameTimeDefaultMigration.runIfNeeded(repository: repo, defaults: defaults)

        #expect(try repo.fetchSettings()?.gameTime == 30.0)
        #expect(defaults.bool(forKey: GameTimeDefaultMigration.sentinelKey) == true)
    }

    @Test("手動で90にしたユーザーは不変")
    func leavesNinetyUnchanged() throws {
        let repo = try Self.makeRepo()
        let settings = GameSettings()
        settings.gameTime = 90.0
        try repo.saveSettings(settings)
        let defaults = Self.makeDefaults("test.migrate.ninety")

        GameTimeDefaultMigration.runIfNeeded(repository: repo, defaults: defaults)

        #expect(try repo.fetchSettings()?.gameTime == 90.0)
        #expect(defaults.bool(forKey: GameTimeDefaultMigration.sentinelKey) == true)
    }

    @Test("センチネル済みなら何もしない")
    func skipsWhenAlreadyMigrated() throws {
        let repo = try Self.makeRepo()
        let settings = GameSettings()
        settings.gameTime = 60.0
        try repo.saveSettings(settings)
        let defaults = Self.makeDefaults("test.migrate.done")
        defaults.set(true, forKey: GameTimeDefaultMigration.sentinelKey)

        GameTimeDefaultMigration.runIfNeeded(repository: repo, defaults: defaults)

        #expect(try repo.fetchSettings()?.gameTime == 60.0)
    }

    @Test("永続row無しでもクラッシュせずセンチネルを立てる")
    func handlesNoPersistedRow() throws {
        let repo = try Self.makeRepo()
        let defaults = Self.makeDefaults("test.migrate.norow")

        GameTimeDefaultMigration.runIfNeeded(repository: repo, defaults: defaults)

        #expect(try repo.fetchSettings() == nil)
        #expect(defaults.bool(forKey: GameTimeDefaultMigration.sentinelKey) == true)
    }
}
