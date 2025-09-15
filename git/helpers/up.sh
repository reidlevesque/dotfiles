#! /bin/bash
set -eo pipefail

debug="false"
if [[ "${1:-}" == "-d" ]]; then
  debug="true"
fi

timer() {
  local cmd="$1"
  local desc="$2"
  if [[ "$debug" == "true" ]]; then
    echo -n "${desc}..." >&2
    start_time=$(gdate +%s.%N)
  else
    echo "${desc}..." >&2
  fi

  eval "$cmd"

  if [[ "$debug" == "true" ]]; then
    end_time=$(gdate +%s.%N)
    duration_ms=$(bc -l <<< "($end_time - $start_time)/1")
    printf " took %.3fs\n" "$duration_ms" >&2
  fi
}

declare -a branches=(
  "dev"
  "main"
  "prod"
  "head"
  "production"
)

is_worktree=$(git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ "$(git rev-parse --git-common-dir)" != "$(git rev-parse --git-dir)" ] && echo "true" || echo "false")
if [[ "$is_worktree" == "true" ]]; then
  timer "git pull --prune" "Pulling latest changes"
  timer "git fetch --tags --force" "Fetching latest tags"
  exit 0
fi

# In main repo - do full update
current_branch=$(timer "git branch --show-current" "Getting current branch")
default_branch=$(timer "cat $(git rev-parse --git-dir)/refs/remotes/origin/HEAD | sed 's#.*origin/##'" "Getting default branch")
if [[ -z "${default_branch}" ]]; then
  default_branch=$(timer "git remote show origin | sed -n '/HEAD branch/s/.*: //p'" "Getting default branch")
fi

timer "git checkout ${default_branch}" "Switching to default branch"
timer "git pull --prune" "Pulling latest changes"
timer "git fetch --tags --force" "Fetching latest tags"

echo "Cleaning up deleted branches and their worktrees..."
branches_to_delete=$(git branch -vv | grep 'origin/.*: gone]' || true)
if [ -n "${branches_to_delete}" ]; then
  for branch in $(echo "${branches_to_delete}" | awk '{gsub(/^[*+][ ]*/, ""); print $1}'); do
    # Remove worktree if it exists for this branch
    worktree_path=$(git worktree list --porcelain | awk '/^worktree / {path=$0; gsub("^worktree ", "", path)} /^branch refs\/heads\/'"${branch//\//\\/}"'$/ {print path; found=1} /^$/ {if(found) exit; path=""; found=0}' || true)
    if [ -n "${worktree_path}" ]; then
      timer "git worktree remove '${worktree_path}' --force" "Removing worktree: ${worktree_path}"
    fi
    timer "git branch -D '${branch}'" "Removing branch: ${branch}"
  done
fi

echo "Updating local branches..."
for branch in "${branches[@]}"; do
  if git show-ref --verify --quiet "refs/heads/origin/${branch}"; then
    timer "git checkout ${branch} && git reset --hard origin/${branch}" "Updating branch: ${branch}"
  fi
done

timer "git checkout ${current_branch}" "Returning to original branch" || timer "git checkout ${default_branch}" "Falling back to default branch"
