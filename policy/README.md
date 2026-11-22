# Policy files

These are mounted **read-only** at `/etc/claude-code/` in the agent container
(host folder owned by root, mode 644), so the agent cannot change them.

| File | What it does |
|---|---|
| `managed-settings.json` | Claude Code's highest-priority settings. Sessions start in Manual; Auto is allowed when the user switches to it (in 2.1.330 the plan-approval button could switch to Auto even with `disableAutoMode`, so a lock there wasn't reliable anyway); Bypass switched off; plan files can be saved (`~/.claude/plans`) but settings, login, agents/commands/skills/hooks and the program can't be edited; session history kept 365 days; only these allow/deny rules, hooks and MCP servers count (anything a session saves for itself is ignored); no claude.ai connectors; phone pings via fixed-text hooks. |
| `managed-mcp.json` | The only MCP server: `unraid` (read-only API key from `/secrets`). |
| `session-settings.json` | Passed to `claude remote-control --settings`. Without it, Remote Control turns Auto mode on for new sessions. |

Things to re-check against the docs when Claude Code changes: path syntax in
deny rules (`//` = absolute path), the `Bash(notify *)` rule form, and the
Notification hook matchers (`permission_prompt`, `idle_prompt`).

Note: the MCP server is one tool with many actions, so rules can't separate
reads from writes. **The read-only API key is the real boundary.**
