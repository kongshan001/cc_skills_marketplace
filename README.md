# Claude Code Skills Marketplace

> 自定义 Skills 集合，对接 skills.sh

## 安装 Skills

在 skills.sh 搜索并安装，或直接使用 npx：

```bash
# 方式1: 从 skills.sh 安装
npx skills add cc-skills-researcher
npx skills add cc-plugin-researcher
npx skills add cc-code-setup

# 方式2: 从 GitHub 安装
npx skills add kongshan001/cc_skills_marketplace/cc-code-setup
```

## 可用 Skills

| Skill | 描述 | 安装量 |
|-------|------|--------|
| [cc-code-setup](./cc-code-setup/) | 🔥 一键生成完整的 .claude 工程目录结构 | ⭐ 推荐 |
| [cc-skills-researcher](./cc-skills-researcher/) | Claude Code Skills 调研专家 | - |
| [cc-plugin-researcher](./cc-plugin-researcher/) | Claude Code 插件（MCP）调研专家 | - |

### cc-code-setup 特色功能

**一键生成完整的 Claude Code 项目配置**，基于官方文档最佳实践：

- 📁 **完整目录结构**: CLAUDE.md, rules, skills, agents, hooks, MCP
- 🎯 **5 种预设模板**: frontend / backend / cli / library / minimal
- 💬 **12 步交互式配置**: 收集项目信息并生成配置
- ⚡ **一键部署**: 命令行参数或 JSON 配置文件

```bash
# 使用预设模板快速部署
/claude-code-setup --template backend --path ./my-api

# 命令行参数部署
/claude-code-setup --name "My API" --type backend --rules code-style,testing,security

# JSON 配置文件部署
/claude-code-setup --config setup.json
```

**生成的配置包含**:
- CLAUDE.md - 项目上下文和指令
- rules/ - 模块化规则（支持条件加载）
- skills/ - 自定义技能
- agents/ - 自定义 Subagent
- hooks/ - 生命周期钩子
- MCP 服务器配置

## 添加新 Skill

1. 在仓库根目录创建 Skill 文件夹
2. 包含 `SKILL.md` 文件（遵循 AgentSkills 规范）
3. 提交并推送到仓库

## SKILL.md 规范

```markdown
---
name: skill-name
description: 技能描述（用于触发技能）
argument-hint: [参数提示]
---

# 技能说明

技能使用的详细指令...
```

## 提交规范

- Skill 名称使用小写字母、数字和连字符
- 必须包含 `SKILL.md` 文件
- 遵循 skills.sh 规范编写

## 更多信息

- [skills.sh](https://skills.sh) - AI Agent Skills 目录
- [OpenClaw 文档](https://docs.openclaw.ai) - Skills 使用指南
- [Claude Code 文档](https://code.claude.com/docs) - Claude Code 官方文档
