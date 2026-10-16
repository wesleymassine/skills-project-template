# Cheat sheet

One page to keep open while you work: terminal commands, commands inside the agent, and the habits that keep token use low. The process behind them is in `docs/workflow.md`; what each skill does is in `docs/skills.md`.

## First day

```bash
make setup          # install pinned tools, check the machine
make                # list every command
make setup-skills   # once per repository: tracker, labels, domain docs
make grill          # start aligning on the first feature
```

## Terminal (`make`)

| Command | What it does |
|---|---|
| `make doctor` | checks git, jq, mise, gh, Claude Code, symlinks, plugin duplicates and the skill layout |
| `make test` | harness self-tests: hooks, skill layout, review script |
| `make verify` / `make verify-quick FILES="a b"` | full verification (as CI) / fast checks on some files |
| `make secrets` | scan the branch's new commits for secrets before pushing |
| `make harness-check` | protected harness paths this branch changes (they need a maintainer's approval label) |
| `make implement T=<ticket>` | opens Claude Code in a **fresh session** on that ticket |
| `make review T=<ticket>` | conformance review of the current branch |
| `make grill TOPIC="..."`, `make tickets SPEC=<spec>` | align on a feature, split a spec into tickets |
| `make retro`, `make triage`, `make architecture` | improve the harness, triage incoming issues, look for architecture fixes |
| `make protect-main` | team: PRs, a code-owner review and green CI required on `main` |

Skill management:

| Command | What it does |
|---|---|
| `make skills-list` | skills installed in this project |
| `make skills-find Q=react` | search the public catalog before writing your own |
| `make skills-add REPO=owner/repo SKILL="a b"` | add to `.agents/skills/`, symlink for Claude Code, record in `skills-lock.json` |
| `make skills-update` | update vendored skills; review the diff before committing |
| `make skills-remove SKILL=name` | remove one |
| `make skills-restore` | reinstall what `skills-lock.json` lists |
| `make skills-check` | check symlinks, lock and names |
| `make plugins` | plugins on this machine, to spot duplicated skills |

`make implement`, `make review` and the other agent targets open Claude Code. With another agent, open it and type the same `/command`.

## Inside the agent

Project workflow (any agent that reads `.agents/skills/`):

| Command | When |
|---|---|
| `/grill-with-docs` → `/to-spec` → `/to-tickets` | a new feature, in one session |
| `/implement <ticket>` | one ticket, in a fresh session |
| `/conformance-review <ticket>` | end of each ticket |
| `/handoff` | the session is long; continue in a fresh one |
| `/retro` | after a session that went worse than it should |
| `/triage` | issues other people opened |
| `/diagnosing-bugs` | something broken or slow (the agent also picks it up on its own) |

Claude Code built-ins worth knowing:

| Command | What it does |
|---|---|
| `/clear` | fresh context. Costs nothing; use it between unrelated tasks |
| `/rename` then `/resume` | name a session before clearing, come back to it later |
| `/compact <what to keep>` | summarize a long session, keeping what you name. It is itself a large request |
| `/context` | what is filling the context window |
| `/usage` | tokens and plan usage, with attribution to skills, subagents and MCP servers |
| `/model`, `/effort` | match the model and effort to the task |
| `/plan <task>` (or Shift+Tab) | plan before editing; the plan survives compaction |
| Esc, `/rewind` | stop a wrong direction early; go back to a checkpoint |
| `/btw <question>` | side question that doesn't enter the conversation |
| `/skills` | list skills; press `t` to sort by token cost |
| `/skill-doctor` | each skill's context cost and how often it is used |
| `/code-review`, `/simplify`, `/security-review` | review the diff, clean it up, check security |
| `/mcp` | disable MCP servers you aren't using |
| `/doctor` | diagnose installation, settings and instruction files |
| `/fewer-permission-prompts` | allowlist the read-only commands you keep approving |
| `/insights` | report on how you work, with friction points and suggestions |

## Saving tokens

Every message resends the whole conversation, so the size of the context is what you pay for. In order of impact:

1. **One task per session.** `/clear` (or `make implement T=...`) between unrelated tasks. A session left open all day makes even a one-line question expensive.
2. **Match the model to the job.** The strongest model at high effort for grilling, specs and hard bugs; a mid-tier model (Sonnet) for a well-written ticket. Lower `/effort` for simple tasks.
3. **Be specific.** "Add validation to `login()` in `auth.ts`" reads two files; "improve the auth code" reads twenty. Point to paths instead of pasting files.
4. **Plan big changes first** (`/plan`), and stop wrong directions early (Esc, `/rewind`). Rework is the most expensive token there is.
5. **Push noisy work to subagents.** Test runs, log reading and broad searches stay in the subagent; only the summary comes back.
6. **Keep always-loaded text small.** `AGENTS.md` under ~200 lines, app files 10–30 lines; procedures belong in skills, which load only when used.
7. **Few automatic skills, short descriptions.** Manual skills cost nothing until called; check with `/skill-doctor` every few weeks.
8. **Prefer CLIs to MCP servers** (`gh` over a GitHub MCP), and disable unused servers in `/mcp`.
9. **Mind the cache.** After a break longer than the prompt-cache lifetime (an hour on subscriptions, five minutes on API keys), the next message reprocesses the whole context. Coming back to a big session? Prefer `/handoff` and a fresh one.
10. **Let tools filter output.** A hook or script that returns only failing tests beats reading a 10,000-line log.

Sources: [Claude Code: manage costs](https://code.claude.com/docs/en/costs), [commands](https://code.claude.com/docs/en/commands), [skills](https://code.claude.com/docs/en/skills).
