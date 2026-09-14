# raholsn

A personal, employer-neutral engineering workflow engine for Claude Code.

This plugin holds reusable engineering workflows. Configure company conventions
and testing guidance directly in `ref-company-conventions` and
`ref-company-testing` for the current assignment. Connection settings and tracker
configuration live in the profile; repository guidance supplies local context.
External packs remain an optional way to supply additional documents or agents.

## Layers

| Layer | Where | Lifetime |
|---|---|---|
| Personal doctrine | `~/.agents/AGENTS.md` | yours |
| Engine | this plugin | yours |
| Profile | `$CLAUDE_PLUGIN_DATA/profile.json` | per machine |
| Pack | a plugin in the employer's own repo | per job |
| Repo guidance | `AGENTS.md` in each repo | per repo |

## Install

```bash
claude plugin marketplace add <path-or-github-repo>
claude plugin enable raholsn@raholsn-tools
```

Then run `/raholsn:profile` once. It detects what it can (repo root, VCS host,
base branch, build commands) and asks only for what it cannot.

## Commands

For the user-facing flows, see the [code-review guide](docs/code-review.md),
[fix-comments guide](docs/fix-comments.md),
[grill-me-pragmatic guide](docs/grill-me-pragmatic.md), [logs guide](docs/logs.md),
[rabbitmq guide](docs/rabbitmq.md), [profile guide](docs/profile.md), [SQL Server reader guide](docs/sql-server-reader.md),
[create-linear-ticket guide](docs/create-linear-ticket.md), [write-requirements guide](docs/write-requirements.md),
[plan-implementation guide](docs/plan-implementation.md), and [work guide](docs/work.md).

See the [command dependency graph](docs/command-dependencies.md) for how commands
compose shared references and agents.

- `/raholsn:work TICKET-123 description` takes a task through preflight,
  understanding, architecture and compliance review, delivery planning,
  incremental implementation with validation and review per commit, whole-task
  verification, PR delivery and a retrospective. It preserves a resumable session
  and verifies the delivered PR against the reviewed cumulative change.
- `/raholsn:code-review <PR>` reviews an existing pull request. It resolves ticket
  links from the PR description and comments, fetches requirements through the
  configured tracker MCP, then runs functional review and applicable architecture,
  QA and compliance reviews in parallel. It deduplicates findings and optionally
  posts them as PR comments.
- `/raholsn:fix-comments <PR>` addresses review comments, interactively or
  unattended. It evaluates every comment independently before fixing, and will
  argue back with evidence rather than apply a wrong suggestion.
- `/raholsn:logs <query or trace id>` searches logs and distributed traces
  directly against the telemetry store. It speaks OpenTelemetry semantic
  conventions, so a compliant store needs no field mapping at all. It rebuilds
  call paths when relevant, selects queries for traces, errors, latency or counts,
  and interprets severity using the source's documented scale. It also carries
  deprecated-name tables for stores mid-migration. Needs a `logs` block in the
  profile.
- `/raholsn:rabbitmq <environment and question>` investigates queues, DLQs,
  stalled consumers and broker health through the management HTTP API. Uses
  company-supplied connection/authentication settings, metadata reads first,
  and bounded message fetching with requeue only when authorized. Correlates
  logs when configured and proposes recovery steps without executing them.
  See the [RabbitMQ guide](docs/rabbitmq.md).
- `/raholsn:sql-server-reader <what to look up or SELECT>` investigates SQL Server
  and Azure SQL through Microsoft SQL MCP Server, or Microsoft sqlcmd when MCP
  is not configured. It uses read-only access and company-supplied targets,
  translates questions into supported entity reads or SELECTs, and presents
  Run, Cancel and Edit before execution. It reports pagination, output and
  freshness limits. It has no custom database
  runner and never executes writes or stored procedures.
- `/raholsn:create-linear-ticket <title>` creates one Linear ticket,
  after validating its fields, checking duplicates and obtaining explicit draft
  approval. User instructions override the selected preset and company defaults;
  the preview shows the resolved assignee, status and other fields. Add `--auto`
  to create without manual intervention when validation passes; unresolved
  choices, duplicate concerns or failures stop with a report. See the
  [create-linear-ticket guide](docs/create-linear-ticket.md).
- `/raholsn:grill-me-pragmatic <plan>` interrogates a plan one decision at a
  time, exploring the codebase rather than asking what it can find out, then
  writes a decision record to markdown.
- `/raholsn:write-requirements <plan>` turns a decision record into a PRD without restarting
  discovery, preserving requirements, assumptions and blocking decisions.
