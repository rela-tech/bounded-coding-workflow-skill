# Bounded Coding Workflow

`bounded-coding-workflow` coordinates planning, implementation, and independent review to finish coding tasks with verified results. Boundaries constrain scope and decision authority; sessions support continuation rather than define a work budget.

中文版请见 [README.zh-CN.md](README.zh-CN.md)。

## Roles and models

| Work | Default model | Effort |
| --- | --- | --- |
| PLAN / substantive lead decisions | `gpt-6.1-sol` | `high` |
| EXECUTE / ordinary repairs | `gpt-6.1-sol` | `low` |
| Clearly defined local implementation | `gpt-6-luna` | `high` |
| Independent REVIEW | `gpt-6.1-sol` | `medium` |
| Escalated execution | `gpt-6.1-sol` | `high` |

Use Luna high only for clearly defined local work with established patterns and straightforward verification. Default to Sol low when implementation spans interacting modules or requires substantial test design or debugging. Choose based on the remaining work, not file count alone. Resume repairs at the recorded selection; do not automatically downgrade after escalation.

Defaults use generation 6 or later. These are workflow choices, not measured ROI rankings. Review needs a worker context independent of planning and implementation; changing the role label in the same context is not independent review.

## Dispatch and continuation

Use this workflow when separating decisions, implementation, and verification helps reliable completion. Small local changes can be handled directly. The lead owns a usable plan, real decisions, failure escalation, and final delivery; workers own implementation and verification. Avoid duplicate reviews, repeated paperwork, and sessions created merely for phase transitions.

There is no default `k/N` session cap or session-sized plan segmentation. Work through logical milestones and resume workers across context limits within the authorized task. Explicit user budgets remain binding. Keep decisions, progress, and evidence in the handoff; metrics and unused fields are optional.

If the same substantive issue persists after one repair, or two successive repairs make no meaningful acceptance progress, the lead diagnoses the cause: upgrade execution failures to Sol 6.1 high, correct plan defects, resolve environment dependencies, or isolate a smaller verifiable unit. Renaming an issue, restarting, or changing models does not clear its history. Normal red tests during development and formatting issues do not count toward escalation.

Normal flow is `PLAN -> EXECUTE -> REVIEW -> DONE`. Review defaults to focused and is omitted only with explicit `review: skip`. A phase ending is not task completion: the lead collects results, routes repairs and rechecks, and continues until delivery or a real blocker.

## Quick start

```text
$bounded-coding-workflow ROLE=PLAN HANDOFF=.agent_worker/tasks/<task>.md

Task:
<original task request>
```

The lead dispatches workers with the same handoff and `ROLE=EXECUTE` or `ROLE=REVIEW`, using the model table above. See [assets/handoff-template.md](assets/handoff-template.md) and [PROMPTS.md](PROMPTS.md).

## Installation

One repository serves every harness; only the dispatch layer is harness-specific.

| Layer | Files | Portability |
| --- | --- | --- |
| Protocol | `SKILL.md`, `references/*.md`, `assets/handoff-template.md` | harness-neutral |
| Routing policy | `PROMPTS.md` (launch prompts, model routing, continuation) | harness-neutral |
| Dispatch | `PROMPTS.md` dispatch sections, `assets/*.sh` | per lead harness |

Two dispatch paths ship, and you pick by what the **lead** can do:

- **Path A — the lead's harness spawns its own workers.** No script applies. Two obligations remain because they are protocol: provide the role and handoff, and record executor and reviewer session IDs separately for continuation.
- **Path B — a DSH lead driving Codex CLI workers.** The scripted path, and the only one verified end to end here.

```bash
git clone https://github.com/rela-tech/bounded-coding-workflow-skill.git \
  ~/.agent-skills/bounded-coding-workflow

mkdir -p ~/.dsh/skills ~/.codex/skills ~/.claude/skills ~/.agents/skills
ln -s ~/.agent-skills/bounded-coding-workflow ~/.dsh/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.codex/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.claude/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.agents/skills/bounded-coding-workflow
```

