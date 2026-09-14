---
name: ref-architect-review
description: Delegate to the architect subagent for architectural analysis of task.md. Internal-only; used by parent workflows before implementation.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Architect Review

Internal sub-skill. Runs the `architect` subagent against `$WORK_DIR/task.md` and
writes architectural feedback.

**Requires** `$WORK_DIR` and `$WORK_DIR/task.md`.

For a PR review, the caller also supplies a saved diff path and repo path when
available. Pass both to the architect and review the implemented changes against
the task brief. The brief records any unavailable requirements. Do not replace
the saved PR diff with unrelated working-tree changes.

## Process

### 1. Delegate

Delegate to the **architect** subagent with the task description,
`$WORK_DIR/task.md`, `$WORK_DIR`, and the supplied diff/repo paths when present.

The architect may read the repo guidance file and relevant source as needed, then
writes findings to `$WORK_DIR/architect-feedback.md`.

Its analysis covers concerns that hold in any stack:

- Idempotency and repeat delivery.
- Boundaries between externally reachable and internal surfaces.
- Contract compatibility for anything another service or client consumes.
- Concurrency and ordering.
- Error handling, retries and failure recovery.
- Timeout budgets, backpressure, worker/connection exhaustion, and queue lifecycle.
- Performance, resource use, scalability, query efficiency, and cache correctness.
- Data consistency, transaction boundaries, migrations, and safe rollout/rollback.
- Trust and tenant boundaries, observability, operability, and maintainability.
- Domain-specific compliance, as named by repo guidance or the profile's
  `compliance` triggers.

House architecture rules are not part of this skill. They come from the pack's
`knowledge.conventions`, which the architect reads when the profile provides it.

### 2. Finding format

Every finding must carry:

- **Severity:** `CRITICAL`, `WARNING`, or `SUGGESTION`.
- **Blocks planning:** `yes` or `no`.
- **Rationale:** why this matters for correctness, maintainability, rollout or
  compliance.
- **Impacted files/contracts:** known or likely files, APIs, events, procedures,
  tables, config keys or external contracts.
- **Recommendation:** the concrete constraint, design change, validation
  requirement or open question to settle before planning.
- **Evidence:** the affected code/configuration or dependency contract, the
  triggering failure/load scenario, expected impact, and any unverified assumptions.

```markdown
# Architect Feedback

## Verdict
- Planning status: proceed | proceed with constraints | blocked
- Summary:

## Findings

### <short finding title>
- Severity:
- Blocks planning:
- Rationale:
- Impacted files/contracts:
- Recommendation:
```

### 3. Apply

The caller applies the file into `$WORK_DIR/task.md` with `ref-apply-feedback`
before delivery planning.

## Done

`$WORK_DIR/architect-feedback.md` exists, follows the structure above, and is
ready to be applied into `$WORK_DIR/task.md`.
