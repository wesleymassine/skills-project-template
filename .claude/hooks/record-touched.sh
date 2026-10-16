#!/usr/bin/env bash
#
# Claude Code PostToolUse hook (Edit|Write|MultiEdit|NotebookEdit). Records, per session, the files
# the agent edited, so stop-verify.sh checks only what this session touched. Edits made through the
# shell do not go through here, so they are not recorded.

set -euo pipefail

input=$(cat)
command -v jq >/dev/null || exit 0 # stop-verify.sh warns the user about the missing jq
session=$(jq -r '.session_id // empty' <<<"$input")
file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")

# Nothing to record without a session or a file. The session id becomes a file name, so it is only
# accepted when it is safe for that.
[[ -n "$session" && -n "$file" ]] || exit 0
[[ "$session" =~ ^[A-Za-z0-9_-]+$ ]] || exit 0

state="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/state"
mkdir -p "$state"
printf '%s\n' "$file" >>"$state/touched-$session.txt"
