---
name: plan-implementation
description: Turn a PRD or clarified plan into a local implementation issue breakdown with requirement coverage, vertical slices and explicit dependencies. Publish only after approval.
disable-model-invocation: true
argument-hint: <PRD path, plan, issue reference, or URL>
---

# Plan Implementation

Plan implementation after `/raholsn:grill-me-pragmatic` and usually
`/raholsn:write-requirements`. Produce a reviewable markdown breakdown for later
`/raholsn:work` invocations, one ready issue at a time. This command does not
implement code or start the work workflow.

## Core Rules

- Preserve resolved scope, non-goals, decisions and constraints. Do not restart product discovery or silently resolve consequential open questions.
- Prefer thin vertical slices with observable value. An issue can be picked up independently **once its explicit prerequisites are satisfied**.
- Write the local breakdown before publishing. Local planning requires no tracker configuration.
- Creating tracker items, links or updates requires explicit approval of the concrete breakdown and publication proposal. Initial requests to publish authorize preparation, not unseen content. Silence and ambiguous replies are not approval.
- Do not modify the source PRD or parent issue without separate explicit authorization. A parent reference in the source is context, not permission to change it.
- Never invent tracker metadata or claim a tool supports operations without inspecting its available schema.
- Prefer stable behavior, contracts, data shapes and acceptance criteria over brittle file paths and large code snippets.

## 1. Resolve the source

1. Use the explicit PRD path, plan text, issue reference or URL. Read referenced content before relying on it, using read-only access where available. If unavailable, report the limitation and request the relevant source instead of inventing its contents.
2. With no explicit source, use an unambiguous current-conversation plan or grilling decision record. Otherwise inspect likely planning directories (`docs/prds/`, `docs/planning/`, `docs/requirements/`, `planning/`, `prd/`). Do not select a document solely because it is newest. Present candidates if the intended source is ambiguous.
3. Record source paths or URLs and the revision or retrieval date when available. Distinguish source facts, later explicit user corrections, assumptions and unresolved questions. Surface conflicting decisions rather than silently merging them.
4. Respect the PRD readiness marker (`Ready for issue planning` or `Blocked`). A blocked PRD can yield a provisional breakdown with explicit decision tasks, but must not be relabeled ready merely by splitting it into issues. Readiness for issue planning is not implementation approval.
5. Explore local context only as needed to establish terminology, existing contracts, constraints and dependencies. Do not treat implementation guesses as approved product requirements.

Ask focused questions only when a missing decision materially changes the breakdown.
Other gaps can remain explicit assumptions or blocked decision items in the draft.

## 2. Draft and check the breakdown

- Give every issue a stable local ID such as `I-01`. Keep IDs stable during revisions and publishing.
- Build narrow, complete paths through the relevant layers. Each implemented slice should be demoable, testable or operationally verifiable.
- The first implementation slice should deliver value or prove the riskiest integration. Horizontal enabling work is acceptable only with an explanation of why a useful vertical slice cannot include it.
- Classify implementation issues **AFK** when acceptance criteria and decisions are sufficient for work without additional human input. This classification does not authorize autonomous execution or remove the work workflow's checks.
- Classify **HITL** when human design, approval, compliance interpretation or an external decision is necessary. Name the unresolved decision, required decision maker or role if known, expected decision artifact and which implementation issues it blocks. Do not guess an owner or disguise unresolved behavior as implementation-ready.
- Separate readiness (`ready` or `blocked`) from AFK/HITL. An otherwise AFK issue can be blocked by a predecessor or external prerequisite. A decision task may be ready for human action while downstream implementation remains blocked.
- Specify local and external dependencies, their reasons and evidence of completion if already satisfied. Check for missing IDs, self-dependencies and cycles. Do not imply an issue is ready because its blocker ticket has merely been created.
- Map every in-scope source requirement and acceptance criterion to issues. Reuse source IDs, or assign local references in the breakdown without editing the source. Explain uncovered requirements or proposed deferrals explicitly. Unapproved omissions prevent treating the plan as complete.
- Preserve testing, compatibility, migration, rollout and operational requirements where the source requires them. Do not add generic tasks just to fill a checklist.
- Check for overlapping responsibilities, duplicate acceptance criteria and oversized slices. Keep cross-issue integration responsibility explicit.

## 3. Save and review

Use the user-specified output path, otherwise an existing issue-planning directory
such as `docs/issues/`, `docs/planning/`, `docs/prds/`, `planning/` or `prd/`.
If none exists, create `docs/issues/` in the working repository. Name the file
`YYYY-MM-DD-<short-plan-slug>-issues.md`. Preserve existing files with a numeric
suffix unless the user explicitly asked to revise that file. Subsequent edits to
the newly created draft update that same artifact and preserve publication records.

If file writing is unavailable, provide the draft inline and report that it was
not saved. Do not publish until a local breakdown can be saved.

