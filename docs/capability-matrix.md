# Harness Capability Matrix

This matrix records adapter mechanisms. The shared semantics remain in `skills/deep-review/protocol.md`.

| Capability | Devin adapter | Codex adapter |
| --- | --- | --- |
| Skill location | `~/.config/devin/skills/deep-review` | `~/.agents/skills/deep-review` |
| Installed skill composition | Native wrapper plus linked canonical files/directories | Native wrapper and metadata plus linked canonical files/directories |
| Native agent location | `~/.config/devin/agents/` | `~/.codex/agents/*.toml` |
| Coordinator model | Devin skill frontmatter pins the existing Sol medium assignment | Parent Codex session; the adapter does not override the user's coordinator model |
| Generic scout | `code-reviewer`, Luna medium; `exec` is available, so no-write/no-probe confinement is instruction-enforced | `deep_review_scout`, Luna medium, read-only sandbox |
| Structural scout | `code-reviewer-structural`, Sol medium; `exec` is available, so no-write/no-probe confinement is instruction-enforced | `deep_review_structural`, Sol medium, read-only sandbox |
| Static validator | `code-reviewer-validator-static`, Luna high; `exec` is available, so no-write/no-probe confinement is instruction-enforced | `deep_review_validator_static`, Luna high, read-only sandbox |
| Writable validator | `code-reviewer-validator-probe`, Luna high, with `exec`, write, and edit tools | `deep_review_validator_probe`, Luna high, workspace-write sandbox |
| Simultaneous scout gate | Adapter checks available background subagent capacity before launch | Adapter checks active Codex subagent capacity before spawn |
| Global concurrency | Never modified | Never modified |
| Ordinary GitHub work | `git` and `gh` | `git` and `gh` |

Capability differences are diagnostic unless they prevent a hard protocol invariant. An adapter that cannot preserve an invariant stops the review rather than degrading it.

On Unix-like systems, composition uses symbolic links. Native Windows PowerShell and Git Bash use directory junctions and file hardlinks, with a warned copy fallback when a link cannot be created. Neither installer changes harness concurrency.
