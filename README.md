# Bounded Coding Workflow

`bounded-coding-workflow` is a multi-session protocol for splitting a coding task into deliberate planning, mechanical execution, and optional independent review. It keeps the durable task state in a compact, repository-local handoff file so each worker can continue without relying on prior chat context.

中文版请见 [README.zh-CN.md](README.zh-CN.md)。

## When to use it

Use this workflow when separating uncertainty reduction from implementation and review will lower the total cost of finishing a task. Typical candidates include changes with several files, unclear existing ownership, or meaningful regression risk.

Do not use it for a single-point bug fix, one-file addition, or other local change where the coordination overhead is larger than the work.

## Roles and state flow

The workflow has three roles:

- `PLAN` is the architect. It uses the smallest relevant repository evidence to establish responsibility boundaries, acceptance criteria, design decisions, scope, validation, and an execution contract that a low-authority worker can follow. Repository investigation is evidence for architecture, not the role's end goal.
- `EXECUTE` is the low-authority implementation worker. It mechanically implements only the approved plan, validates it, and records progress and deviations. It escalates rather than making cross-boundary design choices.
- `REVIEW` is the independent verifier: it checks the implementation, acceptance criteria, scope compliance, and validation evidence without modifying product code.

Normal flow:

```text
PLAN -> READY -> EXECUTE -> DONE
PLAN -> READY -> EXECUTE -> IMPLEMENTED -> REVIEW -> DONE
```

`BLOCKED` routes the work back to `PLAN`, `EXECUTE`, or the user according to the smallest unresolved decision. `READY` work may also pause between executor sessions without becoming blocked.

## Quick start

Start a planning session with a task-specific handoff path:

```text
$bounded-coding-workflow ROLE=PLAN HANDOFF=.agent_worker/tasks/<task>.md

Task:
<original task request>
```

The planner creates the handoff from [`assets/handoff-template.md`](assets/handoff-template.md), then sets it to `status=READY` and `next=EXECUTE` once remaining engineering uncertainty is local (`U <= 1`).

Launch the executor with the same handoff:

```text
$bounded-coding-workflow ROLE=EXECUTE HANDOFF=.agent_worker/tasks/<task>.md
```

When execution satisfies every acceptance criterion, it normally routes to review:

```text
$bounded-coding-workflow ROLE=REVIEW HANDOFF=.agent_worker/tasks/<task>.md
```

Set `review: skip` in the handoff only when independent review is explicitly unnecessary; otherwise the default is `focused` review.

## Handoff contract

The handoff is both the architect's design record and the execution contract between workers. Its stable sections record the goal, acceptance criteria, facts, decisions, non-goals, scope, plan, validation approach, and risks. Its volatile sections carry the current status, execution results, deviations, review result, blocker, and lightweight metrics.

The plan is segmented into executor-sized units and each step includes a repository-relative `path:symbol` anchor, intended behavior, edge-case default, and an acceptance tag such as `[A1]`. Executors must stay within `approved_surface`; a new subsystem or durable schema/format change always routes to the user for approval.

## Repository layout

```text
SKILL.md                    Core protocol and invariants
PROMPTS.md                  Copyable launch prompts and model-tier guidance
assets/handoff-template.md  Starting structure for a task handoff
references/plan.md          Planner role contract
references/execute.md       Executor role contract
references/review.md        Reviewer role contract
agents/openai.yaml          Agent metadata
```

## Further reading

Read [`SKILL.md`](SKILL.md) first, then read exactly one role contract for the active role:

- [`references/plan.md`](references/plan.md)
- [`references/execute.md`](references/execute.md)
- [`references/review.md`](references/review.md)

[`PROMPTS.md`](PROMPTS.md) contains the recommended session launch messages and model-tier mapping.
