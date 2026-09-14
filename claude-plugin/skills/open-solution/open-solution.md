---
name: open-solution
description: "Open a .NET solution. Use when the user says open solution, open this solution, or open the solution for a repository."
user-invocable: true
disable-model-invocation: false
argument-hint: "[solution path or pattern] [depth]"
---

# open-solution

Request: $ARGUMENTS

Run `zsh "${CLAUDE_PLUGIN_ROOT}/tools/open-solution.sh"` in the requested
repository, or the current repository when none is specified.

Pass the requested solution path/pattern and optional depth as separate quoted
arguments. With no arguments, let the script find the solution. If it reports
multiple matches, ask which one and rerun with that path. The script opens the
OS-associated application. Report the opened solution or error.
