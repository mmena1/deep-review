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

## Context capture and persisted run state

Context capture is deterministic protocol machinery, not a task for the model to reimplement during a run. Once an artifact has passed path, type, size, target-binding, and race checks, the coordinator copies its bytes with a stable coordinator/harness filesystem primitive or a fixed predetermined copy operation. The operation must preserve bytes exactly and must not use model-authored writes to reconstruct contents or generate an ad-hoc executable capture script. Existing pre/post size and mtime checks, retry behavior, SHA-256 and metadata verification, provenance, privacy, size limits, and snapshot immutability remain mandatory.

The coordinator persists protocol state in one coordinator-owned `run-state.json` (or an equivalent single run-state record when the harness requires another serialization) rather than one file per pipeline stage. That state records the exact pinned baseline identity and restoration status; scout completion and provenance; canonical hypotheses, original IDs, origins, deduplication evidence, and context references; every completed validator outcome and evidence; incomplete-run and unattempted-hypothesis status; final report data; and cleanup status. The context snapshot remains separate because it is an immutable evidence bundle with manifests. A user-facing `final-report.md` may be preserved when useful, and a `publication-receipt.json` is created only when publication occurs. Separate intermediate files for scout output, canonical hypotheses, or individual validator outcomes are not created unless a concrete runtime constraint requires them and that constraint is recorded in the run state.

## Pipeline invariants

- All selected scouts inspect one pinned coordinator-owned worktree concurrently and read-only. The validator later receives writable access to that same disposable worktree.
- The validator runs for every deduplicated hypothesis, and never runs when successful scouting produces zero hypotheses.
- Exactly one late-bound `reviewers/validator-manifest` is created when hypotheses survive; it is derived from those hypotheses and reused for sequential adjudications.
- Once each context artifact passes validation, its bytes are captured mechanically; the model does not reconstruct artifact contents or generate capture machinery during a run.
- Coordinator-owned protocol state is consolidated in one run state, with final-report and publication-receipt artifacts created only under the conditions above.
- Once the coordinator-owned worktree and exact baseline are established, restoration authorization is obtained once for that exact path or encapsulated in a coordinator-only helper that rejects other paths; no blanket `git reset` or `git clean` permission is granted. The coordinator preserves each outcome and evidence outside probe state, automatically restores the exact pinned baseline, cleans tracked, untracked, and ignored artifacts only in that worktree, and verifies `HEAD`, the tree, and `git status` before the next invocation. Restoration failure stops validation and marks the run incomplete.
- Any scout or validator failure makes the run incomplete, prevents PASS/`No findings`, and prevents publication. Unattempted hypotheses remain explicitly not validated due to review failure.
- A changed PR head makes the pinned result stale. Report reviewed and current SHAs, and rerun before current-gate use or publication.
- A Finding may be presented assertively. An Unresolved item may be published only with explicit approval and only as a question describing evidence and remaining uncertainty.
