# アクセシビリティガイド / Accessibility Guide

**最終更新日 / Last Updated**: 2025年8月20日 / August 20, 2025

---

## 日本語版

### アクセシビリティガイド

「シャボン玉消しゲーム」は、すべてのユーザーが等しく楽しめるよう、包括的なアクセシビリティ機能を実装しています。このガイドでは、各種支援技術との使用方法や最適な設定について詳しく説明します。

#### 1. 視覚支援機能

**1.1 VoiceOver（画面読み上げ）対応**

本アプリは、iOS標準のVoiceOver機能に完全対応しています。

**基本操作**
- **画面要素の読み上げ**: すべてのボタン、テキスト、スコア情報が音声で案内されます
- **ジェスチャナビゲーション**: 左右スワイプで要素間移動、ダブルタップで選択
- **ゲーム進行状況**: スコア、制限時間、残り泡数が定期的にアナウンスされます

**VoiceOver設定手順**
1. iOS設定 > アクセシビリティ > VoiceOver
2. VoiceOverを「オン」に設定
3. 読み上げ速度を好みに調整
4. アプリを起動して音声ガイドを確認

**ゲーム中のVoiceOver体験**
- **メニュー画面**: 「ゲーム開始ボタン」「設定ボタン」など明確に案内
- **ゲーム画面**: 「シャボン玉が15個あります」「制限時間30秒」などの状況説明
- **タップ時**: 「シャボン玉を消しました。スコア10点追加」などの結果音声
- **ゲーム終了**: 「ゲーム終了。最終スコア120点」の詳細報告

**1.2 高コントラスト表示対応**

**設定方法**
1. iOS設定 > アクセシビリティ > 画面表示とテキストサイズ
2. 「コントラストを上げる」をオン
3. アプリが自動的に高コントラストカラーに切り替わります

**高コントラスト時の変更点**
- 背景色: より暗い青色に変更
- シャボン玉: 境界線を太く、色彩をより鮮明に
- UI要素: ボタンの枠線を強調
- 文字: より太いフォントウェイトで表示

**1.3 文字サイズ調整（Dynamic Type）**

**設定方法**
1. iOS設定 > アクセシビリティ > 画面表示とテキストサイズ
2. 「さらに大きな文字」を有効化
3. テキストサイズを最大まで調整可能

**対応範囲**
- メニューのすべてのテキスト
- 設定画面の項目名と説明
- ゲーム中のスコア表示
- チュートリアルのテキスト

#### 2. 聴覚支援機能

**2.1 視覚的フィードバック強化**

聴覚に制限があるユーザー向けに、音声情報を視覚的に補完します。

**実装内容**
- **画面フラッシュ**: シャボン玉を消した時の画面全体の微細な点滅
- **パーティクル効果**: 破裂時の視覚的爆発エフェクト
- **カラーフィードバック**: スコア変動時の色彩変化
- **進行バー**: 制限時間の視覚的表示

**2.2 字幕・テキスト表示**

**機能詳細**
- すべての音響効果に対応するテキスト表示
- BGMの曲名とムードをテキストで表示
- ゲーム状況の詳細テキスト通知

#### 3. 運動機能支援

**3.1 カスタマイズ可能なタッチ設定**

**設定項目**
- **タッチ感度調整**: 軽いタッチから強いタッチまで5段階調整
- **長押し無効化**: 誤操作防止のための長押し判定オフ
- **連続タップ間隔**: 最小0.1秒から最大1.0秒まで調整可能

**3.2 AssistiveTouch連携**

**対応機能**
- iOSのAssistiveTouchとの完全互換性
- カスタムジェスチャーの認識
- 外部スイッチコントローラー対応

#### 4. 認知支援機能

**4.1 シンプルなインターフェース**

**設計思想**
- 最小限の情報表示で混乱を防止
- 明確な視覚階層と直感的なレイアウト
- 一貫したデザインパターン

**4.2 段階的チュートリアル**

**構成内容**
1. **基本操作**: タップによるシャボン玉消去
2. **スコアシステム**: 点数の仕組み説明
3. **制限時間**: タイマーの概念紹介
4. **数字順モード**: より複雑なルール説明

各ステップは：
- 自分のペースで進行可能
- いつでも再開・やり直しが可能
- 音声と視覚の両方でガイド

#### 5. アクセシビリティ設定

**5.1 アプリ内アクセシビリティ設定**

**アクセス方法**
設定画面 > 「アクセシビリティ」セクション

**利用可能設定**
- **VoiceOver詳細度**: 簡潔／標準／詳細の3段階
- **効果音説明**: 音響効果の詳細音声説明ON/OFF
- **自動ポーズ**: VoiceOver使用時の自動一時停止機能
- **コントラスト**: 標準／高コントラストの切り替え
- **アニメーション**: モーション効果の軽減設定

**5.2 iOS設定との連携**

アプリは以下のiOS標準設定を自動認識し、適用します：

- **視差効果を減らす**: アニメーション効果を最小限に
- **透明度を下げる**: UI要素の透明効果を無効化
- **ボタンの形**: ボタン要素の境界線を明確化
- **オン／オフラベル**: スイッチにテキストラベル追加

