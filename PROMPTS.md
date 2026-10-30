# Routing and worker prompts

Use the defaults in [SKILL.md](SKILL.md). Route by the remaining task’s evidence, ambiguity, coupling, and verification needs, not model recency or file count.

## Task-based model routing

| Task characteristics | Selection | Boundary |
| --- | --- | --- |
| Product/architecture decisions and coordination | Sol 6.1 / high | Lead retains acceptance and integration responsibility |
| Interacting modules, test design, ordinary debugging | Sol 6.1 / low | Increase to high for demonstrated reasoning difficulty |
| Screenshot-driven UI repair, app interaction, visual inspection, scoped documentation | Terra 6.1 / medium | Decided behavior, observable outcome; code checks still required |
| Mechanical edits or repetitive local implementation | Luna 6 / high | Established pattern, clear contract, straightforward checks |
| Independent semantic review | Sol 6.1 / medium | Separate context; use high for concrete deep-review risk |
| Unresolved architecture or reasoning after Sol high and a changed approach | Astra 6 / high | Evidence-backed escalation, subject to user restrictions and availability |

These are starting policies, not a measured quality or cost ranking. Terra is a specialized route, not a universal replacement for Sol or Luna. A scoped code fix can use Terra when visual/app evidence dominates; an ambiguous cross-module defect stays with Sol. Choose one model for a coherent work item; do not add a worker just to use every model.

