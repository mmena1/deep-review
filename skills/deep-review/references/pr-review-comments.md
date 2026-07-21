# Add PR Review Comments

Use this only for a confirmed GitHub PR when the user asks to add comments.

1. Re-check the PR state and reviewed head SHA with `gh pr view --json state,mergedAt,headRefOid`. Stop if it is closed, merged, or changed.
2. Draft concise inline comments in `references/review-tone.md` for direct findings, validated findings, and unresolved questions the user explicitly chose to post.
3. Get per-comment approval with target file/line.
4. Re-check PR state and head SHA immediately before posting.
5. Submit one review with `gh api POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews`, `event: COMMENT`, an empty `body`, and the approved inline `comments` array. Add a top-level body only when the user explicitly requests a summary.
6. Place each comment on a changed line; move an unresolvable target to the nearest relevant changed line and adjust its wording.
7. Verify the expected comment count with `gh api repos/{owner}/{repo}/pulls/{pr}/comments`.
