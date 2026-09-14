---
name: work
description: Take a task from ticket or description through understanding, review, planning, incremental implementation, validation, PR, and retrospective. Employer-neutral; every specific comes from the profile.
disable-model-invocation: true
argument-hint: TICKET-123 OR one selected task description or planning artifact
---

# Work Process

## Sub-skills this composes

Invoke each by name at the step that calls for it. Do not preload them.
The `ref-*` skills supply supporting context for this workflow and can be
called directly without asking the user to invoke each step.

`profile`, `ref-cli-check`, `ref-service-check`, `ref-mcp-check`, `ref-ticket`,
`ref-git-preflight`, `ref-create-branch-and-pr`, `ref-work-session`,
`ref-understand-task`, `ref-architect-review`, `ref-compliance-review`,
`ref-apply-feedback`, `ref-delivery-planning`, `ref-context-usage-report`,
`ref-build-and-test`, `ref-review-loop`, `ref-update-pr-description`,
`ref-post-push-review`, `ref-session-retrospective`.

## Definition of Done

A successful session is complete only when all of these are true:

- The resolved task is implemented according to the acceptance criteria in `$WORK_DIR/task.md`.
- Applicable architect and compliance feedback is reconciled with evidence; unresolved required reviews or valid blockers prevent completion.
- Under normal commit scope, every active implementation step has `Status: implemented` with its intended commit recorded. Under explicit no-commit scope, completion means validated local changes and an accurate handoff of uncommitted steps.
- Applicable configured build and affected tests pass. Any unavailable validation is recorded accurately and its delivery limitation is explicitly accepted before committing or publishing.
- Reviewer feedback has no unresolved CRITICAL findings. WARNING findings are fixed or deliberately skipped with evidence and rationale.
- Required setup/cleanup is restored, task changes are delivered to the authorized local or remote destination, and unrelated preexisting work is preserved.
- The PR description, push and delivered-head verification are complete when publication is in scope. Local-only completion includes the prepared PR body and local results. A failed in-scope delivery is partial, not complete. The retrospective and handoff report the actual outcome. Post-merge hooks are pending until a merge is confirmed and the follow-up is authorized; they are not a prerequisite for completing a PR handoff.

If the workflow cannot complete, report the checkout, branch, session path, phase, blocker, attempts and next action. Ask only for a decision or access that is actually needed; do not manufacture a question for an external failure.

## Input and delivery scope

This command implements **one selected actionable task**. It can follow
`grill-me-pragmatic` → `write-requirements` → `plan-implementation`: use the selected issue and relevant
PRD decisions as context, not authorization to implement the entire PRD or backlog.
For a planning file containing multiple tasks, resolve the selected task before
branch creation or external writes. Preserve dependencies, acceptance criteria,
non-goals and unresolved decisions in the task brief. An unmet prerequisite or
materially ambiguous scope must be resolved before implementation.

An invocation requests the end-to-end implementation workflow, including local
commits, pushing the task branch and creating/updating its PR. Honor narrower
instructions such as local-only or no push throughout. It does not authorize
merging, deploying, posting review comments or sending colleague messages. Keep
those actions separate and use existing explicit authorization when available.
A description alone does not request creation of a tracker ticket; it can run
ticketless even with a tracker configured. Use `create-linear-ticket` separately
when ticket creation is requested.

## Workflow Rules

- **Profile first.** Step 0 resolves the profile. Every later step reads values from it by dotted key. If you find yourself about to type a company name, a repo name, a branch name, or a build command into this workflow, it belongs in the profile instead.
- **Optional configuration.** A missing optional profile block skips its step and is recorded. Invalid configuration or a missing prerequisite for the requested action is reported and resolved before dependent work. See `profile` for the full rule.
- Delegation ownership: references that delegate already own that delegation. Call them from the main agent instead of wrapping them in another agent. Pass bounded tasks and explicit artifact paths.
- Subagent settings: use the plugin's named agents (`preflight`, `cross-repo-explorer`, `architect`, `planner`, `functional-reviewer`, `comment-fixer`, `retrospective`); do not override their model or tool settings. Effort is tiered per role in the agent definitions: deep-reasoning roles (`architect`, `comment-fixer`) run highest; discovery and planning roles run mid; `preflight` runs cheapest. Spawn unnamed subagents at a mid tier.
- Handoffs: after each subagent step, read only the named artifact(s), apply decisions, then continue from the artifact instead of raw output.
- Artifacts: create `$WORK_DIR` before delegation. Use exact session paths for every output. Save review inputs, validation logs and outcomes by step and attempt; never consume another run's artifacts.
- Lifecycle: after consuming a subagent artifact, treat that agent as closed; start the next phase with a fresh agent instead of continuing an old one.
- Context budget: save noisy discovery/diff/build output to artifact/log files, read only relevant lines, and load shared references only for the current step's concern.
- Step discipline: report the current phase and selected step. Implementation-step files stay outside the repo and are never added to code commits. Run independent checks/reviews in parallel; keep dependent mutations and feedback reconciliation sequential.
- Diagnose and fix recoverable failures. Reconcile conflicting reviewer claims against evidence before escalating. Stop dependent work when the same blocker persists after three attempts or requires unavailable access/product judgment. Save the state and continue independent work where useful.

