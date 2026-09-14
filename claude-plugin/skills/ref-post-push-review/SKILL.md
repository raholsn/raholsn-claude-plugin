---
name: ref-post-push-review
description: After pushing, review the PR with the functional-reviewer agent, post findings as comments, then address the unresolved actionable threads with the comment-fixer agent. Internal sub-skill.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Post-Push Review & Fix

Internal sub-skill. Runs the review-then-fix pass against a pushed PR.

The workflow uses this instead of the standalone review and comment-fixing
commands, so the main workflow depends on two agents rather than on two
user-facing skills.

## Caller contract

| Input | Default | Notes |
|---|---|---|
| `pr_url` | none | Required |
| `work_dir` | `$WORK_DIR` | Artifacts land here |
| `cli` | the profile's `vcs.cli`, else `gh` | The host CLI |
| `signature` | the profile's `tool_signature` | Marks comments this tool wrote |
| `post_comments` | `all` | `all`, `critical_warnings`, or `none` |
| `auto_fix` | `true` | Address threads without asking one by one |

## The host operations this needs

The engine needs these operations from the host. Use the syntax the configured
`cli` documents for each. For a GitHub host these are `gh` commands, with
unresolved-thread listing and thread resolution going through its GraphQL API,
because the REST comments endpoint cannot tell you what is already resolved.

1. Read PR metadata: title, state, base branch, changed files, commits.
2. Read the diff.
3. Post a review comment anchored to a file and line.
4. Post a general PR comment.
5. List review threads with their resolved state.
6. Resolve a thread.
7. Read general PR comments, review summaries, and complete thread replies.
8. Reply to a thread or general comment.

Paginate all listings, including nested replies. If resolution state is
unavailable, record it as unknown. General comments have no thread-resolution
state. Unsupported resolution is reported as a manual follow-up, never faked.

## 1. Review

Fetch PR metadata and the diff, writing each to its own file under `work_dir`.
**Do not paste the full diff into the conversation.**

Delegate to the **functional-reviewer** subagent against those files. Supply the
existing task brief and acceptance criteria from this work session, plus the
repo path and configured company document paths. If requirements are unavailable,
record that limitation rather than inventing product intent. It grades findings
`CRITICAL`, `WARNING` or `SUGGESTION`, the same vocabulary every reviewer in this
engine uses.

Consolidate and dedupe findings before posting. When two findings overlap, keep
the more specific one: a named missing check on a given line beats a general
"validate input".

## 2. Post

Honour `post_comments`:

- `all`: post every finding.
- `critical_warnings`: post only those two tiers.
- `none`: write the findings to `work_dir` and post nothing.

Anchor a finding to its file and line when it has one; otherwise post it as a
general comment. End every posted comment with a one-line footer containing
`signature`.

That footer is load-bearing. The fix pass in section 3 identifies its own
tool's threads by matching it, so the same `signature` value must be used on both
sides. It comes from the profile precisely so that renaming the tool cannot break
the loop.

## 3. Fix

Fetch current threads, general comments and review summaries with full replies.
Select actionable findings from this tool by the configured signature on the
original finding, including those authored by the PR author. Other reviewers'
items are included only when the parent explicitly supplies that scope. Exclude
resolved threads, acknowledgements and duplicate findings. Preserve full source
conversations for assessment against the prepared checkout below.
`post_comments: none` creates no new host items to fix; it does not authorize
publishing the unposted findings during this step.

Before individual assessment or edits, create a fresh task-feedback folder under
`work_dir` for this pass. Save the raw source snapshot and write `index.md` plus
one ordered `001-<source-id>.md` file per selected item. The index records PR/head,
fetch time, scope limitations, item links/statuses and excluded IDs with reasons.
Each item preserves its source ID/URL, author, location, host state and full
conversation, followed by pending assessment, action, validation/delivery and
reply/resolution fields. Keep replies with their thread; split independent
requests with a source-ID suffix and track their shared thread. Resolution must
wait until all requests in that thread have an eligible disposition.

