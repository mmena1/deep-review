# Glossary

- **Hypothesis** — A concrete concern about the committed target that can be tested or investigated.
- **Direct finding** — A concern settled by the analysis reviewer with sufficient evidence. Evidence may come from deterministic source/control-flow analysis, existing tests, focused commands, or a disposable reproduction/probe. No validator investigation is required.
- **Candidate finding** — A credible concern the analysis reviewer could not settle within its permissions, environment, or reasonable verification budget. It must contain a falsifiable validation hypothesis.
- **Validated finding** — A Candidate subsequently confirmed by the validator.
- **Disproved** — The hypothesis was tested or investigated sufficiently and rejected; do not report it as a finding.
- **Unresolved** — The validator still cannot establish or disprove the Candidate.
- **Stated intent** — The change goal expressed by the target PR or commits; `unknown` when neither source provides it.
- **Action** — The recommended next step for a finding in the report. One of `fix-now`, `discuss`, or `follow-up`.
- **fix-now** — A finding that is confirmed/likely, low-to-medium severity, and has a small unambiguous fix (about 20 changed lines or fewer). The report should include a concrete suggested fix.
- **discuss** — A finding that needs author context, a tradeoff decision, or further validation before anyone writes code. Plausible evidence and unresolved candidates map here.
- **follow-up** — A finding that is real but too large or out-of-scope for the current PR. The report should describe the follow-up scope rather than a code snippet.

The state flow is:

`hypothesis → Direct if settled by specialist → discard if disproved → Candidate if still unsettled → validator → Validated / Disproved / Unresolved`
