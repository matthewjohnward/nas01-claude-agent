# syntax=docker/dockerfile:1
#
# nas01-claude-agent: Claude Code "Remote Control" server for an Unraid box.
# Runs as a non-root user (99:100 = Unraid's nobody:users). Claude Code itself is
# NOT baked in: the entrypoint installs it into /config on first start with
# Anthropic's official installer, and it then keeps itself up to date.
#
# Base image pinned by digest (Dependabot proposes bumps). `apt-get upgrade` at
# build time picks up Debian security fixes on every (weekly) rebuild.
FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq less procps ripgrep tini tmux \
      python3 python3-venv \
 && rm -rf /var/lib/apt/lists/*

# unraid-mcp (MCP server for the Unraid GraphQL API), installed from a
# hash-locked requirements file: every package version AND file hash is fixed,
# wheels only (no build scripts run). Regenerate with the command in
# agent/requirements.in after reviewing a new unraid-mcp release.
COPY agent/requirements.txt /opt/unraid-mcp/requirements.txt
RUN python3 -m venv /opt/unraid-mcp \
 && /opt/unraid-mcp/bin/pip install --no-cache-dir --disable-pip-version-check \
      --require-hashes --no-deps --only-binary=:all: \
      -r /opt/unraid-mcp/requirements.txt \
 && /opt/unraid-mcp/bin/pip uninstall -y pip

# A named user for UID 99 (Debian has no user 99; group 100 "users" exists).
# /app/logs: unraid-mcp writes its log there when it detects Docker; without a
# writable folder it falls back to its own (read-only) install folder and crashes.
RUN useradd --uid 99 --gid 100 --home-dir /config --no-create-home \
      --shell /bin/bash agent \
 && mkdir -p /config /workspace /app/logs \
 && chown 99:100 /config /workspace /app/logs

COPY --chmod=0755 agent/bin/ /usr/local/bin/

# ENABLE_CLAUDEAI_MCP_SERVERS=false: no claude.ai connectors (Google Drive etc.).
# Telemetry opt-out variables are deliberately NOT set: per Anthropic's docs,
# DISABLE_TELEMETRY / DO_NOT_TRACK make Remote Control unavailable when the
# account uses Trusted Devices, and CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
# always does. Third-party telemetry hosts are blocked by the proxy anyway.
ENV HOME=/config \
    PATH=/config/.local/bin:/usr/local/bin:/usr/bin:/bin \
    LANG=C.UTF-8 \
    ENABLE_CLAUDEAI_MCP_SERVERS=false

WORKDIR /workspace
USER 99:100

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
