#!/usr/bin/env bash
# acceptance-gate-2.3.sh - Task 2.3 Acceptance Gate
# 
# Verifies deliverables for Task 2.3:
# - .renovaterc.json configuration file exists and is valid
# - GitHub workflow for Renovate validation exists
# - Documentation for Renovate setup exists
# - Configuration includes weekly schedule and appropriate safeguards

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Task 2.3 Acceptance Gate${NC}"
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

# Test 1: Renovate configuration file exists and is valid JSON
check_renovate_config() {
    if [ ! -f ".renovaterc.json" ]; then
        echo "❌ .renovaterc.json file not found"
        return 1
    fi
    
    # Check if it's valid JSON
    if jq empty .renovaterc.json >/dev/null 2>&1; then
        echo "✅ .renovaterc.json is valid JSON"
    else
        echo "❌ .renovaterc.json is not valid JSON"
        return 1
    fi
    
    # Check file size (should have meaningful content)
    local file_size=$(wc -c < .renovaterc.json)
    if [ "$file_size" -gt 100 ]; then
        echo "✅ Configuration file has substantial content ($file_size bytes)"
        return 0
    else
        echo "❌ Configuration file seems too small ($file_size bytes)"
        return 1
    fi
}

run_test "Renovate configuration exists and is valid JSON" "check_renovate_config"

# Test 2: Weekly schedule is configured
check_weekly_schedule() {
    if jq -e '.schedule // .extends | contains(["schedule:weekly"]) or (type == "array" and map(test("every saturday")) | any)' .renovaterc.json >/dev/null 2>&1; then
        echo "✅ Weekly schedule configured in extends or schedule field"
        return 0
    elif grep -q "schedule:weekly\|every saturday" .renovaterc.json; then
        echo "✅ Weekly schedule found in configuration"
        return 0
    else
        echo "❌ Weekly schedule not configured"
        return 1
    fi
}

run_test "Weekly schedule is configured" "check_weekly_schedule"

# Test 3: Security configuration present
check_security_config() {
    if jq -e '.vulnerabilityAlerts.enabled == true or .osvVulnerabilityAlerts == true' .renovaterc.json >/dev/null 2>&1; then
        echo "✅ Vulnerability alerts are enabled"
    else
        echo "❌ Vulnerability alerts not properly configured"
        return 1
    fi
    
    # Check for security package rules
    if jq -e '.packageRules[]? | select(.labels[]? == "security")' .renovaterc.json >/dev/null 2>&1; then
        echo "✅ Security package rules configured"
        return 0
    else
        echo "❌ Security package rules not found"
        return 1
    fi
}

run_test "Security configuration is present" "check_security_config"

# Test 4: Auto-merge safeguards in place
check_automerge_safeguards() {
    # Check that platformAutomerge is disabled (safer)
    if jq -e '.platformAutomerge == false' .renovaterc.json >/dev/null 2>&1; then
        echo "✅ Platform auto-merge is disabled (safer)"
    else
        echo "⚠️  Platform auto-merge setting not explicitly disabled"
    fi
    
    # Check for required status checks on auto-merge rules
    if jq -e '.packageRules[]? | select(.automerge == true) | .requiredStatusChecks // empty | length > 0' .renovaterc.json >/dev/null 2>&1; then
        echo "✅ Auto-merge rules have required status checks"
        return 0
    else
        echo "❌ Auto-merge rules don't have required status checks"
        return 1
    fi
}

run_test "Auto-merge safeguards are in place" "check_automerge_safeguards"

# Test 5: Rate limiting configured
check_rate_limiting() {
    local has_limits=false
    
    if jq -e '.prHourlyLimit' .renovaterc.json >/dev/null 2>&1; then
        local hourly_limit=$(jq -r '.prHourlyLimit' .renovaterc.json)
        echo "✅ PR hourly limit set to $hourly_limit"
        has_limits=true
    fi
    
    if jq -e '.prConcurrentLimit' .renovaterc.json >/dev/null 2>&1; then
        local concurrent_limit=$(jq -r '.prConcurrentLimit' .renovaterc.json)
        echo "✅ PR concurrent limit set to $concurrent_limit"
        has_limits=true
    fi
    
    if [ "$has_limits" = true ]; then
        return 0
    else
        echo "❌ No rate limiting configured"
        return 1
    fi
}

run_test "Rate limiting is configured" "check_rate_limiting"

# Test 6: Package grouping configured
check_package_grouping() {
    local groups_found=0
    
    # Check for React Native grouping
    if jq -e '.packageRules[]? | select(.groupName and (.groupName | contains("React Native")))' .renovaterc.json >/dev/null 2>&1; then
        echo "✅ React Native package grouping found"
        ((groups_found++))
    fi
    
    # Check for NestJS grouping
    if jq -e '.packageRules[]? | select(.groupName and (.groupName | contains("NestJS")))' .renovaterc.json >/dev/null 2>&1; then
        echo "✅ NestJS package grouping found"
        ((groups_found++))
    fi
    
    # Check for security grouping
    if jq -e '.packageRules[]? | select(.labels[]? == "security")' .renovaterc.json >/dev/null 2>&1; then
        echo "✅ Security package handling found"
        ((groups_found++))
    fi
    
    if [ "$groups_found" -ge 2 ]; then
        echo "✅ Multiple package groupings configured ($groups_found found)"
        return 0
    else
        echo "❌ Insufficient package grouping configured ($groups_found found)"
        return 1
    fi
}

