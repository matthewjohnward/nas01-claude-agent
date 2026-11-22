# nas01-claude-agent

A small, locked-down container that runs **Claude Code Remote Control** on an
Unraid server, so sessions can be started and approved from the Claude phone app
or claude.ai/code while the work happens on the server. Personal setup, shared
in case it's useful. No secrets live in this repo.

```
 Phone / browser ──► Anthropic relay ◄── outbound HTTPS only ──┐
                                                               │
   Unraid host                                                 │
   ┌───────────────────────────────────────────────────────────┼──┐
   │ claude-agent  (UID 99:100, no capabilities, 2 GB)         │  │
   │   Remote Control server · Manual mode · locked policy     │  │
   │   MCP: unraid (read-only API key) · notify → Apprise      │  │
   │        │ network "claude-net" (--internal: no route out)  │  │
   │        ▼                                                  │  │
   │ claude-proxy (Squid) ── allowlisted HTTPS domains ────────┘  │
   │        └─ LAN: one IP, ports 80 + 8000 only                  │
   └──────────────────────────────────────────────────────────────┘
```

## What's here
| Path | What it is |
|---|---|
| `agent/Dockerfile` | Debian slim (pinned digest) + tools + `unraid-mcp` from a hash-locked lockfile. Runs as 99:100. |
| `agent/bin/` | `entrypoint.sh` (installs/updates Claude Code into `/config`), `supervisor.sh` (keeps Remote Control running, reattaches with `--continue`), `claude-setup` (one-time sign-in), `notify` + `hook-notify` (phone pings via Apprise, quiet buckets only, fixed text), `unraid-mcp-launch` (reads the key from a read-only file). |
| `policy/` | Claude Code managed settings, mounted read-only at `/etc/claude-code/`. |
| `proxy/` | Squid from Debian packages, its config and the domain allowlist. |
| `unraid/` | Unraid container templates. |
| `.github/` | Weekly + on-push build to ghcr.io with pinned Actions, SBOM and signed provenance; Dependabot for digests. |

## Security model (short)
- **Hard limits** (enforced outside Claude): non-root, `--cap-drop=ALL`,
  `no-new-privileges`, no Docker socket, no host shares; only its own appdata
  folder; an internal Docker network whose only exit is the allowlist proxy; a
  read-only Unraid API key; policy files mounted read-only.
- **Soft limits** (inside Claude): Manual approval mode, Auto and Bypass
  disabled, only managed rules/hooks/MCP servers, no claude.ai connectors.
- **Known gap:** Claude Code updates itself inside `/config`, which the agent
  can write to. The hard limits still hold if that were abused.

## Setup outline
1. Create an internal network: `docker network create --internal --subnet 172.31.250.0/24 claude-net`
2. Put `proxy/squid.conf` + `proxy/allowlist-domains.txt` in the proxy's config folder; create the proxy from its template.
3. Create `appdata/claude-agent/{config,workspace,secrets,policy}`; copy `policy/*` (owned by root, 644); write the API key file yourself (mode 400, owner 99:100).
4. Create the agent from its template, then `docker exec -it claude-agent claude-setup`.

Images are published at `ghcr.io/matthewjohnward/nas01-claude-agent` and
`ghcr.io/matthewjohnward/nas01-claude-proxy` (public, inherited from the repo).
