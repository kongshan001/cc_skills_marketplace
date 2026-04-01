---
name: cc-skill-evolver
description: |
  基于 autoresearch 实验循环思路，持续迭代优化已有的 Claude Code skill。
  以 skill-creator 为评估引擎，复用其 evals.json、subagent 测试、grading、
  eval viewer、description 优化等成熟功能，在其之上叠加 autoresearch 的
  单变量实验循环（修改 → 测试 → 保留/回滚 → 重复）。
  当用户想要改进、优化、迭代一个已有的 skill 时使用此技能。
  适用场景：用户说"优化这个 skill"、"迭代改进 skill"、"让 skill 更好"、
  "skill 效果不好需要改进"、"帮我调优 skill"、"运行 skill 进化循环"，
  或者用户提到 skill 的任何质量问题、触发不准、输出不理想等问题。
  即使用户没有明确说"进化"或"迭代"，只要涉及 skill 质量改进就应该使用此技能。
---

# cc-skill-evolver

基于 [karpathy/autoresearch](https://github.com/karpathy/autoresearch) 的实验循环思路，对已有的 Claude Code skill 进行持续迭代优化。

**核心定位**：cc-skill-evolver 是 autoresearch 循环的**编排层**，**skill-creator 是评估执行引擎**。不重新造轮子。

```
┌─────────────────────────────────────────┐
│  cc-skill-evolver（编排层）               │
│  ├── autoresearch 实验循环               │
│  ├── 单变量实验策略                      │
│  ├── git 驱动的 keep/discard             │
│  ├── results.tsv 追踪                   │
│  ├── 简单性准则                          │
│  └── 收敛检测                            │
├───────────── 调用 ──────────────────────┤
│  skill-creator（评估引擎）               │
│  ├── evals.json 测试用例管理             │
│  ├── subagent 并行测试执行               │
│  ├── grader 自动评分                     │
│  ├── benchmark 聚合                      │
│  ├── eval viewer 人工审查界面            │
│  └── description 优化循环                │
└─────────────────────────────────────────┘
```

核心理念：**修改 → 调用 skill-creator 测试 → 比较结果 → 保留或回滚 → 重复**。

## 依赖

本 skill 需要以下工具已安装：
- **skill-creator** skill — 作为评估引擎使用
- **git** — 版本管理和 keep/discard 决策

## 设计哲学

从 autoresearch 中提取核心原则迁移到 skill 迭代场景：

| Autoresearch | Skill Evolver |
|---|---|
| `train.py`（唯一修改目标） | `SKILL.md` + `references/` |
| `prepare.py`（只读基准） | `eval/` 错误案例 + `evals/evals.json` |
| `val_bpb`（量化指标） | skill-creator benchmark 通过率 |
| `results.tsv`（实验日志） | skill 的 `results.tsv` |
| git commit / reset | 版本管理 keep/discard |
| 单变量实验 | 每次只改一个维度 |
| 简单性准则 | 更简洁的 skill 版本优先 |

## Phase 0：环境准备

### 0.1 确定目标 skill

询问用户要优化哪个 skill：
- **单个 skill**：`优化 py-doc-generator 这个 skill`
- **多个 skill**：`优化所有 skill 的触发准确度`（每个 skill 独立迭代）

如果没有指定，列出当前项目中可用的 skill 供用户选择。

### 0.2 检查评估基础设施

目标 skill 需要评估基准。检查以下任一是否存在：

**格式 A：错误案例（eval/ 目录）**

```
target-skill/
├── eval/
│   ├── error_001.md          # 场景 + 实际行为 + 期望行为
│   ├── error_001_fix.md      # 详细正确输出（盲评时才读取）
│   ├── error_002.md
│   ├── error_002_fix.md
│   └── ...
```

**格式 B：skill-creator evals.json（evals/ 目录）**

```
target-skill/
├── evals/
│   └── evals.json            # skill-creator 标准格式
```

两种格式可以共存，会合并使用。

### 0.3 引导创建评估基准

如果两种格式都不存在，引导用户创建：

> "要优化这个 skill，需要先建立评估基准。有两种方式：
>
> **方式一（推荐）**：在 `eval/` 目录下创建错误案例文件：
> - `error_001.md`：描述一个 skill 处理不当的具体场景（含实际行为和期望行为）
> - `error_001_fix.md`：描述期望的正确输出
> - 建议至少 3 个错误案例
>
> **方式二**：在 `evals/` 目录下创建 `evals.json`，遵循 skill-creator 标准：
> - 每个 eval 包含 prompt、expected_output、assertions
> - 你可以说'帮我生成 evals.json'，我会引导你完成"

**错误案例编写指南**：

error_x.md 应该包含：
- **场景描述**：具体的用户输入、项目上下文、文件结构等
- **实际行为**：skill 当前的错误输出（具体示例）
- **期望行为**：概述正确的处理方式

error_x_fix.md 应该包含：
- **正确输出**：完整的期望输出（用于评估对比，盲评时才读取）
- **关键改进点**：具体需要改进的方面

### 0.4 将错误案例转为 evals.json

skill-creator 的评估引擎使用 `evals.json` 格式。如果目标 skill 只有 eval/ 错误案例，需要将其转换为 evals.json：

```json
{
  "skill_name": "<skill-name>",
  "evals": [
    {
      "id": 1,
      "prompt": "<从 error_001.md 的场景描述中提取>",
      "expected_output": "<从 error_001_fix.md 的正确输出中提取>",
      "files": [],
      "assertions": [
        {"name": "覆盖所有必要步骤", "type": "contains", "value": "..."},
        {"name": "生成完整文档套件", "type": "contains", "value": "..."}
      ]
    }
  ]
}
```

将生成的 evals.json 保存到 `target-skill/evals/evals.json`。

如果目标 skill 已有 evals.json，跳过此步骤。

### 0.5 初始化实验环境

```bash
# 创建迭代分支
git checkout -b evolve/<skill-name>/<date-tag>

# 初始化 results.tsv（如果不存在）
echo -e "iteration\tdimension\tchange_description\tscore_before\tscore_after\tdelta\tstatus" > results.tsv
```

results.tsv 字段：
- `iteration`：迭代轮次
- `dimension`：修改维度（trigger / workflow / reference / quality）
- `change_description`：具体变更描述
- `score_before`：变更前通过率（0.00-1.00）
- `score_after`：变更后通过率
- `delta`：分数变化
- `status`：keep / discard / crash / pending_review

results.tsv 不提交到 git，它是运行时日志。

## Phase 1：建立 Baseline

### 1.1 读取完整 skill

读取目标 skill 的 `SKILL.md` 和所有 `references/` 文件。

### 1.2 调用 skill-creator 运行 Baseline 评估

**这一步直接调用 skill-creator 的评估流程**。使用 Skill 工具调用 skill-creator，让它：

1. 读取 evals.json 中的测试用例
2. 为每个测试用例启动 subagent（with-skill 模式）
3. 使用 grader 评分
4. 聚合 benchmark 数据

向 skill-creator 传达的指令：

> "对 skill `<path-to-skill>` 运行一次评估。使用 `evals/evals.json` 中的测试用例。
> 这是 baseline 运行，不需要 baseline 对比。
> 将结果保存到 `<skill-path>-workspace/iteration-0/`。
> 请完成 eval 执行、grading、benchmark 聚合。"

如果 skill-creator 不可用或用户偏好快速评估，可以降级为内联模拟：
- 对每个 evals.json 中的 prompt，按 skill 指令模拟处理
- 用 assertions 逐条验证
- 记录通过率

### 1.3 记录 Baseline

将 skill-creator 返回的 benchmark 数据记录到 results.tsv：

```
0	baseline	初始状态评估	-	0.XX	-	baseline
```

## Phase 2：实验循环（核心）

这是 autoresearch 的 NEVER STOP 循环。每次迭代复用 skill-creator 的评估能力。

### 2.1 循环流程

```
LOOP:
  1. 分析当前状态（results.tsv + evals.json + 上轮 benchmark）
  2. 选择一个单变量改进方向
  3. 修改 skill 的一个方面
  4. git commit
  5. 调用 skill-creator 运行评估
  6. 读取 benchmark 结果
  7. 决策：keep / discard / pending_review
  8. 记录到 results.tsv
  9. 继续循环（直到停止条件触发）
```

### 2.2 改进维度

每次迭代选择**一个**维度：

#### trigger（触发准确度）
- **修改对象**：SKILL.md 的 `description` 字段
- **策略**：补充触发场景、消除误触发、添加具体的使用上下文
- **进阶**：可以调用 skill-creator 的 description 优化循环（`scripts.run_loop`），自动化生成候选 description 并用 trigger eval 筛选最优解

#### workflow（工作流质量）
- **修改对象**：SKILL.md 的工作流步骤
- **策略**：添加缺失步骤、优化顺序、增加错误处理、改进指令清晰度、删除冗余步骤

#### reference（参考资源）
- **修改对象**：`references/` 目录下的文件
- **策略**：添加缺失模板、优化现有模板、增加边界情况指南、删除未使用文件

#### quality（质量保障）
- **修改对象**：SKILL.md 的质量规则、反模式、检查清单
- **策略**：添加反模式规则、增加检查清单项、从错误案例提炼新规则

### 2.3 单变量实验规则

**严格要求**：每次只改一个方面。

- 修改 `description` → 不动其他内容
- 修改某个 Phase 的步骤 → 不动其他 Phase
- 添加 reference 文件 → 不动 SKILL.md 指令部分
- 修改质量规则 → 不动工作流步骤

好处：精确归因、避免多变量交互、diff 简洁可审查。

### 2.4 调用 skill-creator 运行评估

每次修改并 git commit 后，**调用 skill-creator 重新运行评估**：

向 skill-creator 传达的指令：

> "对修改后的 skill `<path-to-skill>` 运行评估。
> 使用 `evals/evals.json` 中的测试用例。
> 同时运行 with-skill 版本。
> 将结果保存到 `<skill-path>-workspace/iteration-N/`。
> 如果有上一次迭代的结果，用 `--previous-workspace` 参数指向它。
> 请完成 eval 执行、grading、benchmark 聚合，并启动 eval viewer。"

skill-creator 会：
1. 为每个 eval 启动 subagent 执行
2. 使用 grader 评估 assertions
3. 聚合为 benchmark.json（包含 pass_rate、timing、tokens）
4. 启动 eval viewer 供人工查看

### 2.5 读取评估结果

从 skill-creator 产出的 benchmark 数据中提取关键指标：

- `pass_rate`：通过率（核心指标，类似 autoresearch 的 val_bpb）
- 逐 eval 的 assertion 通过情况
- timing 和 token 使用数据

如果 skill-creator 产出了 eval viewer，告知用户可以查看：
> "评估已完成，eval viewer 已启动。你可以在浏览器中查看每个测试用例的详细输出和评分。看完后告诉我反馈。"

### 2.6 读取人工反馈（可选）

如果用户通过 eval viewer 提交了 feedback.json，读取并纳入决策：

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "具体反馈内容"},
    ...
  ]
}
```

人工反馈是最终决策的重要参考。如果反馈指出严重问题，即使 pass_rate 提升也可以 discard。

### 2.7 决策规则

#### keep（保留）
- pass_rate 提高 ≥ 0.05
- 或 pass_rate 持平但 skill 更简洁（删除代码得到同等效果）
- 人工反馈正面

#### discard（回退）
- pass_rate 下降
- 或 pass_rate 持平且变更增加了不必要复杂度
- 人工反馈负面

#### pending_review（待人工审核）
- pass_rate 提高但 < 0.05
- 变更涉及核心设计决策
- 连续 3 次迭代无明显改善

#### crash（失败）
- skill 格式错误、无法触发、subagent 执行异常

### 2.8 Git 操作

```bash
# 修改前先 commit
git add -A && git commit -m "experiment: <迭代描述>"

