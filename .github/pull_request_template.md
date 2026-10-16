<!-- The `pr` skill writes this body when an agent opens the PR. Keep the sections. -->

## Ticket

<!-- Path or link to the ticket and its parent spec. -->

## Summary

<!-- The smallest view that shows the change: pseudocode, a call tree, a file tree or a Mermaid diagram, with a sentence around it. The reviewer already has the diff. -->

## Evidence

<!-- Before and after: the test that failed and now passes, the output that changed, or a screenshot. -->

## Merge Danger

<!-- One-way door (hard to reverse: destructive migration, public API removal) or two-way door (cheap to reverse)? Blast radius: what breaks if this is wrong? -->

## Verification

- [ ] `scripts/verify.sh full` passed
- [ ] Code review done
- [ ] `/conformance-review` done; unfixed findings listed below, with the reason
- [ ] Owner documents (`GLOSSARY.md`, `docs/adr/`, `docs/`, `CODING_STANDARDS.md`) updated in this PR, if the change touched them

## Unfixed findings
