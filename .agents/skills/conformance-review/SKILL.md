---
name: conformance-review
description: Independent check that the current change delivers its ticket, by a fresh-context reviewer. Run at the end of each ticket.
license: MIT
compatibility: Needs git and bash. The reviewer subagent is defined for Claude Code; other agents run the review in a fresh session.
metadata:
  source: skills-project-template
  version: "1.0.0"
disable-model-invocation: true
arguments: [ticket]
allowed-tools: Bash(.agents/skills/conformance-review/scripts/diff.sh*)
---

Review whether the current change delivers what the ticket asks for. The review is done by a reviewer that did not see the implementation; you only prepare the material, hand it over and handle the findings.

## Steps

1. **Find the criteria.** They are in the ticket passed as `$ticket`, or the one in progress; `docs/agents/issue-tracker.md` says where tickets live. Without a ticket, ask the user for the criteria and save them to `.review/criteria-<date>.md`.
2. **Write the diff to a file** with `.agents/skills/conformance-review/scripts/diff.sh`. It covers everything since the branch left `main`, including uncommitted edits and new files, and prints the path of the diff. Pass another base branch as its argument if the project doesn't use `main`.
3. **Hand it to the reviewer**, with only two inputs: the diff path and the criteria path. Do not summarize the change or give an opinion on it: the value of the review is the clean context.
   - In Claude Code: the `reviewer` subagent (`.claude/agents/reviewer.md`).
   - In an agent with subagents but no `reviewer` definition: a new subagent, given the body of `.claude/agents/reviewer.md` as its instructions.
   - In an agent without subagents: stop and ask the user to open a fresh session and paste the reviewer instructions with both paths.
4. **Handle the findings.** Show the user the list as it came back. Fix the High and Medium findings the user approves, in a new commit. Unfixed findings go, with the reason, into the ticket and into the "Unfixed findings" section of the pull request.
5. **After the fixes**, run `scripts/verify.sh full`. Only then can the ticket be closed.
