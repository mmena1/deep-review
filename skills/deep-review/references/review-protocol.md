# Review Protocol

The public review state machine is:

`hypothesis → finding | disproved | unresolved`

The operational validation flow is:

`hypothesis → static adjudication → finding | disproved | unresolved | needs probe → writable probe → finding | disproved | unresolved`

`Needs probe` is an internal transitional state only and is never exposed in reports or publication.

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

The validator receives exactly one canonical hypothesis per invocation. Every hypothesis enters a concurrent static adjudication wave against the same pinned worktree under a read-only contract. A static invocation returns exactly one of:

- **Finding** — decisive static evidence independently establishes the hypothesis, including final severity and evidence of actual reachability and impact.
- **Disproved** — concrete static evidence such as an invariant, guard, contract, or test rejects the hypothesis. It is not user-visible.
- **Unresolved** — static adjudication cannot establish or reject the hypothesis and no meaningful writable check can settle it. It maps to `discuss`.
- **Needs probe** — static evidence cannot settle the hypothesis, but a bounded writable check can materially answer a specific unresolved factual question. It must include the unresolved question, why static evidence is insufficient, and the cheapest decisive check. This is an internal transition only.

After the complete static wave, the coordinator queues only `Needs probe` hypotheses for sequential writable validation, ordered by canonical hypothesis ID. Each writable invocation receives exactly one canonical hypothesis plus its unresolved question and proposed check, independently adjudicates the full hypothesis, and returns exactly one final `Finding`, `Disproved`, or `Unresolved` outcome.

Static validators may read/search repository files and use read-only Git inspection. They must not run builds, tests, linters, typecheckers, scripts, probes, package-manager commands, or other commands that can create filesystem artifacts. Writable probes use the existing exact-baseline restoration and contamination protections.

Every validator first tries to falsify, checks callers, guards, invariants, contracts, tests, configuration, instructions, and relevant context, and reports no unrelated issue. A hypothesis not attempted because of operational failure is **not validated due to review failure**, not Unresolved.

## Context capture and persisted run state

Context capture is deterministic protocol machinery, not a task for the model to reimplement during a run. Once an artifact has passed path, type, size, target-binding, and race checks, the coordinator copies it exactly once with the fixed direct `cp` filesystem operation (or the harness's byte-for-byte equivalent selected before the run). Every manifest references that existing snapshot entry; a manifest lookup never triggers another copy or rewrite. The operation must preserve bytes exactly and must not use model-authored writes to reconstruct contents or generate an ad-hoc executable capture script. Existing pre/post size and mtime checks, retry behavior, SHA-256 and metadata verification, provenance, privacy, size limits, and snapshot immutability remain mandatory.

The coordinator persists protocol state in one coordinator-owned `run-state.json` (or an equivalent single run-state record when the harness requires another serialization) rather than one file per pipeline stage. That state records the exact pinned baseline identity and restoration status; scout completion and provenance; canonical hypotheses, original IDs, origins, deduplication evidence, and context references; every completed validator outcome and evidence; incomplete-run and unattempted-hypothesis status; final report data; cleanup status; and, when publication occurs, the exact publication payload. The context snapshot remains separate because it is an immutable evidence bundle with manifests. A user-facing `final-report.md` may be preserved when useful, and a `publication-receipt.json` is created only when publication occurs and contains the exact payload together with its publication receipt. Separate intermediate files for scout output, canonical hypotheses, or individual validator outcomes are not created unless a concrete runtime constraint requires them and that constraint is recorded in the run state.

## Pipeline invariants

- All selected scouts inspect one pinned coordinator-owned worktree concurrently and read-only. Static validators later inspect that same disposable worktree concurrently under a read-only contract; writable probes receive access sequentially.
- Every deduplicated hypothesis enters the static adjudication wave, and no validator runs when successful scouting produces zero hypotheses.
- Exactly one late-bound `reviewers/validator-manifest` is created when hypotheses survive; it is derived from those hypotheses and reused for all static and writable invocations.
- The coordinator waits for the complete static wave, then verifies the shared worktree is still at the exact recorded pinned baseline before starting writable probes. Any unexpected contamination or baseline mismatch at this boundary marks the review incomplete and prevents writable probing.
- Only completed `Needs probe` outcomes enter the writable queue, ordered by canonical hypothesis ID. Before every writable probe, including the first, the coordinator restores, cleans, and verifies the exact recorded pinned baseline.
- Static validators never execute artifact-producing commands. A static-wave failure preserves completed outcomes, marks the review incomplete, and prevents writable probing for hypotheses without successful static adjudication.
- Once each context artifact passes validation, it is copied exactly once with the fixed direct `cp` operation or selected harness equivalent; manifests reference the existing snapshot entry, and the model does not reconstruct artifact contents or generate capture machinery during a run.
- Coordinator-owned protocol state is consolidated in one run state, including the exact publication payload when applicable, with final-report and publication-receipt artifacts created only under the conditions above.
- Once the coordinator-owned worktree and exact baseline are established, restoration authorization is obtained once for that exact path or encapsulated in a coordinator-only helper that rejects other paths; no blanket `git reset` or `git clean` permission is granted. The coordinator preserves each outcome and evidence outside probe state, automatically restores the exact pinned baseline, cleans tracked, untracked, and ignored artifacts only in that worktree, and verifies `HEAD`, the tree, and `git status` before the next invocation. Restoration failure stops validation and marks the run incomplete.
- Any scout, static validator, writable validator, or restoration failure makes the run incomplete, prevents PASS/`No findings`, and prevents publication. Unattempted hypotheses remain explicitly not validated due to review failure.
- A changed PR head makes the pinned result stale. Report reviewed and current SHAs, and rerun before current-gate use or publication.
- A Finding may be presented assertively. An Unresolved item may be published only with explicit approval and only as a question describing evidence and remaining uncertainty.
