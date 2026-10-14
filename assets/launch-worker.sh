#!/usr/bin/env bash
# Launch one headless CLI worker and publish its thread id immediately.
#
# Dispatch path B in PROMPTS.md. A lead whose harness has native worker
# delegation (path A) does not need this: the harness spawns and continues its
# own workers, and only the two protocol obligations apply.
#
# Why a script: `Routing.executor_session` is what makes a paused or review-fix
# worker cheap to continue (a resumed thread keeps its warm prompt cache), and a
# handoff field that depends on the lead remembering to fill it stays empty.
#
# Two properties this script exists to guarantee:
#   1. the thread id is published the moment the worker announces it, not when
#      the worker exits — Routing needs it immediately, and a launcher session
#      that dies mid-flight can only be continued with it;
#   2. the script stays in the foreground of its job and exits when the worker
#      exits, so the launcher's completion notice (which is what wakes the lead)
#      fires exactly once, at the right time.
#
# Usage:
#   launch-worker.sh <repo-root> <handoff-path> <role> <prompt-file> [model] [effort]
#
# <role> is a short stable label (execute, execute-fix, review, review2, ...).
# The prompt file's text is piped to the worker on stdin.
# THREAD_WAIT_S (default 300) bounds the wait for the worker's thread id.
#
# Writes beside the handoff (never inside it — the handoff is the worker's to edit):
#   <handoff>.workers             append-only: <role> <thread-id> <final> <events>
#   <handoff-base>.<role>.final   the worker's final message (the ONLY thing to read)
#   <handoff-base>.<role>.events  the JSONL event stream (diagnostics only)
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
thread_wait=${THREAD_WAIT_S:-300}

case "$handoff" in
  /*) handoff_abs=$handoff ;;
  *) handoff_abs="$repo/$handoff" ;;
esac
base=${handoff_abs%.md}
final="$base.$role.final"
events="$base.$role.events"
registry="$handoff_abs.workers"

[ -f "$handoff_abs" ] || { echo "launch-worker: no such handoff: $handoff_abs" >&2; exit 2; }
[ -f "$prompt" ] || prompt="$repo/$prompt"
[ -f "$prompt" ] || { echo "launch-worker: no such prompt: $prompt" >&2; exit 2; }

cd "$repo"
codex exec \
  -C "$repo" \
  -m "$model" \
  -c model_reasoning_effort="$effort" \
  -c approval_policy="never" \
  -s workspace-write \
  -o "$final" \
  --json \
  - < "$prompt" > "$events" &
worker_pid=$!

thread_id=""
for _ in $(seq 1 "$thread_wait"); do
  if [ -s "$events" ]; then
    # `|| true` keeps pipefail from aborting this probe loop on a no-match grep.
    line=$(grep -m1 '"type"[[:space:]]*:[[:space:]]*"thread.started"' "$events" 2>/dev/null || true)
    if [ -n "$line" ]; then
      thread_id=$(printf '%s' "$line" | sed -E 's/.*"thread_id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
      [ -n "$thread_id" ] && break
    fi
  fi
  kill -0 "$worker_pid" 2>/dev/null || break
  sleep 1
done

if [ -n "$thread_id" ]; then
  printf '%s %s %s %s\n' "$role" "$thread_id" "$final" "$events" >> "$registry"
  echo "executor_session[$role]: $thread_id"
else
  echo "launch-worker: no thread id after ${thread_wait}s (worker pid ${worker_pid}); the worker may have failed before starting a thread" >&2
fi
echo "final message: $final"

# Do not background the worker into the void: this script exiting is the
# completion signal the launcher turns into the lead's wake-up notice.
wait "$worker_pid"
