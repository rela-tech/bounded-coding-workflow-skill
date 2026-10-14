---
name: bounded-coding-workflow
description: Coordinate coding tasks through deliberate planning, bounded execution, and independent review with a compact repo-local handoff. Use when separating design decisions, implementation, and verification helps complete a task reliably.
---

# Bounded coding workflow

Complete the user's task with verified results. Bound scope and decision authority; session count and token usage are not success criteria. Use enough investigation, implementation, and repair to finish. Avoid coordination that does not advance the result.

Inputs: `ROLE=PLAN|EXECUTE|REVIEW`, `HANDOFF=<repo-relative path>`, and the task request for initial planning. A lead invoked without a role starts with PLAN and chooses a task-specific handoff path; a dispatched worker uses the role and path it receives. Read the handoff and the active role's reference: [PLAN](references/plan.md), [EXECUTE](references/execute.md), or [REVIEW](references/review.md). The lead also reads [PROMPTS.md](PROMPTS.md) for dispatch mechanics and model routing.

## Model roles

| Work | Default model | Effort |
| --- | --- | --- |
| PLAN and substantive lead decisions | `gpt-6.1-sol` | `high` |
| EXECUTE and ordinary repairs | `gpt-6.1-sol` | `low` |
| Clearly defined local implementation | `gpt-6-luna` | `high` |
| Independent REVIEW | `gpt-6.1-sol` | `medium` |
| Escalated execution | `gpt-6.1-sol` | `high` |

Use Luna high only for clearly defined local work with established patterns and straightforward verification. Default to Sol low when implementation spans interacting modules or requires substantial test design or debugging. Choose based on the remaining work, not file count alone. Resume repairs at the recorded selection; do not automatically downgrade after escalation.

Use generation 6 or later. These are configured choices, not measured ROI claims. Honor explicit user overrides and verify that the selected launcher supports the model. Do not silently substitute a different model. If the default is unavailable, report the mismatch and choose an available generation-6-or-later alternative within the user's authorization; ask only when that choice requires user input. REVIEW uses a separate worker context from whoever planned or implemented the change; changing a role label in the same context is not independent review.

## Lead / dispatcher responsibilities

Own progress through delivery, not just dispatch. Default to the role split above for substantial work. Keep the lead's context for planning, resolving decisions, and coordinating the result.

- Give EXECUTE a usable decision and acceptance contract, then let it implement, debug, and validate. Do not shadow its work or reconstruct every patch.
- On worker return, read the concise result and relevant handoff updates. Route concrete next work: continue, repair, decide, review, or deliver. Do not perform a second full review after the independent reviewer.
- Fix your own plan text and trivial metadata locally. If a plan correction affects code, have the current executor implement and validate it, or make a genuinely small direct correction and obtain independent review of the changed result. Never send a text-only correction through a fresh implementation pass; never send affected but unfixed code straight to review.
- User-supplied decisions update the contract directly. Resume implementation without a ceremonial planning pass or another approval of already-authorized work.
- Reuse productive worker sessions. Start a new context when independence, model switching limitations, stale context, or an actual failure makes it useful. Role transitions and milestones do not automatically require new sessions.
- Keep dispatch live: wait for or collect completion and continue the workflow. Launching a worker is not task completion. Record recoverable worker IDs and the next action before a real interruption.
- Ask the user only for missing requirements, authority, or choices that materially change the outcome. Ordinary continuation, local implementation choices, and an estimated milestone overrun need no approval.

For a small local edit or explicit user request, use `mode: direct` in the existing context. Do not turn that exception into the lead routinely doing the executor's work. Do not spawn additional planners, auditors, or parallel workers merely to satisfy a process.

## Boundaries and continuation

PLAN settles behavior, contracts, scope, and material risks. EXECUTE owns implementation details and local debugging, including reading adjacent callers, tests, and dependencies needed to do the job. It may adapt stale anchors and choose private helpers or test structure without escalating. Changed public behavior, architecture, ownership, or scope requires a lead decision.

