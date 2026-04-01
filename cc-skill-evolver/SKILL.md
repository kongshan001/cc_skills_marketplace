---
name: cc-skill-evolver
description: |
  基于 autoresearch 实验循环思路，持续迭代优化已有的 Claude Code skill。
  当用户想要改进、优化、迭代一个已有的 skill 时使用此技能。
  适用场景：用户说"优化这个 skill"、"迭代改进 skill"、"让 skill 更好"、
  "skill 效果不好需要改进"、"帮我调优 skill"、"运行 skill 进化循环"，
  或者用户提到 skill 的任何质量问题、触发不准、输出不理想等问题。
  即使用户没有明确说"进化"或"迭代"，只要涉及 skill 质量改进就应该使用此技能。
---

# cc-skill-evolver

基于 [karpathy/autoresearch](https://github.com/karpathy/autoresearch) 的实验循环思路，对已有的 Claude Code skill 进行持续迭代优化。

核心理念：**修改 → 测试 → 比较结果 → 保留或回滚 → 重复**。

## 设计哲学

本项目从 autoresearch 中提取了以下核心原则并迁移到 skill 迭代场景：

| Autoresearch | Skill Evolver |
|---|---|
| `train.py`（唯一修改目标） | `SKILL.md` + `references/`（被迭代的 skill） |
| `prepare.py`（只读基准） | `eval/` 错误案例（只读评估基准） |
| `val_bpb`（量化指标） | eval 通过率 + AI 自评分数 |
| `results.tsv`（实验日志） | skill 的 `results.tsv` |
| git commit / reset | skill 版本管理 |
| 单变量实验 | 每次只改一个维度 |
| 简单性准则 | 更简洁的 skill 版本优先 |
| NEVER STOP | 持续迭代直到人工停止或收敛 |

## Phase 0：环境准备

在开始迭代之前，需要确保目标 skill 具备正确的目录结构和评估基础设施。

### 0.1 确定目标 skill

询问用户要优化哪个 skill。用户可以指定：
- **单个 skill**：`优化 py-doc-generator 这个 skill`
- **多个 skill**：`优化所有 skill 的触发准确度`（每个 skill 独立迭代）

如果用户指定了 skill 路径，直接使用。如果没有，列出当前项目中可用的 skill 供用户选择。

### 0.2 检查目录结构

目标 skill 支持两种评估格式，优先使用格式 A，如果已有格式 B 也可直接使用：

**格式 A：错误案例格式（推荐）**

```
target-skill/
├── SKILL.md                  # 被迭代的主体（必需）
├── eval/                     # 评估基准
│   ├── error_001.md          # 错误案例：场景 + 实际行为 + 期望行为
│   ├── error_001_fix.md      # 期望修复结果：正确的详细输出（评估时不提前读取）
│   ├── error_002.md
│   ├── error_002_fix.md
│   └── ...
├── results.tsv               # 实验日志（自动创建）
└── references/               # 可选的参考资源
```

**格式 B：skill-creator evals.json 格式（兼容）**

```
target-skill/
├── SKILL.md
├── evals/
│   └── evals.json            # skill-creator 标准评估文件
├── results.tsv
└── references/
```

`evals.json` 格式如下（来自 skill-creator 标准）：

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "用户的任务描述",
      "expected_output": "期望输出的描述",
      "files": [],
      "assertions": [
        {"name": "assertion-name", "type": "contains", "value": "..."}
      ]
    }
  ]
}
```

如果目标 skill 同时有 `eval/` 和 `evals/evals.json`，合并使用。

### 0.3 引导创建 eval/ 错误案例

如果 `eval/` 目录不存在或为空，也没有 `evals/evals.json`，需要引导用户创建。

**方式一：引导用户创建错误案例文件**

> "要优化这个 skill，我们需要先建立评估基准。请在 eval/ 目录下创建错误案例：
> - `error_001.md`：描述一个 skill 处理不当的具体场景
> - `error_001_fix.md`：描述期望的正确处理结果
>
> 每个错误案例应该是一个具体的、可复现的场景，而不是笼统的描述。
> 建议至少创建 3 个错误案例才能开始迭代。"

**方式二：引导用户创建 evals.json**

> "或者，你可以在 evals/ 目录下创建 `evals.json`，遵循 skill-creator 的标准格式：
> 包含 prompt（测试输入）、expected_output（期望输出）、assertions（断言）。"

**错误案例编写指南**（向用户展示）：

```markdown
## error_x.md 格式（包含完整信息用于后续分析）

### 场景描述
描述触发此 skill 的用户输入或上下文。越具体越好，包括文件路径、项目结构、
用户原话等。

