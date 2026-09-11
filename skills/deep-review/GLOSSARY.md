# Glossary

- **Hypothesis** — An admission-qualified scout concern about the committed target awaiting independent adjudication.
- **Finding** — A hypothesis independently established by the validator with final severity and evidence of actual reachability and impact.
- **Disproved** — A hypothesis rejected by validation; it is not user-visible.
- **Unresolved** — Validation was attempted but could not establish or reject a hypothesis; it is not a Finding and maps to `discuss`.
- **Not validated due to review failure** — A hypothesis the validator could not attempt because the run failed; it makes the review incomplete and is distinct from Unresolved.
- **Stated intent** — The change goal expressed by the target PR or commits; `unknown` when neither source provides it.
- **Action** — The recommended next step: `fix-now`, `discuss`, or `follow-up`.
- **fix-now** — A Finding with a small, unambiguous fix based on final severity and fix size.
- **discuss** — An Unresolved item or a Finding needing author context or a tradeoff decision.
- **follow-up** — A Finding that is real but too large or out of scope for the current change.

The protocol is defined in `references/review-protocol.md` and follows:

`hypothesis → validator → finding | disproved | unresolved`
