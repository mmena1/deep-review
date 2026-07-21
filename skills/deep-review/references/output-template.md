# Code Review Output Template

```markdown
## Code Review Results

Reviewed: [confirmed target]
Base / head: [base] / [head SHA]
Publication: [PR # / local only]
Reviewers: [selected analysis reviewers] + validation reviewer [run / not needed]

**Headline takeaway:** [most important finding, or "No findings"]

### Findings

1. **Title** — Direct | Validated
   File: path/to/file:line
   Severity: blocker | high | medium | low
   Evidence: [source evidence or validation result]
   Why it matters: [impact]
   Suggested fix: [concise change]

### Unresolved Questions

1. **Question**
   File: path/to/file:line
   Evidence: [source evidence]
   Validation attempted: [probe/check and result]
   Decision: post to PR | keep private / investigate | discard

### Recommended Actions

- [ ] Fix finding #1
- [ ] Decide unresolved question #1
```