- `/raholsn:plan-implementation <PRD>` plans thin vertical implementation slices with
  requirement coverage, dependencies and explicit human decisions.
- `/raholsn:profile` configures the skills with your company’s context. `show` prints the
  resolved values; `reset` backs up and re-bootstraps.

The planning flow is `grill-me-pragmatic` → `write-requirements` → `plan-implementation`: clarify the
plan, record requirements, then break them into implementation issues. Each
produces markdown. Tracker publishing is a separate authorized action for the
PRD and issue breakdown. Start `work` with one selected, actionable issue when
you are ready to implement; planning alone does not start implementation.

`code-review` and `fix-comments` form a loop: the first signs its comments with
`tool_signature`, and the second finds its own threads by matching it. Both read
that value from the profile, so renaming the tool cannot break the pairing.

Inside `work`, the same pass runs through `ref-post-push-review` instead, so the
main workflow depends on two agents rather than on two user-facing commands.

## The rule that makes it portable

Missing optional configuration skips its optional step and is recorded. No tracker
means general development workflows run ticketless; no build command means the
configured validation gate is skipped, not reported as passing. An empty
compliance list skips configured compliance reviewers. No pack skips pack
lookups while repository guidance still applies.

Invalid configuration is reported rather than treated as absent. Commands that
need a particular connection, such as logs, SQL or ticket creation, require that
configuration to fulfil the request. `roots.artifacts` and `vcs.base_branch` are
required effective profile values.

The profile is read afresh for each workflow invocation. Repository overrides
in `repo_overrides`, applicable repository guidance and explicit invocation
instructions refine shared company defaults without rewriting the saved profile.
Bootstrap stores detected build commands under the matching repository override;
existing top-level build settings remain shared company defaults and are checked
against the target repository before use.

The profile configures the skills with your company’s context. An optional pack
adds company conventions, domain knowledge and runbooks.

## Profiles

During PR review, the command reads all PR conversation and review comments,
including integration comments that link the actual ticket. It prefers explicit
issue links, then falls back to identifiers in the PR title or branch according
to the configured conventions. `tracker.issue_hosts` optionally identifies the
tracker's issue-link hosts (for example, `["linear.app"]`), and
`tracker.ticket_regex` validates extracted identifiers.

With a Linear profile, the command reads the linked issue through the bundled
Linear MCP. Its description and acceptance criteria are saved once for all
reviewers. The functional reviewer checks the implementation against those
criteria and distinguishes satisfied, contradicted, and unverified requirements.
It also traces the affected user journey through entry, intermediate steps,
completion, feedback, and recovery, using available client or API evidence.
Ambiguous ticket associations are clarified; absent or inaccessible tickets are
reported as limitations. Review lookup never creates or updates tracker issues.

`profiles/` contains one worked example: `company.example.json`.
Its RabbitMQ sandbox/production templates need real connection values and
provisioned auth files. Credentials stay outside the profile.

Copy it to `$CLAUDE_PLUGIN_DATA/profile.json` and edit, or let
`/raholsn:profile` write it for you.

## Packs

A pack is an employer's own plugin holding what cannot travel: house
conventions, testing doctrine, domain knowledge, runbooks, and any
domain-specific reviewer agents. The profile points at it, and the engine reads
from it by path.

The pack declares the dependency, never the reverse:

```jsonc
{ "name": "acme-pack", "dependencies": [{ "name": "raholsn", "version": "^0.1.0" }] }
```

Where a store does not follow OpenTelemetry, the profile's `logs` block is a
translation table from the standard names onto the local ones, so the deviation
stays configuration rather than reaching the skill.

The plugin bundles its MCP and LSP server declarations in `.mcp.json` and
`.lsp.json`. Keep server definitions needed by the shipped skills here, so
installing a separate plugin is not required to supply them. Authentication
and account access still need to be configured by each user.

Current external dependencies:

| Capability | Connection | Bundled MCP server |
|---|---|---|
| Ticket tracker (`profile`, `create-linear-ticket`, and ticket-related workflow steps) | Linear HTTP MCP | `linear` in `.mcp.json` |
| SQL reads | Microsoft SQL MCP Server, or Microsoft sqlcmd with configured database authentication | Optional `sql-server` HTTP connection in `.mcp.json` |
| Log queries | Elastic Agent Builder HTTP MCP | `elastic` in `.mcp.json` |
| RabbitMQ investigations | Management HTTP API through curl/jq, optional Kubernetes tunnel | None |
| Branches and PRs | Git and the configured host CLI | None |

