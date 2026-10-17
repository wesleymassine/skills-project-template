# skills-project-template

A GitHub template for teams that build software with coding agents (Claude Code, Codex, Copilot, Cursor, Gemini) and want to keep engineering standards high.

It gives every project the same process and the same guardrails:

- **A process**, from [Matt Pocock's skills](https://github.com/mattpocock/skills): grill the idea → write a spec → split it into tickets → implement each ticket test-first.
- **A harness** around it: one owner per document, a verification gate the agent can't skip, an independent review against the ticket, and CI that enforces it all for humans and agents alike.

The template has no language or framework. Everything stack-specific goes through one script, `scripts/verify.sh`.

**Start here:** run `make` for every command, and keep [`docs/cheatsheet.md`](docs/cheatsheet.md) open: terminal commands, commands inside the agent, and token-saving habits on one page.

## Contents

- [Quick start: team](#quick-start-team)
- [Quick start: solo](#quick-start-solo)
- [Joining a project](#joining-a-project)
- [Daily workflow](#daily-workflow)
- [What's inside](#whats-inside)
- [Monorepos](#monorepos)
- [Agent support](#agent-support)
- [Vendored skills or plugin?](#vendored-skills-or-plugin)
- [Troubleshooting](#troubleshooting)
- [Maintaining and contributing](#maintaining-and-contributing)
- [Credits and license](#credits-and-license)

## Quick start: team

**Prerequisites:** `git`, `jq`, [mise](https://mise.jdx.dev), [`gh`](https://cli.github.com) (logged in) and at least one coding agent.

1. **Create the repository.** On this page, click **Use this template → Create a new repository**. Or, from the command line:
   ```bash
   gh repo create your-org/your-project --template wesleymassine/skills-project-template --private --clone
   cd your-project
   ```
2. **Initialize it** with the GitHub user or team that owns the process, and check the machine:
   ```bash
   make init-team OWNER=@your-org/your-team      # same as scripts/init.sh --owner @your-org/your-team
   git add -A && git commit -m "Initialize from skills-project-template" && git push
   make setup
   ```
   This fills in the placeholders, sets up `CODEOWNERS`, replaces this README with one for your project and removes the template's own files.
3. **Protect `main`**, so changes only land through a reviewed pull request with green CI: `make protect-main`. It runs:
   ```bash
   gh api -X PUT repos/your-org/your-project/branches/main/protection --input - <<'EOF'
   {
     "required_status_checks": { "strict": true, "contexts": ["harness-linux", "harness-macos", "secrets", "verify", "harness-guard"] },
     "enforce_admins": true,
     "required_pull_request_reviews": { "required_approving_review_count": 1, "require_code_owner_reviews": true },
     "restrictions": null
   }
   EOF
   ```
   Branch protection on private repositories needs a paid GitHub plan; on public ones it's free. `make protect-main` also creates the `harness-change-approved` label used by the harness guard.
4. **Set up the process:** `make setup-skills`, or type `/setup-matt-pocock-skills` inside your agent. Choose **GitHub Issues** as the issue tracker, so the whole team sees the specs and tickets.
5. **Describe the problem** in `docs/context.md`, then `make grill` (or `/grill-with-docs` inside the agent). It interviews you, including the engineering questions in `docs/context.md` (security, data, observability, backend, frontend, mobile, test pyramid), and writes `GLOSSARY.md` and the first ADRs in `docs/adr/`.
6. **Decide the stack** (record it as an ADR), pin it in `mise.toml` (`init.sh` creates it with no tools; run `mise trust` after editing it), and replace the TODOs in `scripts/verify.sh` with your commands. Until you do, the `verify` CI check fails on purpose and `make doctor` warns.

## Quick start: solo

Same as the team flow, minus the team parts:

```bash
gh repo create your-project --template wesleymassine/skills-project-template --private --clone
cd your-project
make init                  # no owner: no CODEOWNERS
git add -A && git commit -m "Initialize from skills-project-template"
make setup
```

Then steps 4–6 above. For `/setup-matt-pocock-skills`, local markdown files are fine as the tracker when you work alone.

Prefer to stay off GitHub for now? Clone this repository once and create projects from it locally: `make new-project DEST=~/code/your-project [OWNER=@org/team]`.

## Joining a project

Everything lives in the repository, so onboarding is short:

1. Install `git`, `jq`, [mise](https://mise.jdx.dev) and your agent. On Windows, run `git config --global core.symlinks true` before cloning.
2. Clone the repository and run `make setup`: it installs the pinned tools and checks the machine.
3. Open your agent in the project folder. Type `/` to check that the skills are listed.
4. Read [`docs/cheatsheet.md`](docs/cheatsheet.md) (commands and token habits), [`docs/workflow.md`](docs/workflow.md) (how the team works) and [`docs/skills.md`](docs/skills.md) (what each skill does).

## Daily workflow

The full version, including token-saving habits, is in [`docs/workflow.md`](docs/workflow.md).

| When | You run (inside the agent) | Result |
|---|---|---|
| New feature | `/grill-with-docs` | shared vocabulary and decisions, written down |
| | `/to-spec` | a spec in the tracker |
| | `/to-tickets` | small tickets with dependencies |
| Each ticket, fresh session and branch | `/implement <ticket>` (or `make implement T=<ticket>`) | test-first code, reviewed and committed |
| | `/conformance-review` | an independent check against the ticket |
| | `scripts/verify.sh full`, open a PR | CI and a teammate review it; the `pr` skill writes the body |
| Issues from other people | `/triage` | agent-ready briefs or questions for the reporter |
| After a hard session | `/retro` | proposed fixes to the harness, so it doesn't happen again |

Commands starting with `/` are typed **inside the agent**. Typed in a shell they fail with `no such file or directory`.

## What's inside

| Piece | Files | What it does |
|---|---|---|
| Instructions | `AGENTS.md` | the project's rules and the map of its documents |
| Owner documents | `docs/context.md`, `docs/workflow.md`, `docs/skills.md`, `docs/cheatsheet.md`, `docs/monorepo.md`, `GLOSSARY.md`, `docs/adr/` |
| Commands | `Makefile` | `make` lists setup, verification, skill management and agent shortcuts | each piece of information lives in exactly one place |
| Skills | `.agents/skills/`, `skills-lock.json` | the process, pinned and versioned with the code |
| Verification contract | `scripts/verify.sh` | `quick <files>` after every agent turn, `full` before a PR and in CI |
| Verification gate | `.claude/hooks/` | the agent can't end its turn while `verify.sh quick` fails (up to 3 retries) |
| Coding standards | `CODING_STANDARDS.md` | judgement-call rules for reviewers; `/retro` proposes new ones, mechanical rules become checks instead |
| Independent review | `.agents/skills/conformance-review/`, `.claude/agents/reviewer.md`, `REVIEW.md` | a fresh-context reviewer checks the change against the ticket |
| Permissions | `.claude/settings.json` | blocks reading `.env`, force pushes and merges; asks before harness edits |
| Team guarantee | `.github/workflows/ci.yml`, `pull_request_template.md`, `CODEOWNERS` | CI for everyone, a PR checklist, an owner for the harness |
| Self-tests | `scripts/test/` | hooks, skill layout, review script and secret scan, tested in CI on Linux and macOS |
| Harness guard | `.github/workflows/harness-guard.yml`, `.github/harness-protected`, `scripts/harness-guard.sh` | a pull request that changes CI, hooks, `verify.sh` or the review rules fails until a maintainer adds the `harness-change-approved` label; a new push removes it. Runs main's copy, never the pull request's code |
| Secret scanning | `scripts/secret-scan.sh` | gitleaks on every pull request and push (`make secrets` locally); a leak fails CI with the secret redacted |

Deliberately left out until a project needs them: approval pages for ticket plans, acceptance criteria frozen by hooks, issue-tracker and design-tool integrations over MCP, and a prompt hook that tells the agent to load skills on every message (it costs tokens without a matching gain).

## Monorepos

One repository with several apps works with the same template: a root `AGENTS.md` with the shared rules and the map of apps, plus a short `AGENTS.md` per app with only what differs there. Always start the agent from the repository root, because Claude Code does not inherit `.claude/settings.json` from parent folders. [`docs/monorepo.md`](docs/monorepo.md) covers the layout, a per-app `verify.sh`, CI per app, glossaries per domain and per-app ownership. A single-app project deletes that file.

## Agent support

The core is agent-neutral. Claude Code gets an extra adapter.

| Layer | Files | Read by |
|---|---|---|
| Instructions | `AGENTS.md` | Claude Code (v2.1.277+), Codex, Copilot, Cursor, Gemini and others |
| Skills | `.agents/skills/` ([Agent Skills](https://agentskills.io) format) | Codex, Copilot, Cursor, Gemini |
| Skills for Claude Code | `.claude/skills/`, symlinks into `.agents/skills/` | Claude Code |
| Verification, review checklist, CI | `scripts/verify.sh`, `REVIEW.md`, `.github/` | every agent, and humans |
| Claude Code adapter | `.claude/settings.json`, `.claude/hooks/`, `.claude/agents/` | Claude Code only |

Without Claude Code you lose the end-of-turn gate (CI still enforces `verify.sh full`), the permission rules and the built-in `/code-review`, `/simplify` and `/security-review`. `conformance-review` explains how to run the review without the `reviewer` subagent.

## Vendored skills or plugin?

| | Vendored (default) | Plugin (`init.sh --plugin`) |
|---|---|---|
| Where | `.agents/skills/` in git, pinned by `skills-lock.json` | installed per machine |
| Agents | all of them | Claude Code only |
| Updates | `npx skills update`, reviewed like any diff | automatic |
| Editable | yes | no |
| Names | `/tdd`, `/to-spec` | `/mattpocock-skills:tdd` |
| Use for | teams, multiple agents, adapted skills | solo experiments and prototypes |

Never both in one project, or every skill shows up twice. Vendored projects switch the plugin off in `.claude/settings.json`.

Matt Pocock's `code-review` skill is left out on purpose: its name collides with Claude Code's built-in `/code-review`. Skills for one kind of project (a stack, a domain) are added to that project only: `npx skills add <repo> --skill <name> --agent claude-code codex`. See [`docs/skills.md`](docs/skills.md).

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `zsh: no such file or directory: /grill-with-docs` | Slash commands go inside the agent, not the shell. Start `claude` (or your agent) first. |
| Every skill appears twice (`tdd` and `mattpocock-skills:tdd`) | The plugin is installed on your machine. `claude plugin list` shows its id; add it to `enabledPlugins` as `false` in `.claude/settings.json`. The template covers `@claude-plugins-official` and `@synced`. |
| Claude Code ignores `AGENTS.md` | A `CLAUDE.md` or `CLAUDE.local.md` exists in the project or a parent folder. Remove it, or make its first line `@AGENTS.md`. Also requires Claude Code v2.1.277+. |
| Skills missing in Claude Code on Windows | Symlinks were checked out as text files. `git config core.symlinks true`, then re-clone. `scripts/test/layout.test.sh` detects it. |
| `npx skills` fails with a syntax error | The `skills` CLI needs Node 22.20+: `mise exec node@22 -- npx skills ...` |
| The agent keeps getting blocked at the end of a turn | `verify.sh quick` is failing on the files it edited; the message says why. After 3 attempts the gate lets go and warns you. |
| An app's rules are ignored in a monorepo | The session was started inside the app folder, or the app has a `CLAUDE.md`. Start from the root; `layout.test.sh` flags stray `CLAUDE.md` files and apps without `AGENTS.md`. |
| `harness-guard` fails on a pull request | It changes a protected path (`make harness-check` lists them). A maintainer reviews those files and adds the `harness-change-approved` label. Extend `.github/harness-protected` with the files your `verify.sh` depends on. |
| The `verify` CI check fails on a new project | `scripts/verify.sh full` still has its TODOs. Fill them in once the stack is decided. |
| `mise install` fails with "not trusted" | A new or changed `mise.toml` must be trusted once per machine: `mise trust`. |

## Maintaining and contributing

- Run the self-tests: `make test`.
- **Releasing a version:** add an entry to `CHANGELOG.md`, set the same number in `TEMPLATE_VERSION` (the self-tests fail when they differ), commit, then `git tag -a vX.Y.Z -m vX.Y.Z` and push with `--tags`. Projects record their starting version in `.template-version`; the changelog entries after it are what they need to bring over.
- Update the vendored skills: `make skills-update`, review the diff, commit. Projects created earlier update on their own schedule.
- Changing `conformance-review` or adding a skill of your own: test it with and without the skill in fresh sessions, or with the `skill-creator` plugin's evals (see [`docs/skills.md`](docs/skills.md)).
- Issues and pull requests are welcome. Keep the core agent-neutral, and put anything agent-specific in that agent's adapter folder.

## Credits and license

- The skills in `.agents/skills/` (except `conformance-review`) are by [Matt Pocock](https://github.com/mattpocock/skills), MIT. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
- Everything else: [MIT](LICENSE).
