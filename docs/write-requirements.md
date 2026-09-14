# Writing a PRD with write-requirements

## When to use this skill

Use `/raholsn:write-requirements` after [grill-me-pragmatic](grill-me-pragmatic.md) has
clarified a plan. It turns the decision record and relevant context into a local
product requirements document for the next planning step, `/raholsn:plan-implementation`.
You can also supply a sufficiently clarified plan directly.

## Motivation

A useful PRD preserves the decisions from planning and makes the expected
behavior testable. This skill carries those decisions forward, exposes assumptions
and identifies missing decisions that would change implementation. It avoids
restarting discovery or calling an unresolved draft implementation-ready.

## Usage

```text
/raholsn:write-requirements docs/planning/2026-09-14-example-grill-decisions.md
/raholsn:write-requirements Turn our clarified plan into a PRD at docs/prds/example-prd.md
/raholsn:write-requirements Revise docs/prds/example-prd.md with the decisions above
```

The default result is a markdown file. No company profile or tracker is needed.
Publishing is optional and requires an explicit request followed by approval of
the concrete publishing proposal. There is no `--auto` publishing mode.

## Workflow

### High-level overview

These diagrams describe the instructions in the
[`write-requirements` skill](../claude-plugin/skills/write-requirements/write-requirements.md), not a recorded execution.

```mermaid
flowchart TD
    Start["Clarified plan or decision record"] --> Source["Resolve sources and preserve decisions"]
    Source --> Draft["Draft requirements and acceptance criteria<br/>Identify assumptions and material gaps"]
    Draft --> Ready{"Implementation decisions resolved?"}
    Ready -->|Yes| Prepared["Mark ready for issue planning"]
    Ready -->|No| Clarify["Ask focused question<br/>Continue independent drafting"]
    Clarify --> Resolved{"Blocker resolved?"}
    Resolved -->|Yes| Prepared
    Resolved -->|No| Blocked["Mark blocked and identify affected requirements"]
    Prepared --> Save["Save local PRD and report readiness"]
    Blocked --> Save
    Save --> Requested{"Publishing requested?"}
    Requested -->|No| Local["Return file and suggested next step"]
    Requested -->|Yes| Check["Validate target, fields and duplicate concerns"]
    Check --> Available{"Publishing prerequisites resolved?"}
    Available -->|No| Pending["Keep local file and report pending publication"]
    Available -->|Yes| Preview["Show concrete publishing proposal"]
    Preview --> Choice{"User decision?"}
    Choice -->|Publish| Publish["Write once and verify result"]
    Choice -->|Edit| Edit["Revise and repeat affected checks<br/>Present a fresh proposal"]
    Choice -->|Cancel| Cancel["Keep local PRD without publishing"]
```

### Detailed sequence

<details>
<summary>Expand drafting, readiness and optional publishing</summary>

```mermaid
sequenceDiagram
    actor User as Developer
    participant Skill as Write Requirements
    participant Context as Source files and conversation
    participant File as Local PRD
    participant Tracker as Configured tracker

    User->>Skill: Clarified plan or decision record, optional output path
    Skill->>Context: Read intended sources and targeted supporting context
    Context-->>Skill: Decisions, evidence, assumptions and gaps
    opt Material ambiguity or conflict
        Skill->>User: Ask a focused question
        User-->>Skill: Clarification or unresolved decision
    end
    Skill->>Skill: Draft requirements and linked acceptance criteria
    alt Material implementation decisions resolved
        Skill->>Skill: Mark ready for issue planning
    else Material implementation decisions unresolved
        Skill->>Skill: Mark blocked and identify affected requirements
    end
    Skill->>File: Save PRD using output policy
    File-->>Skill: Saved path or write limitation
    Skill-->>User: Report file or inline fallback, readiness and next step

    opt User requested publishing
        Skill->>Skill: Resolve company tracker configuration and tools
        Skill->>Tracker: Validate target and fields, read existing item or search duplicates
        Tracker-->>Skill: Available metadata, existing content or access limitation
        alt Prerequisites unresolved
            Skill-->>User: Preserve local PRD and report publishing pending
        else Prerequisites resolved
            Skill->>User: Show target, content, fields and planned writes
            User-->>Skill: Publish, Edit or Cancel
            loop Edit chosen
                Skill->>Skill: Revise proposal and repeat affected checks
                Skill->>User: Present revised proposal
                User-->>Skill: Publish, Edit or Cancel
            end
            alt Publish explicitly approved
                Skill->>Tracker: Execute approved operation once
                Tracker-->>Skill: Result or uncertain outcome
                opt Verification or reconciliation needed
                    Skill->>Tracker: Read-only lookup
                    Tracker-->>Skill: Confirmed state or remaining uncertainty
                end
                Skill-->>User: Confirmed result and any remaining work
            else Cancelled or no explicit approval
                Skill-->>User: Keep local PRD without tracker writes
            end
        end
    end
```