## 0. Resolve Session and Preflight

The main agent identifies the target repository from the explicit request or
current checkout. Resolve an ambiguous target before delegating; never assume
`roots.repos` itself is the implementation repository. Apply **`profile`** for
that target and retain one effective snapshot, including repository overrides.

Apply **`ref-work-session`** with `artifacts_root`, `repo_path`, the raw task
request and an explicit `resume_dir` only when resuming. Save the resolved profile
snapshot without credentials and delivery scope in the session. `$WORK_DIR`
exists before any subagent writes. For a resumed session, follow the resume
contract below rather than overwriting its task and plan.

Delegate once to **`preflight`**, supplying the effective profile, exact repo,
source selection, delivery scope, `$WORK_DIR/preflight.md` and
`$WORK_DIR/source-context.md`. It resolves the source read-only and checks
applicable tools, services, tracker access and Git state. It returns blockers to
the main agent instead of asking the user or changing the checkout. On resume,
archive the previous source/preflight snapshots before refreshing them and compare
changed requirements with the existing task brief.

Read both artifacts. Resolve scope, missing requirements and consequential
choices before dependent work. Ensure source acceptance criteria, PRD/local issue
IDs, non-goals and dependency evidence are present. Optional configuration may
be absent; required access and unmet implementation dependencies cannot be waived
by labeling a check skipped. No ticket is created or advanced by preflight.

## 1. Prepare Implementation Checkout

Act on the Git preflight report. For new work, create the task branch from the
resolved base commit; use an isolated worktree if the current checkout contains
unrelated work or is on another task. For resume, verify branch ownership and
existing commits. Never silently transplant dirty changes or discard user work.

Use branch/title naming from **`ref-create-branch-and-pr`** as reference only.
Do not execute its combined branch/push/PR helper here. Publish after validated
implementation commits exist. Resolve collisions by inspecting existing work or
choosing an unused name, not by resetting an existing branch.

Record absolute implementation checkout, repository identity, base remote/ref
and commit, task branch, push remote/repository and starting HEAD in `session.md`.
All later Git, build, discovery and reviewer calls use this checkout explicitly,
including when it differs from the user's original directory. Reconcile any
checkout-specific configuration without losing the selected repository's profile
and guidance. `.repo` retains source identity and the session records worktrees.

### Resume contract

Read `session.md`, `task.md`, the delivery plan and step records before writes.
Verify the recorded task/repo, checkout, branch, actual commits and any existing
PR. Archive obsolete evidence instead of treating it as current. A recorded
`implemented` step requires its intended changes still present in the current
history and relevant validation still applicable. An uncertain commit or push is
reconciled against Git/host state before retrying.

Resume the first incomplete phase. Do not regenerate the whole plan or reset
completed steps on every invocation. Re-plan only the affected remaining scope
when requirements, dependencies or implementation changed. Preserve stable step
IDs and prior commit evidence. Record externally completed work explicitly.

## 2. Task Understanding

Apply **`ref-understand-task`** with the selected source snapshot, preflight artifact, implementation checkout and `$WORK_DIR`. It writes or reconciles `$WORK_DIR/task.md`. Do not refetch unchanged ticket context already captured in preflight. Resolve blocking product/contract decisions before planning; low-risk assumptions remain explicit.

Implementation-agent discovery is scoped to the resolved implementation repo only. Do not search or read related repos locally when cross-repo explorers are active.

For cross-repo or broad discovery, spawn `cross-repo-explorer` **SUBAGENT** explorers. Each explorer answers one bounded question and writes a concise artifact named `$WORK_DIR/cross-repo-<topic>.md`.

Wait for all explorer artifacts before step 3, update `$WORK_DIR/task.md` from those artifacts, then close the explorer agents. Do not keep broad search output or unrelated source excerpts in the implementation agent.

## 3. Architectural Feedback + Compliance Review

Apply the following references in parallel against `$WORK_DIR/task.md`; each owns its reviewer delegation:

1. Apply **`ref-architect-review`** with `<task-description>`, `$WORK_DIR/task.md`, and `$WORK_DIR`.
   - Outputs `$WORK_DIR/architect-feedback.md`.
