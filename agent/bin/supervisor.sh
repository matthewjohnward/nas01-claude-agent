#!/bin/bash
# Keeps `claude remote-control` running. On every (re)start it first tries to
# reattach to the last session (--continue, works for ~4 h); if there is nothing
# to reattach to it starts a fresh server. Waits until claude-setup has been run.
set -uo pipefail
cd /workspace || exit 1

log() { echo "[supervisor] $(date '+%F %T') $*"; }

ARGS=(
  --name "${RC_NAME:-NAS01}"
  --spawn same-dir
  --capacity "${RC_CAPACITY:-3}"
  --permission-mode default
  --settings /etc/claude-code/session-settings.json
)

until [ -f /config/.setup-done ]; do
  log "waiting: run 'claude-setup' in the container console first"
  sleep 60
done

while true; do
  start=$(date +%s)
  log "starting Remote Control (--continue)"
  claude remote-control --continue "${ARGS[@]}"
  rc=$?
  if [ $(( $(date +%s) - start )) -lt 30 ]; then
    log "--continue exited quickly (rc=$rc): starting a fresh server"
    claude remote-control "${ARGS[@]}"
    rc=$?
  fi
  log "Remote Control exited (rc=$rc); restarting in 15 s"
  sleep 15
done
