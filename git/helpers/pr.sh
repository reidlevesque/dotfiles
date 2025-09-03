#! /bin/bash
set -eo pipefail

commit_message="${1:-}"
commit_body="${2:-}"

# Validate conventional commit format
if [[ -n "$commit_message" ]] && [[ ! "$commit_message" =~ ^(feat|fix|chore|wip)(!)?:.+ ]]; then
    echo "Error: Commit message must follow conventional commit format (feat:, fix:, chore:, or wip:)" >&2
    echo "Example: git pr \"feat: add user authentication\"" >&2
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

# Detect repository type (GitHub or GitLab)
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" =~ github\.com ]]; then
    repo_type="github"
elif [[ "$remote_url" =~ git\.groq\.io ]]; then
    repo_type="gitlab"
else
    echo "Error: Repository must be hosted on GitHub or git.groq.io" >&2
    echo "Remote URL: $remote_url" >&2
    echo "Install 'gh' for GitHub or 'glab' for GitLab repositories" >&2
    exit 1
fi

echo "Detected $repo_type repository"

use_force_push=false
current_branch=$(git branch --show-current)
default_branch=$(cat "$(git rev-parse --git-dir)/refs/remotes/origin/HEAD" | sed 's#.*origin/##' 2>/dev/null || git remote show origin | sed -n '/HEAD branch/s/.*: //p' 2>/dev/null || echo "main")

# If on default branch, create a new branch, otherwise use current branch
if [[ "$current_branch" == "$default_branch" ]]; then
    # Generate branch name from commit message
    branch_suffix=$(echo "$commit_message" | sed 's/^[^:]*: *//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    branch_name="reid/$branch_suffix"
    echo "Creating branch: $branch_name"
    git checkout -b "$branch_name"
    current_branch=$(git branch --show-current)
else
    echo "Using current branch: $current_branch"
fi

# Only commit if a commit message is provided
if [[ -n "$commit_message" ]]; then
    # Check if there are any changes in the repository
    if git diff --quiet && git diff --cached --quiet && [[ -z $(git ls-files --others --exclude-standard) ]]; then
        echo "Error: No changes detected in repository" >&2
        exit 1
    fi

    # Stage files if no staged changes exist
    if git diff --cached --quiet; then
        echo "Staging all changes..."
        git add -A
    fi

    # Check if we should amend instead of creating new commit
    if [[ "$current_branch" != "$default_branch" ]]; then
        # Get the last commit message on this branch
        last_commit_msg=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")

        # Check if this branch has commits ahead of default branch
        commits_ahead=$(git rev-list --count "$default_branch..$current_branch" 2>/dev/null || echo "0")

        if [[ "$commits_ahead" -gt 0 && "$last_commit_msg" == "$commit_message" ]]; then
            echo "Amending previous commit with same message: $commit_message"
            git commit --amend --no-edit
            use_force_push=true
        else
            echo "Committing changes with message: $commit_message"
            echo -e "$commit_message\n\n$commit_body" | git commit -F -
        fi
    else
        echo "Committing changes with message: $commit_message"
        echo -e "$commit_message\n\n$commit_body" | git commit -F -
    fi
else
    commit_message=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")
    commit_body=$(git log -1 --pretty=format:"%b" 2>/dev/null || echo "")
fi

# Push with appropriate flags
echo "Pushing branch to remote..."
if [[ "$use_force_push" == "true" ]]; then
    git push --force-with-lease
else
    git push -u origin "$current_branch"
fi

echo "Creating pull request..."
if [[ "$repo_type" == "github" ]]; then
    pr_output=$(gh pr create --title "$commit_message" --body "$commit_body" 2>&1 || true)

    # Check if PR already exists or was created
    if echo "$pr_output" | grep -q "already exists"; then
        # Extract existing PR URL
        pr_url=$(echo "$pr_output" | grep "https://github.com" || true)
        echo "PR already exists: $pr_url"
    elif echo "$pr_output" | grep -q "https://github.com"; then
        # New PR created
        pr_url=$(echo "$pr_output" | grep "https://github.com" || true)
        echo "PR created: $pr_url"
    else
        echo "Failed to create PR"
        echo "$pr_output" >&2
        pr_url=""
    fi
elif [[ "$repo_type" == "gitlab" ]]; then
    pr_output=$(glab mr create --title "$commit_message" --description "$commit_body" 2>&1 || true)

    # Check if MR already exists or was created
    if echo "$pr_output" | grep -q "already exists"; then
        # Extract existing MR URL
        pr_url=$(echo "$pr_output" | grep "https://git\.groq\.io" || true)
        echo "MR already exists: $pr_url"
    elif echo "$pr_output" | grep -q "https://git\.groq\.io"; then
        # New MR created
        pr_url=$(echo "$pr_output" | grep "https://git\.groq\.io" || true)
        echo "MR created: $pr_url"
    else
        echo "Failed to create MR"
        echo "$pr_output" >&2
        pr_url=""
    fi
fi

# Copy PR/MR URL to clipboard and open in browser on macOS
if [[ "$(uname)" == "Darwin" ]] && [[ -n "$pr_url" ]]; then
    echo "$pr_url" | pbcopy
    if [[ "$repo_type" == "github" ]]; then
        echo "PR URL copied to clipboard"
        echo "Opening PR in browser..."
    else
        echo "MR URL copied to clipboard"
        echo "Opening MR in browser..."
    fi
    open "$pr_url"
fi
