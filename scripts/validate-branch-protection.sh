#!/usr/bin/env bash
# validate-branch-protection.sh - Validate branch protection configuration
set -euo pipefail

echo "🔍 Validating branch protection configuration..."

REPO_OWNER="Apesensei"
REPO_NAME="nightbff-integration"

# Function to check if required CI jobs are defined
validate_ci_jobs() {
    echo "📋 Checking CI workflow jobs..."
    
    local required_jobs=("sanity" "unit_backend" "unit_frontend" "contract_backend" "integration_tests")
    local workflow_file=".github/workflows/integration-ci.yml"
    
    if [ ! -f "$workflow_file" ]; then
        echo "❌ Workflow file not found: $workflow_file"
        return 1
    fi
    
    for job in "${required_jobs[@]}"; do
        if grep -q "^[[:space:]]*${job}:" "$workflow_file"; then
            echo "✅ Required job '$job' found in workflow"
        else
            echo "❌ Required job '$job' not found in workflow"
            return 1
        fi
    done
    
    echo "✅ All required CI jobs are defined"
}

# Function to validate documentation exists
validate_documentation() {
    echo "📚 Checking documentation..."
    
    if [ -f "docs/BRANCH_PROTECTION_SETUP.md" ]; then
        echo "✅ Branch protection documentation exists"
    else
        echo "❌ Branch protection documentation missing"
        return 1
    fi
    
    if [ -f "scripts/setup-branch-protection.sh" ] && [ -x "scripts/setup-branch-protection.sh" ]; then
        echo "✅ Setup script exists and is executable"
    else
        echo "❌ Setup script missing or not executable"
        return 1
    fi
}

# Function to check for protection status (requires GitHub CLI or API access)
check_protection_status() {
    echo "🔐 Checking branch protection status..."
    
    # Check if gh CLI is available
    if command -v gh >/dev/null 2>&1; then
        echo "📡 GitHub CLI detected, checking protection status..."
        
        # Check if authenticated
        if ! gh auth status >/dev/null 2>&1; then
            echo "⚠️  GitHub CLI not authenticated - cannot check protection status"
            echo "   Run 'gh auth login' to enable protection status checking"
            return 0
        fi
        
        # Check main branch protection
        if gh api "repos/${REPO_OWNER}/${REPO_NAME}/branches/main/protection" >/dev/null 2>&1; then
            echo "✅ Main branch protection is enabled"
            
            # Check for required status checks
            local checks
            checks=$(gh api "repos/${REPO_OWNER}/${REPO_NAME}/branches/main/protection/required_status_checks" --jq '.contexts[]' 2>/dev/null || echo "")
            
            if echo "$checks" | grep -q "sanity\|unit_backend\|unit_frontend"; then
                echo "✅ Required status checks are configured"
            else
                echo "⚠️  Required status checks may not be fully configured"
            fi
        else
            echo "❌ Main branch protection not detected"
            echo "   Please configure branch protection using the setup guide"
            return 1
        fi
    else
        echo "⚠️  GitHub CLI not available - cannot automatically check protection status"
        echo "   Install GitHub CLI (https://cli.github.com/) for automated validation"
        echo "   Or manually verify protection at: https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
    fi
}

# Function to simulate protection test
simulate_protection_test() {
    echo "🧪 Simulating protection scenarios..."
    
    # Check if we're on a protected branch
    local current_branch
    current_branch=$(git branch --show-current)
    
    if [ "$current_branch" = "main" ]; then
        echo "⚠️  Currently on main branch - direct pushes should be blocked"
        echo "   Recommended: work on feature branches and use PRs"
    else
        echo "✅ Currently on branch '$current_branch' - safe for development"
    fi
    
    # Check for uncommitted changes that might indicate direct main editing
    if [ "$current_branch" = "main" ] && ! git diff --quiet; then
        echo "⚠️  Uncommitted changes detected on main branch"
        echo "   This may indicate bypass of branch protection"
    fi
}

# Main execution
main() {
    echo "🛡️  Branch Protection Validation for ${REPO_OWNER}/${REPO_NAME}"
    echo "=============================================================="
    
    local exit_code=0
    
    validate_ci_jobs || exit_code=1
    validate_documentation || exit_code=1
    check_protection_status || exit_code=1
    simulate_protection_test
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        echo "✅ Branch protection validation completed successfully"
        echo ""
        echo "📝 Next steps if protection is not yet applied:"
        echo "1. Review: docs/BRANCH_PROTECTION_SETUP.md"
        echo "2. Apply settings via GitHub web UI or CLI"
        echo "3. Test with a dummy PR to verify protection"
    else
        echo "❌ Branch protection validation failed"
        echo ""
        echo "🔧 Required actions:"
        echo "1. Fix the issues identified above"
        echo "2. Run this validation script again"
        echo "3. Apply branch protection settings when validation passes"
    fi
    
    return $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 