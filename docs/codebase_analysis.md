# BubblePopGame コードベース分析レポート

## 概要
BubblePopGame プロジェクトに対して実装を伴わないコードレビューを行い、主要な課題と改善ポイントを整理しました。以下では重要度順に指摘事項をまとめています。

## 高優先度
- `GameViewModel.swift:19`, `GameViewModel.swift:116` 初期化時に固定の `screenBounds` でバブルを生成しており、`GameView.swift:155` で実デバイスのサイズを受け取る前に画面外座標へ配置される可能性があります。依存注入の順序見直しや遅延初期化で実サイズ反映を保証してください。
- `GameView.swift:134` の時間バーと `GameOverView.swift:102-104` の統計が常に 60 秒を基準にしており、設定画面で時間を変更しても UI と記録が一致しません。`gameSettings.gameTime` を参照するよう修正が必要です。
- `GameView.swift:156` で生成する `ParticleEffectView` が値型のまま `EffectServiceImpl` に渡され、`ParticleEffectView.swift:21-27` の状態更新が表示層に反映されません。参照共有の仕組み（ラッパークラスやバインディング）を導入してステートを連動させてください。
- `AccessibilityUtils.swift:131` が `isHighContrastEnabled` を常に `false` で返し、高コントラスト設定を無効化しています。`UIAccessibility` など実データを返すよう修正し、アクセシビリティ対応を阻害しない設計にしてください。

## 中優先度
- `HighScoreRow.swift:32` などで日本語テキストを直書きしており、ローカライズ資産（`Localizable.strings`）を経由していません。一貫性確保のため翻訳ファイルへ集約してください。
- `PauseOverlayView.swift:42`, `PauseOverlayView.swift:86`, `PauseOverlayView.swift:94` の英語メッセージも同様にローカライズ漏れです。既存の多言語対応と整合を取ってください。
- `BubbleService.swift:31-71` のバブル生成ロジックが `GameSettings` の `bubbleMinRadius`, `bubbleMaxRadius`, `animationSpeed` などを参照せず固定値を使用しています。設定画面で調整した値がゲームに反映されるようロジックを修正してください。
- `GameViewModel.swift:110-113` で `EffectService` を具象型へダウンキャストしており抽象化が崩れています。プロトコルへ必要な API を追加するなど依存逆転を守ってください。
- `GameViewModel.swift:95-107` のパフォーマンス調整はバブル数削減のみで、負荷が回復しても復元されません。目標個数の再評価や追加生成ロジックを検討してください。

## 低優先度
- `EffectService.swift:47`, `AudioService.swift:74` などに多数の `print` ログが残っており、本番ビルドでコンソールを汚染します。`OSLog` やデバッグビルド限定ログへ移行してください。
- `MenuViewModel.swift:20` など `TODO` が残っている箇所は、メニュー機能仕上げ（ハイスコア取得など）の優先度を決めて対処してください。
- テストは初期値確認や簡易性能計測（`SimpleGameViewModelTests.swift:15` など）が中心で、動的難易度やリポジトリ動作の回帰防止が不足しています。主経路（設定変更後のゲーム開始、スコア保存、統計更新）のテスト追加を検討してください。
- `SimplePerformanceTests.swift:33` などテストコード内の `print` により CI ログが騒がしくなります。必要であればメトリクス収集や `#expect` のみで計測結果を扱ってください。

## 推奨対応順序
1. 画面サイズ反映と時間表示エラーなどゲームプレイ直結の致命的バグを修正。
2. パーティクル演出の共有方法とアクセシビリティ挙動を是正。
3. ローカライズ漏れ・設定反映漏れを整備し、テストのカバレッジを拡充。
4. ログ出力や `TODO` の整理、追加テスト作成など仕上げを実施。

以上です。追加で深掘りが必要な箇所があればお知らせください。
