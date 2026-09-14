#!/bin/zsh
# Inspect selected GitHub Actions jobs without assuming an organization or pipeline.
set -euo pipefail
setopt extendedglob
if (( $# < 3 || $# > 4 )); then
  print -u2 'Usage: get-deploy-status <owner/repo[,owner/repo]> <workflow> <job-name-substring> [limit=10]'
  exit 2
fi
repos=$1
workflow=$2
job_filter=$3
run_limit=${4:-10}
[[ -n "$workflow" && -n "$job_filter" && "$run_limit" == <1-100> ]] || {
  print -u2 'Workflow and job filter are required; limit must be 1-100.'; exit 2
}
command -v gh >/dev/null
command -v jq >/dev/null
repo_list=("${(@s:,:)repos}")
for repo in "${repo_list[@]}"; do
  [[ "$repo" == [A-Za-z0-9_.-]##/[A-Za-z0-9_.-]## ]] || {
    print -u2 'Each repository must be an explicit owner/repo.'; exit 2
  }
done
failed=0
for repo in "${repo_list[@]}"; do
  print -r -- "Repository: $repo; workflow: $workflow; job contains: $job_filter"
  if ! runs=$(gh run list --repo "$repo" --workflow "$workflow" --limit "$run_limit" --json databaseId,url,status,conclusion); then
    print -u2 -- "Could not read runs for $repo."; failed=1; continue
  fi
  if ! ids=$(printf '%s' "$runs" | jq -er 'if type == "array" then map(.databaseId | tostring) | join("\n") else error("Expected runs array") end'); then
    print -u2 'Invalid workflow response.'; failed=1; continue
  fi
  if [[ -z "$ids" ]]; then
    print 'No matching runs in this query.'; continue
  fi
  for run_id in "${(@f)ids}"; do
    if ! jobs=$(gh run view "$run_id" --repo "$repo" --json url,jobs); then
      print -u2 -- "Could not read jobs for run $run_id."; failed=1; continue
    fi
    printf '%s' "$jobs" | jq --arg match "$job_filter" '{url, jobs: [.jobs[] | select(.name | contains($match)) | {name,status,conclusion,completedAt}]}'
  done
done
print 'Results describe workflow jobs, not live application health. Empty job lists mean no name matched.'
exit "$failed"
