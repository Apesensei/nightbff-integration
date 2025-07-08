#!/usr/bin/env bash
# setup-branch-protection.sh - Configure branch protection rules
# Usage: Run manually or adapt for GitHub API calls

set -euo pipefail

echo "🛡️  Setting up branch protection rules for NightBFF Integration repository..."

# Repository information
REPO_OWNER="Apesensei"
REPO_NAME="nightbff-integration"
GITHUB_API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"

# Required CI checks based on integration-ci.yml workflow
REQUIRED_CHECKS=(
    "sanity"
    "unit_backend" 
    "unit_frontend"
    "contract_backend"
    "integration_tests"
)

echo "📋 Required CI checks identified:"
for check in "${REQUIRED_CHECKS[@]}"; do
    echo "  ✓ $check"
done

# Function to create branch protection rule
setup_main_protection() {
    cat << EOF

🔐 MAIN BRANCH PROTECTION CONFIGURATION:
=====================================

Branch: main
Settings to configure in GitHub:

1. Require status checks to pass before merging: ✅
   Required checks:
$(printf '   - %s\n' "${REQUIRED_CHECKS[@]}")

2. Require branches to be up to date before merging: ✅

3. Require conversation resolution before merging: ✅

4. Restrict who can push to matching branches: ✅
   - Repository administrators only
   - No force pushes allowed
   - No deletions allowed

5. Require signed commits: ⚠️  (Optional - see analysis below)

6. Require linear history: ✅ (Aligns with fast-forward merge strategy)

SIGNED COMMITS ANALYSIS:
- PRO: Enhanced security, audit trail
- CON: May disrupt current developer workflow
- RECOMMENDATION: Enable after team training on commit signing

GITHUB WEB UI PATH:
Repository → Settings → Branches → Add rule → Branch name pattern: main

EOF
}

# Function to create integration branch protection (lighter rules)
setup_integration_protection() {
    cat << EOF

🔐 INTEGRATION/** BRANCH PROTECTION CONFIGURATION:
==============================================

Branch pattern: integration/**
Settings to configure in GitHub:

1. Require status checks to pass before merging: ✅
   Required checks:
   - sanity (minimum safety check)
   - unit_backend (core functionality)

2. Require branches to be up to date before merging: ❌
   (Integration branches are experimental)

3. Require conversation resolution before merging: ❌

4. Restrict who can push to matching branches: ❌
   (Allow team flexibility for integration work)

5. Require signed commits: ❌

6. Require linear history: ❌

RATIONALE:
Integration branches are short-lived (≤5 days) and used for 
cross-team experimentation. Lighter protection allows agility
while maintaining core safety checks.

GITHUB WEB UI PATH:
Repository → Settings → Branches → Add rule → Branch name pattern: integration/**

EOF
}

# Function to validate current CI workflow
validate_workflow() {
    echo "🔍 Validating CI workflow configuration..."
    
    if [ ! -f ".github/workflows/integration-ci.yml" ]; then
        echo "❌ integration-ci.yml not found"
        return 1
    fi

    echo "✅ Integration CI workflow found"
    
    # Check if all required jobs exist in workflow
    for check in "${REQUIRED_CHECKS[@]}"; do
        if grep -q "^[[:space:]]*${check}:" .github/workflows/integration-ci.yml; then
            echo "✅ Job '$check' found in workflow"
        else
            echo "❌ Job '$check' not found in workflow"
            return 1
        fi
    done
    
    echo "✅ All required CI checks are defined in workflow"
}

# Function to create GitHub CLI commands (if gh CLI is available)
generate_gh_commands() {
    cat << EOF

🤖 GITHUB CLI COMMANDS (if 'gh' CLI is installed):
===============================================

# Protect main branch
gh api repos/${REPO_OWNER}/${REPO_NAME}/branches/main/protection \\
  --method PUT \\
  --field required_status_checks='{"strict":true,"contexts":["sanity","unit_backend","unit_frontend","contract_backend","integration_tests"]}' \\
  --field enforce_admins=true \\
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \\
  --field restrictions=null \\
  --field required_linear_history=true \\
  --field allow_force_pushes=false \\
  --field allow_deletions=false

# Protect integration/** branches (lighter protection)
gh api repos/${REPO_OWNER}/${REPO_NAME}/branches/integration/*/protection \\
  --method PUT \\
  --field required_status_checks='{"strict":false,"contexts":["sanity","unit_backend"]}' \\
  --field enforce_admins=false \\
  --field required_pull_request_reviews=null \\
  --field restrictions=null \\
  --field required_linear_history=false \\
  --field allow_force_pushes=true \\
  --field allow_deletions=true

EOF
}

# Main execution
main() {
    echo "🔧 Branch Protection Setup for ${REPO_OWNER}/${REPO_NAME}"
    echo "======================================================="
    
    validate_workflow
    setup_main_protection
    setup_integration_protection
    generate_gh_commands
    
    echo ""
    echo "📝 NEXT STEPS:"
    echo "1. Review the configuration above"
    echo "2. Apply settings via GitHub web UI or CLI commands"
    echo "3. Test with a dummy PR to verify protection is active"
    echo "4. Update team documentation with new branch protection rules"
    
    echo ""
    echo "✅ Branch protection configuration script completed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 