Report the path, issue count, AFK/HITL split, ready/blocked split, requirement gaps
and major dependency chain. Ask for review or edits. Approval of the plan alone
does not authorize publishing. Local-only completion is a normal outcome.

## Breakdown Template

```markdown
# <Plan title> - Issue Breakdown

## Source and scope

- Source: <path or URL and revision/date when known>
- Parent context: <reference if any, does not authorize changes>
- Scope and non-goals: <preserved source boundaries>
- Assumptions and unresolved decisions: <explicitly identified>

## Summary

<Strategy, AFK/HITL and readiness counts, dependency chain, completeness status.>

## Coverage

| Source requirement or criterion | Issue IDs | Gap or proposed deferral |
|---|---|---|
| <reference and short description> | I-01 | None |

## Proposed Issues

### I-01: <Issue title>

- Type: AFK | HITL
- Readiness: ready | blocked
- Blocked by: <local IDs or external prerequisites and reasons, or None>
- Covers: <source references>

#### What to build or decide

<End-to-end behavior, or decision needed and expected decision artifact.>

#### Acceptance criteria

- [ ] <Observable result, including relevant verification>

#### Notes

- <Necessary testing, rollout, compatibility or risk detail>
- <For HITL: decision role if known, question and downstream impact>

## Publication record

<Initially not published. After approval, record target and approved fields,
local ID to tracker ID/URL, confirmed writes, failures, uncertain results and
remaining operations. Keep credentials and sensitive tool output out.>
```

## 4. Prepare optional publication

Only when publishing is requested, resolve the tracker through `profile` and its
`tracker` block. Resolve it earlier only if required to read a tracker source.
A missing tracker makes publication unavailable, not local planning a failure.
Company settings belong in the profile.

Before presenting the publication proposal:

1. Inspect configured tools and validate the target team, status, assignee and any requested project, milestone, labels or parent relationship. Explicit user fields override configured defaults. Omit missing optional fields. Do not infer that implementation issues should use the working status of `work`; show the actual intended planning status.
2. Check existing publication records and search for plausible duplicates in the intended target. Present matches or incomplete search limitations for a user decision. Do not silently reuse, modify or replace existing tickets.
3. Show the exact selected issues, bodies, target, fields and required relationship/update operations. A local PRD path is not a publicly accessible URL: preserve it as provenance, and make each body self-contained.
4. Inspect whether blocker relationships can be set on creation or require follow-up updates. If unsupported, propose explicit blocker references in bodies and disclose the lack of native dependency links. Never promise unsupported linking.
5. Present **Publish / Edit / Cancel** and wait for explicit approval. Publish approves only the displayed scope and operations. Edit repeats affected checks and requires renewed approval. Cancel keeps the markdown and stops without tracker writes. No `--auto` publishing mode is defined for this command.

Unresolved product decisions must remain visibly blocked. They do not prohibit
publishing an explicitly approved planning backlog, but do prevent presenting
that backlog as ready for implementation. Missing tracker prerequisites prevent
publication.

## 5. Publish and recover

1. Use the approved saved version and fields as the source of truth. Changes to scope, bodies, targets or write operations require fresh approval.
2. Create issues once in dependency order, recording each confirmed ID and URL immediately against its local ID in the markdown. Create blockers before dependents and substitute their actual references in dependent bodies without changing approved meaning.
3. Apply only approved relationship operations to the newly created issues. Do not edit existing parent/source items as an incidental publishing step. Keep AFK/HITL in bodies unless approved tracker labels exist.
4. Verify returned fields and relationships. Report unsupported or unverified state honestly. If saving the publication record fails, stop further writes and report confirmed results in chat.
5. On a failed or uncertain write, stop the batch. Use read-only lookups to reconcile what exists. Never blindly retry creation, create a replacement or delete successful issues to simulate rollback.
6. Record confirmed successes, missing updates, uncertain results and uncreated issues. Before resuming, reconcile uncertain creations, recheck relevant prerequisites and obtain explicit approval of the remaining operations. Do not recreate confirmed issues.

Final output includes the markdown path, completeness/readiness summary and,
if published, local-ID mappings to confirmed tracker IDs/URLs plus remaining
work. Hand off a selected ready implementation issue to `work` only when the user
requests implementation. Publishing does not start implementation or complete
its blockers.

## Issue Body Template

```markdown
## Source

<PRD reference and local issue ID, parent context if relevant.>

## What to build or decide

<Self-contained behavior or decision, with relevant contracts and scope.>

## Acceptance criteria

- [ ] <Observable criterion>

## Dependencies and readiness

- Readiness: ready | blocked
- Blocked by: <confirmed tracker references or external prerequisites and reason>

## Notes

- Type: AFK | HITL
- Covers: <source references>
- <Relevant verification, compatibility, rollout or risk notes>
- <For HITL: decision required, expected artifact and role if known>
```
