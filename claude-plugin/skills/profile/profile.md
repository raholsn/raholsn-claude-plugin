---
name: profile
description: Configure raholsn skills with company context. Load, validate, show or reset shared settings and resolve repository overrides (roots, VCS, tracker, build commands, pack path).
argument-hint: (no args) | reset | show
---

# Profile

The profile configures skills with shared company settings; optional packs and repository guidance
supply additional company knowledge and repository-specific overrides. Company
conventions and testing guidance can be configured directly in the shared
`ref-company-conventions` and `ref-company-testing` skills; do not require a pack
or create external knowledge paths for that setup. Workflows resolve
these inputs before using them. Nothing in the engine may hardcode an org, a
repo name, a tracker, or a build command.

**Run this as a standalone tool call.** Do not interleave it with other calls.

## Location

```
$CLAUDE_PLUGIN_DATA/profile.json
```

`$CLAUDE_PLUGIN_DATA` survives plugin updates. If the variable does not resolve
in your runtime, fall back to `~/.raholsn/profile.json` and say so once.

## Process

### 1. Dispatch the argument, then read

Resolve the profile path and handle the argument before deciding to bootstrap:

- **No argument:** load and validate an existing file. Bootstrap only if absent.
- **`show`:** read, validate and print the resolved block and its path. If missing
  or invalid, report that condition. Never bootstrap, repair or write in this mode.
- **`reset`:** bootstrap a replacement even if the existing file is valid. Before
  replacing it, copy the original bytes to `profile.json.bak`; if that exists, use
  a unique timestamped backup instead. If backup fails, stop without replacing
  the profile. Keep the original in place until the replacement is ready.
- **Unknown argument:** report supported arguments without changing anything.

Read with the Read tool in a standalone call. Malformed JSON is an error, not
an absent profile: report the path and parser location/message, preserve the
file, and stop loading it. Do not claim a particular key broke unless known.
An explicit `reset` can replace an invalid file using the backup procedure above.

For each top-level workflow invocation, read the profile afresh and resolve it
for the target repository. Share that snapshot with downstream steps and agents;
they must not bootstrap independently. An explicit `show`, `reset`, profile edit,
or change of target repository requires fresh resolution. Do not carry cached
values across workflow invocations.

### 2. Bootstrap when absent or explicitly reset

Ask only for what cannot be detected. Treat detection as proposed configuration,
show its evidence and uncertainty before writing, and resolve consequential
ambiguities such as the repository owner, base branch or tracker team.
Do not run build or test commands during detection.

| Value | Evidence |
|---|---|
| `roots.repos` | Explicit user-provided repo-root environment variable, otherwise the parent of the current repository; outside a repository, ask for the intended root |
| `vcs.host`, `vcs.org` | Parse the target remote URL into host and owner, handling SSH and HTTPS; map supported providers to their host identifier and CLI, preserving self-hosted host information when needed |
| `vcs.base_branch` | Target remote's default branch from its symbolic HEAD or a read-only host lookup; normalize `origin/main` to `main`. Never use the current feature branch as a default. If unresolved, ask |
| `build.*` | Explicit repository guidance, CI configuration, scripts, package manager and test-runner configuration, scoped to the intended workspace |
| `guidance_file` | `AGENTS.md` if present, otherwise `CLAUDE.md` if present, otherwise null |

Use `origin` when it identifies the intended repository. Missing or ambiguous
remotes, including forks with a different upstream target, require resolving the
target before saving VCS defaults. Do not store credentials embedded in a URL.

Project markers identify candidates, not verified commands. For example,
`package.json` alone proves neither an npm build script nor support for `-t`;
`pyproject.toml` alone proves neither a build backend nor pytest. Inspect scripts,
lockfiles and runner configuration before proposing commands. For mixed stacks
or multiple workspaces, use the repository's documented entrypoint or ask which
workspace is intended. Leave unsupported commands and filter templates null.

Ask for:

1. **Ticket tracker**, or none. Discover available MCP connections; ask which to
   use only when ambiguous or unavailable. Probe with a read-only call. Resolve
   the current user and available teams through that MCP, and ask for the team
   when there is more than one plausible choice. Do not select the first prefix
   silently. If unavailable, leave tracker setup pending or proceed without it
   according to the user's choice; never fabricate IDs.
2. **Pack path**, if they have one. Offer none.

