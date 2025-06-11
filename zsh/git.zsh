#! /bin/zsh

if (( $+commands[gitleaks] )); then
  eval "$(gitleaks completion zsh)"
fi

if alias gr > /dev/null; then unalias gr; fi
# if alias gk > /dev/null; then unalias gk; fi

function clean-git-branches() {
  $DOTFILES/git/clean-git-branches
}

function groq_repos() {
  local github_org="groq"

  local page=1 # 1-based pages :(
  local repos=""

  while true; do
    local page_repos=$(gh api /orgs/${github_org}/repos \
      -X GET \
      -f per_page=100 \
      -f page=${page} \
    | jq -r '.[] | select(.archived == false) | .name')

    [[ -z "${page_repos}" ]] && break

    repos="${repos}\n${page_repos}"
    let "page+=1"
  done

  echo "${repos}"
}

function groq_archived_repos() {
  local github_org="groq"

  local page=1 # 1-based pages :(
  local repos=""

  while true; do
    local page_repos=$(gh api /orgs/${github_org}/repos \
      -X GET \
      -f per_page=100 \
      -f page=${page} \
    | jq -r '.[] | select(.archived == true) | .name')

    [[ -z "${page_repos}" ]] && break

    repos="${repos}\n${page_repos}"
    let "page+=1"
  done

  echo "${repos}"
}

function clone-all-repos() {
  local github_org="groq"

  pushd ~/dev > /dev/null

  for repo in $(groq_repos); do
    if [[ ! -d "${repo}" ]]; then
      git clone "git@github.com:${github_org}/${repo}.git"
    fi
  done

  popd > /dev/null
}

function update-repo() {
  local repo=$1
  local repo_dir="$HOME/dev"

  pushd ${repo_dir}/${repo} > /dev/null
  echo "Updating ${repo}"
  git up
  popd > /dev/null
}

function update-all-repos() {
  local repo_dir="$HOME/dev"
  # Run update-repo in the background for each repository
  for repo in $(ls ${repo_dir}); do
    if [[ -d "${repo_dir}/${repo}" ]]; then
      echo "Updating ${repo}"
      (update-repo "${repo}") &
    fi
  done
  # Wait for all background jobs to finish
  wait
}

function prune-repos() {
  local github_org="groq"

  pushd ~/dev > /dev/null

  for repo in $(groq_archived_repos); do
    if [[ -d "${repo}" ]]; then
      echo "Deleting ${repo}"
      rm -rf "${repo}"
    fi
  done

  popd > /dev/null
}

function gr {
    local flags=(
        --slack
        --update-mr
        --ci-start
    )
    local extras=()
    case $1 in
    # push) extras=(--label ReleaseUpdate::NotRequired --ci-start);;
    push) extras=(--ci-start);;
    mr-get) extras=(--format=short)
    esac
    SFT_AUTH_SOCK= command gr $flags $extras "$@"
}