# keep → 保持 commit，继续
# discard → git reset --hard HEAD~1
# pending_review → 保持 commit，标记
```

### 2.9 简单性准则

移植自 autoresearch：

> 同等效果下，更简单的 skill 版本优先。

- pass_rate 提升 < 0.05 但增加 20+ 行 → 考虑 discard
- pass_rate 提升 < 0.05 但来自删除冗余指令 → keep
- pass_rate 持平但 skill 更简洁 → keep（简化胜利）
- pass_rate 提升 ≥ 0.05 → 通常 keep

### 2.10 停止条件

1. **人工中断**：用户说"停止"或"暂停"
2. **收敛**：连续 5 次迭代 pass_rate 未提升超过 0.02
3. **全部通过**：所有 eval 的 pass_rate 达到 1.0
4. **兜底**：单次循环不超过 20 轮

达到停止条件后汇报：迭代次数、baseline → 最终 pass_rate 变化、results.tsv 完整日志。

### 2.11 触发准确度专项优化

当迭代维度为 `trigger` 时，除了常规的单变量实验，还可以调用 skill-creator 的 **description 优化循环**：

1. 调用 skill-creator 生成 20 个 trigger eval queries（should-trigger / should-not-trigger）
2. 让用户审核这些 queries
3. 运行 `scripts.run_loop` 自动化优化 description（最多 5 轮）
4. 选择 test score 最高的 description 作为最优解

这比手动逐条修改 description 高效得多。

## Phase 3：汇报与交付

### 3.1 生成迭代报告

在 skill 目录下生成 `eval/iteration-report.md`：

```markdown
# Skill 迭代报告

