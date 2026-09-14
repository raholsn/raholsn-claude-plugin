---
name: ref-create-branch-and-pr
description: Create a feature branch and an optionally-draft PR in one step. Uses a configured helper or the bundled GitHub script, with a host CLI fallback for other providers. Internal sub-skill.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Create Branch & PR

Internal sub-skill. Opens the branch and the PR the workflow will commit into.

## Caller contract

| Input | Default | Notes |
|---|---|---|
| `ticket` | empty | May be empty on a ticketless run |
| `description` | none | Short subject, used for the branch slug and the PR title |
| `base_branch` | the profile's `vcs.base_branch` | |
| `branch_template` | the profile's `vcs.branch_template`, else `{ticket}` | Falls back to a description slug when `ticket` is empty |
| `pr_title_template` | the profile's `vcs.pr_title_template` | |
| `draft` | the profile's `vcs.draft_prs`, else `true` | |
| `helper` | the profile's `vcs.branch_helper` | Optional |
| `cli` | the profile's `vcs.cli`, else `gh` | The host CLI |
| `allow_empty_commit` | `false` | Enable only when the user or repository guidance authorizes an initial empty commit |

## 1. Compute the names

Substitute `{ticket}` and `{description}` into the templates. When `ticket` is
empty, drop the ticket segment and any separator it leaves behind, then slugify
the description: lowercase, non-alphanumerics to hyphens, collapse repeats, trim
to a reasonable length.

Print the branch name and PR title before creating anything.

## 2. Pick the path

Run `command -v <helper>` when a helper is configured.

- **Found**: use it. This is preferred, because a house helper usually applies
  conventions the profile does not capture.
- **Not configured or not found, and `cli` is `gh`**: use the bundled script.
- **Other host CLI**: use the fallback.

## 3a. Helper path

```bash
<helper> <ticket> "<description>"
```

If it fails, for instance because the branch exists, surface the error and ask
the user how to proceed. Do not fall through to the generic path silently: the
helper failing usually means the branch is already there.

## 3b. Bundled GitHub script

The plugin includes `tools/create-branch-and-pr.sh`, adapted from the original
local helper. It requires Bash, git, and authenticated `gh`; no shell alias or
external script installation is needed.

Pass the names computed in step 1 as quoted arguments:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/tools/create-branch-and-pr.sh" \
  --branch "<branch>" --title "<pr-title>" --base "<base-branch>"
```

Add `--ready` when `draft` is false. Omit `--base` if unconfigured to resolve
the base from `origin/HEAD`. Optional `--repo`, `--remote`, and `--body-file`
arguments select the repository, remote, or PR body. Otherwise the script
discovers a repository PR template and falls back to a generic body.

Like the original helper, opening a PR before implementation needs an initial
commit. Pass `--allow-empty-commit` only when `allow_empty_commit` is authorized.
Without it the script stops before creating a branch or pushing. If not
authorized, defer PR creation until an implementation commit exists and use
the host CLI then. Never retry with the flag merely to bypass the refusal.

The script requires a clean working tree, rejects existing local or remote
feature branches, and branches from the fetched base without updating the
local base branch. If PR creation fails after pushing, retain the branch and
retry only PR creation after resolving the error.

## 3c. Fallback path

Assumes `git` and the host CLI are installed, which the caller verified.

```bash
git checkout -b <branch>
git push -u origin <branch>
```

Then open the PR with `cli`, passing the base branch, the computed title, an
empty body, and the draft flag when `draft` is true. The engine does not hardcode
one host's flag syntax. Use the syntax that `cli` documents.

If PR creation fails because the branch has no commits yet, tell the user to make
an initial commit, then re-run. Do not create an empty commit on your own.

## Done

The branch exists locally and on the remote, and a PR is open against
`base_branch`. The caller can now fetch the PR URL through `cli`.
