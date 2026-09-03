# Agent Instructions for deep-review

## Repository layout

- `skills/deep-review/` — the `/deep-review` skill. Symlinked to `~/.config/devin/skills/deep-review`.
- `agents/` — custom subagent profiles. Symlinked to `~/.config/devin/agents/`.

## Working in this repo

- Edit skill and agent files in this repo. They are also reachable through the symlinks in `~/.config/devin/`.
- After changes, verify Devin still loads the skill and agents:
  - `devin skills list`
  - `devin -p "List the available subagent profiles"`
- Commit changes with concise, descriptive summaries. Do not add generated-by boilerplate.
- Keep references in `skills/deep-review/references/` up to date.

## Agent skills

### Issue tracker

Issues and specs live in this repository's GitHub Issues; use the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five canonical triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repository with root `CONTEXT.md` and `docs/adr/` decisions. See `docs/agents/domain.md`.
