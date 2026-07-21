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
