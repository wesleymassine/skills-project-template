# Skills guide

Quick reference: what each skill does, when to use it and what it produces. The process they fit into is `docs/workflow.md`.

**How to invoke:** type `/<name>` **inside the agent** (Claude Code, Codex, Copilot...), not in the shell. Typing `/` alone lists what is available. In plugin mode, Claude Code prefixes the names: `/mattpocock-skills:<name>`.

**Manual or automatic:** *manual* skills run only when you call them (`disable-model-invocation`). *Automatic* skills are also loaded by the agent on its own when the task matches their description.

**What they cost:** an automatic skill's name and description are in the agent's context in every session; a manual skill costs nothing until you call it. So add manual skills freely, keep automatic ones few, and keep every description short (under ~150 characters, leading with the words a request would contain). In Claude Code, `/skill-doctor` reports each skill's context cost and how often it is used; run it every few weeks and remove what nobody calls.

**Where they live:** `.agents/skills/` is the source, read natively by Codex, Copilot, Cursor and Gemini. `.claude/skills/` only holds symlinks to it, because Claude Code reads skills from there.

## Once per project

| Skill | Type | When | Produces |
|---|---|---|---|
| `/setup-matt-pocock-skills` | manual | right after creating the project, before the others | `docs/agents/` (issue tracker, labels, doc layout) and the "Agent skills" section in `AGENTS.md` |

For team work, pick **GitHub Issues** as the tracker. Local files (`.scratch/`) are only for solo work.

## Align and plan (per feature)

| Skill | Type | When | Produces |
|---|---|---|---|
| `/grill-with-docs` | manual | before any non-trivial change. A relentless interview about the plan | `GLOSSARY.md` and ADRs in `docs/adr/`, written as decisions settle |
| `grilling` | automatic | when you want an idea stress-tested; also called by grill-with-docs | the conversation only, no docs |
| `domain-modeling` | automatic | when discussing domain terms, editing the glossary or recording an ADR | `GLOSSARY.md`, `docs/adr/` |
| `/to-spec` | manual | after grilling. Synthesizes the conversation without a new interview, after confirming the test seams with you | the spec, published to the tracker |
| `/to-tickets` | manual | after the spec. Tracer-bullet vertical slices, each declaring what blocks it | one ticket per slice, in the tracker |
| `/triage` | manual | issues **other people** opened (bug reports, requests, external PRs). Recommends a category and state, applies nothing until you agree. Not for tickets from `/to-tickets` | agent-ready briefs, questions for the reporter, or closed issues with a reason |

## Implement (per ticket, in a fresh session)

| Skill | Type | When | Produces |
|---|---|---|---|
| `/implement` | manual | with a ticket reference. Uses `tdd` at the agreed seams, calls `code-review` at the end and commits to the current branch | code, tests, commit |
| `tdd` | automatic | red → green for a feature or a fix. Tests only at confirmed seams, through the public interface | tests that survive refactoring |
| `codebase-design` | automatic | when designing a module's interface, deciding where a seam goes or making code more testable | shared vocabulary: deep module, seam, adapter |
| `diagnosing-bugs` | automatic | something broken, throwing or slow. A disciplined loop, phase by phase | a proven cause and its fix |

## Review and deliver

| Skill | Type | When | Produces |
|---|---|---|---|
| `/simplify` | Claude Code built-in | before the review: cleanup without changing behavior | applied changes |
| `/code-review` | Claude Code built-in | defects in the diff. `/implement` already calls it | findings |
| `/conformance-review` | manual, from this template | at the end of a ticket: a reviewer that did not see the implementation checks the diff against the ticket, the ADRs and `REVIEW.md` | findings by severity |
| `/security-review` | Claude Code built-in | changes touching authentication, external input or secrets | security findings |
| `pr` | automatic | whenever the agent writes a pull request body | Summary, Evidence and Merge Danger (one-way or two-way door, blast radius), matching `.github/pull_request_template.md` |

Other agents have no `/simplify`, `/code-review` or `/security-review` built in. There, `implement` and `conformance-review` still work; use the agent's own review command, or add Matt Pocock's `code-review` (see below).

## Improve the harness

| Skill | Type | When | Produces |
|---|---|---|---|
| `/retro` | manual | at the end of a session that was harder than it should have been | proposed fixes to the environment: a pointer, an automated check, a `CODING_STANDARDS.md` rule. Nothing changes until you pick one |
| `/improve-codebase-architecture` | manual | every few weeks, or when a module keeps causing trouble | an HTML report of deepening opportunities, then a grilling on the one you pick |
| `writing-for-agents` | automatic | when creating or editing a skill, `AGENTS.md` or another file agents read | concise instructions that cost fewer tokens |

## Session and context

| Skill | Type | When | Produces |
|---|---|---|---|
| `/handoff` | manual | the session got long or you are switching windows | a handoff document for another session to continue |

## Outside the default set

- **Matt Pocock's `code-review`:** left out because its name collides with Claude Code's built-in `/code-review`. Outside Claude Code there is no collision: `npx skills add mattpocock/skills --skill code-review`.
- **Other Matt Pocock skills**, added per project when needed with `npx skills add mattpocock/skills --skill <name> --agent claude-code codex`:
  - `implement-spec`: lands a whole spec in one run, one subagent per ticket in parallel worktrees. Worth it for large specs with a real dependency graph; it spends many more tokens than `/implement` ticket by ticket.
  - `wayfinder`: plans work too big for one session as a map of decision tickets.
  - `wizard`: writes an interactive script for steps only a human can do (dashboards, credentials, CI secrets). Useful for onboarding to third-party services.
  - `prototype` and `research` collide with Claude Code built-ins of the same name, like `code-review`. Use them outside Claude Code, or through the plugin's namespaced names.
- **replica-skill and stack skills:** project scope only. See the README.

## Maintenance

The commands (`make skills-list`, `skills-find`, `skills-add`, `skills-update`, `skills-remove`, `skills-restore`, `skills-check`) are in `docs/cheatsheet.md`. They wrap the `skills` CLI, which needs Node 22.20+, and always install for both `claude-code` (the symlink in `.claude/skills/`) and `codex`.

**Testing a skill you write or change** (such as `conformance-review`): collect a few realistic prompts, run each in a fresh session with the skill on and again with it off, and compare. The `skill-creator` plugin (`/plugin install skill-creator@claude-plugins-official`) automates this with stored evals, blind A/B comparisons and description tuning.

**Muting a skill for yourself**, without editing it: `skillOverrides` in `.claude/settings.local.json`, for example `{"skillOverrides": {"triage": "off"}}`.

Third-party skills run with the agent's permissions: read the `SKILL.md` before adding one. `make skills-check` also validates every skill against the [Agent Skills specification](https://agentskills.io/specification): lowercase hyphenated names up to 64 characters matching the folder, descriptions up to 1,024 characters, `SKILL.md` under 500 lines, scripts in `scripts/` and long material in `references/`.
