#!/usr/bin/env bash
#
# Tests for the record-touched.sh and stop-verify.sh hooks, in a fake project in a temp directory.
#   scripts/test/hooks.test.sh

set -uo pipefail

here=$(cd "$(dirname "$0")/../.." && pwd)
fails=0

check() { # description, expected, actual
  if [[ "$2" == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi
}

setup() {
  proj=$(mktemp -d)
  mkdir -p "$proj/.claude/hooks" "$proj/scripts"
  cp "$here/.claude/hooks/"*.sh "$proj/.claude/hooks/"
  touch "$proj/a.ts"
  export CLAUDE_PROJECT_DIR=$proj
}

fake_verify() { # exit code of the fake verify
  printf '#!/usr/bin/env bash\necho "verify $*"\nexit %s\n' "$1" >"$proj/scripts/verify.sh"
  chmod +x "$proj/scripts/verify.sh"
}

touch_file() { echo "{\"session_id\":\"s1\",\"tool_input\":{\"file_path\":\"$proj/$1\"}}" | "$proj/.claude/hooks/record-touched.sh"; }
stop() { echo '{"session_id":"s1"}' | "$proj/.claude/hooks/stop-verify.sh" >"$proj/stdout" 2>"$proj/stderr"; echo $?; }

# No edits in the session: the turn ends without running anything.
setup; fake_verify 1
check "no touched file, releases" 0 "$(stop)"

# Edit + verify ok: releases and clears the state.
setup; fake_verify 0; touch_file a.ts
check "verify ok, releases" 0 "$(stop)"
check "verify ok, clears the list" no "$([[ -e $proj/.claude/state/touched-s1.txt ]] && echo yes || echo no)"

# Edit + failing verify: blocks, passes the relative path once and returns the output.
setup; fake_verify 1; touch_file a.ts; touch_file a.ts
check "verify fails, blocks" 2 "$(stop)"
check "relative path, no duplicates" yes "$(grep -q 'verify quick a.ts$' "$proj/stderr" && echo yes || echo no)"

# After 3 consecutive blocks, releases so it never loops.
stop >/dev/null; stop >/dev/null
check "fourth Stop releases" 0 "$(stop)"
check "fourth Stop warns the user" yes "$(jq -e .systemMessage "$proj/stdout" >/dev/null && echo yes || echo no)"

# A touched file that was then deleted is not verified.
setup; fake_verify 1; touch_file b.ts
check "deleted file, releases" 0 "$(stop)"

# Files edited outside the project are not passed to verify.
setup; fake_verify 1; outside=$(mktemp); echo "{\"session_id\":\"s1\",\"tool_input\":{\"file_path\":\"$outside\"}}" | "$proj/.claude/hooks/record-touched.sh"
check "file outside the project, releases" 0 "$(stop)"

# An unsafe session id never becomes a file name.
setup; echo "{\"session_id\":\"../x\",\"tool_input\":{\"file_path\":\"$proj/a.ts\"}}" | "$proj/.claude/hooks/record-touched.sh"
check "unsafe session ignored" no "$([[ -d $proj/.claude/state ]] && echo yes || echo no)"

echo
((fails == 0)) && echo "all passed" || { echo "$fails failure(s)"; exit 1; }
