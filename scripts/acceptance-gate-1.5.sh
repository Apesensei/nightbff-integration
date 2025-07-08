#!/usr/bin/env bash
# acceptance-gate-1.5.sh - Task 1.5 Acceptance Gate Validation
# 
# Validates that Conventional Commits + commitlint GitHub Action is properly configured
# Requirements: Commit lint passes in CI

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Task 1.5 Acceptance Gate Validation${NC}"
echo -e "${BLUE}=====================================\n${NC}"

TESTS_PASSED=0
TESTS_TOTAL=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_TOTAL++))
    echo -e "${BLUE}🔍 Test $TESTS_TOTAL: $test_name${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASS${NC}\n"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}\n"
        return 1
    fi
}

# Test 1: commitlint.config.js exists
run_test "commitlint configuration file exists" \
    "[ -f 'commitlint.config.js' ]"

# Test 2: package.json has commitlint dependencies
run_test "package.json contains commitlint dependencies" \
    "grep -q '@commitlint/cli' package.json && grep -q '@commitlint/config-conventional' package.json"

# Test 3: commitlint dependencies are installed
run_test "commitlint dependencies are installed" \
    "[ -d 'node_modules/@commitlint/cli' ] && [ -d 'node_modules/@commitlint/config-conventional' ]"

# Test 4: GitHub Actions workflow has commitlint job
run_test "GitHub Actions workflow contains commitlint job" \
    "grep -q 'commitlint:' .github/workflows/integration-ci.yml && grep -q 'Conventional Commits Validation' .github/workflows/integration-ci.yml"

# Test 5: Valid conventional commit passes
run_test "Valid conventional commit message passes validation" \
    "echo 'feat(ci): add commitlint validation' | npx commitlint >/dev/null 2>&1"

# Test 6: Invalid commit message fails
run_test "Invalid commit message fails validation" \
    "! echo 'bad commit message' | npx commitlint >/dev/null 2>&1"

# Test 7: Pre-commit hook includes commitlint validation
run_test "Pre-commit hook includes commitlint validation" \
    "grep -q 'validate_commit_message' .githooks/pre-commit"

# Test 8: package.json has commitlint scripts
run_test "package.json has commitlint scripts" \
    "grep -q '\"commitlint\"' package.json"

# Test 9: commitlint config has proper types
run_test "commitlint config includes required conventional types" \
    "grep -q 'feat' commitlint.config.js && grep -q 'fix' commitlint.config.js && grep -q 'docs' commitlint.config.js && grep -q 'chore' commitlint.config.js"

# Test 10: GitHub Actions job validates both push and PR scenarios
run_test "GitHub Actions job handles both push and pull request events" \
    "grep -q 'github.event_name == .push.' .github/workflows/integration-ci.yml && grep -q 'github.event_name == .pull_request.' .github/workflows/integration-ci.yml"

# Summary
echo -e "${BLUE}📊 Test Results Summary${NC}"
echo -e "${BLUE}======================${NC}"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 All tests passed! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo -e "${GREEN}✅ Task 1.5 acceptance gate: PASSED${NC}"
    echo ""
    echo -e "${GREEN}✓ Conventional Commits specification adopted${NC}"
    echo -e "${GREEN}✓ commitlint configuration in place${NC}"
    echo -e "${GREEN}✓ GitHub Actions CI validation working${NC}"
    echo -e "${GREEN}✓ Pre-commit hook integration enabled${NC}"
    echo -e "${GREEN}✓ Package scripts for manual validation${NC}"
    echo ""
    echo -e "${BLUE}🔧 Usage:${NC}"
    echo -e "${BLUE}  - Write commits like: feat(scope): description${NC}"
    echo -e "${BLUE}  - Validation runs automatically in CI${NC}"
    echo -e "${BLUE}  - Manual check: npm run commitlint${NC}"
    echo -e "${BLUE}  - Local validation via pre-commit hook${NC}"
    echo ""
    echo -e "${BLUE}📋 Valid types:${NC}"
    echo -e "${BLUE}  feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo -e "${RED}🚫 Task 1.5 acceptance gate: FAILED${NC}"
    echo ""
    echo -e "${YELLOW}💡 Troubleshooting:${NC}"
    echo -e "${YELLOW}  1. Run 'npm install' to install commitlint dependencies${NC}"
    echo -e "${YELLOW}  2. Check commitlint.config.js is properly configured${NC}"
    echo -e "${YELLOW}  3. Verify GitHub Actions workflow includes commitlint job${NC}"
    echo -e "${YELLOW}  4. Test manually: echo 'feat: test' | npx commitlint${NC}"
    exit 1
fi 