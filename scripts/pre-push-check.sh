#!/usr/bin/env bash
# =============================================================================
# Pathfinder Frontend Pre-Push Check Script
# =============================================================================
# Runs all quality gates before allowing a push to remote.
# This script is called by the git pre-push hook.
#
# Checks (run in parallel where possible):
#   1. ESLint + TypeScript type check (parallel)
#   2. Tests (if test script exists)
#   3. Build verification
#   4. Security audit (npm audit)
#
# Manual reviews (run these yourself BEFORE pushing):
#   coderabbit review --plain --base main    — CodeRabbit CLI review
#   /review-fix                               — CodeRabbit + Claude + security review loop
#
# Exit codes:
#   0 — All checks passed, push is allowed
#   1 — One or more checks failed, push is blocked
#
# Usage:
#   ./scripts/pre-push-check.sh          # Run all checks
#   ./scripts/pre-push-check.sh --quick  # Skip tests (for emergency fixes only)
# =============================================================================

set -euo pipefail

# ---- Configuration ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
QUICK_MODE=false

if [ "${1:-}" = "--quick" ]; then
  QUICK_MODE=true
  echo "WARNING: Quick mode — skipping tests. Use only for emergencies!"
fi

# ---- Temp files (cleaned up on exit) ----
TMPFILE=$(mktemp /tmp/pathfinder-frontend-pre-push-XXXXXX.log)
SEC_TMPFILE=$(mktemp /tmp/pathfinder-frontend-security-XXXXXX.json)
LINT_TMPFILE=$(mktemp /tmp/pathfinder-frontend-lint-XXXXXX.log)
TSC_TMPFILE=$(mktemp /tmp/pathfinder-frontend-tsc-XXXXXX.log)
trap 'rm -f "$TMPFILE" "$SEC_TMPFILE" "$LINT_TMPFILE" "$TSC_TMPFILE"' EXIT

# ---- Colors for output ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No color

# ---- Track results ----
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
RESULTS=()
START_TIME=$(date +%s)

# ---- Helper functions ----

print_header() {
  echo ""
  echo -e "${BLUE}============================================${NC}"
  echo -e "${BLUE}  Pathfinder Frontend Pre-Push Quality Gates${NC}"
  echo -e "${BLUE}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
  echo -e "${BLUE}============================================${NC}"
  echo ""
}

record_result() {
  local check_name=$1
  local exit_code=$2
  local duration=$3

  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

  if [ "$exit_code" -eq 0 ]; then
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    RESULTS+=("${GREEN}PASS${NC}  ${check_name} (${duration}s)")
    echo -e "  ${GREEN}PASS${NC} (${duration}s)"
  else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    RESULTS+=("${RED}FAIL${NC}  ${check_name} (${duration}s)")
    echo -e "  ${RED}FAIL${NC} (${duration}s)"
  fi
}

run_check() {
  local check_name=$1
  shift
  local check_start=$(date +%s)
  local exit_code=0

  "$@" > $TMPFILE 2>&1 || exit_code=$?

  local check_end=$(date +%s)
  local duration=$((check_end - check_start))

  record_result "$check_name" "$exit_code" "$duration"

  if [ "$exit_code" -ne 0 ]; then
    echo -e "  ${YELLOW}Output:${NC}"
    tail -20 $TMPFILE | sed 's/^/    /'
    echo ""
  fi

  return "$exit_code"
}

print_summary() {
  local end_time=$(date +%s)
  local total_duration=$((end_time - START_TIME))
  local minutes=$((total_duration / 60))
  local seconds=$((total_duration % 60))

  echo ""
  echo -e "${BLUE}============================================${NC}"
  echo -e "${BLUE}  Pre-Push Check Summary${NC}"
  echo -e "${BLUE}============================================${NC}"
  echo ""

  for result in "${RESULTS[@]}"; do
    echo -e "  $result"
  done

  echo ""
  echo -e "  Total: ${TOTAL_CHECKS} checks | ${GREEN}${PASSED_CHECKS} passed${NC} | ${RED}${FAILED_CHECKS} failed${NC}"
  echo -e "  Duration: ${minutes}m ${seconds}s"
  echo ""

  if [ "$FAILED_CHECKS" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}ALL CHECKS PASSED — push allowed${NC}"
  else
    echo -e "  ${RED}${BOLD}CHECKS FAILED — push blocked${NC}"
    echo -e "  ${YELLOW}Fix the issues above and try again.${NC}"
  fi

  echo -e "${BLUE}============================================${NC}"
  echo ""
}

# ==========================================================================
# Main execution
# ==========================================================================

cd "$PROJECT_ROOT"

print_header

HAS_FAILURES=0

# --------------------------------------------------------------------------
# Check 1+2: Lint + Type Check (PARALLEL — saves ~20s)
# --------------------------------------------------------------------------
echo -e "${BOLD}[1/4] Frontend ESLint + TypeScript Type Check (parallel)...${NC}"
PARALLEL_START=$(date +%s)

LINT_EXIT=0
TSC_EXIT=0

npm run lint > "$LINT_TMPFILE" 2>&1 &
LINT_PID=$!

