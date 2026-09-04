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

The repo is the source of truth. The handoff is both a **design document** and the **cross-worker execution contract**: PLAN spends freely to make it complete; EXECUTE translates it mechanically; REVIEW verifies on demand. Session context is only a cache: keep the handoff sufficient for another worker to continue.

Read this file, the handoff if it exists, exactly one role file (`references/plan.md`, `execute.md`, or `review.md`), and only repo evidence needed for that role. Detailed role contracts live in the role files; `PROMPTS.md` maps roles to model tiers.

EXECUTE and REVIEW are **pure sessions**: their inputs are whitelisted in their role files, and repo-wide entry flows (e.g. knowledge-context bootstrap) are exempt for them. EXECUTE is low authority but feedback-capable: never designs, escalates with evidence.

Do not spawn subagents by default. Delegate only when coordination/context cost is likely lower than doing the bounded work directly.

Small changes — single-point bugfixes, one-file additions, local tweaks — do not need this workflow. Run it when separating uncertainty reduction from implementation is expected to reduce total cost.

## State

Normal: `PLAN -> READY -> EXECUTE -> DONE`
With review: `PLAN -> READY -> EXECUTE -> IMPLEMENTED -> REVIEW -> DONE`
Exception: `EXECUTE|REVIEW -> BLOCKED -> PLAN|EXECUTE|USER`

**Pause vs BLOCKED**: within the approved envelope, an EXECUTE session that runs out of room *pauses* (`session: k/N` = consumed EXECUTE sessions, keeps `status=READY`, `next=EXECUTE`) — automatic continuation, not a blocker. Status values are `PLANNING/READY/IMPLEMENTED/DONE/BLOCKED`; `next` carries the routing role `PLAN|EXECUTE|REVIEW|USER` — never mix the two. BLOCKED is reserved for decisions: `U>=2` with evidence -> PLAN; envelope exceeded or final-session DoD unmet -> PLAN (re-plan; user alignment is a plan-window activity); user-only blockers (requirements/permissions/environment) -> USER.

Validation is part of EXECUTE.

## Gates

**Uncertainty gate** — `U` = remaining engineering uncertainty (`0` mechanical, `1` local choices, `2` cross-boundary/contract/behavior decision, `3` goal/root-cause/architecture unresolved). PLAN emits `READY` only when `U<=1`. EXECUTE solves problems inside decided architecture; a `U>=2` need blocks with evidence instead of replanning.

**Scope gate** — core invariant: *PLAN may enlarge the minimal surface only with explicit repo evidence or explicit user approval; EXECUTE may never enlarge the approved surface.* `minimal_surface` = fewest architectural responsibilities satisfying the DoD; existing responsibilities stay reused by default. Hard triggers (any hit forces `next=USER`; never self-approve): a new architectural subsystem; persistence/schema or durable-format change. Soft warnings (record in Risks/Open; READY still allowed with justification): a new runtime dependency; >5 plan steps; thin delta rationale.

**Envelope (size gate)** — PLAN organizes the Plan into session-sized segments (`[s<k>]`), each one EXECUTE session's worth, preferring vertical (end-to-end) segments. The envelope = the sessions approved at the single user checkpoint; afterwards the execution window targets zero user interventions. Within the envelope EXECUTE pauses/continues freely; exceeding it routes `BLOCKED -> PLAN`. Segments are plan-internal structure, never parallel-work distribution units.

## Review

`review=skip|focused|deep`, default `focused` (REVIEW runs by default; `skip` only when the handoff explicitly sets it). `focused`: shared behavior/contract touched, meaningful deviations, regression risk. `deep`: security/permissions/data-loss/migration, weak validation at high risk, evidence questioning architecture assumptions. Code volume alone never raises the level. Blocker paths never route through REVIEW.

## Ownership

PLAN owns: Goal, Acceptance, Facts, Decisions, Non-goals, Scope, Plan (segments + boundary defaults), Validate, envelope, Risks/Open. EXECUTE owns: Execution, Deviations, validation results, evidence-based escalations — bound to `approved_surface`, never enlarging it and never adding unplanned design. REVIEW owns: Review. Any role may update status/routing, `U`, risk/review level with evidence, append a blocker, append one metric line. Never silently rewrite another role's decision; record evidence and route to PLAN.

## Handoff hygiene

Two layers with different lifetimes:
- **Stable (design document — never pruned)**: Goal, Acceptance, Decisions (rationale where a plausible wrong choice exists), Non-goals, Scope, Plan, Validate, Risks/Open.
- **Volatile (runtime state — replace stale, don't accumulate)**: status/next, session progress, Execution, Deviations, Review, Metrics, Current Blocker.

Rules: `path:symbol` anchors; never paste source excerpts, chain-of-thought, or discarded alternatives; machine fields (frontmatter keys, status values, section titles) in English, prose may use the team language, anchors verbatim; a blocker records only evidence, conflict, and the smallest decision needed.

Append one compact metric line per worker turn under `# Metrics` — friction detection and threshold calibration, not token accounting. `result` uses the fixed vocabulary (PLAN `READY|BLOCKED|REPLAN-READY`, EXECUTE `paused|IMPLEMENTED|BLOCKED`, REVIEW `clean|BLOCKED`); `friction` is a stable, dedupe-able label. Use `?` when a value is not cheaply available; never run tools merely to collect metrics.
