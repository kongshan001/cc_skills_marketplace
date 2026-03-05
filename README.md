# Claude Code Skills Marketplace

> 自定义 Skills 集合，对接 skills.sh

## 安装 Skills

在 skills.sh 搜索并安装，或直接使用 npx：

```bash
# 方式1: 从 skills.sh 安装
npx skills add cc-skills-researcher
npx skills add cc-plugin-researcher

# 方式2: 从 GitHub 安装
npx skills add kongshan001/cc_skills_marketplace/cc-skills-researcher
```

## 可用 Skills

| Skill | 描述 | 安装量 |
|-------|------|--------|
| [cc-skills-researcher](./cc-skills-researcher/) | Claude Code Skills 调研专家 | - |
| [cc-plugin-researcher](./cc-plugin-researcher/) | Claude Code 插件（MCP）调研专家 | - |

## 添加新 Skill

1. 在 `skills/` 目录下创建 Skill 文件夹
2. 包含 `SKILL.md` 文件（遵循 AgentSkills 规范）
3. 提交并推送到仓库

## SKILL.md 规范

```markdown
---
name: skill-name
description: 技能描述（用于触发技能）
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
