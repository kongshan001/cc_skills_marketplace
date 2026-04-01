#!/usr/bin/env bash
# validate-registry.sh - Validate registry.json consistency with disk
# Usage: ./scripts/validate-registry.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$ROOT_DIR/registry.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=0
FAIL=0

echo "=== Validating registry.json ==="

# Check registry.json exists
if [[ ! -f "$REGISTRY" ]]; then
  echo -e "${RED}[FAIL]${NC} registry.json not found at $REGISTRY"
  exit 1
fi

# Extract skill paths from registry
REGISTRY_PATHS=$(python -c "
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
for skill in data.get('skills', []):
    print(skill['path'])
" "$REGISTRY" 2>/dev/null | tr -d '\r')

if [[ -z "$REGISTRY_PATHS" ]]; then
  echo -e "${RED}[FAIL]${NC} No skills found in registry.json"
  exit 1
fi

# Check each registry skill exists on disk
while IFS= read -r skill_path; do
  FULL_PATH="$ROOT_DIR/$skill_path"
  if [[ -d "$FULL_PATH" ]]; then
    if [[ -f "$FULL_PATH/SKILL.md" ]]; then
      echo -e "${GREEN}[PASS]${NC} $skill_path - exists with SKILL.md"
      PASS=$((PASS + 1))
    else
      echo -e "${RED}[FAIL]${NC} $skill_path - directory exists but no SKILL.md"
      FAIL=$((FAIL + 1))
    fi
  else
    echo -e "${RED}[FAIL]${NC} $skill_path - directory not found"
    FAIL=$((FAIL + 1))
  fi
done <<< "$REGISTRY_PATHS"

# Check for skills on disk not in registry
echo ""
echo "--- Checking for unregistered skills ---"
for skill_dir in "$ROOT_DIR"/*/; do
  if [[ -f "$skill_dir/SKILL.md" ]]; then
    SKILL_NAME=$(basename "$skill_dir")
    if echo "$REGISTRY_PATHS" | grep -qx "$SKILL_NAME"; then
      :
    else
      echo -e "${YELLOW}[WARN]${NC} $SKILL_NAME exists on disk but not in registry.json"
    fi
  fi
done

# Validate JSON syntax
if python -c "
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    json.load(f)
" "$REGISTRY" 2>/dev/null; then
  echo -e "${GREEN}[PASS]${NC} registry.json is valid JSON"
  PASS=$((PASS + 1))
else
  echo -e "${RED}[FAIL]${NC} registry.json has invalid JSON syntax"
  FAIL=$((FAIL + 1))
fi

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "Overall: ${GREEN}PASS${NC} | $PASS checks passed"
else
  echo -e "Overall: ${RED}FAIL${NC} | $PASS passed, $FAIL failed"
fi

exit $FAIL
