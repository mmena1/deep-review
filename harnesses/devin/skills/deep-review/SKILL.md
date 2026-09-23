---
name: deep-review
model: gpt-5-6-sol-medium
triggers:
  - user
description: Run a strict PR-gate review with parallel read-only scouts and independent hypothesis validation.
argument-hint: "[PR number | PR URL | branch | commit range]"
permissions:
  allow:
    - Read(/tmp/deep-review-context/**)
    - Read(/tmp/deep-review-runs/**)
    - Write(/tmp/deep-review-runs/**)
    - Exec(git diff)
    - Exec(git log)
    - Exec(git show)
    - Exec(git status)
---

# Deep Review for Devin

Read `protocol.md` completely, then execute that protocol with Devin's native subagent mechanism.

## Native orchestration

- Determine Devin's available concurrent subagent capacity before analysis. Stop with required and available counts when it is below the selected scout count.
- Launch every selected scout in one background wave. Use `code-reviewer` for `bugs`, `conventions`, `history`, and `docs`; pass the corresponding `reviewers/lenses/<slug>.md`. Use `code-reviewer-structural` for `structural`.
- Wait for the complete scout wave. Preserve completed scout evidence when one invocation fails and mark the run incomplete.
- When hypotheses survive deduplication, queue canonical hypotheses in `H1`, `H2`, … order and launch one `code-reviewer-validator-static` invocation per hypothesis using the maximum safe validator capacity. Refill a slot whenever an invocation finishes, including after failure or timeout, until every queued hypothesis has been attempted exactly once; static failures mark the run incomplete but do not stop queue drainage.
- After every static invocation has finished, verify the baseline and launch `code-reviewer-validator-probe` sequentially only when the static phase completed without failure; any static failure or timeout blocks the entire writable phase.
- Capture the Devin runtime identity/version and native role names for the shared runtime acceptance receipt. Mark only coordinator-observed paths as `PASS` or `FAIL`; leave every other row `NOT EXERCISED`.
- Never substitute the coordinator for a scout or validator and never change the user's global Devin concurrency configuration.

The adapter metadata provides native tool restrictions. The shared protocol owns target resolution, state meanings, failure behavior, reporting, publication, and cleanup.