## 基本信息
- 目标 Skill: [skill-name]
- 迭代分支: [branch-name]
- 总迭代次数: X
- Baseline pass_rate: XX% → 最终 pass_rate: XX%

## 迭代历史
| # | 维度 | 变更 | 前 | 后 | Δ | 状态 |
|---|------|------|----|----|---|------|

## 保留的改进
## 回退的尝试
## 待审核项
## 建议
```

### 3.2 清理

- 将 `results.tsv` 移到 `eval/results.tsv` 归档
- 提醒用户检查 pending_review 项
- 询问是否合并迭代分支

## 多 Skill 批量模式

1. 为每个 skill 创建独立迭代分支
2. 每个 skill 独立运行 Phase 0-3
3. 依次处理，不并行
4. 全部完成后生成总览报告

## eval/ 错误案例维护

迭代过程中如果发现：
- **新的失败模式**：建议用户添加新的 error_x.md + error_x_fix.md
- **已修复的案例退化**：记录并在汇报中强调
- **案例质量不佳**：建议用户改进案例描述

错误案例是评估的基础。案例质量直接决定迭代质量。

## evals.json 维护

随着 skill 迭代，evals.json 也可能需要更新：
- 如果错误案例有新增/修改，重新生成对应的 evals.json 条目
- 如果 skill 的功能范围扩展，可以添加新的 eval 测试用例
- evals.json 的 assertions 应该保持客观可验证

## Anti-patterns（反模式）

1. **多变量修改**：一次改多个维度，无法归因效果
2. **过度拟合**：只针对特定 eval 调参，损害通用性
3. **盲目堆叠**：持续添加规则不删减，导致 skill 膨胀
4. **忽视简单性**：微小改善牺牲可读性和简洁性
5. **跳过 baseline**：无法衡量改进
6. **忽略 crash**：crash 包含重要信息
7. **过度迭代**：收敛后继续迭代浪费资源
8. **绕过 skill-creator**：重新实现 eval/grading/viewer 而非复用

## 检查清单

每次迭代前：
- [ ] 只修改了一个维度
- [ ] 修改范围最小化
- [ ] evals.json 测试用例有效
- [ ] results.tsv 记录了上次结果

每次迭代后：
- [ ] skill-creator 评估已完成
- [ ] benchmark 数据已读取
- [ ] results.tsv 已更新
- [ ] git 状态正确
- [ ] 简单性准则已考虑