</details>

## Sources, assumptions and readiness

The supplied source and active planning conversation determine the PRD. The skill
reads files before using them, reports unavailable sources and asks when several
sources could be intended. Later explicit user corrections take precedence;
other material contradictions are surfaced rather than silently resolved.

Low-risk gaps can become visible assumptions. Decisions that could change scope,
behavior, contracts or acceptance criteria require clarification. Independent
sections can still be drafted while a decision remains open.

| Status | Meaning |
|---|---|
| **Ready for issue planning** | Requirements and acceptance criteria are concrete enough to break into issues, with explicit low-risk assumptions. |
| **Blocked** | An unresolved implementation decision affects named requirements. The saved document is a draft. |

Rollout-only prerequisites are recorded separately with their required release
conditions. Readiness does not mean the user has approved publishing,
implementation or release. The skill does not claim research, stakeholder
agreement or compliance conclusions that the sources do not establish.

## Document contents

The PRD contains its sources and readiness, problem, goals and non-goals, users,
requirements, acceptance criteria, implementation decisions, testing strategy,
relevant operational considerations, risks, assumptions and open questions.
Detail stays proportional to the work; irrelevant sections do not need invented
content.

Requirements have stable IDs such as `R1`. Acceptance criteria have IDs such as
`AC1` and reference the requirements they validate. Those references make coverage
traceable when `/raholsn:plan-implementation` creates the issue breakdown. Revisions preserve
existing IDs.

## File location and revisions

An explicit output path takes precedence. Otherwise the skill prefers an existing
PRD or planning directory, such as `docs/prds/`, `docs/planning/`,
`docs/requirements/`, `planning/` or `prd/`. If none exists, it creates
`docs/prds/` under the current working directory.

The default filename is `YYYY-MM-DD-<short-prd-slug>-prd.md`. New documents do not
silently overwrite existing files. An explicit revision updates the intended PRD,
preserving unrelated edits and stable IDs. The source decision record is preserved.
If writing is unavailable, the skill provides inline output and states that it
was not saved. Inline-only output can also be requested.

## Optional publishing and configuration

Publishing uses the [company profile](profile.md) only when requested. Its
`tracker` block identifies the configured connection and defaults; available tool
schemas and tracker metadata determine supported fields and operations. Missing
configuration leaves publishing pending and preserves the local result.

The skill resolves create versus update, checks the destination and fields,
and checks for plausible duplicates before creating. For updates, it reads the
existing item and shows the proposed changes while preserving unrelated content.
A source issue reference alone does not authorize changing that issue.

| Decision | Result |
|---|---|
| **Publish** | Execute the displayed operation, content, fields and planned follow-up writes. |
| **Edit** | Revise the proposal, repeat affected checks and request fresh approval. |
| **Cancel** | Keep the local PRD without tracker writes. |

An initial publishing request, silence or an ambiguous reply does not approve the
final proposal. A blocked PRD can be published only as a clearly identified draft
with explicit approval.

## Responsibilities

| Participant | Responsibility |
|---|---|
| Developer | Supply planning intent, resolve material decisions and approve optional publishing. |
| Skill | Preserve source decisions, write testable requirements, assess readiness, save the PRD and verify authorized publication. |
| Local context | Supply evidence for terminology, existing behavior and constraints. |
| Company profile and tracker | Supply publishing configuration, supported metadata and confirmed write results when publishing is requested. |

## Results and next steps

The skill returns the PRD path and a compact summary of readiness and remaining
decisions. A ready PRD can be passed to `/raholsn:plan-implementation <prd-path>` for planning
the implementation slices. A blocked draft identifies the decisions needed first.
Neither result automatically starts another command or implements the plan.

A successful publication also returns the confirmed tracker URL and fields.
Uncertain writes are reconciled through read-only lookup, without blind retries.
Partial success reports the existing item and incomplete work rather than creating
a replacement. Retries and repairs require fresh explicit approval.
