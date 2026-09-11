# Context

## Review run

A **review run** is one coordinated execution of multiple read-only scouts and sequential validator adjudications.

A **review workspace** is the coordinator-owned disposable area belonging to one review run.

A **review target** is the committed PR, branch, or commit range being reviewed. When no target is supplied, the caller's current branch is the target; a detached caller has no implicit target.

A **caller checkout** is the repository and checked-out branch from which a run starts. It is launch context, not necessarily the review target.

A **PR gate review** requires a clean caller checkout only when it overlaps the review target. A different target may be reviewed from a dirty checkout, but working-tree changes never become review input.

An **ignored context artifact** is local material excluded from Git tracking that may provide supplemental intent, requirements, architecture, standards, or decision context.

A **context snapshot** is one immutable, coordinator-owned collection of selected ignored artifacts. A **reviewer context manifest** identifies the core and bounded entries a scout or validator should read; it does not copy artifacts.

**Operational instructions** from the materialized target govern behavior. Ignored context is supplemental evidence unless supported repository configuration explicitly designates it otherwise.

A **hypothesis** is an admission-qualified scout concern grounded in changed code or a changed behavior-bearing path. A **Finding** is independently established by the validator. **Disproved** rejects a hypothesis. **Unresolved** is attempted but unsettled and is not a Finding.

A **publication boundary** separates private/local context from team-visible evidence suitable for a GitHub review comment. Ignored context does not cross it automatically.

A **comment scope** describes a point, method/design, or compact range comment. A **source anchor** is the smallest semantically representative code location. Publication coordinates must be mechanically valid for the current head as well as semantically representative.
