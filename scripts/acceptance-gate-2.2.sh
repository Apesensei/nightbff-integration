#!/usr/bin/env bash
# acceptance-gate-2.2.sh - Task 2.2 Acceptance Gate
# 
# Verifies deliverables for Task 2.2:
# - .nvmrc file exists and specifies Node 20
# - .tool-versions file exists and specifies Node 20.x
# - Pre-commit hook includes Node version verification
# - Documentation exists

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Task 2.2 Acceptance Gate${NC}"
echo -e "${BLUE}============================${NC}\n"

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

# Test 1: .nvmrc file exists and contains Node 20
check_nvmrc() {
    if [ ! -f ".nvmrc" ]; then
        echo "❌ .nvmrc file not found"
        return 1
    fi
    
    local nvmrc_content=$(cat .nvmrc | tr -d '\n' | tr -d '\r' | tr -d ' ')
    echo "Found .nvmrc content: '$nvmrc_content'"
    
    if [ "$nvmrc_content" = "20" ]; then
        echo "✅ .nvmrc correctly specifies Node 20"
        return 0
    else
        echo "❌ .nvmrc should contain '20', found '$nvmrc_content'"
        return 1
    fi
}

run_test ".nvmrc file exists and specifies Node 20" "check_nvmrc"

# Test 2: .tool-versions file exists and contains Node 20.x
check_tool_versions() {
    if [ ! -f ".tool-versions" ]; then
        echo "❌ .tool-versions file not found"
        return 1
    fi
    
    if grep -q "nodejs" .tool-versions; then
        local nodejs_version=$(grep "nodejs" .tool-versions | awk '{print $2}')
        echo "Found Node.js version in .tool-versions: $nodejs_version"
        
        # Check if it starts with 20
        if echo "$nodejs_version" | grep -q "^20\."; then
            echo "✅ .tool-versions correctly specifies Node 20.x"
            return 0
        else
            echo "❌ .tool-versions should specify Node 20.x, found $nodejs_version"
            return 1
        fi
    else
        echo "❌ .tool-versions should contain nodejs entry"
        return 1
    fi
}

run_test ".tool-versions file exists and specifies Node 20.x" "check_tool_versions"

# Test 3: Pre-commit hook includes Node version verification
check_precommit_node_verification() {
    if [ ! -f ".githooks/pre-commit" ]; then
        echo "❌ Pre-commit hook not found"
        return 1
    fi
    
    # Check for the verify_node_version function
    if grep -q "verify_node_version()" .githooks/pre-commit; then
        echo "✅ verify_node_version function found in pre-commit hook"
    else
        echo "❌ verify_node_version function not found in pre-commit hook"
        return 1
    fi
    
    # Check if function is called in main
    if grep "verify_node_version" .githooks/pre-commit | grep -v "verify_node_version()" | grep -q "verify_node_version"; then
        echo "✅ verify_node_version is called in pre-commit hook"
        return 0
    else
        echo "❌ verify_node_version is not called in pre-commit hook main function"
        return 1
    fi
}

run_test "Pre-commit hook includes Node version verification" "check_precommit_node_verification"

# Test 4: Pre-commit hook checks .nvmrc and .tool-versions
check_precommit_file_checks() {
    if ! grep -q ".nvmrc" .githooks/pre-commit; then
        echo "❌ Pre-commit hook doesn't check .nvmrc"
        return 1
    fi
    
    if ! grep -q ".tool-versions" .githooks/pre-commit; then
        echo "❌ Pre-commit hook doesn't check .tool-versions"
        return 1
    fi
    
    echo "✅ Pre-commit hook checks both .nvmrc and .tool-versions"
    return 0
}

run_test "Pre-commit hook validates version files" "check_precommit_file_checks"

