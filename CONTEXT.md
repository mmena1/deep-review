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
