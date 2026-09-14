# Local script commands

## When to use

| Ask naturally | Command |
|---|---|
| “Did these services deploy?” | `/raholsn:get-deploy-status` |
| “Open the PR page for this branch.” | `/raholsn:show-pullrequests` |
| “Open this solution.” | `/raholsn:open-solution` |
| “Open Argo for this service.” | `/raholsn:open-argo` |

These commands support explicit and natural-language invocation. Discussing or
reviewing a script does not request execution. Missing targets are clarified.

## Motivation

The wrappers translate intent into a bundled script's arguments and working
directory. Repository ownership comes from explicit input or Git remotes, and
deployment targets come from the selected environment's configuration.
No previous employer's organization, URLs or naming conventions are built in.

## Bundled scripts and prerequisites

Each skill directly invokes its matching script with zsh. No shell alias,
profile bootstrap or shared wrapper reference is required.

| Script | Prerequisites |
|---|---|
| [get-deploy-status.sh](../claude-plugin/tools/get-deploy-status.sh) | Authenticated GitHub CLI and jq |
| [show-pullrequests.sh](../claude-plugin/tools/show-pullrequests.sh) | Git, Python 3.9+, `open` or `xdg-open` |
| [open-argo.sh](../claude-plugin/tools/open-argo.sh) | Python 3, `open` or `xdg-open` |
| [open-solution.sh](../claude-plugin/tools/open-solution.sh) | Git/find and macOS `open`, as used by the existing solution helper |

## Arguments and behavior

### Deployment status

```text
get-deploy-status "example-org/service-a,example-org/service-b" deploy.yml "Release production" 10
```

Supply complete `owner/repo` identifiers, the actual workflow name/file, and a
substring matching the intended deployment job names. The run limit defaults to
10 and must be 1–100. The skill can inspect repository workflows to identify
these inputs, but asks when their meaning is ambiguous. There is no default
organization, workflow or production job.

All matching jobs in the selected recent runs are reported with their status,
conclusion and links. Empty results and failed reads remain distinct; partial
read failures return a nonzero exit status. This reads GitHub Actions state and
does not trigger a deployment or verify live application health. See the
[GitHub CLI run-view reference](https://cli.github.com/manual/gh_run_view).

### PR page

```text
show-pullrequests upstream
```

The optional remote defaults to `origin`. The script reads the remote URL and
current branch; it does not infer ownership or project names from the local
folder. GitHub.com HTTPS/SSH and Azure DevOps HTTPS/SSH remotes are supported,
including legacy `visualstudio.com` HTTPS URLs. Unsupported hosts/formats and
detached HEAD fail without opening a page.

For GitHub it opens the current branch's compare page in the selected remote.
For Azure DevOps it opens that repository's PR page. It does not create a PR or
list PR data in chat. For forks, choose the intended remote explicitly.

### Argo CD

```text
open-argo --url https://argocd.example.com --namespace delivery --application service-a
```

`ARGOCD_URL` and `ARGOCD_NAMESPACE` can supply defaults when the corresponding
flags are absent. The application name is always explicit. The namespace is
where the Argo CD Application resource lives, not its workload destination.
The skill resolves the requested environment from supplied configuration or asks;
it never assumes production or transforms a repository prefix into an app name.

The script opens `/applications/<namespace>/<application>` under the configured
base URL. This is browser navigation only; it does not authenticate, sync or
deploy. The old area/stage shortcut flags are no longer supported.

### Solution

`open-solution [path-or-pattern] [depth]` retains the existing behavior: depth
3 by default, `.slnx` preferred over `.sln`, and the OS-associated application.
Ambiguous matches require selection. It does not build or switch IDEs.

## Results and validation

The response identifies the target, opened URL or job results, and failures.
Opening a browser page does not prove an application exists, a deployment
succeeded or a PR was created.

Local fixture tests exercise organization-independent remote parsing, URL
encoding, required configuration, job selection and partial read failures with
mocked GitHub/browser commands. They do not contact providers or validate live
account permissions. Run them with `python3 -m unittest discover -s tests`.