If RabbitMQ setup is requested, collect environment names, management URLs,
vhosts and protected auth-file paths, plus optional Kubernetes tunnel settings
and company notes. Use the schema in
[`rabbitmq/references/management-api.md`](../rabbitmq/references/management-api.md).
Do not run the RabbitMQ investigation during profile setup. Do not inspect auth
file contents, fetch tokens, start tunnels or contact a broker just to load/show
configuration. Keep RabbitMQ omitted when it is not requested. Example profiles
are templates: resolve `REPLACE_WITH_*` and example.com endpoints with the user
before presenting the requested connection as ready.

Use these defaults for new profiles unless the user specifies otherwise:

| Key | Default |
|---|---|
| `assignment` | `day-one` |
| `roots.artifacts` | `~/.raholsn-work` |
| `vcs.draft_prs` | `true` |
| `vcs.branch_template` | `{description}` |
| `vcs.pr_title_template` | `{description}` |
| `vcs.commit_title_template` | `{title}` |
| `tool_signature` | `raholsn` |
| Unconfirmed build commands and test filter | null |
| Optional tracker, logs, SQL, RabbitMQ, pack, knowledge, toolchain, services, compliance and hooks | omitted |

Save repository-derived build settings under `repo_overrides`, keyed by the
absolute target repository root, rather than making them defaults for unrelated
repositories. Explicitly supplied shared build defaults remain in
`build`. Each override uses the same field structure as the main profile, e.g.:

```json
"repo_overrides": {
  "/home/developer/dev/web-app": {
    "build": { "build_cmd": "npm run build", "test_cmd": "npm test" },
    "vcs": { "base_branch": "main" },
    "guidance_file": "AGENTS.md"
  }
}
```

Validate the proposed profile before writing. Create the profile's parent
folder as needed, write a temporary sibling file, verify it parses and validates,
then replace the destination. Preserve existing unknown fields when making
focused repairs; only explicit reset starts from scratch. A cancelled or failed
bootstrap leaves any existing profile intact.

### 3. Resolve and validate

Require a JSON object. Validate known blocks as objects, list fields as arrays
(`compliance`, `local_services`, `post_merge_hooks`), `vcs.draft_prs` as a boolean,
and configured paths, commands and identifiers as strings. Optional fields may
be absent or null; null disables that field. Validate `repo_overrides` as an
object of repository-root keys and profile-shaped override objects, without
nested `repo_overrides`. Preserve unknown fields for other consumers; this
loader does not validate every service-specific schema.

Recognize optional `rabbitmq` as an object (or absent/null). When present, validate
`environments` as a nonempty object of environment objects, and any configured
`default_environment` as a nonempty string naming one of those environments.
Validate each environment against the RabbitMQ connection contract linked above:
URL shape, vhost, auth type/path, optional regex/notes and tunnel field types and
port consistency. This is configuration validation only. Check file access,
credentials, tunnel readiness and broker access only when the RabbitMQ command
runs. Placeholder targets remain explicitly unconfigured for RabbitMQ and do
not block unrelated workflows; malformed configured values remain errors.

Resolve effective values in this order:

1. Shared company defaults in the profile.
2. Matching `repo_overrides` entry, using the normalized absolute Git repository
   root. Merge objects by field; replace arrays and scalars, including null.
3. Explicit settings in the target repository's applicable guidance.
4. Explicit instructions for the current invocation.

Without a target repository, resolve shared company defaults only and report that
repository overrides were not applied; `show` must not prompt for a repository.
An override changes the effective snapshot, not the saved profile. Pass the full
resolved object to callers, not only the printed summary. Report which repository
and override sources were used. Existing top-level build settings remain valid
shared company defaults, but check their applicability against repository evidence
before handing them to execution. If they conflict with the target stack or
workspace and no explicit override resolves the conflict, surface the mismatch
and resolve the affected command rather than executing it blindly.

`roots.artifacts` and `vcs.base_branch` must be nonempty strings after resolution.
Reject missing or invalid required values and wrongly typed configured values
with their dotted paths; valid JSON alone is insufficient. For `show`, report
validation errors without mutation. For normal loading, explain the needed
correction and stop until resolved; do not silently reset. Report unresolved
optional values as unset, not as verified defaults. Consumers validate additional
configuration needed for their particular action.

Expand paths as described below. The loader does not create artifact directories
just to show or load configuration; artifact-writing workflows create the
configured directory before use and report any creation or access failure.