# Test 5: Documentation exists
check_documentation() {
    if [ ! -f "docs/LOCAL_DEVELOPMENT_SETUP.md" ]; then
        echo "❌ LOCAL_DEVELOPMENT_SETUP.md documentation not found"
        return 1
    fi
    
    # Check for key sections
    local required_sections=("nvm" "asdf" ".nvmrc" ".tool-versions" "Node.js 20")
    
    for section in "${required_sections[@]}"; do
        if ! grep -iq "$section" docs/LOCAL_DEVELOPMENT_SETUP.md; then
            echo "❌ Documentation missing section about: $section"
            return 1
        fi
    done
    
    echo "✅ Documentation contains all required sections"
    return 0
}

run_test "Documentation exists and is complete" "check_documentation"

# Test 6: Files are properly formatted and readable
check_file_format() {
    # Check .nvmrc is single line
    local nvmrc_lines=$(wc -l < .nvmrc)
    if [ "$nvmrc_lines" -gt 1 ]; then
        echo "❌ .nvmrc should be single line, found $nvmrc_lines lines"
        return 1
    fi
    
    # Check .tool-versions has nodejs entry
    if [ "$(grep -c "nodejs" .tool-versions)" -ne 1 ]; then
        echo "❌ .tool-versions should have exactly one nodejs entry"
        return 1
    fi
    
    echo "✅ Version files are properly formatted"
    return 0
}

run_test "Version files are properly formatted" "check_file_format"

# Test 7: Integration with existing Node validation script
check_integration() {
    if [ ! -f "scripts/validate-node-alignment.sh" ]; then
        echo "❌ Node alignment validation script not found"
        return 1
    fi
    
    # The script should pass with our new files
    if ./scripts/validate-node-alignment.sh >/dev/null 2>&1; then
        echo "✅ Node alignment script passes with new version files"
        return 0
    else
        echo "❌ Node alignment script fails with current configuration"
        return 1
    fi
}

run_test "Integration with Node alignment validator" "check_integration"

# Test 8: Pre-commit hook is executable and syntactically valid
check_hook_validity() {
    if [ ! -x ".githooks/pre-commit" ]; then
        echo "❌ Pre-commit hook is not executable"
        return 1
    fi
    
    # Basic syntax check
    if bash -n .githooks/pre-commit; then
        echo "✅ Pre-commit hook syntax is valid"
        return 0
    else
        echo "❌ Pre-commit hook has syntax errors"
        return 1
    fi
}

run_test "Pre-commit hook is valid and executable" "check_hook_validity"

# Summary
echo -e "${BLUE}📊 Task 2.2 Acceptance Results${NC}"
echo -e "${BLUE}===============================${NC}"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 All acceptance tests passed! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo -e "${GREEN}✅ Task 2.2 deliverables verified:${NC}"
    echo -e "${GREEN}   📄 .nvmrc file with Node 20${NC}"
    echo -e "${GREEN}   📄 .tool-versions file with Node 20.x${NC}"
    echo -e "${GREEN}   🔧 Pre-commit hook Node verification${NC}"
    echo -e "${GREEN}   📚 Local development documentation${NC}"
    echo ""
    echo -e "${BLUE}🛠️  Developers can now use:${NC}"
    echo -e "${BLUE}   • nvm use (reads .nvmrc)${NC}"
    echo -e "${BLUE}   • asdf install (reads .tool-versions)${NC}"
    echo -e "${BLUE}   • Pre-commit automatic verification${NC}"
    exit 0
else
    echo -e "${RED}❌ Task 2.2 acceptance failed! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo -e "${RED}🚫 Please fix the issues above${NC}"
    echo ""
    echo -e "${YELLOW}💡 Required deliverables:${NC}"
    echo -e "${YELLOW}   • .nvmrc file containing '20'${NC}"
    echo -e "${YELLOW}   • .tool-versions file with 'nodejs 20.x.x'${NC}"
    echo -e "${YELLOW}   • Pre-commit hook with verify_node_version function${NC}"
    echo -e "${YELLOW}   • Documentation in docs/LOCAL_DEVELOPMENT_SETUP.md${NC}"
    exit 1
fi 