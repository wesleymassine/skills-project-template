#!/usr/bin/env bash
#
# Runs every harness self-test. CI calls this script directly (not `make test`), so the Makefile
# stays an ordinary, editable file while the test entry point is protected by the harness guard.
#
#   scripts/test/run.sh

set -uo pipefail
cd "$(dirname "$0")"
status=0
for t in *.test.sh; do
  echo "== $t"
  ./"$t" || status=1
done
exit $status
