---
name: get-deploy-status
description: "Show deployment workflow job status. Use when the user asks whether a service deployed or wants recent deployment results."
user-invocable: true
disable-model-invocation: false
argument-hint: "<owner/repo[,owner/repo]> <workflow> <job-name-substring> [limit]"
---

# get-deploy-status

Request: $ARGUMENTS

Run `zsh "${CLAUDE_PLUGIN_ROOT}/tools/get-deploy-status.sh"` with explicit
owner/repo identifiers as one comma-separated argument, workflow name or file,
deployment-job name substring, and optional run limit (default 10, maximum 100).

Resolve repository ownership from the selected Git remote or explicit input.
Inspect repository workflow files for the requested environment's workflow/job
names; ask when ambiguous or unavailable. Do not assume an organization, pipeline
name or production deployment job. Use separate quoted arguments and report all
matching jobs, links, failures and missing matches. Job results do not prove live
application health. No deployment or workflow is triggered.
