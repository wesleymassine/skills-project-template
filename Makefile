# Everyday commands for this repository. Run `make` to list them.
#
# Targets under "Agent" open Claude Code in a fresh session already running a skill. A fresh session
# per task is the cheapest way to work, so prefer `make implement T=<ticket>` over reusing an old one.
# Using another agent? Open it and type the same /command inside it.

SHELL := /bin/bash
CLAUDE ?= claude

# The skills CLI needs Node 22.20+. Use mise when it is there, so the project's own Node is untouched.
SKILLS := $(shell command -v mise >/dev/null 2>&1 && echo "mise exec node@22 --") npx -y skills@latest
AGENTS := --agent claude-code codex

.DEFAULT_GOAL := help
.PHONY: help doctor setup test verify verify-quick secrets harness-check check \
	skills-list skills-find skills-add skills-update skills-remove skills-restore skills-check plugins \
	setup-skills grill spec tickets implement review retro triage architecture \
	protect-main init init-team init-plugin new-project

help: ## List the commands
	@awk 'BEGIN {FS = ":.*## "} /^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0, 5)} /^[a-z-]+:.*## / {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\nCommands inside the agent and token-saving habits: docs/cheatsheet.md\n"

##@ Setup

doctor: ## Check that this machine has everything the project needs
	@ok=1; \
	for t in git jq mise; do \
	  if command -v $$t >/dev/null; then printf "  ok    %s\n" $$t; else printf "  MISS  %s\n" $$t; ok=0; fi; \
	done; \
	if command -v $(CLAUDE) >/dev/null; then printf "  ok    claude %s\n" "$$($(CLAUDE) --version 2>/dev/null | head -1)"; else printf "  info  claude not found (fine if you use another agent)\n"; fi; \
	if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then printf "  ok    gh (logged in)\n"; else printf "  info  gh missing or logged out (needed for GitHub Issues and make protect-main)\n"; fi; \
	if command -v gitleaks >/dev/null || { command -v docker >/dev/null && docker info >/dev/null 2>&1; }; then printf "  ok    secret scan (gitleaks or Docker)\n"; else printf "  info  no gitleaks or running Docker: make secrets can't run locally (CI still scans)\n"; fi; \
	if [[ "$$(git config core.symlinks)" == false ]]; then printf "  MISS  git core.symlinks is false: skills won't load in Claude Code\n"; ok=0; fi; \
	if command -v $(CLAUDE) >/dev/null && $(CLAUDE) plugin list 2>/dev/null | grep -q 'mattpocock-skills@'; then \
	  printf "  info  mattpocock-skills plugin is installed; this project turns it off (see make plugins)\n"; fi; \
	if [[ -f .template-version ]]; then printf "  ok    created from template v%s\n" "$$(awk '/^version:/{print $$2}' .template-version)"; fi; \
	if [[ ! -f scripts/init.sh ]]; then \
	  if [[ ! -f mise.toml ]]; then printf "  warn  no mise.toml: tools come from your global mise config locally and from the runner in CI\n"; \
	  elif ! awk '/^\[/{t=($$0=="[tools]")} t && /^[[:space:]]*[^#[:space:][]/{f=1} END{exit !f}' mise.toml; then \
	    printf "  warn  mise.toml pins no tools yet: pin the stack once it is decided (ADR)\n"; \
	  elif command -v mise >/dev/null && ! mise ls --local >/dev/null 2>&1; then printf "  warn  mise can't read mise.toml (not trusted? run mise trust)\n"; \
	  else printf "  ok    mise.toml pins the stack\n"; fi; \
	fi; \
	scripts/test/layout.test.sh >/dev/null && printf "  ok    skill layout\n" || { printf "  MISS  skill layout (run make skills-check)\n"; ok=0; }; \
	[[ $$ok == 1 ]] && printf "\nReady.\n" || { printf "\nFix the MISS lines above.\n"; exit 1; }

setup: ## Install the pinned tool versions and check the machine
	@if ! command -v mise >/dev/null; then echo "mise not found: install it from https://mise.jdx.dev"; \
	elif ! mise install; then echo "mise install failed (a new or changed mise.toml needs mise trust first)"; fi
	@$(MAKE) --no-print-directory doctor

##@ Verify

test: ## Run the harness self-tests (hooks, skill layout, review script, secret scan)
	@scripts/test/run.sh

verify: ## Full verification, same as CI
	@scripts/verify.sh full

verify-quick: ## Fast checks on some files: make verify-quick FILES="src/a.ts src/b.ts"
	@scripts/verify.sh quick $(FILES)

secrets: ## Scan the branch's new commits for secrets (gitleaks, local or Docker)
	@scripts/secret-scan.sh $(RANGE)

harness-check: ## List the protected harness paths this branch changes compared to main
	@{ git diff --name-only main...HEAD; git diff --name-only; git ls-files --others --exclude-standard; } | sort -u | scripts/harness-guard.sh || \
	  echo "A pull request with these changes needs a maintainer's harness-change-approved label."