#### 6. 支援技術との互換性

**6.1 対応支援技術**

**完全対応**
- VoiceOver（iOS標準スクリーンリーダー）
- Switch Control（外部スイッチ操作）
- AssistiveTouch（タッチ支援）
- Voice Control（音声制御）

**部分対応**
- 外部キーボード（基本ナビゲーション）
- 外部ポインティングデバイス

**6.2 第三者支援アプリとの連携**

**推奨アプリ**
- **Proloquo2Go**: コミュニケーション支援（音声出力装置）
- **Be My Eyes**: 視覚支援ボランティアサービス
- **Seeing AI**: AIによる画像認識・説明

#### 7. トラブルシューティング

**7.1 VoiceOver関連の問題**

**症状**: VoiceOverが正常に動作しない
**解決方法**:
1. アプリを完全に終了し、再起動
2. iOS設定でVoiceOverをオフ→オンに切り替え
3. デバイスを再起動
4. アプリを最新版にアップデート

**症状**: 読み上げ速度が早すぎる/遅すぎる
**解決方法**:
1. VoiceOver設定で読み上げ速度調整
2. アプリ内設定で詳細度を変更

**7.2 表示関連の問題**

**症状**: 文字が小さくて読めない
**解決方法**:
1. iOS設定で文字サイズを最大に調整
2. 「さらに大きな文字」機能を有効化
3. アプリを再起動して設定を反映

**症状**: 色の区別がつかない
**解決方法**:
1. iOS設定で「コントラストを上げる」を有効化
2. 色覚調整機能（色覚多様性）を設定
3. アプリ内で高コントラストモードを選択

#### 8. フィードバックと改善

**8.1 アクセシビリティに関するフィードバック**

より良いアクセシビリティ体験のため、ユーザーからのフィードバックを歓迎します。

**フィードバック方法**
- App Storeのレビュー機能
- アプリページからの開発者への連絡

**改善要望の例**
- 新しい支援技術への対応要求
- 現在の機能の改善提案
- 新しいアクセシビリティ機能の提案

**8.2 継続的な改善**

開発チームは以下の方針でアクセシビリティ向上に取り組んでいます：

- 最新のWCAG（Web Content Accessibility Guidelines）準拠
- Apple Human Interface Guidelines遵守
- ユーザーテストによる実用性検証
- 定期的なアクセシビリティ監査実施

---

## English Version

### Accessibility Guide

"Bubble Pop Game" implements comprehensive accessibility features to ensure all users can enjoy the game equally. This guide provides detailed information on how to use various assistive technologies and optimal settings.

#### 1. Visual Support Features

**1.1 VoiceOver (Screen Reader) Support**

The app is fully compatible with iOS standard VoiceOver functionality.

**Basic Operations**
- **Element Reading**: All buttons, text, and score information are announced via audio
- **Gesture Navigation**: Swipe left/right to navigate between elements, double-tap to select
- **Game Progress**: Score, time limit, and remaining bubble count are regularly announced

**VoiceOver Setup Instructions**
1. iOS Settings > Accessibility > VoiceOver
2. Turn VoiceOver "On"
3. Adjust speaking rate to your preference
4. Launch the app to verify audio guidance

**VoiceOver Experience During Gameplay**
- **Menu Screen**: Clear announcements like "Start Game button," "Settings button"
- **Game Screen**: Status descriptions like "15 bubbles available," "30 seconds time limit"
- **Tap Actions**: Result feedback like "Bubble popped. 10 points added to score"
- **Game End**: Detailed reporting like "Game over. Final score 120 points"

**1.2 High Contrast Display Support**

**Setup Method**
1. iOS Settings > Accessibility > Display & Text Size
2. Turn on "Increase Contrast"
3. App automatically switches to high contrast colors

**High Contrast Changes**
- Background: Changes to darker blue
- Bubbles: Thicker borders with more vivid colors
- UI Elements: Enhanced button outlines
- Text: Displays with bolder font weight

**1.3 Text Size Adjustment (Dynamic Type)**

**Setup Method**
1. iOS Settings > Accessibility > Display & Text Size
2. Enable "Larger Text"
3. Text size can be adjusted to maximum

**Supported Elements**
- All menu text
- Settings screen items and descriptions
- In-game score display
- Tutorial text

#### 2. Hearing Support Features

**2.1 Enhanced Visual Feedback**

Visual compensation for audio information for users with hearing limitations.

**Implementation Details**
- **Screen Flash**: Subtle full-screen flash when bubbles are popped
- **Particle Effects**: Visual explosion effects during bursts
- **Color Feedback**: Color changes during score variations
- **Progress Bar**: Visual time limit display

**2.2 Subtitles & Text Display**

**Feature Details**
- Text display corresponding to all sound effects
- BGM track names and moods displayed as text
- Detailed text notifications of game status

#### 3. Motor Function Support

**3.1 Customizable Touch Settings**

