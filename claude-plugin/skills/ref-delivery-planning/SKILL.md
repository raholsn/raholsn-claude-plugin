---
name: ref-delivery-planning
description: Delegate to the planner subagent to decide whether the reconciled task ships as one commit or several, and write one step file per commit. Internal-only.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Delivery Planning

Internal sub-skill. Runs the `planner` subagent to produce the plan the workflow
implements against.

**Requires** `$WORK_DIR` and `$WORK_DIR/task.md`.

`task.md` is the source of truth. Architect and plan-stage compliance feedback
should already be reconciled into it before this runs.

## Process

### 1. Delegate

Delegate to the **planner** subagent with the task description,
`$WORK_DIR/task.md`, and `$WORK_DIR`.

The planner should not repeat source discovery unless `task.md` lacks a detail
needed to split the work. If it must inspect code, it uses narrow reads and
writes the reason into the plan.

It writes:

- `$WORK_DIR/delivery-plan.md`
- One file per commit under `$WORK_DIR/implementation-steps/`, ordered by
  filename.

For single-commit delivery, exactly one file. For incremental delivery, one file
per planned commit with numeric prefixes such as `01-add-schema-migration.md`,
`02-add-service-behavior.md`.

### 2. Rubric

Judge the plan against this before writing files:

- **Smallest safe commits.** Split only where each commit can build, be reviewed,
  and leave the repo coherent. Avoid artificial splits of tightly coupled work.
- **Dependency order.** Schema, contract and config foundations before the code
  that consumes them. Make every step's dependencies explicit.
- **User-visible behavior.** Identify the behavior, API, event or config surface
  each step affects, including backwards compatibility and rollout.
- **Rollback and migration risk.** Call out schema, data or otherwise
  irreversible changes, plus the recovery path.
- **Test mapping.** Map each step to targeted validation built from the profile's
  `build` block, and to wider validation when side effects justify it. State the
  reason when no test is available.
- **Config impact.** Identify environment variables, feature flags, and any
  deployed-config surface named in the profile's `repo_roles` or handled by a
  `post_merge_hooks` entry.

Every commit must satisfy the applicable configured validation commands.
Resolve build, affected tests and full-suite checks independently: a missing
`build.build_cmd` does not suppress configured tests. Use explicit repository
guidance as applicable, and record unmet prerequisites or missing required
checks. Only plan against review alone when no automated checks are available,
and state that limitation rather than inventing a gate or claiming a pass.

`delivery-plan.md` must include the verdict, an explicit ordered list of active
step IDs and paths, the step sequence rationale, and rubric risks or tradeoffs.
On resume, preserve completed steps and their IDs/evidence. Reconcile only affected
remaining work; archive superseded files and exclude them from the active list.
Do not overwrite a prior plan merely because this reference was invoked again.

Each step file must include:

- Status (`pending`, `in_progress`, `implemented`; new files start `pending`)
- Scope
- Files likely affected
- Dependencies on earlier steps
- Validation commands
- Done criteria
- Minimal context to load
- Context to avoid rereading

### 3. Read the plan

Read `$WORK_DIR/delivery-plan.md`, then scan `$WORK_DIR/implementation-steps/` by
status. Read only the first pending step file unless its dependency notes require
earlier ones. The verdict is one of:

- **SINGLE COMMIT.** One step file. The caller runs implement, test, review and
  commit once.
- **INCREMENTAL DELIVERY.** Several step files. The caller repeats that cycle per
  planned commit.

## Done

The caller has a clear strategy and one or more concrete step files. The files
persist for the rest of the workflow.
