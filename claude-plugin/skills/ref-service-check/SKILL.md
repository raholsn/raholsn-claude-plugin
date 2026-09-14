---
name: ref-service-check
description: Verify required local backing services are reachable by probing their ports. Warns when one is down rather than failing silently. Internal sub-skill.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Service Check

Internal sub-skill. The caller passes the local services the task needs.

## Caller contract

| Input | Default | Notes |
|---|---|---|
| `services` | none | `{name, port}` entries from the profile's `local_services` |
| `start_hint` | none | Command the user can run to bring them up, if the profile or repo guidance names one |

**If `services` is empty, report `skipped (not configured)` and return.** Do not
guess which services a repo needs from its source.

## Process

For each entry, probe the port:

```bash
nc -z localhost <port>
```

If the runtime has no `nc`, fall back to listing running containers and matching
by name.

If a port is closed, report which service is down and its expected port, then
warn:

```
<name> on port <port> is not responding. Tests that depend on it will fail.
Start it (<start_hint>) and re-run, or continue anyway?
```

Do not silently continue on failures. Always surface them, and let the caller or
the user decide.

## Done

All requested ports respond, or the user explicitly chose to continue with one or
more down. Output: `Service check passed (<n>/<n> responding)` or
`skipped (not configured)`.
