# deep-review

`deep-review` is a harness-agnostic protocol for strict PR-gate code review with first-class Devin and Codex adapters. It reviews committed PRs, branches, or commit ranges through simultaneous read-only scouting and independent hypothesis adjudication, then presents an actionable report and publishes only user-approved outcomes.

## Protocol

The shared pipeline is:

1. Resolve and pin a committed target without modifying unrelated caller state.
2. Capture immutable bounded context and create exactly one disposable review worktree.
3. Select review lenses and verify enough runtime capacity to launch the complete scout set simultaneously.
4. Run every selected scout read-only against the same pinned worktree.
5. Deduplicate admission-qualified Hypotheses.
6. Adjudicate every surviving hypothesis independently through a concurrent read-only static wave, followed by sequential writable probes only when required.
7. Report Findings, Disproved hypotheses, and Unresolved questions with consistent failure, freshness, publication, and cleanup semantics.

The canonical semantics live in `skills/deep-review/protocol.md`. Shared scout and validator contracts live in `skills/deep-review/reviewers/`; harness wrappers contain only native orchestration and metadata.

## Layout

```text
skills/deep-review/              canonical protocol and reviewer sources
harnesses/devin/                 complete Devin skill and agent adapter
harnesses/codex/                 complete Codex skill and custom-agent adapter
scripts/sync-agents.sh           refresh generated adapter content
scripts/check.sh                 canonical local and CI verification
docs/capability-matrix.md        adapter mechanism differences
docs/runtime-acceptance.md       manual orchestration smoke tests
```

Generated composed views are committed so each harness skill directory is directly installable. Edit canonical sources, then refresh adapters:

```sh
./scripts/sync-agents.sh
./scripts/check.sh
```

## Install

```sh
./install.sh           # every detected supported harness
./install.sh --devin
./install.sh --codex
./install.sh --all
```

The installer links each complete adapter as one unit. On Windows it uses directory junctions and file hardlinks, the narrow equivalents available without administrator privileges. It backs up unrelated existing destinations, replaces repository-owned or broken managed links, and never changes global concurrency settings.

Devin installs under `~/.config/devin/`. Codex installs the personal skill under `~/.agents/skills/` and custom agents under `~/.codex/agents/`, following current Codex discovery locations.

## Verification

`./scripts/check.sh` verifies canonical sources, composed adapter views, generated reviewer sections, native metadata structure, required `git` and `gh` commands, harness-neutral shared content, adapter-role mappings, and installer behavior. CI invokes the same command.

Static checks cannot prove multi-agent orchestration. Run `docs/runtime-acceptance.md` on Devin and Codex after changes to wrappers, permissions, native agent metadata, or orchestration behavior.
