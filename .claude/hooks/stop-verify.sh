#!/usr/bin/env bash
#
# Claude Code Stop hook: a quality gate at the end of every turn.
#
# Takes the files this session edited (recorded by record-touched.sh) and runs
# `scripts/verify.sh quick` on them. If verification fails, the turn is not allowed to end: the
# failure output is handed back to the agent so it fixes the problem before reporting success.
#
# Exit codes follow the Claude Code hook protocol: 0 lets the turn end, 2 keeps it going and feeds
# stderr to the agent. The gate gives up after MAX_BLOCKS consecutive failures and tells the user,
# so a problem the agent cannot solve never traps it in a loop.

set -uo pipefail

MAX_BLOCKS=3

input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$PWD}"

# Without jq nothing can be parsed, so the gate would be off without anyone noticing. Say so.
if ! command -v jq >/dev/null; then
  printf '{"systemMessage": "Stop hook: jq is not installed, so nothing was verified. Install jq to enable the verification gate."}\n'
  exit 0
fi
session=$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null)
state="$root/.claude/state"
verify="$root/scripts/verify.sh"

[[ -n "$session" && "$session" =~ ^[A-Za-z0-9_-]+$ ]] || exit 0
list="$state/touched-$session.txt"
blocks="$state/blocks-$session"
[[ -s "$list" ]] || exit 0

# Unique files that still exist inside the project, relative to the root. A deleted file has nothing
# to verify, and files outside the project (user settings, other repositories) are not ours to check.
files=()
while IFS= read -r f; do
  [[ -e "$f" && "$f" == "$root"/* ]] || continue
  files+=("${f#"$root"/}")
done < <(sort -u "$list")

if ((${#files[@]} == 0)); then
  rm -f "$list" "$blocks"
  exit 0
fi

if [[ ! -x "$verify" ]]; then
  jq -n --arg m "Stop hook: scripts/verify.sh is missing or not executable; nothing was verified." \
    '{systemMessage: $m}'
  exit 0
fi

if output=$(cd "$root" && "$verify" quick "${files[@]}" 2>&1); then
  rm -f "$list" "$blocks"
  exit 0
fi

n=$(($(cat "$blocks" 2>/dev/null || echo 0) + 1))
if ((n > MAX_BLOCKS)); then
  rm -f "$list" "$blocks"
  jq -n --arg m "Stop hook: verify quick still fails after $MAX_BLOCKS attempts. The turn was released; check it by hand." \
    '{systemMessage: $m}'
  exit 0
fi
echo "$n" >"$blocks"

{
  echo "scripts/verify.sh quick failed on the files this session edited (attempt $n of $MAX_BLOCKS). Fix it before ending the turn:"
  echo "$output" | tail -n 80
} >&2
exit 2