**Configuration Options**
- **Touch Sensitivity**: 5-level adjustment from light to firm touch
- **Long Press Disable**: Turn off long press detection to prevent accidental operations
- **Continuous Tap Interval**: Adjustable from 0.1 to 1.0 seconds

**3.2 AssistiveTouch Integration**

**Supported Features**
- Full compatibility with iOS AssistiveTouch
- Custom gesture recognition
- External switch controller support

#### 4. Cognitive Support Features

**4.1 Simple Interface**

**Design Philosophy**
- Minimal information display to prevent confusion
- Clear visual hierarchy and intuitive layout
- Consistent design patterns

**4.2 Progressive Tutorial**

**Content Structure**
1. **Basic Operations**: Bubble popping via tap
2. **Score System**: Explanation of point mechanics
3. **Time Limit**: Introduction to timer concept
4. **Numbered Mode**: More complex rule explanation

Each step features:
- Self-paced progression
- Restart/retry available anytime
- Both audio and visual guidance

#### 5. Accessibility Settings

**5.1 In-App Accessibility Settings**

**Access Method**
Settings Screen > "Accessibility" Section

**Available Settings**
- **VoiceOver Verbosity**: Concise/Standard/Detailed (3 levels)
- **Sound Effect Description**: Detailed audio description of sound effects ON/OFF
- **Auto Pause**: Automatic pause function when using VoiceOver
- **Contrast**: Standard/High Contrast toggle
- **Animation**: Motion effect reduction settings

**5.2 iOS Settings Integration**

The app automatically recognizes and applies the following iOS standard settings:

- **Reduce Motion**: Minimizes animation effects
- **Reduce Transparency**: Disables transparency effects in UI elements
- **Button Shapes**: Clarifies button element boundaries
- **On/Off Labels**: Adds text labels to switches

#### 6. Assistive Technology Compatibility

**6.1 Supported Assistive Technologies**

**Full Support**
- VoiceOver (iOS standard screen reader)
- Switch Control (external switch operation)
- AssistiveTouch (touch assistance)
- Voice Control (voice commands)

**Partial Support**
- External keyboard (basic navigation)
- External pointing devices

**6.2 Third-Party Assistive App Integration**

**Recommended Apps**
- **Proloquo2Go**: Communication assistance (speech output device)
- **Be My Eyes**: Visual assistance volunteer service
- **Seeing AI**: AI-powered image recognition and description

#### 7. Troubleshooting

**7.1 VoiceOver-Related Issues**

**Symptom**: VoiceOver not functioning properly
**Solution**:
1. Completely close and restart the app
2. Turn VoiceOver off and on in iOS settings
3. Restart the device
4. Update the app to the latest version

**Symptom**: Reading speed too fast/slow
**Solution**:
1. Adjust reading speed in VoiceOver settings
2. Change verbosity level in app settings

**7.2 Display-Related Issues**

**Symptom**: Text too small to read
**Solution**:
1. Adjust text size to maximum in iOS settings
2. Enable "Larger Text" feature
3. Restart app to apply settings

**Symptom**: Cannot distinguish colors
**Solution**:
1. Enable "Increase Contrast" in iOS settings
2. Configure color vision adjustment (color vision diversity)
3. Select high contrast mode within the app

#### 8. Feedback and Improvement

**8.1 Accessibility Feedback**

We welcome user feedback for a better accessibility experience.

**Feedback Methods**
- App Store review feature
- Developer contact through app page

**Example Improvement Requests**
- Support requests for new assistive technologies
- Improvement suggestions for current features
- Proposals for new accessibility features

**8.2 Continuous Improvement**

The development team is committed to improving accessibility with the following approach:

- Compliance with latest WCAG (Web Content Accessibility Guidelines)
- Adherence to Apple Human Interface Guidelines
- Usability verification through user testing
- Regular accessibility audits

---

## 重要なリソース / Important Resources

### 関連文書 / Related Documents
- **ユーザーサポートガイド**: support-documentation.md
- **アプリ設定マニュアル**: README（開発者向け）
- **プライバシーポリシー**: privacy-policy.md

### 外部リソース / External Resources

**日本語**
- [Apple アクセシビリティ](https://www.apple.com/jp/accessibility/)
- [iOS アクセシビリティガイド](https://support.apple.com/ja-jp/accessibility/iphone-ipad)
- [VoiceOver ユーザガイド](https://support.apple.com/ja-jp/guide/iphone/iph3e2e415f/ios)

**English**
- [Apple Accessibility](https://www.apple.com/accessibility/)
- [iOS Accessibility Guide](https://support.apple.com/accessibility/iphone-ipad)
- [VoiceOver User Guide](https://support.apple.com/guide/iphone/iph3e2e415f/ios)

---

**アプリ名 / App Name**: シャボン玉消しゲーム / Bubble Pop Game  
**開発者 / Developer**: [Developer Name]  
**連絡先 / Contact**: App Store アプリページ / App Store App Page  

*このガイドは、アクセシビリティ技術の進歩に合わせて定期的に更新されます。最新版は常にアプリ内でご確認いただけます。*

*This guide is regularly updated to keep pace with accessibility technology advances. The latest version is always available within the app.*