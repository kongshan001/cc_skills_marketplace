---
name: cc-plugin-researcher
description: Claude Code 插件（MCP）调研专家。用于定期调研 Claude Code 热门 MCP 插件，搜索 GitHub/awesome-claude-code 生成调研报告并推送到远程仓库。适用于：(1) 用户要求调研 MCP 插件 (2) 定时任务需要生成插件调研报告 (3) 分析热门 MCP 服务器并整理文档
---

# Claude Code 插件调研

## 核心任务

1. 搜索 GitHub/awesome-claude-code 热门 MCP 插件
2. 分析以下方向：
   - 游戏客户端开发插件
   - Python 开发插件
   - 自动化测试插件
   - 开发者工具插件
3. 生成调研文档，推送到 GitHub

## 工作流程

### 1. 搜索热门插件

```bash
# 搜索 MCP 相关仓库
gh search repo "mcp" --sort stars --order desc --limit 30

# 搜索 Claude Code 插件
gh search repo "claude-code" --sort stars --order desc --limit 20
```

### 2. 调研方向

优先关注：
- **游戏客户端开发**: Claude-Code-Game-Studios, Unreal-MCP, pixel-plugin, Godot-Development
- **Python 开发**: Pydantic-AI-Skills, FastAPI-MCP, Django-MCP
- **自动化测试**: Playwright-MCP, TestSprite-MCP, Percy-MCP
- **开发者工具**: Superpowers, Lazy-Bird, AWS-MCP-Server, Context7-MCP

### 3. 生成报告

报告格式：
- 文档位置：`/root/.openclaw/workspace/cc_plugin/supplement-YYYY-MM-DD-vXX/README.md`
- 更新 README.md 添加链接

### 4. 推送到 GitHub

```bash
cd /root/.openclaw/workspace/cc_plugin
git add -A
git commit -m "docs: 添加插件调研 vXX"
git push origin main
```

## 输出要求

- 生成完整的 Markdown 调研报告
- 包含热门插件排行榜
- 分析各方向发展趋势
- 推送到 https://github.com/kongshan001/cc_plugin

## 注意事项

- 工作目录：`/root/.openclaw/workspace/cc_plugin`
- 使用绝对路径操作文件
- 调研完成后自动推送，无需询问用户
- 遇到编辑错误时，检查文件路径是否正确
