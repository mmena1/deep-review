# Agent Instructions for deep-review

## Repository layout

- `skills/deep-review/` — canonical harness-neutral protocol, reviewer contracts, lenses, glossary, and references.
- `harnesses/devin/` — Devin wrappers, native metadata, and reviewer agents.
- `harnesses/codex/` — Codex wrappers, native metadata, and custom reviewer agents.
- `scripts/` — generated-body synchronization and the canonical distribution check.

## Working in this repo

- Edit shared semantics only under `skills/deep-review/`; edit native metadata and orchestration only under the corresponding `harnesses/` adapter.
- Do not commit copies of shared protocol, glossary, reference, or reviewer files under a harness adapter; the installers compose those paths at install time.
- After shared reviewer changes, run `./scripts/sync-agents.sh` and commit the refreshed reviewer bodies embedded in native agent files.
- Run `./scripts/check.sh` before commit. It is the same command CI uses.
- After changes, verify Devin still loads the skill and agents:
  - `devin skills list`
  - `devin -p "List the available subagent profiles"`
- Verify Codex discovers the installed skill and custom agents with a fresh session and the runtime matrix in `docs/runtime-acceptance.md`.
- Commit changes with concise, descriptive summaries. Do not add generated-by boilerplate.
- Keep references in `skills/deep-review/references/` up to date.

## Agent skills

### Issue tracker

Issues and specs live in this repository's GitHub Issues; use the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five canonical triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repository with root `CONTEXT.md` and `docs/adr/` decisions. See `docs/agents/domain.md`.
