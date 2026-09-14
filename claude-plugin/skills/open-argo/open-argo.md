---
name: open-argo
description: "Open an Argo CD application in the browser using the selected deployment's URL, namespace and exact application name."
user-invocable: true
disable-model-invocation: false
argument-hint: "--url <base-url> --namespace <namespace> --application <name>"
---

# open-argo

Request: $ARGUMENTS

Run `zsh "${CLAUDE_PLUGIN_ROOT}/tools/open-argo.sh"` with `--url`, `--namespace`
and `--application` as separate quoted arguments. `ARGOCD_URL` and
`ARGOCD_NAMESPACE` may supply connection defaults when explicit values are absent.

Resolve the requested environment and exact application from explicit input,
applicable repository guidance or deployment manifests. Ask for missing or
ambiguous values. Do not derive application names by stripping repository prefixes
or assume production. Show the target before opening it. The script opens a page;
it does not authenticate, sync or deploy anything.
