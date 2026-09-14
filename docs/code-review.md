# Running a code review

## When to use this skill

Use this skill when a PR is ready for review and you want to check that it meets
the requirements, works through the affected user journeys, and handles relevant
failure scenarios.

## Motivation

A PR needs to be assessed from several perspectives: whether it delivers the
requested behavior, preserves user journeys, handles system failures, and has
meaningful test coverage. Some changes also require checking specific compliance
rules. Covering those perspectives is a substantial part of a developer's review.

The motivation for this skill is to bring those reviews together and shorten the
path to a useful assessment. It connects the PR to its requirements, runs the
relevant specialist reviews in parallel, and consolidates their findings into
prioritized concerns, supporting evidence and an overall conclusion. The developer
can use that assessment alongside their own independent review, verifying the
findings and deciding what needs attention before merge.

## Usage

Start with `/raholsn:code-review <PR URL or owner/repo#number>`.
Optionally append `post_comments=all`, `post_comments=critical_warnings`, or
`post_comments=none` to choose the posting behavior up front.

## Workflow

### High-level overview

The diagram shows the main stages of the
[`code-review` workflow](../claude-plugin/skills/code-review/code-review.md).
Selected reviewers work in parallel, each looking at a different kind of risk.

```mermaid
flowchart TD
    Start["Start with a PR"] --> Context["Gather context<br/>PR changes, requirements and repo guidance"]
    Context --> Select["Select applicable reviewers"]

    subgraph Reviews["Review in parallel"]
        Functional["Functional · always<br/>User journeys and correctness"]
        Architect["Architecture · when relevant<br/>System design and failure modes"]
        QA["QA · when relevant<br/>Tests and validation evidence"]
        Compliance["Compliance reviewer<br/>Relevant changes trigger review<br/>Uses additional rules and context"]
    end

    Select --> Functional & Architect & QA & Compliance
    Functional & Architect & QA & Compliance --> Findings["Combine findings<br/>Verify, deduplicate and classify"]
    Findings --> Present["Present findings and limitations"]
    Present --> Post["Optionally post PR comments<br/>Use your preference or ask first"]
```

### Detailed sequence

<details>
<summary>Detailed sequence: setup, review coordination and posting</summary>

This diagram expands the overview above into the individual interactions.
It describes the workflow, not a recorded execution.

```mermaid
sequenceDiagram
    actor User
    participant Review as Code-review command
    participant Profile as Profile and customer guidance
    participant PR as PR host via configured CLI
    participant Tracker as Configured tracker MCP
    participant Agents as Review agents
    participant Files as Local review files

    User->>Review: Run code-review with a PR and optional posting preference
    Review->>Profile: Load profile
    opt Profile needs setup
        Profile->>User: Ask for missing configuration
        User->>Profile: Supply configuration
    end
    Profile-->>Review: Host, CLI, paths, build settings and compliance domains
    Review->>Review: Validate PR argument and check required CLI tools
    Note over User,Review: Invalid input or unavailable prerequisites require resolution before continuing
    Review->>PR: Read PR state and metadata
    PR-->>Review: Title, branches, change counts and state
    opt PR is closed or merged
        Review->>User: Continue reviewing this PR?
        User->>Review: Continue or stop
        Note over User,Review: Remaining steps run only if the user continues
    end
    Review-->>User: Show PR title and change summary

    Review->>Profile: Locate local repository using configured paths
    opt Repository is not available locally
        Review-->>User: Report limited source access
    end
    Review->>Files: Create a fresh invocation directory
    Review->>PR: Read head and base commits
    Review->>PR: Fetch diff, changed paths, commits, body and comments in parallel
    PR-->>Review: PR context
    Review->>Review: Verify the diff comparison belongs to the recorded revision
    Review->>Files: Save context and prepare source snapshot or record limited access
    Review->>Review: Read repo guidance at reviewed revision when available
    Review->>Review: Find ticket links in PR body and comments, then title or branch fallback
    opt Linked ticket found and tracker configured
        Review->>Tracker: Read linked issue description and acceptance criteria
        Tracker-->>Review: Ticket requirements or an access limitation
        Review->>Files: Save ticket requirements and source links for all reviewers
    end
    Review->>Files: Write fresh requirements brief and record unknowns
    Review->>Profile: Match repo guidance and affected domain to configured compliance reviewers
    Review-->>User: Explain selected reviews and skipped specialists

    Note over Review,Agents: Separate reviewers examine different risks<br/>Functional checks behavior, architect checks system design and failure modes, QA checks validation evidence
    par Architecture review
        opt Changes with architectural or operational impact, or explicitly requested
            Review->>Agents: Architect checks design, resilience, performance and operability
            Agents->>Files: Write architecture findings
        end
    and Functional review - always
        Review->>Agents: Functional reviewer checks user journeys, requirements and implementation correctness
        Agents->>Files: Write functional findings and open product questions
    and QA review
        opt Behavior, test or validation-sensitive configuration changes, or explicitly requested
            Review->>Agents: QA checks coverage, assertions and validation evidence
            Agents->>Files: Write QA findings independently
        end
    and Optional compliance review
        opt Repo context and changed scope match a configured domain
            Review->>Profile: Resolve the domain rules and reference documents
            Profile-->>Review: Relevant company or regulatory context
            Review->>Agents: Compliance reviewer receives the change, matched trigger and reference documents
            Agents->>Agents: Read additional context and assess the change against applicable rules
            Agents->>Files: Write compliance findings
        end
    end

    Files-->>Review: Findings produced by this review invocation
    Review->>Review: Verify conflicting claims, deduplicate and reconcile severity
    Review-->>User: Show critical issues, warnings, suggestions and areas that look good
    alt Posting preference was supplied with the command
        Review->>Review: Apply that preference
    else No posting preference supplied
        Review->>User: Post all, critical/warnings, individually selected findings, or none?
        User->>Review: Choose what to post
    end
    opt Findings selected for posting
        Review->>PR: Check reviewed head and base are still current
        opt Comparison changed
            Review->>Review: Refresh affected review and revalidate findings
        end
        Review->>PR: Post inline or general comments with the configured review signature
        PR-->>Review: Posting result
        Review-->>User: Confirm how many comments were posted
    end
    Review-->>User: Totals, review scope, evidence limits, posting outcome and assessment
```

