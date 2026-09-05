---
name: bounded-coding-workflow
description: Explicit multi-session coding protocol for PLAN, EXECUTE, and REVIEW workers sharing a compact repo-local handoff. Use when separating uncertainty reduction from implementation/review is expected to reduce total completion cost.
---

# Bounded coding workflow

Inputs:
- `ROLE=PLAN|EXECUTE|REVIEW`
- `HANDOFF=<repo-relative path>`
- Initial PLAN only: the task request

Do not infer a missing role or handoff path.

The repo is the source of truth. The handoff is both a **design document** and the **cross-worker execution contract**: PLAN resolves design uncertainty; EXECUTE implements and validates the decided behavior; REVIEW checks delivery against evidence. Optimize total completion cost, including lead rereads and repair cycles, rather than the executor's unit price. Session context is only a cache: keep the handoff sufficient for another worker to continue.

Read this file, the handoff if it exists, exactly one role file (`references/plan.md`, `execute.md`, or `review.md`), and only repo evidence needed for that role. Detailed role contracts live in the role files; PLAN/lead also reads `PROMPTS.md` for model/effort routing; pure workers use the selection recorded in the handoff.

EXECUTE and REVIEW are **pure sessions**: their inputs are whitelisted in their role files, and repo-wide entry flows (e.g. knowledge-context bootstrap) are exempt for them. EXECUTE is low authority but feedback-capable: never designs, escalates with evidence.

Do not spawn subagents by default. Delegate only when coordination/context cost is likely lower than doing the bounded work directly. Task size or a long plan alone is not a delegation benefit. Record what the lead will stop doing; if the lead must repeatedly reconstruct the implementation or design its tests, prefer direct execution by a capable model.

Small changes — single-point bugfixes, one-file additions, local tweaks — do not need this workflow. Run it when separating uncertainty reduction from implementation is expected to reduce total cost.

## State

Normal: `PLAN -> READY -> EXECUTE -> DONE`
With review: `PLAN -> READY -> EXECUTE -> IMPLEMENTED -> REVIEW -> DONE`
Exception: `EXECUTE|REVIEW -> BLOCKED -> PLAN|EXECUTE|USER`

**Pause vs BLOCKED**: within the approved envelope, an EXECUTE session that runs out of room *pauses* (`session: k/N` = consumed EXECUTE sessions, keeps `status=READY`, `next=EXECUTE`) — automatic continuation, not a blocker. Status values are `PLANNING/READY/IMPLEMENTED/DONE/BLOCKED`; `next` carries `PLAN|EXECUTE|REVIEW|USER|DONE` (`DONE` only for terminal completion) — never mix the two. BLOCKED records a decision or an explicit review repair: local review fixes -> EXECUTE; `U>=2` with evidence -> PLAN; envelope exceeded or final-session DoD unmet -> PLAN (re-plan; user alignment is a plan-window activity); user-only blockers (requirements/permissions/environment) -> USER.

Validation is part of EXECUTE.

## Gates

**Uncertainty gate** — `U` = remaining engineering uncertainty (`0` fully decided, `1` local choices, `2` cross-boundary/contract/behavior decision, `3` goal/root-cause/architecture unresolved). PLAN emits `READY` only when `U<=1`. EXECUTE solves problems inside decided architecture; a `U>=2` need blocks with evidence instead of replanning.

**Execution difficulty** — assess separately from `U`: `mechanical` (existing patterns and straightforward verification), `reasoning` (decided behavior but concurrency, failure recovery, or nontrivial test design), `demanding` (several interacting mechanisms require substantial implementation and validation reasoning). Low uncertainty does not imply low effort. EXECUTE is low authority, not necessarily low reasoning. PLAN records difficulty, model/effort, delegation benefit, and lead re-entry conditions in `Routing`; use the provisional defaults in `PROMPTS.md`.

