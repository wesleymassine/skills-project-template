#!/usr/bin/env bash
#
# Writes the whole change under review to .review/<timestamp>.diff and prints that path: everything
# since the branch left main (or since the first commit), uncommitted edits and untracked files.
#
#   .agents/skills/conformance-review/diff.sh [<base-branch>]

set -euo pipefail

base_branch=${1:-main}
base=$(git merge-base HEAD "$base_branch" 2>/dev/null || git rev-list --max-parents=0 HEAD)
mkdir -p .review
out=".review/$(date +%Y%m%d-%H%M%S).diff"

{
  git diff "$base" -- . ':(exclude).review'
  git ls-files --others --exclude-standard -z -- . ':(exclude).review' |
    while IFS= read -r -d '' f; do git diff --no-index -- /dev/null "$f" || true; done
} >"$out"

echo "$out"