2. Apply **`ref-compliance-review`** with `<task-description>`, `$WORK_DIR/task.md`, and `$WORK_DIR`.
   - Capture every returned domain artifact path. Multiple domains need distinct files.
   - With no configured reviewer, do not spawn one. Record any explicit required domain review as unreviewed and resolve that prerequisite; absence of configuration is not compliance approval.

3. Apply **`ref-apply-feedback`** with `$WORK_DIR`, `$WORK_DIR/task.md`, and `$WORK_DIR/architect-feedback.md`.
4. Apply **`ref-apply-feedback`** to every returned compliance artifact from this invocation, including limitations and blockers. Do not assume a single fixed filename or consume a stale prior file.
5. Close the architect and compliance reviewer agents after the feedback has been applied.

## 4. Delivery Planning

Apply **`ref-delivery-planning`**, which delegates to the `planner` agent, with `<task-description>`, `$WORK_DIR/task.md`, and `$WORK_DIR`.

It outputs `$WORK_DIR/delivery-plan.md` and an ordered set of `$WORK_DIR/implementation-steps/*.md` files.

After reading the plan and step files, close the planner agent.

## 5. Prepare Implementation Context

Before the implementation loop, read only:

1. `$WORK_DIR/task.md`
2. `$WORK_DIR/delivery-plan.md`
3. The next implementation-step file selected in step 7
4. Narrow repo files needed for that step

Load applicable configured company references on demand for the changed area. Repository guidance does not silently replace explicit company requirements:

- `knowledge.conventions` when its rules apply to the changed code or design.
- `knowledge.testing` when the step adds or changes tests.
- `knowledge.domains.<area>` when the step touches that domain.

Resolve reference paths according to the profile. If no references are configured, use repository guidance and source evidence. If a configured reference cannot be resolved, report that limitation rather than treating it as absent. Pass applicable paths explicitly to reviewers.

## 6. Context Usage Report

Apply **`ref-context-usage-report`** with `$WORK_DIR`, `$WORK_DIR/task.md`, and `$WORK_DIR/delivery-plan.md`.

Run this locally in the implementation agent, not in a subagent. It reports the implementation agent's own context status and writes `$WORK_DIR/context-usage.md` beside `$WORK_DIR/task.md`.

The report must copy visible status-line values for `context-used`, `total-input-tokens`, and `total-output-tokens` when present. It must not include subagent token/context usage. It may list preflight, cross-repo discovery, architect/compliance review, and delivery-planning artifact paths consumed by the implementation agent.

After writing it, treat `$WORK_DIR/context-usage.md` as the implementation loading plan: avoid files/outputs listed under "Can summarize or drop" and prefer the "Suggested next-step loading strategy".

## 7. Implement Next Step

Repeat steps 7-9 for the ordered step IDs in the current delivery plan. Ignore archived/superseded files; directory glob order alone is not the plan.

1. Read the current plan's ordered step paths and recorded status.
2. Read only the first file with `Status` other than `implemented` (missing means `pending`), plus dependency step files named by that file; mark it `in_progress`.
3. Verify dependencies against completed code/decision evidence. Resolve material blockers before implementation; nonblocking questions remain explicit.
4. Otherwise, plan and implement only the selected step.
5. Record required validation setup for step 8; do not run setup twice outside the validation reference.

## 8. Validate & Review

1. Apply **`ref-build-and-test`** with `affected_only: true`. Run the applicable configured checks independently and any required repo checks. Missing build configuration does not discard configured tests. Do not invent command syntax; resolve required missing configuration before relying on validation. Record each check as passed, failed, not applicable (with reason), or unavailable. A skipped check is never a pass. If required validation is unavailable, present the exact limitation and obtain explicit acceptance before committing or publishing; failed checks remain blockers.
2. Save the selected step's complete diff, including intended new files, and base/HEAD/working-tree identity under `$WORK_DIR/reviews/<step-id>/<attempt>/`. Pass this explicit `diff_source`, a feedback path there, the checkout, task and step file to **`ref-review-loop`** with `reviewer_agent: functional-reviewer` and the applicable revalidation call. The reference owns delegation. Refresh saved diff inputs after edits before another pass.
3. Validate reviewer claims against source evidence. Fix supported findings, document rejected claims and resolve material unknowns. After fixes, rerun affected checks and review material changes. Archive validation output under the step/attempt before another step can overwrite shared log paths. The gate applies to the final diff being committed, not an earlier revision.

## 9. Commit

