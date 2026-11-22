#!/bin/bash
# Container start: make sure Claude Code is installed and current, then run the
# Remote Control supervisor inside tmux (so a person can attach to it with
# `docker exec -it claude-agent tmux attach -t rc` if something needs a reply).
set -uo pipefail
umask 077

log() { echo "[entrypoint] $(date '+%F %T') $*"; }

mkdir -p /config/.local/bin /workspace

# First start: install Claude Code. Keep retrying (the restart policy is "no",
# so exiting would leave the container stopped). If this loops, check
# `docker logs claude-proxy` for TCP_DENIED lines and extend the allowlist.
while [ ! -x /config/.local/bin/claude ]; do
  log "installing Claude Code with Anthropic's official installer"
  if curl -fsSL --retry 3 https://claude.ai/install.sh -o /tmp/claude-install.sh; then
    bash /tmp/claude-install.sh || log "installer failed"
    rm -f /tmp/claude-install.sh
  else
    log "could not download the installer (proxy allowlist?)"
  fi
  [ -x /config/.local/bin/claude ] || { log "not installed yet; retrying in 5 minutes"; sleep 300; }
done

log "Claude Code $(claude --version 2>/dev/null | head -1)"
claude update >/dev/null 2>&1 && log "update check done" || log "update check failed (continuing)"

tmux new-session -d -s rc /usr/local/bin/supervisor.sh
log "supervisor started in tmux session 'rc'"

# Keep the container alive for as long as the supervisor's tmux session exists.
while tmux has-session -t rc 2>/dev/null; do sleep 30; done
log "tmux session ended; exiting so the container shows as stopped"
exit 1