Install only the links for harnesses you use:

| Harness | Personal, global skill directory |
| --- | --- |
| DeepSeek Harness | `~/.dsh/skills/bounded-coding-workflow` |
| Codex | `~/.codex/skills/bounded-coding-workflow` |
| Claude Code | `~/.claude/skills/bounded-coding-workflow` |
| GitHub Copilot | `~/.agents/skills/bounded-coding-workflow` |

Path B requirements — nothing here is needed for path A:

| Requirement | Why |
| --- | --- |
| `codex` on `PATH`, signed in | `assets/launch-worker.sh` spawns `codex exec`; Routing supplies the model and effort, the Codex install supplies credentials |
| The lead session's workspace is the repository under work | handoff paths are repo-relative and Plan anchors are `path:symbol` |
| A permission preset that lets the launcher run | under `workspace-write` the CLI cannot initialize its own state directory, and with approval prompts disabled a denied escalation cannot be recovered |

Where symbolic links are unavailable, copy the cloned directory instead and re-copy it after updating the clone. Start a new session in that harness after installing or updating.

The optional `agents/openai.yaml` is Codex metadata; do not remove `SKILL.md`, `assets/`, or `references/`.

## Updating and versioning

For a symlink installation, update the shared clone and start a new session in the harness you use:

```bash
git -C ~/.agent-skills/bounded-coding-workflow pull --ff-only
```

For a copied installation, update the clone and copy the skill directory to each target again. Do not edit the installed copy: make changes in the clone, commit them, and then update or re-copy it.

### Vendored copies inside a repository

A repository may commit its own copy of this skill (for example under `.agents/skills/`). That copy is what its workers read whenever a launch prompt names it by a repo-relative path, so it must not lag — a stale copy silently reverts every rule change, and the lead then reports the missing pieces in good faith, which reads as an agent failure and is not one.

```bash
assets/sync-install.sh <repo>/.agents/skills/bounded-coding-workflow          # sync
assets/sync-install.sh <repo>/.agents/skills/bounded-coding-workflow --check  # verify, non-zero on divergence
```

`--check` is the only reliable guard; run it before committing an update or cutting a release.

Use Git tags as the single version source. The current release is `v0.0.3`, which is pre-1.0: compatibility is not guaranteed until `v1.0.0`. Until then, use patch releases for wording or non-behavioral corrections and minor releases for material workflow or protocol changes. After `v1.0.0`, follow semantic versioning: patch for compatible fixes, minor for compatible additions, and major for incompatible protocol changes. Consumers who need reproducible behavior should clone a tag instead of the default branch:

```bash
git clone --branch v0.0.3 --depth 1 \
  https://github.com/rela-tech/bounded-coding-workflow-skill.git \
  ~/.agent-skills/bounded-coding-workflow
```

There is no need to duplicate the version in `SKILL.md`; the release tag is authoritative. Add a GitHub Release with concise notes for every published tag so users can see the change and upgrade guidance.

## Handoff contract

The handoff preserves goals, acceptance, material decisions, authorized scope, planned work, verification evidence, and current progress. Update it when useful; omit unused fields. No per-turn metrics or session counters are required, and logical milestones do not map to sessions.

Executors may inspect necessary adjacent code and choose local implementation details. Material behavior, architecture, or scope changes return to the lead. Existing user authorization does not require renewed approval. Continue old handoffs without a separate format migration: protocol-generated session estimates no longer block progress, while explicit user limits remain binding.

## Repository layout

```text
SKILL.md                    Core protocol and invariants
PROMPTS.md                  Copyable launch prompts and model-tier guidance
assets/handoff-template.md  Starting structure for a task handoff
assets/launch-worker.sh     Launch a headless CLI worker and record its thread id
assets/resume-worker.sh     Continue a recorded worker thread instead of restarting it
assets/sync-install.sh      Keep a vendored copy byte-identical, or check it
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
