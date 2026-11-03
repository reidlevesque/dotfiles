#!/bin/bash
set -euo pipefail

if ! command -v gcloud >/dev/null 2>&1; then
  echo "Skipping NumPy installation: gcloud is not installed."
  exit 0
fi

# Allow gcloud to use NumPy for faster IAP TCP uploads.
export CLOUDSDK_PYTHON_SITEPACKAGES=1

# Homebrew recreates gcloud's Python environment during upgrades.
gcloud_python="$(gcloud info --format='value(basic.python_location)')"
"$gcloud_python" -m pip install numpy
