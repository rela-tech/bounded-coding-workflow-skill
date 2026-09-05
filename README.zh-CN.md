# Bounded Coding Workflow

`bounded-coding-workflow` 是一个多会话编码协议：它将任务分为审慎规划、有边界的实现与验证和可选的独立审查。任务的持久状态存放在仓库内简洁的交接文件中，因此各角色无需依赖此前的对话上下文即可继续工作。

English version: [README.md](README.md).

## 适用场景

当把不确定性消解、实现和审查拆开，能够降低任务总成本时，使用本工作流。它适合涉及多个文件、现有职责归属不清，或有明显回归风险的变更。

对单点缺陷、一文件新增或其他局部变更，若协调成本高于实际工作量，则不应使用此工作流。

## 模型选择与委派

EXECUTE 的低决策权限不等于低推理投入。暂定默认：机械修改用 Luna low；行为已确定但仍涉及并发、失败恢复或有效测试设计，用 Luna high；focused review 用 Terra medium。多个机制相互影响时，可直接由强模型执行。这些是待实测校准的策略，不是模型能力或成本定论。

PLAN 在 Routing 记录执行难度、模型与 effort、委派收益及 lead 再介入条件。只有 lead 能退出日常执行/审查循环时才委派。同类必要交付遗漏在一次修复后再次出现，应改变配置或缩小完整执行单元，不再反复追加提示词。用户明确限制与会话预算仍有效。详见 [PROMPTS.md](PROMPTS.md)。

## 角色与状态流转

工作流包含三个角色：

- `PLAN`：架构师。它以最小必要的仓库证据确定职责边界、验收条件、设计决策、范围、验证方式，以及可由低权限 worker 遵循的执行契约。调查仓库是架构决策的取证手段，不是该角色的最终目的。
- `EXECUTE`：低权限的实现 worker。它按选定的推理投入，只实现并验证已获批准的计划，并记录进度与偏差；遇到跨边界设计决策时应上报，而不是自行决定。
- `REVIEW`：独立验证者（可类比为监理）。它不修改产品代码，只检查实现、验收条件、范围合规性和验证证据。

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

## 安装

本仓库是可移植的 Agent Skill 包：根目录的 `SKILL.md` 及其引用资源可原样用于 Codex、Claude Code、GitHub Copilot 和 DeepSeek Harness。建议只克隆一份源码，再将其链接到你所使用工具的用户级 Skill 目录：

```bash
git clone https://github.com/rela-tech/bounded-coding-workflow-skill.git \
  ~/.agent-skills/bounded-coding-workflow

mkdir -p ~/.codex/skills ~/.claude/skills ~/.agents/skills ~/.dsh/skills
ln -s ~/.agent-skills/bounded-coding-workflow ~/.codex/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.claude/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.agents/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.dsh/skills/bounded-coding-workflow
```

只为实际使用的工具创建对应链接即可。各工具的全局安装位置如下：

| Harness | 个人全局 Skill 目录 |
| --- | --- |
| Codex | `~/.codex/skills/bounded-coding-workflow` |
| Claude Code | `~/.claude/skills/bounded-coding-workflow` |
| GitHub Copilot | `~/.agents/skills/bounded-coding-workflow`（或 `~/.copilot/skills/bounded-coding-workflow`） |
| DeepSeek Harness | `~/.dsh/skills/bounded-coding-workflow` |

在 Windows 或无法使用符号链接的环境中，改为将克隆目录复制到相应目标目录；更新源码后需再次复制。安装后请开启新的 Codex 或 Copilot 会话；Claude Code 会实时侦测既有 Skill 目录中的改动，但如果 `~/.claude/skills` 是新建的顶层目录，仍需重启。

可选文件 `agents/openai.yaml` 是 Codex 元数据，其他 harness 会忽略它。不要移除 `SKILL.md`、`assets/` 或 `references/`，它们都属于共享的 Skill 包。

## 更新与版本

若使用符号链接安装，请更新共享 clone，然后在对应 harness 中开启新会话：

```bash
git -C ~/.agent-skills/bounded-coding-workflow pull --ff-only
```

若使用复制安装，先更新 clone，再将整个 Skill 目录复制到各个目标目录。不要直接编辑安装副本；应在 clone 中修改、提交，然后更新或重新复制。

使用 Git tag 作为唯一版本来源。当前版本为 `v0.0.3`，仍处于 pre-1.0 阶段，在 `v1.0.0` 前不承诺兼容性。此阶段中，措辞或不改变行为的修正发布 patch 版本；工作流或协议的实质性变更发布 minor 版本。达到 `v1.0.0` 后遵循语义化版本：兼容修复使用 patch、兼容新增使用 minor、不兼容协议变更使用 major。需要可复现行为的使用者应 clone 固定 tag，而不是默认分支：

```bash
git clone --branch v0.0.3 --depth 1 \
  https://github.com/rela-tech/bounded-coding-workflow-skill.git \
  ~/.agent-skills/bounded-coding-workflow
```

无需在 `SKILL.md` 中重复维护版本号，发布 tag 是权威来源。每次发布 tag 时请创建带简短说明的 GitHub Release，方便使用者了解变更与升级方式。

## 交接文件契约

交接文件既是架构师的设计记录，也是角色之间的执行契约。其中的稳定部分记录目标、验收条件、事实、决策、非目标、范围、计划、验证方式和风险；易变部分记录当前状态、执行结果、偏差、审查结果、阻塞项和轻量指标。

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
