---
name: show-pullrequests
description: "Open the pull-request page in the browser. Use when the user says open pull requests, show the PR page, or open the PR page for this branch."
user-invocable: true
disable-model-invocation: false
argument-hint: "[repository directory] [remote]"
---

# show-pullrequests

Request: $ARGUMENTS

Run `zsh "${CLAUDE_PLUGIN_ROOT}/tools/show-pullrequests.sh"` with an optional
remote name (default `origin`) in the requested repository, or the current
repository. The remote supplies the host, owner, project and repository; the local
folder name is irrelevant. For forks, use the explicitly selected remote and
report its target. Ask if the intended remote is ambiguous.

Requires Git, Python 3 and an OS browser opener. The script opens the current branch's GitHub compare page or Azure DevOps PR
page. Report the opened URL or error. This opens a page; it does not list PRs in
chat or submit a new PR.
