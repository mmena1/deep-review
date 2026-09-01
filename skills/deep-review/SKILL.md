---
name: deep-review
model: gpt-5-6-sol-medium
triggers:
  - user
description: Run a strict PR-gate review with isolated parallel reviewers and targeted validation.
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
3. After reviewer selection, resolve and capture the ignored context snapshot for this target before creating reviewer worktrees. Use one unique coordinator-owned root under `/tmp/deep-review-context/<run-id>/` with `files/`, `manifest`, `core-manifest`, and one `reviewers/<reviewer>-manifest` for each selected analysis reviewer. Create no validator manifest during snapshot setup. The coordinator requests a narrowly scoped, one-time write approval for the current context root, captures the files, then restricts the root to user-only read access; do not pre-approve context-root writes for reviewers. Bind every automatically selected artifact to the resolved target through an explicit active-work reference, selected-context reference, bounded repository rule, or changed-path/tracked-instruction relevance. Omit ambiguous local context or ask the user before including it. A directory pointer never authorizes recursive copying. The captured artifact contents and canonical provenance are immutable after capture; coordinator-owned derived reviewer manifests may be created later without recapturing or modifying the snapshot.
4. Record canonical provenance for each selected artifact: repository-relative source path, bundle path, SHA-256, size, required/optional status, selection reason, target-binding reason/relationship, repository identity, target/base/head SHAs, and capture metadata. Accept regular files only; reject symlinks, special files, external paths, traversal, and normalized collisions. Limit each artifact to 2 MiB and the complete bundle to 16 MiB; repositories may narrow these limits but may not broaden them silently. Check metadata before and after copying and retry once if size or mtime changed; required failures stop the run, optional failures are omitted with a warning. Create an explicit empty bundle when nothing is selected.
5. Create a unique run directory under `/tmp/deep-review-runs/`. Create one uniquely named reviewer workspace beneath it for every selected analysis reviewer and later for the validator. Do not reuse the caller checkout or a workspace from another run.
6. In each reviewer workspace, materialize the target as the result of merging the target into its base so base files and conventions are available alongside the changes. For PRs, use `refs/pull/<number>/merge` when available and fall back to the head SHA. For branches or ranges, attempt a temporary merge of head into base, or use the resolved head if a clean merge is not possible. Use Git's worktree mechanism for every workspace.
7. Give each analysis reviewer the context root, canonical manifest, core context manifest, and its bounded reviewer-specific manifest identifying what to read and why. Reviewers may read the context snapshot but may write only inside their assigned disposable worktree, including creating probes. The snapshot is coordinator-owned and read-only after capture; later creation of a coordinator-owned validator manifest does not alter it. The review-workspace parent is the only additional background write scope; do not grant global deletion permissions. If Devin's configured permissions cannot enforce separate read/write roots, document that limitation and preserve the separation as strongly as practical.

Complete when the selected analysis reviewers, run paths, immutable context snapshot, canonical and core manifests, each selected analysis reviewer's manifest, and one isolated Git worktree per analysis reviewer are recorded, and every analysis reviewer can inspect the same committed target without relying on the caller checkout.

## 4. Gather review context

Collect the changed files, resolved diff, base and head SHAs, relevant tracked project instructions, recent commits, stated intent from the target PR or commits, PR freshness metadata when applicable, and source files without corresponding tests. Treat tracked instructions from the materialized target as operational authority. Ignored context is supplemental evidence about intent, requirements, architecture, standards, or prior decisions unless supported repository configuration explicitly designates it otherwise.

Give every reviewer the same core context needed to understand target intent plus a bounded reviewer-specific subset. The stable manifest paths are `manifest`, `core-manifest`, and `reviewers/<reviewer>-manifest`; analysis reviewers must read the artifacts named by both `core-manifest` and their reviewer-specific manifest, and must not recursively inspect the bundle. When Candidates remain after analysis deduplication, the coordinator creates `reviewers/validator-manifest` from the immutable snapshot; the validator reads the artifacts named by both `core-manifest` and that manifest. Each reviewer manifest must identify each selected artifact and why it is relevant. Use these default focus mappings: bugs—spec/PRD, issue, acceptance criteria, tests, and edge cases; structural—spec, ADRs, and design artifacts; conventions—standards and conventions; history—decision rationale and relevant ADRs; docs—spec, behavior, and terminology; validator—core context plus only material relevant to the actual Candidate set.

The supported repository-declared selection convention is a `deep-review-context` block in the governing tracked instruction chain. Each declaration is one exact relative file path or bounded glob, prefixed with `required` or `optional`, for example `deep-review-context required: CONTEXT.md` or `deep-review-context optional-glob: docs/adr/*.md`. The coordinator applies declarations only when their instruction scope covers the resolved target; it records the declaration as the target-binding basis. Active-work references and references from selected artifacts remain explicit relative paths. Other prose is informative only and does not authorize discovery.

