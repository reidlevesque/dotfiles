#!/bin/bash
set -eo pipefail

# Thin wrapper around git worktree with enhanced add functionality

print_help() {
    cat <<'EOF'
Usage:
  git wt add <branch>
  git wt rm
  git wt [git-worktree-args...]

Thin wrapper around `git worktree` with two custom commands:

Commands:
  add <branch>   Create a sibling worktree at ../<repo>_<branch>.
                 This stashes local changes, runs `git up`, checks out the
                 default branch in the main repo, and then creates or reuses
                 the requested branch in the new worktree.
  rm             Interactively select and remove a non-primary worktree with `fzf`.
  help           Show this message.

Passthrough:
  Any other arguments are forwarded directly to `git worktree`.

Examples:
  git wt add feature/my-branch
  git wt rm
  git wt list
  git wt lock ../repo_feature-my-branch

More help:
  git wt add --help
  git wt rm --help
EOF
}

print_add_help() {
    cat <<'EOF'
Usage:
  git wt add <branch>

Creates a sibling worktree directory named:
  ../<repo>_<branch>

Behavior:
  - Stashes local tracked changes in the current worktree, if needed
  - Runs `git up`
  - Checks out the repository default branch in the main worktree
  - Creates the new worktree using one of these rules:
    * existing local branch: use it as-is
    * existing origin branch: create a local tracking branch
    * otherwise: create a new local branch
  - Checks the main worktree back out to the original branch

Note:
  Slashes in <branch> are replaced with dashes in the worktree directory name.
EOF
}

print_rm_help() {
    cat <<'EOF'
Usage:
  git wt rm

Interactively removes a non-primary worktree.

Behavior:
  - Lists all worktrees except the main repository checkout
  - Uses `fzf` to choose one
  - Runs `git worktree remove` on the selected path

Requirement:
  `fzf` must be installed and available on PATH.
EOF
}

case "${1:-}" in
    "" )
        exec git worktree
        ;;
    help|-h|--help)
        print_help
        ;;
    add)
        if [[ "${2:-}" == "help" || "${2:-}" == "-h" || "${2:-}" == "--help" ]]; then
            print_add_help
            exit 0
        fi

        if [[ $# -ne 2 ]]; then
            echo "Error: git wt add expects exactly one branch name" >&2
            echo >&2
            print_add_help >&2
            exit 1
        fi

        branch_name="$2"

        # Remember the current branch to checkout later
        current_branch=$(git branch --show-current)

        # Get repo name and sanitize branch name for directory
        repo_name=$(basename "$(git rev-parse --show-toplevel)")
        sanitized_branch=$(echo "$branch_name" | sed 's/\//-/g')
        worktree_dir="../${repo_name}_${sanitized_branch}"

        echo "Setting up worktree for branch: $branch_name"

        # 1. Stash any local changes
        if ! git diff-index --quiet HEAD --; then
            echo "Stashing local changes..."
            git stash push -m "Auto-stash before worktree add $branch_name"
        fi

        # 2. Run git up
        echo "Running git up..."
        "$(dirname "$0")/up.sh"

        # 3. Get default branch and checkout
        default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)
        if [[ -z "$default_branch" ]]; then
            default_branch="main"
        fi
        echo "Checking out default branch: $default_branch"
        git checkout "$default_branch"

        # 4. Create worktree - let git worktree handle branch existence logic
        echo "Creating worktree for $branch_name..."
        if git show-ref --verify --quiet "refs/heads/$branch_name"; then
            # Branch exists locally, use it
            git worktree add "$worktree_dir" "$branch_name"
        elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
            # Branch exists on remote, create tracking branch
            git worktree add "$worktree_dir" -b "$branch_name" "origin/$branch_name"
        else
            # New branch, create it
            git worktree add "$worktree_dir" -b "$branch_name"
        fi

        echo "Worktree created at $worktree_dir"

        # 5. Return to the original branch
        if [[ -n "$current_branch" ]]; then
            echo "Returning to original branch: $current_branch"
            git checkout "$current_branch"
        fi

        echo "run 'dev ${repo_name}_${sanitized_branch}' to open the worktree in VS Code"
        ;;
    rm)
        if [[ "${2:-}" == "help" || "${2:-}" == "-h" || "${2:-}" == "--help" ]]; then
            print_rm_help
            exit 0
        fi

        if [[ $# -ne 1 ]]; then
            echo "Error: git wt rm does not accept additional arguments" >&2
            echo >&2
            print_rm_help >&2
            exit 1
        fi

        # Interactive worktree removal with fzf
        if ! command -v fzf >/dev/null 2>&1; then
            echo "Error: fzf is required for interactive worktree removal" >&2
            exit 1
        fi

        # Get list of worktrees (excluding the main one)
        main_worktree=$(git rev-parse --show-toplevel)
        worktrees=$(git worktree list --porcelain | grep -E '^worktree ' | sed 's/^worktree //' | grep -v "^${main_worktree}$")

        if [[ -z "$worktrees" ]]; then
            echo "No additional worktrees found"
            exit 0
        fi

        # Let user select worktree to remove
        selected=$(echo "$worktrees" | fzf --prompt="Select worktree to remove: " --height=40%)

        if [[ -n "$selected" ]]; then
            echo "Removing worktree: $selected"
            git worktree remove "$selected"
            echo "Worktree removed successfully"
        else
            echo "No worktree selected"
        fi
        ;;
    *)
        # Pass through all other commands to git worktree
        exec git worktree "$@"
        ;;
esac
