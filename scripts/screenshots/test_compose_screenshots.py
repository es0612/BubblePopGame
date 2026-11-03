"""compose_screenshots.py の単体テスト（#78）。
実行（Pillow が要る）: <venv>/bin/python -I -m unittest discover -s scripts/screenshots -v
"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import compose_screenshots as cs  # noqa: E402

ORDER = ["game", "game-numbered", "result", "menu", "settings"]


class JobsTests(unittest.TestCase):
    def test_locales_share_screen_order(self):
        self.assertEqual(set(cs.JOBS), {"ja", "en"})
        for locale in ("ja", "en"):
            self.assertEqual([screen for screen, _ in cs.JOBS[locale]], ORDER, locale)

    def test_no_emoji_in_captions(self):
        for locale, jobs in cs.JOBS.items():
            for _, caption in jobs:
                self.assertFalse(any(ord(ch) >= 0x1F000 for ch in caption), f"{locale}: {caption}")

    def test_en_captions_fit_without_shrinking_too_far(self):
        cw = 1242  # 6.5" のキャンバス幅（3 サイズで最も狭い iPhone）
        margin = int(cw * 0.07)
        for _, caption in cs.JOBS["en"]:
            font = cs.fit_font(caption, cw - 2 * margin, int(cw * 0.072), cs.FONT_BOLD)
            self.assertGreaterEqual(font.size, cw * 0.05, caption)


if __name__ == "__main__":
    unittest.main()
