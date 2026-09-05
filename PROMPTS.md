# Session launch prompts

## Model and effort selection (PLAN/lead only)

These are provisional starting policies, not measured capability or cost rankings. Honor explicit user model/effort constraints and verify availability on the host. Model and effort are separate choices; an EXECUTE role restricts design authority, not reasoning. Keep pure workers on their recorded selection instead of making them rediscover routing.

| Remaining execution work | Starting selection |
| --- | --- |
| Mechanical edits using existing patterns and straightforward checks | GPT-5.6 Luna / low |
| Decided behavior, but concurrency, failure recovery, or effective test design still requires reasoning | GPT-5.6 Luna / high |
| Several interacting mechanisms with substantial implementation/validation reasoning | Capable direct execution (for example Astra); delegate only with a concrete benefit |
| Luna high repeats a required-delivery failure after one repair | Re-route to Terra / medium or a smaller complete unit; do not keep the same retry loop |
| Routine independent focused review | Terra / medium |

Prefer direct execution when handing off will leave the lead rereading every patch or designing tests for the executor. PLAN records `mode`, `execution_difficulty`, `delegation_benefit`, executor/reviewer selections, and `lead_reentry` in Routing. Reviewer selection does not authorize parallel workers or override review=skip. A separate Luna reviewer is an experiment for narrow completeness checks, not an assumed reliable semantic gate. Use available deterministic checks for file/state/command facts.

Low U does not imply mechanical execution. A long plan does not imply delegation pays. Compare whole-task completion cost/time, required-evidence coverage, repair rounds, and lead interventions; collect only already-available accounting. Test these defaults on comparable tasks before claiming Luna high or Terra saves money. Higher Luna effort is the first trial for reasoning-heavy bounded work, not a guaranteed fix for omissions.

For existing handoffs without Routing/evidence fields, PLAN adds them when re-planning; EXECUTE preserves the current explicit/host selection, adds evidence to Execution as needed, and does not restart the plan just to migrate the document.

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
   if any required evidence is missing, keep working; pause only for genuine exhaustion, or BLOCKED on a final-session/decision boundary. Never claim completion from the test count alone.
2. Update the HANDOFF file: `Execution.result/progress/deviations/validation`, `session: (k+1)/N` (consumed count — this turn consumed one), and append one `Metrics` line.
3. Final message states the status ONLY: `paused k/N` | `IMPLEMENTED` | `DONE` | `BLOCKED` (k = sessions consumed). No free-form prose.
   "Task completed" is allowed ONLY when all acceptance is met (`IMPLEMENTED`/`DONE`).
4. Read back saved status, next, session, and Execution.evidence. Code changed without a matching handoff is NOT delivered. Repair metadata locally; do not automatically replay implementation. Repeated same-class delivery failures route to PLAN for a model/effort/unit change.
```
Launch with the model AND effort recorded in Routing. Do not downgrade effort because the role is EXECUTE. Keep the session pure: no other skills, no agent frameworks, no repo-wide entry flows, no self-brief. The handoff is the exploration; the executor only translates. Execute segments consecutively while budget allows (a segment boundary is not a stop point). Re-launching the same command continues from the handoff's `Execution.progress` (paused session) — it does not restart the task.

## REVIEW
```text
$bounded-coding-workflow ROLE=REVIEW HANDOFF=.agent_worker/tasks/<task>.md
```
Runs by default (`review=focused`) on the recorded reviewer (starting policy: Terra / medium); skipped only when the handoff explicitly sets `review=skip`. Let this reviewer own routine repair rechecks; the high-tier lead returns only for recorded decision triggers.

## REPLAN
A handoff revision — format migration, re-segmentation, deepening steps, blocker resolution — is a replan, not a fresh PLAN. Return to the existing PLAN session when possible:
```text
$bounded-coding-workflow ROLE=PLAN HANDOFF=.agent_worker/tasks/<task>.md
```

## REVIEW FIX
If REVIEW routes `status=BLOCKED`, `next=EXECUTE`, the executor may resume the recorded local fixes within the envelope. Reuse its session when useful, unless recurring failures require a recorded configuration change:
```text
$bounded-coding-workflow ROLE=EXECUTE HANDOFF=.agent_worker/tasks/<task>.md
```
