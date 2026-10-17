#!/usr/bin/env bash
#
# Turns a fresh copy of this template into your project. Run it once, from the root of the new
# repository (created with "Use this template" on GitHub, or by scripts/new-project.sh):
#
#   scripts/init.sh --owner @your-org/your-team   # team: CODEOWNERS guards the harness
#   scripts/init.sh                               # solo: no CODEOWNERS
#   add --plugin to use the Claude Code plugin instead of vendored skills (Claude Code only)
#
# It fills in the placeholders, removes the template's own files (README, LICENSE, these scripts)
# and deletes itself. Review the result with `git status` and commit it.

set -euo pipefail

usage() { echo "usage: scripts/init.sh [--owner <@user|@org/team>] [--plugin]" >&2; exit 64; }

owner=""
mode=vendored
while (($#)); do
  case "$1" in
  --owner) owner=${2:-}; [[ "$owner" == @* ]] || usage; shift 2 ;;
  --plugin) mode=plugin; shift ;;
  *) usage ;;
  esac
done

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
command -v jq >/dev/null || { echo "jq is required." >&2; exit 1; }
[[ -f AGENTS.md && -f scripts/init.sh ]] || { echo "Run this from a fresh copy of the template." >&2; exit 1; }
if git remote -v 2>/dev/null | grep -q 'skills-project-template'; then
  echo "This looks like the template repository itself. Create your project first:" >&2
  echo "  GitHub: 'Use this template', or locally: scripts/new-project.sh <destination>" >&2
  exit 1
fi

name=$(basename "$root")
replace() { # file, placeholder, value
  sed -i.bak "s|$2|$3|g" "$1" && rm "$1.bak"
}

replace AGENTS.md '{{NAME}}' "$name"
replace docs/context.md '{{date}}' "$(date +%Y-%m-%d)"

if [[ -n "$owner" ]]; then
  replace .github/CODEOWNERS '@{{OWNER}}' "$owner"
else
  rm .github/CODEOWNERS
fi

if [[ "$mode" == plugin ]]; then
  for s in $(jq -r '.skills | keys[]' skills-lock.json); do
    rm -rf ".agents/skills/$s" ".claude/skills/$s"
  done
  rm skills-lock.json .agents/skills/LICENSE.mattpocock THIRD_PARTY_NOTICES.md
  # Vendored projects turn the plugin off under both of its ids (installed from the CLI, or synced
  # from a claude.ai account). Plugin mode removes those blocks.
  tmp=$(mktemp)
  jq 'del(.enabledPlugins["mattpocock-skills@claude-plugins-official", "mattpocock-skills@synced"])
      | if .enabledPlugins == {} then del(.enabledPlugins) else . end' \
    .claude/settings.json >"$tmp" && mv "$tmp" .claude/settings.json
fi

# Record where the project came from, so later template releases can be compared with it.
template_version=$(tr -d '[:space:]' <TEMPLATE_VERSION)
{
  echo "# Created from this template version. Compare it with the template's CHANGELOG.md to see what changed since."
  echo "template: wesleymassine/skills-project-template"
  echo "version: $template_version"
  echo "initialized: $(date +%Y-%m-%d)"
  echo "mode: $mode, $([[ -n "$owner" ]] && echo team || echo solo)"
} >.template-version
rm TEMPLATE_VERSION CHANGELOG.md

# The stack is not decided yet, so mise.toml starts with no tools: make doctor warns until one is
# pinned. Without the file, mise falls back to the developer's global config and CI to the runner's
# preinstalled tools, so local and CI would run different versions without anyone noticing.
cat >mise.toml <<'EOF'
# Tool versions for this project, installed by `make setup` (mise install) and in CI by jdx/mise-action.
# Pin the stack once it is decided (record the decision as an ADR): uncomment or add lines under
# [tools] for the language and the tools verify.sh calls (linters, package managers).
# A new or changed mise.toml must be trusted once per machine: `mise trust`.
[tools]
# go = "1.26"
# golangci-lint = "2"
# java = "21"
# node = "22"
# pnpm = "10"
# python = "3.13"
# rust = "1.90"
# uv = "0.9"
EOF

# Template-only make targets (init, new-project) have no use in the project.
sed -i.bak '/^# >>> template-only/,/^# <<< template-only/d' Makefile && rm Makefile.bak

# The template's README and LICENSE describe the template, not your project.
rm -f LICENSE scripts/new-project.sh
cat >README.md <<EOF
# $name

<!-- What this project is, in one paragraph. -->

## Working on this project

This repository is set up for coding agents (Claude Code, Codex, Copilot, Cursor, Gemini).

- Instructions for agents and humans: [\`AGENTS.md\`](AGENTS.md)
- How we work, from idea to pull request: [\`docs/workflow.md\`](docs/workflow.md)
- What each skill does: [\`docs/skills.md\`](docs/skills.md)

Prerequisites: \`git\`, \`jq\`, [mise](https://mise.jdx.dev) and your agent. Then run \`make setup\`, and \`make\` to see every command. Day-to-day commands and token-saving habits: [\`docs/cheatsheet.md\`](docs/cheatsheet.md).
EOF
rm scripts/init.sh

echo "Initialized $name from template v$template_version (skills: $mode, $([[ -n "$owner" ]] && echo "team, owner $owner" || echo "solo"))."
echo
echo "Next steps:"
[[ "$mode" == plugin ]] && echo "  - claude plugin install mattpocock-skills@claude-plugins-official   (once per machine, unless synced from claude.ai)"
echo "  1. git add -A && git commit -m 'Initialize from skills-project-template'   (then: make doctor)"
echo "  2. Fill in docs/context.md: the problem and the facts you have already verified."
echo "  3. make setup-skills, then make grill   (or type /setup-matt-pocock-skills and /grill-with-docs in your agent)"
echo "  4. Once the stack is decided (ADR): pin it in mise.toml (then mise trust) and fill in scripts/verify.sh."
[[ -n "$owner" ]] && echo "  5. Create the GitHub repository and push (gh repo create <org>/$name --private|--public --source . --push), then make protect-main."
echo
echo "Run make to see every command; docs/cheatsheet.md has the commands inside the agent."
exit 0
