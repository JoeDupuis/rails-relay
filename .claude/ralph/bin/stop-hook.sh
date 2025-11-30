#!/usr/bin/env bash
[ "$RALPH_WIGGUM_LOOP" != "true" ] && exit 0
cat << 'JSON'
{
  "decision": "block",
  "continue": true,
  "reason": "You cannot exit until you are done. If you are done exit by calling the kill script at .claude/ralph/bin/kill-claude. If you believe there is an issue and you need user input, use the AskUserQuestion tool."
}
JSON
