# Autoresearch 深度调研报告

> 来源：https://github.com/karpathy/autoresearch
> 作者：Andrej Karpathy
> 调研日期：2026-04-02

---

## 1. 项目概述

Autoresearch 是 Karpathy 于 2026 年 3 月发布的实验性项目，核心理念是：**让 AI agent 拥有一个小型但真实的 LLM 训练环境，自主进行过夜实验**。Agent 修改代码、训练 5 分钟、检查结果是否改善、保留或丢弃、循环往复。用户早上醒来时获得一份实验日志和（期望中的）更好的模型。

### 核心文件

| 文件 | 角色 | 是否可修改 |
|------|------|-----------|
| `prepare.py` | 固定常量、数据准备、评估工具 | **不可修改**（只读） |
| `train.py` | 模型架构、优化器、训练循环 | **Agent 唯一修改目标** |
| `program.md` | Agent 指令（本质上是一个"skill"） | **人类迭代优化** |

---

## 2. 核心架构分析

### 2.1 实验循环（Experiment Loop）

```
LOOP FOREVER:
  1. 查看 git 状态：当前分支/commit
  2. 用实验性想法修改 train.py
  3. git commit
  4. 运行实验：uv run train.py > run.log 2>&1
  5. 读取结果：grep "^val_bpb:" run.log
  6. 如果无输出 → 崩溃，查看 tail -n 50 run.log
  7. 记录结果到 results.tsv（不提交到 git）
  8. 如果 val_bpb 改善（更低）→ 推进分支，保留 commit
  9. 如果 val_bpb 持平或恶化 → git reset 回退
```

### 2.2 关键设计决策

#### 单文件修改原则
- Agent 只修改 `train.py` 一个文件
- **好处**：scope 可控、diff 可审查、避免多文件修改导致的混乱
- **迁移到 skill 场景**：每次实验只修改 SKILL.md 或其 references/ 下的单个文件

#### 固定时间预算
- 训练总是运行恰好 5 分钟（墙钟时间）
- **好处**：实验可直接比较，不受模型大小/批量大小影响
- **迁移到 skill 场景**：每次 eval 运行使用相同的测试集和评分标准

#### 简单性准则（Simplicity Criterion）
- 同等效果下更简单的方案优先
- 删除代码并得到同等或更好结果 → 大胜利
- 0.001 val_bpb 改善但增加 20 行丑陋代码 → 不值得
- 0.001 val_bpb 改善来自删除代码 → 值得保留
- **迁移到 skill 场景**：优化不仅看效果提升，也看 skill 的简洁性

#### 永不停止（NEVER STOP）
- 实验循环开始后不暂停询问人类
- 人类可能正在睡觉，期望 agent 持续工作直到手动中断
- **迁移到 skill 场景**：迭代循环可持续运行，但需要更频繁的人工检查点

---

## 3. program.md 指令结构分析

program.md 是 autoresearch 的"skill"文件，结构如下：

```
1. Setup（设置）
   - 约定 run tag
   - 创建分支
   - 读取上下文文件
   - 验证数据存在
   - 初始化 results.tsv
   - 确认并开始

2. Experimentation（实验规则）
   - 可以做什么 / 不能做什么
   - 评估指标说明
   - VRAM 软约束
   - 简单性准则
   - 首次运行 = baseline

3. Output Format（输出格式）
   - 结构化输出格式
   - 结果提取方法

4. Logging Results（结果记录）
   - TSV 格式：commit, val_bpb, memory_gb, status, description
   - status: keep / discard / crash

5. The Experiment Loop（实验循环）
   - 无限循环逻辑
   - 超时处理
   - 崩溃处理
   - NEVER STOP 指令
```

### 启示
- **清晰的 phase 划分**：Setup → Rules → Format → Logging → Loop
- **明确的边界**：CAN/CANNOT 清单
- **结果驱动**：每个行为都围绕"降低 val_bpb"这个单一目标
- **自包含**：所有信息在一个文件中，无需外部查找

---

## 4. train.py 技术架构

### 模型
- GPT 架构，单 GPU
- 关键特性：RMSNorm、Rotary Embeddings、滑动窗口注意力（SSSL 模式）、Value Embeddings（ResFormer）、Logit softcap
- 配置：DEPTH=8, HEAD_DIM=128, ASPECT_RATIO=64

### 优化器
- **MuonAdamW**：Muon 用于 2D 矩阵参数，AdamW 用于其余
- Polar Express 正交化（5 步迭代）
- NorMuon 方差缩减
- Cautious weight decay（只在梯度与参数同号时衰减）
- 所有核心操作 `torch.compile` 编译

### 训练循环
- 固定 5 分钟墙钟时间
- 梯度累积
- 学习率调度：warmup → 恒定 → warmdown
- Muon momentum 渐进调度（0.85 → 0.95）
- GC 优化：首次后 freeze+disable，每 5000 步 collect 一次

---

## 5. 与 Skill 迭代的映射关系

| Autoresearch 概念 | Skill 迭代对应 |
|-------------------|---------------|
| `train.py` | `SKILL.md` + `references/` |
| `prepare.py` | `eval/` 错误案例（只读基准） |
| `program.md` | 本 skill 自身（cc-skill-evolver 的 SKILL.md） |
| `val_bpb` | eval 通过率 + AI 自评分数 |
| `results.tsv` | skill 的 `results.tsv` |
| `uv run train.py` | 运行 skill-creator eval 或 AI 自评 |
| `git commit / reset` | skill 版本管理 |
| 5 分钟固定预算 | 固定 eval 测试集 |
| NEVER STOP | 持续迭代直到人工停止或收敛 |

---

## 6. skill-creator 的 Eval 机制

skill-creator 提供了完整的 eval 基础设施：

### evals.json 格式
```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "用户任务 prompt",
      "expected_output": "期望结果描述",
      "assertions": [
        {"name": "assertion-name", "type": "contains", "value": "..."}
      ]
    }
  ]
}
```

### 评估流程
1. 为每个 eval 启动 subagent（with-skill 和 without-skill）
2. AI grader 评估 assertions
3. 聚合为 benchmark.json
4. 生成 HTML viewer 供人类审查
5. 收集 feedback.json 用于下一轮迭代

### Description 优化
- 20 个 eval queries（should-trigger / should-not-trigger）
- 自动化优化循环（最多 5 次迭代）
- 按测试集分数选择最佳 description

---

## 7. 设计决策总结

基于 autoresearch 的设计哲学和 skill-creator 的 eval 机制，我们得出以下设计决策：

1. **单变量实验**：每次迭代只修改 SKILL.md 的一个方面
2. **错误案例驱动**：`eval/` 目录中的 `error_x.md` + `error_x_fix.md` 提供量化基准
3. **混合评估**：AI 结构化自评 + 人工最终审核
4. **Git 驱动版本管理**：commit 保留改进，reset 回退退步
5. **results.tsv 追踪**：记录每次实验的指标和决策
6. **四维优化**：触发准确度、工作流质量、参考资源、质量保障
