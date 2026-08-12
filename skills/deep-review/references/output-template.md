# Code Review Output Template

```markdown
## Code Review Results

Reviewed: [confirmed target]
Base / head: [base] / [head SHA]
Publication: [PR # / local only]
Reviewers: [selected analysis reviewers] + validation reviewer [run / not needed]

**Headline takeaway:** [most important finding, or "No findings"]

### Findings

#### Fix now

1. **Title** — Direct | Validated | Action: fix-now
   File: path/to/file:line
   Severity: blocker | high | medium | low
   Evidence: [source evidence or validation result]
   Why it matters: [impact]
   Suggested fix: [concrete code snippet]

#### Discuss

1. **Title** — Direct | Validated | Action: discuss
   File: path/to/file:line
   Severity: blocker | high | medium | low
   Evidence: [source evidence or validation result]
   Why it matters: [impact]
   Discussion prompt: [question or tradeoff to resolve]

#### Follow-up

1. **Title** — Direct | Validated | Action: follow-up
   File: path/to/file:line
   Severity: blocker | high | medium | low
   Evidence: [source evidence or validation result]
   Why it matters: [impact]
   Follow-up scope: [what the follow-up PR/ticket should cover]

### Unresolved Questions

Unresolved questions are treated as **Action: discuss**.

1. **Question**
   File: path/to/file:line
   Evidence: [source evidence]
   Validation attempted: [probe/check and result]
   Decision: post to PR | keep private / investigate | discard

### Recommended Actions

- [ ] Fix fix-now finding #1
- [ ] Discuss discuss finding #1
- [ ] Create follow-up ticket for follow-up finding #1
- [ ] Decide unresolved question #1
```
