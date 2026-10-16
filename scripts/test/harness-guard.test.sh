#!/usr/bin/env bash
#
# Tests for scripts/harness-guard.sh.
#   scripts/test/harness-guard.test.sh

set -uo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
guard="$root/scripts/harness-guard.sh"
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi; }
run() { printf '%s\n' "$@" | "$guard" >/dev/null 2>&1; echo $?; }

check "ordinary code passes" 0 "$(run src/app.ts README.md docs/adr/0001-x.md Makefile)"
check "verify.sh is protected" 1 "$(run src/app.ts scripts/verify.sh)"
check "nested workflow file is protected" 1 "$(run .github/workflows/ci.yml)"
check "the patterns file protects itself" 1 "$(run .github/harness-protected)"
check "a hook is protected" 1 "$(run .claude/hooks/stop-verify.sh)"
check "the reviewer skill is protected" 1 "$(run .agents/skills/conformance-review/SKILL.md)"
check "other skills are not" 0 "$(run .agents/skills/tdd/SKILL.md)"
check "a renamed protected file (old name listed) is caught" 1 "$(run docs/moved.md REVIEW.md)"
check "a similar but different name passes" 0 "$(run scripts/verify.sh.md REVIEW.md.bak)"
check "empty input passes" 0 "$(printf '' | "$guard" >/dev/null 2>&1; echo $?)"

out=$(printf '%s\n' scripts/verify.sh scripts/verify.sh | "$guard")
check "lists each protected path once" 1 "$(grep -c 'scripts/verify.sh' <<<"$out")"

tmp=$(mktemp) && printf '# only comments\n\n' >"$tmp"
check "a patterns file without patterns cannot check" 2 "$(echo x | "$guard" "$tmp" >/dev/null 2>&1; echo $?)"
check "a missing patterns file cannot check" 2 "$(echo x | "$guard" /nonexistent >/dev/null 2>&1; echo $?)"

echo
((fails == 0)) && echo "all passed" || { echo "$fails failure(s)"; exit 1; }
