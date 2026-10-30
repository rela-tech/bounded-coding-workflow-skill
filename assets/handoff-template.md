---
protocol: bounded-coding/v3
task: <slug>
status: PLANNING
next: PLAN
base: <git-rev>
review: focused
---

# Goal
<intended outcome and material constraints>

# Acceptance
- A1: <condition/action -> observable required outcome>

# Decisions and scope
- <affected responsibilities and existing mechanisms to reuse; repo-relative anchors>
- <material behavior/contract decisions and rationale>
- <non-goals and any scope approval actually needed>

# Routing
mode: delegated
planner: gpt-6.1-sol / high
executor: gpt-6.1-sol / low
# Terra medium: screen-driven/scoped prose; Luna high: mechanical local work.
# Sol high: reasoning escalation; preserve recorded upgrades on resume.
reviewer: gpt-6.1-sol / medium
launcher: <native delegation or CLI>
executor_session: none
reviewer_session: none
# Record explicit user limits only when provided. No default session envelope.

<!-- Optional for parallel work; parent list is lead-owned. Each writer uses a child handoff.
# Work items
| ID | Depends on | Acceptance | Writable scope | Owner/session | Model/effort | Status | Child handoff/evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
Record one integration owner and combined verification before parent REVIEW.
-->

# Plan
1. `<path>:<symbol-or-location>` [A1] — <behavior and material edge cases>

# Validate
- [A1] `<command or observation>` — <outcome it proves and relevant failure case>

# Execution
progress: pending
validation: pending
# Required acceptance -> actual test/assertion/observation -> result.
# Add deviations and unresolved failure history only when meaningful:
# underlying issue -> attempted repair -> observed result -> routing change.

# Review
result: pending
# Findings retain their identifiers through repair and recheck.

# Current Blocker
none

<!-- Optional: material risks, external dependencies, or already-available metrics.
Omit unused sections. Update on meaningful progress, handoff, or interruption;
do not maintain per-turn metrics or session counters. -->
