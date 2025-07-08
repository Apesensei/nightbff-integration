#!/usr/bin/env bash
# validate-node-alignment.sh - Node Version Alignment Validator
# 
# Validates that Node 20 is consistently specified across:
# - GitHub Actions workflows
# - Dockerfiles  
# - package.json engines fields

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Node Version Alignment Validator${NC}"
echo -e "${BLUE}===================================${NC}\n"

TESTS_PASSED=0
TESTS_TOTAL=0
EXPECTED_NODE_VERSION="20"

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

# Test 1: GitHub Actions workflows use Node 20
check_github_actions() {
    local workflow_files=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null)
    if [ -z "$workflow_files" ]; then
        echo "No GitHub Actions workflows found"
        return 1
    fi
    
    local node_versions=$(grep -h "node-version:" $workflow_files | sed "s/.*node-version: *['\"]*//" | sed "s/['\"].*//" | sort -u)
    
    echo "Found Node versions in workflows: $node_versions"
    
    # Check if all versions are 20
    for version in $node_versions; do
        if [ "$version" != "$EXPECTED_NODE_VERSION" ]; then
            echo "❌ Found Node version $version, expected $EXPECTED_NODE_VERSION"
            return 1
        fi
    done
    
    echo "✅ All workflow jobs use Node $EXPECTED_NODE_VERSION"
    return 0
}

run_test "GitHub Actions workflows use Node 20" "check_github_actions"

# Test 2: Dockerfiles use Node 20
check_dockerfiles() {
    local dockerfile_paths=$(find . -name "Dockerfile*" -not -path "./node_modules/*" -not -path "./.git/*" 2>/dev/null)
    if [ -z "$dockerfile_paths" ]; then
        echo "No Dockerfiles found"
        return 0
    fi
    
    local node_images=$(grep "FROM node:" $dockerfile_paths | grep -v "^#" || true)
    
    if [ -z "$node_images" ]; then
        echo "No Node base images found in Dockerfiles"
        return 0
    fi
    
    echo "Found Node base images:"
    echo "$node_images"
    
    # Check if all use Node 20
    if echo "$node_images" | grep -v "node:$EXPECTED_NODE_VERSION"; then
        echo "❌ Found Node versions other than $EXPECTED_NODE_VERSION"
        return 1
    fi
    
    echo "✅ All Dockerfiles use Node $EXPECTED_NODE_VERSION"
    return 0
}

run_test "Dockerfiles use Node 20" "check_dockerfiles"

# Test 3: package.json engines field specifies Node 20+
check_package_engines() {
    local package_files=$(find . -name "package.json" -not -path "./node_modules/*" -not -path "./.git/*" 2>/dev/null)
    local found_engines=false
    
    for package_file in $package_files; do
        if grep -q '"engines"' "$package_file"; then
            found_engines=true
            echo "Checking engines in $package_file:"
            
            local node_constraint=$(grep -A 5 '"engines"' "$package_file" | grep '"node"' | sed 's/.*"node": *"//' | sed 's/".*//')
            
            if [ -n "$node_constraint" ]; then
                echo "  Node constraint: $node_constraint"
                
                # Check if constraint allows Node 20
                if echo "$node_constraint" | grep -q ">=20\|^20\|~20\|\^20"; then
                    echo "  ✅ Allows Node $EXPECTED_NODE_VERSION"
                else
                    echo "  ❌ Does not properly specify Node $EXPECTED_NODE_VERSION"
                    return 1
                fi
            else
                echo "  ❌ No node constraint found in engines"
                return 1
            fi
        fi
    done
    
    if [ "$found_engines" = false ]; then
        echo "❌ No package.json files with engines field found"
        return 1
    fi
    
    echo "✅ All package.json engines fields properly specify Node $EXPECTED_NODE_VERSION+"
    return 0
}

run_test "package.json engines specify Node 20+" "check_package_engines"

# Test 4: Local Node version (if available)
check_local_node() {
    if command -v node >/dev/null 2>&1; then
        local local_version=$(node --version | sed 's/v//' | cut -d. -f1)
        echo "Local Node version: $local_version"
        
        if [ "$local_version" -ge "$EXPECTED_NODE_VERSION" ]; then
            echo "✅ Local Node version is compatible"
            return 0
        else
            echo "⚠️  Local Node version is older than expected"
            return 1
        fi
    else
        echo "ℹ️  Node.js not found locally (this is fine in CI)"
        return 0
    fi
}

run_test "Local Node version compatibility" "check_local_node"

# Summary
echo -e "${BLUE}📊 Node Alignment Results${NC}"
echo -e "${BLUE}=========================${NC}"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 All Node version checks passed! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo -e "${GREEN}✅ Node $EXPECTED_NODE_VERSION alignment verified${NC}"
    echo ""
    echo -e "${BLUE}📋 Validated configurations:${NC}"
    echo -e "${BLUE}  - GitHub Actions workflows: Node $EXPECTED_NODE_VERSION${NC}"
    echo -e "${BLUE}  - Docker base images: Node $EXPECTED_NODE_VERSION-alpine${NC}"  
    echo -e "${BLUE}  - package.json engines: Node >=$EXPECTED_NODE_VERSION.0.0${NC}"
    exit 0
else
    echo -e "${RED}❌ Node version alignment issues found! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo -e "${RED}🚫 Please fix the issues above${NC}"
    echo ""
    echo -e "${YELLOW}💡 Common fixes:${NC}"
    echo -e "${YELLOW}  - Update 'node-version' in .github/workflows/*.yml${NC}"
    echo -e "${YELLOW}  - Update 'FROM node:X' in Dockerfile${NC}"
    echo -e "${YELLOW}  - Add 'engines.node: \">=$EXPECTED_NODE_VERSION.0.0\"' to package.json${NC}"
    exit 1
fi 