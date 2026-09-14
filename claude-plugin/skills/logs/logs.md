---
name: logs
description: Search and trace backend logs and distributed traces through Elastic MCP, by trace id, span, service, severity, or latency. Speaks OpenTelemetry semantic conventions. Use whenever investigating a production or staging issue, an error, a slow response, or unexpected behavior, including when the user just says "check the logs", "why is this failing in prod", or hands you a trace or correlation id.
disable-model-invocation: true
argument-hint: [what to search for, or a trace id]
---

# Log & Trace Search

Query: $ARGUMENTS

Query the telemetry store through the configured Elastic MCP server. Tool
responses can be limited or truncated; a partial result is not a complete trace.

This skill reasons in **OpenTelemetry semantic conventions**. A store that emits
OpenTelemetry needs no field mapping at all. A store that does not gets one
translation table in the profile, and nothing about it leaks in here.

## 0. Resolve the profile

Apply **`profile`** and read its `logs` block.

**If there is no `logs` block, stop and say so.** Offer to add one. Do not guess an
MCP connection or an index. A wrong index can return zero rows, which
reads as "nothing happened" when the truth is "you asked the wrong question".

```jsonc
"logs": {
  "type": "elasticsearch",
  "mcp": "elastic",                  // server key in the plugin's .mcp.json
  "mapping": "otel",                  // "otel" | "ecs" | "custom"
  "streams": { "logs": "logs-*.otel-*", "traces": "traces-*.otel-*" },
  "default_window": "1 hour",
  "keyword_suffix": ".keyword",       // for non-OTel stores that need it
  "field_map": {},                    // only when mapping is "custom"
  "severity_map": {},                 // source level values for ECS/custom
  "span_kind_map": {},                // only when mapping is "custom"
  "notes": "knowledge/logging.md"
}
```

## 1. Resolve the MCP connection

Use `logs.mcp`, defaulting to the bundled `elastic` server for an Elasticsearch
profile. The bundled connection reads `ELASTIC_MCP_URL` and
`ELASTIC_MCP_API_KEY` from the environment inherited by Claude. It points at
Elastic Agent Builder in Kibana: `<kibana-url>/api/agent_builder/mcp`, or
`<kibana-url>/s/<space>/api/agent_builder/mcp` for a named space. It is not the
Elasticsearch `/_query` endpoint.

The deployment must expose Agent Builder MCP. An API key needs Agent Builder
access in Kibana as well as read access to the target data. Never print or
retrieve the key into conversation context; the MCP client handles authentication.
See the README's Elastic MCP setup instructions.

Older profiles may still contain `logs.endpoint` and `logs.auth`; those fields
are no longer used. Keep their stream and field mappings, but report the MCP
setup required. Do not infer a Kibana URL from an Elasticsearch hostname or
silently fall back to shell queries.

## 2. Discover and check the tools

Discover tools on the server selected by `logs.mcp`. Plugin MCP server and tool
names may be namespaced or normalized by the client; use the actual exposed
names and input schemas, not a guessed `mcp__...` identifier.

Elastic Agent Builder's relevant tool IDs are:

| Tool ID | Purpose |
|---|---|
| `platform.core.execute_esql` | Run the bounded ES\|QL query |
| `platform.core.get_index_mapping` | Verify fields on the selected indices |
| `platform.core.list_indices` | Discover accessible indices and data streams |

Resolve the stream from `logs.streams`, or the requested environment in
`logs.indices` (falling back to `logs.default_index` when configured). If no
target is configured, use index discovery to identify candidates and ask which
to use; never treat all accessible indices as the search scope. When
`separate_traces_stream` is false, use the chosen log index for both signals.

Apply `ref-mcp-check` with the resolved server and its exposed read-only mapping
or index-listing tool as the probe, using the actual schema and selected index
where supported. This operation is read-only. If the server is absent,
unauthenticated, or lacks an ES|QL execution tool, stop and identify the missing
connection, permission, or capability. For the bundled API-key connection, fix
the environment/key privileges and reconnect; browser sign-in alone does not
configure its API key. Do not claim there are no matching logs after a failed call.

