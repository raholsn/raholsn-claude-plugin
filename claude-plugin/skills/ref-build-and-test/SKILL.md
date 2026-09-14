---
name: ref-build-and-test
description: Run pre-test setup, the configured build, affected tests by default, and post-test cleanup. Commands come from the profile, never from this file. Internal sub-skill.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Build & Test

Internal sub-skill. Builds and runs affected tests using the profile's `build`
block plus any repo-specific setup and cleanup.

**Requires** the caller has already read the preflight artifact.

## Caller contract

| Input | Default | Notes |
|---|---|---|
| `affected_only` | `true` | When `false`, run the full suite after affected tests pass |
| `build` | the profile's `build` block | `build_cmd`, `test_cmd`, `test_filter_template`, `full_suite_cmd`, `workspace_glob`, `pre_test_setup`, `post_test_cleanup` |
| `repo` | current repo name | Substituted into `{repo}` in setup and cleanup |

Resolve build, affected-test and full-suite commands independently from the
effective profile and explicit repository guidance. A missing build command
skips only the build, not configured tests. Do not invent commands or filtering
syntax from project filenames. Record missing required commands as validation
limitations for the caller to resolve, never as passing checks.

## Process

1. **Prepare.** Record the selected commands, working directory and affected
   behavior. If no relevant validation command is available, report that fact
   without running setup solely for a nonexistent check. Preserve the initial
   working-tree state so cleanup cannot remove unrelated work.

2. **Pre-test setup.** Before the selected checks, run `pre_test_setup` with
   `{repo}` substituted and setup explicitly required by repository guidance.
   Avoid running the same setup twice. If setup fails, skip dependent checks,
   record the failure and still attempt required cleanup for partial setup.

3. **Build.** Run `build_cmd` when configured, from its documented directory.
   Respect configured scope rather than silently retargeting the command.
   Record an absent build as skipped and continue with independently runnable
   tests. A build failure blocks dependent tests until corrected.

4. **Affected tests.** Run `test_cmd` when configured and applicable. Use
   `test_filter_template` only when the affected test mapping and substitution
   are known. Otherwise run the configured unfiltered command, or a narrower
   command explicitly supplied by repository guidance. If tests require a build
   and none is available, record the unmet prerequisite rather than claim a pass.
   If no tests apply, explain the affected behavior and why coverage is unnecessary.

5. **Full suite.** When `affected_only` is false or guidance requires it, run
   `full_suite_cmd` after its prerequisites pass. A missing affected-test command
   does not suppress an independently runnable full suite. If the configured
   `test_cmd` already ran the same full suite, reuse that result. A required but
   unavailable suite is a limitation, not an optional skip.

6. **Cleanup on every exit.** Once setup or checks begin, attempt configured
   `post_test_cleanup` and required repository cleanup even after setup, build or
   test failure. Preserve both the original failure and any cleanup failure.
   Verify setup changes were restored and unrelated user changes were preserved.
   Do not reset or delete unrelated files to obtain a clean working tree.

Save noisy output under `$WORK_DIR/validation/`, using separate build/test logs.
Report commands, exit outcomes, relevant errors and skipped checks with reasons.
After a fix, rerun affected checks. Follow the caller's bounded failure policy;
stop on repeated failure with the evidence and remaining blocker.

## Done

Report each check as passed, failed, skipped or blocked, plus cleanup status.
Success means all required checks ran successfully and required cleanup completed.
The caller decides whether delivery with an explicitly reported validation
limitation is authorized. Missing commands and unavailable checks are never
reported as successful validation.
