# Runtime Acceptance Matrix

Static checks cannot prove multi-agent orchestration. Every real review therefore emits a passive receipt in its run state and final report with the harness identity/version, reviewed adapter commit, selected roles, and observed result for every row. Use `PASS`, `FAIL`, or `NOT EXERCISED`; unobserved behavior is never a pass.

| Scenario | Devin expected result | Codex expected result |
| --- | --- | --- |
| Zero hypotheses | No validator launches; report says all selected dimensions completed with nothing to validate | Same |
| Surviving hypotheses | Independent static validator launches for every canonical hypothesis | Same |
| Multiple selected scouts | Every selected scout starts in one simultaneous wave | Same |
| Insufficient scout capacity | Review stops before launching any scout and reports required versus available capacity | Same |
| Validator uses probes | Static wave completes first; baseline is verified, then restored before every sequential writable probe | Same |
| One scout fails | Running scouts may finish; run becomes incomplete and cannot publish or claim PASS/`No findings` | Same |
| Validator fails partway | Completed outcomes remain; unattempted hypotheses are not validated due to review failure; run is incomplete | Same |
| PR head changes | Reviewed and current SHAs are reported; result is stale and publication is blocked | Same |
| Cleanup | Only the current run's worktree, context snapshot, and run directory are removed | Same |

Normal reviews exercise only paths they encounter. Keep rare failures and transitions `NOT EXERCISED` until natural execution or a targeted smoke run observes them; never perturb a real review solely to fill the matrix. After changes to wrappers, permissions, custom-agent metadata, or orchestration language, targeted Devin and Codex smoke runs remain required for important gaps not covered by passive receipts.

Cross-harness acceptance passes only when collected receipts and targeted smoke evidence show both harnesses preserve the protocol's state meanings, failure behavior, publication safeguards, and single-worktree invariant. Different hypotheses or wording across harnesses are expected and do not fail behavioral equivalence.