Before edits, read the PR source repository, branch and head commit. Verify the
repo identity and inspect working-tree status and local commits. Reuse a clean
checkout at that head, or create an isolated worktree at the recorded head;
preserve unrelated work and do not blindly pull or switch the user's checkout.
Record the explicit source push destination, including forks.

First delegate to **comment-fixer** with `phase: assess`, the task-feedback index
and item paths, prepared repo, starting revision, requirements and company context.
It explores every item sequentially and records evidence and proposed actions
without editing code, even when `auto_fix` is true.

Once every selected item is assessed or explicitly limited by missing evidence,
write `assessment.md` in the task-feedback folder. Include each item's ID/link,
claim, verdict, concrete evidence, proposed action, validation needs and questions.
Reconcile overlapping or conflicting proposals and present the entire assessment
to the user before applying any fix. Keep this presentation even in automatic
mode; compact mode shortens entries rather than omitting items.

With `auto_fix: false`, offer **Fix**, **I will review manually**, or **Ignore**
for every item after presenting the completed assessment, and wait for choices
by item ID. Fix authorizes the supported proposed correction. Manual review and
Ignore leave code and PR comments untouched; record manual follow-up separately
from intentional no-action decisions. Unanswered items stay pending. If Fix has
no supported correction, clarify rather than inventing an edit or substituting
reply/resolution permission. With `auto_fix: true`, continue after presenting it without
an extra approval pause. Then delegate `phase: apply` with the selected actions.
The agent applies items sequentially and updates their files/index. Recheck later
proposals against earlier fixes; record shared dependencies and defer unsafe
changes. Material changes to interactive approvals require a revised decision.

The agent owns local analysis/edits and draft replies only. This caller owns
validation, commits, pushes, replies and resolution, using the returned per-item
files to distinguish changes from no-change dispositions and deferred items.

The fixer's doctrine, which is the reason this step exists at all:

- Do **not** assume the reviewer is correct. Read the code and form your own
  understanding before evaluating the comment.
- If the concern is valid, form your own solution. Do not default to the
  reviewer's suggested fix.
- If the concern is invalid, build the case with evidence from the code.

With `auto_fix` true, apply the clear-cut fixes without prompting per comment,
and leave anything ambiguous, risky, conflicting or product-dependent unresolved,
recorded in the summary.

When code changed, run the caller's validation and inspect the final diff. Commit only
intentional fixes after validation passes. If validation fails or is unavailable,
leave code-fix items open; a skipped check is not passing. Delivery with a stated
validation limitation needs the user's explicit acceptance.
When no code changed, skip commit and push and finalize eligible no-change
responses. Skipped or deferred items remain open.

Re-read the source branch and head before pushing. If it advanced, incorporate
the new work, reassess affected comments and revalidate. Stop on unresolved
conflicts or repeated concurrent movement; never force push to bypass it. Push
to the recorded PR source branch when authorized (`auto_fix: true` permits this;
otherwise use existing authorization or ask). Confirm the PR contains the fix
commit. Failed or declined delivery leaves affected threads open.

Only then post code-fix completion replies with the commit and validation result,
and resolve the corresponding threads. No-change dispositions can be finalized
without a new commit when supported by current PR evidence and authorized.
Re-read conversations before posting, reassess new discussion, and avoid duplicate
replies. Append the configured signature to replies. General comments get a
linked reply and addressed status, not a thread-resolution claim. Record each
host action only after confirmation, retaining pending actions on failure.
Update the corresponding item file and index with validation, delivery and host
results. These files remain the record for the summary; do not create a competing
results list. Append newly discovered items before processing them.

## 4. Summarize

Report findings by severity, delivered fixes, local fixes pending delivery,
no-change dispositions, confirmed replies/resolutions, and deferred items with
reasons. Refresh remaining thread state and separately report unknown state and
unaddressed general comments. Include validation results or limitations; do not
replay the full review in the conversation.

## Done

The PR has been reviewed, findings are posted according to `post_comments`, the
selected items are addressed or explicitly left open with reasons, and local
fixes are distinguished from those validated and delivered to the PR.