npm run type-check > "$TSC_TMPFILE" 2>&1 &
TSC_PID=$!

wait $LINT_PID || LINT_EXIT=$?
wait $TSC_PID || TSC_EXIT=$?

PARALLEL_END=$(date +%s)
PARALLEL_DURATION=$((PARALLEL_END - PARALLEL_START))

# Record lint result
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ "$LINT_EXIT" -eq 0 ]; then
  PASSED_CHECKS=$((PASSED_CHECKS + 1))
  RESULTS+=("${GREEN}PASS${NC}  Frontend Lint (${PARALLEL_DURATION}s)")
  echo -e "  Lint:       ${GREEN}PASS${NC}"
else
  FAILED_CHECKS=$((FAILED_CHECKS + 1))
  RESULTS+=("${RED}FAIL${NC}  Frontend Lint (${PARALLEL_DURATION}s)")
  echo -e "  Lint:       ${RED}FAIL${NC}"
  echo -e "  ${YELLOW}Output:${NC}"
  tail -20 "$LINT_TMPFILE" | sed 's/^/    /'
  echo ""
  HAS_FAILURES=1
fi

# Record type-check result
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ "$TSC_EXIT" -eq 0 ]; then
  PASSED_CHECKS=$((PASSED_CHECKS + 1))
  RESULTS+=("${GREEN}PASS${NC}  Frontend Type Check (${PARALLEL_DURATION}s)")
  echo -e "  Type Check: ${GREEN}PASS${NC}"
else
  FAILED_CHECKS=$((FAILED_CHECKS + 1))
  RESULTS+=("${RED}FAIL${NC}  Frontend Type Check (${PARALLEL_DURATION}s)")
  echo -e "  Type Check: ${RED}FAIL${NC}"
  echo -e "  ${YELLOW}Output:${NC}"
  tail -20 "$TSC_TMPFILE" | sed 's/^/    /'
  echo ""
  HAS_FAILURES=1
fi

echo -e "  Combined:   ${PARALLEL_DURATION}s"

# --------------------------------------------------------------------------
# Check 3: Frontend Tests
# --------------------------------------------------------------------------
if [ "$QUICK_MODE" = true ]; then
  echo -e "  ${YELLOW}SKIP${NC} — Quick mode, tests skipped"
  RESULTS+=("${YELLOW}SKIP${NC}  Frontend Tests — quick mode")
elif node -e "const p=require('./package.json'); if(!p.scripts||!p.scripts.test){process.exit(1)}" 2>/dev/null; then
  echo -e "${BOLD}[2/4] Frontend Tests...${NC}"
  run_check "Frontend Tests" npm test || HAS_FAILURES=1
else
  echo -e "  ${YELLOW}SKIP${NC} — No test script in package.json (add 'test' script when ready)"
  RESULTS+=("${YELLOW}SKIP${NC}  Frontend Tests — no test script yet")
fi

# --------------------------------------------------------------------------
# Check 4: Frontend Build
# --------------------------------------------------------------------------
echo -e "${BOLD}[3/4] Frontend Build...${NC}"
run_check "Frontend Build" npm run build || HAS_FAILURES=1

# --------------------------------------------------------------------------
# Check 5: Security Audit
# --------------------------------------------------------------------------
echo -e "${BOLD}[4/4] Security Audit (npm audit)...${NC}"
SEC_START=$(date +%s)
SEC_EXIT=0
npm audit --json > $SEC_TMPFILE 2>&1 || SEC_EXIT=$?
SEC_END=$(date +%s)
SEC_DURATION=$((SEC_END - SEC_START))

if [ "$SEC_EXIT" -eq 0 ]; then
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  PASSED_CHECKS=$((PASSED_CHECKS + 1))
  RESULTS+=("${GREEN}PASS${NC}  Security Audit (${SEC_DURATION}s)")
  echo -e "  ${GREEN}PASS${NC} (${SEC_DURATION}s)"
else
  CRITICAL_COUNT=$(node -e "try{const d=JSON.parse(require('fs').readFileSync('$SEC_TMPFILE','utf8'));console.log((d.metadata&&d.metadata.vulnerabilities&&d.metadata.vulnerabilities.critical)||0)}catch(e){console.log(0)}" 2>/dev/null || echo "0")
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  if [ "$CRITICAL_COUNT" -gt 0 ]; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    RESULTS+=("${RED}FAIL${NC}  Security Audit — critical vulnerabilities found (${SEC_DURATION}s)")
    echo -e "  ${RED}FAIL${NC} — critical vulnerabilities found (${SEC_DURATION}s)"
    echo -e "  ${YELLOW}Run 'npm audit' to see details${NC}"
    HAS_FAILURES=1
  else
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    RESULTS+=("${YELLOW}WARN${NC}  Security Audit — non-critical issues (advisory) (${SEC_DURATION}s)")
    echo -e "  ${YELLOW}WARN${NC} — non-critical issues (advisory) (${SEC_DURATION}s)"
  fi
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
print_summary

# Exit with appropriate code
if [ "$HAS_FAILURES" -ne 0 ]; then
  exit 1
fi

exit 0
