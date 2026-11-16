#!/bin/bash
set -euo pipefail

if ! gcloud_bin="$(command -v gcloud)"; then
  echo "Skipping Google Cloud setup: gcloud is not installed."
  exit 0
fi

# Snap cannot install SDK components. Keep the same SDK version in mise.
gcloud_sdk="$("$gcloud_bin" info --format='value(installation.sdk_root)')"
if [[ "$gcloud_sdk" == /snap/* ]]; then
  gcloud_version="$("$gcloud_bin" info --format='value(basic.version)')"
  mise use --global "gcloud@$gcloud_version"
  gcloud_bin="$(mise which gcloud)"
fi

"$gcloud_bin" components install gke-gcloud-auth-plugin --quiet
if command -v mise >/dev/null 2>&1; then
  mise reshim
fi

# Allow gcloud to use NumPy for faster IAP TCP uploads.
export CLOUDSDK_PYTHON_SITEPACKAGES=1

# Homebrew recreates gcloud's Python environment during upgrades.
gcloud_python="$("$gcloud_bin" info --format='value(basic.python_location)')"
"$gcloud_python" -m pip install numpy
