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

# Deep Review

Run one committed-target review: **gate**, **resolve**, **context**, **scout**, **deduplicate**, **validate**, **decide**, then publish only approved outcomes. The coordinator runs in the root session and never changes the caller checkout.

Read `references/review-protocol.md` before coordinating. It is the canonical state, schema, ID, dedupe, outcome, and invariant contract.

## Gate and resolve

1. Resolve the repository root with `git rev-parse --show-toplevel`; stop outside Git.
2. Resolve the target: current branch when omitted, otherwise PR, branch, or commit range. Stop for a detached omitted target or standalone commit/file target.
3. Define overlap explicitly: an omitted/current-branch target, an explicitly named current branch, or a PR whose source branch is the caller's current branch overlaps the caller checkout. Require `git status --porcelain` to be empty only in those cases; a different target excludes caller working-tree changes.
4. For a PR, capture repository, number, base, head ref, head SHA, state, diff, and merge ref. For branches/ranges, resolve base, head SHA, diff, and any associated open PR without replacing the requested target. A branch or range without a unique open PR is local and non-posting; require an explicit PR number or URL before publication.
5. Echo target, base/head, associated PR or lack of one, publication eligibility, and review mode; obtain confirmation before fetching refs or creating workspaces.

## Context and one shared worktree

1. Classify the target as production source, tests, docs, config/build, or other. Recommend only valuable scout dimensions, explain each inclusion and exclusion, and present the complete catalog:
   - `bugs` — bug and test-coverage review of executable code or behavior-bearing configuration (`code-reviewer`).
   - `structural` — structural maintainability review of changed production logic or control flow (`code-reviewer-structural`).
   - `conventions` — project conventions and standards review for most changes (`code-reviewer`).
   - `history` — regression-risk review using relevant commit history for modified code or configuration (`code-reviewer`).
   - `docs` — accuracy review of changed comments, TODOs, documentation, and behavior claims (`code-reviewer`).
2. Ask the user to confirm the recommended dimensions or provide a non-empty comma-separated set of catalog slugs. If the user supplies an empty or unrecognized set, offer to end the review rather than silently changing the selection.
3. Capture the immutable target-bound context snapshot with `manifest`, `core-manifest`, and one `reviewers/<scout>-manifest` per selected scout. Apply each in-scope `deep-review-context` declaration from the governing tracked instruction chain only when it names one exact relative path or bounded glob using `required:` or `optional-glob:`; active-work references and selected-artifact references must be explicit relative paths. Preserve repository-relative source path, bundle path, target-binding reasons, repository identity, base/head SHAs, capture metadata, SHA-256, size, required/optional status, and selection reasons in canonical provenance. Accept regular files only; reject symlinks, special files, traversal, external paths, and normalized collisions. Limit artifacts to 2 MiB and the bundle to 16 MiB, check size/mtime before and after copying with one retry, stop on required failures, omit optional failures with a warning, and create an explicit empty bundle when nothing is selected. After each artifact passes validation, copy it exactly once with the fixed direct `cp` filesystem operation or the harness's byte-for-byte equivalent selected before the run; manifests reference the existing snapshot entry and never trigger another copy or rewrite. Never reconstruct contents with model-authored writes or generate a per-run capture script. The snapshot is immutable and read-only after capture. Do not create a validator manifest yet.
4. Create exactly one uniquely named coordinator-owned Git worktree under the run directory. Materialize the pinned target as the existing merge result: PR merge ref when available, otherwise the established fallback; for branches/ranges, merge head into base when clean or use resolved head otherwise. Leave the caller checkout untouched.
5. Record the exact baseline and verify it. All scouts receive the same worktree concurrently, plus the context root and their bounded manifests. Never create per-scout worktrees. Request narrowly scoped approval for the exact `git worktree add` operation and its coordinator-owned path; do not pre-authorize destructive Git commands globally.

## Read-only scouting

