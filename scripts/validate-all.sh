#!/usr/bin/env bash
# validate-all.sh - Validate all skill directories in the marketplace
# Usage: ./scripts/validate-all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================="
echo " CC Skills Marketplace - Validate All"
echo "========================================="

TOTAL_PASS=0
TOTAL_FAIL=0

# Find all directories containing SKILL.md
for skill_dir in "$ROOT_DIR"/*/; do
  if [[ -f "$skill_dir/SKILL.md" ]]; then
    if bash "$SCRIPT_DIR/validate-skill.sh" "$skill_dir"; then
      TOTAL_PASS=$((TOTAL_PASS + 1))
    else
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
  fi
done

echo ""
echo "========================================="
if [[ $TOTAL_FAIL -eq 0 ]]; then
  echo -e " All skills passed ($TOTAL_PASS/$((TOTAL_PASS + TOTAL_FAIL)))"
else
  echo -e " $TOTAL_FAIL skill(s) failed, $TOTAL_PASS passed"
fi
echo "========================================="

exit $TOTAL_FAIL
