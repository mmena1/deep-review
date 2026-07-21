# Structural Maintainability Review Rubric

Use this rubric only for the structural maintainability reviewer.

## Mission

Find cases where the diff makes the implementation harder to reason about, then suggest behavior-preserving simplifications that reduce concepts, branches, modes, wrappers, layers, coupling, or incidental complexity.

Be ambitious about structural simplification: look for changes that reduce concepts, branches, modes, wrappers, layers, or incidental complexity rather than only smoothing the changed lines, while keeping every finding anchored to how the diff introduces, exposes, or worsens concrete maintainability cost.

## Code Judo

A code-judo move is a behavior-preserving restructuring that makes complexity disappear instead of relocating it. Prefer suggestions that delete branches, modes, wrappers, duplicated concepts, or incidental layers over suggestions that merely organize the same complexity differently.

Good code-judo findings explain why the current diff makes the surrounding structure harder to reason about and point to a simpler shape that would make the change feel inevitable in hindsight.

## Scope

Expand the review beyond changed lines when the changed hunk adds complexity to a broader local structure.

Inspect the surrounding function, class, module, package, or flow when the diff adds:

- another condition, mode, flag, fallback, or special case
- logic inside an already large or branch-heavy function
- feature-specific behavior to a shared/general path
- another wrapper, adapter, helper, or abstraction layer
- casts, optionality, nullable branches, or shape checks that hide an invariant
- duplicated logic or a near-duplicate helper

You may recommend restructuring surrounding pre-existing code when the diff exposes or worsens a larger local design problem. Keep rewrite recommendations scoped to the diff's impact; broad legacy cleanup unrelated to the diff is out of scope.

## What to Flag Aggressively

Flag structural maintainability issues when there is concrete diff evidence of:

- ad-hoc conditionals bolted onto already busy flows
- repeated conditions that suggest a missing model, policy, dispatcher, or helper
- feature logic leaking into shared or general-purpose code
- wrong-layer logic that belongs in a different service, package, module, or boundary
- thin wrappers, identity helpers, pass-through abstractions, or indirection that does not buy clarity
- magical or overly generic handling that hides simple data-shape assumptions
- unnecessary casts, optionality, nullable modes, or fallback branches that obscure the real invariant
- duplicated concepts or bespoke helpers where a canonical utility or existing abstraction should own the behavior
- file, function, or component growth past a healthy size boundary
- refactors that move complexity around without reducing the number of concepts a reader must hold
- orchestration that serializes independent work or leaves related updates less atomic when a cleaner structure is visible

## Preferred Remedies

Prefer suggestions that make the implementation smaller, more direct, and easier to reason about:

- delete a branch, mode, wrapper, or layer instead of polishing it
- normalize inputs earlier so downstream logic becomes linear
- collapse duplicate branches into one clearer flow
- extract a helper or pure function only when it removes visible complexity
- move logic to the package/module/layer that already owns the concept
- replace repeated condition chains with an explicit model, policy, state machine, or dispatcher
- make invariants explicit at the boundary instead of relying on casts, nullable fallbacks, or shape checks
- isolate feature-specific behavior behind a dedicated abstraction instead of scattering feature checks through shared code
- split oversized functions, files, or components into cohesive units
- reuse existing canonical helpers instead of creating near-duplicates
- restructure related updates into a more atomic flow when partial state would be harder to reason about

## Guardrails

- Keep every finding anchored to how the diff introduces, exposes, or worsens the issue.
- Only flag pre-existing complexity when the diff makes it meaningfully worse or reveals a clear local simplification.
- Report only structural findings; style preferences belong in the conventions review.
- Suggest a new abstraction only when it removes more complexity than it adds.
- If no concrete simplification is visible, report no finding.
- Report direct findings when source evidence establishes the concern; otherwise report a candidate finding with a falsifiable validation hypothesis.

## Useful Review Language

- `this adds another special-case branch into an already busy flow. can we restructure this so the new case falls through the same path as the existing ones?`
- `this works, but it makes the surrounding function carry another mode. i think there's a code-judo move here that would delete the branch instead of centralizing it.`
- `this feels like feature logic leaking into a shared path. can we move the decision to the layer that owns this concept?`
- `this abstraction seems thin: it adds another thing to understand without deleting complexity elsewhere. can we keep the direct flow?`
- `this refactor moves complexity around, but doesn't reduce the number of concepts the reader has to hold. is there a way to simplify the model itself?`
