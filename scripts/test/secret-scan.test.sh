#!/usr/bin/env bash
#
# Tests for scripts/secret-scan.sh, in a throwaway repository. Skips when neither gitleaks nor a
# running Docker is available.
#   scripts/test/secret-scan.test.sh

set -uo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/secret-scan.sh"
if ! command -v gitleaks >/dev/null && ! { command -v docker >/dev/null && docker info >/dev/null 2>&1; }; then
  echo "skipped: no gitleaks and no running Docker"
  exit 0
fi

fails=0
check() { if [[ "$2" == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi; }

repo=$(mktemp -d) && cd "$repo"
mkdir scripts && cp "$script" scripts/
git init -q -b main && git config user.email t@t && git config user.name t
echo "clean" >readme.txt && git add . && git commit -qm base

git checkout -qb feature
echo "nothing to see" >notes.txt && git add . && git commit -qm clean-change
scripts/secret-scan.sh main..HEAD >/dev/null 2>&1
check "clean branch passes" 0 $?

# A realistic-looking token, built at runtime so this test file itself holds no secret.
token="ghp_$(printf 'a1B2c3D4e5F6g7H8i9J0k1L2m3N4o5P6q7R8')"
echo "GITHUB_TOKEN=$token" >config.env && git add . && git commit -qm leak
scripts/secret-scan.sh main..HEAD >/dev/null 2>&1
check "a committed token fails" 1 $?

out=$(scripts/secret-scan.sh main..HEAD 2>&1)
check "the report never prints the secret" no "$(grep -q "$token" <<<"$out" && echo yes || echo no)"

echo
((fails == 0)) && echo "all passed" || { echo "$fails failure(s)"; exit 1; }
