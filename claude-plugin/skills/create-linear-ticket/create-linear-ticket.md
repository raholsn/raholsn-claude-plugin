---
name: create-linear-ticket
description: Prepare and create one Linear ticket after draft approval, or without manual intervention when the user explicitly supplies --auto. Resolves company defaults and presets, checks duplicates, and validates the requested fields before creation.
disable-model-invocation: true
argument-hint: <title or context> [--preset-name] [--auto]
---

# Create Linear Ticket

Request: $ARGUMENTS

Create one ticket in Linear using company context from the profile. No team,
project, assignee or working status is hardcoded.
Profile defaults and presets capture the developer's usual assignee, projects
and milestones, so they do not need to repeat those choices for every ticket.
Explicit instructions override that configuration for the current ticket.

By default, **do not write to Linear until the user explicitly approves the
displayed draft and resolved fields.** Read-only configuration, metadata and
duplicate checks may proceed during preparation.

### Opt-in unattended mode: `--auto`

Recognize `--auto` only as an explicit standalone flag in this invocation's
arguments. Do not infer it from quoted ticket content, examples, profile defaults
or earlier invocations. Reserve it as a control flag, not a preset alias, and
exclude it from the ticket content.

`--auto` authorizes creation of one ticket and any necessary validated follow-up
update without draft approval. Run all configuration, field validation and
duplicate checks normally. Present the prepared draft and resolved fields for
visibility, then execute without waiting when every prerequisite is satisfied.

Do not ask questions or wait for manual intervention in this mode. Wherever the
workflow would require clarification or acknowledgement, stop instead and return
the draft with the unresolved choice or blocker. This includes ambiguous fields,
plain-prose preset suggestions needing confirmation, conflicting presets,
plausible duplicates, incomplete duplicate searches and unavailable access.
Optional unknowns may remain visible in the description when they do not prevent
a meaningful ticket. Never guess required values to keep running.

On failed or uncertain writes, reconcile using read-only lookups and report the
confirmed outcome and remaining work. `--auto` does not authorize automatic
retries, repairs after failure, or creating a replacement ticket. The user can
start a new invocation with the missing information or use interactive mode.

## 1. Resolve context and tools

Apply **`profile`** as a standalone call and read its `tracker` block. Require a
configured Linear connection. If configuration is missing, the provider is not
Linear, or access is unavailable, explain the blocker and preserve the available
ticket draft as markdown. Do not guess a connection or team.

Apply **`ref-mcp-check`** with `mcp: <tracker.mcp>` and the configured
`probe_call`, when present. Inspect the exposed tool descriptions and schemas.
Resolve read-only lookup/search tools, the creation tool, and an update tool only
if a separate update is needed. `create_call`, `status_call` and optional
`update_call` are configured tool hints; verify their actual capabilities and
arguments. Never assume a creation tool accepts updates or invent tool names.
If a configured hint is stale, explain it and use a verified equivalent on the
same Linear connection, or stop if none exists.

## 2. Resolve presets and fields

An explicit `--preset-name` or configured flag alias selects a preset. Match
flags as complete tokens, case-insensitively, normalizing leading dashes. Unknown
flags require clarification. A preset name or alias mentioned in plain prose is
only a suggestion: ask whether to apply it before using its values. Do not
activate presets from incidental text, negation or quoted examples.

Use at most one preset. If several are selected or suggested, ask the user which
to use; do not silently merge them. Report the selected preset and why it applies.

Resolve each field with this precedence:

1. Explicit user value, including an explicit request to leave it unset.
2. Selected preset value.
3. Profile `tracker.defaults` value.
4. Omit optional fields; clarify missing team or intended status.

Apply this rule consistently to team, assignee, state, project, milestone, labels,
priority and due date. Labels replace the lower-precedence list unless the user
explicitly requests additions. With no configured or requested assignee, leave
it unassigned; do not assume the current user. Resolve `me` through the connected
Linear identity. Do not silently substitute another person or status.