Only use read-only query and discovery tools for this skill. Other tools exposed
by Agent Builder, including tools that execute workflows or change data, are
outside this skill's scope.

## 3. Know which shape you are querying

Three shapes, declared by `logs.mapping`. This is the first thing to establish,
because the same concept has a different field name in each.

| Concept | `otel` | `ecs` | `custom` |
|---|---|---|---|
| Trace id | `trace_id` | `trace.id` | `field_map.trace_id` |
| Span id | `span_id` | `span.id` | `field_map.span_id` |
| Parent span id | `parent_span_id` (spans only) | `parent.id` | `field_map.parent_span_id` |
| Severity name | `severity_text` | `log.level` | `field_map.severity_text` |
| Severity number | `severity_number` | `event.severity` | often absent |
| Message | `body.text` | `message` | `field_map.body` |
| Record attributes | `attributes.*` | flattened | `field_map.*` |
| Resource attributes | `resource.attributes.*` | flattened `service.*` | `field_map.*` |

**The quick tell for an Elasticsearch store:** an index or data stream containing
`.otel-` is OpenTelemetry-native, so expect `trace_id` and `body.text`. Something
shaped like `*-apm*` or plain ECS gives you `trace.id` and `message`.

Under `otel`, semantic-convention keys are preserved verbatim beneath
`attributes.` and `resource.attributes.`, so `attributes.http.request.method` and
`resource.attributes.service.name` are the real field paths.

The OpenTelemetry data model spells fields in PascalCase, the wire protocol uses
snake_case, and its JSON form uses lowerCamelCase. All three are in circulation.
`TraceId`, `trace_id` and `traceId` are the same field.

## 4. Severity

OpenTelemetry severity is a **number**, and the ranges are the contract:

| Range | Name |
|---|---|
| 1-4 | TRACE |
| 5-8 | DEBUG |
| 9-12 | INFO |
| 13-16 | WARN |
| 17-20 | ERROR |
| 21-24 | FATAL |

Choose the filter for the actual source, not just the field's numeric type:

- **OpenTelemetry:** when the field is populated with OTel severity numbers,
  filter errors with `severity_number >= 17`, including FATAL. Severity text is
  source-defined; use it for display rather than assuming one spelling. If
  numeric severity is missing, use documented source-level values or a verified
  `severity_map` and report the coverage limitation.
- **ECS:** `event.severity` uses the event source's scale. Never apply the OTel
  threshold unless the source explicitly documents that scale. Use documented
  error/fatal values in `log.level` (including their actual casing), or a numeric
  predicate supported by the source's severity definitions. Read `logs.notes`
  or the configured `severity_map`; mappings establish types, not level meaning.
- **Custom:** use `field_map.severity_text` and the error/fatal values in
  `severity_map`, or another source-documented predicate. Do not infer the
  numeric scale from example values alone.

For ECS/custom, `severity_map` maps OTel level names to the source's text values
in its severity-name field. If semantics remain unknown, report that an error
filter cannot be established reliably. Continue with relevant request, service
or event evidence where possible instead of inventing a threshold. Missing
severity is not evidence of a successful operation.

