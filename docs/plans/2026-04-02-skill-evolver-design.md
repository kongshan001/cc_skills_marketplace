# cc-skill-evolver 设计文档

> 日期：2026-04-02
> 基于 autoresearch 实验循环 + skill-creator eval 机制

---

## 目标

创建一个 Claude Code skill，能够按 autoresearch 的实验循环思路，持续迭代优化其他已有的 Claude Code skill。

## 核心循环

```
选择目标 skill → 读取 eval/ 错误案例 → 单变量修改 SKILL.md → 运行 eval 测试（盲评）→
  AI 自评（结构化打分）→ 改善则 git commit → 恶化则 git reset → 记录 results.tsv → 继续
```

## 支持的评估格式

### 格式 A：错误案例（推荐）

```
skill-name/eval/
├── error_001.md      # 场景 + 实际行为 + 期望行为概述
├── error_001_fix.md  # 详细正确输出（评估时不提前读取，防止信息泄露）
├── error_002.md
├── error_002_fix.md
└── ...
```

### 格式 B：evals.json（兼容 skill-creator）

```
skill-name/evals/
└── evals.json        # skill-creator 标准评估格式
```

### 盲评协议

为防止评估信息泄露，评估分三阶段：
1. **阶段 A（模拟）**：只读 skill + 测试输入，产出模拟输出
2. **阶段 B（评分）**：此时才读 fix 文件 / expected_output，对比打分
3. **阶段 C（汇总）**：计算通过率，记录结果

## 评估机制（混合模式）

### AI 自评（第一层筛选）
- 盲评协议：先模拟产出，再对比 fix 文件
- 结构化打分：PASS/PARTIAL/FAIL
- 计算通过率作为量化指标

### 人工审核（最终确认）
- AI 标记为"pending_review"的变更需要人工确认
- 提供 results.tsv 供人类审查实验历史

## 实验变量维度

1. **触发准确度（trigger）**：优化 description 字段
2. **工作流质量（workflow）**：优化步骤指令
3. **参考资源（reference）**：优化 references/ 文件
4. **质量保障（quality）**：优化反模式、检查清单

## 实验策略

- **单变量**：每次只改一个维度的一个方面
- **盲评**：模拟时不看 fix 文件，防止信息泄露
- **简单性准则**：同等效果下更简洁的 skill 版本优先
- **停止条件**：人工中断 / 收敛 / 全部通过 / 20 轮上限
