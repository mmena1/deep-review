# Code Review Output Template

```markdown
## Code Review Results

Reviewed: [confirmed target]
Base / reviewed head / current head: [base] / [reviewed SHA] / [current SHA]
Publication: [PR # / local only / stale and blocked]
Scouts: [selected scouts]
Validation: [run / not needed / incomplete]
Context snapshot: [target-bound files/manifests, omitted optional files, warnings, or "empty"]

**Pipeline:** Hypotheses [discovered] → [after dedupe]; Validation [findings] Finding, [disproved] Disproved, [unresolved] Unresolved

**Headline takeaway:** [most important Finding, or "No findings"]

### Findings

#### Fix now

1. **Title** — Finding | Action: fix-now
   File: path/to/file:line
   Comment scope: point | method/design | compact range
   Source anchor: [single line, declaration, or range with diff side]
   Anchor rationale: [why this is the smallest representative location]
   Severity: blocker | high | medium | low
   Evidence: [validator evidence]
   Why it matters: [impact]
   Suggested fix: [concrete remediation]

#### Discuss

1. **Title** — Finding | Action: discuss
   File: path/to/file:line
   Comment scope: point | method/design | compact range
   Source anchor: [location and side]
   Anchor rationale: [semantic rationale]
   Severity: blocker | high | medium | low
   Evidence: [validator evidence]
   Why it matters: [impact]
   Discussion prompt: [question or tradeoff]

#### Follow-up

1. **Title** — Finding | Action: follow-up
   File: path/to/file:line
   Severity: blocker | high | medium | low
   Evidence: [validator evidence]
   Why it matters: [impact]
   Follow-up scope: [next ticket or PR scope]

### Unresolved

Unresolved outcomes are always Action: discuss and are not Findings.

1. **Title**
   File: path/to/file:line
   Evidence: [source evidence]
   Validation attempted: [probe/check and result]
   Remaining question: [what could not be established]
   Decision: post to PR | keep private / investigate | discard

### Recommended Actions

- [ ] Fix fix-now Finding #1
- [ ] Discuss Finding #1 or Unresolved item #1
- [ ] Decide Unresolved item #1
```
