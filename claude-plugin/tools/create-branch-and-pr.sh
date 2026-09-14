#!/usr/bin/env bash
# GitHub branch and pull-request helper with explicit repository inputs.
# GitHub adapter. Company conventions are supplied by the caller.
set -euo pipefail

usage() {
    printf '%s\n' 'Usage: bash create-branch-and-pr.sh --branch NAME --title TITLE [options]
  --base NAME             Base branch (default: origin/HEAD)
  --remote NAME           Git remote (default: origin)
  --repo PATH             Working repository (default: current directory)
  --ready                 Create a ready PR (default: draft)
  --body-file PATH        Use this PR body instead of repository template discovery
  --allow-empty-commit    Explicitly allow an initial empty commit
  --help                  Show help'
}
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

branch=''
title=''
base=''
remote='origin'
repo='.'
body_file=''
draft=true
allow_empty=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) usage; exit 0 ;;
        --ready) draft=false; shift ;;
        --allow-empty-commit) allow_empty=true; shift ;;
        --branch|--title|--base|--remote|--repo|--body-file)
            [[ $# -ge 2 && -n "$2" ]] || fail "Missing value for $1"
            case "$1" in
                --branch) branch="$2" ;;
                --title) title="$2" ;;
                --base) base="$2" ;;
                --remote) remote="$2" ;;
                --repo) repo="$2" ;;
                --body-file) body_file="$2" ;;
            esac
            shift 2 ;;
        *) fail "Unknown argument: $1" ;;
    esac
done
[[ -n "$branch" && -n "$title" ]] || { usage >&2; exit 1; }
command -v git >/dev/null || fail 'git is required'
command -v gh >/dev/null || fail 'GitHub CLI (gh) is required'
repo=$(git -C "$repo" rev-parse --show-toplevel) || fail 'Not a Git repository'
[[ -z "$(git -C "$repo" status --porcelain)" ]] || fail 'Working tree must be clean'
[[ "$remote" != -* ]] || fail 'Invalid remote'
git -C "$repo" remote get-url "$remote" >/dev/null
if [[ -z "$base" ]]; then
    base=$(git -C "$repo" symbolic-ref --quiet --short "refs/remotes/$remote/HEAD") ||
        fail 'Cannot resolve remote default branch; pass --base'
    base="${base#"$remote/"}"
fi
[[ "$base" != -* && "$branch" != -* ]] || fail 'Invalid branch name'
git check-ref-format "refs/heads/$base" >/dev/null || fail 'Invalid base branch'
git check-ref-format "refs/heads/$branch" >/dev/null || fail 'Invalid feature branch'
[[ "$branch" != "$base" ]] || fail 'Feature branch must differ from base'
if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
    fail "Local branch already exists: $branch"
fi
remote_branch=$(git -C "$repo" ls-remote --heads "$remote" "refs/heads/$branch")
[[ -z "$remote_branch" ]] || fail "Remote branch already exists: $branch"
[[ -z "$body_file" || -f "$body_file" ]] || fail "Body file does not exist: $body_file"

find_pr_template() {
    local git_root="$1"
    local candidate
    local template_dir

    local template_file_dirs=(
        "$git_root/.github"
        "$git_root/docs"
        "$git_root"
    )

    for template_dir in "${template_file_dirs[@]}"; do
        if [[ -d "$template_dir" ]]; then
            candidate=$(find "$template_dir" -maxdepth 1 -iname "pull_request_template.md" -type f 2>/dev/null | sort | head -1)
            if [[ -n "$candidate" ]]; then
                echo "$candidate"
                return 0
            fi
        fi
    done

    for template_dir in "${template_file_dirs[@]}"; do
        if [[ -d "$template_dir" ]]; then
            candidate=$(find "$template_dir" -maxdepth 1 -iname "pull_request_template*.md" -type f 2>/dev/null | sort | head -1)
            if [[ -n "$candidate" ]]; then
                echo "$candidate"
                return 0
            fi
        fi
    done

    local template_dirs=(
        "$git_root/.github/PULL_REQUEST_TEMPLATE"
        "$git_root/.github/pull_request_template"
        "$git_root/docs/PULL_REQUEST_TEMPLATE"
        "$git_root/docs/pull_request_template"
        "$git_root/PULL_REQUEST_TEMPLATE"
        "$git_root/pull_request_template"
    )

    for template_dir in "${template_dirs[@]}"; do
        if [[ -d "$template_dir" ]]; then
            candidate=$(find "$template_dir" -maxdepth 1 -iname "*.md" -type f 2>/dev/null | sort | head -1)
            if [[ -n "$candidate" ]]; then
                echo "$candidate"
                return 0
            fi
        fi
    done

    return 1
}

if [[ -z "$body_file" ]]; then
    body_file=$(find_pr_template "$repo" || true)
fi
# Resolve relative paths before changing to the target repo.
if [[ -n "$body_file" && "$body_file" != /* ]]; then
    body_file="$PWD/$body_file"
fi
[[ "$allow_empty" == true ]] ||
    fail 'A new branch needs a commit before opening a PR. Pass --allow-empty-commit to authorize a placeholder, or create the PR after implementation.'
printf 'Branch: %s\nPR title: %s\nBase: %s\n' "$branch" "$title" "$base"
git -C "$repo" fetch "$remote" "refs/heads/$base"
# Branch from the fetched base without changing or merging a local base branch.
git -C "$repo" checkout -b "$branch" FETCH_HEAD
git -C "$repo" commit --allow-empty -m "Initial empty commit for $branch"
git -C "$repo" push -u "$remote" "$branch"

pr_args=(pr create --title "$title" --head "$branch" --base "$base")
[[ "$draft" != true ]] || pr_args+=(--draft)
if [[ -n "$body_file" ]]; then
    pr_args+=(--body-file "$body_file")
else
    pr_args+=(--body '## Changes

<what changed>

## Validation

<how this was verified>

## Risks / Notes

<any impact, exceptions, or none>')
fi
# Pin the PR repository to the chosen remote, even when gh has another default.
remote_url=$(git -C "$repo" remote get-url "$remote")
pr_args+=(--repo "$remote_url")
cd "$repo"
gh "${pr_args[@]}" ||
    fail "PR creation failed; branch $branch remains pushed on $remote. Resolve the error and retry gh pr create."

