#!/usr/bin/env bash
set -euo pipefail
# Creates & mounts a case-sensitive APFS sparsebundle, then (optionally) clones a repo.

# --- Config (change if you like) ---
VOLNAME="CaseSensitiveRepo"        # Volume name when mounted
SIZE="100g"                        # Max size cap; sparse so it grows as needed
IMG="$HOME/${VOLNAME}.sparsebundle"  # Image path
MOUNT="/Volumes/${VOLNAME}"


exists() { command -v "$1" >/dev/null 2>&1; }

# Create image if missing
if [[ ! -e "$IMG" ]]; then
  echo "Creating case-sensitive APFS sparsebundle at: $IMG"
  hdiutil create -type SPARSEBUNDLE -fs "Case-sensitive APFS" -size "$SIZE" -volname "$VOLNAME" "$IMG"
fi

# Attach if not mounted
if [[ ! -d "$MOUNT" || ! -w "$MOUNT" ]]; then
  echo "Mounting $IMG..."
  hdiutil attach "$IMG" -nobrowse >/dev/null
fi

echo "Mounted at: $MOUNT"

# Optional: turn off Spotlight indexing for speed/noise
if exists mdutil; then
  mdutil -i off "$MOUNT" >/dev/null 2>&1 || true
fi
