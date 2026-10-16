#!/usr/bin/env bash
#
# Scans commits for secrets with gitleaks: API keys, tokens, private keys, passwords in URLs.
#
#   scripts/secret-scan.sh [<git log range>]
#
# Without a range it scans what the branch has on top of origin/main (or main), and the whole
# history when neither exists. CI passes the range of the pull request or of the push. Uses a local
# gitleaks binary when there is one, otherwise the pinned Docker image.
#
# Exit 0: no secret found. 1: secrets found (reported redacted). 2: could not scan.
#
# A finding that is not a secret (a test fixture, a documented example) is allowed with a
# `gitleaks:allow` comment on that line, never by weakening this script.

set -uo pipefail

GITLEAKS_IMAGE=ghcr.io/gitleaks/gitleaks:v8.30.1

cd "$(dirname "$0")/.."

range=${1:-}
if [[ -z "$range" ]]; then
  for base in origin/main main; do
    if git rev-parse -q --verify "$base" >/dev/null && [[ "$(git rev-parse "$base")" != "$(git rev-parse HEAD)" ]]; then
      range="$base..HEAD"
      break
    fi
  done
fi

args=(git --no-banner --redact --exit-code 1)
[[ -n "$range" ]] && args+=(--log-opts="$range")

if command -v gitleaks >/dev/null; then
  gitleaks "${args[@]}" .
elif command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  docker run --rm -v "$PWD:/repo" -w /repo "$GITLEAKS_IMAGE" "${args[@]}" /repo
else
  echo "secret-scan: neither gitleaks nor a running Docker is available; nothing was scanned." >&2
  exit 2
fi
status=$?

case $status in
0) echo "secret-scan: no secrets in ${range:-the whole history}." ;;
1) echo "secret-scan: secrets found. Remove them, rotate them at the source, and rewrite the commits that added them." >&2 ;;
*) echo "secret-scan: gitleaks could not run (exit $status)." >&2; exit 2 ;;
esac
exit $status
