---
name: ref-mcp-check
description: Verify a named MCP server is connected and authenticated before a workflow depends on it. Internal sub-skill.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# MCP Check

Internal sub-skill. The caller passes the MCP server it needs and the cheapest
read-only call to probe it with.

## Caller contract

| Input | Default | Notes |
|---|---|---|
| `mcp` | none | Server name, e.g. from the profile's `tracker.mcp` |
| `probe_call` | none | A cheap read-only call on that server, e.g. `tracker.probe_call` |

**If `mcp` is absent, report `skipped (not configured)` and return.**

## Process

Make the `probe_call` against the named server. If the caller did not name one,
pick the lightest read-only call the server exposes. Never pick a call that
writes.

Outcomes:

- **Success.** The server is ready. Continue.
- **Auth error.** Identify the connection's authentication method. For OAuth,
  direct the user to `/mcp` to complete sign-in. For API-key connections, identify
  the configured environment variable or missing permission without printing
  credentials, and ask the user to fix it and reconnect. Wait for confirmation.
- **Server absent.** Warn that the server is not installed in this Claude
  session at all. The caller decides whether to abort or continue with reduced
  functionality. For a tracker, reduced functionality means the workflow runs
  without a ticket.

## Done

The named server is reachable, or the user explicitly opted to continue without
it. Output: `<mcp> ready`, `<mcp> unavailable, continuing without`, or
`skipped (not configured)`.
