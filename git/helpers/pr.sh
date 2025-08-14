#! /bin/bash
set -eo pipefail

# Check if commit message is provided
if [[ $# -ne 1 ]]; then
    echo "Usage: git pr \"commit message\"" >&2
    echo "Example: git pr \"feat: add user authentication\"" >&2
    exit 1
fi

commit_message="$1"

# Validate conventional commit format
if [[ ! "$commit_message" =~ ^(feat|fix|chore|wip):.+ ]]; then
    echo "Error: Commit message must follow conventional commit format (feat:, fix:, chore:, or wip:)" >&2
    echo "Example: git pr \"feat: add user authentication\"" >&2
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

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

# Generate branch name from commit message
# Extract the part after the type and colon, remove leading/trailing whitespace,
# replace spaces with hyphens, and make it lowercase
branch_suffix=$(echo "$commit_message" | sed 's/^[^:]*: *//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
branch_name="reid/$branch_suffix"

echo "Creating branch: $branch_name"
git checkout -b "$branch_name"

echo "Committing changes with message: $commit_message"
git commit -m "$commit_message"

echo "Pushing branch to remote..."
git push -u origin "$branch_name"

echo "Creating pull request..."
gh pr create --title "$commit_message" --body ""
