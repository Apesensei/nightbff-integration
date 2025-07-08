#!/usr/bin/env bash
# acceptance-gate-1.4.sh - Task 1.4 Acceptance Gate Validation
# 
# Validates that pre-commit hook is properly installed and working
# Requirements: Hook auto-installed via `postinstall`

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Task 1.4 Acceptance Gate Validation${NC}"
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

# Test 1: .githooks/pre-commit exists and is executable
run_test "Pre-commit hook file exists and is executable" \
    "[ -f '.githooks/pre-commit' ] && [ -x '.githooks/pre-commit' ]"

# Test 2: Git hook is installed and links to our custom hook
run_test "Git hook is installed and properly linked" \
    "[ -L '.git/hooks/pre-commit' ] && [ \"\$(readlink '.git/hooks/pre-commit')\" = '../../.githooks/pre-commit' ]"

# Test 3: package.json has postinstall script with setup:hooks
run_test "package.json has postinstall script calling setup:hooks" \
    "grep -q '\"postinstall\".*setup:hooks' package.json"

# Test 4: Git hooks setup script exists and is executable
run_test "Git hooks setup script exists and is executable" \
    "[ -f 'scripts/setup-git-hooks.js' ] && [ -x 'scripts/setup-git-hooks.js' ]"

# Test 5: lint-staged is configured in package.json
run_test "lint-staged configuration exists in package.json" \
    "grep -q '\"lint-staged\"' package.json"

# Test 6: Required dependencies are installed
run_test "lint-staged and prettier dependencies are installed" \
    "[ -d 'node_modules/lint-staged' ] && [ -d 'node_modules/prettier' ]"

# Test 7: Hook script contains required functionality
run_test "Pre-commit hook contains lint-staged and submodule drift checks" \
    "grep -q 'lint-staged' .githooks/pre-commit && grep -q 'submodule.*drift' .githooks/pre-commit"

# Test 8: Hook setup script can be run successfully
run_test "Git hooks setup script runs successfully" \
    "cd \$(mktemp -d) && git init --quiet && cp -r \"\$OLDPWD/.githooks\" . && cp \"\$OLDPWD/scripts/setup-git-hooks.js\" . && node setup-git-hooks.js > /dev/null 2>&1"

# Summary
echo -e "${BLUE}📊 Test Results Summary${NC}"
echo -e "${BLUE}======================${NC}"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 All tests passed! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo -e "${GREEN}✅ Task 1.4 acceptance gate: PASSED${NC}"
    echo ""
    echo -e "${GREEN}✓ Pre-commit hook created in .githooks/pre-commit${NC}"
    echo -e "${GREEN}✓ Hook runs lint-staged and submodule drift checks${NC}"
    echo -e "${GREEN}✓ Auto-installation via postinstall script works${NC}"
    echo -e "${GREEN}✓ Git hooks are properly linked and executable${NC}"
    echo ""
    echo -e "${BLUE}🔧 Usage:${NC}"
    echo -e "${BLUE}  - Hooks are automatically installed when running 'npm install'${NC}"
    echo -e "${BLUE}  - Manual installation: 'npm run setup:hooks'${NC}"
    echo -e "${BLUE}  - Hooks will run automatically on 'git commit'${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo -e "${RED}🚫 Task 1.4 acceptance gate: FAILED${NC}"
    echo ""
    echo -e "${YELLOW}💡 Troubleshooting:${NC}"
    echo -e "${YELLOW}  1. Run 'npm install' to set up hooks automatically${NC}"
    echo -e "${YELLOW}  2. Check that .githooks/pre-commit is executable${NC}"
    echo -e "${YELLOW}  3. Verify lint-staged and prettier are installed${NC}"
    echo -e "${YELLOW}  4. Run 'npm run setup:hooks' manually if needed${NC}"
    exit 1
fi 