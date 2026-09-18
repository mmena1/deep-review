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
- When hypotheses survive deduplication, spawn `deep_review_validator_static` once per canonical hypothesis in one concurrent wave.
- After the complete static wave and baseline verification, spawn `deep_review_validator_probe` sequentially for successful `Needs probe` outcomes only.
- Never substitute the coordinator or a built-in generic agent for a required deep-review role. Never edit the user's global Codex concurrency settings.

The custom agent files provide native model, reasoning, and sandbox metadata. The shared protocol owns target resolution, state meanings, failure behavior, reporting, publication, and cleanup.
