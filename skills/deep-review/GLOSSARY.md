# Glossary

- **Direct finding** — A concern established mechanically from source evidence; it needs no execution probe.
- **Candidate finding** — A concern raised by an analysis reviewer that needs a falsifiable validation hypothesis before it can become a finding.
- **Validated finding** — A candidate confirmed by the validation reviewer with a targeted probe, test, or execution result.
- **Unresolved question** — A candidate the validation reviewer could neither confirm nor disprove. It includes source evidence, attempted validation, and the remaining question; the user decides whether it is posted, kept private, or discarded. Unresolved questions are treated as `Action: discuss`.
- **Disproved** — A candidate contradicted by validation and excluded from review results.
- **Stated intent** — The change goal expressed by the target PR or commits; `unknown` for uncommitted work without either source.
- **Action** — The recommended next step for a finding in the report. One of `fix-now`, `discuss`, or `follow-up`.
- **fix-now** — A finding that is confirmed/likely, low-to-medium severity, and has a small unambiguous fix (about 20 changed lines or fewer). The report should include a concrete suggested fix.
- **discuss** — A finding that needs author context, a tradeoff decision, or further validation before anyone writes code. Plausible evidence, judgment-call tradeoffs, and unresolved questions map here.
- **follow-up** — A finding that is real but too large or out-of-scope for the current PR. The report should describe the follow-up scope rather than a code snippet.