### 实际行为
描述 skill 当前的错误行为或不足之处。包括具体的错误输出示例。

### 期望行为
描述 skill 应该如何正确处理此场景。

## error_x_fix.md 格式（评估时才读取，防止信息泄露）

### 正确输出
描述 skill 应该产生的完整正确输出，包括具体的文件内容、步骤等。

### 关键改进点
- 列出具体需要改进的方面
```

**关于信息泄露的说明**：

error_x.md 中同时包含"实际行为"和"期望行为"是故意的——这些信息帮助 AI 在迭代时理解问题本质和制定改进策略。但 error_x_fix.md 中的详细正确输出在评估模拟阶段是**禁止提前读取**的（见 Phase 2.4 的盲评协议），只有在模拟产出结果后才对比 fix 文件打分。

### 0.4 初始化 results.tsv

如果 `results.tsv` 不存在，创建它：

```
iteration	dimension	change_description	score_before	score_after	delta	status
```

字段说明：
- `iteration`：迭代轮次编号
- `dimension`：修改维度（trigger / workflow / reference / quality）
- `change_description`：本次实验的具体变更描述
- `score_before`：变更前的通过率（0.00-1.00）
- `score_after`：变更后的通过率（0.00-1.00）
- `delta`：分数变化（正数=改善，负数=退步）
- `status`：keep / discard / crash / pending_review

### 0.5 创建迭代分支

```bash
git checkout -b evolve/<skill-name>/<date-tag>
```

例如：`git checkout -b evolve/py-doc-generator/apr2`

确认一切就绪后，进入 Phase 1。

## Phase 1：建立 Baseline

在开始任何修改之前，必须先建立当前 skill 的性能基准。

### 1.1 读取完整 skill

读取目标 skill 的 `SKILL.md` 和所有 `references/` 文件，完整理解其当前行为。

### 1.2 运行 Baseline 评估

根据检测到的评估格式运行 baseline：

**格式 A（错误案例）**：对 `eval/` 中的每个错误案例执行以下步骤（遵循盲评协议）：

1. **模拟运行**：只读 `error_x.md`，假设你是一个使用该 skill 的 AI agent，按照 skill 的指令处理场景
2. **产出输出**：记录模拟输出
3. **对比期望**：此时才读取 `error_x_fix.md`，将模拟输出与期望结果对比
4. **逐项评分**：对每个错误案例给出通过/未通过判定

**格式 B（evals.json）**：对 `evals/evals.json` 中的每个 eval 执行：

1. **模拟运行**：只读 `prompt` 和 `files`，按 skill 指令处理
2. **产出输出**：记录模拟输出
3. **检查 assertions**：此时才读取 `expected_output` 和 `assertions`，逐条验证
4. **逐项评分**：计算 assertion 通过率

**评分标准**：

| 等级 | 含义 | 分数 |
|------|------|------|
| PASS | 输出完全满足期望结果 | 1.0 |
| PARTIAL | 输出部分满足，有关键缺失 | 0.5 |
| FAIL | 输出与期望严重不符 | 0.0 |

### 1.3 记录 Baseline

将 baseline 结果记录到 `results.tsv`：

```
0	baseline	初始状态评估	-	0.XX	-	baseline
```

同时记录每个错误案例的详细评分到 `eval/baseline_scores.md`：

```markdown
## Baseline 评估结果

### error_001: [案例简述]
- 评分: PASS/PARTIAL/FAIL (分数)
- 分析: [为什么失败/成功]

### error_002: [案例简述]
...
```

## Phase 2：实验循环

这是核心循环，类似 autoresearch 的 NEVER STOP 循环。

### 2.1 循环流程

```
LOOP:
  1. 分析当前状态（results.tsv 历史 + eval 错误案例）
  2. 选择一个单变量改进方向
  3. 修改 skill 的一个方面
  4. 运行 eval 测试
  5. AI 自评打分
  6. 对比 baseline / 上次最佳分数
  7. 决策：keep（改善）或 discard（退步/持平）
  8. 记录到 results.tsv
  9. 继续循环
