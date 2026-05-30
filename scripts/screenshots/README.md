# App Store スクリーンショット生成

App Store 提出用スクショを **半自動** で再生成する手順。UI 変更後に作り直すとき用。

## 仕組み

1. **DEBUG 起動引数 `--screenshot=<画面>`**（`ContentView.configureForScreenshot`、`#if DEBUG` 限定・リリース未影響）で、起動直後に任意画面へ直行する。`result` は見栄えのするサンプルスコアを注入。
   - 対応画面: `menu` / `game` / `game-numbered` / `result` / `settings` / `highscore`
2. **`simctl`** で iPhone / iPad シミュレータに各画面を表示させ生スクショを撮る（`simctl` はタップ不可なので、この起動引数で画面遷移を代替している）。
3. **`compose_screenshots.py`**（Pillow）で「グラデ背景 + 上部の日本語見出し + デバイス枠」に合成し、App Store 必須解像度（6.9" / 6.5" / iPad 13"）で出力する。

## 再生成手順

```bash
# 0) Pillow（初回のみ）
python3 -m venv /tmp/bpg-venv && /tmp/bpg-venv/bin/pip install pillow

# 1) Debug ビルド
xcodebuild build -project app/BubblePopGame.xcodeproj -scheme BubblePopGame \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/bpg-ss

# 2) 生スクショ撮影（iPhone 17 Pro / iPad Pro 13"）
#    各画面: xcrun simctl launch <UDID> com.asapapalab.BubblePopGame --screenshot=<画面>
#    → 数秒待って xcrun simctl io <UDID> screenshot /tmp/bpg-shots/<device>-<画面>.png → terminate
#    （BGM がデフォルト ON なので撮影後は必ず terminate すること）

# 3) 合成（→ /tmp/bpg-final/ に出力）
/tmp/bpg-venv/bin/python scripts/screenshots/compose_screenshots.py
```

生成物（`/tmp/bpg-final/` → `app-store-assets/screenshots/` にコピー）は `.gitignore` 対象。
スクリプトと DEBUG 機能だけをバージョン管理し、画像は再生成可能とする。

## 見出し文・配色の変更

`compose_screenshots.py` の `JOBS`（画面ごとの日本語見出し）と `GRAD_TOP`/`GRAD_BOTTOM`（背景グラデ）を編集する。フォントは `ヒラギノ角ゴシック W7`。
