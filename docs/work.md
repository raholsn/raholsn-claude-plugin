# Implementing a task with work

## When to use this skill

Use `/raholsn:work` to implement one actionable ticket or task through review,
validation, commits and a PR. It can follow the planning sequence
`grill-me-pragmatic` → `write-requirements` → `plan-implementation`: select one task from the resulting
plan and supply its relevant context. A whole backlog requires a task selection
before implementation begins.

## Motivation

Implementation needs a clear scope, useful review and evidence that the change
works. This skill carries a selected task from the planning record into an
implementation checkout, reviews and validates coherent commits, then verifies
the complete change and delivered PR. A durable session keeps the source,
decisions and delivery evidence together so interrupted work can resume. Company and
repository configuration supplies the tools, commands and conventions.

## Usage

```text
/raholsn:work TEAM-123
/raholsn:work Implement the selected retry task from the planning artifact
/raholsn:work Fix the timeout handling, keep this local and do not push
```

An existing ticket is read for its requirements even when you add instructions.
A description can run ticketless with a configured tracker; this command does
not automatically create tickets. Use [create-linear-ticket](create-linear-ticket.md)
when you want one created.

The normal invocation includes implementation commits, pushing the task branch
and creating or updating its PR. Narrower instructions such as local-only remain
in effect. Merging, deployment, publishing review comments and sending colleague
messages require separate authorization. The skill can prepare a colleague note
for you to copy.

## Workflow

### High-level overview

These diagrams describe the instructions in the
[`work` skill](../claude-plugin/skills/work/work.md), not a recorded execution.

Each large container is a numbered workflow step. Inside it, smaller boxes show
the checks in order. Blue boxes are agent work; their owners are listed below. Arrows between containers show
the next step or a loop. The flow is split into three consecutive panels so the
text stays readable.

#### Steps 0–4: Prepare and plan

```mermaid
%%{init: {"themeVariables": {"fontSize": "18px"}, "flowchart": {"nodeSpacing": 30, "rankSpacing": 45, "padding": 22}}}%%
flowchart TB
    subgraph S0["0 · Choose the repository and check readiness"]
        direction TB
        Profile["Load repository settings"] --> Session["Create or resume task folder"]
        Session --> Source["Read task requirements"]
        Source --> CLI["Check tools and sign-in"]
        Source --> Services["Check local service connectivity"]
        Source --> MCP["Check issue-tracker access"]
        Source --> Git["Inspect branches and existing changes"]
        CLI --> Evidence["Save readiness report"]
        Services --> Evidence
        MCP --> Evidence
        Git --> Evidence
    end
    subgraph S1["1 · Prepare implementation checkout"]
        direction LR
        Branch["Select task branch"] --> Checkout["Prepare isolated working copy"] --> Identity["Record branch and repository"]
    end
    subgraph S2["2 · Understand selected task"]
        direction LR
        Task["Inspect task and relevant code"] --> Explore["Trace cross-repository dependencies"] --> Brief["Write implementation brief"]
    end
    subgraph S3["3 · Review task design"]
        direction TB
        Architect["Review architecture"] --> Feedback["Resolve review findings"]
        Domain["Review applicable domain requirements"] --> Feedback
    end
    subgraph S4["4 · Plan delivery"]
        direction LR
        Plan["Choose implementation steps"] --> Steps["Order steps and define checks"] --> PlanFiles["Save delivery plan"]
    end
    Evidence --> Ready{"Ready to start?"}
    Ready -->|Ready to start| Branch
    Ready -->|Missing prerequisites| Blocked["Resolve missing prerequisites"]
    Identity --> Task
    Brief --> Architect
    Brief --> Domain
    Feedback --> Design{"Design ready?"}
    Design -->|Ready| Plan
    Design -->|Open decisions| Clarify["Resolve open design decisions"]
    PlanFiles --> Next["Continue to step 5"]
    classDef agent fill:#dbeafe,stroke:#2563eb,color:#172554
    class Source,CLI,Services,MCP,Git,Evidence,Explore,Architect,Domain,Plan,Steps,PlanFiles agent
```

The preflight agent checks whether work can start; it does not implement code or
create tickets. It checks developer tools, local services, tracker access and Git
state independently, so those checks can run in parallel. A responding service
port establishes connectivity, not full application health. Reference mappings
and agent responsibilities are listed below the flow diagrams.

Missing optional configuration is
recorded as skipped; a missing prerequisite blocks dependent work. Architecture
and applicable domain reviews also run in parallel.

#### Steps 5–9: Implement, validate and review

