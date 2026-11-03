"""search_rank.py の単体テスト（#78）。実行: python3 -I -m unittest discover -s scripts/aso -v"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from search_rank import find_rank, format_row  # noqa: E402

BUNDLE = "com.asapapalab.BubblePopGame"


class FindRankTests(unittest.TestCase):
    def test_find_rank_returns_1_based_position(self):
        results = [{"bundleId": "a"}, {"bundleId": BUNDLE}, {"bundleId": "c"}]
        self.assertEqual(find_rank(results, BUNDLE), 2)

    def test_find_rank_none_when_absent(self):
        self.assertIsNone(find_rank([{"bundleId": "a"}], BUNDLE))


class FormatRowTests(unittest.TestCase):
    def test_fetch_error_is_not_out_of_rank(self):
        self.assertEqual(format_row("泡", None, None), "泡\tERROR\t-")
        self.assertEqual(format_row("泡", None, 154), "泡\t圏外\t154")
        self.assertEqual(format_row("シャボン玉", 4, 53), "シャボン玉\t4\t53")


if __name__ == "__main__":
    unittest.main()
