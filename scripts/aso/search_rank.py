#!/usr/bin/env python3
"""App Store の検索順位を測る（#78 ASO の物差し）。

iTunes Search API で検索語ごとに上位 200 件を取り、BubblePopGame の順位を TSV で出す。
App Store アプリ内の検索とは完全には一致しないので、前後比較の目安として使う。
同じ語の一覧・同じコマンドで、1.1.2 の配信前と配信 4 週後に測る。

実行:
  python3 -I scripts/aso/search_rank.py scripts/aso/terms-ja.txt --country jp
出力（標準出力、TSV）:
  term<TAB>rank<TAB>total   rank は 1 始まり。見つからなければ「圏外」、取得に失敗したら「ERROR」
"""
import argparse
import json
import sys
import time
import urllib.parse
import urllib.request

BUNDLE_ID = "com.asapapalab.BubblePopGame"
API = "https://itunes.apple.com/search"


def find_rank(results, bundle_id):
    """results の中で bundle_id が何番目か（1 始まり）。無ければ None。"""
    for i, item in enumerate(results, start=1):
        if item.get("bundleId") == bundle_id:
            return i
    return None


def format_row(term, rank, total):
    """total が None は取得失敗（ERROR）。rank が None は圏外。"""
    if total is None:
        return f"{term}\tERROR\t-"
    return f"{term}\t{rank if rank is not None else '圏外'}\t{total}"


def fetch(term, country):
    query = urllib.parse.urlencode(
        {"term": term, "country": country, "entity": "software", "limit": 200}
    )
    with urllib.request.urlopen(f"{API}?{query}", timeout=20) as res:
        return json.load(res)["results"]


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("terms_file", help="1 行 1 語。# で始まる行と空行は無視")
    parser.add_argument("--country", default="jp")
    parser.add_argument("--wait", type=float, default=1.0, help="語ごとの待ち秒数")
    args = parser.parse_args()

    with open(args.terms_file, encoding="utf-8") as f:
        terms = [t.strip() for t in f if t.strip() and not t.startswith("#")]

    print("term\trank\ttotal")
    for term in terms:
        try:
            results = fetch(term, args.country)
            print(format_row(term, find_rank(results, BUNDLE_ID), len(results)))
        except Exception as e:  # 通信・HTTP・JSON の失敗は圏外と区別して記録する
            print(f"  fetch failed: {term}: {e}", file=sys.stderr)
            print(format_row(term, None, None))
        sys.stdout.flush()
        time.sleep(args.wait)


if __name__ == "__main__":
    main()
