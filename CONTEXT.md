# Context

## Review run

A **review run** is one coordinated execution of multiple independent reviewers.

A **review workspace** is the dedicated parent area belonging to one review run.

A **reviewer workspace** is the isolated area assigned to one reviewer within the review workspace.

A **probe** is a disposable file, fixture, or generated artifact created to validate a review hypothesis.

The **coordinator** owns the lifecycle of the review workspace and reviewer workspaces. Reviewers may create probes in their assigned reviewer workspace but do not own cleanup.

**Cleanup** is a separate coordinator-owned phase that runs after all reviewers finish, including when a reviewer fails, times out, or is cancelled. Cleanup removes only artifacts inside the review workspace.

A **caller checkout** is the repository and checked-out branch from which a review run starts. It is launch context, not necessarily the review target.

A **review target** is the committed PR, branch, or commit range being reviewed. When no target is supplied, the caller's current branch is the review target; a detached caller has no implicit target.

A **PR gate review** is a review run whose caller checkout must be clean when it overlaps the review target. An omitted/current-branch target, an explicitly named current branch, or a PR whose source branch is the caller's current branch overlaps it. A different target may be reviewed from a dirty caller checkout, but working-tree changes never become review input.

A **clean caller repository state** has no staged, unstaged, deleted, renamed, or untracked non-ignored files. Ignored files do not affect this state. It is required only when the caller checkout overlaps the review target.

An **ignored context artifact** is local repository material excluded from Git tracking that may provide supplemental intent, requirements, architecture, standards, or decision context for a review target.

A **context snapshot** is one immutable, coordinator-owned collection of selected ignored context artifacts for a review run. A **context bundle** is the files and canonical provenance manifest in that snapshot.

A **reviewer context manifest** identifies the core and bounded context-bundle entries a particular reviewer should read and explains their relevance. It does not copy the artifacts.

A **target-binding basis** is the explicit active-work reference, selected-context reference, bounded repository rule, or changed-path/tracked-instruction relevance that establishes why an ignored context artifact applies to the resolved review target.

**Operational instructions** from the materialized target govern reviewer behavior. Ignored context is supplemental evidence unless supported repository configuration explicitly designates it otherwise.

A **publication boundary** separates private/local context used for reasoning from team-visible evidence suitable for a GitHub review comment. Ignored context does not cross that boundary automatically.

A **comment scope** describes the semantic breadth of a review comment: a **point comment** addresses one precise incorrect statement, a **method/design comment** addresses an implementation or design as a whole, and a **compact range comment** addresses one issue demonstrated collectively by adjacent lines.

A **source anchor** is the code location selected to represent a comment's scope. A source anchor may be a single line, a method or function declaration, or a bounded contiguous range. **Semantic representativeness** means that the anchor is the smallest source location that credibly makes the comment's claim intelligible.

**Publication coordinates** are the GitHub-specific path, line or range, side, and head information used to encode a source anchor. **Mechanical validity** means that those coordinates are well-formed, refer to the intended diff side and current head, and satisfy GitHub's changed-line constraints. Mechanical validity does not establish semantic representativeness.

An **anchor fallback** is an explicitly recorded substitution of the smallest relevant changed line or compact range when the semantically preferred anchor is not commentable. A fallback preserves the comment's scope in its wording and rationale; an arbitrary nearest line is not a valid fallback.

**Coordinate remapping** is GitHub's post-publication attempt to map an original anchor onto a later head. A missing current `line` with intact original coordinates is remapping state, not evidence that the initial anchor was invalid.
