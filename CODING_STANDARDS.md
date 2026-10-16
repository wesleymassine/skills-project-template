# Coding standards

Judgement calls that no linter, type checker or test can enforce. Code reviewers read this file (the built-in code review, the `reviewer` subagent and human reviewers); `/retro` proposes additions to it.

**Before adding a rule, try to automate it.** A mechanical rule (a banned API, an import boundary, a file-location convention) becomes a lint rule, a type, a test or a CI job instead. This file is for what remains.

Keep each rule to one line, with the reason when it isn't obvious. Delete rules that stop catching anything.

## Rules

{{Add rules as reviews and retros reveal them. Examples of the kind of rule that belongs here:}}

- {{Errors carry the context needed to act on them: what failed and with which input, never only "something went wrong".}}
- {{A function that touches money, permissions or data deletion has a test for its failure path, not only the happy path.}}
