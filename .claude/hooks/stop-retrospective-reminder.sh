#!/bin/bash
# Stop hook: セッション終了タイミングで振り返りを促す（条件付き）
#
# 条件:
# 1. 最終リマインドから1時間以上経過
# 2. 直近2時間でgit commitが3件以上
#
# 出力: 上記を満たす場合のみ JSON で systemMessage を返す
#       (Claude Code が systemMessage を Claude のコンテキストに渡し、振り返りを促せる)

set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
    # gitリポジトリ外なら何もしない
    exit 0
fi

STATE_FILE="$REPO_ROOT/.claude/.last-retrospective-reminder"
NOW=$(date +%s)
LAST=0
if [ -f "$STATE_FILE" ]; then
    LAST=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
fi
ELAPSED=$((NOW - LAST))

# 1時間（3600秒）以内に既にリマインド出してたらスキップ
if [ "$ELAPSED" -lt 3600 ]; then
    exit 0
fi

# 直近2時間のコミット数を取得
COMMIT_COUNT=$(git -C "$REPO_ROOT" log --oneline --since="2 hours ago" 2>/dev/null | wc -l | tr -d ' ')

# 3件以上ならリマインドを出力
if [ "$COMMIT_COUNT" -ge 3 ]; then
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$NOW" > "$STATE_FILE"

    # systemMessage を JSON で返す
    # additionalContext で Claude に振り返りスキル呼出を促す
    cat <<EOF
{
  "systemMessage": "💡 直近2時間でコミット${COMMIT_COUNT}件検出。セッション終わる前に session-retrospective スキルで学びを CLAUDE.md / Issue に反映しませんか？",
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": "Session has been productive (${COMMIT_COUNT} recent commits). If the user is wrapping up, suggest running session-retrospective skill to extract learnings into CLAUDE.md and create follow-up Issues. Do NOT auto-run the skill — only suggest it."
  }
}
EOF
fi

exit 0
