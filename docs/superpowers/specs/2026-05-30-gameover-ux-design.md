# GameOver画面UX改善 + 制限時間デフォルト 設計書

- 日付: 2026-05-30
- 対象 Issue: #35（制限時間60秒→30秒）/ #36（「もう一度プレイ」誤タップ）/ #37（リザルト画面の失敗感・スタッツ・子供向け）
- ステータス: 承認済み（2026-05-30）

## 背景

TestFlight 配信後、起票者（＝アプリオーナー）がプレイして気づいた UX 課題3件。いずれも小さなポリッシュだが、子供向けカジュアルゲームとしての印象を左右する。3件のスクリーンショットを一次証拠として確認済み。

## 全体方針・PR構成

stacked PR のマージ順の罠を避けるため、**すべて base=main** で 2 本に分割する。

- **PR-A**: #37 + #36 — どちらも `Views/GameOver/GameOverView.swift` と同一画面なので 1 PR にまとめる
- **PR-B**: #35 — `Models/GameSettings.swift` / `Models/GameScore.swift` / 起動時 migration（別ファイル群）。PR-A と独立

⚠️ **検証注記（#23 の教訓）**: #36 は実機/タップ無しで再現不可。本修正は**ハードニング**であり、推測で「fixed」と断定せず、TestFlight 実機で誤タップが解消したことを確認してからクローズする。

---

## #37 リザルト画面（ライト改善）

### 前提（コード確認済み）

- ゲームに**勝ち負けの概念は無い**。`GameViewModel.endGame()` を呼ぶ経路は次の2つだけ:
  1. `updateGameTimer()`（`timeRemaining <= 0` でタイムアップ）
  2. `PauseOverlayView`（ポーズメニューからの手動終了）
- どちらも「失敗」ではない。→ **`gameEndReason` enum は不要（YAGNI）**。リザルトは常にお祝いトーンで正しい。

### A. 失敗感の払拭

1. **背景グラデーション**: 現状 `[.red.opacity(0.3), .orange.opacity(0.1)]`（`GameOverView.swift:117`）を、明るいお祝いトーン（ミント/シアン系など）へ変更。`.accessible()`（色覚対応変換）は維持。最終色は実装時にシミュレータのスクショで微調整する（View レイヤの色はユニットテストで守れないため）。
2. **タイトル文言と色**: `gameover_title`（現「ゲーム終了」/「Game Over」、赤）を、タイムアップ・手動終了どちらでも自然なポジティブ文言へ。採用文言:
   - ja: 「おしまい！」
   - en / Base: "All Done!"
   - 色は赤 → 明るい色（背景トーンと調和する色。実装時調整）。
3. **（任意・余力）** `endGame()` 内の `effectService.triggerErrorFeedback()`（エラー触覚）は失敗感の一因。中立/成功系フィードバックへ差し替える（アセット不要の安価な改善）。`game_over` SFX の差し替えはアセットが必要なため今回スコープ外。

### B. スタッツ整理（子供向け）

- **メイン4カードは維持**: 最終スコア / 割れた数（bubblesPopped）/ 最大チェイン（bestStreak）/ 正確率。既に色鮮やかで子供向け。
- **詳細統計を整理**:
  - **削除**: 平均反応速度（`gameover_avg_reaction`）/ シャボン玉密度（`gameover_bubble_density`）— 開発者寄りの比率指標で子供に価値が薄い。
  - **プレイ時間（`gameover_play_time`）は残してバグ修正**。
- **「プレイ時間 0 sec」バグの根本原因と修正**:
  - 原因: `seconds_format` は `"%d秒"` / `"%d sec"`（**整数書式 %d**）。`GameOverView.swift:102` はここに **Double**（`gameSettings.gameTime - timeRemaining`）を渡しており、`%d` に Double を渡すと不正値（0等）になる。`SettingsView.swift:41` は同じキーに `Int(...)` を渡しているので正常。
  - 修正: `Int(gameSettings.gameTime - timeRemaining)` にキャストして渡す。

### C. ローカライズ

- 変更（`gameover_title`）と削除（`gameover_avg_reaction` / `gameover_bubble_density`）を **ja / en / Base の3ファイルすべて**に反映する。
- スクリーンショットは英語UIで撮られている → ポジティブ文言は **en に確実に反映**すること（ja だけでは起票者の画面が変わらない）。
- 削除後、3ファイルのキー集合が一致していることを確認（先日 CLAUDE.md に追記した「ローカライズの検証戦略」に沿う）。
- ファイル形式は `.strings`（`.xcstrings` ではない）: `ja.lproj/Localizable.strings` 等。

### 変更ファイル（#37）

- `app/BubblePopGame/Views/GameOver/GameOverView.swift`（背景色・タイトル色・スタッツ行の削除・Play Time の Int キャスト）
- `app/BubblePopGame/{ja,en,Base}.lproj/Localizable.strings`（`gameover_title` 文言変更 / 2キー削除）
- （任意）`app/BubblePopGame/ViewModels/GameViewModel.swift`（`endGame()` の触覚差し替え）

---

## #36 誤タップ対策（タップ抑止ガード）

### 仮説

プレイ中の連打 → ゲームオーバー画面が出現 → 流れで指が最上段の大きい緑「Play Again」に着弾し、リザルトを見る前に即リスタートしてしまう。

### 設計