</details>

## Context and requirements

Setup loads the profile and checks PR access. Missing configuration or unclear
requirements may need your input; a closed or merged PR requires confirmation
to continue. Linked ticket requirements are fetched once and shared with all
reviewers. Missing context is recorded as a limitation.

Reviewers read surrounding source and tests at the recorded PR revision, using
an isolated snapshot or revision-specific host content. Missing source is
reported as a limitation. The user's working checkout is preserved.

## Review responsibilities

| Agent | Main question | Scope |
|---|---|---|
| Functional reviewer | Can the user complete the intended journey, and does the implementation deliver the agreed behavior correctly? | Journey entry and prerequisites, connected steps, progress and outcome feedback, interruption and recovery, acceptance criteria, business rules, calculations, state transitions, permissions, and regressions. Uses available client/API evidence and flags missing product decisions without inventing requirements. |
| Architect | Will the affected system remain correct, resilient, efficient, and operable as load and failure conditions change? | Boundaries, contracts, data consistency, idempotency, retryability, timeout budgets, concurrency, performance, scalability, resource limits, backpressure, caching, security isolation, observability, recovery, rollout/rollback, and maintainability. |
| QA | What evidence demonstrates that the change works and continues to work? | Requirement-to-test coverage, meaningful assertions, test isolation and reliability, boundary/failure scenarios, integration and regression coverage, and appropriate concurrency/load/recovery validation. Distinguishes passing results from tests that were never run. |
| Compliance reviewer | Does the change satisfy the rules that apply to this area? | Runs when configured triggers match the change or repository requirements. Reads supplied domain rules, company documents, and relevant requirements before assessing the implementation. Reports missing context as unreviewed. |

### How the reviewers complement each other

For example, the architect checks whether retrying after a timeout can duplicate
a side effect and whether retries fit the caller's time budget. The functional
reviewer checks that the resulting state and response meet the agreed behavior.
QA checks whether validation actually exercises the timeout, retry, and duplicate
delivery scenarios and asserts the outcomes.

Architectural review follows relevant risks through the affected system rather
than stopping at class or service structure. Findings need a concrete scenario,
evidence, and impact; speculative scale assumptions are recorded as questions.
These scopes establish primary responsibility, not restrictions on reporting a
real defect found by another reviewer.

### Selecting reviewers

Functional review runs for every PR. Explicitly requested specialists also run.
Small documentation or cosmetic changes normally skip architecture and QA.

## Compliance review

### When it runs

Compliance review is enabled selectively through the profile. Each registered
reviewer has a trigger identifying the area it covers. The command compares
those triggers with the changed code, affected behavior, task requirements, and
repository guidance. A matching change brings that reviewer into the parallel
review; a repo-wide requirement can also trigger it. Several matches can run
several compliance reviewers.

For example, a configured payment-processing reviewer could be selected for a
change to payment handling. It would receive the PR diff and shared requirements,
the reason its trigger matched, and the relevant payment rules or company
documents. This example does not impose payment rules on other repositories.

### Additional context

The profile's customer pack supplies additional reference documents through
`knowledge.domains`; repository guidance and the task brief can name further
references. The reviewer reads that context alongside any domain references
configured in its own agent definition before judging the change. It cites the
rules it used and explains why they apply.

An ambiguous match may need clarification. Missing reviewers, unreadable
references, or uncertain applicable rules are reported as unreviewed areas.
Having no configured compliance reviewer does not establish that no obligations
apply.

## Findings and validation

The command creates `task.md` before dispatching, records missing requirements,
and consolidates only feedback from the current invocation. Single-pass review
does not require a build. Missing evidence limits the final assessment.

Reviewers report independently; the command deduplicates their findings and
reconciles severity using the impact-based definitions in each agent. Missing
tests alone are not critical defects.
QA assesses configuration, retries, recovery, and data-integrity validation by
their concrete risk, including when broader validation runs only after merge.

## Posting comments

The command uses your `post_comments` preference or asks which findings to post.
Before posting, it checks that the reviewed PR revision is still current and
revalidates affected findings if it changed.

## Results and saved files

The review writes its working files to
`<roots.artifacts>/review-<repo>-<pr-number>/run-<unique-id>`. It presents findings
without applying code fixes or merging the PR. The final report includes the
review assessment, evidence limitations and posting outcome. Build verification
is optional; a review result does not establish that tests passed.
