#!/usr/bin/env bash
# =============================================================================
# Pathfinder Frontend Pre-Push Check Script
# =============================================================================
# Runs all quality gates before allowing a push to remote.
# This script is called by the git pre-push hook.
#
# Checks (in order):
#   1. ESLint (code quality)
#   2. TypeScript type checking
#   3. Tests (if test script exists)
#   4. Build verification
#   5. Security audit (npm audit)
#   6. CodeRabbit CLI review (local — replaces GitHub CodeRabbit)
#
# IMPORTANT: Before running this script, you MUST have already run:
#   - /simplify (code reuse, quality, efficiency) — during coding
#   - /review-fix (CodeRabbit + Claude + security review loop) — before push
#   These are Claude Code skills and cannot be automated in a bash hook.
#
# Exit codes:
#   0 — All checks passed, push is allowed
#   1 — One or more checks failed, push is blocked
#
# Usage:
#   ./scripts/pre-push-check.sh          # Run all checks
#   ./scripts/pre-push-check.sh --quick  # Skip tests + CodeRabbit (for emergency fixes only)
# =============================================================================

set -euo pipefail

# ---- Configuration ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
QUICK_MODE=false

if [ "${1:-}" = "--quick" ]; then
  QUICK_MODE=true
  echo "WARNING: Quick mode — skipping tests + CodeRabbit review. Use only for emergencies!"
fi

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

print_step() {
  local step_num=$1
  local step_name=$2
  echo -e "${BOLD}[${step_num}] ${step_name}...${NC}"
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

  "$@" > /tmp/pathfinder-frontend-pre-push-output.log 2>&1 || exit_code=$?

  local check_end=$(date +%s)
  local duration=$((check_end - check_start))

  record_result "$check_name" "$exit_code" "$duration"

  if [ "$exit_code" -ne 0 ]; then
    echo -e "  ${YELLOW}Output:${NC}"
    tail -20 /tmp/pathfinder-frontend-pre-push-output.log | sed 's/^/    /'
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
# Check 1: Frontend Lint
# --------------------------------------------------------------------------
print_step "1/6" "Frontend ESLint"
run_check "Frontend Lint" npm run lint || HAS_FAILURES=1

# --------------------------------------------------------------------------
# Check 2: Frontend TypeScript Type Check
# --------------------------------------------------------------------------
print_step "2/6" "Frontend TypeScript Type Check"
run_check "Frontend Type Check" npm run type-check || HAS_FAILURES=1

# --------------------------------------------------------------------------
# Check 3: Frontend Tests
# --------------------------------------------------------------------------
if [ "$QUICK_MODE" = true ]; then
  echo -e "  ${YELLOW}SKIP${NC} — Quick mode, tests skipped"
  RESULTS+=("${YELLOW}SKIP${NC}  Frontend Tests — quick mode")
elif node -e "const p=require('./package.json'); if(!p.scripts||!p.scripts.test){process.exit(1)}" 2>/dev/null; then
  print_step "3/6" "Frontend Tests"
  run_check "Frontend Tests" npm test || HAS_FAILURES=1
else
  echo -e "  ${YELLOW}SKIP${NC} — No test script in package.json (add 'test' script when ready)"
  RESULTS+=("${YELLOW}SKIP${NC}  Frontend Tests — no test script yet")
fi

# --------------------------------------------------------------------------
# Check 4: Frontend Build
# --------------------------------------------------------------------------
print_step "4/6" "Frontend Build"
run_check "Frontend Build" npm run build || HAS_FAILURES=1

# --------------------------------------------------------------------------
# Check 5: Security Audit
# --------------------------------------------------------------------------
print_step "5/6" "Security Audit (npm audit)"
SEC_START=$(date +%s)
SEC_EXIT=0
npm audit --audit-level=critical > /tmp/pathfinder-frontend-security-output.log 2>&1 || SEC_EXIT=$?
SEC_END=$(date +%s)
SEC_DURATION=$((SEC_END - SEC_START))

if [ "$SEC_EXIT" -eq 0 ]; then
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  PASSED_CHECKS=$((PASSED_CHECKS + 1))
  RESULTS+=("${GREEN}PASS${NC}  Security Audit (${SEC_DURATION}s)")
  echo -e "  ${GREEN}PASS${NC} (${SEC_DURATION}s)"
else
  CRITICAL_COUNT=$(grep -c 'critical' /tmp/pathfinder-frontend-security-output.log 2>/dev/null || echo "0")
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
rm -f /tmp/pathfinder-frontend-security-output.log

# --------------------------------------------------------------------------
# Check 6: CodeRabbit CLI Review (local, replaces GitHub CodeRabbit)
# --------------------------------------------------------------------------
if [ "$QUICK_MODE" = true ]; then
  echo -e "  ${YELLOW}SKIP${NC} — Quick mode, CodeRabbit skipped"
  RESULTS+=("${YELLOW}SKIP${NC}  CodeRabbit Review — quick mode")
elif ! command -v coderabbit &> /dev/null; then
  echo -e "  ${YELLOW}SKIP${NC} — CodeRabbit CLI not installed. Run: curl -fsSL https://cli.coderabbit.ai/install.sh | sh"
  RESULTS+=("${YELLOW}SKIP${NC}  CodeRabbit Review — CLI not installed")
else
  print_step "6/6" "CodeRabbit CLI Review"

  CR_START=$(date +%s)
  CR_EXIT=0

  coderabbit review --plain --base main > /tmp/pathfinder-frontend-coderabbit-output.log 2>&1 || CR_EXIT=$?

  CR_END=$(date +%s)
  CR_DURATION=$((CR_END - CR_START))

  if [ "$CR_EXIT" -ne 0 ]; then
    echo -e "  ${YELLOW}WARN${NC} — CodeRabbit CLI failed (exit $CR_EXIT). Run 'coderabbit auth login' if auth expired."
    RESULTS+=("${YELLOW}WARN${NC}  CodeRabbit Review — CLI error (${CR_DURATION}s)")
  else
    # Count critical findings from CodeRabbit plain text output
    # CodeRabbit --plain outputs "Type: potential_issue", "Type: bug", "Type: security"
    CRITICAL_COUNT=$(grep -icE '(Type:\s*(potential_issue|bug|security))' /tmp/pathfinder-frontend-coderabbit-output.log 2>/dev/null || true)

    if [ "$CRITICAL_COUNT" -gt 0 ]; then
      RESULTS+=("${YELLOW}WARN${NC}  CodeRabbit Review — $CRITICAL_COUNT issue(s) found (${CR_DURATION}s)")
      echo -e "  ${YELLOW}WARN${NC} — $CRITICAL_COUNT issue(s) found (advisory) (${CR_DURATION}s)"
      echo -e "  ${YELLOW}Review manually: coderabbit review --plain --base main${NC}"
    else
      RESULTS+=("${GREEN}PASS${NC}  CodeRabbit Review — clean (${CR_DURATION}s)")
      echo -e "  ${GREEN}PASS${NC} — clean (${CR_DURATION}s)"
    fi
  fi

  rm -f /tmp/pathfinder-frontend-coderabbit-output.log
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
print_summary

# Clean up temp file
rm -f /tmp/pathfinder-frontend-pre-push-output.log

# Exit with appropriate code
if [ "$HAS_FAILURES" -ne 0 ]; then
  exit 1
fi

exit 0
