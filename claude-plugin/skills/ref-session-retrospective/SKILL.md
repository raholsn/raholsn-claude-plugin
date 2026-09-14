---
name: ref-session-retrospective
description: End-of-workflow retrospective. Internal-only; delegates to the retrospective subagent and surfaces suggestions for repo guidance, the profile, the pack, and the workflow.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Session Retrospective

Internal sub-skill. Runs at the end of a workflow session to capture learnings.

## Process

### 1. Delegate

Delegate to the **retrospective** subagent. It reviews the session and proposes
improvements to:

- The repo's guidance file.
- The **profile**, when a value was missing, stale or wrong. A workflow step that
  stalled on an unconfigured value is the single most useful thing this
  retrospective can catch.
- The **pack**, when house knowledge was missing or out of date.
- The engine's skills and agents.
- The workflow itself: step ordering, a missing sub-skill, a gate in the wrong
  place.

### 2. Route each suggestion

Suggestions land in different places, and putting one in the wrong layer is how
employer specifics leak back into the engine. Route by this rule:

| Suggestion is about | Goes to |
|---|---|
| This repo only | the repo guidance file |
| A value that differs per employer or machine | the profile |
| A house convention, domain fact or runbook | the pack |
| The method itself, true at any employer | the engine skill or agent |

If a suggestion would put a company name, repo name or stack command into an
engine file, it belongs in the profile or the pack instead. Say so rather than
applying it.

### 3. Present and apply

Present the suggestions to the user. **Only apply what the user approves.** Do not
auto-edit repo guidance, the profile, the pack or plugin files.

## Done

The retrospective ran, suggestions were surfaced and routed to the right layer,
and approved changes were applied.
