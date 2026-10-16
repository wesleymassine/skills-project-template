#!/usr/bin/env bash
#
# Harness guard: reads changed paths (one per line) on stdin and lists those that match a pattern in
# .github/harness-protected.
#
#   scripts/harness-guard.sh [<patterns file>] < changed-paths
#
# Exit 0: nothing protected changed. 1: protected paths changed (printed). 2: could not check.
#
# In CI the workflow runs main's copy of this script and of the patterns file, so a pull request
# cannot change the rules it is judged by. Locally, `make harness-check` shows what a branch touches.

set -uo pipefail

patterns_file=${1:-"$(cd "$(dirname "$0")/.." && pwd)/.github/harness-protected"}
[[ -r "$patterns_file" ]] || { echo "harness-guard: cannot read $patterns_file" >&2; exit 2; }

patterns=()
while IFS= read -r line; do
  line=${line%%#*}
  line=${line//[[:space:]]/}
  [[ -n "$line" ]] && patterns+=("$line")
done <"$patterns_file"
((${#patterns[@]})) || { echo "harness-guard: no patterns in $patterns_file" >&2; exit 2; }

hits=()
while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  for p in "${patterns[@]}"; do
    # Unquoted on purpose: the right-hand side of == is a glob, and `*` also matches `/`.
    # shellcheck disable=SC2053
    if [[ "$file" == $p ]]; then
      hits+=("$file")
      break
    fi
  done
done

if ((${#hits[@]} == 0)); then
  echo "harness-guard: no protected path changed."
  exit 0
fi
echo "harness-guard: this change touches protected harness paths:"
printf '  %s\n' "${hits[@]}" | sort -u
exit 1
