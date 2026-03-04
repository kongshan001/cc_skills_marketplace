# Claude Code Skills Marketplace

> 自定义 Skills 集合，对接 skill.sh

## 安装 Skills

```bash
npx skills add <skill-name>
```

## 可用 Skills

| Skill | 描述 | 状态 |
|-------|------|------|
| cc-skills-researcher | Claude Code Skills 调研专家 | ✅ |
| cc-plugin-researcher | Claude Code 插件（MCP）调研专家 | ✅ |

## 添加新 Skill

1. 在 `skills/` 目录下创建 Skill 文件夹
2. 包含 `SKILL.md` 文件
3. 提交并推送到仓库

## 使用方式

```bash
# 调研 Skills
npx skills add cc-skills-researcher

# 调研插件
npx skills add cc-plugin-researcher
```

## 提交规范

- Skill 名称使用小写字母、数字和连字符
- 必须包含 `SKILL.md` 文件
- 参考 skill.sh 规范编写
