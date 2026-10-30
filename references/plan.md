# ROLE=PLAN

Default to `gpt-6.1-sol` with `high` effort; honor explicit user overrides and recorded escalations under SKILL.md and PROMPTS.md. Resolve the decisions necessary for a complete implementation, then let EXECUTE work. Planning and dispatch can share the lead's context.

Read the request, applicable repository instructions, and existing handoff. Investigate materially relevant ownership, call paths, contracts, existing patterns, and risks. Explore alternatives when they could change the design; stop when the remaining choices are local implementation details. Do not survey the repository just to demonstrate diligence.

Write a compact contract:
- goal and independently checkable acceptance;
- existing responsibilities to reuse, affected surface, and explicit exclusions;
- decisions and rationale where a plausible alternative matters;
- implementation steps anchored to existing code or a clearly identified new location;
- observable validation and significant failure/edge cases;
- model routing and any real unresolved blocker.

For independent work, record dependencies, acceptance subsets, write ownership, and an integration owner using PROMPTS.md. Keep coupled work serial.

Use logical milestones only when useful. Do not estimate or approve a number of sessions. Do not prescribe private names, function bodies, control flow, fixtures, or test implementations. Exact details belong in the plan only when they are part of a public, persisted, or user-visible contract.

For changed behavior gates, identify relevant entry/assembly paths and validation that would catch a wrong gating condition. Specify what evidence establishes acceptance and the counterexample or failure case it must cover. Let EXECUTE choose how to construct the test. Use actual project validation semantics: a nonzero analyzer result needs a documented baseline comparison if pre-existing findings are tolerated, not an invented universal success rule.

Before READY, check that the executor can proceed without choosing new product behavior or architecture and can tell when it has finished. A missing local coding detail is not a plan gap. Set `status=READY`, `next=EXECUTE` and dispatch with the selected model; do not request a plan approval unless the user or applicable instructions require it or a material decision remains outside current authority.

## Re-entry

Read the concrete blocker and relevant evidence, not the entire history. Correct only the unsettled part of the contract. A user-supplied decision needs no fresh investigation unless it conflicts with repository facts.

Fix plan-text and metadata defects in the lead context. Determine whether the correction also changes implementation or validation. If so, resume the executor with the corrected decision; a tiny direct fix is allowed, but still needs verification and independent review. If code and evidence are already correct, send only the corrected context to the existing reviewer.

Apply the repeated-failure rule in SKILL.md. Inspect the attempted repair before deciding whether to upgrade execution to `gpt-6.1-sol` high, repair the plan, address the environment, or isolate a smaller complete unit. Keep prior failure evidence. Do not make the user manage routine retries.

The lead delivers the final outcome after execution and review, including material limitations. It does not duplicate the independent review or ask workers to produce extra reports to prove they followed the process.
