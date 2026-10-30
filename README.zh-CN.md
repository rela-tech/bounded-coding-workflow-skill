# Bounded Coding Workflow

`bounded-coding-workflow` 用规划、实现和独立审查协作完成编码任务。边界约束的是任务范围与决策权限；会话用于延续工作，不是预算单位。目标是完成任务并验证结果。

English version: [README.md](README.md).

## 角色与模型

| 工作 | 默认模型 | Effort |
| --- | --- | --- |
| PLAN / 调度方的重要决策 | `gpt-6.1-sol` | `high` |
| EXECUTE / 常规修复 | `gpt-6.1-sol` | `low` |
| 截图驱动的 UI 修复、视觉检查与范围明确的文案 | `gpt-6.1-terra` | `medium` |
| 有既有模式的机械性局部实现 | `gpt-6-luna` | `high` |
| 独立 REVIEW | `gpt-6.1-sol` | `medium` |
| 执行失败后的升级 | `gpt-6.1-sol` | `high` |

Terra medium 用于以截图、应用状态或文案为主要依据、行为已经确定的任务；视觉检查不替代代码验证和独立审查。Luna high 用于已有模式可循且验证直接的机械性局部任务。涉及模块联动、较多测试设计或调试时，默认 Sol low；不要只按文件数量判断。修复沿用已记录的配置，升级后不自动降回默认值。

默认仅使用 6 代及之后的模型。模型选择是工作流配置，并非已验证的 ROI 排名。审查必须使用独立于规划和实现的 worker 上下文；同一会话改角色名不构成独立审查。

## 调度与持续推进

适用于设计决策、实现和验证分工能帮助可靠完成的任务。小型局部修改可直接处理。调度方负责可执行的计划、真实决策、失败升级和最终交付；worker 负责具体实现和验证。不要重复审查、反复补表，或只为切换阶段创建会话。

没有默认的 `k/N` 会话硬上限，也不要求按 session 切计划。在授权范围内持续完成逻辑里程碑，遇到上下文限制则保存进度、恢复已有 worker。用户明确指定的预算仍有效。handoff 记录决策、进度和证据；指标与不适用的字段可省略。

同一实质问题修复一次后仍失败，或连续两次修复未推动必要验收，由调度方检查原因：执行能力不足升级到 Sol 6.1 high；计划错误修正计划；环境问题处理依赖；工作耦合过强则拆出更小的可验证单元。换标签、重启或换模型不清除失败历史。普通调试的红测试和格式问题不计入升级次数。

正常流转为 `PLAN -> EXECUTE -> REVIEW -> DONE`。默认 focused review；仅在明确 `review: skip` 时跳过。阶段结束不是任务完成；调度方持续收取结果、安排修复和复查，直到交付或遇到真实阻塞。