Additional integrations need their own connection and authentication setup.
Profiles select targets; they do not install services or grant access.

### RabbitMQ setup

Copy the `rabbitmq` block from [the company example](profiles/company.example.json)
into your profile, or use the sandbox/production template in the company example.
Replace sample hosts and `REPLACE_WITH_*` tunnel fields, confirm each vhost, and
choose a default environment or omit it to select one per request. If a broker
is directly reachable, use its HTTPS management root and omit `port_forward`.

Provision each referenced auth-only curl file with owner-only permissions through
your credential tooling. Basic credentials or OAuth tokens belong there, never
in the profile. For OAuth renewal, optional company notes supply the provider,
client, scopes and login/helper procedure. The examples do not install such a
helper or authenticate you. Optional `notes` and `dlq_name_regex` are described
in the [connection contract](claude-plugin/skills/rabbitmq/references/management-api.md).

`/raholsn:profile show` validates configuration and reports environment selection;
it does not verify broker access. Placeholder targets cannot be queried. Run
`/raholsn:rabbitmq <environment> check broker health` when connection setup is
complete. See the [RabbitMQ guide](docs/rabbitmq.md) for the workflow.

### SQL Server reader setup

The reader supports two paths, selected through the profile's `sql.backend`:

- **`mcp`:** configure Microsoft SQL MCP Server (Data API builder) with the
  tables/views and read permissions the company chooses to expose. Set `sql.mcp`
  to the connection name. The optional bundled `sql-server` HTTP connection uses
  `SQL_MCP_URL`; configure its authentication through the MCP client/server.
  Existing named connections and local stdio deployments are also supported.
- **`sqlcmd`:** install Microsoft sqlcmd, configure `sql.servers`, the database
  authentication mechanism and limits, and use a database identity restricted to
  the required reads. Go and ODBC client variants have different authentication
  and encryption options; inspect the installed client's help.

This is company-supplied infrastructure and access configuration. Installing the
plugin does not deploy MCP, expose database entities or grant permissions. An
unconfigured SQL MCP connection does not prevent use of the sqlcmd path.
Authentication details and credentials belong in the connection environment,
not committed profile examples.

The paths have different capabilities: MCP uses structured entity operations;
sqlcmd accepts SQL. A missing entity or failed MCP call never silently triggers
direct database access. Switching requires an explicitly selected, configured
path and authorization for the new read scope. Neither the skill nor sqlcmd's
read-only application-intent setting replaces database permissions.

The earlier custom `.cs` runner has been removed. Its SQL parser, JSON result
contract, hard client row cap and automatic local audit file are no longer
provided. The skill instead bounds reads using the selected tool and query,
reports incomplete output, and uses audit facilities supplied by the environment.
Older `writable_servers` settings never enable writes. See the
[reader guide](docs/sql-server-reader.md) for configuration examples and workflow.

### Elastic MCP setup

The `logs` skill uses the official Elastic Agent Builder MCP endpoint. Use a
deployment that supports it (Elastic 9.2+ or Elasticsearch Serverless), and
configure these environment variables in the environment that launches Claude:

- `ELASTIC_MCP_URL`: the complete Kibana MCP URL,
  `https://<kibana-host>/api/agent_builder/mcp`. For a named space, use
  `https://<kibana-host>/s/<space>/api/agent_builder/mcp`.
- `ELASTIC_MCP_API_KEY`: an encoded API key with Agent Builder application
  access in Kibana and read access to the required indices. Supply the key
  value only; `.mcp.json` adds the `ApiKey` prefix. An old Elasticsearch query
  key may lack the Kibana privileges this endpoint requires.

Keep credentials outside the repository. Restart Claude after configuring its
environment, then check the plugin's `elastic` connection with `/mcp`.
Missing environment variables leave this connection unconfigured; it is not
needed for commands that do not query logs. Installation alone does not establish
access to a customer's deployment.

Set `logs.mcp` to `elastic` in your profile (the default for Elasticsearch).
Keep stream/index selection and field mappings in `logs`; the server URL and
authentication belong to the MCP connection. Legacy `logs.endpoint` and
`logs.auth` fields are no longer consumed. The skill does not fall back to curl.

The skill discovers the server's exposed tool names and schemas, using ES|QL
execution and index discovery/mappings. Tool responses can be truncated, so it
checks coverage before treating results as a complete trace.

