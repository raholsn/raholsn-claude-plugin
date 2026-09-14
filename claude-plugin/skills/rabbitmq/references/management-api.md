# RabbitMQ connection and API reference

## Profile contract

An optional `rabbitmq` block supplies deployment values. Example only:

```json
{
  "rabbitmq": {
    "default_environment": "sandbox",
    "environments": {
      "sandbox": {
        "management_url": "https://rabbitmq.example.com",
        "vhost": "/",
        "auth": {
          "type": "basic",
          "curl_config_file": "~/.config/rabbitmq/sandbox.auth.conf"
        },
        "dlq_name_regex": "[.]dead$",
        "notes": "knowledge/rabbitmq.md"
      }
    }
  }
}
```

Require `environments` to be a nonempty object; the selected environment must be
an object with nonempty `management_url`, `vhost`, `auth.type` and
`auth.curl_config_file` strings. `auth.type` is `basic` or `oauth2`.
`default_environment`, when present, must name an existing environment.
`management_url` is the management root (optionally a reverse-proxy prefix), not
an AMQP URL or `/api` endpoint. Reject embedded credentials, query strings and
fragments. Treat `REPLACE_WITH_*` values and example.com hosts (including their
subdomains) as unconfigured placeholders: stop before connecting and identify
the fields to fill. Require HTTPS except for a loopback endpoint used locally or through
an explicit tunnel; never disable TLS verification.

Optional `dlq_name_regex` is a valid regex used only as a candidate filter.
Optional `notes` is a pack-relative file path, resolved against `pack`; an
absolute or home-relative path is also supported. Resolve a relative auth-file
path against the profile directory and expand `~`. Validate only the selected
environment's connection prerequisites before querying. Report malformed values
with their dotted paths; do not substitute guessed targets.

Optional `port_forward` is an object with nonempty string `context`, `namespace`
and `resource` (for example `svc/rabbitmq`), and integer `local_port` and
`remote_port` in 1–65535. Require a loopback management URL matching `local_port`.
The company supplies these values; Kubernetes is not otherwise a dependency.

## Authentication

Use an existing, user-owned auth-only curl config with owner-only permissions
(0600 or equivalent). Check metadata without printing the file. It may contain
`user = "<username>:<password>"` for Basic authentication or an OAuth
`header = "Authorization: Bearer <access-token>"`, according to the deployment.
It must not contain URLs, redirects, output destinations or other request options.
Do not read secret contents into model context to validate it. Have the configured
credential tooling provision it; if its provenance is unknown, ask the user to
supply an auth-only file. Never commit this file or include it in reports.

OAuth acquisition is deployment-specific. Company notes supply the provider,
issuer/tenant, client ID, audience/scopes and approved credential helper or login
procedure. Reuse valid credentials for that identity and environment; do not
reuse a global token across brokers. If a documented device-code flow is used,
respect the provider's polling interval, slow-down response, expiry and denial;
stop on expiry/denial. Only the sign-in URL, user code and login instructions
belong in conversation, never access/refresh tokens or device-code secrets.
Use the company credential tool's protected cache rather than inventing one.

## Requests

Use curl and jq when installed. Variables below are resolved values, assigned
with shell quoting as data. Do not evaluate profile strings as shell code.
Disable shell tracing. Do not place expanded credentials in command arguments.

```bash
# RABBITMQ_BASE_URL, RABBITMQ_AUTH_FILE, RABBITMQ_VHOST and RABBITMQ_QUEUE
# are supplied from the resolved target; auth file contents are never printed.
RABBITMQ_VHOST_PATH=$(printf '%s' "$RABBITMQ_VHOST" | jq -sRr @uri)
RABBITMQ_QUEUE_PATH=$(printf '%s' "$RABBITMQ_QUEUE" | jq -sRr @uri)

rabbitmq_get() {
  curl -q --config "$RABBITMQ_AUTH_FILE" --silent --show-error --fail \
    --connect-timeout 5 --max-time 30 \
    --url "${RABBITMQ_BASE_URL%/}$1"
}
```

Use `pipefail` in the calling shell and check exit status before interpreting
JSON. Do not follow redirects with credentials. Do not print raw error bodies.
Encode each raw path segment once, including `/` as `%2F`; encode query values
independently. Check response shape and pagination metadata, not just HTTP 200.

| Purpose | Method and path |
|---|---|
| Identity/version | GET `/api/whoami`, `/api/overview` |
| Queue survey | GET `/api/queues/{vhost}?pagination=true&page=1&page_size=100&disable_stats=true&enable_queue_totals=true` |
| Queue state | GET `/api/queues/{vhost}/{queue}` |
| Queue bindings | GET `/api/queues/{vhost}/{queue}/bindings` |
| Policies | GET `/api/policies/{vhost}`, `/api/operator-policies/{vhost}` |
| Consumers | GET `/api/consumers/{vhost}` |
| Node state | GET `/api/nodes` |

For a survey, iterate all returned pages within the requested scope; default to
at most 20 pages before reporting partial coverage and proposing a narrower
filter or continuation. Filter the `items` array locally. Do not sum only the
displayed top rows as a total. Concurrent changes can shift pagination; label
surveys as non-atomic. Prefer selected-queue consumer details over a full vhost
consumer response. Large node/consumer responses also need local projection.

For direct queue state, project name, vhost, type, state, messages,
messages_ready, messages_unacknowledged, consumers, message_stats, arguments,
policy, operator_policy and effective_policy_definition. Missing fields remain
unknown. Use queue bindings and relevant source policies to trace DLX routing.

Only after the parent skill's inspection authorization, POST to
`/api/queues/{vhost}/{queue}/get`, using the same auth and timeout options,
`Content-Type: application/json`, and a JSON body such as:

```json
{"count":5,"ackmode":"ack_requeue_true","encoding":"auto","truncate":4096}
```

Validate count and truncate as positive bounded integers agreed for this sample.
Generate JSON with a JSON encoder, not string interpolation. Project the response
locally to approved fields before it reaches tool output. Never add automatic
retry to this operation or change its ack mode to obtain more messages.

## Primary references

Check the detected broker version's documentation when semantics differ:

- [HTTP API](https://www.rabbitmq.com/docs/http-api-reference)
- [Dead-lettering](https://www.rabbitmq.com/docs/dlx)
- [Quorum delivery and poison-message handling](https://www.rabbitmq.com/docs/quorum-queues)
- [OAuth authentication](https://www.rabbitmq.com/docs/oauth2)
