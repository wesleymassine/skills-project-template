#!/usr/bin/env bash
#
# Protects the default branch with a repository ruleset. Run it once after the first push, as a
# repository admin (whoever creates the repository is one):
#
#   scripts/protect-main.sh        # or: make protect-main
#
# - Changes land only through a pull request with green CI; no direct push, force push or deletion.
# - Team projects (with .github/CODEOWNERS): one approval from a code owner. Every team named in
#   CODEOWNERS gets write access, which GitHub requires before it counts the team as an owner.
# - Admins may bypass the rules, but only through a pull request: in a production emergency an admin
#   merges without waiting for review or CI, and the bypass stays recorded on the pull request.
#   docs/workflow.md ("Emergency merge") says when that is allowed.
#
# Running it again updates the same ruleset. A classic branch protection on the branch is removed,
# since its rules would apply on top of the ruleset and block the bypass.

set -euo pipefail

name="main"
checks=(harness-linux harness-macos secrets verify harness-guard)
label=harness-change-approved
admin_role_id=5 # GitHub's built-in RepositoryRole id for "admin"

die() { echo "protect-main: $*" >&2; exit 1; }
warn() { echo "  warn  $*" >&2; }

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner) || die "no GitHub repository here (push it first)"
is_admin=$(gh api "repos/$repo" --jq '.permissions.admin')
[[ "$is_admin" == true ]] || die "you are not an admin of $repo. Only an admin can protect main, and an admin is the one who can merge in an emergency; ask an organization owner to make you one."
branch=$(gh api "repos/$repo" --jq '.default_branch')

approvals=0
if [[ -f .github/CODEOWNERS ]]; then
  approvals=1
  # Teams are written @org/slug; users (@login) need no setup here.
  for team in $(grep -v '^#' .github/CODEOWNERS | grep -o '@[A-Za-z0-9_.-]*/[A-Za-z0-9_.-]*' | sort -u); do
    org=${team#@} && org=${org%%/*} && slug=${team#*/}
    privacy=$(gh api "orgs/$org/teams/$slug" --jq '.privacy' 2>/dev/null) || die "team $team in CODEOWNERS does not exist"
    gh api -X PUT "orgs/$org/teams/$slug/repos/$repo" -f permission=push >/dev/null
    echo "  ok    $team has write access"
    [[ "$privacy" == closed ]] ||
      warn "$team is a secret team: CODEOWNERS ignores it, so no review is requested. An org owner makes it visible with: gh api -X PATCH orgs/$org/teams/$slug -f privacy=closed"
  done
fi

contexts=$(printf '{"context":"%s"},' "${checks[@]}")
ruleset=$(cat <<EOF
{
  "name": "$name",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "bypass_actors": [ { "actor_id": $admin_role_id, "actor_type": "RepositoryRole", "bypass_mode": "pull_request" } ],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": $approvals,
        "require_code_owner_review": $( ((approvals)) && echo true || echo false ),
        "dismiss_stale_reviews_on_push": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false } },
    { "type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [ ${contexts%,} ] } }
  ]
}
EOF
)

existing=$(gh api "repos/$repo/rulesets" --jq ".[] | select(.name == \"$name\") | .id" 2>/dev/null) || {
  [[ $(gh api "repos/$repo" --jq '.private') == true ]] &&
    die "rulesets are not available for this private repository on the current GitHub plan. Make the repository public, or move the organization to GitHub Team."
  die "could not read the rulesets of $repo"
}
if [[ -n "$existing" ]]; then
  gh api -X PUT "repos/$repo/rulesets/$existing" --input - <<<"$ruleset" >/dev/null
else
  gh api -X POST "repos/$repo/rulesets" --input - <<<"$ruleset" >/dev/null
fi
echo "  ok    ruleset \"$name\" on $branch: pull request, green CI$( ((approvals)) && echo ", 1 code-owner approval"), admin bypass through a pull request"

if gh api "repos/$repo/branches/$branch/protection" >/dev/null 2>&1; then
  gh api -X DELETE "repos/$repo/branches/$branch/protection" >/dev/null
  echo "  ok    removed the classic branch protection (replaced by the ruleset)"
fi

gh label create "$label" -R "$repo" --color B60205 -f \
  --description "A maintainer reviewed this pull request's harness changes" >/dev/null
echo "  ok    label $label"

admins=$(gh api "repos/$repo/collaborators?per_page=100" --jq '[.[] | select(.role_name == "admin") | .login] | join(", ")')
echo "  info  admins who can merge in an emergency: $admins"

if [[ -f .github/CODEOWNERS ]]; then
  errors=$(gh api "repos/$repo/codeowners/errors" --jq '.errors | length' 2>/dev/null || echo 0)
  ((errors == 0)) || warn "GitHub reports $errors CODEOWNERS error(s) on $branch: gh api repos/$repo/codeowners/errors"
fi
