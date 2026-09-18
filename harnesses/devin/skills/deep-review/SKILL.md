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
- When hypotheses survive deduplication, launch `code-reviewer-validator-static` once per canonical hypothesis in one concurrent read-only wave.
- After the complete static wave and baseline verification, launch `code-reviewer-validator-probe` sequentially for successful `Needs probe` outcomes only.
- Never substitute the coordinator for a scout or validator and never change the user's global Devin concurrency configuration.

The adapter metadata provides native tool restrictions. The shared protocol owns target resolution, state meanings, failure behavior, reporting, publication, and cleanup.
