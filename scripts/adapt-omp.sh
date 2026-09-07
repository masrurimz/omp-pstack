#!/usr/bin/env bash
# Adapt upstream (Cursor-flavored) pstack skill files to OMP.
# Deterministic sed table — every rule documented in ADAPTATION.md.
# Usage: adapt-omp.sh <file>  (edits in place)
set -euo pipefail
f="$1"

sed -i '' \
  -e 's/claude-fable-5-1-thinking-max/your slow-role model/g' \
  -e 's/gpt-5\.6-sol-max/your default-role model/g' \
  -e 's/grok-4\.6-fast-xhigh/your smol-role model/g' \
  -e 's/claude-opus-5-thinking-xhigh/your task-role model/g' \
  -e 's|~/.cursor/rules/pstack-models.mdc|~/.omp/agent/config.yml modelRoles|g' \
  -e "s/Cursor's built-in \`\/loop\` command/an autonomous-run watcher loop/g" \
  -e "s/Cursor's \`\/loop\`/an autonomous-run watcher loop/g" \
  -e 's/a real terminal `\/loop`/an autonomous-run loop/g' \
  -e 's/`\/loop`/the autonomous-run loop/g' \
  -e "s/Cursor's built-in \`create-skill\` skill/the **authoring-a-skill** playbook/g" \
  -e 's|\.cursor/skills/|~/.agents/skills/|g' \
  -e 's|~/.cursor/skills/|~/.agents/skills/|g' \
  -e 's/- `subagent_type`: `generalPurpose`/- dispatch via the OMP `task` tool (default worker)/g' \
  -e 's/One Cursor cloud agent/One OMP background agent/g' \
  -e 's/Cursor cloud agent/OMP background agent/g' \
  -e 's|origin/main:pstack/skills/|origin/main:skills/|g' \
  -e 's/`AskQuestion`/the `ask` tool/g' \
  "$f"
