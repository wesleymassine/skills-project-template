#!/usr/bin/env bash
#
# Tests for .agents/skills/conformance-review/scripts/diff.sh, in a throwaway git repository.
#   scripts/test/review.test.sh

set -uo pipefail

script="$(cd "$(dirname "$0")/../.." && pwd)/.agents/skills/conformance-review/scripts/diff.sh"
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi; }
has() { grep -q -- "$1" "$out" && echo yes || echo no; }

repo=$(mktemp -d) && cd "$repo"
git init -q -b main && git config user.email t@t && git config user.name t
echo one >committed.txt && git add . && git commit -qm base
git checkout -qb feature
echo two >>committed.txt && git commit -qam change
echo three >>committed.txt
echo new >"untracked file.txt"

out=$("$script")
check "prints a path under .review/" yes "$([[ "$out" == .review/*.diff && -f "$out" ]] && echo yes || echo no)"
check "includes committed branch changes" yes "$(has '+two')"
check "includes uncommitted edits" yes "$(has '+three')"
check "includes untracked files, even with spaces" yes "$(has '+new')"
check "excludes base commit content" no "$(has '+one')"

out2=$("$script")
check "never includes earlier review diffs" no "$(grep -q 'diff --git a/.review' "$out2" && echo yes || echo no)"

echo
((fails == 0)) && echo "all passed" || { echo "$fails failure(s)"; exit 1; }