See the [ECS severity definition](https://www.elastic.co/docs/reference/ecs/ecs-event#field-event-severity).

## 5. The trace model

Three identifiers, and one asymmetry that matters:

- **`trace_id`** spans the whole request chain. Present on both logs and spans.
- **`span_id`** is one unit of work. Present on both.
- **`parent_span_id`** links a span to its caller. **Present on spans only.** A log
  record does not carry it.

That asymmetry drives the method. **You rebuild the call tree from span
documents, then use logs for detail.** Trying to build a tree from log rows alone
does not work on an OpenTelemetry store, because the parent link is not there.

Two profile flags change this. When `separate_traces_stream` is false, there are
no span documents and everything lives in one stream. When `parent_span_on_logs`
is true, the store puts the parent link on log records, which is a deviation from
the specification in a useful direction: you can build the tree from logs alone.
With both set that way, treat the log stream as the span stream and proceed
exactly as below.

An empty or all-zero `parent_span_id` means a root span, which is where the
request entered the system.

Span kinds tell you what each hop is:

| Kind | Meaning |
|---|---|
| `SERVER` | Inbound request being handled |
| `CLIENT` | Outbound call awaiting a response, **including database calls** |
| `PRODUCER` | Work scheduled or a message published |
| `CONSUMER` | Work processing something a producer started |
| `INTERNAL` | Neither, the default |

Span status is `Unset`, `Ok` or `Error`. **`Unset` is the default status; it
is not proof of success or absence of failure.** Instrumentation generally leaves
status unset unless it records an error, while applications may explicitly set
`Ok`. Use `Error` to find explicitly error-marked spans; do not use "not Ok" as
an error filter or exclude unset spans from latency and request investigations.
Correlate status with logs, response codes, timing and other available outcomes
before drawing a conclusion. See the
[OpenTelemetry status specification](https://opentelemetry.io/docs/specs/otel/trace/api/#set-status).

If the store carries `traceparent` headers, the format is
`version-traceid-parentid-flags`: two hex characters, thirty-two, sixteen, then
two. The trailing `01` means sampled. An unsampled request may have no spans
stored at all, which is a common reason a trace looks missing rather than broken.

## 6. Method

1. **Establish scope and time.** Honor the user's explicit environment, filters
   and time window. Use `logs.default_window` only when no window was supplied.
   Resolve relative times once into concrete UTC bounds for consistent repeated
   queries; clarify an ambiguous timezone if it changes the scope materially.
   Keep requested totals within those bounds. For trace follow-up, a deliberately
   wider window can capture delayed asynchronous work; label that extra scope
   separately rather than silently changing the original query.
2. **Choose the starting query from the question.**

   | Intent | Starting query |
   |---|---|
   | Trace or correlation lookup | Filter by the supplied identifier and scope, across relevant levels/statuses. |
   | Error investigation | Use the source-appropriate severity/status or documented failure predicate, then inspect matching requests. |
   | Latency investigation | Query the relevant operations and duration field, verifying its unit. Include successful and unset-status operations; sort by duration for slow examples or aggregate for requested statistics. |
   | Counts, rates or trends | Aggregate matching records across the full requested scope; define what is counted and any rate denominator. Do not count a limited sample as the total or mix logs and spans as if they were unique requests. |
   | Ordinary event or service search | Apply the requested fields or event text without adding an error-only filter. |

3. **Follow a request only when useful.** For a selected trace, query span IDs,
   parent IDs, operation names, kind, timing and status, then reconstruct the
   available relationships. Select candidate traces that match the question;
   do not substitute an unrelated error trace for a slow or ordinary request.
   If trace relationships are unavailable, use a bounded log timeline and state
   that limitation. Aggregations do not require a trace ID or call tree.
4. **Inspect relevant detail.** For trace follow-up, pull logs for the relevant
   trace and span together. Read only the attributes and body fields needed to
   explain the behavior. Event searches can inspect their requested message
   fields directly; building a call tree is not a prerequisite.
5. **Check coverage and report.** Handle query errors and truncation explicitly.
   Distinguish observed evidence from inferred cause and missing context. Do not
   infer successful execution from a missing error record or unset span status.

For request investigations, establish the available relationships before reading
large payloads. For aggregate questions, compute the requested result directly
and use individual records only as supporting examples.

## 7. Signals worth filtering on

Stable attribute names, with the deprecated predecessors you will still meet in
older data. Query both when the data spans a migration.

**HTTP**

| Current | Deprecated |
|---|---|
| `http.request.method` | `http.method` |
| `http.response.status_code` | `http.status_code` |
| `url.full` (client spans) | `http.url` |
| `url.path`, `url.query` (server spans) | `http.target` |
| `server.address`, `server.port` | `net.host.name`, `net.peer.name` |
| `client.address` | `http.client_ip` |
| `user_agent.original` | `http.user_agent` |
| `http.route` | server-side route template, the low-cardinality grouping key |

`net.peer.name` is direction-dependent: it became `server.address` on client
spans and `client.address` on server spans.

**Database**

| Current | Deprecated |
|---|---|
| `db.system.name` | `db.system` |
| `db.query.text` | `db.statement` |
| `db.operation.name` | `db.operation` |
| `db.namespace` | `db.name` |
| `db.collection.name` | `db.sql.table`, `db.mongodb.collection` |
| `db.stored_procedure.name`, `db.query.summary`, `db.response.status_code` | |

`db.system` was renamed **and its values changed**: `mssql` became
`microsoft.sql_server`, `oracle` became `oracle.db`, `dynamodb` became
`aws.dynamodb`. Filtering `db.system.name == "mssql"` silently returns nothing.

**Messaging.** These conventions are still experimental, so expect either
generation in the same system. `messaging.system`,
`messaging.destination.name`, `messaging.message.id`,
`messaging.message.conversation_id` for the correlation id, and
`messaging.operation.type` whose values are `create`, `send`, `receive`,
`process`, `settle`. The older `publish` became `send` and `deliver` became
`process`. `messaging.operation` became `messaging.operation.type`.

**Errors.** `exception.type`, `exception.message`, `exception.stacktrace`, and
`error.type`. At least one of exception type or message is always present on an
exception record, so search both. For HTTP, `error.type` carries the status code
as a string when one is available. There is no general-purpose `error.message`;
`exception.escaped` is deprecated, so do not build a filter on it.

**Service and infrastructure.** `service.name`, `service.namespace`,
`service.version`, `service.instance.id`, and `deployment.environment.name`. That
last one was renamed from `deployment.environment`, which is the single most
likely cause of a stale environment filter. Kubernetes resources are
`k8s.pod.name`, `k8s.namespace.name`, `k8s.container.name` and
`k8s.deployment.name`.

## 8. Query mechanics

Pass ES|QL to the discovered `platform.core.execute_esql` tool using its exposed
input schema. For example, after substituting the resolved stream:

```esql
FROM <stream>
| WHERE @timestamp > NOW() - 1 hour
| SORT @timestamp ASC
| LIMIT 20
```

Use `logs.default_window` or the user's explicit window instead of the example's
one hour, with the explicit window taking precedence. For repeated queries,
replace the relative expression with the fixed UTC bounds established in step 6.
Apply the trace/span/service filter before sorting and limiting.
Verify field names with mappings before querying; identifiers and values taken
from user input must be escaped as ES|QL data, never spliced in as query syntax.

- **Exact-match filters may need a keyword subfield.** Where `logs.keyword_suffix`
  is set, append it before comparing with `==` or `IN`. A bare text field in a
  term filter returns zero rows silently. Use the base name for `LIKE` and
  full-text matching.
- Always bound returned rows with `LIMIT`. Sort before limiting for worst-case
  examples. For counts and statistics, apply scope filters then aggregate before
  the output limit; never limit source rows first. An output limit can truncate
  groups, so report or recover missing groups rather than claiming complete totals.
- Timestamps are UTC. Say which you are showing.
- Decode the MCP tool's returned content or structured result. If its table has
  `columns` and `values`, map by position; do not assume a raw HTTP response shape.
- Check for tool errors, partial results, and truncation before drawing
  conclusions. If a limit is reached, narrow or split the time window and use
  counts to establish coverage; do not claim the entire trace was returned.
- A stringified payload blob is searched with `LIKE "*\"Key\"*"`, and is usually
  truncated, so absence of a value inside it is not evidence.

## 9. Reporting

Answer the question asked. Show the smallest set of rows that supports it, name
the window and the stream you searched, and say plainly when you found nothing so
it is not mistaken for a clean result.

Never paste whole payloads. Quote the field that matters.

Values arriving as a run of asterisks are masked at the source. No query reveals
them.

If `logs.notes` names a pack document, read it when a field or a level is not
self-explanatory. That is where a non-standard platform's own vocabulary lives.
