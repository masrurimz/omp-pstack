#!/usr/bin/env bash
# Sync upstream cursor/plugins/pstack into this OMP port.
# Runs in CI (sync-upstream.yml) and locally. Idempotent.
#
# Port-owned (NEVER overwritten from upstream):
#   skills/poteto-mode/SKILL.md     — OMP router adaptation
#   skills/poteto-mode/playbooks/   — OMP-adapted playbooks (drift REPORTED,
#                                     see upstream-drift.md — never clobbered)
#   skills/pstack-omp/              — OMP adapter
#   skills/orchestrate-omp/         — OMP orchestration
# Everything else copies from upstream THEN passes through the OMP adaptation
# layer (scripts/adapt-omp.sh — rules documented in ADAPTATION.md).
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
DRIFT_REPORT=""

for d in "$SRC"/*; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  case "$name" in
    pstack-omp|orchestrate-omp) continue ;;                       # port-owned
    poteto-mode)
      # SKILL.md and playbooks are port-owned. Report drift, never apply.
      for pb in "$d"/playbooks/*.md; do
        [ -e "$pb" ] || continue
        ours="skills/poteto-mode/playbooks/$(basename "$pb")"
        if [ ! -f "$ours" ]; then
          DRIFT_REPORT+="- NEW upstream playbook (needs manual OMP port): $(basename "$pb")"$'\n'
        elif ! cmp -s "$pb" "$ours"; then
          DRIFT_REPORT+="- drifted: $(basename "$pb")"$'\n'
        fi
      done
      for ours in skills/poteto-mode/playbooks/*.md; do
        [ -e "$ours" ] || continue
        if [ ! -e "$d/playbooks/$(basename "$ours")" ]; then
          DRIFT_REPORT+="- removed upstream: $(basename "$ours")"$'\n'
        fi
      done
      ;;
    *)
      tmp="$(mktemp -d)"
      cp -R "$d" "$tmp/$name"
      # adapt every text file in the copy
      find "$tmp" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \) \
        -exec bash scripts/adapt-omp.sh {} \;
      if [ ! -d "skills/$name" ] || ! diff -rq "$tmp/$name" "skills/$name" >/dev/null 2>&1; then
        rm -rf "skills/$name"
        cp -R "$tmp/$name" "skills/$name"
        echo "skill synced+adapted: $name"
        CHANGED=1
      fi
      rm -rf "$tmp"
      ;;
  esac
done

# write drift report (always rewrite so it reflects reality)
if [ -n "$DRIFT_REPORT" ]; then
  printf 'Upstream poteto-mode playbook drift (needs manual OMP port — do NOT copy verbatim):\n\n%s\n' "$DRIFT_REPORT" > upstream-drift.md
  git add upstream-drift.md
  CHANGED=1
  echo "drift report updated"
elif [ -f upstream-drift.md ]; then
  git rm -q upstream-drift.md 2>/dev/null || rm -f upstream-drift.md
  CHANGED=1
fi

if [ "$CHANGED" -eq 0 ]; then
  echo "upstream in sync — nothing to do"
  exit 0
fi

git add skills/
exit 0