```mermaid
%%{init: {"themeVariables": {"fontSize": "18px"}, "flowchart": {"nodeSpacing": 35, "rankSpacing": 45, "padding": 22}}}%%
flowchart TB
    subgraph S5["5 · Load implementation context"]
        direction LR
        Load["Read task and delivery plan"] --> Select["Load next step and code"] --> Rules["Load company guidance"]
    end
    subgraph S6["6 · Record context usage"]
        direction LR
        Context["Check available context usage"] --> Usage["Save context loading plan"]
    end
    subgraph S7["7 · Implement selected step"]
        direction LR
        Dependencies["Verify completed dependencies"] --> Progress["Mark step in progress"] --> Implement["Implement selected step"]
    end
    subgraph S8["8 · Validate and review"]
        direction TB
        Setup["Prepare test environment"] --> Tests["Build and run tests"] --> Cleanup["Restore environment and save results"]
        Cleanup --> Pass{"Checks passed?"}
        Pass -->|No, fixable| TestFix["Fix validation failure"]
        TestFix --> Setup
        Pass -->|Yes| Review["Review behavior and regressions"]
        Review --> Findings{"Supported fixes needed?"}
        Findings -->|Yes| Fix["Apply supported review fixes"]
        Fix --> Setup
        Findings -->|No| Validated["Confirm step is ready"]
    end
    subgraph S9["9 · Commit and record evidence"]
        direction LR
        Stage["Check staged changes"] --> Commit["Commit selected step"] --> Record["Record completion and commit"]
    end
    Rules --> Context
    Usage --> Dependencies
    Implement --> Setup
    Validated --> Stage
    Record --> More{"More planned steps?"}
    More -->|Yes| Dependencies
    More -->|No| Next["Continue to step 10"]
    classDef agent fill:#dbeafe,stroke:#2563eb,color:#172554
    class Review agent
```

The inner loop fixes and revalidates the current change. The outer loop selects
the next planned implementation step. Unresolvable failures pause dependent work.
An explicit no-commit scope ends with validated local changes and pending commit
steps, rather than marking uncommitted work as implemented.

#### Steps 10–14: Verify and deliver

```mermaid
%%{init: {"themeVariables": {"fontSize": "18px"}, "flowchart": {"nodeSpacing": 35, "rankSpacing": 45, "padding": 22}}}%%
flowchart TB
    subgraph S10["10 · Verify whole task and prepare PR description"]
        direction LR
        Acceptance["Verify all acceptance criteria"] --> Whole["Review the complete change"] --> Body["Prepare PR description"]
    end
    subgraph S11["11 · Push and create or update PR"]
        direction LR
        Remote["Check remote branch changes"] --> Push["Push validated commits"] --> PR["Create or update PR"]
    end
    subgraph S12["12 · Verify delivered change"]
        direction TB
        Fetch["Fetch PR changes and CI results"] --> Compare["Compare delivered and reviewed changes"] --> Needed{"New review needed?"}
        Needed -->|Yes| DeliveredReview["Review delivered changes"]
        Needed -->|No| Reuse["Reuse matching review results"]
        DeliveredReview --> Threads["Handle authorized review comments"]
        Reuse --> Threads
        Threads --> Head["Record delivery and CI status"]
    end
    subgraph S13["13 · Handle post-merge hooks"]
        direction LR
        Hooks["Load post-merge actions"] --> Merged["Check merge status and authorization"] --> HookResult["Run eligible actions"]
    end
    subgraph S14["14 · Retrospective and handoff"]
        direction LR
        Retro["Review session lessons"] --> Suggestions["Propose improvements"] --> Handoff["Report results and pending work"]
    end
    Body --> Complete{"Whole-task criteria satisfied?"}
    Complete -->|No| Replan["Revise steps and return to implementation"]
    Complete -->|Yes| Publish{"Publication in scope?"}
    Publish -->|Yes| Remote
    Publish -->|No, local only| Hooks
    PR --> Fetch
    Head --> Fixes{"Supported delivery fixes?"}
    Fixes -->|Yes| Repair["Fix, validate and commit"]
    Repair --> Remote
    Fixes -->|No| Hooks
    HookResult --> Retro
    classDef agent fill:#dbeafe,stroke:#2563eb,color:#172554
    class Whole,DeliveredReview,Threads,Retro agent
```

A whole-task gap returns to implementation. Delivery fixes repeat push and
verification after local validation and review. Identical reviewed changes reuse
their evidence. Published review findings require explicit authorization; the
workflow does not merge the PR or wait indefinitely for a merge.

### Supporting skills and agents

<details>
<summary>Show which agent and reference each step uses</summary>

