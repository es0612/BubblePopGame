#!/usr/bin/env python3
"""App Store 用スクショ合成スクリプト (#5)

simctl で撮った生スクショ（/tmp/bpg-shots/{iphone,ipad}-<screen>.png）を、
「グラデ背景 + 上部の日本語見出し + デバイス枠に収めたアプリ画面」に合成し、
App Store 必須解像度（6.9" / 6.5" / iPad 13"）で出力する。

実行:
  /tmp/bpg-venv/bin/python scripts/screenshots/compose_screenshots.py
依存: Pillow（venv に導入）/ macOS のヒラギノ角ゴシック
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SRC_DIR = "/tmp/bpg-shots"
OUT_DIR = "/tmp/bpg-final"
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"

# 出力キャンバス（App Store 必須）と、使う生スクショの元デバイス
CANVASES = {
    "iphone-6.9_1290x2796": (1290, 2796, "iphone"),
    "iphone-6.5_1242x2688": (1242, 2688, "iphone"),
    "ipad-13_2064x2752":    (2064, 2752, "ipad"),
}

# (screen キー, 日本語見出し) ※絵文字なし
JOBS = [
    ("menu",          "美しいシャボン玉の世界へ"),
    ("game",          "指先でシャボン玉をはじこう"),
    ("game-numbered", "数字を順番に消すチャレンジ"),
    ("result",        "あなたの記録を更新しよう"),
    ("settings",      "自分好みに自由カスタマイズ"),
]

# ブランドのグラデ（上=濃いめの空色 → 下=淡い水色）
GRAD_TOP = (74, 168, 232)
GRAD_BOTTOM = (231, 246, 255)
TEXT_COLOR = (255, 255, 255)
SHADOW_COLOR = (20, 70, 110)


def vertical_gradient(w, h, top, bottom):
    col = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / (h - 1)
        col.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return col.resize((w, h)).convert("RGBA")


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return m


def fit_font(text, max_w, start_px, font_path):
    px = start_px
    while px > 20:
        f = ImageFont.truetype(font_path, px)
        if f.getbbox(text)[2] <= max_w:
            return f
        px -= 2
    return ImageFont.truetype(font_path, 20)


def compose(raw_path, caption, out_path, canvas):
    cw, ch, _ = canvas
    bg = vertical_gradient(cw, ch, GRAD_TOP, GRAD_BOTTOM)
    draw = ImageDraw.Draw(bg)

    # --- 上部見出し ---
    margin = int(cw * 0.07)
    font = fit_font(caption, cw - 2 * margin, int(cw * 0.072), FONT_BOLD)
    bbox = draw.textbbox((0, 0), caption, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (cw - tw) // 2 - bbox[0]
    ty = int(ch * 0.055)
    # 影 + 本体
    draw.text((tx + 3, ty + 3), caption, font=font, fill=SHADOW_COLOR)
    draw.text((tx, ty), caption, font=font, fill=TEXT_COLOR)

    # --- デバイス枠にアプリ画面を収める ---
    shot = Image.open(raw_path).convert("RGBA")
    sw, sh = shot.size
    # 画面領域の目標幅（キャンバス幅の比率）。残り縦に収まるよう高さでも制限。
    top_zone = int(ch * 0.20)          # 見出しゾーン
    bottom_margin = int(ch * 0.04)
    avail_h = ch - top_zone - bottom_margin
    bezel = max(10, int(cw * 0.013))   # 黒縁の太さ
    target_w = int(cw * 0.80)
    target_h = int(target_w * sh / sw)
    if target_h + 2 * bezel > avail_h:
        target_h = avail_h - 2 * bezel
        target_w = int(target_h * sw / sh)
    shot_resized = shot.resize((target_w, target_h))

    # スクショ角丸
    radius = max(24, int(target_w * 0.045))
    shot_resized.putalpha(rounded_mask((target_w, target_h), radius))

    # ベゼル（黒の角丸）
    fw, fh = target_w + 2 * bezel, target_h + 2 * bezel
    frame = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle(
        [0, 0, fw - 1, fh - 1], radius=radius + bezel, fill=(22, 24, 28, 255)
    )
    frame.alpha_composite(shot_resized, (bezel, bezel))

    fx = (cw - fw) // 2
    fy = top_zone + (avail_h - fh) // 2

    # ドロップシャドウ
    shadow = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        [fx, fy + int(bezel * 1.5), fx + fw, fy + fh + int(bezel * 1.5)],
        radius=radius + bezel, fill=(10, 40, 70, 110),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(cw * 0.02)))
    bg.alpha_composite(shadow)
    bg.alpha_composite(frame, (fx, fy))

    bg.convert("RGB").save(out_path, "PNG")
    return out_path


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    made = []
    for cname, canvas in CANVASES.items():
        device = canvas[2]
        for i, (screen, caption) in enumerate(JOBS, start=1):
            raw = os.path.join(SRC_DIR, f"{device}-{screen}.png")
            if not os.path.exists(raw):
                print(f"  SKIP (no raw): {raw}")
                continue
            out = os.path.join(OUT_DIR, f"{cname}__{i:02d}_{screen}.png")
            compose(raw, caption, out, canvas)
            made.append(out)
            print(f"  OK: {out}")
    print(f"\n生成 {len(made)} 枚 -> {OUT_DIR}")


if __name__ == "__main__":
    main()
