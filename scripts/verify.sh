#!/usr/bin/env bash
#
# The project's verification contract. The harness (hooks, review, CI) only knows this interface:
#
#   scripts/verify.sh quick <files...>   fast: types, lint and tests for what these files touch.
#                                        Called by the Stop hook at the end of every turn.
#   scripts/verify.sh full [<app>]       everything, as in CI. Run once, before the commit that
#                                        closes the ticket. In a monorepo, <app> limits it to one app
#                                        (see docs/monorepo.md); without it, every app.
#
# Exit 0: ok. Anything else: failed, and the output says why.
#
# This file comes from the stack-less template. Replace the TODO blocks with the project's commands;
# the examples below are a starting point.

set -euo pipefail

mode=${1:-}
shift || true

case "$mode" in
quick)
  # TODO: the project's fast checks. Examples:
  #   Node/TS: npx tsc --noEmit && npx eslint "$@" && npx vitest related --run "$@"
  #            (if the tests drive the app in a child process, `related` finds none: run the suite)
  #   Go:      go vet ./... && golangci-lint run --new-from-rev=HEAD && go test ./...
  echo "verify.sh: quick mode is not configured yet (edit scripts/verify.sh)." >&2
  exit 0
  ;;
full)
  # TODO: the full verification, same as CI. Examples:
  #   Node/TS: npx tsc --noEmit && npx eslint . && npx vitest run --coverage
  #   Go:      go vet ./... && golangci-lint run && go test -race ./...
  echo "verify.sh: full mode is not configured yet (edit scripts/verify.sh)." >&2
  exit 1
  ;;
*)
  echo "usage: scripts/verify.sh quick <files...> | full [<app>]" >&2
  exit 64
  ;;
esac