| Step | Owner | Supporting skills |
|---|---|---|
| 0 · Settings and task folder | Main agent | `profile`, `ref-work-session` |
| 0 · Task and readiness checks | Preflight agent | `ref-ticket`, `ref-cli-check`, `ref-service-check`, `ref-mcp-check`, `ref-git-preflight` |
| 1 · Working copy | Main agent | Naming guidance from `ref-create-branch-and-pr` only |
| 2 · Task understanding | Main agent, optional cross-repo explorers | `ref-understand-task` |
| 3 · Design review | Architect and applicable domain agents, main agent reconciles | `ref-architect-review`, `ref-compliance-review`, `ref-apply-feedback` |
| 4 · Delivery plan | Planner agent | `ref-delivery-planning` |
| 5 · Implementation context | Main agent | Applicable company guidance |
| 6 · Context usage | Main agent | `ref-context-usage-report` |
| 7 · Implementation | Main agent | Selected implementation step |
| 8 · Validation and review | Main agent and functional reviewer | `ref-build-and-test`, `ref-review-loop` |
| 9 · Commit | Main agent | Repository commit conventions |
| 10 · Whole-task verification | Main agent and relevant reviewers | `ref-review-loop`, applicable architecture/domain references, `ref-update-pr-description` for an existing PR |
| 11 · PR delivery | Main agent | Configured host CLI |
| 12 · Delivered-change review | Main agent, functional reviewer, comment-fixer when authorized | `ref-review-loop`, optional `ref-post-push-review` |
| 13 · Post-merge actions | Main agent | Configured `post_merge_hooks` |
| 14 · Retrospective | Retrospective agent, main agent hands off | `ref-session-retrospective` |

</details>

### Detailed sequence

<details>
<summary>Expand implementation, delivery and handoff</summary>

```mermaid
sequenceDiagram
    actor User as Developer
    participant Main as Work coordinator
    participant Profile as Company profile
    participant Agents as Supporting agents
    participant Repo as Local repository
    participant Host as Configured PR host

    User->>Main: One ticket or task, context and delivery scope
    Main->>Profile: Resolve configuration
    Profile-->>Main: Paths, tools and optional company references
    Main->>Main: Create unique external session or verify explicit resume
    Main->>Agents: Read source and inspect prerequisites in target repo
    Agents-->>Main: Source snapshot, preflight artifact and blockers
    alt Scope or prerequisite unresolved
        Main-->>User: Explain blocker and required decision
    else Ready
        Main->>Repo: Prepare or verify task branch and implementation checkout
        Main->>Main: Record checkout, base, source remote and branch
        Main->>Main: Understand task and preserve planning constraints
        opt Bounded cross-repo question
            Main->>Agents: Read-only discovery
            Agents-->>Main: Relevant evidence artifact
        end
        par Architecture review
            Main->>Agents: Review task brief
        and Applicable configured compliance
            opt Matching domain reviewers
                Main->>Agents: Review applicable requirements
            end
        end
        Agents-->>Main: Architecture and all applicable domain artifact paths
        Main->>Main: Reconcile feedback into task
        Main->>Agents: Plan coherent implementation commits
        Agents-->>Main: Delivery plan and ordered step files
        loop Each remaining step in current delivery plan
            Main->>Repo: Implement selected step
            Main->>Repo: Run applicable checks and cleanup
            Main->>Agents: Review saved step diff in explicit checkout
            Agents-->>Main: Findings artifact
            Main->>Main: Apply supported fixes and revalidate
            opt Required validation unavailable
                Main->>User: Present exact delivery limitation
                User-->>Main: Accept limitation or resolve blocker
            end
            Main->>Repo: Commit only after gate is satisfied
            Main->>Main: Record implemented status, commit and evidence
        end
        Main->>Main: Map every selected acceptance criterion to evidence
        Main->>Agents: Review cumulative change if not already covered
        Agents-->>Main: Whole-task findings
        Main->>Main: Resolve findings and required integration checks
        alt Whole-task gate satisfied and publication authorized
            Main->>Host: Push and create or update PR
            Host-->>Main: Confirmed PR URL and head
            Main->>Host: Fetch actual PR diff, base/head and CI state
            Host-->>Main: Delivered change and observed checks
            alt Exact cumulative change already reviewed
                Main->>Main: Reuse review evidence and verify delivered head
            else Change differs or lacks cumulative review
                Main->>Agents: Review saved PR diff, never empty local diff
                Agents-->>Main: Findings
            end
            opt Supported corrections needed
                Main->>Repo: Fix, validate and commit
                Main->>Host: Push fixes and refresh PR description
            end
            opt Review comment publication explicitly authorized
                Main->>Host: Publish and manage scoped review findings
            end
        else Local-only scope or unresolved whole-task gate
            Main->>Main: Retain prepared output and report pending work
        end
        Main->>Main: Record applicable hooks pending confirmed merge
        Main->>Agents: Retrospective
        Agents-->>Main: Retrospective artifact
        Main-->>User: Scope, validation, branch, PR and pending work
    end
```

