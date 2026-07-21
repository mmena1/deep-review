---
name: deep-review
disable-model-invocation: true
description: Review a change with parallel analysis and targeted validation.
argument-hint: "[PR number | PR URL | branch | commit range | file paths]"
---

# Deep Review

Review one explicit target predictably: **resolve**, **analyze**, **settle**, **decide**, then publish only approved comments. This skill runs in the root session because it coordinates reviewers and publication.

## 1. Resolve the target

1. Treat an argument containing a PR number/URL, branch, commit range, or file paths as the immutable review target. Resolve it without consulting the current checkout.
2. For a PR, collect its number, repository, base ref, head ref, head SHA, state, and diff. For a branch or commit range, resolve its base, head SHA, and diff; look up an associated open PR without substituting it for the supplied target.
3. For file paths, resolve exactly those paths and their applicable diff. If no target argument exists, auto-detect uncommitted changes, then an open PR for the current branch.
4. Echo the resolved target, base, head, associated PR (or lack of one), and review mode. Ask the user to confirm before analyzing.
5. A branch with no unique open PR is a local, non-posting review. Require an explicit PR number/URL before publishing comments.

Complete when the confirmed target, diff, base/head, and publication eligibility are recorded.

## 2. Gather review context

Collect the changed files; relevant project instructions and their contents; recent commits for the resolved target; stated intent from the target PR or commits; PR freshness metadata when applicable; and source files without corresponding tests. Pass this context to every reviewer.

Complete when each reviewer can inspect the same target without relying on the root checkout.

## 3. Choose analysis reviewers

Classify the diff as production source, tests, docs, config/build, or other. Recommend only valuable reviewers, explain inclusions and exclusions, then let the user select from:

- **Bug and test coverage** — executable code or behavior-bearing configuration.
- **Structural maintainability** — changed production logic or control flow.
- **Conventions** — most changes.
- **History** — modified code/config with regression-relevant history.
- **Comments and docs** — changed comments, TODOs, or behavior claims.

Complete when the user confirms a non-empty reviewer set, or explicitly ends the review.

## 4. Analyze in parallel

Launch the selected analysis reviewers in parallel with the read-only `code-reviewer` profile (or `code-reviewer-structural` for structural maintainability). They use repository read/search tools only; they do not execute shell commands or create files.

See `GLOSSARY.md` for finding types. Each reviewer reports only:

- **Direct finding** with file/line and source evidence.
- **Candidate finding** with file/line, impact, confidence, source evidence, and one falsifiable validation hypothesis.

Use `references/structural-maintainability-review.md` for structural review. The history reviewer identifies historical evidence from the supplied context; it does not run Git commands itself.

Complete when every selected reviewer returns direct findings and candidate findings in this form.

## 5. Settle candidates

Deduplicate candidates, then pass every remaining candidate to one validation reviewer. Create an isolated worktree for validation, then launch that reviewer as foreground `subagent_general` so required write/command permissions can be approved. The reviewer prioritizes uncertain high-impact candidates, then cheap and decision-relevant checks.

The validation reviewer may create disposable probes or focused tests, run the smallest relevant local command, and remove every artifact before reporting. It never commits, pushes, changes shared configuration, runs deployments, or calls external systems. See `GLOSSARY.md` for outcomes. It returns one outcome per candidate: **Validated finding**, **Unresolved question**, or **Disproved**.

Complete when every candidate is validated, unresolved with an attempted check, or disproved, and the validation worktree is clean.

## 6. Present and decide

Use `references/output-template.md`.

Present direct and validated findings as **Findings**. Present unresolved questions separately with evidence, attempted validation, and a per-question choice: **post to PR**, **keep private / investigate**, or **discard**. Do not draft unresolved questions for publication until the user chooses to post them.

Then offer: fix all findings, fix selected findings, add PR review, keep reviewing, or dismiss.

Complete when the user selects an action. Before a delayed action, re-check the target: PR state/head SHA for PRs, or the diff summary for local reviews.

## Publication

When the user chooses **add PR review**, follow `references/pr-review-comments.md`. Draft only direct, validated, and user-selected unresolved questions. Get per-comment approval. Submit one inline GitHub review with an empty top-level body unless the user explicitly requests a summary.

Complete when the approved comments are posted and their count is verified, or the user declines publication.