run_test "Package grouping is configured" "check_package_grouping"

# Test 7: GitHub workflow for validation exists
check_validation_workflow() {
    if [ ! -f ".github/workflows/renovate-config-validation.yml" ]; then
        echo "❌ Renovate validation workflow not found"
        return 1
    fi
    
    # Check workflow has required elements
    if grep -q "renovate-config-validator" .github/workflows/renovate-config-validation.yml; then
        echo "✅ Workflow uses renovate-config-validator"
    else
        echo "❌ Workflow doesn't use renovate-config-validator"
        return 1
    fi
    
    if grep -q "node-version.*20" .github/workflows/renovate-config-validation.yml; then
        echo "✅ Workflow uses Node 20"
        return 0
    else
        echo "❌ Workflow doesn't use Node 20"
        return 1
    fi
}

run_test "GitHub validation workflow exists" "check_validation_workflow"

# Test 8: Documentation exists and is complete
check_documentation() {
    if [ ! -f "docs/RENOVATE_SETUP.md" ]; then
        echo "❌ RENOVATE_SETUP.md documentation not found"
        return 1
    fi
    
    # Check for key sections
    local required_sections=("Setup Instructions" "Configuration" "weekly" "auto-merge" "security" "troubleshooting")
    local missing_sections=()
    
    for section in "${required_sections[@]}"; do
        if ! grep -iq "$section" docs/RENOVATE_SETUP.md; then
            missing_sections+=("$section")
        fi
    done
    
    if [ ${#missing_sections[@]} -eq 0 ]; then
        echo "✅ Documentation contains all required sections"
        return 0
    else
        echo "❌ Documentation missing sections: ${missing_sections[*]}"
        return 1
    fi
}

run_test "Documentation exists and is complete" "check_documentation"

# Test 9: Semantic commits integration
check_semantic_commits() {
    if jq -e '.semanticCommits == "enabled"' .renovaterc.json >/dev/null 2>&1; then
        echo "✅ Semantic commits enabled"
    else
        echo "⚠️  Semantic commits not explicitly enabled"
    fi
    
    if jq -e '.commitMessagePrefix' .renovaterc.json >/dev/null 2>&1; then
        local prefix=$(jq -r '.commitMessagePrefix' .renovaterc.json)
        echo "✅ Commit message prefix configured: $prefix"
        return 0
    else
        echo "❌ Commit message prefix not configured"
        return 1
    fi
}

run_test "Semantic commits integration" "check_semantic_commits"

# Test 10: Configuration validation using Node.js (if available)
check_config_validation() {
    if command -v node >/dev/null 2>&1; then
        # Simple JSON parsing test
        if node -e "JSON.parse(require('fs').readFileSync('.renovaterc.json', 'utf8'))" 2>/dev/null; then
            echo "✅ Configuration passes Node.js JSON validation"
            return 0
        else
            echo "❌ Configuration fails Node.js JSON validation"
            return 1
        fi
    else
        echo "ℹ️  Node.js not available for validation (using jq validation instead)"
        # Fall back to jq validation which we already did
        return 0
    fi
}

run_test "Configuration validation with Node.js" "check_config_validation"

# Summary
echo -e "${BLUE}📊 Task 2.3 Acceptance Results${NC}"
echo -e "${BLUE}===============================${NC}"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 All acceptance tests passed! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo -e "${GREEN}✅ Task 2.3 deliverables verified:${NC}"
    echo -e "${GREEN}   📄 .renovaterc.json configuration with weekly schedule${NC}"
    echo -e "${GREEN}   🛡️  Security updates and vulnerability alerts enabled${NC}"
    echo -e "${GREEN}   🔄 Auto-merge with CI safeguards for safe packages${NC}"
    echo -e "${GREEN}   📊 Rate limiting and package grouping configured${NC}"
    echo -e "${GREEN}   🔍 GitHub workflow for config validation${NC}"
    echo -e "${GREEN}   📚 Complete documentation for setup and operations${NC}"
    echo ""
    echo -e "${BLUE}🤖 Renovate Bot Ready For:${NC}"
    echo -e "${BLUE}   • Weekly dependency updates (Saturdays)${NC}"
    echo -e "${BLUE}   • Automatic security updates${NC}"
    echo -e "${BLUE}   • Package grouping by ecosystem${NC}"
    echo -e "${BLUE}   • Manual review for major updates${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next Steps (Requires Repository Admin):${NC}"
    echo -e "${YELLOW}   1. Install Renovate GitHub App${NC}"
    echo -e "${YELLOW}   2. Update team mentions in config${NC}"
    echo -e "${YELLOW}   3. Configure branch protection for Renovate bot${NC}"
    exit 0
else
    echo -e "${RED}❌ Task 2.3 acceptance failed! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo -e "${RED}🚫 Please fix the issues above${NC}"
    echo ""
    echo -e "${YELLOW}💡 Required deliverables:${NC}"
    echo -e "${YELLOW}   • .renovaterc.json with weekly schedule${NC}"
    echo -e "${YELLOW}   • Security and auto-merge safeguards${NC}"
    echo -e "${YELLOW}   • Rate limiting and package grouping${NC}"
    echo -e "${YELLOW}   • GitHub validation workflow${NC}"
    echo -e "${YELLOW}   • Complete setup documentation${NC}"
    exit 1
fi 