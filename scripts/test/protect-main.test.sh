#!/usr/bin/env bash
#
# Tests for scripts/protect-main.sh, against a fake `gh` that records every call and answers from
# environment variables. Nothing reaches GitHub.
#   scripts/test/protect-main.test.sh

set -uo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/protect-main.sh"
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1 (expected '$2', got '$3')"; fails=$((fails + 1)); fi; }

work=$(mktemp -d)
mkdir -p "$work/bin" "$work/repo/.github"
cat >"$work/bin/gh" <<'EOF'
#!/usr/bin/env bash
# Records the call (and any --input body), then answers like GitHub would.
echo "$*" >>"$GH_LOG"
if [[ " $* " == *" --input - "* ]]; then
  body=$(cat); echo "$body" >>"$GH_LOG"
  jq -e . >/dev/null <<<"$body" || { echo "fake gh: invalid JSON body" >&2; exit 98; }
fi
args=" $* "
case "$args" in
*" repo view "*) echo acme/app ;;
*" -X PUT orgs/"*"/teams/"*"/repos/"*) ;;
*" orgs/acme/teams/devs "*) echo "${FAKE_PRIVACY:-closed}" ;;
*" orgs/"*"/teams/"*) exit 1 ;;
*" -X POST repos/acme/app/rulesets "* | *" -X PUT repos/acme/app/rulesets/"*) ;;
*" repos/acme/app/rulesets "*)
  [[ "${FAKE_RULESETS:-}" == 403 ]] && exit 1
  if [[ -n "${FAKE_RULESETS:-}" ]]; then echo "$FAKE_RULESETS"; fi ;;
*" -X DELETE repos/acme/app/branches/main/protection "*) ;;
*" repos/acme/app/branches/main/protection "*) [[ "${FAKE_CLASSIC:-no}" == yes ]] || exit 1 ;;
*" repos/acme/app/collaborators"*) echo owner ;;
*" repos/acme/app/codeowners/errors "*) echo "${FAKE_CO_ERRORS:-0}" ;;
*" label create "*) ;;
*" repos/acme/app "*)
  case "$args" in
  *".permissions.admin"*) echo "${FAKE_ADMIN:-true}" ;;
  *".default_branch"*) echo main ;;
  *".private"*) echo "${FAKE_PRIVATE:-false}" ;;
  esac ;;
*) echo "fake gh: unexpected call: $*" >&2; exit 99 ;;
esac
EOF
chmod +x "$work/bin/gh"

# run <name> [VAR=value ...]: runs the script in the fake repo; sets $status, $out and $log.
run() {
  local n=$1; shift
  export GH_LOG="$work/$n.log"; : >"$GH_LOG"
  out=$(cd "$work/repo" && env PATH="$work/bin:$PATH" "$@" "$script" 2>&1); status=$?
  log=$(cat "$GH_LOG")
}
writes() { grep -cE -- '-X (PUT|POST|DELETE|PATCH)|label create' <<<"$log"; }

printf '/.github/ @acme/devs\n/REVIEW.md @someone\n' >"$work/repo/.github/CODEOWNERS"

run non-admin FAKE_ADMIN=false
check "a non-admin is refused" 1 "$status"
check "a non-admin changes nothing" 0 "$(writes)"
check "the refusal says why" 1 "$(grep -c 'not an admin' <<<"$out")"

run team
check "team project succeeds" 0 "$status"
check "the CODEOWNERS team gets write access" 1 "$(grep -c 'X PUT orgs/acme/teams/devs/repos/acme/app -f permission=push' <<<"$log")"
check "a user owner needs no access call" 0 "$(grep -c 'someone' <<<"$log")"
check "a new ruleset is created" 1 "$(grep -c 'X POST repos/acme/app/rulesets' <<<"$log")"
check "admins bypass only through a pull request" 1 "$(grep -c '"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "pull_request"' <<<"$log")"
check "one code-owner approval" 1 "$(grep -c '"required_approving_review_count": 1' <<<"$log")"
check "every CI check is required" 1 "$(grep -c '"context":"harness-linux"},{"context":"harness-macos"},{"context":"secrets"},{"context":"verify"},{"context":"harness-guard"}' <<<"$log")"
check "no force push and no deletion" 2 "$(grep -cE '"type": "(deletion|non_fast_forward)"' <<<"$log")"
check "the harness label is created" 1 "$(grep -c 'label create harness-change-approved' <<<"$log")"
check "it names the emergency admins" 1 "$(grep -c 'admins who can merge in an emergency: owner' <<<"$out")"

run rerun FAKE_RULESETS=42
check "a second run updates the same ruleset" 1 "$(grep -c 'X PUT repos/acme/app/rulesets/42' <<<"$log")"
check "a second run creates no new ruleset" 0 "$(grep -c 'X POST repos/acme/app/rulesets' <<<"$log")"

run classic FAKE_CLASSIC=yes
check "classic protection is removed" 1 "$(grep -c 'X DELETE repos/acme/app/branches/main/protection' <<<"$log")"

run secret-team FAKE_PRIVACY=secret
check "a secret team still succeeds" 0 "$status"
check "a secret team is reported with the fix" 1 "$(grep -c 'privacy=closed' <<<"$out")"

run co-errors FAKE_CO_ERRORS=3
check "CODEOWNERS errors are reported" 1 "$(grep -c '3 CODEOWNERS error' <<<"$out")"

run private-free FAKE_RULESETS=403 FAKE_PRIVATE=true
check "a private repo without rulesets fails" 1 "$status"
check "it names the plan as the cause" 1 "$(grep -c 'GitHub Team' <<<"$out")"
check "it creates no ruleset" 0 "$(grep -c 'rulesets ' <<<"$(grep -E -- '-X (POST|PUT)' <<<"$log")")"

printf '/.github/ @acme/ghost\n' >"$work/repo/.github/CODEOWNERS"
run missing-team
check "an unknown team fails" 1 "$status"
check "it names the team" 1 "$(grep -c '@acme/ghost' <<<"$out")"

rm "$work/repo/.github/CODEOWNERS"
run solo
check "solo project succeeds" 0 "$status"
check "solo needs no approval" 1 "$(grep -c '"required_approving_review_count": 0' <<<"$log")"
check "solo makes no team calls" 0 "$(grep -c 'orgs/' <<<"$log")"

rm -rf "$work"
echo
((fails == 0)) && echo "all passed" || { echo "$fails failure(s)"; exit 1; }
