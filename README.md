# deep-review

A Devin skill for strict PR-gate code review. It takes a PR, branch, or commit range and runs multiple read-only scouts against one pinned review worktree, independently adjudicates every surviving hypothesis, and presents an actionable report — optionally posting inline comments to the PR. It reviews committed targets only.

## How it works

The pipeline is:

1. **Gate & resolve** — Resolve and pin the committed target, requiring a clean caller checkout only when it overlaps the target. The caller checkout is never modified.
2. **Context** — Collect the changed files, diff, commit history, project conventions, stated intent, and target-bound immutable context manifests.
3. **Choose scouts** — Select review dimensions and give each a bounded context manifest.
4. **Scout** — Run selected specialists concurrently against exactly one coordinator-owned worktree. Scouts are read-only and emit only admission-qualified hypotheses or no hypotheses.
5. **Deduplicate & validate** — Deduplicate conservatively, preserve evidence and origins, create a late-bound validator manifest, and invoke the validator sequentially once per canonical hypothesis. Each invocation returns Finding, Disproved, or Unresolved.
6. **Present & decide** — Report discovery/dedupe/outcome counts, classify Findings by final severity × fix size, map Unresolved to `discuss`, and offer next steps.

The validator first tries to falsify and may use decisive static evidence or the smallest focused check. No hypothesis becomes a Finding without validator establishment. If successful scouts produce zero hypotheses, the validator is not invoked and the report explicitly says all selected dimensions completed with nothing to validate. Any scout or validator failure makes the run incomplete and blocks PASS, `No findings`, and publication. A changed PR head makes the pinned result stale until rerun.

### Reviewers

| Reviewer | Focus |
|---|---|
| `bugs` | Bug detection and behavior coverage |
| `structural` | Maintainability of changed production logic |
| `conventions` | Code style and project standards |
| `history` | Regression risk from commit history |
| `docs` | Accuracy of comments, TODOs, and documentation claims |

### Publication

Findings may be published as assertive comments supported by validator evidence. An Unresolved item may be posted only with explicit per-item approval and must be a question describing evidence and remaining uncertainty. Semantic anchors, changed-line validation, freshness checks, private-context safeguards, and comment-count verification remain required.

## Contents

- `skills/deep-review/` — the `/deep-review` skill and protocol references
- `agents/` — scout and validator profiles

The coordinator creates one Git worktree per run under `/tmp/deep-review-runs/`, gives scouts read-only access, then gives the validator writable access to that same worktree. The coordinator restores the pinned baseline between hypotheses and owns final cleanup. Context snapshots remain separate, immutable, target-bound, and privacy-aware.

## Install

```sh
./install.sh
```

This symlinks the skill and agents into `~/.config/devin/skills/` and `~/.config/devin/agents/`.

## Update

Edit files in this repo (or through the symlinks), then commit the changes. Run `./install.sh` when you need to refresh installed symlinks.
