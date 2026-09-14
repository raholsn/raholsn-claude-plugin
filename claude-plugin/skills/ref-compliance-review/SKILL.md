---
name: ref-compliance-review
description: Dispatch a domain compliance reviewer when the profile registers one whose trigger matches the task. Internal-only; used by parent workflows.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Compliance Review

Internal sub-skill. Conditional. Runs only when the profile registers a
compliance reviewer whose trigger matches this task.

**Requires** `$WORK_DIR` and `$WORK_DIR/task.md`.

For PR review the caller supplies a fresh requirements brief and saved diff.
Pass the diff and repo path when available to the domain reviewer, so it checks
the implementation as well as the stated intent. Report unknown requirements.

## Caller contract

| Input | Default | Notes |
|---|---|---|
| `compliance` | the profile's `compliance` list | `{trigger, agent}` entries |
| `knowledge.domains` | the profile's domain document map | Domain key to reference path, resolved against `pack` |
| `pack` | the profile's pack path | Base for configured relative reference paths |

## 1. Decide whether to run

**If `compliance` is absent or empty, return immediately.** Write nothing, spawn
nothing, and report `no compliance domains configured`. This does not establish
that no obligations apply. If supplied repo guidance explicitly requires a
domain review, report that requirement as unreviewed because no agent is configured.

Otherwise, read `$WORK_DIR/task.md` and match each entry's `trigger` against the
repo name, the service/domain and changed scope recorded in Repo Context, and
the compliance triggers captured from repo guidance. Record the source and reason
for a match. A repo-wide review requirement in guidance applies even when the
changed files do not name the domain directly.

- Exactly one match: run it.
- Several match: run each, writing one file per reviewer.
- No match: write `$WORK_DIR/compliance-plan-review.md` recording that no
  registered domain applies, and stop.
- Ambiguous: ask the user once, naming the candidates.

## 2. Check the agent exists

A cross-plugin agent call fails hard when the agent is absent, so verify the
`agent` value resolves before dispatching. If it does not, report the missing
agent name and treat compliance as unreviewed rather than letting the workflow
crash. Say so in the artifact; do not silently continue as if approved.

## 3. Resolve domain context and dispatch

For each matched domain, resolve its configured `knowledge.domains` document
against `pack`, along with any relevant references explicitly named in repo
guidance or the task brief. Pass the document paths and applicability rationale
to the selected agent. The agent reads the relevant rules before assessing the
change and also uses any domain skills its own definition preloads.

Do not assume the agent inherits references loaded by the parent. Do not invent
rules when a reference is absent. If a configured document cannot be read, or
required rule/version/jurisdiction information is missing, report what remains
unreviewed instead of claiming approval. When no separate document is configured,
the agent can use its own domain references and supplied guidance, naming its sources.

Delegate to the matched agent with the task description, `$WORK_DIR/task.md`,
`$WORK_DIR`, the resolved domain reference paths and applicability rationale,
and any supplied diff/repo paths. It writes
`$WORK_DIR/compliance-plan-review.md` (or one distinct file per matched domain,
returning every path to the caller).

The review must include:

- **Verdict:** `not_applicable`, `approved`, `task_update_required`, or `blocked`.
- **Basis:** applicable rules and reference sources, why they apply to this repo
  and change, and any missing context that limits the verdict.
- **Task updates:** the exact constraints, validation requirements or open
  questions to add to `$WORK_DIR/task.md`.
- **Planner impact:** whether those updates change implementation order,
  validation or done criteria.

Findings inside the review use the same severity vocabulary as every other
reviewer: `CRITICAL`, `WARNING`, `SUGGESTION`.

## 4. Apply

The caller applies the file into `$WORK_DIR/task.md` with `ref-apply-feedback`
before delivery planning.

## Done

Compliance is unconfigured, not applicable, approved, or its plan-stage updates
and blockers are written to `$WORK_DIR/compliance-plan-review.md`.