**Scope gate** — core invariant: *PLAN may enlarge the minimal surface only with explicit repo evidence or explicit user approval; EXECUTE may never enlarge the approved surface.* `minimal_surface` = fewest architectural responsibilities satisfying the DoD; existing responsibilities stay reused by default. Hard triggers (any hit forces `next=USER`; never self-approve): a new architectural subsystem; persistence/schema or durable-format change. Soft warnings (record in Risks/Open; READY still allowed with justification): a new runtime dependency; >5 plan steps; thin delta rationale.

**Envelope (size gate)** — PLAN organizes the Plan into session-sized segments (`[s<k>]`), each one EXECUTE session's worth, preferring vertical (end-to-end) segments. The envelope = the sessions approved at the single user checkpoint; afterwards the execution window targets zero user interventions. Within the envelope EXECUTE pauses/continues freely; exceeding it routes `BLOCKED -> PLAN`. Segments are plan-internal structure, never parallel-work distribution units.

## Review

`review=skip|focused|deep`, default `focused` (REVIEW runs by default; `skip` only when the handoff explicitly sets it). `focused`: shared behavior/contract touched, meaningful deviations, regression risk. `deep`: security/permissions/data-loss/migration, weak validation at high risk, evidence questioning architecture assumptions. Code volume alone never raises the level. Blocker paths never route through REVIEW.

## Delivery and escalation

Before semantic review, check delivery completeness against required acceptance IDs, validation results, and handoff state. Use existing automated checks for mechanical facts where available; a passing test count or an IMPLEMENTED message is not evidence of acceptance. Incomplete delivery returns to EXECUTE within the envelope, rather than triggering a fresh high-tier design review.

Track a stable failure class (for example `missing-required-tests`, `invalid-test-causality`, `handoff-state-mismatch`) and consecutive occurrences in `Execution`. If the same class recurs after one repair attempt, stop relaunching the same model/effort with a longer checklist. PLAN/lead selects higher effort, a stronger executor, or a smaller complete unit and records the change before resuming. Ordinary isolated bugs do not automatically require escalation. Explicit user model/effort limits and the approved envelope still apply; model changes do not reset consumed sessions. Do not enlarge the envelope merely to keep an ineffective configuration retrying.

The selected reviewer owns ordinary review/fix/recheck cycles. High-tier lead re-entry is for the recorded decision triggers, not routine duplicate review.

## Ownership

PLAN owns: Goal, Acceptance, Facts, Decisions, Non-goals, Scope, Plan (segments + boundary defaults), Validate, Routing, envelope, Risks/Open. EXECUTE owns: Execution, Deviations, validation results, evidence-based escalations — bound to `approved_surface`, never enlarging it and never adding unplanned design. REVIEW owns: Review. Any role may update status/routing, `U`, risk/review level with evidence, append a blocker, append one metric line. Never silently rewrite another role's decision; record evidence and route to PLAN.

## Handoff hygiene

Two layers with different lifetimes:
- **Stable (design document — never pruned)**: Goal, Acceptance, Decisions (rationale where a plausible wrong choice exists), Non-goals, Scope, Plan, Validate, Routing, Risks/Open.
- **Volatile (runtime state — replace stale, don't accumulate)**: status/next, session progress, Execution, Deviations, Review, Metrics, Current Blocker.

Rules: `path:symbol` anchors; never paste source excerpts, chain-of-thought, or a discarded-alternatives diary; record in `Decisions`/`delta_justification` the materially relevant competing mechanisms and the evidence that rejects them (so REVIEW can see what was surveyed); machine fields (frontmatter keys, status values, section titles) in English, prose may use the team language, anchors verbatim; a blocker records only evidence, conflict, and the smallest decision needed.

Append one compact metric line per worker turn under `# Metrics` — friction detection and threshold calibration, not mandatory token accounting. When already available, compare whole-task cost/time and lead interventions across configurations; include cached/uncached accounting consistently and do not infer savings from model unit prices. Do not fetch usage just to populate metrics. `result` uses the fixed vocabulary (PLAN `READY|BLOCKED|REPLAN-READY`, EXECUTE `paused|IMPLEMENTED|BLOCKED`, REVIEW `clean|BLOCKED`); `friction` is a stable, dedupe-able label. Use `?` when a value is not cheaply available; never run tools merely to collect metrics.
