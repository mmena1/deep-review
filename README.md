# deep-review

`deep-review` is a harness-agnostic protocol for strict PR-gate code review with first-class Devin and Codex adapters. It reviews committed PRs, branches, or commit ranges through simultaneous read-only scouting and independent hypothesis adjudication, then presents an actionable report and publishes only user-approved outcomes.

## Protocol

The shared pipeline is:

1. Resolve and pin a committed target without modifying unrelated caller state.
2. Capture immutable bounded context and create exactly one disposable review worktree.
3. Select review lenses and verify enough runtime capacity to launch the complete scout set simultaneously.
4. Run every selected scout read-only against the same pinned worktree.
5. Deduplicate admission-qualified Hypotheses.
6. Adjudicate every surviving hypothesis independently through a capacity-bounded read-only static phase, followed by sequential writable probes only when required.
7. Report Findings, Disproved hypotheses, and Unresolved questions with consistent failure, freshness, publication, and cleanup semantics.

The canonical semantics live in `skills/deep-review/protocol.md`. Shared scout and validator contracts live in `skills/deep-review/reviewers/`; harness wrappers contain only native orchestration and metadata.

## Layout

```text
skills/deep-review/              canonical protocol and reviewer sources
harnesses/devin/                 Devin wrappers, metadata, and native agents
harnesses/codex/                 Codex wrappers, metadata, and native agents
install.sh / install.ps1         compose personal installations from those sources
scripts/sync-agents.sh           refresh embedded native-agent reviewer bodies
scripts/check.sh                 canonical local and CI verification
docs/capability-matrix.md        adapter mechanism differences
docs/runtime-acceptance.md       passive receipts and targeted smoke tests
```

Shared protocol, glossary, references, and reviewer contracts are committed only under `skills/deep-review/`. The installers compose each harness's personal skill directory from those canonical sources and its native wrapper; only reviewer bodies embedded inside native agent files are generated. After reviewer changes, refresh those embedded sections:

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

From native Windows PowerShell, use `./install.ps1` with `-Devin`, `-Codex`, or `-All`. After pulling repository updates, rerun the relevant native installer to refresh the installed adapter.

The installer creates a small managed skill root and materializes canonical directories, canonical files, and native wrapper metadata into it. Unix uses symbolic links. Windows uses directory junctions and file hardlinks, the narrow equivalents available without administrator privileges. If link creation fails, including across volumes, it copies the affected path and warns that the installer must be rerun after repository updates. It backs up unrelated existing destinations, replaces repository-owned or broken managed links, and never changes global concurrency settings.

Devin installs under `~/.config/devin/`. Codex installs the personal skill under `~/.agents/skills/` and custom agents under `~/.codex/agents/`, following current Codex discovery locations.

## Verification

`./scripts/check.sh` verifies canonical sources, the absence of committed semantic copies in adapters, install-time composition, generated reviewer sections, native metadata structure, required `git` and `gh` commands, harness-neutral shared content, adapter-role mappings, and installer behavior. CI invokes the same command on Linux, macOS, and Windows.

Static checks cannot prove multi-agent orchestration. Every real review emits a passive runtime-acceptance receipt; use the targeted scenarios in `docs/runtime-acceptance.md` for important paths that normal reviews do not exercise.
