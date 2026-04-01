#!/usr/bin/env bash
# validate-skill.sh - Validate a single skill directory against Agent Skills specification
# Usage: ./scripts/validate-skill.sh <skill-directory>

set -euo pipefail

SKILL_DIR="${1:?Usage: validate-skill.sh <skill-directory>}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0
WARN=0

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo -e "  ${RED}[FAIL]${NC} $1"; }
warn() { WARN=$((WARN + 1)); echo -e "  ${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "  ${GREEN}[PASS]${NC} $1"; pass; }

SKILL_NAME=$(basename "$SKILL_DIR")
SKILL_FILE="$SKILL_DIR/SKILL.md"

echo ""
echo "=== Validating: $SKILL_NAME ==="

# ============================================================
# Phase 1: Structure Checks
# ============================================================
echo ""
echo "--- Phase 1: Structure ---"

if [[ -f "$SKILL_FILE" ]]; then
  info "SKILL.md exists"
else
  fail "SKILL.md NOT found at $SKILL_FILE"
  echo "Cannot continue validation without SKILL.md"
  exit 1
fi

if [[ -f "$SKILL_DIR/README.md" ]]; then
  info "README.md exists"
else
  warn "README.md not found (recommended)"
fi

# Extract name field from frontmatter
FM_NAME=""
if command -v python &>/dev/null; then
  FM_NAME=$(python -c "
import re, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    content = f.read()
match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
if match:
    for line in match.group(1).split('\n'):
        if line.startswith('name:'):
            print(line.split(':',1)[1].strip().strip('\"').strip(\"'\"))
            break
" "$SKILL_FILE" 2>/dev/null || echo "")
fi

if [[ -n "$FM_NAME" ]]; then
  if [[ "$FM_NAME" == "$SKILL_NAME" ]]; then
    info "Directory name matches frontmatter name field ($SKILL_NAME)"
  else
    fail "Directory name '$SKILL_NAME' does not match frontmatter name '$FM_NAME'"
  fi
else
  warn "Could not extract name field from frontmatter"
fi

# ============================================================
# Phase 2: Frontmatter Checks
# ============================================================
echo ""
echo "--- Phase 2: Frontmatter ---"

# Check YAML frontmatter exists
FM_CONTENT=$(python -c "
import re, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    content = f.read()
match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
if match:
    print(match.group(1))
else:
    print('')
" "$SKILL_FILE" 2>/dev/null || echo "")

if [[ -n "$FM_CONTENT" ]]; then
  info "YAML frontmatter is parseable"
else
  fail "YAML frontmatter not found or not parseable"
fi

# Check name field
if echo "$FM_CONTENT" | grep -q "^name:"; then
  info "name field exists"
  # Validate name format
  if echo "$FM_NAME" | grep -qE "^[a-z][a-z0-9-]*[a-z0-9]$|^[a-z]$"; then
    info "name format valid (lowercase + numbers + hyphens)"
  else
    fail "name '$FM_NAME' does not match pattern: lowercase letters, numbers, hyphens only"
  fi
  # Check name length
  if [[ ${#FM_NAME} -le 64 ]]; then
    info "name length <= 64 characters (${#FM_NAME})"
  else
    fail "name exceeds 64 characters (${#FM_NAME})"
  fi
else
  fail "name field missing from frontmatter"
fi

# Check description field
FM_DESC=$(echo "$FM_CONTENT" | python -c "
import sys
content = sys.stdin.read()
in_desc = False
lines = []
for line in content.split('\n'):
    if line.startswith('description:') or line.startswith('description >'):
        in_desc = True
        val = line.split(':',1)[1].strip()
        if val and val != '>':
            lines.append(val)
        continue
    if in_desc:
        if line.startswith('  ') or line.startswith('\t'):
            lines.append(line.strip())
        else:
            break
print(' '.join(lines))
" 2>/dev/null || echo "")

if [[ -n "$FM_DESC" ]]; then
  info "description field exists"
  # Check third-person (no first/second person)
  if echo "$FM_DESC" | grep -qE "^(我|我 |You |I |We |My |我们的)"; then
    warn "description may not be in third person"
  else
    info "description appears to be third-person"
  fi
  # Check length
  DESC_LEN=${#FM_DESC}
  if [[ $DESC_LEN -le 1024 ]]; then
    info "description length <= 1024 characters ($DESC_LEN)"
  else
    fail "description exceeds 1024 characters ($DESC_LEN)"
  fi
else
  fail "description field missing or empty"
fi

# ============================================================
# Phase 3: Content Checks
# ============================================================
echo ""
echo "--- Phase 3: Content ---"

# Count body lines (after closing ---)
BODY_LINES=$(python -c "
import sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    lines = f.readlines()
count = 0
found_end = False
for i, line in enumerate(lines):
    if i == 0 and line.strip() == '---':
        continue
    if not found_end:
        if line.strip() == '---':
            found_end = True
        continue
    count += 1
print(count)
" "$SKILL_FILE" 2>/dev/null || echo "0")

if [[ "$BODY_LINES" -le 500 ]]; then
  info "SKILL.md body is $BODY_LINES lines (<= 500)"
elif [[ "$BODY_LINES" -le 800 ]]; then
  warn "SKILL.md body is $BODY_LINES lines (> 500, recommended limit)"
else
  fail "SKILL.md body is $BODY_LINES lines (> 800, hard limit)"
fi

# Check for hardcoded absolute paths
if grep -qE "/root/|/home/|/Users/" "$SKILL_FILE" 2>/dev/null; then
  warn "Found hardcoded Unix absolute paths in SKILL.md"
else
  info "No hardcoded absolute paths detected"
fi

# ============================================================
# Phase 4: Quality Checks (core tier)
# ============================================================
echo ""
echo "--- Phase 4: Quality ---"

if [[ -d "$SKILL_DIR/references" ]]; then
  REF_COUNT=$(find "$SKILL_DIR/references" -name "*.md" 2>/dev/null | wc -l)
  if [[ "$REF_COUNT" -gt 0 ]]; then
    info "references/ directory exists with $REF_COUNT file(s)"
  else
    warn "references/ directory exists but contains no .md files"
  fi
else
  warn "references/ directory not found"
fi

if echo "$FM_CONTENT" | grep -q "^license:"; then
  info "license field present in frontmatter"
else
  warn "license field missing from frontmatter"
fi

if echo "$FM_CONTENT" | grep -q "version:"; then
  info "version field present in frontmatter"
else
  warn "version field missing from frontmatter (add metadata.version)"
fi

if echo "$FM_CONTENT" | grep -q "compatibility:"; then
  info "compatibility field present in frontmatter"
else
  warn "compatibility field missing from frontmatter"
fi

# ============================================================
# Phase 5: Reference File Checks
# ============================================================
if [[ -d "$SKILL_DIR/references" ]]; then
  echo ""
  echo "--- Phase 5: References ---"

  for ref_file in "$SKILL_DIR/references"/*.md; do
    [[ -f "$ref_file" ]] || continue
    REF_NAME=$(basename "$ref_file")
    REF_LINES=$(wc -l < "$ref_file")
    if [[ "$REF_LINES" -gt 100 ]]; then
      # Check for TOC
      if grep -qiE "^##.*Contents|^##.*目录|^##.*Table of Contents" "$ref_file"; then
        info "$REF_NAME is $REF_LINES lines but has TOC"
      else
        warn "$REF_NAME is $REF_LINES lines (>100) and missing TOC"
      fi
    else
      info "$REF_NAME is $REF_LINES lines (<= 100)"
    fi
  done
fi

# ============================================================
# Summary
# ============================================================
echo ""
TOTAL=$((PASS + FAIL + WARN))
if [[ $FAIL -eq 0 ]]; then
  echo -e "Overall: ${GREEN}PASS${NC} | $PASS passed, $WARN warnings"
else
  echo -e "Overall: ${RED}FAIL${NC} | $PASS passed, $FAIL failed, $WARN warnings"
fi

exit $FAIL
