# Bounded Coding Workflow

`bounded-coding-workflow` 是一个多会话编码协议：它将任务分为审慎规划、机械执行和可选的独立审查。任务的持久状态存放在仓库内简洁的交接文件中，因此各角色无需依赖此前的对话上下文即可继续工作。

English version: [README.md](README.md).

## 适用场景

当把不确定性消解、实现和审查拆开，能够降低任务总成本时，使用本工作流。它适合涉及多个文件、现有职责归属不清，或有明显回归风险的变更。

对单点缺陷、一文件新增或其他局部变更，若协调成本高于实际工作量，则不应使用此工作流。

## 角色与状态流转

工作流包含三个角色：

- `PLAN`：调查最小相关仓库范围，定义验收条件与范围，并产出可由低权限执行者安全遵循的交接文件。
- `EXECUTE`：只实现已获批准的计划，完成验证，并记录进度与偏差。遇到跨边界设计决策时应上报，而不是自行决定。
- `REVIEW`：独立检查实现、验收条件、范围合规性和验证证据。

正常流转：

```text
PLAN -> READY -> EXECUTE -> DONE
PLAN -> READY -> EXECUTE -> IMPLEMENTED -> REVIEW -> DONE
```

`BLOCKED` 会根据最小的未决问题，路由回 `PLAN`、`EXECUTE` 或用户。处于 `READY` 的任务也可以在执行会话之间暂停，而不必标记为阻塞。

## 快速开始

用一个任务专属的交接文件路径启动规划会话：

```text
$bounded-coding-workflow ROLE=PLAN HANDOFF=.agent_worker/tasks/<task>.md

Task:
<原始任务请求>
```

规划者会基于 [`assets/handoff-template.md`](assets/handoff-template.md) 创建交接文件；当剩余工程不确定性只剩局部选择（`U <= 1`）时，将其设为 `status=READY`、`next=EXECUTE`。

以相同的交接文件启动执行者：

```text
$bounded-coding-workflow ROLE=EXECUTE HANDOFF=.agent_worker/tasks/<task>.md
```

当执行满足全部验收条件后，通常会路由至审查：

```text
$bounded-coding-workflow ROLE=REVIEW HANDOFF=.agent_worker/tasks/<task>.md
```

只有在明确不需要独立审查时，才将交接文件中的 `review: skip`；默认值是聚焦式审查 `focused`。

## 交接文件契约

交接文件既是设计记录，也是角色之间的执行契约。其中的稳定部分记录目标、验收条件、事实、决策、非目标、范围、计划、验证方式和风险；易变部分记录当前状态、执行结果、偏差、审查结果、阻塞项和轻量指标。

计划以适合执行会话的粒度分段。每一步都包含仓库相对的 `path:symbol` 锚点、预期行为、边界情况默认值，以及如 `[A1]` 的验收标签。执行者必须停留在 `approved_surface` 内；新增子系统或持久化的 schema／格式变更必须交由用户批准。

## 仓库结构

```text
SKILL.md                    核心协议与不变量
PROMPTS.md                  可复制的启动提示与模型层级建议
assets/handoff-template.md  任务交接文件的起始结构
references/plan.md          规划者角色契约
references/execute.md       执行者角色契约
references/review.md        审查者角色契约
agents/openai.yaml          Agent 元数据
```

## 延伸阅读

先阅读 [`SKILL.md`](SKILL.md)，然后只阅读当前角色对应的一份角色契约：

- [`references/plan.md`](references/plan.md)
- [`references/execute.md`](references/execute.md)
- [`references/review.md`](references/review.md)

[`PROMPTS.md`](PROMPTS.md) 包含推荐的会话启动消息和模型层级映射。
