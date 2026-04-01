# cc_skills_marketplace

个人 Claude Code Skills Marketplace，收集和分发自定义 Agent Skills。

## 项目结构

```
cc_skills_marketplace/
├── CLAUDE.md              # 本文件，项目上下文
├── README.md              # 自动生成的目录（从 registry.json）
├── registry.json          # 机器可读技能注册表（唯一事实来源）
├── registry-schema.json   # 注册表 JSON Schema
├── scripts/
│   ├── validate-skill.sh      # 验证单个技能
│   ├── validate-all.sh        # 验证所有技能
│   ├── validate-registry.sh   # 验证注册表一致性
│   └── generate-readme.sh     # 从 registry.json 生成 README.md
└── <skill-name>/          # 每个技能一个目录
    ├── SKILL.md           # 必填：技能定义
    ├── README.md          # 必填：使用说明
    └── references/        # 可选：补充文档
```

## 开发规范

### Skill 命名
- 使用 gerund 形式：`generating-python-docs`、`researching-skills`
- 小写字母 + 数字 + 连字符，max 64 字符
- 目录名必须与 SKILL.md `name` 字段一致

### SKILL.md 要求
- Frontmatter 必填：`name`、`description`
- Frontmatter 推荐：`license`、`compatibility`、`metadata.version`
- Body < 500 行，超出部分提取到 `references/`
- description 用第三人称，包含触发关键词

### 质量分级
- `core`: 完全符合规范，有 references/、完整 frontmatter
- `standard`: 基本符合，允许缺 references/ 或部分字段
- `basic`: 有效但有多项不合规
- `experimental`: WIP

### 开发流程
1. 修改技能后运行 `bash scripts/validate-skill.sh <skill-name>`
2. 更新 `registry.json` 中的版本号和描述
3. 运行 `bash scripts/validate-registry.sh` 确认一致性
4. 运行 `bash scripts/generate-readme.sh` 更新 README
5. 提交 PR

## 参考文档
- [Agent Skills 规范](https://agentskills.io/specification)
- [Anthropic 最佳实践](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [skills.sh](https://skills.sh)
