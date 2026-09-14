---
name: ref-company-conventions
description: Company engineering conventions template and reference for architecture, implementation, review, and delivery agents.
user-invocable: false
disable-model-invocation: false
---

# Company conventions

Configure the current company's engineering conventions directly in the sections below.
Agents preload this reference, so its configured guidance is available wherever
this skill is shared. Keep the skill name stable when changing companies.
Replace previous company-specific content when preparing the next assignment;
record the company, scope and authoritative sources so its applicability is clear.

The sections are initially unconfigured and impose no requirements until filled.
If no applicable guidance is configured, use repository guidance and observed
patterns, distinguishing observations from confirmed company requirements.

A caller may explicitly supply a separate document, or select one through
`knowledge.conventions` in its effective profile. Read that document when provided
(resolve relative paths against `pack`); it overrides the corresponding local
sections for that invocation. Report material conflicts or unclear applicability.
Do not bootstrap a profile inside an agent. External documents are optional;
configuring this reference directly requires no pack or profile knowledge path.

## Ownership and sources

Not configured. Record the company/team, scope, authoritative documents, and
the date these conventions were confirmed.

## Architecture and boundaries

Not configured. Record service/module responsibilities, dependency direction,
shared-library rules, and relevant architectural decisions.

## Contracts and data

Not configured. Record API/event compatibility, database migrations, transaction
boundaries, idempotency, and concurrency rules that apply to this company.

## Implementation and operations

Not configured. Record naming, error handling, logging/redaction, configuration,
and operational requirements. Keep executable commands in the profile.

## Delivery and review

Not configured. Record review expectations, release constraints, and exception
handling. Reference the company testing document for testing policy.