### 4. Emit the resolved block

Print this summary using effective resolved values, writing `unset` for absent
or null scalar fields and `none` for absent or null optional blocks. Follow it
with the target repository and override sources when applicable:

```
Profile: <assignment>  (<path>)
  roots.repos        = <value>
  roots.artifacts    = <value>
  vcs                = <host> <org> base=<base_branch> draft=<draft_prs>
  tracker            = <type> prefix=<prefix> mcp=<mcp>   | none
  logs               = <type> mcp=<mcp> | none
  rabbitmq           = environments=<names> default=<name or unset> | none
  build              = <build_cmd> | unset
  test               = <test_cmd> | unset
  pack               = <path> | none
  guidance_file      = <value>
  tool_signature     = <value>
```

Downstream steps reference these by dotted key, for example `vcs.base_branch`.

For an Elasticsearch `logs` block, `logs.mcp` defaults to `elastic`. The bundled
server is configured separately through `ELASTIC_MCP_URL` and
`ELASTIC_MCP_API_KEY`; the profile does not supply those environment variables.
Do not print credentials in the resolved block. Older `logs.endpoint` and
`logs.auth` values are not used by the MCP-based `logs` skill; preserve its
field/index mappings and point to the README's Elastic MCP setup when migrating.

For RabbitMQ, show environment names and the configured default, or `unset` if
selection is required. Flag placeholder targets as unconfigured. Do not print
auth-file contents or claim access was verified. Paths and connection values
are passed in the effective object to the consumer, not read from a credential
file into the summary.

## The rule every consumer inherits

**Missing optional configuration skips its optional step. Invalid configuration
and missing prerequisites for the requested action must be reported.**

- No `tracker`: general development workflows run ticketless, derive branch names
  from the description, and skip tracker actions. A request to create a ticket
  needs tracker setup before it can be fulfilled.
- No `build.build_cmd`: the configured validation gate is skipped and recorded
  as not run. Never report skipped validation as passing.
- Empty or absent `compliance`: skip configured compliance reviewers.
- No `pack`: skip pack lookups; applicable repository guidance still applies.
- No `logs`, `sql` or `rabbitmq`: unrelated workflows continue, but a matching query request
  reports the missing prerequisite and needs configuration before querying.

Do not convert a configured but malformed or inaccessible dependency into an
unconfigured one. Report the limitation; the caller decides whether its requested
outcome can still be met. Missing optional configuration never authorizes invented
commands, targets, IDs or successful results.

## Resolving paths

- `~` expands to `$HOME`.
- Resolve relative `roots.*` and `pack` paths against the profile directory.
- `guidance_file` resolves against the target repository root.
- Normalize `repo_overrides` keys to absolute repository roots; require absolute
  or home-relative keys and reject duplicate keys after normalization.
- Relative `knowledge.*` and `post_merge_hooks` entries resolve against `pack`.
- `repo_roles.*` values resolve against `roots.repos`.
- RabbitMQ auth-file paths resolve against the profile directory; relative
  RabbitMQ notes resolve against `pack`. Expand home-relative paths and preserve
  absolute paths as specified by its connection contract.
- `{ticket}`, `{description}`, `{title}`, `{class}`, `{repo}` are the only
  workflow template placeholders. Service-specific templates such as logs
  `{service}` are defined by their consumer. Substitute values as data with
  appropriate quoting when constructing commands; never evaluate substituted text.

## Migrating an older config

If the profile is absent and the user names a legacy config file, read it and
pre-fill what maps cleanly. A flat `key=value` file holding a ticket prefix, a
user id and a label id maps onto `tracker.prefix`, `tracker.user_id` and
`tracker.label_id`.

Tell the user which values were carried over, and ask them to confirm each one is
still current before writing. A stale ticket prefix from a previous team is the
most common thing such a file carries, and it will silently file new tickets in
the wrong place. Do not delete the old file.

## Arguments

- no argument: load, bootstrapping only if absent.
- `show`: print the resolved block and the file path, change nothing.
- `reset`: bootstrap from scratch, backing up the original before replacement as
  described in step 1.

## Done

A validated effective profile and its source path are available to the caller,
with unresolved optional configuration and repository overrides identified. Or
the loader has reported why resolution failed, preserving the existing file.
Never continue dependent actions using a profile that failed validation.
