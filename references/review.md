# ROLE=REVIEW

Goal: independently verify the implementation without replaying PLAN. Do not modify product code. REVIEW runs by default (level `focused`); it is skipped only when the handoff explicitly sets `review=skip`.

Require `status=IMPLEMENTED` and `next=REVIEW`.

Read in this order:
1. Goal + Acceptance;
2. Decisions + Plan;
3. Scope compliance: `minimal_surface` vs `plan_surface` vs `approved_surface` (fallback = `minimal_surface` when no scope_decision exists) — determines the surface EXECUTE was bound to;
4. Execution + Deviations + validation results + session progress;
5. git diff and changed code;
6. only additional repo evidence needed to verify a concrete concern.

For `focused`, stay diff-centered.
For `deep`, widen only along the stated risk boundary or evidence that challenges an architecture assumption.

Prioritize correctness, acceptance mismatch, surface compliance (the diff must not enlarge the approved surface), regression/contract/data/concurrency/security risk, unsupported deviations, missing/misleading validation, and unplanned design (robustness/abstraction EXECUTE added beyond the plan).
Surface compliance is checked against the recorded `approved_surface` (or `minimal_surface`), not by re-litigating the chosen design: a design the user approved is not a defect just because another design exists.

**Complete the full pass before deciding an outcome.** Finish reading all six inputs (Goal/Acceptance, Decisions/Plan, scope, Execution/Deviations/validation, git diff, and any concrete-concern evidence) and collect *every* finding. Do not block on the first defect found — a partial review that reports one issue and stops produces a fix-then-rediscover ping-pong. Aggregate all findings, then emit exactly one outcome.

Outcome:
- clean -> `status=DONE`, `next=DONE`;
- local implementation defect -> `status=BLOCKED`, `next=EXECUTE`;
- unapproved surface enlargement or unplanned design by EXECUTE/PLAN -> `status=BLOCKED`, `next=PLAN` (or `next=USER` when only the user may approve the enlargement);
- invalid/unknown architecture assumption -> `status=BLOCKED`, `next=PLAN`;
- envelope/size mismatch (plan under-sized for the delivered surface) -> `status=BLOCKED`, `next=PLAN` (re-segment; user alignment is a plan-window activity);
- user/environment/external blocker -> `status=BLOCKED`, `next=USER`.

Blocker paths never route into REVIEW: REVIEW only ever runs on `IMPLEMENTED`.

When clean, write a one-line result. When blocked, write the *complete* findings list — every defect, with severity and the fix or decision each requires — so EXECUTE/PLAN can resolve all of them in one pass; never report a single finding and stop. Append one metric line.
