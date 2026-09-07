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
    - Exec(git worktree)
    - Exec(git reset)
    - Exec(git clean)
---

# Deep Review

Run one committed-target review: **gate**, **resolve**, **context**, **scout**, **deduplicate**, **validate**, **decide**, then publish only approved outcomes. The coordinator runs in the root session and never changes the caller checkout.

Read `references/review-protocol.md` before coordinating. It is the canonical state, schema, ID, dedupe, outcome, and invariant contract.

## Gate and resolve

1. Resolve the repository root with `git rev-parse --show-toplevel`; stop outside Git.
2. Resolve the target: current branch when omitted, otherwise PR, branch, or commit range. Stop for a detached omitted target or standalone commit/file target.
3. Require `git status --porcelain` to be empty only when the caller checkout overlaps the target. A different target excludes caller working-tree changes.
4. For a PR, capture repository, number, base, head ref, head SHA, state, diff, and merge ref. For branches/ranges, resolve base, head SHA, diff, and any associated open PR without replacing the requested target.
5. Echo target, base/head, publication eligibility, and review mode; obtain confirmation before fetching refs or creating workspaces.

## Context and one shared worktree

1. Select valuable scout dimensions and obtain confirmation.
2. Capture the immutable target-bound context snapshot with `manifest`, `core-manifest`, and one `reviewers/<scout>-manifest` per selected scout. Preserve existing provenance, size, privacy, tracked-instruction authority, and bounded selection rules. Do not create a validator manifest yet.
3. Create exactly one uniquely named coordinator-owned Git worktree under the run directory. Materialize the pinned target as the existing merge result: PR merge ref when available, otherwise the established fallback; for branches/ranges, merge head into base when clean or use resolved head otherwise. Leave the caller checkout untouched.
4. Record the exact baseline and verify it. All scouts receive the same worktree concurrently, plus the context root and their bounded manifests. Never create per-scout worktrees.

## Read-only scouting

Launch selected scout profiles in parallel. They may read/search repository files and use read-only Git inspection (`git diff`, `git log`, `git show`, `git status`). They emit only fixed-schema admission-qualified Hypotheses with reviewer-local IDs, potential severity, source evidence, impact, falsification condition, suggested validation, and context references. They do not modify files, create probes, run builds/tests/linters/typecheckers/scripts, assign final severity, or propose remediation.

Wait for every selected scout. Allow running scouts to finish after a failure so partial diagnostics are preserved, but any failure, timeout, or missing required context marks the review incomplete. An incomplete run cannot claim PASS/`No findings` or publish.

If every scout succeeds and emits zero hypotheses, do not create validator state. Report that all selected review dimensions completed and there was nothing to validate.

## Deduplicate and validate

After successful scouting, conservatively deduplicate hypotheses: merge only the same behavioral failure and materially same causal mechanism; preserve distinct evidence, origin slugs, and reviewer-local IDs. Assign canonical run-local IDs (`H1`, `H2`, …). If at least one survives, create exactly one late-bound `reviewers/validator-manifest` from the actual set and reuse it.

Invoke the validator sequentially once per canonical hypothesis, passing exactly one hypothesis each time and the same shared worktree. The validator tries to falsify first, uses static evidence when decisive, and runs the smallest focused check only when needed. It returns exactly one `Finding`, `Disproved`, or `Unresolved` and no unrelated issue.

Before the next invocation, preserve the outcome/evidence outside disposable state, restore the worktree to the exact recorded baseline, clean tracked/untracked/ignored artifacts as needed, and verify the baseline. Restoration failure stops validation, marks the run incomplete, and leaves later hypotheses explicitly not validated due to review failure. Validator failure preserves completed outcomes, marks unattempted hypotheses the same way, and blocks publication.

## Present, freshness, and publication

Use `references/output-template.md`. Report hypotheses discovered, hypotheses after dedupe, and outcome counts. Classify Findings by final severity × fix size into `fix-now`, `discuss`, and `follow-up`. Unresolved is separate, always `discuss`, and never a Finding. Do not expose scout provenance in normal Finding text.

Before presenting a result as current/actionable or publishing, re-check target freshness. If the PR head changed, report reviewed and current SHAs, mark the result stale, and require a rerun.

Use `references/pr-review-comments.md` for publication. Findings may be drafted as established defects. User-selected Unresolved items require explicit approval and must be questions describing evidence and remaining uncertainty. Preserve semantic anchors, payload validation, per-comment approval, privacy, and publication safeguards.

## Coordinator cleanup

After every exit path, preserve the final report and evidence, remove only the exact coordinator-created worktree with the narrowest Git worktree mechanism, verify its registration is gone, then remove the matching context snapshot and run directory only after preservation checks pass. Report exact leftovers if cleanup is interrupted.
