#!/bin/bash
set -eo pipefail

# mr.sh - Create a merge request on remote host for groq-monorepo (read-only local repo)
# Usage: git mr [commit_message] [commit_body]

commit_message="${1:-}"
commit_body="${2:-}"

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

# Check if this is the groq-monorepo
repo_name=$(basename "$(git rev-parse --show-toplevel)")
if [[ "$repo_name" != "groq-monorepo" ]]; then
    echo "Error: git mr only works in groq-monorepo" >&2
    echo "Current repo: $repo_name" >&2
    exit 1
fi

# Get current branch
current_branch=$(git branch --show-current)
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "head")

# Determine the branch name for the remote
if [[ "$current_branch" != "$default_branch" ]] && [[ -n "$current_branch" ]]; then
    # We're on an existing branch, use it
    echo "Using existing branch: $current_branch"
    remote_branch="$current_branch"
    use_existing_branch=true
    # If no commit message provided, use the last commit message from the branch
    if [[ -z "$commit_message" ]]; then
        commit_message=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")
        commit_body=$(git log -1 --pretty=format:"%b" 2>/dev/null || echo "")
        if [[ -z "$commit_message" ]]; then
            echo "Error: No commit message provided and no previous commits on branch" >&2
            exit 1
        fi
        echo "Using last commit message: $commit_message"
    fi