- `GameOverView` に `@State private var buttonsEnabled = false` を追加。
- `.onAppear` で一定遅延（**約0.7秒**、定数化して調整可能に）後に `buttonsEnabled = true` をアニメーション付きで設定。
- ボタン群（`VStack`、`GameOverView.swift:41-92`）に `.disabled(!buttonsEnabled)` を付与し、無効中は `.opacity` を下げてフェードインさせる（「まだ押せない」ことが視覚的に伝わる）。
- 対象はボタン群**全体**（Play Again だけでなく Back to Menu の誤爆も防止）。

### テスト戦略

- SwiftUI の `.onAppear` + 遅延タイミングは単体テストが困難。→ **手動 walk-through 必須**。PR description に確認チェックリストを明記。
- 遅延を定数化し、可能なら初期状態（`buttonsEnabled == false`）が検証できる形にする。

### 変更ファイル（#36）

- `app/BubblePopGame/Views/GameOver/GameOverView.swift`

---

## #35 制限時間デフォルト30秒 + 既存ユーザー移行

### 既定値変更

- `app/BubblePopGame/Models/GameSettings.swift:47` `self.gameTime = 60.0` → `30.0`
- `app/BubblePopGame/Models/GameScore.swift:22` 引数デフォルト `gameTimeLimit: TimeInterval = 60.0` → `30.0`（呼び出し側は `effectiveGameTime` を渡すので実害は小さいが整合のため）

### 条件付き1回限り migration

チョークポイントの選定が肝（screenBounds/guard の教訓: 前提を供給するコードが全到達経路で走るか確認）。

- 現状、設定ロードは `SettingsViewModel.init` / `GameViewModel.init` で**遅延的**に発生し、設定画面を一度も開かないユーザーには永続 row が存在しないことがある。
- ケース分け:
  - **永続 row 無し**ユーザー → 既定値変更だけで新規 `GameSettings()` が 30 になる（migration 不要）。
  - **永続 row 有り & `gameTime == 60.0`** ユーザー → migration で 30 へ書き換える。
- **全ユーザーが起動時に必ず通る単一経路**で 1 回だけ実行する。**設定画面に紐付けると起票者本人に発火しない**ため不可。
  - 採用チョークポイント: ルート起動ビュー（`LaunchScreenView` / `ContentView` のうち `modelContainer` 環境を持つ側）の `.task`（起動時 1 回・MainActor・container 利用可）。ここは Tutorial 経由の有無に関わらず全ユーザーが通る。
  - 実装は副作用を testable に切り出す: `GameTimeDefaultMigration.runIfNeeded(repository:defaults:)` のような純ロジックを作り、`.task` から呼ぶ（ロジックは単体テスト、呼び出しは手動確認）。
  - **タイミング制約**: migration は「その起動で最初にゲーム時間が読まれる前」に完了している必要がある。`.task` は menu 操作前に走るので満たすが、`GameViewModel` が init 時点の古い値を保持する経路がないか実装時に確認する（必要なら startGame 時に再読込 or migration 完了後に再ロード）。
- 二重実行防止に **UserDefaults センチネル** `didMigrateDefaultGameTimeTo30`（Bool）を使用。
- ロジック: センチネル未設定なら、永続 row を fetch し、存在して `gameTime == 60.0` のときだけ `30.0` に書き換えて保存。実行後センチネルを true に。
- **弱点（許容済み）**: 「意図的に 60 を選んだユーザー」も 30 に変わる。60 は旧デフォルトなので大半はデフォルト据え置きユーザーと判断。手動で 90 等にしたユーザーは尊重される。

### テスト戦略（TDD）

in-memory ModelContainer を使った単体テストで以下を検証:

- `gameTime == 60.0` & センチネル未設定 → 実行後 `30.0` & センチネル true
- `gameTime == 90.0` → 不変（90 のまま）
- センチネル既に true → 何もしない
- 永続 row 無し → 何もしない（クラッシュしない）

### 変更ファイル（#35）

- `app/BubblePopGame/Models/GameSettings.swift`
- `app/BubblePopGame/Models/GameScore.swift`
- 新規 migration ロジック（例: `Services/` か `BubblePopGameApp` 起動経路）＋ 呼び出し
- `app/BubblePopGameTests/` に migration テスト

---

## マージ前手動確認チェックリスト

### PR-A（#37 + #36）

- [ ] リザルト画面の背景が明るいお祝いトーンになっている（赤くない）
- [ ] タイトルが「おしまい！」/「All Done!」でポジティブな色
- [ ] 平均反応速度・シャボン玉密度が消えている
- [ ] プレイ時間が正しい秒数で表示される（0 sec にならない）
- [ ] ja / en 両ロケールで確認（en で文言が反映されている）
- [ ] ゲームオーバー直後、約0.7秒はボタンが押せない（連打しても即リスタートしない）／その後フェードインして押せる
- [ ] TestFlight 実機で #36 の誤タップが実際に解消したか確認（クローズ条件）

### PR-B（#35）

- [ ] 新規インストール（永続 row 無し）で初期値が 30 秒
- [ ] 旧 60 秒のまま（未変更）の既存ユーザーが、アップデート起動後に 30 秒へ移行
- [ ] 手動で 90 秒等にしていたユーザーは値が保持される
- [ ] 設定画面を開かずにアプリを起動しても migration が発火する
