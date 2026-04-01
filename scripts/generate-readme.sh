#!/usr/bin/env bash
# generate-readme.sh - Generate README.md from registry.json
# Usage: ./scripts/generate-readme.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$ROOT_DIR/registry.json"
README="$ROOT_DIR/README.md"

if [[ ! -f "$REGISTRY" ]]; then
  echo "Error: registry.json not found"
  exit 1
fi

python -c "
import json, sys, os
registry_path = sys.argv[1]
readme_path = sys.argv[2]

with open(registry_path, "r", encoding="utf-8") as f:
    data = json.load(f)

skills = data.get("skills", [])

# Tier badges
TIER_BADGES = {
    "core": "![core](https://img.shields.io/badge/tier-core-green)",
    "standard": "![standard](https://img.shields.io/badge/tier-standard-blue)",
    "basic": "![basic](https://img.shields.io/badge/tier-basic-yellow)",
    "experimental": "![experimental](https://img.shields.io/badge/tier-experimental-orange)",
}

lines = []
lines.append("# Claude Code Skills Marketplace")
lines.append("")
lines.append("> 个人 Claude Code Agent Skills 集合，遵循 [Agent Skills 规范](https://agentskills.io/specification)，通过 [skills.sh](https://skills.sh) 分发。")
lines.append("")
lines.append("## 安装 Skills")
lines.append("")
lines.append("```bash")
lines.append("# 从 GitHub 安装指定技能")
lines.append("npx skills add kongshan001/cc_skills_marketplace/<skill-name>")
lines.append("")
lines.append("# 全局安装")
lines.append("npx skills add kongshan001/cc_skills_marketplace/<skill-name> -g -y")
lines.append("```")
lines.append("")
lines.append("## 可用 Skills")
lines.append("")
lines.append("| Skill | 描述 | 等级 | 版本 |")
lines.append("|-------|------|------|------|")

for skill in skills:
    name = skill["name"]
    desc = skill["description"]
    if len(desc) > 60:
        desc = desc[:57] + "..."
    tier = skill.get("tier", "basic")
    badge = TIER_BADGES.get(tier, tier)
    version = skill.get("version", "-")
    lines.append(f"| [{name}](./{skill['path']}/) | {desc} | {badge} | {version} |")

lines.append("")
lines.append("### 质量等级说明")
lines.append("")
lines.append("| 等级 | 含义 |")
lines.append("|------|------|")
lines.append("| ![core](https://img.shields.io/badge/tier-core-green) | 完全符合规范，有 references/、完整 frontmatter、body < 500 行 |")
lines.append("| ![standard](https://img.shields.io/badge/tier-standard-blue) | 基本符合规范，允许缺 references/ 或部分 frontmatter 字段 |")
lines.append("| ![basic](https://img.shields.io/badge/tier-basic-yellow) | 功能可用，但有多项不合规（如超长、命名不规范等） |")
lines.append("| ![experimental](https://img.shields.io/badge/tier-experimental-orange) | 实验性，WIP |")
lines.append("")
lines.append("## 添加新 Skill")
lines.append("")
lines.append("1. 在仓库根目录创建技能文件夹（使用 gerund 命名，如 `generating-docs`）")
lines.append("2. 包含 `SKILL.md` 文件（遵循 [Agent Skills 规范](https://agentskills.io/specification)）")
lines.append("3. 包含 `README.md`（安装说明和使用示例）")
lines.append("4. 运行验证：`bash scripts/validate-skill.sh <skill-name>`")
lines.append("5. 更新 `registry.json` 添加技能条目")
lines.append("6. 运行 `bash scripts/generate-readme.sh` 重新生成 README")
lines.append("7. 提交 PR")
lines.append("")
lines.append("## SKILL.md 规范")
lines.append("")
lines.append("```yaml")
lines.append("---")
lines.append("name: skill-name           # 必填，gerund 形式，与目录名一致")
lines.append("description: 技能描述...     # 必填，第三人称，< 1024 字符")
lines.append("license: Apache-2.0        # 推荐")
lines.append("metadata:")
lines.append("  version: \"1.0.0\"         # SemVer")
lines.append("  author: \"your-name\"")
lines.append("  tags: [\"tag1\", \"tag2\"]")
lines.append("---")
lines.append("```")
lines.append("")
lines.append("## 验证")
lines.append("")
lines.append("```bash")
lines.append("# 验证单个技能")
lines.append("bash scripts/validate-skill.sh <skill-name>")
lines.append("")
lines.append("# 验证所有技能")
lines.append("bash scripts/validate-all.sh")
lines.append("")
lines.append("# 验证注册表一致性")
lines.append("bash scripts/validate-registry.sh")
lines.append("```")
lines.append("")
lines.append("## 更多信息")
lines.append("")
lines.append("- [Agent Skills 规范](https://agentskills.io/specification)")
lines.append("- [Anthropic 最佳实践](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)")
lines.append("- [skills.sh](https://skills.sh) - AI Agent Skills 目录")
lines.append("- [Claude Code 文档](https://code.claude.com/docs) - Claude Code 官方文档")
lines.append("")

with open(readme_path, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(lines) + "\n")
PYTHON_SCRIPT

echo "README.md generated from registry.json"
