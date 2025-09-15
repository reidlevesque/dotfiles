#!/bin/bash
set -eo pipefail

# Thin wrapper around git worktree with enhanced add functionality

if [[ "$1" == "add" ]] && [[ $# -ge 2 ]]; then
    if [[ $# -gt 2 ]]; then
        echo "Error: wt.sh add only accepts one branch name argument" >&2
        echo "Usage: wt.sh add <branch>" >&2
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
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
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
elif [[ "$1" == "rm" ]]; then
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
else
    # Pass through all other commands to git worktree
    exec git worktree "$@"
fi
