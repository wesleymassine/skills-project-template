# Changelog

All notable changes to this template. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/):

- **major:** the harness contract changes (`scripts/verify.sh`, hook behavior, required CI checks) in a way projects must adapt to;
- **minor:** new harness features or skills;
- **patch:** fixes.

Projects record the version they were created from in `.template-version`. To bring a project up to date, read the entries between that version and the latest one.

## [Unreleased]

### Added

- **Setup:** `scripts/init.sh` creates a `mise.toml` with no tools and examples, and `make doctor` warns while it is missing, pins no tools, or is not trusted. Without it, local runs used the global mise config and CI the runner's preinstalled tools.
- **Verification:** `scripts/verify.sh` examples cover Go, Java, Node/TS, Python and Rust, and the `mise.toml` examples match.

### Changed

- **Team:** `make protect-main` now runs `scripts/protect-main.sh`, which creates a repository ruleset instead of classic branch protection. Admins may bypass review and CI through a pull request, so one person can merge a production fix; `docs/workflow.md` has the "Emergency merge" rules. It refuses to run for a non-admin, gives every `CODEOWNERS` team write access, warns about secret teams and CODEOWNERS errors, explains the private-repository plan limit, and removes a classic protection it replaces. Solo projects get the same ruleset without the approval.

### Fixed

- **Setup:** `make setup` printed "mise not found" when `mise install` failed (for example on an untrusted `mise.toml`).

## [0.1.0] - 2026-10-16

First release.

### Added

- **Process:** Matt Pocock's skills vendored in `.agents/skills/` with `skills-lock.json` (grill, spec, tickets, implement, TDD, diagnosis, domain modeling, handoff, retro, triage, pr, writing-for-agents, architecture review), symlinked for Claude Code.
- **Instructions:** agent-neutral `AGENTS.md` with task rules (every change belongs to a ticket, one branch per ticket, done only after conformance review and full verification) and compact instructions.
- **Owner documents:** `docs/context.md` with engineering questions, `docs/workflow.md`, `docs/skills.md`, `docs/cheatsheet.md`, `docs/monorepo.md`, `REVIEW.md`, `CODING_STANDARDS.md`.
- **Verification contract:** `scripts/verify.sh quick|full`, called by the Stop hook after every agent turn and by CI.
- **Claude Code adapter:** permissions (denied `.env` reads, force pushes, merges, self-approval of harness changes), Stop and PostToolUse hooks, the `reviewer` subagent.
- **Independent review:** the `conformance-review` skill and its diff script.
- **Harness guard:** a `pull_request_target` workflow that fails pull requests changing protected paths (`.github/harness-protected`) until a maintainer adds the `harness-change-approved` label.
- **CI:** harness self-tests on Linux and macOS, actionlint, secret scanning with gitleaks, full verification, Dependabot for actions, PR template, CODEOWNERS.
- **Setup:** `scripts/init.sh` (solo, team and plugin modes), `scripts/new-project.sh`, and a `Makefile` with setup, verification, skill management and agent shortcuts.
- **Self-tests:** hooks, skill layout and the Agent Skills specification, the review diff script, the secret scan, the harness guard, template versioning.