</details>

## Decisions and boundaries

Consequential scope conflicts, unmet dependencies and missing required access
must be resolved before dependent work. The skill does not implement every issue
in a supplied plan or infer that a planning artifact authorizes external writes.

A failed check blocks delivery. A missing required check is reported as
unavailable and needs explicit acceptance of the delivery limitation before a
commit or push. Checks that do not apply need a reason. Skips are not passes.
Supported critical review findings must be fixed; unsupported claims require
evidence for rejection. Warnings can be left only with a specific, recorded rationale. Cleanup is attempted on failed validation as well as success.

Existing work is preserved. Branch reuse requires matching the selected task;
resuming reconciles step artifacts against actual commits and changed requirements.
Preflight inspects the checkout without stashing, switching or discarding work.
The coordinator creates an isolated checkout when needed and passes that path to
all subsequent steps. The workflow does
not create an empty commit merely to open a PR before implementation.

Per-step checks are followed by a whole-task gate: all selected acceptance
criteria need implementation and validation evidence, and cross-step behavior
needs appropriate coverage. Before claiming delivery, the actual PR base/head
and saved cumulative diff must match the reviewed change. An identical reviewed
change does not need a duplicate review just because it was pushed.

## Configuration

Configure company context through the [profile](profile.md).

| Setting | Purpose |
|---|---|
| `roots.repos`, `roots.artifacts` | Repository location and session artifacts outside checkouts |
| `guidance_file` | Repository instructions, setup and validation requirements |
| `vcs` | Base branch, naming, host CLI, commit title and draft preference |
| `tracker` | Optional access to the selected existing ticket |
| `toolchain`, `local_services` | Applicable prerequisite checks |
| `build` | Independently configured build and test commands, setup and cleanup |
| `pack`, `knowledge` | Optional conventions and domain references loaded as needed |
| `compliance` | Optional plan-stage compliance review |
| `post_merge_hooks` | Optional follow-ups after confirmed merge and authorization |
| `browser_open_cmd` | Optional opening of the confirmed PR URL |

Missing optional configuration skips the corresponding optional step. Missing
configuration needed for this task is resolved before relying on it. An absent
build command does not suppress configured tests. Commands are not guessed from
file names. A successful local check does not establish that host CI passed.

## Responsibilities

| Participant | Responsibility |
|---|---|
| Developer | Select the task, clarify product decisions and set delivery scope |
| Work coordinator | Reconcile evidence, implement, validate, commit and deliver within scope |
| Preflight and discovery agents | Check prerequisites and answer bounded evidence questions |
| Review agents | Assess architecture, configured compliance and functional correctness |
| Planner | Write the commit sequence and step-level validation requirements |
| Retrospective agent | Record lessons from the actual session |
| Company profile and repo guidance | Supply applicable tools, paths, commands and conventions |

References that delegate own their agents; the coordinator does not wrap them
in duplicate agent layers. Agent artifacts preserve decisions without carrying
all discovery output into implementation context.

## Results and recovery

A unique session directory outside checkouts is created before preflight. It
holds `session.md`, `.repo`, `.task`, `source-context.md`, `preflight.md`, `task.md`,
`delivery-plan.md`, `implementation-steps/*.md` and `context-usage.md`. Review inputs
and feedback are kept by step/attempt under `reviews/`, with delivered-head
evidence under `reviews/delivery/<head>/`. Validation logs are preserved per step. A step becomes
`implemented` only after its commit succeeds, with the commit SHA and validation
evidence recorded. The current plan explicitly identifies its active step files;
archived files do not re-enter the implementation loop. An explicit no-commit
request produces validated local changes and a report of pending commits. It does
not mark uncommitted steps as implemented.

To resume, supply the recorded session path and selected task. The skill verifies
its repository, checkout, branch and commits, preserves completed evidence, and
resumes the first incomplete phase. It does not recreate the plan or overwrite
another task just because the branch names match.

The handoff reports completed scope, validation and limitations, the checkout,
session path, branch and
PR URL when present, unresolved findings and pending actions. An uncertain push
or PR creation is checked against remote state before retrying. A failed PR
creation does not discard the pushed branch.

This workflow ends at a PR handoff without waiting indefinitely for a merge.
Configured hooks remain pending until the intended PR is confirmed merged and
the follow-up action is authorized. Completed hooks are recorded so a resumed
session does not repeat them. A blocked run reports the current step, attempts,
blocker and decision needed to resume.
