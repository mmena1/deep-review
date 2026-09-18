# Runtime Acceptance Matrix

Static checks cannot prove multi-agent orchestration. Run these manual smoke tests after changes to wrappers, permissions, custom-agent metadata, or orchestration language. Record the harness version, reviewed commit, selected roles, and observed result.

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

The smoke test passes only when both harnesses preserve the protocol's state meanings, failure behavior, publication safeguards, and single-worktree invariant. Different hypotheses or wording across harnesses are expected and do not fail behavioral equivalence.
