---
name: ref-git-preflight
description: Inspect repository, base and task-branch readiness while preserving existing work. Supports new isolated work and resumed tasks.
user-invocable: false
disable-model-invocation: false
---

# Git Preflight

Inspect repository readiness without changing the user's checkout. Branch and
worktree creation belong to the calling workflow after this report.

## Caller contract

| Input | Default / purpose |
|---|---|
| `repo_path` | Explicit target checkout, otherwise current working directory |
| `base_branch` | Explicit caller value, then configured VCS base, then verified remote HEAD |
| `base_remote` | Configured base remote, or unambiguous repository remote |
| `task_branch` | Optional known branch for resuming the selected task |

## Process

1. Verify repository identity and record absolute root, current branch/HEAD,
   staged, unstaged and untracked changes, worktrees and relevant remotes. Inspect
   enough to distinguish existing task work from unrelated changes. Never stash,
   reset, clean, discard, commit or switch branches in this inspection.
2. Resolve the base branch and its remote explicitly. Do not assume `origin` or
   override a supplied base with remote HEAD. Report ambiguous remotes. Fetch
   the selected base when available, recording its commit. If fetching fails,
   distinguish the known local reference from an unverified current remote tip.
3. For new work, recommend a branch from the resolved base. A dirty checkout or
   unrelated feature branch normally calls for an isolated worktree, not asking
   the user to discard changes. For resume, verify the task branch identity,
   commits and relation to its base. Do not demand a switch to the base branch.
4. Record existing branch/remote collisions, concurrent movement and unmet
   prerequisites. A behind base is information to assess, not permission to
   rewrite task history. Never force-push as a preflight repair.

## Result

Return repository/base identities and commits, checkout state, recommended
new-work or resume path, and blockers or limitations. A dirty original checkout
can coexist with a ready isolated worktree. The caller owns any necessary
clarification and subsequent mutations.
