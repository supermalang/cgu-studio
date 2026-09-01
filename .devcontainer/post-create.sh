#!/usr/bin/env bash
# Runs inside the container, once, after it is created.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Regular (non-secret) app env lives outside .devcontainer, next to the app.
if [ ! -f frontend/.env.local ]; then
  cp frontend/.env.example frontend/.env.local
  echo "Created frontend/.env.local from .env.example — fill in your Supabase / n8n values."
fi

echo "Installing frontend dependencies..."
npm --prefix frontend install

# gh picks up GITHUB_TOKEN from secrets.env automatically; just report status.
if [ -n "${GITHUB_TOKEN:-}" ]; then
  echo "GITHUB_TOKEN is set — gh CLI is authenticated."
else
  echo "GITHUB_TOKEN is not set — add it to .devcontainer/secrets.env to use the gh CLI."
fi

echo "Done. Run 'npm --prefix frontend run dev' to start Vite on port 5173."
