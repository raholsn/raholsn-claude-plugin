---
name: ref-apply-feedback
description: Apply review feedback artifacts into the shared task.md during a work session. Internal-only; used by parent workflows after feedback files are written.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Apply Feedback

Internal sub-skill. The implementing agent uses this to update
`$WORK_DIR/task.md` from one or more feedback files.

**Requires** `$WORK_DIR`, `$WORK_DIR/task.md`, and at least one feedback file.

## Inputs

Typical feedback files:

- `$WORK_DIR/architect-feedback.md`
- `$WORK_DIR/compliance-plan-review.md`
- `$WORK_DIR/delivery-plan.md`
- `$WORK_DIR/review-feedback.md`

The caller decides which to apply at the current step.

Every reviewer in this engine grades findings as `CRITICAL`, `WARNING` or
`SUGGESTION`, so this skill can consume any of them without special-casing the
source. Phase verdicts differ by phase and are read as written.

## Process

### 1. Read artifacts

Read `$WORK_DIR/task.md` first, then each requested feedback file.

If a requested file is missing or empty, stop and surface the missing path. The
one exception is a compliance file the caller says was deliberately not written,
which is skipped without comment.

### 2. Classify feedback

For each item:

- **Accepted.** Update `task.md` with the constraint, validation requirement,
  implementation implication or open question.
- **Not applied.** Record the item and a short reason.
- **Blocked.** Record the blocker and stop before the next workflow step.

Treat these as blockers unless the feedback clearly says otherwise:

- A compliance verdict of `blocked`.
- Security, data loss, regulatory or irreversible migration concerns.
- Architect feedback saying the task direction is invalid or unsafe.
- Missing information that prevents a defensible implementation plan.

### 3. Update `task.md`

Prefer updating existing sections: `Constraints`, `Tests / Validation`,
`Code Areas`, `Implementing Agent Notes`.

Maintain a concise section near the end:

```markdown
## Feedback Applied
- Architect:
- Compliance:
- Delivery planner:
- Not applied:
- Blockers:
```

Omit empty bullets. Do not paste whole feedback files into `task.md`. Summarize
decisions and constraints.

### 4. Decide whether to proceed

- Blockers remain: stop and ask the user how to proceed.
- Feedback changed scope, validation or constraints: make sure `task.md` reflects
  that before the next step.
- All applied or deliberately skipped: continue.

## Done

`$WORK_DIR/task.md` is updated and has no unresolved blockers for the next step.
