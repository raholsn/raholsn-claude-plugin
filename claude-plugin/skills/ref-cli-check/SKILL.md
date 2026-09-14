---
name: ref-cli-check
description: Verify CLI tools, shell aliases, and tool plugins are installed. Collects all missing items, presents them in one prompt, and offers an install flow. Internal sub-skill.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# CLI Check

Internal sub-skill. The caller passes the tools it needs; this verifies them in
parallel and offers to install anything missing.

## Caller contract

| Input | Default | Notes |
|---|---|---|
| `required` | none | Tools whose absence blocks the workflow |
| `optional` | none | Tools whose absence is a warning only |
| `aliases` | none | `{name, source}` pairs; `source` is the script the alias points at |
| `plugins` | none | Plugins a listed tool loads, as `{tool, plugin, version}`, where a pin matters |
| `shell_rc` | `~/.zshrc` | Where aliases are declared |

All five come from the profile's `toolchain` block. **If the caller passes
nothing, report `skipped (not configured)` and return.** Do not invent a tool
list from the repo.

## Process

### Verify in PARALLEL

- For each tool in `required` and `optional`, run `command -v <tool>`.
- For each alias, grep `shell_rc` for its name.
- For each plugin, run that tool's own list command.

**Collect ALL missing items before reporting.** Never stop at the first.

Treat a tool as present if `command -v` resolves it, whether it is a binary, a
function, or an alias.

### Report and offer install

If anything is missing, present one list and ask:

```
Missing:
  - <item>  (required | optional)  install: <command>
Install now, or continue without?
```

Install sequentially, respecting dependencies: a language runtime before a tool
that ships through it, an auth step after the CLI that needs it.

- For a CLI with its own auth (a VCS host CLI, a cloud CLI), run its login
  command and wait for the user.
- For a daemon-backed tool such as a container runtime, wait for the user to
  start it rather than trying to start it yourself.
- For an alias, verify the `source` path exists before appending the alias line
  to `shell_rc`, then re-source it.

Re-verify everything with `command -v` after install.

### Authentication

For any tool in `required` that has a login state, check it. The generic probe is
the tool's own status subcommand. Report an unauthenticated tool as missing, not
as present, because the workflow will fail later either way.

## Done

All `required` items are installed and authenticated, or the user explicitly
chose to continue without them. Missing `optional` items are reported and do not
block. Output one line: `CLI check passed` or `CLI check passed with N optional
missing` or `skipped (not configured)`.