```

### 2.2 改进维度与策略

每次迭代选择以下**一个**维度进行改进：

#### 维度 1：触发准确度（trigger）
- **修改对象**：SKILL.md 的 `description` 字段
- **改进策略**：
  - 补充遗漏的触发场景
  - 消除误触发的边界情况
  - 添加更具体的"何时使用"描述
  - 参考 skill-creator 的 description 优化方法
- **验证方法**：检查错误案例中是否有因 skill 未被正确触发导致的问题

#### 维度 2：工作流质量（workflow）
- **修改对象**：SKILL.md 的工作流步骤
- **改进策略**：
  - 添加缺失的处理步骤
  - 优化步骤顺序
  - 增加错误处理分支
  - 改进指令清晰度（解释"为什么"而非只说"做什么"）
  - 删除冗余或无效的步骤
- **验证方法**：检查错误案例中是否有因工作流不完整或步骤不清晰导致的问题

#### 维度 3：参考资源（reference）
- **修改对象**：`references/` 目录下的文件
- **改进策略**：
  - 添加缺失的模板或示例
  - 优化现有模板的实用性
  - 增加边界情况的处理指南
  - 删除未使用的参考文件
- **验证方法**：检查错误案例中是否有因缺少参考资源导致的问题

#### 维度 4：质量保障（quality）
- **修改对象**：SKILL.md 的质量规则、反模式、检查清单
- **改进策略**：
  - 添加新的反模式规则
  - 增加质量检查清单项
  - 补充边界情况处理
  - 添加从错误案例中提炼的新规则
- **验证方法**：检查错误案例中是否有因缺少质量规则导致的问题

### 2.3 单变量实验规则

**严格要求**：每次迭代只修改一个方面。

- 如果修改 `description` 字段，不动其他内容
- 如果修改 Phase 2 的某个步骤，不动其他 Phase
- 如果添加一个 reference 文件，不动 SKILL.md 的指令部分
- 如果修改质量规则，不动工作流步骤

这样做的好处：
- 可以精确归因每个变更的效果
- 避免多变量交互导致的混乱
- diff 简洁可审查

### 2.4 AI 自评方法（盲评协议）

每次修改后，重新运行所有 eval 测试用例并评估。**严格遵循盲评协议**，防止信息泄露影响评估质量。

#### 盲评协议

评估分三个阶段，**必须按顺序执行，不可提前读取后续阶段的文件**：

**阶段 A：模拟运行（只读 skill + 测试输入，不读 fix）**

1. 重读修改后的 skill：完整读取更新后的 `SKILL.md` 和 `references/`
2. 读取测试输入：
   - 错误案例格式：只读 `error_x.md`（包含场景描述、实际行为、期望行为概述）
   - evals.json 格式：只读 `prompt` 和 `files` 字段
3. 按照修改后的 skill 指令，模拟处理该场景，产出完整输出
4. **将模拟输出记录下来**（写入内部评估记录，不修改任何源文件）

**阶段 B：对比评分（此时才读取 fix 文件）**

5. 读取期望结果：
   - 错误案例格式：读取 `error_x_fix.md`
   - evals.json 格式：读取 `expected_output` 和 `assertions`
6. 将阶段 A 的模拟输出与期望结果逐项对比
7. 对每个测试用例给出评分

**阶段 C：汇总分析**

8. 汇总所有评分，计算通过率
9. 与 baseline / 上次最佳分数对比
10. 记录到 results.tsv

#### 为什么需要盲评

如果 AI 在模拟运行前就知道期望的详细输出（error_x_fix.md），评估就变成了"开卷考试"——AI 会不自觉地朝已知答案靠拢，掩盖 skill 本身的不足。盲评协议确保：

- 模拟运行完全基于 skill 自身的指令质量
- 只有在产出结果后才进行对比
- 评估结果更真实地反映 skill 的实际效果

#### 评分标准

| 等级 | 含义 | 分数 |
|------|------|------|
| PASS | 输出完全满足期望结果 | 1.0 |
| PARTIAL | 输出部分满足，有关键缺失 | 0.5 |
| FAIL | 输出与期望严重不符 | 0.0 |

对于 evals.json 中的 assertions，逐条检查：
- 每条通过的 assertion 计入分数
- 最终分数 = 通过的 assertions 数 / 总 assertions 数

#### 评估输出格式

```markdown
## 评估结果 - 迭代 #N

### 维度: [trigger/workflow/reference/quality]
### 变更描述: [具体改了什么]

### error_001: [案例简述]
- 评分: PASS/PARTIAL/FAIL (分数)
- 模拟输出摘要: [阶段 A 产出的关键内容]
- 对比分析: [与 fix 文件的具体差异]
- 对比 baseline: [改善/持平/退步]

### evals.json #1: [案例简述]
- 评分: X/Y assertions 通过 (分数)
- 失败 assertions: [哪些失败了，为什么]
- 对比 baseline: [改善/持平/退步]

