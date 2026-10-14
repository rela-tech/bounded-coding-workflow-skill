#!/usr/bin/env bash
# Keep a vendored (copied) installation of this skill byte-identical to this clone.
#
# Repositories that commit a copy under `.agents/skills/` make that copy the one
# their workers actually read, because the worker launch prompts name it by a
# repo-relative path. A stale copy silently reverts every rule change — a lead
# then reports a missing asset in good faith and works around it.
#
# Usage:
#   sync-install.sh <target-skill-dir>            copy the canonical set into the target
#   sync-install.sh <target-skill-dir> --check    report divergence, change nothing
#
# Exit status is non-zero when --check finds any diverged or missing file, so it
# can gate a commit or a release step.
set -euo pipefail

src=$(cd "$(dirname "$0")/.." && pwd)
target=${1:?usage: sync-install.sh <target-skill-dir> [--check]}
mode=${2:-apply}

# The canonical set a vendored installation carries. READMEs and agents/ stay
# out of it: a vendored copy is for workers, not for readers.
files=(
  SKILL.md
  PROMPTS.md
  references/plan.md
  references/execute.md
  references/review.md
  assets/handoff-template.md
  assets/launch-worker.sh
  assets/resume-worker.sh
)

rc=0
for f in "${files[@]}"; do
  if [ "$mode" = "--check" ]; then
    if ! cmp -s "$src/$f" "$target/$f" 2>/dev/null; then
      echo "DIVERGED: $f"
      rc=1
    fi
    continue
  fi
  mkdir -p "$target/$(dirname "$f")"
  cp "$src/$f" "$target/$f"
done

if [ "$mode" = "--check" ]; then
  [ "$rc" -eq 0 ] && echo "in sync: $target"
  exit "$rc"
fi

for f in assets/launch-worker.sh assets/resume-worker.sh; do
  chmod 755 "$target/$f"
done
echo "synced $((${#files[@]})) files into $target"
