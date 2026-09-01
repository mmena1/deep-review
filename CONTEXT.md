# Context

## Review run

A **review run** is one coordinated execution of multiple independent reviewers.

A **review workspace** is the dedicated parent area belonging to one review run.

A **reviewer workspace** is the isolated area assigned to one reviewer within the review workspace.

A **probe** is a disposable file, fixture, or generated artifact created to validate a review hypothesis.

The **coordinator** owns the lifecycle of the review workspace and reviewer workspaces. Reviewers may create probes in their assigned reviewer workspace but do not own cleanup.

**Cleanup** is a separate coordinator-owned phase that runs after all reviewers finish, including when a reviewer fails, times out, or is cancelled. Cleanup removes only artifacts inside the review workspace.

A **PR gate review** is a review run that may start only from a clean caller repository state. It evaluates committed review targets and does not treat working-tree changes or ad-hoc file paths as review targets.

A **clean caller repository state** has no staged, unstaged, deleted, renamed, or untracked non-ignored files. Ignored files do not affect this state.

An **ignored context artifact** is local repository material excluded from Git tracking that may provide supplemental intent, requirements, architecture, standards, or decision context for a review target.

A **context snapshot** is one immutable, coordinator-owned collection of selected ignored context artifacts for a review run. A **context bundle** is the files and canonical provenance manifest in that snapshot.

A **reviewer context manifest** identifies the core and bounded context-bundle entries a particular reviewer should read and explains their relevance. It does not copy the artifacts.

A **target-binding basis** is the explicit active-work reference, selected-context reference, bounded repository rule, or changed-path/tracked-instruction relevance that establishes why an ignored context artifact applies to the resolved review target.

**Operational instructions** from the materialized target govern reviewer behavior. Ignored context is supplemental evidence unless supported repository configuration explicitly designates it otherwise.

A **publication boundary** separates private/local context used for reasoning from team-visible evidence suitable for a GitHub review comment. Ignored context does not cross that boundary automatically.
