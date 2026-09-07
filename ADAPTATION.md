# OMP adaptation layer

Upstream [cursor/plugins/pstack](https://github.com/cursor/plugins/tree/main/pstack)
is Cursor-flavored. This port adapts it for OMP via a deterministic sed table
(`scripts/adapt-omp.sh`) applied by the sync bot to every upstream file it
copies. Every rule:

| Upstream (Cursor) | Port (OMP) |
|---|---|
| `claude-fable-5-1-thinking-max` | your slow-role model |
| `gpt-5.6-sol-max` | your default-role model |
| `grok-4.6-fast-xhigh` | your smol-role model |
| `claude-opus-5-thinking-max` | your task-role model |
| `~/.cursor/rules/pstack-models.mdc` | `~/.omp/agent/config.yml` modelRoles |
| Cursor's `/loop` command / terminal `/loop` | autonomous-run watcher loop |
| Cursor's built-in `create-skill` skill | the **authoring-a-skill** playbook |
| `.cursor/skills/` / `~/.cursor/skills/` | `~/.agents/skills/` |
| `subagent_type: generalPurpose` | dispatch via the OMP `task` tool |
| Cursor cloud agent | OMP background agent |
| `origin/main:pstack/skills/…` git-show paths | `origin/main:skills/…` |
| `AskQuestion` | the `ask` tool |

## What is port-owned (never synced)

- `skills/poteto-mode/SKILL.md` — the OMP router
- `skills/poteto-mode/playbooks/*` — OMP-adapted playbooks (upstream drift is
  REPORTED to `upstream-drift.md` by the bot, never auto-applied)
- `skills/pstack-omp/`, `skills/orchestrate-omp/`

Model-role mapping matches a glm-only OMP setup
(`modelRoles`: default/smol/slow/task). If your panel differs, the phrasing
degrades gracefully to "your X-role model" — edit `scripts/adapt-omp.sh`.
