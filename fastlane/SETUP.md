# fastlane ASC メタデータ投入 セットアップ & 運用手順

バイナリは **Xcode Cloud が所有**したまま、**メタデータ（What's New / marketing URL / 説明文 等）だけ**を fastlane で ASC に投入するための手順。
（skill: `asc-metadata-delivery` / 検証委譲: `release-version-bump-check`）

---

## ⚠️ 大原則（事故防止）

1. **`upload_metadata` は本番 ASC に書き込む**（`submit_for_review:false` でも editable バージョンに stage される）。「審査に出さない」だけで「ASC に書かない」ではない。
2. **必ず `download` → `edit` → `upload` → `precheck` → 人間 submit の順**。download を飛ばして upload すると、live の説明文/キーワードを空 or placeholder で**上書き破壊**する。
3. 投入系コマンドは **creds を持つ人間が手実行**する（CI / 自動化に乗せない）。
4. **`fastlane/.env`・API Key JSON・`.p8` 秘密鍵はコミット禁止**（`.env` / `*.json` / `*.p8` は gitignore 済み。JSON はリポ外に置くのが安全）。

---

## 1. ASC API Key を発行（初回のみ・所要 5 分）

1. [App Store Connect](https://appstoreconnect.apple.com) → **ユーザーとアクセス** → **統合**（Integrations）タブ → **App Store Connect API**
2. **「+」**でキーを生成（アクセス権は **App Manager** で十分）
3. 控える値:
   - **Key ID**（例 `ABC123DEFG`）
   - **Issuer ID**（画面上部の UUID）
   - **`.p8` 秘密鍵ファイル**（**1 回しかダウンロードできない**。安全な場所に保存）

## 2. API Key を JSON ファイル化

fastlane の download(CLI) / upload(lane) / precheck はすべて **API Key JSON ファイル**で認証する（個別フラグ `--api_key_id` 等は CLI に存在しない）。下記の JSON を作る:

```json
{
  "key_id": "ABC123DEFG",
  "issuer_id": "6053b7fe-68a8-4acb-89be-165aa6465141",
  "key": "-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMG...（.p8 の中身を改行込みで貼る。実改行でも \\n でも可）...\n-----END PRIVATE KEY-----",
  "in_house": false
}
```

リポ外（例: `~/.private_keys/asc_api_key.json`）に置くのが安全。`fastlane/` 内に置く場合も `*.json` / `*.p8` は gitignore 済み。

> `.p8` の中身を JSON にそのまま貼ればよい（`key` フィールド）。fastlane は実改行・`\n` どちらも受け付ける。

## 3. `.env` を作成

```bash
cp fastlane/.env.example fastlane/.env
# fastlane/.env を編集して JSON のパスを入れる:
#   APP_STORE_CONNECT_API_KEY_PATH=/Users/<you>/.private_keys/asc_api_key.json
```

fastlane は起動時に `fastlane/.env` を自動ロードするので、**この 1 変数で download(CLI)・upload(lane)・precheck の全部が認証される**。

## 4. 現状の live メタデータを取得（**最初に必ず！**）

```bash
# リポルートで実行。.env の APP_STORE_CONNECT_API_KEY_PATH を自動で読む。
# metadata/ に live ASC の全フィールドが txt で落ちてくる（ローカルを上書きするが ASC は変更しない＝読み取り側）。
fastlane deliver download_metadata
```

> 認証フラグを明示したい場合のみ: `fastlane deliver download_metadata --api_key_path "$APP_STORE_CONNECT_API_KEY_PATH"`
> （deliver CLI の API Key 認証は `--api_key_path`（JSON）または `--api_key`（hash）のみ。`--api_key_id` 等は無い。）

これで `fastlane/metadata/<locale>/*.txt` が live の内容で埋まる。**ここを起点に編集する**（placeholder で上書きしない）。

## 5. 変更フィールドだけ編集

`fastlane/metadata/` 配下を編集。download で生成された **`description.txt` / `keywords.txt` 等は触らない**（live を維持）。
v1.1 で変えるのは **release_notes（What's New）と marketing_url の 2 種だけ**。

```
metadata/
├── ja/
│   ├── release_notes.txt      ← 更新
│   └── marketing_url.txt      ← 更新
└── en-US/
    ├── release_notes.txt      ← 更新（絵文字 NG）
    └── marketing_url.txt      ← 更新
```

### v1.1 で投入する内容

**`ja/release_notes.txt`**（まず絵文字あり版。ASC が 🫧 を弾いたら絵文字なし版に差し替え。v1.0 で ja 絵文字が拒否された実績あり）:
```
軽微な内部改善とビルドの安定性向上を行いました。引き続きごゆっくりお楽しみください🫧
```
絵文字なしフォールバック:
```
軽微な内部改善とビルドの安定性向上を行いました。引き続きごゆっくりお楽しみください。
```

**`en-US/release_notes.txt`**（絵文字禁止・plain text）:
```
This update includes minor internal improvements and build stability fixes. Thank you for playing!
```

**`ja/marketing_url.txt` と `en-US/marketing_url.txt`**（誤った `weightscale-7cdf1.web.app` → サポート URL に是正）:
```
https://note.com/es0612swift
```

## 6. upload 前のローカル検証（precheck が拾わない穴）

- en の `release_notes.txt` に**絵文字が無い**こと（ASC の en は絵文字を silent reject）
- `MARKETING_VERSION` / build の bump → `release-version-bump-check` skill（v1.1 は `1.1 / 40` 済み）

## 7. 【前提】ASC に v1.1 バージョンが存在すること

`upload_metadata` は ASC の **editable バージョン**にメタデータを stage する。よって **upload 前に v1.1 の editable バージョンが ASC 上に存在している必要がある**:
- ASC UI で「v1.1 を新規バージョン作成」で先に作る、**または**
- Xcode Cloud で build 40 が ASC に上がり、その build に紐づく v1.1 バージョンが作られている

存在しない状態で upload すると stage 先が無くエラーになる。

## 8. ASC に stage → 検証

```bash
fastlane upload_metadata
```

- `upload_to_app_store`（skip_binary_upload）で metadata を ASC の editable に stage
- 投入直前に deliver が **HTML プレビュー**を出すので、内容を目視確認してから続行（`force` は付けていない）
- 続けて `precheck` が staged コピーを検証（placeholder / curse / 到達不能 URL 等）

## 9. 審査提出（人間・ASC UI）

precheck が通ったら、**ASC の Web UI で提出ボタンを押す**（fastlane では自動提出しない）。

提出後の流れは `docs/RELEASE_v1.1.md` の「提出前チェックリスト」「クローズ条件」に従う:
- Xcode Cloud 配信ビルドの Test ログで **#44 も同時検証**
- 受理後に `git tag -a v1.1 ... && git push origin v1.1` → #46 / #44 クローズ

---

## トラブルシュート

| 症状 | 対処 |
| --- | --- |
| en の What's New が保存できない/弾かれる | 絵文字が混入していないか確認（en は絵文字 NG） |
| ja の 🫧 が弾かれる | 絵文字なしフォールバック文に差し替え |
| upload で「version が無い」系エラー | 手順 7。ASC に v1.1 editable バージョンを先に作る |
| upload で screenshots エラー | `skip_screenshots: true` 済み。スクショは ASC 側で v1.0 分を流用 |
| live の説明文が消えた | download を飛ばして upload した。download_metadata でやり直し → 再 upload |
| `ITMS-90186 / 90062` | version bump 漏れ。`release-version-bump-check` skill 参照（v1.1 は対応済み） |
| 認証エラー | `APP_STORE_CONNECT_API_KEY_PATH` の JSON パス・JSON 中の key_id/issuer_id/key を再確認 |
