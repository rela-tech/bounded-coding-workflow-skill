# Session launch prompts

Model tiers (operational mapping; the cost saving is a result of this split, not a metric):
- PLAN: high-tier model with maximum reasoning (e.g. DeepSeek v4 pro, max thinking). Exploration and design are the deliberate, expensive phase.
- EXECUTE: low-tier model, low effort (e.g. codex effort low). Mechanical translation of the decided plan.
- REVIEW: mid-tier model (e.g. Terra / DeepSeek v4 flash) or skipped.

## Initial PLAN
```text
$bounded-coding-workflow ROLE=PLAN HANDOFF=.agent_worker/tasks/<task>.md

Task:
<original task>
```

## EXECUTE (pure session)
```text
$bounded-coding-workflow ROLE=EXECUTE HANDOFF=.agent_worker/tasks/<task>.md

This is a pure bounded-coding-workflow EXECUTE session. Do not load or invoke
any other skill — including using-superpowers and other startup/process skills
(per using-superpowers' own "User Instructions take precedence" rule, this
launch prompt is that explicit instruction). Read only the role file, the
handoff, and the plan anchors; no self-brief, no repo-wide entry flows.

MANDATORY SESSION CLOSING (do BEFORE your final message):
1. Verify completion: check every acceptance bullet against the plan's `[A#]` tags;
   if any is unmet, this is a PAUSE, not completion.
2. Update the HANDOFF file: `Execution.result/progress/deviations/validation`, `session: (k+1)/N` (consumed count — this turn consumed one), and append one `Metrics` line.
3. Final message states the status ONLY: `paused k/N` | `IMPLEMENTED` | `BLOCKED` (k = sessions consumed). No free-form prose.
   "Task completed" is allowed ONLY when all acceptance is met (`IMPLEMENTED`/`DONE`).
4. Code changed without a handoff update = NOT delivered; the session is rejected and re-run.
```
Launch with the low-tier model and low effort. Keep the session pure: no other skills, no agent frameworks, no repo-wide entry flows, no self-brief. The handoff is the exploration; the executor only translates. Execute segments consecutively while budget allows (a segment boundary is not a stop point). Re-launching the same command continues from the handoff's `Execution.progress` (paused session) — it does not restart the task.

## REVIEW
```text
$bounded-coding-workflow ROLE=REVIEW HANDOFF=.agent_worker/tasks/<task>.md
```
Runs by default (`review=focused`); skipped only when the handoff explicitly sets `review=skip`.

## REPLAN
A handoff revision — format migration, re-segmentation, deepening steps, blocker resolution — is a replan, not a fresh PLAN. Return to the existing PLAN session when possible:
```text
$bounded-coding-workflow ROLE=PLAN HANDOFF=.agent_worker/tasks/<task>.md
```

## REVIEW FIX
If REVIEW routes `next=EXECUTE`, return to the existing EXECUTE session when possible:
```text
$bounded-coding-workflow ROLE=EXECUTE HANDOFF=.agent_worker/tasks/<task>.md
```
