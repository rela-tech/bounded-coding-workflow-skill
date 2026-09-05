# Bounded Coding Workflow

`bounded-coding-workflow` is a multi-session protocol for splitting a coding task into deliberate planning, bounded implementation and validation, and optional independent review. It keeps the durable task state in a compact, repository-local handoff file so each worker can continue without relying on prior chat context.

中文版请见 [README.zh-CN.md](README.zh-CN.md)。

## When to use it

Use this workflow when separating uncertainty reduction from implementation and review will lower the total cost of finishing a task. Typical candidates include changes with several files, unclear existing ownership, or meaningful regression risk.

Do not use it for a single-point bug fix, one-file addition, or other local change where the coordination overhead is larger than the work.

## Model routing and delegation

Execution authority and reasoning effort are separate. Provisional defaults: Luna low for mechanical edits; Luna high for decided behavior that still requires concurrency/failure/test reasoning; Terra medium for focused review. Demanding work may be cheaper to execute directly with a capable model. These are hypotheses to calibrate against whole-task cost and completion evidence, not benchmark claims.

PLAN records the difficulty, selections, delegation benefit, and lead re-entry triggers in Routing. Delegate only if the lead can leave ordinary execution/review loops. When the same required-delivery failure recurs after a repair, change configuration or reduce the unit instead of repeatedly adding instructions. Explicit user constraints and the session envelope remain binding. See [PROMPTS.md](PROMPTS.md).

## Roles and state flow

The workflow has three roles:

- `PLAN` is the architect. It uses the smallest relevant repository evidence to establish responsibility boundaries, acceptance criteria, design decisions, scope, validation, and an execution contract that a low-authority worker can follow. Repository investigation is evidence for architecture, not the role's end goal.
- `EXECUTE` is the low-authority implementation worker. It implements only the approved plan using the selected reasoning effort, validates it, and records progress and deviations. It escalates rather than making cross-boundary design choices.
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

## Installation

This repository is a portable Agent Skill bundle: its root `SKILL.md` and the resources it references work unchanged with Codex, Claude Code, GitHub Copilot, and DeepSeek Harness. Clone one shared copy, then link it into the user-level skills directory for each tool you use:

```bash
git clone https://github.com/rela-tech/bounded-coding-workflow-skill.git \
  ~/.agent-skills/bounded-coding-workflow

mkdir -p ~/.codex/skills ~/.claude/skills ~/.agents/skills ~/.dsh/skills
ln -s ~/.agent-skills/bounded-coding-workflow ~/.codex/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.claude/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.agents/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.dsh/skills/bounded-coding-workflow
```

Install only the links for tools you use. The target directories are:

| Harness | Personal, global skill directory |
| --- | --- |
| Codex | `~/.codex/skills/bounded-coding-workflow` |
| Claude Code | `~/.claude/skills/bounded-coding-workflow` |
| GitHub Copilot | `~/.agents/skills/bounded-coding-workflow` (or `~/.copilot/skills/bounded-coding-workflow`) |
| DeepSeek Harness | `~/.dsh/skills/bounded-coding-workflow` |

On Windows, or where symbolic links are unavailable, copy the cloned directory to the relevant target instead. Re-run the copy after updating the clone. Start a new Codex or Copilot session after installation; Claude Code detects changes in existing skill directories live, although creating `~/.claude/skills` itself requires a restart.

The optional `agents/openai.yaml` file is Codex metadata. Other harnesses ignore it; do not remove `SKILL.md`, `assets/`, or `references/`, because they are part of the shared skill bundle.

## Updating and versioning

For a symlink installation, update the shared clone and start a new session in the applicable harness:

```bash
git -C ~/.agent-skills/bounded-coding-workflow pull --ff-only
```

For a copied installation, update the clone and copy the skill directory to each target again. Do not edit the installed copy: make changes in the clone, commit them, and then update or re-copy it.

Use Git tags as the single version source. The current release is `v0.0.3`, which is pre-1.0: compatibility is not guaranteed until `v1.0.0`. Until then, use patch releases for wording or non-behavioral corrections and minor releases for material workflow or protocol changes. After `v1.0.0`, follow semantic versioning: patch for compatible fixes, minor for compatible additions, and major for incompatible protocol changes. Consumers who need reproducible behavior should clone a tag instead of the default branch:

```bash
git clone --branch v0.0.3 --depth 1 \
  https://github.com/rela-tech/bounded-coding-workflow-skill.git \
  ~/.agent-skills/bounded-coding-workflow
```

There is no need to duplicate the version in `SKILL.md`; the release tag is authoritative. Add a GitHub Release with concise notes for every published tag so users can see the change and upgrade guidance.

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
