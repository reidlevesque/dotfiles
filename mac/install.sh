#!/usr/bin/env bash
set -euo pipefail

# Only run on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script is only for macOS"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.user.casesensitiverepo.plist"

# Create the case-sensitive volume
"$SCRIPT_DIR/case-sensitive-fs.sh"

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$LAUNCH_AGENTS_DIR"

# Copy the plist file
echo "Installing LaunchAgent for case-sensitive volume auto-mount..."
cp "$SCRIPT_DIR/$PLIST_NAME" "$LAUNCH_AGENTS_DIR/"

# Load the LaunchAgent
if launchctl list | grep -q "com.user.casesensitiverepo"; then
    echo "Unloading existing LaunchAgent..."
    launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
fi

echo "Loading LaunchAgent..."
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo "✓ LaunchAgent installed and loaded successfully"
echo "The case-sensitive volume will auto-mount on login"