Official guidance checked 2026-10-30: [model selection](https://developers.openai.com/api/docs/guides/model-selection) positions Terra for visual reasoning, computer use, concise writing, and scoped code fixes; [Work/Codex models](https://learn.chatgpt.com/docs/models) describes Sol for sustained work and Astra for the most demanding tasks. The effort settings above are this workflow’s choices, not official task benchmarks. Recheck official guidance when changing this policy; do not assume API pricing or effort settings apply unchanged to a Codex subscription or launcher.

Verify the actual launcher’s model and effort support. Honor user pins. If a specialized model is unavailable, report and record a supported alternative (normally Sol for Terra/Luna work) within existing authorization; do not silently substitute or bypass a pin. Keep the recorded selection for continuation and repair. Use the failure classification in SKILL.md before escalating; environment failures do not justify a stronger model. Sol high is the first reasoning escalation; Astra is reserved for residual difficulty, not automatic retries.

## Lead dispatch

Prefer native worker delegation when it supports the requested models and efforts. Otherwise use the CLI launchers where available and permitted. Pass the role, handoff, and only useful new context. Record executor and reviewer IDs separately so both can resume; review must have its own context.

Keep the task moving after dispatch. Use the harness's completion notification and wait/collect mechanism; where notifications are unavailable, use bounded polling. Do not end the workflow merely because a worker is running. Do not repeatedly read an unchanged event log. On completion, read the concise final message and relevant handoff changes, then route the next productive action.

Reuse the existing executor for continuation and ordinary review repairs. An upgrade may resume the same worker with a different model if supported; otherwise launch the upgraded worker with the current handoff and repair evidence. Resume the independent reviewer for rechecks. New sessions are tools for context and model selection, not milestones or accounting units.

Resolve which installed skill the worker will load. When the project intentionally vendors a copy, `assets/sync-install.sh <target-skill-dir>` synchronizes it and `--check` detects divergence. Do not create or synchronize extra installations unless needed by this task.

## Dependency-aware orchestration

Use a single executor unless independent work can shorten delivery without duplicating investigation or creating competing writers. When splitting helps:

1. Keep a small work-item list in the parent handoff: ID, dependencies, acceptance IDs, writable scope, owner, model/effort, status, and evidence/result location. Use stable IDs across retries. Omit the list for a single work item.
2. Dispatch only items whose dependencies have accepted outputs available in the dependent worker’s checkout. For isolated checkouts, the integrator transfers accepted changes before dependent work starts. Respect available worker slots and user budgets; do not fill slots for their own sake. Keep the lead available to collect results and resolve decisions.
3. Give each concurrent writer disjoint files or an isolated checkout with a designated integrator. Shared contracts, lockfiles, generated output, mutable app sessions, and test databases count as shared resources: serialize their mutation. Read-only research may run alongside implementation but must identify the revision inspected.
4. Give each parallel worker a separate child handoff and result location. Only the lead updates the parent work-item list. Children reference the parent’s decisions and their acceptance subset; they do not edit the parent or launch nested workers. With CLI dispatch, use a separate child handoff per concurrent worker to avoid registry/output collisions. Never resume one session concurrently.
5. A worker result includes work-item ID, inspected base/revision, changed files, observed checks, unresolved findings, and next action. The lead accepts the result against its contract before unblocking dependents; a worker saying “done” is insufficient. A failed item blocks its dependents, not unrelated ready work.
6. Assign one executor to integrate outputs and validate combined acceptance. Individual passes cannot establish integrated correctness. Keep the parent READY / EXECUTE until combined acceptance passes, then route it to IMPLEMENTED / REVIEW. Child IMPLEMENTED means only its acceptance subset passed; it does not trigger a separate review or complete the parent. Preserve failure history across child and integration repairs.

Before interruption, record active session IDs and next actions. On recovery, inspect worker state and existing outputs before relaunching; do not duplicate a still-running writer. When a user decision changes a contract, pause affected writers, update the contract, and invalidate only dependent outputs/evidence that the change makes stale. Resume unaffected work.

For repeated tasks, compare routing using observed acceptance, material repair attempts, elapsed time, and cost only when available. Record evidence of recurring mismatches before changing defaults; do not claim Terra savings without comparable completed work.

## Initial PLAN

```text
$bounded-coding-workflow ROLE=PLAN HANDOFF=.agent_worker/tasks/<task>.md

Task:
<original task>

Resolve material decisions and acceptance, then coordinate execution and independent
review through completion. Keep the handoff proportional to the work.
```

## EXECUTE / continuation / repair

```text
$bounded-coding-workflow ROLE=EXECUTE HANDOFF=.agent_worker/tasks/<task>.md

Implement and validate the agreed task. Read adjacent code and tests as needed;
follow applicable repository instructions. Continue through logical milestones.
Update progress and evidence before returning. If a repair repeatedly fails,
record the attempts and route to the lead for a changed approach.

New context or review findings, if any:
<only the concrete correction or next action>
```

## Independent REVIEW

```text
$bounded-coding-workflow ROLE=REVIEW HANDOFF=.agent_worker/tasks/<task>.md

Independently inspect the actual change and verify required behavior. Run relevant
validation, aggregate actionable findings, and record observed results. Rechecks
focus on unresolved findings and the repair diff.
```

## CLI path

The scripts accept `<repo-root> <handoff-path> <role> <prompt-file> [model] [effort]`.
Pass the Routing model and effort explicitly. Their role-aware defaults are Sol 6.1 low for execute labels, Sol 6.1 medium for review labels, and Sol 6.1 high for plan labels. Terra tasks, local Luna tasks, deep reviews, and escalated execution always supply the recorded model AND effort explicitly, including on resume; omitted arguments use role defaults, not the previous worker configuration.

```bash
assets/launch-worker.sh <repo-root> <handoff-path> execute <prompt-file> gpt-6.1-sol low
assets/launch-worker.sh <repo-root> <child-handoff-path> execute-ui <ui-prompt-file> gpt-6.1-terra medium
assets/launch-worker.sh <repo-root> <handoff-path> review <prompt-file> gpt-6.1-sol medium
assets/resume-worker.sh <repo-root> <handoff-path> execute <repair-prompt-file> gpt-6.1-sol high
```

Run the launcher as a tracked job when the harness requires it for completion notifications. It remains attached to the worker until exit and records the thread ID beside the handoff in `<handoff>.workers`. The registry's role key distinguishes executor and reviewer; resume using the original role key. Record the matching ID in Routing when it is available. Read the final-message file first; inspect event output only for a concrete failure or missing state.

The launcher sets the repository working directory and workspace-write sandbox. Resume changes directory first and uses `-c sandbox_mode=workspace-write` because its CLI shape differs from initial launch. Verify compatibility with the installed CLI when dispatch fails; do not assume all versions have identical flags. The launcher needs permission to initialize CLI state, and reviewers need shell access for verification. Do not silently bypass permission failures.

Worker accounting may be useful when already available, but collecting or formatting token metrics is not part of task acceptance. Evaluate routing by completion quality, progress, and repair behavior; model price alone does not establish ROI.
