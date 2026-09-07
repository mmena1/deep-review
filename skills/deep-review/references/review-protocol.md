# Review Protocol

The active review state machine is:

`hypothesis → validator → finding | disproved | unresolved`

## Hypotheses

A **Hypothesis** is an admission-qualified concern about the committed target awaiting independent adjudication. A scout emits either hypotheses or no hypotheses; it does not settle them.

Each hypothesis uses this Markdown shape:

```markdown
### Hypothesis <reviewer-slug>-H<number>
- **Origin:** <reviewer slug>
- **Title:** <concise behavioral concern>
- **File/line:** <repository-relative path>:<line>
- **Potential severity:** blocker | high | medium | low
- **Source evidence:** <concrete changed-code or behavior-path evidence>
- **Expected impact:** <reachable consequence>
- **Falsification condition:** <specific evidence that would reject the concern>
- **Suggested validation:** <cheapest decision-relevant check; no remediation>
- **Context references:** <relevant manifest entries, or none>
```

A hypothesis must be grounded in changed code or a changed behavior-bearing path, identify a plausible consequence, and state how it could be falsified. Discarded or internal speculation is not emitted. Scout severity is only potential severity.

Scouts assign reviewer-local IDs such as `bugs-H1` or `structural-H1`. After deduplication, the coordinator assigns canonical run-local IDs (`H1`, `H2`, …). Canonical IDs are stable for that run; the coordinator retains every original ID and origin slug for provenance.

## Deduplication

The coordinator merges hypotheses only when they describe the same behavioral failure and materially the same causal mechanism. Similar titles or the same file/line are signals, not sufficient keys. Merged hypotheses retain all materially distinct evidence and all origin slugs. When equivalence is uncertain, keep hypotheses separate and validate both.

## Validation outcomes

The validator receives exactly one canonical hypothesis per invocation and returns exactly one outcome:

- **Finding** — the validator independently establishes the hypothesis through decisive static evidence or the smallest targeted check. Finding includes final severity and evidence of actual reachability and impact. The bare term carries the independent-validation guarantee.
- **Disproved** — a concrete invariant, guard, contract, test, or other evidence rejects the hypothesis. It is not user-visible.
- **Unresolved** — bounded validation cannot establish or reject the hypothesis. It is not a Finding and maps to `discuss`.

The validator first tries to falsify, checks callers, guards, invariants, contracts, tests, configuration, instructions, and relevant context, and uses a focused probe only when static reasoning cannot settle the claim. It reports no unrelated discoveries, and assigns final severity only for a Finding. A hypothesis not attempted because of operational failure is **not validated due to review failure**, not Unresolved.

## Pipeline invariants

- All selected scouts inspect one pinned coordinator-owned worktree concurrently and read-only. The validator later receives writable access to that same disposable worktree.
- The validator runs for every deduplicated hypothesis, and never runs when successful scouting produces zero hypotheses.
- Exactly one late-bound `reviewers/validator-manifest` is created when hypotheses survive; it is derived from those hypotheses and reused for sequential adjudications.
- The coordinator preserves each outcome and evidence outside probe state, restores the exact pinned baseline, cleans tracked, untracked, and ignored artifacts, and verifies the baseline before the next invocation. Restoration failure stops validation and marks the run incomplete.
- Any scout or validator failure makes the run incomplete, prevents PASS/`No findings`, and prevents publication. Unattempted hypotheses remain explicitly not validated due to review failure.
- A changed PR head makes the pinned result stale. Report reviewed and current SHAs, and rerun before current-gate use or publication.
- A Finding may be presented assertively. An Unresolved item may be published only with explicit approval and only as a question describing evidence and remaining uncertainty.