When validation and review are clean (or only deliberately-skipped findings remain):
- Confirm repo guidance post-test cleanup, and `build.post_test_cleanup` when set, are restored.
- Inspect staged paths and content, then commit only the selected step using `vcs.commit_title_template` when set. Include intended new files, exclude unrelated edits and all external session artifacts. Honor an explicit no-commit scope by recording validated local changes and handing off without falsely marking the step committed.
- Only after the commit succeeds, mark the selected step `Status: implemented` and record its commit SHA and validation evidence in the step artifact. Keep `in_progress` on failure; reconcile the commit before retrying an uncertain operation.
- If any current-plan step is incomplete, repeat from step 7; otherwise continue to step 10. If a no-commit scope prevents separate implementation commits, deliver the validated local diff and report remaining commit steps rather than loop forever.

## 10. Verify the Whole Task and Prepare PR Description

Compare the complete task-branch diff against the intended PR base and check every
selected acceptance criterion against implementation and validation evidence.
Per-step passes do not establish end-to-end coverage. Record missing behavior,
integration checks and non-goal violations before publication. Run additional
checks only when cross-step effects, changed scope or required guidance justify
them. A no-change outcome needs evidence that the task is already satisfied and
must not produce an empty commit or PR.

Save the cumulative diff and revision identities. Obtain a functional review of
this cumulative change when earlier reviews did not cover it as a whole. Revisit
architecture and applicable domain reviews when the implementation changes their
assumptions, contracts or risk. Resolve findings and revalidate before delivery.
Record this gate's head and evidence in `session.md`.

Prepare the final PR title and body from the completed task and actual diff,
following the repo template. Record Changes / Validation / Risks accurately,
including skipped checks and accepted limitations. If the PR already exists,
apply **`ref-update-pr-description`** within the authorized scope. Otherwise keep
the prepared body for creation in step 11.

## 11. Summary, Push and PR

Summarize the implementation, commits, architect and review outcomes, optional
compliance outcome and validation. Recheck the recorded source branch and remote,
and detect concurrent changes before pushing. Incorporate and revalidate relevant
changes or report a conflict; never force push to bypass it.

Within the authorized scope, push the task commits and create or update the PR
using the configured host CLI, base, title, body and draft preference (default
`true`). Do not rerun the branch-creation helper against an existing branch.
Verify the PR points to the intended source head. On an uncertain push or PR
creation result, inspect remote state before retrying to avoid duplicate PRs.
A failed PR creation leaves the pushed branch available for recovery.

For local-only or no-push instructions, report the branch and prepared PR text,
mark publication and post-push steps pending, and continue to retrospective.
Otherwise report the confirmed PR URL. If `browser_open_cmd` is configured,
open that URL. Provide a copyable colleague note without sending it, and label
draft PRs as draft rather than claiming they are ready for review.

## 12. Verify Delivered Head and Address Findings

Fetch the intended PR metadata and full base-to-head diff through the configured
host, recording source repo, base/head SHAs and saved diff path under
`$WORK_DIR/reviews/delivery/<head>/`. Verify the PR contains the intended commits
and compare it with the cumulative change reviewed in step 10. Never call a
pushed review with the default local working-tree diff, which may be empty.

If the delivered change differs or has not received a cumulative review, apply
**`ref-review-loop`** in `single-pass` mode with this explicit saved `diff_source`,
checkout, task brief and feedback path. If the exact change already passed that
review, reuse its evidence instead of running an identical review again. Report
host CI checks as observed, including pending or unavailable; local validation
does not prove CI success. Resolve task-related failures required by repository
policy, or report the external blocker without claiming delivery is complete.

For supported new findings, prepare the verified source checkout, fix, validate,
commit and push within existing scope. Refresh the whole-task gate when fixes
change acceptance behavior, then verify the new delivered head and PR body.
Do not resolve findings based on an undelivered local fix.

Review findings stay local unless their publication is explicitly authorized.
When posting and managing review threads is requested, call
**`ref-post-push-review`** with the exact PR and authorized scope; it owns those
review/fix delegates. Do not separately launch the same review twice. Uncertain
host writes are reconciled read-only before retrying.

## 13. Post-Merge Hooks

This workflow does not merge the PR. If `post_merge_hooks` is configured, record
applicable hooks as pending in the handoff while the PR is open. A closed but
unmerged PR does not qualify. Do not wait indefinitely for someone to merge.

Run hooks only after the host confirms the intended PR was merged and existing
user authorization covers each follow-up action. Resolve hook paths against
`pack`; surface missing configuration before execution. Record completed hooks
and their evidence to avoid replaying external actions on resume. Report pending,
failed and completed hooks distinctly. Skip when none are configured.

## 14. Retrospective and Handoff

Apply **`ref-session-retrospective`**, which delegates to the `retrospective`
agent. Return the branch and PR URL when present, completed scope, validation
results and limitations, unresolved findings, and pending publication or hooks.
Link `$WORK_DIR/task.md` and the delivery/step artifacts for resumption. Distinguish
completed implementation from a blocked run or local work pending delivery.
