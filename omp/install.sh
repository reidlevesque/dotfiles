#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly script_dir
readonly config_dir="$HOME/.omp/agent"
readonly models_source="$script_dir/models.yml"
readonly models_file="$config_dir/models.yml"
readonly config_file="$config_dir/config.yml"
readonly default_model="nvidia-inference/nvidia/moonshotai/eccn-kimi-k3"

link_models() {
  if [[ -L "$models_file" ]]; then
    ln -sfn "$models_source" "$models_file"
    return
  fi

  if [[ -e "$models_file" ]]; then
    if ! cmp -s "$models_file" "$models_source"; then
      echo "Cannot configure omp: $models_file differs from $models_source." >&2
      exit 1
    fi

    rm "$models_file"
  fi

  ln -s "$models_source" "$models_file"
}

set_default_model() {
  if ! command -v yq >/dev/null 2>&1; then
    echo "Cannot configure omp: yq is not available." >&2
    exit 1
  fi

  touch "$config_file"
  DEFAULT_MODEL="$default_model" yq -i '.modelRoles.default = strenv(DEFAULT_MODEL)' "$config_file"
}

if ! command -v omp >/dev/null 2>&1; then
  echo "Skipping omp configuration: omp is not installed."
  exit 0
fi

mkdir -p "$config_dir"
link_models
set_default_model

if [[ ! -f "$HOME/.pi/agent/auth.json" ]]; then
  echo "omp reuses the Pi key. Run pi, then /login nvidia-inference to authenticate."
fi
