---
name: ref-review-loop
description: Delegate to a reviewer subagent, address findings by severity, re-verify, and re-review while material fixes keep changing the diff. Internal sub-skill.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Review Loop

Internal sub-skill. Runs a reviewer against the uncommitted changes, addresses
its findings, and decides whether another pass is warranted.

**Requires** `$WORK_DIR`. In `loop` mode, run `ref-build-and-test` or equivalent
validation first. In `single-pass` mode a build is optional; report unrun
validation instead of treating it as passed.

## Caller contract

| Input | Default | Notes |
|---|---|---|
| `reviewer_agent` | `functional-reviewer` | Any reviewer agent, including one from a pack |
| `feedback_file` | `$WORK_DIR/review-feedback.md` | One file per reviewer |
| `re_verify` | `ref-build-and-test affected_only:true` | What to re-run after fixes |
| `mode` | `loop` | `loop` iterates until findings settle; `single-pass` reviews once and stops |
| `diff_source` | `git diff` plus `git diff --cached` | A saved diff file path when reviewing a PR rather than a working tree |

In `single-pass` mode, run section 1 and then stop. Skip sections 2 through 4
entirely: the caller is collecting findings to present or post, not applying them.
`code-review` uses this. Applying fixes inside a review of someone else's pushed
branch is not the caller's decision to make.

## 1. Delegate

Delegate to the **`<reviewer_agent>`** subagent with the explicit `diff_source`,
`feedback_file`, `$WORK_DIR`, and requirements/task brief when available. A saved
PR diff must be reviewed as supplied, not replaced by local `git diff` output.

The reviewer reads the supplied change source and any available task brief or
implementation-step file. Pass architecture feedback only when it belongs to
this change and is relevant; missing requirements limit acceptance claims.

It reopens the repo guidance file, a README, or pack knowledge only when the task
artifacts lack a convention it needs to judge the change.

## 2. Address findings

Read `<feedback_file>`.

- **CRITICAL.** Assess against the code and requirements. Fix supported findings;
  reject an unsupported claim with concrete evidence. An unresolved valid critical
  finding blocks delivery.
- **WARNING.** Fix unless there is a specific reason not to. Write down every
  skip and its reason.
- **SUGGESTION.** Use judgement. Apply when it improves the code.

## 3. Re-verify after fixes

If any fixes were applied, run `re_verify`. That validation call owns required
setup and cleanup; do not run setup a second time outside it. Refresh any saved
diff after fixes before re-review, recording the new revision or working-tree
identity. Preserve each pass's feedback rather than overwriting its evidence.

## 4. Re-review if needed

If fixes materially changed the diff, delegate to **`<reviewer_agent>`** again.

Continue while each pass produces new actionable findings and the fixes make
meaningful progress. Stop and ask the user when the same blocker repeats, when
findings conflict, or when another pass is unlikely to improve the result.

## Done

Either the review came back clean, or every CRITICAL and WARNING was addressed
and the user has been told about any deliberately-skipped findings.
