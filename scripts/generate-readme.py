#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Generate README.md from registry.json"""

import json
import os
import sys

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    registry_path = os.path.join(root, "registry.json")
    readme_path = os.path.join(root, "README.md")

    with open(registry_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    skills = data.get("skills", [])

    TIER_BADGES = {
        "core": "![core](https://img.shields.io/badge/tier-core-green)",
        "standard": "![standard](https://img.shields.io/badge/tier-standard-blue)",
        "basic": "![basic](https://img.shields.io/badge/tier-basic-yellow)",
        "experimental": "![experimental](https://img.shields.io/badge/tier-experimental-orange)",
    }

    lines = []
    lines.append("# Claude Code Skills Marketplace")
    lines.append("")
    lines.append("> \u4e2a\u4eba Claude Code Agent Skills \u96c6\u5408\uff0c\u9075\u5faa [Agent Skills \u89c4\u8303](https://agentskills.io/specification)\uff0c\u901a\u8fc7 [skills.sh](https://skills.sh) \u5206\u53d1\u3002")
    lines.append("")
    lines.append("## \u5b89\u88c5 Skills")
    lines.append("")
    lines.append("```bash")
    lines.append("# \u4ece GitHub \u5b89\u88c5\u6307\u5b9a\u6280\u80fd")
    lines.append("npx skills add kongshan001/cc_skills_marketplace/<skill-name>")
    lines.append("")
    lines.append("# \u5168\u5c40\u5b89\u88c5")
    lines.append("npx skills add kongshan001/cc_skills_marketplace/<skill-name> -g -y")
    lines.append("```")
    lines.append("")
    lines.append("## \u53ef\u7528 Skills")
    lines.append("")
    lines.append("| Skill | \u63cf\u8ff0 | \u7b49\u7ea7 | \u7248\u672c |")
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
    lines.append("### \u8d28\u91cf\u7b49\u7ea7\u8bf4\u660e")
    lines.append("")
    lines.append("| \u7b49\u7ea7 | \u542b\u4e49 |")
    lines.append("|------|------|")
    lines.append("| ![core](https://img.shields.io/badge/tier-core-green) | \u5b8c\u5168\u7b26\u5408\u89c4\u8303\uff0c\u6709 references/\u3001\u5b8c\u6574 frontmatter\u3001body < 500 \u884c |")
    lines.append("| ![standard](https://img.shields.io/badge/tier-standard-blue) | \u57fa\u672c\u7b26\u5408\u89c4\u8303\uff0c\u5141\u8bb8\u7f3a references/ \u6216\u90e8\u5206 frontmatter \u5b57\u6bb5 |")
    lines.append("| ![basic](https://img.shields.io/badge/tier-basic-yellow) | \u529f\u80fd\u53ef\u7528\uff0c\u4f46\u6709\u591a\u9879\u4e0d\u5408\u89c4\uff08\u5982\u8d85\u957f\u3001\u547d\u540d\u4e0d\u89c4\u8303\u7b49\uff09 |")
    lines.append("| ![experimental](https://img.shields.io/badge/tier-experimental-orange) | \u5b9e\u9a8c\u6027\uff0cWIP |")
    lines.append("")
    lines.append("## \u6dfb\u52a0\u65b0 Skill")
    lines.append("")
    lines.append("1. \u5728\u4ed3\u5e93\u6839\u76ee\u5f55\u521b\u5efa\u6280\u80fd\u6587\u4ef6\u5939\uff08\u4f7f\u7528 gerund \u547d\u540d\uff0c\u5982 `generating-docs`\uff09")
    lines.append("2. \u5305\u542b `SKILL.md` \u6587\u4ef6\uff08\u9075\u5faa [Agent Skills \u89c4\u8303](https://agentskills.io/specification)\uff09")
    lines.append("3. \u5305\u542b `README.md`\uff08\u5b89\u88c5\u8bf4\u660e\u548c\u4f7f\u7528\u793a\u4f8b\uff09")
    lines.append("4. \u8fd0\u884c\u9a8c\u8bc1\uff1a`bash scripts/validate-skill.sh <skill-name>`")
    lines.append("5. \u66f4\u65b0 `registry.json` \u6dfb\u52a0\u6280\u80fd\u6761\u76ee")
    lines.append("6. \u8fd0\u884c `bash scripts/generate-readme.sh` \u91cd\u65b0\u751f\u6210 README")
    lines.append("7. \u63d0\u4ea4 PR")
    lines.append("")
    lines.append("## SKILL.md \u89c4\u8303")
    lines.append("")
    lines.append("```yaml")
    lines.append("---")
    lines.append("name: skill-name           # \u5fc5\u586b\uff0cgerund \u5f62\u5f0f\uff0c\u4e0e\u76ee\u5f55\u540d\u4e00\u81f4")
    lines.append("description: \u6280\u80fd\u63cf\u8ff0...     # \u5fc5\u586b\uff0c\u7b2c\u4e09\u4eba\u79f0\uff0c< 1024 \u5b57\u7b26")
    lines.append("license: Apache-2.0        # \u63a8\u8350")
    lines.append("metadata:")
    lines.append("  version: \"1.0.0\"         # SemVer")
    lines.append("  author: \"your-name\"")
    lines.append("  tags: [\"tag1\", \"tag2\"]")
    lines.append("---")
    lines.append("```")
    lines.append("")
    lines.append("## \u9a8c\u8bc1")
    lines.append("")
    lines.append("```bash")
    lines.append("# \u9a8c\u8bc1\u5355\u4e2a\u6280\u80fd")
    lines.append("bash scripts/validate-skill.sh <skill-name>")
    lines.append("")
    lines.append("# \u9a8c\u8bc1\u6240\u6709\u6280\u80fd")
    lines.append("bash scripts/validate-all.sh")
    lines.append("")
    lines.append("# \u9a8c\u8bc1\u6ce8\u518c\u8868\u4e00\u81f4\u6027")
    lines.append("bash scripts/validate-registry.sh")
    lines.append("```")
    lines.append("")
    lines.append("## \u66f4\u591a\u4fe1\u606f")
    lines.append("")
    lines.append("- [Agent Skills \u89c4\u8303](https://agentskills.io/specification)")
    lines.append("- [Anthropic \u6700\u4f73\u5b9e\u8df5](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)")
    lines.append("- [skills.sh](https://skills.sh) - AI Agent Skills \u76ee\u5f55")
    lines.append("- [Claude Code \u6587\u6863](https://code.claude.com/docs) - Claude Code \u5b98\u65b9\u6587\u6863")
    lines.append("")

    with open(readme_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")

    print("README.md generated from registry.json")

if __name__ == "__main__":
    main()
