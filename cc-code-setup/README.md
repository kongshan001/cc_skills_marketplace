# cc-code-setup

一键生成完整的 Claude Code 项目配置，基于官方文档最佳实践。

## 安装

```bash
npx skills add kongshan001/cc_skills_marketplace/cc-code-setup
```

## 使用方式

### 方式 1: 交互式生成

```bash
/claude-code-setup
```

按照 12 步交互式流程配置项目。

### 方式 2: 预设模板

```bash
# Frontend 项目
/claude-code-setup --template frontend

# Backend 项目
/claude-code-setup --template backend

# CLI 工具
/claude-code-setup --template cli

# 库项目
/claude-code-setup --template library

# 最小配置
/claude-code-setup --template minimal
```

### 方式 3: 命令行参数

```bash
/claude-code-setup \
  --path /path/to/project \
  --name "my-api" \
  --type backend \
  --language typescript \
  --framework "Express,Prisma" \
  --rules code-style,testing,security,api-design \
  --skills review-pr \
  --agents test-writer \
  --hooks pre-tool-use \
  --mcp github,postgres \
  --yes
```

### 方式 4: JSON 配置文件

```bash
/claude-code-setup --config setup.json
```

## 生成的配置结构

```
project/
├── CLAUDE.md                    # 项目上下文
├── .mcp.json                    # MCP 服务器配置
└── .claude/
    ├── README.md                # 配置说明
    ├── settings.json            # 项目设置
    ├── settings.local.json      # 本地设置（敏感信息）
    ├── rules/                   # 模块化规则
    │   ├── code-style.md
    │   ├── testing.md
    │   └── api-design.md        # 带条件加载
    ├── skills/                  # 自定义技能
    ├── agents/                  # 自定义 Agent
    └── hooks/                   # 生命周期钩子
```

## 预设模板

| 模板 | 用途 | Rules | Skills | Agents |
|------|------|-------|--------|--------|
| frontend | React/Vue/Angular | 3 | 2 | 1 |
| backend | Node.js/Python API | 4 | 2 | 2 |
| cli | 命令行工具 | 3 | 1 | 1 |
| library | 库/包项目 | 2 | 2 | 2 |
| minimal | 最小配置 | 0 | 0 | 0 |

## 文档

- [Claude Code 官方文档](https://code.claude.com/docs)
- [Settings 配置](https://code.claude.com/docs/en/settings)
- [Memory 和 Rules](https://code.claude.com/docs/en/memory)
- [Skills](https://code.claude.com/docs/en/skills)

## License

MIT