Launch selected scout profiles in parallel. They may read/search repository files and use read-only Git inspection (`git diff`, `git log`, `git show`, `git status`). They emit only fixed-schema admission-qualified Hypotheses with reviewer-local IDs, potential severity, source evidence, impact, falsification condition, suggested validation, and context references. They do not modify files, create probes, run builds/tests/linters/typecheckers/scripts, assign final severity, or propose remediation.

Wait for every selected scout. Allow running scouts to finish after a failure so partial diagnostics are preserved, but any failure, timeout, or missing required context marks the review incomplete. An incomplete run cannot claim PASS/`No findings` or publish.

If every scout succeeds and emits zero hypotheses, do not create validator state. Report that all selected review dimensions completed and there was nothing to validate.

## Deduplicate and validate

After successful scouting, conservatively deduplicate hypotheses: merge only the same behavioral failure and materially same causal mechanism; preserve distinct evidence, origin slugs, and reviewer-local IDs. Assign canonical run-local IDs (`H1`, `H2`, …). If at least one survives, create exactly one late-bound `reviewers/validator-manifest` from the actual set and reuse it for every static and writable invocation.

First launch one static validator invocation per canonical hypothesis concurrently against the same pinned worktree under a read-only contract. Each invocation receives exactly one hypothesis and returns `Finding`, `Disproved`, `Unresolved`, or the internal `Needs probe` transition using the exact schemas defined in `agents/code-reviewer-validator/AGENT.md`. Static validators must not run builds, tests, linters, typecheckers, scripts, probes, package-manager commands, or other artifact-producing commands. Wait for the entire static wave before proceeding.

Build a deterministic writable queue only from successful `Needs probe` outcomes, ordered by canonical hypothesis ID. Invoke those probes sequentially against the same shared worktree, passing exactly one hypothesis plus its unresolved factual question and cheapest decisive check. The writable validator independently returns exactly one final `Finding`, `Disproved`, or `Unresolved`; `Needs probe` must never appear in user-facing reporting or publication. Static-wave failures preserve completed outcomes, mark the review incomplete, and do not enqueue hypotheses without successful static adjudication.

Once the coordinator-owned worktree and its recorded baseline are established, obtain one narrowly scoped authorization for automatic restoration of that exact worktree, or encapsulate restoration behind a coordinator-only helper that refuses any other path. Do not add blanket `git reset` or `git clean` permissions. After each writable probe, preserve the outcome/evidence in the single coordinator-owned run state before touching disposable probe state, automatically run the authorized restoration against the recorded baseline, clean tracked/untracked/ignored artifacts only in that worktree, and verify `HEAD`, the tree, and `git status` before continuing. Restoration failure stops validation, marks the run incomplete, and leaves later hypotheses explicitly not validated due to review failure. Validator failure preserves completed outcomes, marks unattempted hypotheses the same way, and blocks publication.

## Present, freshness, and publication

Use `references/output-template.md`. Report hypotheses discovered, hypotheses after dedupe, and outcome counts. Apply the deterministic action policy: every Finding with a small, unambiguous fix of about 20 changed lines or fewer is `fix-now`; every Finding with a larger or cross-module fix is `follow-up`; every Unresolved outcome is separate and always `discuss`. Do not expose scout provenance in normal Finding text.

Before presenting a result as current/actionable or publishing, re-check target freshness. If the PR head changed, report reviewed and current SHAs, mark the result stale, and require a rerun.

Use `references/pr-review-comments.md` for publication. Findings may be drafted as established defects. User-selected Unresolved items require explicit approval and must be questions describing evidence and remaining uncertainty. Preserve semantic anchors, payload validation, per-comment approval, privacy, and publication safeguards.

## Coordinator cleanup

After every exit path, preserve the final report and evidence, request narrowly scoped approval for the exact coordinator-created worktree cleanup path, remove only that worktree with the narrowest Git worktree mechanism, verify its registration is gone, then remove the matching context snapshot and run directory only after preservation checks pass. Report exact leftovers if cleanup is interrupted.
