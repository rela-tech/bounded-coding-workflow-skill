# Routing and worker prompts

Use the model table in [SKILL.md](SKILL.md): PLAN `gpt-6.1-sol` high, default EXECUTE `gpt-6.1-sol` low (clearly defined local tasks: `gpt-6-luna` high), independent REVIEW `gpt-6.1-sol` medium. Repeated execution failures escalate to `gpt-6.1-sol` high as described there. Use generation 6 or later; do not fall back to 5.x defaults. Verify availability on the actual launcher rather than assuming every harness supports the same models.

## Lead dispatch

Prefer native worker delegation when it supports the requested models and efforts. Otherwise use the CLI launchers where available and permitted. Pass the role, handoff, and only useful new context. Record executor and reviewer IDs separately so both can resume; review must have its own context.

Keep the task moving after dispatch. Use the harness's completion notification and wait/collect mechanism; where notifications are unavailable, use bounded polling. Do not end the workflow merely because a worker is running. Do not repeatedly read an unchanged event log. On completion, read the concise final message and relevant handoff changes, then route the next productive action.

Reuse the existing executor for continuation and ordinary review repairs. An upgrade may resume the same worker with a different model if supported; otherwise launch the upgraded worker with the current handoff and repair evidence. Resume the independent reviewer for rechecks. New sessions are tools for context and model selection, not milestones or accounting units.

Resolve which installed skill the worker will load. When the project intentionally vendors a copy, `assets/sync-install.sh <target-skill-dir>` synchronizes it and `--check` detects divergence. Do not create or synchronize extra installations unless needed by this task.

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
Pass the Routing model and effort explicitly. Their role-aware defaults are Sol 6.1 low for execute labels, Sol 6.1 medium for review labels, and Sol 6.1 high for plan labels. Local Luna tasks and escalated execution always supply the recorded model AND effort explicitly, including on resume; omitted arguments use role defaults, not the previous worker configuration.

```bash
assets/launch-worker.sh <repo-root> <handoff-path> execute <prompt-file> gpt-6.1-sol low
assets/launch-worker.sh <repo-root> <handoff-path> review <prompt-file> gpt-6.1-sol medium
assets/resume-worker.sh <repo-root> <handoff-path> execute <repair-prompt-file> gpt-6.1-sol high
```

Run the launcher as a tracked job when the harness requires it for completion notifications. It remains attached to the worker until exit and records the thread ID beside the handoff in `<handoff>.workers`. The registry's role key distinguishes executor and reviewer; resume using the original role key. Record the matching ID in Routing when it is available. Read the final-message file first; inspect event output only for a concrete failure or missing state.

The launcher sets the repository working directory and workspace-write sandbox. Resume changes directory first and uses `-c sandbox_mode=workspace-write` because its CLI shape differs from initial launch. Verify compatibility with the installed CLI when dispatch fails; do not assume all versions have identical flags. The launcher needs permission to initialize CLI state, and reviewers need shell access for verification. Do not silently bypass permission failures.

Worker accounting may be useful when already available, but collecting or formatting token metrics is not part of task acceptance. Evaluate routing by completion quality, progress, and repair behavior; model price alone does not establish ROI.
