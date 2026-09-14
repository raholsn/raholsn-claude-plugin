---
name: ref-company-testing
description: Company testing template and reference for planning validation, reviewing coverage, and evaluating test results.
user-invocable: false
disable-model-invocation: false
---

# Company testing

Configure the current company's testing guidance directly in the sections below.
Agents preload this reference, so its configured guidance is available wherever
this skill is shared. Keep the skill name stable when changing companies.
Replace previous company-specific content when preparing the next assignment;
record the company, scope and authoritative sources so its applicability is clear.

The sections are initially unconfigured and impose no requirements until filled.
If no applicable guidance is configured, use repository guidance and observed
patterns, distinguishing observations from confirmed company requirements.

A caller may explicitly supply a separate document, or select one through
`knowledge.testing` in its effective profile. Read that document when provided
(resolve relative paths against `pack`); it overrides the corresponding local
sections for that invocation. Report material conflicts or unclear applicability.
Do not bootstrap a profile inside an agent. External documents are optional;
configuring this reference directly requires no pack or profile knowledge path.

## Ownership and sources

Not configured. Record the company/team, scope, authoritative documents, and
the date the testing requirements were confirmed.

## Test strategy

Not configured. Record which risks require unit, integration, contract, or
system tests, and the company's expectations for regression coverage.

## Frameworks and fixtures

Not configured. Record approved frameworks, fixture patterns, test-data setup,
isolation, shared infrastructure, and cleanup requirements.

## Execution and environments

Not configured. Record where tests run and required backing services. Reference
the profile's `build` commands rather than duplicating shell commands here.

## Acceptance and evidence

Not configured. Record required validation for a change, treatment of flaky or
unavailable tests, and what evidence reviewers expect. Do not treat a test that
was not run as passing.
