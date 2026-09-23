---
name: deep-review
description: Run a strict PR-gate review with simultaneous read-only scouts and independent hypothesis validation. Use for committed PR, branch, or commit-range review; not for uncommitted working-tree review.
---

# Deep Review for Codex

Read `protocol.md` completely, then execute that protocol with Codex subagents and the installed custom agents.

## Native orchestration

- Inspect the active Codex subagent capacity before analysis. Stop with required and available counts when `agents.max_concurrent_threads_per_session` or the current runtime cannot launch the complete selected scout set simultaneously.
- Spawn every selected scout in one concurrent wave. Use `deep_review_scout` for `bugs`, `conventions`, `history`, and `docs`; pass the corresponding `reviewers/lenses/<slug>.md`. Use `deep_review_structural` for `structural`.
- Wait for the complete scout wave. Preserve completed scout evidence when one invocation fails and mark the run incomplete.
- When hypotheses survive deduplication, queue canonical hypotheses in `H1`, `H2`, … order and spawn one `deep_review_validator_static` invocation per hypothesis using the maximum safe validator capacity. Refill a slot whenever an invocation finishes, including after failure or timeout, until every queued hypothesis has been attempted exactly once; static failures mark the run incomplete but do not stop queue drainage.
- After every static invocation has finished, verify the baseline and spawn `deep_review_validator_probe` sequentially only when the static phase completed without failure; any static failure or timeout blocks the entire writable phase.
- Capture the Codex runtime identity/version and native agent types for the shared runtime acceptance receipt. Mark only coordinator-observed paths as `PASS` or `FAIL`; leave every other row `NOT EXERCISED`.
- Never substitute the coordinator or a built-in generic agent for a required deep-review role. Never edit the user's global Codex concurrency settings.

The custom agent files provide native model, reasoning, and sandbox metadata. The shared protocol owns target resolution, state meanings, failure behavior, reporting, publication, and cleanup.
