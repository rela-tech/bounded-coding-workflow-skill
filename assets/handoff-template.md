---
protocol: bounded-coding/v2
task: <slug>
status: PLANNING
next: PLAN
base: <git-rev>
u: 3
risk: low
review: focused
session: 0/N          # consumed EXECUTE sessions (k of N budget). Only EXECUTE touches it; +1 at every EXECUTE turn end (pause/completion/block). PLAN/REVIEW never change it.
---

# Goal
<concise intended outcome and material constraints>

# Acceptance
| ID | Required condition and action | Observable evidence | Blocking |
| --- | --- | --- | --- |
| A1 | <condition -> action> | <outcome that proves the behavior> | yes |

Optional test-writing suggestions are not extra acceptance requirements.

# Facts
- `<path>:<symbol>` — <verified implementation-relevant fact>

# Decisions
- <decision> — <rationale where a plausible wrong choice exists; this is the durable design record>

# Non-goals
- <explicit exclusion>

# Scope
minimal_surface:
- capability: <the capability the acceptance criteria require>
- new_responsibilities:
  - <responsibility the DoD requires that the repo does not already own; e.g., "HTTP transport">
- reused_responsibilities:
  - <existing responsibility kept as-is, with `path:symbol` anchor>
- explicitly_unneeded:
  - <existing or plausible responsibility the DoD does not require; e.g., "durable job scheduling">
plan_surface: <short delta summary: what the Plan adds beyond minimal_surface>
delta_justification: <per material delta: `path:symbol` evidence "existing X cannot satisfy acceptance Y because Z", or reference to an approved scope_decision>
scope_decision:
  status: <required | approved | narrowed>   # default: not triggered
  reason: <one line>
  approved_surface: <the surface EXECUTE is bound to; default = minimal_surface>

# Routing
mode: <direct | delegated>
execution_difficulty: <mechanical | reasoning | demanding; independent of u>
delegation_benefit: <work the lead will no longer repeat; for direct, why handoff does not pay>
executor: <available model ID and effort; explicit user choices override provisional defaults>
reviewer: <available model ID and effort, or none when review=skip>
lead_reentry: <architecture/scope decisions, repeated-delivery routing change, or envelope decision; not routine duplicate review>

# Envelope
sessions: <N — user-approved execution budget, one user checkpoint at plan time>
expected_commits: ~<N>   # estimate only; never a trigger
segmentation: <one line per session-sized segment: what each EXECUTE session delivers>
# NOTE: segments are plan-internal structure, never parallel-work distribution units.

# Plan
# Each step: `<path>:<symbol-or-location>` [s<k>][A#] — <change + intended behavior + edge-case default (failure/empty/error handling)>. Anchors must be fully-locatable repo-relative `path:symbol`, never bare file names (esp. cross-module). `[s<k>]` = session segment; `[A#]` = acceptance bullet it satisfies (enables EXECUTE's completion check). If an edge case is unspecified, EXECUTE picks the least-invasive consistent behavior and records a deviation — it must not invent design.
1. `<path>:<symbol-or-location>` [s1][A1] — <change + behavior + boundary default>

# Validate
- `<command>` — <what it proves>   # attach to the segment(s) it guards

# Risks / Open
- none

# Current Blocker
none   # BLOCKED only for decisions: U>=2, envelope exceeded, or user-only blockers

# Execution
result: pending   # one of: pending | paused | IMPLEMENTED | BLOCKED | DONE
progress: <segments done / remaining steps — kept current by EXECUTE on pause/continue>
deviations: none
validation: pending
evidence: pending  # required A# -> actual test/assertion or observation -> command/result
failure_class: none
consecutive_failures: 0

# Review
result: pending
findings: none
failure_class: none
consecutive_failures: 0

# Metrics
<!-- Append one line per worker turn. Purpose: friction detection + later calibration of thresholds (when to run this workflow, envelope sizing) — NOT token accounting.
Fixed schema (in order): role= result= u= reads= val= rework= dev= human= friction=
`result` vocabulary (no free prose — detail lives in the owning section):
  PLAN:    READY | BLOCKED | REPLAN-READY
  EXECUTE: paused | IMPLEMENTED | BLOCKED
  REVIEW:  clean | BLOCKED
Example:
- role=PLAN result=READY u=3>0 reads=9 val=0 rework=0 dev=0 human=0 friction=plan:size-miscalibration
reads=distinct repo files inspected if cheaply knowable (? when not)
val=validation command invocations
rework=failed implement/validate correction loops
dev=material deviations
human=human intervention requested (0/1)
friction=short STABLE label that dedupes the same recurring problem, e.g. plan:size-miscalibration / plan:stale-api-reference / execute:invented-design / execute:no-handoff-update / handoff:ambiguous / validation:stuck / scope:audit-clean
-->
