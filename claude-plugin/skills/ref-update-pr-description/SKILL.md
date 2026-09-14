---
name: ref-update-pr-description
description: Fill the PR description's Changes, Validation and Risks sections from what was actually done, using the configured host CLI. Internal sub-skill.
user-invocable: false
disable-model-invocation: false
---

Supporting context for other commands. Load this skill only when another
command or its workflow explicitly references it. It is not a user command.
Do not select it independently merely because a general task matches its subject.

# Update PR Description

Internal sub-skill. Updates the body of the current branch's PR to reflect the
work that was actually performed.

## Caller contract

| Input | Default | Notes |
|---|---|---|
| `cli` | the profile's `vcs.cli`, else `gh` | The host CLI |
| `template` | the repo's PR template when present, else the default below | |

## 1. Pick the body

If the repo has a pull request template, read it and fill it in **verbatim**. Do
not paraphrase or reformat a house template; reviewers and automation key off its
headings.

Otherwise use:

```markdown
## Changes
<what changed and why; bullets are fine>

## Validation
<how it was verified: which tests ran, which build, what manual checking>

## Risks / Notes
<risks, side effects, deployment considerations, or "None">
```

## 2. Write it

Edit the PR body through `cli`, passing the composed markdown. Use the syntax
that `cli` documents for editing a pull request body. Pass the body through a
quoted heredoc so backticks and `$` in the text survive.

## 3. Accuracy rules

- Fill every section from the actual diff and the workflow's own notes.
- Do **not** invent validation that did not happen. If the build was skipped
  because no build command is configured, write that.
- Do not gloss over real risks. A migration, a contract change or a config change
  belongs under Risks even when it is routine.

## Done

The PR body reflects reality. Confirm by reading it back through `cli`.
