# cc-skill-evolver 设计文档

> 日期：2026-04-02
> 基于 autoresearch 实验循环 + skill-creator eval 机制

---

## 目标

创建一个 Claude Code skill，能够按 autoresearch 的实验循环思路，持续迭代优化其他已有的 Claude Code skill。

## 核心循环

```
选择目标 skill → 读取 eval/ 错误案例 → 单变量修改 SKILL.md → 运行 eval 测试 →
  AI 自评（结构化打分）→ 改善则 git commit → 恶化则 git reset → 记录 results.tsv → 继续
```

## Skill 目录结构

目标 skill 需要具备以下结构：

```
skill-name/
├── SKILL.md                  # 被迭代优化的主体
├── eval/                     # 评估基准（只读）
│   ├── error_001.md          # 错误案例描述
│   ├── error_001_fix.md      # 期望正确结果
│   ├── error_002.md
│   ├── error_002_fix.md
│   └── ...
├── results.tsv               # 实验日志（不提交 git）
└── references/               # 可选的参考资源（也可被优化）
```

## 评估机制（混合模式）

### AI 自评（第一层筛选）
- 对每个 eval/error_x.md，运行当前 skill 版本处理该场景
- 将输出与 eval/error_x_fix.md 期望结果对比
- 结构化打分：通过/未通过 + 具体差距分析
- 计算通过率作为量化指标（类似 autoresearch 的 val_bpb）

### 人工审核（最终确认）
- AI 自评标记为"改善"的变更需要人工最终确认
- 提供 results.tsv 供人类快速审查实验历史
- 人类可以随时中断循环

## 实验变量维度

1. **触发准确度**：优化 description 字段
2. **工作流质量**：优化步骤指令、错误处理
3. **参考资源**：优化 references/ 文件
4. **质量保障**：优化反模式、检查清单

## 实验策略

- **单变量**：每次实验只改一个维度的一个方面
- **对比基准**：首次运行当前 skill 作为 baseline
- **简单性准则**：同等效果下更简洁的 skill 版本优先
- **永不停止**：循环直到人工中断或收敛

## results.tsv 格式

```
iteration	dimension	change_description	score_before	score_after	delta	status
1	workflow	添加错误处理步骤	0.60	0.75	+0.15	keep
2	trigger	优化 description 触发词	0.75	0.70	-0.05	discard
```

## cc-skill-evolver 自身的 SKILL.md 结构

```yaml
---
name: cc-skill-evolver
description: 基于 autoresearch 实验循环思路，持续迭代优化已有的 Claude Code skill...
---
```

### Phase 0: 环境准备
- 扫描目标 skill 目录结构
- 检查 eval/ 目录是否存在，不存在则引导创建
- 检查 results.tsv 是否存在
- 创建 git 分支

### Phase 1: Baseline 建立
- 读取当前 skill 完整内容
- 运行所有 eval 错误案例，建立 baseline 通过率
- 记录到 results.tsv

### Phase 2: 实验循环
- 分析 eval 错误案例和 results.tsv 历史
- 选择一个单变量改进方向
- 修改 SKILL.md（或 references/）
- 运行 eval 测试
- AI 自评 + 记录结果
- keep 或 discard 决策
- 继续循环
