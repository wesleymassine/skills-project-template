# Development workflow

Owner of this project's process. `AGENTS.md` points here. What each skill does is in `docs/skills.md`.

## From problem to tickets (once per feature)

| Step | Command | Output |
|---|---|---|
| Align | `/grill-with-docs` | `GLOSSARY.md` and ADRs in `docs/adr/` |
| Specify | `/to-spec` | the spec, in the issue tracker |
| Split | `/to-tickets` | small tickets with their blocking edges |

The grill covers the **Engineering questions** in `docs/context.md` (security, data, observability, rollout, and the backend, frontend, mobile and test-pyramid questions that apply), not only what the user brings up. Answers that are not obvious become ADRs.

Use the strongest model at high effort here: mistakes cost the most at this stage.

## From ticket to pull request (a fresh session per ticket)

1. A new session (`/clear` or a new agent), on the ticket's branch.
2. `/implement <ticket>`. It uses `tdd` (red → green) at the agreed seams, runs a code review at the end and commits to the branch. In Claude Code, the Stop hook runs `scripts/verify.sh quick` after every turn.
3. `/simplify`, if the review found excess: cleanup without changing behavior.
4. `/conformance-review`: checks the change against the ticket, done by a reviewer that did not see the implementation. Fixes go in a new commit.
5. `scripts/verify.sh full`, then a pull request following the PR template.

The ticket that sets up the stack is the only one that edits `scripts/verify.sh`, and Claude Code asks you to approve that edit: the file is protected on purpose. Until it is configured, the Stop hook has nothing to run.

A well-written ticket does not need the strongest model. Switch up for ambiguous tickets or hard bugs (`diagnosing-bugs`).

## Incoming issues (teams)

Bug reports and requests from other people go through `/triage` before anyone implements them. It turns each one into an agent-ready brief, a question for the reporter, or a closed issue with a reason. Tickets created by `/to-tickets` skip triage: they are agent-ready already.

## Improving the harness

The harness gets better from real failures, not from guesses:

1. After a session that went worse than it should, run `/retro`. It proposes environment fixes, most severe first.
2. Prefer automation: a mistake a tool could catch becomes a lint rule, a type, a test or a CI job. Only judgement calls become a line in `CODING_STANDARDS.md`.
3. Every few weeks: `/improve-codebase-architecture` for the code, and `/skill-doctor` (Claude Code) for skills that cost context without being used.
4. A fix that helps more than one project goes back to the template.

## Working as a team

- **Tickets live in GitHub Issues**, not in `.scratch/`: choose that in `/setup-matt-pocock-skills`. Local files are only for solo work.
- **One branch and one pull request per ticket.** `main` is protected: changes land only through a PR with green CI.
- **CI is the guarantee, not the hooks.** Hooks help whoever uses Claude Code; CI runs `scripts/verify.sh full` for everyone, with or without an agent.
- **Pull requests follow `.github/pull_request_template.md`**: ticket, summary, evidence, merge danger, verification and unfixed review findings. The `pr` skill writes it in that shape.
- **What is shared goes in git; what is personal does not.** Personal settings go in `.claude/settings.local.json` (ignored); personal instructions go in your user-level file (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`).
- **Never add a `CLAUDE.md` or `CLAUDE.local.md` to the project.** When either exists, Claude Code stops reading `AGENTS.md`. If one is unavoidable, its first line must be `@AGENTS.md`.
- **Harness changes are approved on purpose.** `CODEOWNERS` asks the owner for a review, and the harness guard fails the pull request until a maintainer adds the `harness-change-approved` label. `make harness-check` shows what a branch touches before you open it. Agents are denied adding that label.

## Session hygiene (token cost)

One task per session, the right model for the job, specific requests, plans before big changes. The commands and the full list of habits are in `docs/cheatsheet.md`.

## Changing this workflow

A change to this workflow is a change to the harness (`.agents/skills/`, `.claude/`, `scripts/verify.sh`, `REVIEW.md`, `CODING_STANDARDS.md`). It gets its own task, never a ride along with a ticket.
