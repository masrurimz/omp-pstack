#!/usr/bin/env bash
# Sync upstream cursor/plugins/pstack into this OMP port.
# Runs in CI (sync-upstream.yml) and locally. Idempotent.
#
# Port-owned (NEVER overwritten from upstream):
#   skills/poteto-mode/SKILL.md   — OMP router adaptation
#   skills/pstack-omp/            — OMP adapter
#   skills/orchestrate-omp/       — OMP orchestration
# Everything else in upstream skills/ is copied verbatim (framework-neutral
# SKILL.md markdown that OMP reads as-is), INCLUDING poteto-mode playbooks
# (playbooks are adapted lightly upstream but stay compatible; the PR exists
# exactly so a human can eyeball drift).
set -euo pipefail
cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/cursor/plugins "$WORK/upstream" >/dev/null 2>&1
git -C "$WORK/upstream" sparse-checkout set pstack >/dev/null 2>&1

SRC="$WORK/upstream/pstack/skills"
[ -d "$SRC" ] || { echo "no upstream skills dir found" >&2; exit 1; }

CHANGED=0
for d in "$SRC"/*; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  case "$name" in
    pstack-omp|orchestrate-omp) continue ;;                    # port-owned
    poteto-mode)
      # sync playbooks only; SKILL.md is the OMP router (port-owned)
      mkdir -p "skills/poteto-mode/playbooks"
      for pb in "$d"/playbooks/*.md; do
        [ -e "$pb" ] || continue
        if ! cmp -s "$pb" "skills/poteto-mode/playbooks/$(basename "$pb")"; then
          cp "$pb" "skills/poteto-mode/playbooks/"
          echo "playbook updated: $(basename "$pb")"
          CHANGED=1
        fi
      done
      # references/ and other nested docs also sync
      for sub in references docs; do
        [ -d "$d/$sub" ] || continue
        mkdir -p "skills/poteto-mode/$sub"
        cp -R "$d/$sub/." "skills/poteto-mode/$sub/"
        CHANGED=1
      done
      ;;
    *)
      if [ ! -d "skills/$name" ] || ! diff -rq "$d" "skills/$name" >/dev/null 2>&1; then
        rm -rf "skills/$name"
        cp -R "$d" "skills/$name"
        echo "skill synced: $name"
        CHANGED=1
      fi
      ;;
  esac
done

if [ "$CHANGED" -eq 0 ]; then
  echo "upstream in sync — nothing to do"
  exit 0
fi

git add skills/
echo "SYNCED=1" >> "$GITHUB_OUTPUT" 2>/dev/null || true
exit 0
