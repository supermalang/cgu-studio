# Node 22: required by Vite 7 (^20.19.0 || >=22.12.0)
FROM mcr.microsoft.com/devcontainers/javascript-node:1-22-bookworm

# Tools that are handy in the container but not part of the app image
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq zip unzip postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Claude Code + Supabase CLI, installed as the non-root user
USER node
RUN npm install -g @anthropic-ai/claude-code supabase

WORKDIR /workspaces/jelika