elif [[ -n "$commit_message" ]]; then
    # On default branch, generate new branch name from commit message
    branch_suffix=$(echo "$commit_message" | sed 's/^[^:]*: *//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    remote_branch="reid/$branch_suffix"
    use_existing_branch=false
else
    # Must have a commit message to generate branch name
    echo "Error: Commit message is required for git mr when on default branch" >&2
    exit 1
fi

# Validate conventional commit format (with optional scope)
commit_pattern='^(feat|fix|chore|wip)(\([^)]+\))?(!)?:.+'
if [[ -n "$commit_message" ]] && [[ ! "$commit_message" =~ $commit_pattern ]]; then
    echo "Error: Commit message must follow conventional commit format (feat:, fix:, chore:, or wip:)" >&2
    echo "Examples:" >&2
    echo "  git mr \"feat: add user authentication\"" >&2
    echo "  git mr \"fix(EI-473): resolve login issue\"" >&2
    exit 1
fi

echo "Creating patch from current working directory changes..."

# Check if there are any changes (staged or unstaged)
if git diff --quiet && git diff --cached --quiet && [[ -z $(git ls-files --others --exclude-standard) ]]; then
    echo "Error: No changes detected in repository" >&2
    exit 1
fi

# Create the patch from ALL changes (staged, unstaged, and untracked files)
patch_file="/tmp/groq-monorepo-$(date +%s).patch"
untracked_file="/tmp/groq-monorepo-untracked-$(date +%s).tar.gz"

# Create a combined patch for tracked files (both staged and unstaged)
{
    git diff --cached  # Staged changes
    git diff           # Unstaged changes
} > "$patch_file"

# Handle untracked files separately
untracked_files=$(git ls-files --others --exclude-standard)
if [[ -n "$untracked_files" ]]; then
    echo "Found untracked files, creating archive..."
    # Use a while loop to handle files with spaces properly
    git ls-files --others --exclude-standard -z | tar czf "$untracked_file" --null -T - 2>/dev/null || true
fi

# Check if we have any changes to send
if [[ ! -s "$patch_file" ]] && [[ ! -f "$untracked_file" ]]; then
    echo "Error: No changes to patch" >&2
    rm -f "$patch_file" "$untracked_file"
    exit 1
fi

if [[ -s "$patch_file" ]]; then
    echo "Patch created: $patch_file"
    echo "Patch size: $(wc -c < "$patch_file") bytes"
fi

# Prepare remote commands
remote_host="rlevesque"
remote_patch_dir="patch/Groq"  # Relative to home dir
# Since ~/patch/Groq is the repo, wt.sh will use "Groq" as the repo name
worktree_name="Groq_$(echo "$remote_branch" | sed 's/\//-/g')"
remote_patch_file="$remote_patch_dir/$(basename "$patch_file")"
remote_untracked_file=""

echo "Copying files to remote host..."
# Create remote directory (use escaped $HOME for remote execution)
ssh "$remote_host" 'mkdir -p $HOME/patch/Groq'

# Copy patch if it exists and has content
if [[ -s "$patch_file" ]]; then
    scp "$patch_file" "${remote_host}:${remote_patch_file}"
fi

# Copy untracked files archive if it exists
if [[ -f "$untracked_file" ]]; then
    remote_untracked_file="$remote_patch_dir/$(basename "$untracked_file")"
    scp "$untracked_file" "${remote_host}:${remote_untracked_file}"
fi

echo "Setting up worktree on remote host..."

# Build the remote command script
remote_script=$(cat << REMOTE_SCRIPT
set -eo pipefail

# Arguments passed from local
WORKTREE_NAME="$worktree_name"
REMOTE_BRANCH="$remote_branch"
USE_EXISTING_BRANCH="$use_existing_branch"
PATCH_FILE="\$HOME/$remote_patch_file"  # Add $HOME prefix since we pass relative paths
UNTRACKED_FILE="$remote_untracked_file"
if [[ -n "\$UNTRACKED_FILE" ]]; then
    UNTRACKED_FILE="\$HOME/\$UNTRACKED_FILE"
fi
COMMIT_MESSAGE="$commit_message"
COMMIT_BODY="$commit_body"

cd "\$HOME/patch/Groq"
git up

# Check if worktree already exists
WORKTREE_PATH="\$HOME/patch/\$WORKTREE_NAME"
if [[ -d "\$WORKTREE_PATH" ]]; then
    if [[ "\$USE_EXISTING_BRANCH" == "true" ]]; then
        echo "Using existing worktree at \$WORKTREE_PATH for branch \$REMOTE_BRANCH"
        # Navigate to existing worktree and pull latest
        cd "\$WORKTREE_PATH"
        git pull --rebase || true
    else
        echo "Worktree already exists at \$WORKTREE_PATH, removing it..."
        git worktree remove "\$WORKTREE_PATH" --force || true
        # Create new worktree
        git wt add "\$REMOTE_BRANCH"
        # Navigate to the newly created worktree
        cd "\$WORKTREE_PATH"
    fi
else
    # Worktree doesn't exist, create it
    if [[ "\$USE_EXISTING_BRANCH" == "true" ]] && git show-ref --verify --quiet "refs/remotes/origin/\$REMOTE_BRANCH"; then
        echo "Creating worktree for existing remote branch: \$REMOTE_BRANCH"
        # Branch exists on remote, check it out
        git worktree add "\$WORKTREE_PATH" -b "\$REMOTE_BRANCH" "origin/\$REMOTE_BRANCH" || \
            git worktree add "\$WORKTREE_PATH" "\$REMOTE_BRANCH"
        cd "\$WORKTREE_PATH"
    else
        echo "Creating worktree with new branch: \$REMOTE_BRANCH"
        # Use git wt alias to create new branch
        git wt add "\$REMOTE_BRANCH"
        cd "\$WORKTREE_PATH"
    fi
fi

# Apply the patch if it exists and has content
if [[ -s "\$PATCH_FILE" ]]; then
    echo "Applying patch..."
    git apply "\$PATCH_FILE"
fi

# Extract untracked files if archive exists
if [[ -n "\$UNTRACKED_FILE" ]] && [[ -f "\$UNTRACKED_FILE" ]]; then
    echo "Extracting untracked files..."
    tar xzf "\$UNTRACKED_FILE"
fi

# Check if we have any changes after applying patches
if git diff --quiet && [[ -z \$(git ls-files --others --exclude-standard) ]]; then
    echo "Error: No changes detected after applying patches" >&2
    exit 1
fi

echo "Changes applied successfully"
echo "Running git pr..."

# Run git pr with the provided arguments
git pr "\$COMMIT_MESSAGE" "\$COMMIT_BODY"

echo "Cleaning up patch files..."
rm -f "\$PATCH_FILE" "\$UNTRACKED_FILE"

echo "Done!"
REMOTE_SCRIPT
)

# Execute the remote script (variables are embedded in the script)
echo "Executing operations on remote host..."
ssh "$remote_host" bash <<< "$remote_script"

# Clean up local files
rm -f "$patch_file" "$untracked_file"
git reset --hard

if [[ "$use_existing_branch" == "true" ]]; then
    git pull
    echo "✅ Successfully updated MR on remote host"
    echo "Updated existing branch: $remote_branch"
else
    git up
    git co "$remote_branch" || echo "Branch hasn't synced yet, try again in a minute"
    echo "✅ Successfully created MR on remote host"
    echo "Created new branch: $remote_branch"
fi
