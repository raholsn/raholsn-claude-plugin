---
name: ref-understand-task
description: Build the shared task.md brief for a work session. Internal-only; used by parent workflows after ticket, branch, and work-session setup.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Understand Task

Internal sub-skill. The implementing agent runs this before architecture,
planning, compliance, or implementation.

**Requires** `$WORK_DIR`, the resolved source snapshot, preflight artifact and
explicit implementation checkout. The snapshot supplies the ticket identifier
(possibly empty) and task description. The repo guidance file is optional; use it only when
the artifact says it was present.

## Goal

Produce `$WORK_DIR/task.md`: a concise, current task brief other subagents can
read without repeating broad discovery.

The implementing agent owns this file. Review and planning agents write their own
feedback files; the implementing agent folds those back into `task.md`.

## Process

### 1. Reuse the resolved source

Read the caller's source snapshot and preflight artifact first. Preserve selected
local issue IDs, PRD requirements/acceptance IDs, non-goals, dependencies and
source limitations. Do not widen a selected issue into its entire parent plan.
Fetch tracker content only when the snapshot lacks material detail or evidence
has changed; refresh the snapshot and record why. Reads never change tracker state.

For a description, use the supplied context without creating a ticket. Distinguish
facts, assumptions and unknowns. Resolve material scope, behavior, contract and
acceptance decisions before dependent implementation; a plausible technical path
is not permission to invent product behavior. Continue independent discovery.

On resume, reconcile the existing brief rather than replacing it with a fresh
summary that loses accepted feedback or completed work.

### 2. Reuse repo context

Use the repo guidance captured in the preflight artifact. If the guidance file
was present, do not reread it whole. If it was missing, infer from repo structure
and nearby docs without blocking.

Reopen only the specific sections this task needs:

- Service purpose and domain boundaries.
- Compliance triggers.
- Related repos and shared dependencies.
- Pre-test setup and post-test cleanup.
- Persistence, messaging, API, auth, config and testing conventions.

### 3. Find the relevant code

Search before reading. Start from terms in the ticket: route names, event names,
job names, service names, config keys, table or procedure names, domain nouns.

Keep command output small:

- Prefer listing matching filenames before reading their content.
- Use exact symbols and strings before broad domain terms.
- Cap exploratory searches with a match limit or a path filter.
- If a broad search is unavoidable, redirect it to
  `$WORK_DIR/discovery-raw/<topic>.txt`, then read only the relevant matches.

Prefer entry points, then follow dependencies inward. The general shape, whatever
the stack:

- Request handlers and their contract models.
- Event or message handlers and their contracts.
- Scheduled or background work.
- Domain services and business logic.
- Persistence, migrations and stored procedures.
- Configuration.
- Existing tests and fixtures.

Keep discovery bounded:

- Focus on directly involved files.
- If the relevant code is not clear after about 10 file reads, reassess the
  search terms and write down what is still unknown.
- Distinguish direct implementation files from adjacent reference files.
- For cross-repo discovery, answer one bounded question at a time, starting from
  an exact contract or helper name rather than sweeping a whole repo.
- Once a producer/consumer chain is confirmed, stop searching and capture the
  chain. Do not retain unrelated matches.

### 4. Identify behavior and validation

Capture current behavior, the likely behavior change, nearby tests, fixture and
setup patterns, the targeted validation commands built from the profile's
`build` block, and wider validation when the affected area has broad side
effects.

### 5. Identify constraints

Record what should shape architecture and planning:

- Schema migrations or stored-procedure changes.
- Message contract compatibility and handler idempotency.
- API validation, auth and error-response boundaries.
- External calls, retries, timeouts and failure recovery.
- Configuration changes, including any deployed-config surface named in the
  profile's `repo_roles`.
- Compliance-sensitive rules from repo guidance or referenced docs.
- Backwards compatibility, concurrency and rollout risk.

Skip any bullet the stack does not have. An empty Constraints subsection is
better than an invented one.

## Write `$WORK_DIR/task.md`

```markdown
# Task

## Summary
- Ticket / selected local issue:
- Source snapshot and PRD references:
- Non-goals and dependency evidence:
- Requested change:
- Current understanding:

## Acceptance / Questions
- Acceptance criteria:
- Open questions:

## Repo Context
- Service/domain:
- Relevant repo guidance notes:
- Compliance triggers:
- Related repos/docs:

## Code Areas
- Entry points:
- Implementation files likely involved:
- Adjacent/reference files:
- Discovery artifacts:

## Existing Behavior
- Current flow:
- Data/config/event dependencies:

## Tests / Validation
- Existing tests:
- Targeted commands:
- Wider commands:
- Regression/integration notes:

## Constraints
- Persistence:
- Events/idempotency:
- API/auth:
- External services:
- Config:
- Backwards compatibility/concurrency:

## Implementing Agent Notes
- Assumptions:
- Unknowns:
- Minimal files to read for implementation:
- Context to avoid rereading:
- Next review step:
```

Specific enough for another agent to review, without dumping long source
excerpts.

## Done

`$WORK_DIR/task.md` exists and is ready for `ref-architect-review`.
