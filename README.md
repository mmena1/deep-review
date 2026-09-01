# deep-review

A Devin skill for strict PR-gate code review. It takes a PR, branch, or commit range and runs multiple specialized reviewers in isolated worktrees, validates uncertain findings, and presents an actionable report — optionally posting inline comments to the PR. Every run requires a clean caller repository and reviews committed targets only.

## How it works

The skill runs as a six-step pipeline:

1. **Gate & resolve** — Require a clean caller repository, then lock the committed review target (PR, branch, or range). Create isolated reviewer worktrees so the user's checkout is never touched.
2. **Context** — Collect changed files, diff, commit history, project conventions, and stated intent from the target.
3. **Choose reviewers** — Classify the diff and recommend a subset of analysis reviewers. The user confirms or adjusts.
4. **Analyze** — Launch selected reviewers in parallel in independent disposable worktrees. Each reports **Direct findings** (settled with sufficient evidence) or **Candidate findings** (credible but unsettled within its permissions, environment, or reasonable verification budget). Specialists may use bounded disposable probes without requiring execution when static evidence is decisive.
5. **Settle** — A validation reviewer probes every Candidate with targeted checks, producing **Validated findings**, **Unresolved** Candidates, or **Disproved** hypotheses (dropped). Only Candidates reach validation.
6. **Present & decide** — Group all surviving findings by action (**fix now**, **discuss**, **follow-up**) and offer next steps: apply fixes, post a PR review, or dismiss.

### Reviewers

You pick from five analysis reviewers depending on what changed:

| Reviewer | Focus |
|---|---|
| `bugs` | Bug detection and test coverage gaps |
| `structural` | Maintainability of changed production logic |
| `conventions` | Code style and project standards |
| `history` | Regression risk from commit history |
| `docs` | Accuracy of comments, TODOs, and doc claims |

### Validation

A **Direct finding** is settled by the analysis reviewer with sufficient evidence from deterministic source/control-flow analysis, existing tests, focused commands, or a disposable reproduction/probe; no validator investigation is required. A **Candidate finding** is credible but could not be settled within the reviewer's permissions, environment, or reasonable verification budget and must include a falsifiable validation hypothesis. Candidates go through validation, which returns **Validated**, **Disproved**, or **Unresolved**.

### Actions

Every surviving finding is assigned an action based on its severity, evidence strength, and fix size:

| Action | Meaning | The report includes |
|---|---|---|
| **Fix now** | Small, unambiguous fix (roughly 20 lines or fewer) with confirmed or likely evidence | A concrete code suggestion |
| **Discuss** | Needs author context, a tradeoff decision, or further investigation before anyone writes code | A discussion prompt |
| **Follow-up** | Real issue, but too large or out-of-scope for this PR | A description of the follow-up scope |

## Contents

- `skills/deep-review/` — the `/deep-review` skill
- `agents/` — `code-reviewer`, `code-reviewer-structural`, and `code-reviewer-validator` subagent profiles

The coordinator creates a unique run directory under `/tmp/deep-review-runs/` and one Git worktree per reviewer. Reviewers may write probes only in their assigned workspace; the coordinator owns cleanup after every exit path.

When repository intent or conventions live in ignored files, the coordinator creates one target-bound, read-only context snapshot under `/tmp/deep-review-context/<run-id>/`. It keeps `manifest`, `core-manifest`, and `reviewers/<reviewer>-manifest`, then gives each reviewer the bounded manifests naming what to read and why. Supported repository declarations use exact relative paths or bounded globs in the governing instruction chain, such as `deep-review-context required: CONTEXT.md` or `deep-review-context optional-glob: docs/adr/*.md`; other prose does not authorize discovery. Each artifact is limited to 2 MiB and the bundle to 16 MiB. Selection must bind to the resolved target; ambiguous local context is omitted or requires confirmation. Reviewers never receive context copies in their worktrees. Ignored context is private supplemental evidence and is not named or quoted in PR comments without explicit approval.

## Install

Run:

```sh
./install.sh
```

This symlinks the skill and agents into `~/.config/devin/skills/` and `~/.config/devin/agents/`.

## Update

Edit files in this repo (or through the symlinks in `~/.config/devin/`), then commit the changes. Run `./install.sh` when you need to refresh the installed symlinks.
