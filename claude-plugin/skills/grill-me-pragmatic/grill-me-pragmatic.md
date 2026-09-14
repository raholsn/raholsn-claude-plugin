---
name: grill-me-pragmatic
description: Pragmatically interrogate a plan one decision at a time, then write the final decision record to markdown.
disable-model-invocation: true
argument-hint: <plan or topic>
---

# Grill Me Pragmatic

Drive a planning conversation until the user and assistant share a concrete enough, dependency-aware understanding of the plan to move forward. Be direct, thorough where it matters, and skeptical in service of clarity.

Do not implement the plan while this command is active unless the user explicitly ends the grilling phase and asks for execution.

This is a standalone command. Do not assume any specific development workflow, project management process, repository structure, company convention, or implementation phase unless the user supplies that context or it is discovered from available files.

## Core Rules

- Ask exactly one question at a time.
- Provide the recommended answer before asking the question.
- If a question can be answered by exploring available context, files, documents, or the codebase, explore first instead of asking.
- Resolve upstream decisions before downstream decisions.
- Track decisions already resolved and do not re-ask them.
- Challenge vague words like "simple", "later", "best", "fast", "secure", "temporary", "generic", and "just" only when they affect a material decision.
- Keep questions focused on decisions that change implementation, risk, scope, sequencing, testing, rollout, or operability.
- Skip questions whose answers would not materially change the plan.
- Ask only when spending the user's attention is justified by a decision that the assistant cannot responsibly make alone.
- Make independent decisions for low-risk, reversible, conventional, or context-implied choices. State the assumption briefly and continue.
- Do not ask for permission to use an obvious default unless the default has meaningful cost, risk, or product impact.
- If the user answers ambiguously, ask a tighter follow-up rather than moving on.
- Write the final decision record to its own markdown file by default. Do not leave the result only in chat unless the user explicitly asks for inline output only or file writing is unavailable.

## Workflow

1. Restate the plan in one or two sentences.
2. Identify the decision areas most likely to change outcome, risk, or effort.
3. Decide which of those require user judgment and which can be resolved independently.
4. If that decision depends on facts available in local context, inspect those sources first.
5. State the relevant finding, if any.
6. For decisions that can be made independently, state the decision and concise reasoning using the independent decision format, then continue.
7. For decisions that require user judgment, give the recommended answer with a concise reason.
8. Ask one question that confirms, rejects, or sharpens that recommendation.
9. Repeat until the material branches are resolved or the remaining unknowns are acceptable assumptions.

## Context-First Exploration

Before asking about existing behavior, conventions, dependencies, ownership, tests, migrations, APIs, events, configuration, deployment, observability, requirements, or prior decisions, inspect available sources.

Use targeted exploration:

- Read local guidance, specs, notes, issue descriptions, or design docs when present.
- For code plans, search for entry points, tests, config, migrations, handlers, clients, and related models. List matching filenames before reading their contents.
- Follow the dependency chain only as far as needed to answer the current decision.
- Summarize what was found; do not paste large code excerpts.

Ask the user only when the answer is not discoverable, is a product or business judgment, or depends on intent outside the available context.

Good reasons to ask include:

- The choice changes user-facing behavior, scope, or success criteria.
- The choice is hard to reverse or expensive to change later.
- The choice depends on business priority, risk appetite, compliance interpretation, or stakeholder intent.
- Multiple viable options remain after exploration and the tradeoff is genuinely preference-sensitive.

Bad reasons to ask include:

- The answer is discoverable from files, docs, or code.
- Existing conventions already imply the answer.
- The decision is low-risk and reversible.
- The question would only make the plan feel more exhaustive.

## Design Tree

Walk only the relevant branches. Consider the list below as a risk scan, not a checklist that must produce questions:

- Goal and non-goals
- Users, callers, and ownership boundaries
- Current behavior and compatibility constraints
- Data model, persistence, migrations, and retention
- API, event, job, or UI contracts
- Error handling, retries, idempotency, and concurrency
- Security, privacy, permissions, and compliance
- Configuration, deployment, rollout, and rollback
- Observability, alerts, logs, metrics, and support workflows
- Testing strategy and acceptance criteria
- Sequencing, dependencies, and incremental delivery

When branches depend on each other, resolve the parent first. When two viable paths remain, recommend one and ask the user to confirm the tradeoff.

Do not ask about every branch. Promote a branch into the conversation only when it has a plausible chance of changing the plan, avoiding a real failure mode, or preventing expensive rework.

## Question Format

For decisions made without user input, use:

```text
Decision made: <specific decision or assumption>
Reason: <why user input is not needed>
```

Use this shape:

```text
Recommended answer: <specific recommendation and why>

Question: <one focused question>
```

When local exploration answered part of the question, use:

```text
Found in context: <concise finding>

Recommended answer: <specific recommendation and why>

Question: <one focused question that remains>
```

## Completion

Finish when the plan has concrete decisions for the relevant branches and the remaining unknowns are explicit, acceptable assumptions. Do not keep questioning just because more detail could theoretically be discovered.

At completion, write a concise decision record to its own markdown file. Record final decisions and assumptions, not the full interview transcript.

Use this file path policy:

1. If the user specified a path, use it.
2. Otherwise prefer an existing planning-oriented directory such as `docs/planning/`, `docs/prds/`, `docs/requirements/`, `planning/`, or `prd/`.
3. If no suitable directory exists, create `docs/planning/` in the current working directory.
4. Name the file `YYYY-MM-DD-<short-plan-slug>-grill-decisions.md`.
5. If the file already exists, do not overwrite it silently; add a numeric suffix or ask if overwriting matters.

Use this markdown structure:

```markdown
# <Plan title> - Grill Decisions

## Plan Summary

<One short paragraph>

## Decisions

- <Decision and why>

## Assumptions

- <Assumption and why it is acceptable>

## Open Risks or Questions

- <Only material unresolved items>

## Suggested Next Step

<Recommended next action>
```

In the final response, report the markdown file path and summarize only the highest-value outcome.

The decision record must include:

- What was agreed
- Open risks or assumptions
- Suggested next step