Ignored context may inform reasoning and validation, but it is private/local context and is not automatically suitable evidence for a GitHub review comment. Published findings should stand on committed code and team-visible evidence whenever practical. Do not mention or quote private ignored artifact paths in PR comments without explicit user approval. User-facing reports use repository-relative paths and may summarize the snapshot and warnings without presenting temporary paths as repository paths.

Complete when the canonical context manifest, core manifest, and every selected analysis reviewer manifest are complete, target binding is recorded, and each analysis reviewer has the same target plus only its declared context subset. A validator manifest is absent until the settle-candidates branch requires it.

## 5. Analyze in parallel

Launch the selected analysis reviewers in parallel with the `code-reviewer` profile (or `code-reviewer-structural` for structural maintainability). Give each reviewer its assigned worktree, the read-only context snapshot root, the canonical manifest, the core context manifest, and its reviewer-specific manifest. Each reviewer investigates hypotheses far enough to settle or disprove them when practical. Specialists SHOULD attempt cheap, local verification when practical. They MAY create temporary tests, fixtures, scripts, or other disposable scenarios within their isolated review worktree. They MUST NOT fix or refactor the production implementation as remediation or substantially expand the review into an open-ended debugging session. If verification requires permissions, environment setup, broad changes, long investigation, or commands unavailable to a background subagent, return a Candidate instead. If the hypothesis is disproved, discard it. Specialists do not need to clean up disposable verification artifacts; the coordinator owns worktree lifecycle. Focused runtime verification is opportunistic: use it when the required command is already permitted; otherwise escalate as a Candidate.

See `GLOSSARY.md` for finding types. Each reviewer reports only:

- **Direct finding** when the concern is settled with sufficient evidence. Include title, file/line, severity, evidence classification/how it was settled, source or runtime evidence, impact, and suggested remediation. Static evidence is sufficient when decisive; execution is not required.
- **Candidate finding** when the concern remains credible but cannot be settled within the reviewer's permissions, environment, or reasonable verification budget. Include title, file/line, severity, confidence, source evidence, impact, attempted verification if any, why verification remained blocked or inconclusive, one falsifiable validation hypothesis, and suggested remediation.
- Discard hypotheses that the reviewer disproves.

The validator is an escalation path for candidates analysis reviewers could not settle. Use `references/structural-maintainability-review.md` for structural review. The history reviewer identifies historical evidence from the supplied context; it does not run Git commands itself.

Complete when every selected reviewer has investigated its focus, returned only direct findings, candidate findings, or discarded hypotheses, and reported its workspace state.

## 6. Settle candidates

Deduplicate candidates. If no Candidate findings remain, create no `reviewers/validator-manifest`, create no validator worktree, and continue directly to **Present and decide**. If Candidates remain, derive validator-specific context from the actual deduplicated Candidate set and the immutable snapshot: create `reviewers/validator-manifest` with the core context plus only artifacts relevant to settling those Candidates. Do not recapture or modify snapshot files or canonical provenance. Then create one coordinator-owned validator workspace and pass it the manifest. Launch the validator as a foreground custom subagent so required command and write permissions can be approved. It prioritizes uncertain high-impact candidates, then cheap and decision-relevant checks.

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

When the user chooses **add PR review**, follow `references/pr-review-comments.md`. Draft only direct, validated, and user-selected unresolved candidates. Use committed code and team-visible evidence whenever practical; ignored context is private/local and must not be mentioned or quoted in a PR comment unless the user explicitly approves it. Get per-comment approval. Submit one inline GitHub review with an empty top-level body unless the user explicitly requests a summary. Verify the expected comment count.

## Coordinator-owned cleanup

Cleanup is a separate coordinator phase after all reviewers finish, including reviewer failure, timeout, cancellation, user dismissal, or publication failure. Run it before the review session ends:

1. Collect and preserve the final report and selected evidence outside disposable reviewer workspaces.
2. Remove each exact coordinator-created worktree under `/tmp/deep-review-runs/**` through `git worktree remove --force` (or the narrowest equivalent Git worktree mechanism), because disposable probes may leave worktrees dirty. Do not follow symlinks outside the run path, and do not touch unrelated worktrees or concurrent review runs.
3. Verify each workspace is absent and no corresponding Git worktree registration remains.
4. Remove the matching context snapshot under `/tmp/deep-review-context/**` only after reviewer manifests, findings, and evidence are preserved. Remove the run directory only after those checks pass, using narrowly scoped, one-time coordinator authorization for these exact run paths if deletion approval is required. Never add global or reviewer permissions for broad deletion commands.
5. If cleanup is interrupted or any state remains, report the exact leftover path and Git registration state. Do not broaden the deletion scope or claim cleanup succeeded.

Complete when all coordinator-created worktrees, the matching context snapshot root, and the run directory are verified absent, or exact leftovers (including any context-root leftover) have been reported.
