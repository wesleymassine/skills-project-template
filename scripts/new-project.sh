#!/usr/bin/env bash
#
# Local alternative to GitHub's "Use this template": copies the template to a new folder,
# starts a git repository there and runs scripts/init.sh in it.
#
#   scripts/new-project.sh <destination> [init options: --owner <@user|@org/team>] [--plugin]

set -euo pipefail

dest=${1:-}
[[ -n "$dest" ]] || { echo "usage: $0 <destination> [--owner <@user|@org/team>] [--plugin]" >&2; exit 64; }
shift

template=$(cd "$(dirname "$0")/.." && pwd)
[[ ! -e "$dest" ]] || { echo "$dest already exists; pick another destination." >&2; exit 1; }

mkdir -p "$dest"
# tar keeps the skill symlinks intact.
(cd "$template" && tar cf - --exclude ./.git --exclude ./.claude/state --exclude ./.DS_Store .) |
  (cd "$dest" && tar xf -)

git -C "$dest" init -q -b main
"$dest/scripts/init.sh" "$@"
