#!/usr/bin/env bash
# Continue a previously launched worker instead of starting a fresh one.
#
# Dispatch path B in PROMPTS.md; path A continues workers through the harness's
# own mechanism and does not need this script.
#
# A resumed thread keeps its conversation and its warm prompt cache, so the
# worker does not re-read the diff or re-derive what it already established.
# Measured on one host: fresh thread 8,812 uncached input tokens; resumed turn
# 653.
#
# Usage:
#   resume-worker.sh <repo-root> <handoff-path> <role> <prompt-file> [model] [effort]
#
# <role> must match the label used at launch (see <handoff>.workers).
#
# Codex quirk this script exists to absorb: `codex exec resume` takes no
# `-C`/`--cd` and no `-s`/`--sandbox`. The cwd comes from the shell, so the
# script `cd`s into the repo, and the sandbox is set through
# `-c sandbox_mode="workspace-write"` — without that, `-s` is silently
# unavailable and a non-repo cwd fails with `Not inside a trusted directory`.
set -euo pipefail

repo=${1:?repo root}
handoff=${2:?handoff path}
role=${3:?role label}
prompt=${4:?prompt file}
case "$role" in
  review*) default_model=gpt-6.1-sol; default_effort=medium ;;
  plan*) default_model=gpt-6.1-sol; default_effort=high ;;
  *) default_model=gpt-6.1-sol; default_effort=low ;;
esac
model=${5:-$default_model}
effort=${6:-$default_effort}

case "$handoff" in
  /*) handoff_abs=$handoff ;;
  *) handoff_abs="$repo/$handoff" ;;
esac
base=${handoff_abs%.md}
registry="$handoff_abs.workers"

[ -f "$registry" ] || { echo "resume-worker: no worker registry at $registry — launch first" >&2; exit 2; }
[ -f "$prompt" ] || prompt="$repo/$prompt"
[ -f "$prompt" ] || { echo "resume-worker: no such prompt: $prompt" >&2; exit 2; }

thread_id=$(awk -v r="$role" '$1 == r { id = $2 } END { print id }' "$registry")
[ -n "$thread_id" ] || { echo "resume-worker: no thread id recorded for role '$role'" >&2; exit 3; }

# Name each continuation distinctly while keeping the role the lookup key.
prior=$(awk -v r="$role" '$1 == r' "$registry" | wc -l | tr -d ' ')
suffix=".c$prior"
final="$base.$role$suffix.final"
events="$base.$role$suffix.events"

cd "$repo"
codex exec resume "$thread_id" \
  -m "$model" \
  -c model_reasoning_effort="$effort" \
  -c approval_policy="never" \
  -c sandbox_mode="workspace-write" \
  -o "$final" \
  --json \
  - < "$prompt" > "$events"

resumed_id=$(grep -m1 '"type"[[:space:]]*:[[:space:]]*"thread.started"' "$events" \
  | sed -E 's/.*"thread_id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')

printf '%s %s %s %s\n' "$role" "${resumed_id:-$thread_id}" "$final" "$events" >> "$registry"
echo "resumed thread: ${resumed_id:-$thread_id} (role $role, continuation $prior)"
echo "final message: $final"
