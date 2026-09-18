# Harness Capability Matrix

This matrix records adapter mechanisms. The shared semantics remain in `skills/deep-review/protocol.md`.

| Capability | Devin adapter | Codex adapter |
| --- | --- | --- |
| Skill location | `~/.config/devin/skills/deep-review` | `~/.agents/skills/deep-review` |
| Native agent location | `~/.config/devin/agents/` | `~/.codex/agents/*.toml` |
| Coordinator model | Devin skill frontmatter pins the existing Sol medium assignment | Parent Codex session; the adapter does not override the user's coordinator model |
| Generic scout | `code-reviewer`, Luna medium, read/search/inspection tools | `deep_review_scout`, Luna medium, read-only sandbox |
| Structural scout | `code-reviewer-structural`, Sol medium, read/search/inspection tools | `deep_review_structural`, Sol medium, read-only sandbox |
| Static validator | `code-reviewer-validator-static`, Luna high, read/search/inspection tools | `deep_review_validator_static`, Luna high, read-only sandbox |
| Writable validator | `code-reviewer-validator-probe`, Luna high, write/edit enabled | `deep_review_validator_probe`, Luna high, workspace-write sandbox |
| Simultaneous scout gate | Adapter checks available background subagent capacity before launch | Adapter checks active Codex subagent capacity before spawn |
| Global concurrency | Never modified | Never modified |
| Ordinary GitHub work | `git` and `gh` | `git` and `gh` |

Capability differences are diagnostic unless they prevent a hard protocol invariant. An adapter that cannot preserve an invariant stops the review rather than degrading it.