### 汇总
- 总通过率: X/Y (XX%)
- 对比 baseline: +X.XX / -X.XX / 持平
```

### 2.5 决策规则

#### keep（保留）
- 通过率提高 ≥ 0.05（相对提升）
- 或通过率持平但 skill 更简洁（删除代码/步骤得到同等效果）

#### discard（回退）
- 通过率下降
- 或通过率持平且 skill 变更增加了不必要的复杂度

#### pending_review（待人工审核）
- 通过率提高但 < 0.05（微小改善）
- 或变更涉及 skill 的核心设计决策
- 或连续 3 次迭代未产生明显改善

#### crash（失败）
- 修改后 skill 格式错误、无法触发、或产生严重问题

### 2.6 Git 操作

```bash
# 修改前先记录当前状态
git add -A && git commit -m "experiment: <迭代描述>"

# 如果 keep：保持 commit，继续
# 如果 discard：
git reset --hard HEAD~1

# 如果 pending_review：保持 commit，标记等待人工审核
```

**重要**：`results.tsv` 不提交到 git（加入 .gitignore），它只是运行时日志。

### 2.7 简单性准则

移植自 autoresearch 的设计哲学：

> 同等效果下，更简单的 skill 版本优先。

具体规则：
- 通过率提升 < 0.05 但增加了 20+ 行指令 → 可能不值得，考虑 discard
- 通过率提升 < 0.05 但是来自删除冗余指令 → 值得 keep
- 通过率持平但 skill 更简洁 → keep（简化胜利）
- 通过率提升 ≥ 0.05 → 通常值得 keep，除非引入了严重的技术债

### 2.8 停止条件

与 autoresearch 不同，我们不采用 NEVER STOP。合理的停止条件：

1. **人工中断**：用户明确说"停止"或"暂停"
2. **收敛**：连续 5 次迭代通过率未提升超过 0.02
3. **全部通过**：所有 eval 错误案例都通过（PASS）
4. **兜底限制**：单次迭代循环不超过 20 轮

达到停止条件后，向用户汇报：
- 总迭代次数
- baseline → 最终的通过率变化
- results.tsv 完整日志
- 建议是否需要人工审核某些变更

## Phase 3：汇报与交付

迭代循环结束后：

### 3.1 生成迭代报告

在 skill 目录下生成 `eval/iteration-report.md`：

```markdown
# Skill 迭代报告

## 基本信息
- 目标 Skill: [skill-name]
- 迭代分支: [branch-name]
- 总迭代次数: X
- Baseline 通过率: XX% → 最终通过率: XX%

## 迭代历史
| # | 维度 | 变更 | 前 | 后 | Δ | 状态 |
|---|------|------|----|----|---|------|
| 1 | workflow | ... | 0.60 | 0.75 | +0.15 | keep |
| ... |

## 保留的改进
- [列出所有 keep 的变更及其效果]

## 回退的尝试
- [列出所有 discard 的变更及失败原因]

## 待审核项
- [列出所有 pending_review 的变更]

## 建议
- [下一步优化方向的建议]
```

### 3.2 清理

- 将 `results.tsv` 移到 `eval/results.tsv` 归档
- 如果有待审核项，提醒用户检查
- 询问用户是否要合并迭代分支到主分支

## 多 Skill 批量模式

当用户指定多个 skill 时：

1. 为每个 skill 创建独立的迭代分支
2. 每个 skill 独立运行 Phase 0-3
3. 依次处理，不并行（避免资源冲突）
4. 全部完成后生成总览报告

## eval/ 错误案例维护

在迭代过程中，如果发现：

- **新的失败模式**：应建议用户添加新的 error_x.md + error_x_fix.md
- **已修复的案例变为退化**：记录并在汇报中强调
- **案例质量不佳**：建议用户改进案例描述

错误案例是整个迭代系统的基础。案例质量直接决定迭代质量。

## 质量保障

### Anti-patterns（反模式）

以下行为应避免：

1. **多变量修改**：一次改多个维度，无法归因效果
2. **过度拟合**：只针对特定错误案例调参，损害通用性
3. **盲目堆叠**：持续添加规则而不删减，导致 skill 膨胀
4. **忽视简单性**：为了微小改善牺牲 skill 的可读性和简洁性
5. **跳过 baseline**：没有 baseline 就无法衡量改进
6. **忽略 crash 分析**：crash 包含重要信息，应分析原因
7. **过度迭代**：收敛后继续迭代是浪费资源

### 检查清单

每次迭代前检查：
- [ ] 只修改了一个维度
- [ ] 修改范围最小化（只改必要的部分）
- [ ] eval/ 错误案例全部可读且有效
- [ ] results.tsv 正确记录了上次结果

每次迭代后检查：
- [ ] 所有 eval 错误案例都重新评估了
- [ ] results.tsv 已更新
- [ ] git 状态正确（keep = 有新 commit，discard = 已 reset）
- [ ] 简单性准则已考虑
