#!/usr/bin/env bash
#
# Checks the cross-agent layout:
#   - every skill in .agents/skills/ is reachable by Claude Code through a symlink in .claude/skills/;
#   - every symlink in .claude/skills/ resolves (it breaks on Windows clones without core.symlinks);
#   - every skill in skills-lock.json exists, and every SKILL.md `name` matches its folder;
#   - every skill follows the Agent Skills naming, description and size limits;
#   - no CLAUDE.md or CLAUDE.local.md anywhere, which would make Claude Code skip AGENTS.md there;
#   - every folder under apps/ has its own AGENTS.md;
#   - in a project created from the template, no {{PLACEHOLDER}} is left;
#   - TEMPLATE_VERSION matches CHANGELOG.md (template), or .template-version exists (project).
#
#   scripts/test/layout.test.sh

set -uo pipefail

cd "$(dirname "$0")/../.."
fails=0
fail() { echo "FAIL $1"; fails=$((fails + 1)); }

[[ -f AGENTS.md ]] || fail "AGENTS.md is missing"
while IFS= read -r f; do
  fail "$f exists: in that folder Claude Code would read it instead of AGENTS.md (remove it, or start it with @AGENTS.md)"
done < <(find . \( -name .git -o -name node_modules \) -prune -o \( -name CLAUDE.md -o -name CLAUDE.local.md \) -print)

# Monorepo: every app carries its own short AGENTS.md (docs/monorepo.md).
for app in apps/*/; do
  [[ -d "$app" ]] || continue
  [[ -f "$app/AGENTS.md" ]] || fail "${app%/} has no AGENTS.md"
done

for dir in .agents/skills/*/; do
  [[ -d "$dir" ]] || continue
  name=$(basename "$dir")
  link=".claude/skills/$name"
  if [[ ! -L "$link" ]]; then
    fail "$name has no symlink in .claude/skills/"
  elif [[ "$(cd "$link" 2>/dev/null && pwd -P)" != "$(cd "$dir" && pwd -P)" ]]; then
    fail "$link does not resolve to $dir"
  fi
  skill="$dir/SKILL.md"
  declared=$(awk '/^---/{f++; next} f==1 && /^name:/{print $2; exit}' "$skill" 2>/dev/null)
  [[ "$declared" == "$name" ]] || fail "$skill declares name '$declared'"
  # Agent Skills specification (agentskills.io): name, description and size limits.
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ && ${#name} -le 64 ]] ||
    fail "$name: names are lowercase letters, digits and single hyphens, up to 64 characters"
  description=$(awk '/^---/{f++; next} f==1 && /^description:/{sub(/^description: */, ""); print; exit}' "$skill")
  description=${description#\"}; description=${description%\"}
  ((${#description} >= 1 && ${#description} <= 1024)) || fail "$name: description must be 1-1024 characters (has ${#description})"
  lines=$(wc -l <"$skill")
  ((lines <= 500)) || fail "$name: SKILL.md has $lines lines; keep it under 500 and move detail to references/"
done

for link in .claude/skills/*; do
  [[ -e "$link" || -L "$link" ]] || continue
  [[ -L "$link" ]] || { fail "$link is a real folder; skills belong in .agents/skills/"; continue; }
  [[ -e "$link" ]] || fail "$link is a broken symlink"
done

# Outside the template itself (init.sh deletes itself), no placeholder may survive.
if [[ ! -f scripts/init.sh ]]; then
  left=$(grep -rln '{{[A-Za-z]*}}' AGENTS.md docs .github 2>/dev/null || true)
  [[ -z "$left" ]] || fail "placeholders left in: $left (run scripts/init.sh)"
fi

# Template version: the template keeps TEMPLATE_VERSION equal to the latest CHANGELOG entry; a
# project records the version it came from in .template-version.
semver='^[0-9]+\.[0-9]+\.[0-9]+$'
if [[ -f scripts/init.sh ]]; then
  version=$(tr -d '[:space:]' <TEMPLATE_VERSION 2>/dev/null)
  [[ "$version" =~ $semver ]] || fail "TEMPLATE_VERSION must hold a semantic version (has '$version')"
  latest=$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md 2>/dev/null | tr -d '#[] ')
  [[ "$latest" == "$version" ]] || fail "TEMPLATE_VERSION ($version) differs from the latest CHANGELOG.md entry ($latest)"
else
  recorded=$(awk '/^version:/{print $2}' .template-version 2>/dev/null)
  [[ "$recorded" =~ $semver ]] || fail ".template-version is missing or has no version (run scripts/init.sh)"
fi

if [[ -f skills-lock.json ]]; then
  for s in $(jq -r '.skills | keys[]' skills-lock.json); do
    [[ -f ".agents/skills/$s/SKILL.md" ]] || fail "$s is in skills-lock.json but not in .agents/skills/"
  done
fi

((fails == 0)) && echo "layout ok" || { echo "$fails failure(s)"; exit 1; }
