# Claude Code Skills Marketplace

> 个人 Claude Code Agent Skills 集合，遵循 [Agent Skills 规范](https://agentskills.io/specification)，通过 [skills.sh](https://skills.sh) 分发。

## 安装 Skills

```bash
# 从 GitHub 安装指定技能
npx skills add kongshan001/cc_skills_marketplace/<skill-name>

# 全局安装
npx skills add kongshan001/cc_skills_marketplace/<skill-name> -g -y
```

## 可用 Skills

| Skill | 描述 | 等级 | 版本 |
|-------|------|------|------|
| [py-doc-generator](./py-doc-generator/) | 分析 Python 3 源码并生成完整项目文档，包括 CLAUDE.md、架构概览、UML 图表、业务脑图和 AP... | ![core](https://img.shields.io/badge/tier-core-green) | 1.0.0 |
| [python-unittest-generator](./python-unittest-generator/) | 为现有 Python 代码库生成完整的 unittest 测试套件，支持自动化覆盖率度量，采用最小化 mock 策略。 | ![standard](https://img.shields.io/badge/tier-standard-blue) | 1.0.0 |
| [cc-code-setup](./cc-code-setup/) | 一键生成完整的 .claude 工程目录结构，基于 Claude Code 官方文档最佳实践，支持 5 种预设模板... | ![basic](https://img.shields.io/badge/tier-basic-yellow) | 1.0.0 |
| [cc-skills-researcher](./cc-skills-researcher/) | 定期调研 Claude Code 热门 Skills 和插件，搜索 GitHub/ClawHub 生成调研报告并推... | ![basic](https://img.shields.io/badge/tier-basic-yellow) | 0.1.0 |
| [cc-plugin-researcher](./cc-plugin-researcher/) | 定期调研 Claude Code 热门 MCP 插件，搜索 GitHub/awesome-claude-code ... | ![basic](https://img.shields.io/badge/tier-basic-yellow) | 0.1.0 |
| [cc-skill-evolver](./cc-skill-evolver/) | 基于 autoresearch 实验循环思路，持续迭代优化已有的 Claude Code skill，处理触发不准... | ![basic](https://img.shields.io/badge/tier-basic-yellow) | 0.1.0 |

### 质量等级说明

| 等级 | 含义 |
|------|------|
| ![core](https://img.shields.io/badge/tier-core-green) | 完全符合规范，有 references/、完整 frontmatter、body < 500 行 |
| ![standard](https://img.shields.io/badge/tier-standard-blue) | 基本符合规范，允许缺 references/ 或部分 frontmatter 字段 |
| ![basic](https://img.shields.io/badge/tier-basic-yellow) | 功能可用，但有多项不合规（如超长、命名不规范等） |
| ![experimental](https://img.shields.io/badge/tier-experimental-orange) | 实验性，WIP |

## 添加新 Skill

1. 在仓库根目录创建技能文件夹（使用 gerund 命名，如 `generating-docs`）
2. 包含 `SKILL.md` 文件（遵循 [Agent Skills 规范](https://agentskills.io/specification)）
3. 包含 `README.md`（安装说明和使用示例）
4. 运行验证：`bash scripts/validate-skill.sh <skill-name>`
5. 更新 `registry.json` 添加技能条目
6. 运行 `bash scripts/generate-readme.sh` 重新生成 README
7. 提交 PR

## SKILL.md 规范

```yaml
---
name: skill-name           # 必填，gerund 形式，与目录名一致
description: 技能描述...     # 必填，第三人称，< 1024 字符
license: Apache-2.0        # 推荐
metadata:
  version: "1.0.0"         # SemVer
  author: "your-name"
  tags: ["tag1", "tag2"]
---
```

## 验证

```bash
# 验证单个技能
bash scripts/validate-skill.sh <skill-name>

# 验证所有技能
bash scripts/validate-all.sh

# 验证注册表一致性
bash scripts/validate-registry.sh
```

## 更多信息

- [Agent Skills 规范](https://agentskills.io/specification)
- [Anthropic 最佳实践](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [skills.sh](https://skills.sh) - AI Agent Skills 目录
- [Claude Code 文档](https://code.claude.com/docs) - Claude Code 官方文档

