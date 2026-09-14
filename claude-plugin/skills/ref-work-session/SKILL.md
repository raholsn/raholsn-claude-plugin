---
name: ref-work-session
description: Create a unique external work-session directory or verify an explicit resume, preserving task and repository identity.
user-invocable: false
disable-model-invocation: false
---

# Work Session

Create a unique session outside checkouts, or explicitly resume an existing one.
This reference manages local artifacts only.

## Caller contract

| Input | Purpose |
|---|---|
| `artifacts_root` | Configured external artifact directory |
| `repo_path` | Absolute selected repository path |
| `task_description` | User request, written as literal text |
| `resume_dir` | Optional explicit existing session to resume |

## Process

1. Expand and validate `artifacts_root`. It must be writable and outside the
   implementation checkout. Report invalid configuration before creating files.
2. For a new invocation, create a unique directory under that root using a
   repository slug and collision-resistant run suffix. Do not derive ownership
   from branch name alone. Return the exact absolute path as `$WORK_DIR`.
3. Write `.repo` with the absolute repository identity, `.task` with the request,
   and `session.md` with mode, source, checkout, branch/base/remote/HEAD when known,
   current phase, delivery scope and pending actions. The branch may be unresolved
   until preparation completes. Use structured file writes or safe literal input,
   never interpolate descriptions or paths into executable shell code.
4. For `resume_dir`, read markers before writing anything. Verify the repository
   and selected task match, allowing an explicitly recorded isolated checkout.
   Preserve existing artifacts. Return a mismatch to the caller instead of
   overwriting it. Legacy markers with only a basename need additional evidence.
5. The caller updates `session.md` as branch, scope, phase and delivery facts
   change. If `$WORK_DIR` is lost, recover the recorded exact path, not whichever
   directory happens to share the current branch name. Never infer completed
   work from directory or marker existence alone.

## Result

Return `$WORK_DIR`, `session.md` and new/resume status. All delegated artifact
paths live in this session. Do not commit these files into the implementation
repository or recreate them inside an isolated checkout.
