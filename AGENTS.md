# AGENTS.md — {{NAME}}

{{One or two sentences: what the project does and for whom.}}

## Owner documents

- `docs/context.md`: the problem, verified facts and open questions.
- `docs/workflow.md`: the development workflow, from grilling to pull request.
- `docs/skills.md`: the skills guide (what each does, when to use it, maintenance).
- `docs/cheatsheet.md`: commands (terminal and inside the agent) and token-saving habits.
- `docs/monorepo.md`: how the repository is split into apps (monorepo only).
- `GLOSSARY.md`: domain vocabulary, maintained through `/grill-with-docs`.
- `docs/adr/`: architecture decisions, one per file.
- `CODING_STANDARDS.md`: judgement-call coding rules that reviewers enforce.
- `REVIEW.md`: what the conformance review checks.

Each piece of information has exactly one owner. Other files point to it instead of repeating it.

## Apps

{{Single app: delete this section and docs/monorepo.md. Monorepo: one line per app, as `apps/<name>/`: what it is. Details in docs/monorepo.md.}}

Before changing anything under `apps/<name>/`, read `apps/<name>/AGENTS.md`. Start the agent from the repository root, never from inside an app.

## Stack and commands

{{Language, version (pinned in mise.toml) and main libraries, with the ADR that decided them.}}

Verification always goes through `scripts/verify.sh quick <files>` and `scripts/verify.sh full`.

## Working on a task

- Every code change belongs to a ticket. A request without one: find the ticket that owns it and confirm with the user before starting; if none exists, propose `/grill-with-docs` instead of coding.
- One branch per ticket (`t<NN>-<slug>`). Never commit to `main`.
- A ticket is done only after `/conformance-review` and `scripts/verify.sh full`, in that order.

## Compact instructions

When compacting, keep: the ticket in progress and its acceptance criteria, decisions taken in this session, the files changed, and the latest failing test or verify output.

## Rules

- Never read or write `.env`. Credentials come from environment variables.
- Code, identifiers, docs and commits in English, unless this file says otherwise for the domain or the UI.
- Harness files (`.agents/skills/`, `.claude/`, `scripts/verify.sh`, `REVIEW.md`, `CODING_STANDARDS.md`) only change when the task is about the harness.