References: [Elastic MCP endpoint](https://www.elastic.co/docs/explore-analyze/ai-features/agent-builder/mcp-server),
[API key setup](https://www.elastic.co/docs/explore-analyze/ai-features/agent-builder/mcp-server-api-keys),
[Elastic tool reference](https://www.elastic.co/docs/explore-analyze/ai-features/agent-builder/tools/builtin-tools-reference),
and [Claude environment expansion](https://code.claude.com/docs/en/mcp#environment-variable-expansion-in-mcp-json).

## Plugin manifest notes

Agents declare preloads through their `skills:` frontmatter:

| Agents | Preloaded references |
|---|---|
| Architect, functional reviewer, planner, QA, comment-fixer, retrospective | `ref-company-conventions`, `ref-company-testing` |
| Preflight | `ref-ticket`, `ref-cli-check`, `ref-service-check`, `ref-mcp-check`, `ref-git-preflight` |
| Cross-repo explorer | None |

Configure company guidance directly in the sections of
`claude-plugin/skills/ref-company-conventions/SKILL.md` and
`claude-plugin/skills/ref-company-testing/SKILL.md`. Keep their names stable so the
agents reuse the same references when preparing the next company assignment.
Replace the previous company's rules and record the new scope and sources.
Unconfigured sections impose no requirements.

Caller-supplied documents and profile-selected `knowledge.conventions` or
`knowledge.testing` remain optional overrides. A separate pack is not required
for direct configuration. Agents use their preloaded references without
bootstrapping another profile.

The infrastructure, pipeline, and domain-specific agents from the old plugin
are not shipped here; their specialized references belong with those agents in
a customer pack when needed.

Two things about `plugin.json` are load-bearing and were found by testing rather
than from documentation, on Claude Code 2.1.270:

- **Do not set `skills` or `agents`.** Both directories are auto-discovered.
  Setting either key stops the whole plugin from loading, with no error.
- **A command's name comes from its filename, not its frontmatter.** A command at
  `skills/work/SKILL.md` registers as `/plugin:SKILL`. That is why all
  user-facing commands repeat their name in the filename, as `work/work.md`,
  while internal `ref-*` skills use `SKILL.md`.

All 21 `ref-*` skills supply supporting context for other commands. They set
`user-invocable: false` and `disable-model-invocation: false`, so users cannot
invoke them as commands, but parent workflows can call them. Their descriptions
and instructions require an explicit reference from another command or its
workflow; Claude must not select them independently for a general task.
The explicit-reference requirement is an instruction-level convention; the
invocation flags do not enforce a parent-workflow-only mode.

`profile` and `rabbitmq` remain callable by both users and workflows. Nine other
top-level commands carry `disable-model-invocation: true` and require a user
command.

## Natural-language script commands

These wrappers can be selected implicitly from an action request:

| Request | Command / shell alias |
|---|---|
| Check deployment status | `get-deploy-status` |
| Open this branch's PR page | `show-pullrequests` |
| Open this solution | `open-solution` / `os` |
| Open Argo for this service | `open-argo` |

Each skill runs its matching script bundled in `claude-plugin/tools`; shell aliases
and a separate scripts checkout are not required. Deployment queries take explicit
owner/repo, workflow and job names. PR pages derive from Git remotes. Argo takes
a URL, namespace and exact application name, with optional environment-variable
defaults. No organization, deployment environment or naming scheme is assumed.
See [local script commands](docs/local-script-commands.md) for arguments, defaults
and what each script changes. The scripts remain the implementation; the wrappers
resolve intent and scope, invoke them and report the result.

## Layout

```
.claude-plugin/marketplace.json
claude-plugin/
  .claude-plugin/plugin.json
  skills/
    work/work.md            # the orchestrator
    code-review/code-review.md
    fix-comments/fix-comments.md
    logs/logs.md
    rabbitmq/rabbitmq.md
    sql-server-reader/sql-server-reader.md
    create-linear-ticket/create-linear-ticket.md
    grill-me-pragmatic/grill-me-pragmatic.md
    write-requirements/write-requirements.md
    plan-implementation/plan-implementation.md
    profile/profile.md      # the config layer
    get-deploy-status/get-deploy-status.md
    show-pullrequests/show-pullrequests.md
    open-solution/open-solution.md
    open-argo/open-argo.md
    ref-*/SKILL.md          # 19 shared references + 2 company templates
  agents/                   # 8 generic agents
  tools/
    create-branch-and-pr.sh # bundled GitHub branch and PR helper
    get-deploy-status.sh
    show-pullrequests.sh
    open-solution.sh
    open-argo.sh
profiles/
  company.example.json
```

## Company guidance

Edit the two shared company reference skills for the current assignment. There
is no separate starter directory to copy or maintain. Logging notes may still
be supplied through `logs.notes` when that workflow needs additional context.
