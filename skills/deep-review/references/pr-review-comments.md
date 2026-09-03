# Add PR Review Comments

Use this only for a confirmed GitHub PR when the user asks to add comments.

1. Re-check the PR state and reviewed head SHA with `gh pr view --json state,mergedAt,headRefOid`. Stop if it is closed, merged, or changed.
2. Draft concise inline comments in `references/review-tone.md` for Direct findings, Validated findings, and Unresolved Candidates the user explicitly chose to post. Use committed code and team-visible evidence whenever practical; ignored context is private/local and must not be named or quoted unless the user explicitly approves it.
3. For every Direct finding, Validated finding, and user-selected Unresolved Candidate, declare its comment scope before constructing the payload: point, method/design, or compact range. Record the proposed source anchor and a brief rationale for its semantic representativeness.
4. Construct the GitHub payload from the declared anchor. A point comment has only its endpoint `line` and `side`; a compact range has `start_line`, `start_side`, `line`, and `side`. A method/design comment normally anchors the relevant method or function declaration. Do not publish a method/design comment at an arbitrary implementation line.
5. Validate each payload mechanically against the current head: path, side, changed-line/range eligibility, and complete range fields. Then independently check semantic representativeness: the anchor must be the smallest location that credibly makes the comment's claim intelligible. Reject mismatches rather than silently moving or widening the anchor.
6. If the preferred semantic anchor is not commentable, use only the smallest relevant changed line or compact range as an explicit anchor fallback, preserve the scope in the wording, and record the fallback rationale. If no relevant changed location exists, do not publish the comment inline.
7. Get per-comment approval with the target scope and anchor.
8. Re-check PR state and head SHA immediately before posting. If the head changed, revalidate every finding and seek approval again for any changed comment body or anchor.
9. Submit one review with `gh api POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews`, `event: COMMENT`, an empty `body`, and the approved inline `comments` array. Add a top-level body only when the user explicitly requests a summary.
10. Validate the final payload again after any user coordinate change; approval does not bypass anchor validation.
11. Verify the expected comment count with `gh api repos/{owner}/{repo}/pulls/{pr}/comments`. Treat later `line: null` with intact `original_line` or `original_position` as GitHub coordinate remapping after a subsequent head change, not as proof that the initial anchor was wrong.