Reuse existing responsibilities and implement the smallest complete solution. Do not silently add unrelated subsystems, durable-format changes, or dependencies. If these are already authorized by the user's task, document and proceed; otherwise resolve the material scope decision before implementing. Repository evidence explains a proposal; it does not itself authorize scope expansion.

Sessions are a runtime detail. Work through logical milestones consecutively, continue across context limits, and resume repairs until acceptance is met. There is no default `k/N` cap, per-session plan segmentation, or mandatory user checkpoint. Explicit user budgets and platform limits remain binding. Pause on a real runtime interruption; block on an unresolved decision, failed repair needing rerouting, or external dependency, not a milestone boundary.

Follow applicable repository instructions. Skip optional startup rituals, repeated briefs, and unrelated skills. This workflow does not override higher-priority instructions or required repository checks; integrate required deliverables once instead of reproducing the repository process in every worker.

## State and evidence

Normal: `PLANNING -> READY -> IMPLEMENTED -> DONE`.
`next`: `PLAN|EXECUTE|REVIEW|USER|DONE`.

- READY / EXECUTE: implementation or continuation is in progress; a runtime pause remains READY.
- IMPLEMENTED / REVIEW: all required acceptance is met and execution evidence is recorded.
- DONE / DONE: independent review passed, or execution passed with explicit `review: skip`.
- BLOCKED: record the concrete evidence and smallest next action. Local review repairs route to EXECUTE, decisions or repeated execution failures to PLAN, and user-only blockers to USER.

Default `review: focused`; use `deep` for concrete security, data-loss, migration, or architectural risk. Review depth does not automatically add another reviewer. Missing acceptance evidence returns to execution. Review independently inspects changed behavior and runs relevant verification; it must distinguish observed results from unverified claims.

## Repeated execution failure

Allow one ordinary repair of a substantive implementation or validation failure. If the same underlying failure persists after that repair, or two successive repair attempts make no meaningful progress on required acceptance, the lead intervenes before another attempt. Renaming a finding, restarting a worker, or switching models does not erase the history.

Classify the cause using the failure and repair evidence:
- execution/reasoning failure: escalate from either `gpt-6.1-sol` low or `gpt-6-luna` high to `gpt-6.1-sol` high;
- wrong or incomplete plan: correct the decision, then resume the appropriate executor;
- environment/permissions/external dependency: resolve the actual dependency; model escalation is not a remedy;
- overly coupled work: isolate a smaller verifiable unit while preserving the full task's acceptance.

A repeated failure needs a changed approach, not a longer checklist or an unchanged fresh executor session. If escalated execution also fails after a targeted repair, diagnose the cause and change strategy; use an available generation-6-or-later model when justified and authorized. Do not cycle models blindly or stop merely because an automatic retry count elapsed. Surface a real blocker when no productive authorized action remains.

Record the underlying issue, attempted repair, observed result, and routing change in Execution. Count failed repair attempts, not expected red tests, normal exploratory debugging, unrelated isolated bugs, or cosmetic handoff omissions. Reviewer findings about the same unresolved behavior feed the same history. Reset that issue's count only after verified resolution. Respect explicit model restrictions when escalating.

## Handoff

Use [assets/handoff-template.md](assets/handoff-template.md) as a starting point, not a form to fill for its own sake. Preserve goals, acceptance, decisions, scope, meaningful evidence, and current progress. Omit unused optional sections. Keep updates proportional to new information; no per-turn metric line, read counts, session counters, or status-only response requirement.

PLAN owns decisions and scope; EXECUTE records progress, deviations, validation, and failure history; REVIEW records findings and verification. Any role may repair mechanical metadata, but changes to a substantive decision must be visible and resolved with the lead. Use repo-relative anchors; avoid source dumps and exploration diaries. Final worker messages give status, material results, and the next action or blocker in a few sentences.

For older handoffs, continue from their existing decisions and progress without a format-migration task. Treat protocol-generated session envelopes as historical estimates, unless they represent an explicit user limit. Preserve genuinely user-imposed limits; do not reinterpret them away. Update old model selections to the defaults above unless the user explicitly pinned a different model.
