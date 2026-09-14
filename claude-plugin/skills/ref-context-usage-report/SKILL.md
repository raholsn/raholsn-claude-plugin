---
name: ref-context-usage-report
description: Report planning-phase implementation-agent context usage before implementation starts. Internal-only; writes context-usage.md beside task.md.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Context Usage Report

Internal sub-skill. The implementation agent writes `$WORK_DIR/context-usage.md`
before implementation starts. The default report measures planning-phase context
used by the implementation agent itself. Invoked after the workflow with
`phase: full-run`, it writes `$WORK_DIR/context-usage-full-run.md` instead.

**Requires** `$WORK_DIR` and `$WORK_DIR/task.md`. Reads `$WORK_DIR/delivery-plan.md`
when it exists.

## Process

1. Do not spawn a subagent. This report is about the current implementation
   agent's context, not delegated agents.
2. Copy visible status-line values for `context-used`, `total-input-tokens` and
   `total-output-tokens` only when present. If the runtime exposes exact metrics
   by another direct mechanism, use those and name the source.
3. Do not claim exact token counts, percentages, context window, remaining
   context or tool-call counts unless they are directly visible. Write `unknown`
   for anything that is not.
4. Exclude subagent internal context. List only the subagent artifact paths the
   implementation agent consumed.
5. Do not reread large raw outputs just to audit them. Use known filenames,
   summaries, shell history visible in the turn, and artifact headers unless
   exact content is needed.
6. Write the file beside `$WORK_DIR/task.md`.

## Report Template

```markdown
# Context Usage Report

## Scope
- Created:
- Reporter: implementation agent
- Step:
- Branch:
- Work dir:
- Phase measured:
- Measured agents: main/implementation agent only
- Excluded: preflight, explorer, planner, reviewer, comment-fixer and retrospective subagent internal context

## Runtime Metrics
- Source: visible status line | runtime-provided metrics | unavailable
- Model:
- Context used percentage:
- Total input tokens:
- Output tokens used:
- Total output tokens:
- Exact context window:
- Exact remaining context:
- Tool-call count:

## Main-Agent Context Loaded
- Skills loaded:
- Workflow artifacts read:
- Repo files read:
- Command outputs retained:
- Subagent artifacts consumed:

## Context Sources
- Task artifacts:
- Repo/context files:
- Skill/reference files:
- Command output:
- Subagent artifact summaries:

## Context Waste / Duplication
- Duplicate discovery:
- Re-read files:
- Repeated skill loads:
- Raw output that should have been artifacted:
- Files that should not be reread:

## Optimization Paths
- Can summarize or drop:
- Should avoid rereading:
- Should move to artifact:
- Suggested next-step loading strategy:

## Implementation Risk
- Context risks:
- Mitigations:

## Loading Plan
- Read next:
- Read only if needed:
- Do not read again:
- Save noisy output to:
```

## Done

The report exists beside `$WORK_DIR/task.md`.
