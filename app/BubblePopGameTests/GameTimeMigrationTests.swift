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

    // MARK: - 失敗時に sentinel を立てない（次回再試行）

    @MainActor
    final class ThrowingSettingsRepository: SettingsRepository {
        enum FailMode { case fetch, save }
        let failMode: FailMode
        var stored: GameSettings?
        struct StubError: Error {}

        init(failMode: FailMode, stored: GameSettings? = nil) {
            self.failMode = failMode
            self.stored = stored
        }
        func saveSettings(_ settings: GameSettings) throws {
            if failMode == .save { throw StubError() }
            stored = settings
        }
        func fetchSettings() throws -> GameSettings? {
            if failMode == .fetch { throw StubError() }
            return stored
        }
        func resetToDefaults() throws {}
    }

    @Test("fetch 失敗時は sentinel を立てない（次回再試行できる）")
    func fetchFailureDoesNotBurnSentinel() throws {
        let repo = ThrowingSettingsRepository(failMode: .fetch)
        let defaults = Self.makeDefaults("test.migrate.fetchfail")

        GameTimeDefaultMigration.runIfNeeded(repository: repo, defaults: defaults)

        #expect(defaults.bool(forKey: GameTimeDefaultMigration.sentinelKey) == false)
    }

    @Test("save 失敗時は sentinel を立てない（次回再試行できる）")
    func saveFailureDoesNotBurnSentinel() throws {
        let sixty = GameSettings()
        sixty.gameTime = 60.0
        let repo = ThrowingSettingsRepository(failMode: .save, stored: sixty)
        let defaults = Self.makeDefaults("test.migrate.savefail")

        GameTimeDefaultMigration.runIfNeeded(repository: repo, defaults: defaults)

        #expect(defaults.bool(forKey: GameTimeDefaultMigration.sentinelKey) == false)
    }
}
