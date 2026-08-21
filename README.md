# deep-review

A Devin skill for deep code review. It takes a PR, branch, commit range, or set of file paths and runs multiple specialized reviewers in parallel, validates uncertain findings, and presents an actionable report — optionally posting inline comments to the PR.

## How it works

The skill runs as a six-step pipeline:

1. **Resolve** — Lock the review target (PR, branch, commits, or files). Create an isolated worktree so the user's checkout is never touched.
2. **Context** — Collect changed files, diff, commit history, project conventions, and stated intent from the target.
3. **Choose reviewers** — Classify the diff and recommend a subset of analysis reviewers. The user confirms or adjusts.
4. **Analyze** — Launch selected reviewers in parallel. Each reports **direct findings** (mechanically established) and **candidate findings** (need validation).
5. **Settle** — A validation reviewer probes every candidate with targeted checks, producing **validated findings**, **unresolved questions**, or **disproved** (dropped).
6. **Present & decide** — Group all surviving findings by action (**fix now**, **discuss**, **follow-up**) and offer next steps: apply fixes, post a PR review, create follow-up tickets, or dismiss.

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

## Contents

- `skills/deep-review/` — the `/deep-review` skill
- `agents/` — `code-reviewer` and `code-reviewer-structural` subagent profiles

## Install

Run:

```sh
./install.sh
```

This symlinks the skill and agents into `~/.config/devin/skills/` and `~/.config/devin/agents/`.

## Update

Edit files in this repo (or through the symlinks in `~/.config/devin/`), then commit and push.
