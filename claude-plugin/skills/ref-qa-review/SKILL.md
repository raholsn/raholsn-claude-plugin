---
name: ref-qa-review
description: Delegate to the qa subagent for test coverage analysis, edge cases, regression risk and integration gaps. Internal sub-skill.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# QA Review

Internal sub-skill. Runs the `qa` subagent against a change, either uncommitted
code or a PR diff, and surfaces coverage gaps.

**Requires** `$WORK_DIR` and one of:

- A PR diff file path, typically `$WORK_DIR/pr-diff.txt`, used by `code-review`.
- A reference to the uncommitted changes, used by implementing workflows.

## Process

### 1. Delegate

Delegate to the **qa** subagent with:

- The change scope: a diff path, or "review uncommitted changes".
- `$WORK_DIR`.
- The task brief and acceptance criteria when available, with missing requirements
  identified rather than inferred from the implementation.
- The repo path, so it can read the guidance file and the existing tests.
- The pack's testing document path, when the profile configures one.

That last input matters more here than anywhere else in the engine. Without it
the agent has to infer the project's test level from the code, and an agent that
guesses wrong produces findings that read as coverage gaps but are really style
disagreements.

The agent writes `$WORK_DIR/qa-feedback.md`.

### 2. Read findings

Use the severity definitions in the QA agent's instructions.
Missing tests alone are not critical defects. Require a concrete uncovered
scenario and assess its impact, including existing validation evidence.

## Done

QA findings are read, and either addressed during implementation or surfaced to
the user during PR review.