Use read-only lookups to validate the final team, assignee, team status, project,
project milestone and applicable labels before creating anything. Resolve
ambiguous names and due dates with the user. Validate field formats and supported
values against the actual tool schema. If a requested field cannot be set,
explain and resolve that with the user before approval; never silently drop it.

Prefer creating the ticket with all resolved fields, including status, in one
call when supported. Otherwise prepare the necessary update on the new issue and
include that second step in the preview. Verify update support before creation.

## 3. Prepare the draft and check duplicates

Write a concise title, preserving the user's wording when clear. The description
should explain the problem or requested outcome and include relevant supplied
context and links. Add a short acceptance checklist only when it helps.

Distinguish supplied facts from assumptions and open questions. Do not invent
root causes, business rules, requirements or implementation decisions. Proposed
acceptance criteria must be identifiable as proposals in the draft. Ask focused
questions when missing information prevents a meaningful ticket; otherwise keep
nonblocking unknowns visible for review.

Search for existing issues by title and key context within the resolved team.
Inspect plausible matches and show their identifiers, links and relevant overlap.
If a plausible duplicate exists, require an explicit decision to create a
separate ticket; do not update the existing issue under this command. If search
fails or is incomplete, disclose that limitation and require acknowledgement
before creation. An empty search result is not proof that no duplicate exists.

## 4. Preview and obtain approval

In `--auto` mode, apply the unattended-mode rules above: show the preview, then
proceed without waiting only if no clarification or acknowledgement is needed.
The approval choices below apply to interactive mode.

Show the complete title and description, all resolved fields (including omitted
optional fields), applied preset, duplicate findings or search limitations, and
any required follow-up update. Present these choices:

- **Create:** explicitly approve this draft, fields and displayed write steps.
- **Edit:** collect changes, repeat affected validation and duplicate checks, and
  present the revised draft for approval.
- **Cancel:** stop without creating or modifying a ticket.

Wait for Create or equivalent explicit approval of this proposal. Silence,
ambiguous replies and preselected options do not count. When duplicate concerns
or incomplete search require acknowledgement, make that condition explicit in
the proposal and approval. A substantive change after approval requires a new
preview and approval. Do not ask again for an unchanged, already approved proposal.

## 5. Create and verify

Execute the approved creation call once, with the validated fields and tool
arguments. If a separate update was approved, use the returned issue ID and the
verified update tool. Never update an unrelated issue.

Verify the identifier, URL and final field values from the returned issue or a
read-only fetch. Report confirmed results only. If creation succeeds but an
update fails, retain the created issue ID and URL, explain the actual state and
remaining change, and offer a repair of that issue for explicit approval. Do not
create a replacement ticket.

If a write times out or its outcome is unclear, do not retry automatically.
Reconcile with read-only lookups first. If the issue exists, inspect and report
it; if the outcome remains uncertain, say so. A retry or repair requires a new
explicit approval describing the remaining operation and any duplicate risk. In
`--auto` mode, report the pending operation and stop without requesting approval.

## 6. Report

Return the issue identifier and URL, confirmed assignee and status, relevant
project/milestone/labels, applied preset, and any unresolved or unverified fields.
For cancellation, report that nothing was created. For a blocked or partial
operation, preserve the draft and clearly distinguish completed writes from
pending work.

## Profile shape

Tool names below are placeholders to resolve against the connected Linear MCP.
Existing profiles may retain their verified `create_call` and `status_call`.
`update_call` is optional and needed only if a separate update is required and
cannot be resolved from the exposed tools.

```jsonc
"tracker": {
  "type": "linear",
  "mcp": "<configured-linear-server>",
  "create_call": "<verified-creation-tool>",
  "status_call": "<verified-status-lookup-tool>",
  "defaults": {
    "team": "<team>",
    "assignee": "me",
    "state": "<team-status>"
  },
  "presets": {
    "<preset-name>": {
      "aliases": ["<flag>", "<phrase>"],
      "project": "<project>",
      "milestone": "<milestone>",
      "labels": []
    }
  }
}
```

Defaults and presets may also supply priority and due date when appropriate.
Keep company-specific values in the profile, not in this skill.
