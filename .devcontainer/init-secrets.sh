#!/usr/bin/env bash
# Runs on the HOST before the container is created.
# Guarantees .devcontainer/secrets.env exists so `--env-file` does not fail.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$dir/secrets.env" ]; then
  cp "$dir/secrets.env.sample" "$dir/secrets.env"
  echo "Created .devcontainer/secrets.env from the sample — fill in your tokens and rebuild."
fi
