---
name: deep-review
model: gpt-5-6-sol-medium
triggers:
  - user
description: Run a strict PR-gate review with isolated parallel reviewers and targeted validation.
argument-hint: "[PR number | PR URL | branch | commit range]"
permissions:
  allow:
    - Read(/tmp/deep-review-runs/**)
    - Write(/tmp/deep-review-runs/**)
    - Exec(git diff)
    - Exec(git log)
    - Exec(git show)
    - Exec(git status)
---

# Deep Review

Run one committed-target review predictably: **gate**, **resolve**, **analyze**, **settle**, **decide**, then publish only approved comments. This skill runs in the root session because it coordinates target resolution, reviewer worktrees, validation, publication, and cleanup. It never changes the caller's current branch or checkout.

## 1. Gate the caller repository

Before resolving a target, asking for confirmation, creating a worktree, or launching a subagent:

1. Resolve the caller repository root with `git rev-parse --show-toplevel`. Stop if the caller is not inside a Git repository.
2. Run `git -C <caller-root> status --porcelain`. Require no output. This rejects staged, unstaged, deleted, renamed, and untracked non-ignored files; ignored files remain exempt.
3. Explain that this is a PR-gate review and stop with a clear message if the tree is not clean. Do not fall back to reviewing working-tree changes.

The gate applies to every invocation, including explicit PR identifiers, branches, and commit ranges. This initial result remains valid if the caller checkout changes later, because all reviewers use isolated worktrees.

Complete when the caller root is recorded and a clean `git status --porcelain` result has been recorded for this invocation, or the invocation has been rejected.

## 2. Resolve the committed target

1. Require an argument containing a PR number/URL, branch, or commit range. Do not auto-detect working-tree changes. Do not accept a standalone commit or ad-hoc file paths as review targets; ask for the containing branch, range, or PR instead.
2. For a PR, collect its number, repository, base ref, head ref, head SHA, state, and diff. For a branch or commit range, resolve its base, head SHA, and diff; look up an associated open PR without substituting it for the supplied target.
3. Echo the resolved target, base, head, associated PR (or lack of one), and review mode. Ask the user to confirm before fetching refs or creating review workspaces.
4. A branch or commit range with no unique open PR is a local, non-posting review. Require an explicit PR number/URL before publishing comments.

Complete when the confirmed committed target, diff, base/head, and publication eligibility are recorded.

## 3. Choose reviewers and create isolated workspaces

1. Classify the target as production source, tests, docs, config/build, or other. Recommend only valuable reviewers, explain each inclusion and exclusion, and present the full catalog:
   - `bugs` — Bug and test coverage: executable code or behavior-bearing configuration.
   - `structural` — Structural maintainability: changed production logic or control flow.
   - `conventions` — Conventions: most changes.
   - `history` — History: modified code/config with regression-relevant history.
   - `docs` — Comments and docs: changed comments, TODOs, or behavior claims.
2. Ask the user to confirm the recommended reviewers or specify a non-empty comma-separated set of slugs. If the user requests an empty or unrecognized set, offer to end the review.
3. After reviewer selection, fetch the base and head refs into the shared `.git` directory.
4. Create a unique run directory under `/tmp/deep-review-runs/`. Create one uniquely named reviewer workspace beneath it for every selected analysis reviewer and later for the validator. Do not reuse the caller checkout or a workspace from another run.
5. In each reviewer workspace, materialize the target as the result of merging the target into its base so base files and conventions are available alongside the changes. For PRs, use `refs/pull/<number>/merge` when available and fall back to the head SHA. For branches or ranges, attempt a temporary merge of head into base, or use the resolved head if a clean merge is not possible. Use Git's worktree mechanism for every workspace.
6. Pass each reviewer only its assigned workspace path and the shared review context. Background analysis reviewers may read and write within their assigned workspace, including creating probes, but may not delete artifacts or use the caller checkout. The review-workspace parent is the only additional background write scope; do not grant global deletion permissions.

Complete when the selected reviewers, run path, and one isolated Git worktree per reviewer are recorded, and every reviewer can inspect the same committed target without relying on the caller checkout.

## 4. Gather review context

Collect the changed files, resolved diff, base and head SHAs, relevant project instructions, recent commits, stated intent from the target PR or commits, PR freshness metadata when applicable, and source files without corresponding tests. Pass this context and the assigned workspace path to every reviewer. Reviewers may run read-only Git commands in their own workspace as needed.

Complete when the context package is complete and identical target context is available to every selected reviewer.

## 5. Analyze in parallel

Launch the selected analysis reviewers in parallel with the `code-reviewer` profile (or `code-reviewer-structural` for structural maintainability). Each reviewer investigates hypotheses far enough to settle or disprove them when practical. Specialists SHOULD attempt cheap, local verification when practical. They MAY create temporary tests, fixtures, scripts, or other disposable scenarios within their isolated review worktree. They MUST NOT fix or refactor the production implementation as remediation or substantially expand the review into an open-ended debugging session. If verification requires permissions, environment setup, broad changes, long investigation, or commands unavailable to a background subagent, return a Candidate instead. If the hypothesis is disproved, discard it. Specialists do not need to clean up disposable verification artifacts; the coordinator owns worktree lifecycle. Focused runtime verification is opportunistic: use it when the required command is already permitted; otherwise escalate as a Candidate.

See `GLOSSARY.md` for finding types. Each reviewer reports only:

- **Direct finding** when the concern is settled with sufficient evidence. Include title, file/line, severity, evidence classification/how it was settled, source or runtime evidence, impact, and suggested remediation. Static evidence is sufficient when decisive; execution is not required.
- **Candidate finding** when the concern remains credible but cannot be settled within the reviewer's permissions, environment, or reasonable verification budget. Include title, file/line, severity, confidence, source evidence, impact, attempted verification if any, why verification remained blocked or inconclusive, one falsifiable validation hypothesis, and suggested remediation.
- Discard hypotheses that the reviewer disproves.

The validator is an escalation path for candidates analysis reviewers could not settle. Use `references/structural-maintainability-review.md` for structural review. The history reviewer identifies historical evidence from the supplied context; it does not run Git commands itself.

Complete when every selected reviewer has investigated its focus, returned only direct findings, candidate findings, or discarded hypotheses, and reported its workspace state.

## 6. Settle candidates

Deduplicate candidates, then pass every remaining candidate to one `code-reviewer-validator` in its own coordinator-created workspace. Launch the validator as a foreground custom subagent so required command and write permissions can be approved. It prioritizes uncertain high-impact candidates, then cheap and decision-relevant checks.

The validator may create disposable probes or focused tests and run the smallest relevant local command, but only inside its assigned workspace. It never remediates production code, commits, pushes, deploys, changes shared configuration, or calls external systems. It may leave disposable probes and a dirty worktree; the coordinator owns cleanup. See `GLOSSARY.md` for outcomes. It returns one outcome per candidate: **Validated finding**, **Unresolved**, or **Disproved**.

Complete when every candidate has exactly one outcome with an attempted check where applicable, the validator workspace state is recorded, and all required findings/evidence are copied to a coordinator-owned location outside disposable workspaces.

## 7. Present and decide

Use `references/output-template.md`.

For every direct and validated finding, compute an **Action** using severity, evidence, and fix size:

| Evidence | Severity | Fix size | Action |
|---|---|---|---|
| confirmed / likely | blocker / high | ≤ ~20 lines | **fix-now** |
| confirmed / likely | blocker / high | > ~20 lines or cross-module | **follow-up** |
| confirmed / likely | medium | ≤ ~20 lines | **fix-now** |
| confirmed / likely | medium | > ~20 lines or cross-module | **follow-up** |
| confirmed / likely | low | ≤ ~20 lines | **fix-now** |
| plausible | any | any | **discuss** |
| speculative | any | any | omit |

Present findings grouped as **Fix now**, **Discuss**, and **Follow-up**. Present unresolved candidates separately with evidence, attempted validation, and a per-candidate choice: **post to PR**, **keep private / investigate**, or **discard**. Do not draft unresolved candidates for publication until the user chooses to post them.

Then offer: fix all `fix-now` findings, discuss selected findings, add PR review, keep reviewing, or dismiss. Before any delayed action, re-check the target: PR state/head SHA for PRs, or the committed diff summary for local reviews.

Complete when the user selects an action or ends the review, and the final report plus any selected publication evidence is preserved outside the disposable review workspaces.

## Publication

When the user chooses **add PR review**, follow `references/pr-review-comments.md`. Draft only direct, validated, and user-selected unresolved candidates. Get per-comment approval. Submit one inline GitHub review with an empty top-level body unless the user explicitly requests a summary. Verify the expected comment count.

## Coordinator-owned cleanup

Cleanup is a separate coordinator phase after all reviewers finish, including reviewer failure, timeout, cancellation, user dismissal, or publication failure. Run it before the review session ends:

1. Collect and preserve the final report and selected evidence outside disposable reviewer workspaces.
2. Remove each exact coordinator-created worktree under `/tmp/deep-review-runs/**` through `git worktree remove --force` (or the narrowest equivalent Git worktree mechanism), because disposable probes may leave worktrees dirty. Do not follow symlinks outside the run path, and do not touch unrelated worktrees or concurrent review runs.
3. Verify each workspace is absent and no corresponding Git worktree registration remains.
4. Remove the run directory only after those checks pass, using a narrowly scoped, one-time coordinator authorization for this exact run path if deletion approval is required. Never add global or reviewer permissions for broad deletion commands.
5. If cleanup is interrupted or any state remains, report the exact leftover path and Git registration state. Do not broaden the deletion scope or claim cleanup succeeded.

Complete when all coordinator-created worktrees and the run directory are verified absent, or exact leftovers have been reported.