check: test verify secrets ## Self-tests, full verification and secret scan

##@ Skills

skills-list: ## List the skills installed in this project
	@$(SKILLS) list

skills-find: ## Search the public skills catalog: make skills-find Q=react
	@$(SKILLS) find $(Q)

skills-add: ## Add skills to this project: make skills-add REPO=owner/repo SKILL="a b"
	@test -n "$(REPO)" || { echo "usage: make skills-add REPO=owner/repo [SKILL=\"name ...\"]"; exit 64; }
	@$(SKILLS) add $(REPO) $(if $(SKILL),--skill $(SKILL)) $(AGENTS)
	@scripts/test/layout.test.sh

skills-update: ## Update the vendored skills (review the diff before committing)
	@$(SKILLS) update -p
	@scripts/test/layout.test.sh && git status --short .agents/skills skills-lock.json

skills-remove: ## Remove a skill: make skills-remove SKILL=name
	@test -n "$(SKILL)" || { echo "usage: make skills-remove SKILL=name"; exit 64; }
	@$(SKILLS) remove $(SKILL) -y
	@scripts/test/layout.test.sh

skills-restore: ## Restore the skills listed in skills-lock.json
	@$(SKILLS) experimental_install

skills-check: ## Check the skill layout (symlinks, lock, names)
	@scripts/test/layout.test.sh

plugins: ## Show Claude Code plugins on this machine (duplicates the vendored skills?)
	@$(CLAUDE) plugin list

##@ Agent (opens Claude Code in a fresh session)

setup-skills: ## Configure tracker, labels and domain docs (once per repository)
	@$(CLAUDE) "/setup-matt-pocock-skills"

grill: ## Align on a feature (covers the engineering questions in docs/context.md): make grill TOPIC="..."
	@$(CLAUDE) "/grill-with-docs $(TOPIC) Cover the Engineering questions in docs/context.md that apply."

spec: ## Turn the current grilling into a spec (better: run /to-spec in the same session)
	@$(CLAUDE) "/to-spec $(TOPIC)"

tickets: ## Split a spec into tickets: make tickets SPEC=<path-or-issue>
	@$(CLAUDE) "/to-tickets $(SPEC)"

implement: ## Implement one ticket in a fresh session, on its own branch: make implement T=<ticket>
	@test -n "$(T)" || { echo "usage: make implement T=<ticket path or issue number>"; exit 64; }
	@branch=t$$(basename "$(T)" .md | tr -c 'A-Za-z0-9-\n' '-'); \
	if [[ "$$(git branch --show-current)" == main ]]; then \
	  git switch -q "$$branch" 2>/dev/null || git switch -q -c "$$branch"; echo "On branch $$branch"; fi
	@$(CLAUDE) "/implement $(T)"

review: ## Conformance review of the current branch: make review T=<ticket>
	@$(CLAUDE) "/conformance-review $(T)"

retro: ## Retro on a past session, to improve the harness
	@$(CLAUDE) "/retro"

triage: ## Triage incoming issues from other people
	@$(CLAUDE) "/triage"

architecture: ## Look for architecture improvements
	@$(CLAUDE) "/improve-codebase-architecture"

##@ Team

protect-main: ## Require PRs, a code-owner review and green CI on main (needs gh)
	@repo=$$(gh repo view --json nameWithOwner -q .nameWithOwner) && \
	printf '%s' '{"required_status_checks":{"strict":true,"contexts":["harness-linux","harness-macos","secrets","verify","harness-guard"]},"enforce_admins":true,"required_pull_request_reviews":{"required_approving_review_count":1,"require_code_owner_reviews":true},"restrictions":null}' | \
	gh api -X PUT "repos/$$repo/branches/main/protection" --input - >/dev/null && \
	gh label create harness-change-approved -R "$$repo" --color B60205 -f \
	  --description "A maintainer reviewed this pull request's harness changes" >/dev/null && \
	echo "main is protected on $$repo; harness changes need the harness-change-approved label"

# >>> template-only (scripts/init.sh removes this block)
##@ Template

init: ## Turn this copy into a solo project
	@scripts/init.sh

init-team: ## Turn this copy into a team project: make init-team OWNER=@org/team
	@test -n "$(OWNER)" || { echo "usage: make init-team OWNER=@org/team"; exit 64; }
	@scripts/init.sh --owner $(OWNER)

init-plugin: ## Like init, but use the Claude Code plugin instead of vendored skills
	@scripts/init.sh --plugin $(if $(OWNER),--owner $(OWNER))

new-project: ## Create a project folder from this template: make new-project DEST=~/code/app [OWNER=@org/team]
	@test -n "$(DEST)" || { echo "usage: make new-project DEST=<folder> [OWNER=@org/team]"; exit 64; }
	@scripts/new-project.sh $(DEST) $(if $(OWNER),--owner $(OWNER))
# <<< template-only