可并行任务按依赖、验收子集和写入归属拆分，每个 worker 使用独立的子 handoff；共享文件和应用会话的写入串行处理。调度方维护父任务，指定集成执行者完成组合验收后再独立审查。恢复前检查已有 worker，避免重复写入。详见 [PROMPTS.md](PROMPTS.md#dependency-aware-orchestration)。

模型选择依据已于 2026-10-30 核对的[官方指南](https://developers.openai.com/api/docs/guides/model-selection)，effort 属于本工作流策略，尚非实测最优值。深度审查可用 Sol high；Sol high 经调整策略仍存在推理困难时，才考虑 Astra high。启动与续做必须显式传入已记录的模型和 effort。

## 快速开始

```text
$bounded-coding-workflow ROLE=PLAN HANDOFF=.agent_worker/tasks/<task>.md

Task:
<原始任务请求>
```

调度方使用同一 handoff 为 worker 指定 `ROLE=EXECUTE` 或 `ROLE=REVIEW`，并按上表选择模型。模板见 [assets/handoff-template.md](assets/handoff-template.md)，启动方式见 [PROMPTS.md](PROMPTS.md)。

## 安装

一份仓库服务所有 harness；只有 dispatch 层与 harness 相关。

| 层 | 文件 | 可移植性 |
| --- | --- | --- |
| 协议 | `SKILL.md`、`references/*.md`、`assets/handoff-template.md` | 与 harness 无关 |
| 路由策略 | `PROMPTS.md`（启动提示、模型路由、续做机制） | 与 harness 无关 |
| Dispatch | `PROMPTS.md` 的 dispatch 段、`assets/*.sh` | 取决于 lead 的 harness |

随附两条 dispatch 路径，按 **lead** 的能力选：

- **路径 A —— lead 所在 harness 自带 worker 派生。** 不需要任何脚本。仍有两项义务，因为它们是协议而非机制：提供角色与 handoff；分别记录 executor 和 reviewer 的会话 id，以便恢复。
- **路径 B —— DSH lead 驱动 Codex CLI worker。** 脚本化路径，也是本仓库唯一端到端验证过的路径。

```bash
git clone https://github.com/rela-tech/bounded-coding-workflow-skill.git \
  ~/.agent-skills/bounded-coding-workflow

mkdir -p ~/.dsh/skills ~/.codex/skills ~/.claude/skills ~/.agents/skills
ln -s ~/.agent-skills/bounded-coding-workflow ~/.dsh/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.codex/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.claude/skills/bounded-coding-workflow
ln -s ~/.agent-skills/bounded-coding-workflow ~/.agents/skills/bounded-coding-workflow
```

只为实际使用的 harness 创建链接：

| Harness | 个人全局 Skill 目录 |
| --- | --- |
| DeepSeek Harness | `~/.dsh/skills/bounded-coding-workflow` |
| Codex | `~/.codex/skills/bounded-coding-workflow` |
| Claude Code | `~/.claude/skills/bounded-coding-workflow` |
| GitHub Copilot | `~/.agents/skills/bounded-coding-workflow` |

路径 B 的依赖（路径 A 都不需要）：

| 依赖 | 原因 |
| --- | --- |
| `codex` 在 `PATH` 上且已登录 | `assets/launch-worker.sh` 会 spawn `codex exec`；模型与 effort 来自 Routing，凭证来自 Codex 安装 |
| lead 会话的 workspace 就是目标仓库 | handoff 路径是仓库相对路径，Plan 锚点是 `path:symbol` |
| 允许启动 CLI 的权限 preset | `workspace-write` 下 CLI 无法初始化自己的状态目录；审批提示被禁用时，被拒绝的提权无法补救 |

无法使用符号链接时，改为复制克隆目录，并在更新源码后重新复制。安装或更新后请在对应 harness 中开启新会话。

可选文件 `agents/openai.yaml` 是 Codex 元数据。不要移除 `SKILL.md`、`assets/` 或 `references/`。

## 更新与版本

若使用符号链接安装，请更新共享 clone，然后在使用的 harness 中开启新会话：

```bash
git -C ~/.agent-skills/bounded-coding-workflow pull --ff-only
```

若使用复制安装，先更新 clone，再将整个 Skill 目录复制到各个目标目录。不要直接编辑安装副本；应在 clone 中修改、提交，然后更新或重新复制。

### 仓库内自带的副本

仓库可能提交一份自带的 Skill 副本（例如放在 `.agents/skills/`）。只要派发提示用仓库相对路径引用它，**worker 实际读到的就是这份**，所以它绝不能落后——落后的副本会静默地把这里的每条规则回滚；随后 lead 会如实报告缺失并绕开，看起来像 agent 故障，其实不是。

```bash
assets/sync-install.sh <repo>/.agents/skills/bounded-coding-workflow          # 同步
assets/sync-install.sh <repo>/.agents/skills/bounded-coding-workflow --check  # 校验，有分歧时非零退出
```

`--check` 是唯一可靠的防线；提交更新或切发布前请先跑它。

使用 Git tag 作为唯一版本来源。当前版本为 `v0.0.3`，仍处于 pre-1.0 阶段，在 `v1.0.0` 前不承诺兼容性。此阶段中，措辞或不改变行为的修正发布 patch 版本；工作流或协议的实质性变更发布 minor 版本。达到 `v1.0.0` 后遵循语义化版本：兼容修复使用 patch、兼容新增使用 minor、不兼容协议变更使用 major。需要可复现行为的使用者应 clone 固定 tag，而不是默认分支：

```bash
git clone --branch v0.0.3 --depth 1 \
  https://github.com/rela-tech/bounded-coding-workflow-skill.git \
  ~/.agent-skills/bounded-coding-workflow
```

无需在 `SKILL.md` 中重复维护版本号，发布 tag 是权威来源。每次发布 tag 时请创建带简短说明的 GitHub Release，方便使用者了解变更与升级方式。

## 交接文件契约

交接文件保留目标、验收标准、关键设计决策、授权范围、计划、验证证据与当前进度。按工作需要更新，省略无用字段，不要求每轮指标或会话计数。逻辑里程碑不绑定会话。

执行者可以读取必要的相邻代码并自主处理实现细节；实质性行为、架构或范围变化交由调度方处理。已有用户授权无需重复批准。旧 handoff 可以直接续做，无需单独格式迁移；旧协议的会话估计不再阻止继续，但用户明确规定的限制仍须遵守。

## 仓库结构

```text
SKILL.md                    核心协议与不变量
PROMPTS.md                  可复制的启动提示与模型层级建议
assets/handoff-template.md  任务交接文件的起始结构
assets/launch-worker.sh     启动 headless CLI worker 并记录其线程 id
assets/resume-worker.sh     复用已记录的 worker 线程继续执行，而不是重新启动
assets/sync-install.sh      保持自带副本字节一致，或校验它
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
