# deep-review

A Devin skill for strict PR-gate code review. It takes a PR, branch, commit, or commit range and runs multiple specialized reviewers in isolated worktrees, validates uncertain findings, and presents an actionable report — optionally posting inline comments to the PR. Every run requires a clean caller repository and reviews committed targets only.

## How it works

The skill runs as a six-step pipeline:

1. **Gate & resolve** — Require a clean caller repository, then lock the committed review target (PR, branch, commit, or range). Create isolated reviewer worktrees so the user's checkout is never touched.
2. **Context** — Collect changed files, diff, commit history, project conventions, and stated intent from the target.
3. **Choose reviewers** — Classify the diff and recommend a subset of analysis reviewers. The user confirms or adjusts.
4. **Analyze** — Launch selected reviewers in parallel. Each reports **direct findings** (mechanically established) and **candidate findings** (need validation).
5. **Settle** — A validation reviewer probes every candidate with targeted checks, producing **validated findings**, **unresolved questions**, or **disproved** (dropped).
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

Analysis reviewers produce two kinds of output: **direct findings** (established from source evidence alone) and **candidate findings** (plausible but uncertain). Candidates go through a validation step where a separate reviewer runs targeted probes — disposable tests, small commands, or code inspection — to settle each one as **validated**, **unresolved**, or **disproved** (dropped from the report).

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

## Install

Run:

```sh
./install.sh
```

This symlinks the skill and agents into `~/.config/devin/skills/` and `~/.config/devin/agents/`.

## Update

Edit files in this repo (or through the symlinks in `~/.config/devin/`), then commit and push.
